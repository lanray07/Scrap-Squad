"""Save three localized CPP drafts with verified galleries; never submit review.

Uses Apple's public App Store Connect API and existing GitHub secrets. Preserves
unexpected assets rather than deleting them. A rerun reuses pages and checksums.
"""
import hashlib
import json
from pathlib import Path
from configure_iap import AppleAPI, APP_ID, ROOT, relationship, resource
from release_assets import upload, wait_asset

ASSETS = ROOT / "Marketing/CustomProductPages"
REPORT = ROOT / ".build/custom-product-pages-status.json"


def gallery(api, locale_id, shots):
    display = "APP_IPHONE_67" if shots[0]["device"] == "iPhone" else "APP_IPAD_PRO_3GEN_129"
    sets = api.all(f"/v1/appCustomProductPageLocalizations/{locale_id}/appScreenshotSets?limit=200")
    current = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == display), None)
    if current is None:
        current = api.call("POST", "/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display},
            "relationships": {"appCustomProductPageLocalization": relationship("appCustomProductPageLocalizations", locale_id)}}})["data"]
    existing = api.all(f"/v1/appScreenshotSets/{current['id']}/appScreenshots?limit=200")
    files = [(ASSETS / shot["file"], shot) for shot in shots]
    expected = []
    for file, shot in files:
        data = file.read_bytes()
        assert hashlib.sha256(data).hexdigest() == shot["sha256"], "Asset differs from reviewed manifest"
        expected.append(hashlib.md5(data).hexdigest())
    if any(s["attributes"].get("sourceFileChecksum") not in expected for s in existing):
        raise RuntimeError("Unexpected existing screenshot preserved; manual reconciliation needed")
    ordered = []
    for (file, _), checksum in zip(files, expected):
        match = next((s for s in existing if s["attributes"].get("sourceFileChecksum") == checksum), None)
        asset = wait_asset(api, match["id"]) if match else upload(api, current["id"], file)
        ordered.append(asset["id"])
    api.call("PATCH", f"/v1/appScreenshotSets/{current['id']}/relationships/appScreenshots", {
        "data": [resource("appScreenshots", identifier) for identifier in ordered]})
    actual = api.all(f"/v1/appScreenshotSets/{current['id']}/appScreenshots?limit=200")
    assert [s["attributes"].get("sourceFileChecksum") for s in actual] == expected
    assert all(s["attributes"].get("assetDeliveryState", {}).get("state") == "COMPLETE" for s in actual)
    return {"display": display, "count": len(actual), "checksumsVerified": True, "ordered": True}


def main():
    api = AppleAPI()
    manifest = json.loads((ASSETS / "manifest.json").read_text(encoding="utf-8"))
    report = {"appID": APP_ID, "reviewSubmitted": False, "keywordsAssigned": False, "campaigns": []}
    REPORT.parent.mkdir(exist_ok=True)
    pages = api.all(f"/v1/apps/{APP_ID}/appCustomProductPages?limit=200")
    for campaign in sorted({e["id"] for e in manifest["campaigns"]}):
        entries = [e for e in manifest["campaigns"] if e["id"] == campaign]
        name = entries[0]["referenceName"]
        page = next((p for p in pages if p["attributes"]["name"] == name), None)
        if page is None:
            inline = "${new-cpp-version}"
            page = api.call("POST", "/v1/appCustomProductPages", {"data": {
                "type": "appCustomProductPages", "attributes": {"name": name}, "relationships": {
                    "app": relationship("apps", APP_ID),
                    "appCustomProductPageVersions": {"data": [resource("appCustomProductPageVersions", inline)]}}},
                "included": [{"type": "appCustomProductPageVersions", "id": inline,
                    "relationships": {"appCustomProductPage": {}}}]})["data"]
        versions = api.all(f"/v1/appCustomProductPages/{page['id']}/appCustomProductPageVersions?limit=200")
        version = next((v for v in versions if v["attributes"]["state"] == "PREPARE_FOR_SUBMISSION"), None)
        if version is None:
            raise RuntimeError("No editable draft; preserving review/approved version")
        current = api.all(f"/v1/appCustomProductPageVersions/{version['id']}/appCustomProductPageLocalizations?limit=200")
        result = {"campaign": campaign, "pageID": page["id"], "versionID": version["id"],
                  "url": page["attributes"].get("url"), "state": version["attributes"]["state"], "locales": []}
        report["campaigns"].append(result)
        for entry in entries:
            api = AppleAPI()  # Refresh the short-lived token during long asset batches.
            locale = next((l for l in current if l["attributes"]["locale"] == entry["locale"]), None)
            attrs = {"promotionalText": entry["promotionalText"]}
            assert len(attrs["promotionalText"]) <= 170
            if locale is None:
                locale = api.call("POST", "/v1/appCustomProductPageLocalizations", {"data": {
                    "type": "appCustomProductPageLocalizations", "attributes": {"locale": entry["locale"], **attrs},
                    "relationships": {"appCustomProductPageVersion": relationship("appCustomProductPageVersions", version["id"])}}})["data"]
            elif locale["attributes"].get("promotionalText") != attrs["promotionalText"]:
                api.call("PATCH", f"/v1/appCustomProductPageLocalizations/{locale['id']}", {"data": {
                    **resource("appCustomProductPageLocalizations", locale["id"]), "attributes": attrs}})
            saved = api.call("GET", f"/v1/appCustomProductPageLocalizations/{locale['id']}")["data"]
            assert saved["attributes"]["promotionalText"] == entry["promotionalText"]
            galleries = [gallery(api, locale["id"], [s for s in entry["screenshots"] if s["device"] == device]) for device in ("iPhone", "iPad")]
            result["locales"].append({"locale": entry["locale"], "promotionalTextVerified": True, "galleries": galleries})
            REPORT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
            print(f"Verified {campaign} {entry['locale']}: six screenshots", flush=True)


if __name__ == "__main__":
    main()

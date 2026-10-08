"""Save three localized CPP drafts with verified galleries; never submit review.

Uses Apple's public App Store Connect API and existing GitHub secrets. Preserves
unexpected assets rather than deleting them. A rerun reuses pages and checksums.
"""
import hashlib
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from configure_iap import AppleAPI, APP_ID, ROOT, relationship, resource
import time
import threading
import urllib.parse
import urllib.request

ASSETS = ROOT / "Marketing/CustomProductPages"
REPORT = ROOT / ".build/custom-product-pages-status.json"


RECEIPTS_PATH = ROOT / "Docs/Store/CustomProductPages/upload-receipts.json"
receipts = json.loads(RECEIPTS_PATH.read_text(encoding="utf-8")) if RECEIPTS_PATH.exists() else {}
receipt_lock = threading.Lock()


def transfer(api, set_id, file):
    content = file.read_bytes()
    checksum = hashlib.md5(content).hexdigest()
    asset = api.call("POST", "/v1/appScreenshots", {"data": {
        "type": "appScreenshots", "attributes": {"fileName": file.name, "fileSize": len(content)},
        "relationships": {"appScreenshotSet": relationship("appScreenshotSets", set_id)}}})["data"]
    with receipt_lock:
        receipts[asset["id"]] = checksum
        (ROOT / ".build/upload-receipts.json").write_text(json.dumps(receipts, indent=2), encoding="utf-8")
    for operation in asset["attributes"]["uploadOperations"]:
        if urllib.parse.urlparse(operation["url"]).scheme != "https":
            raise RuntimeError("Apple asset transfer must use HTTPS")
        headers = {h["name"]: h["value"] for h in operation["requestHeaders"]}
        chunk = content[operation["offset"]:operation["offset"] + operation["length"]]
        request = urllib.request.Request(operation["url"], data=chunk, method=operation["method"], headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                response.read()
        except Exception:
            raise RuntimeError("Asset transfer failed; signed URL omitted") from None
    api.call("PATCH", f"/v1/appScreenshots/{asset['id']}", {"data": {
        **resource("appScreenshots", asset["id"]), "attributes": {"uploaded": True, "sourceFileChecksum": checksum}}})
    print(f"Transferred screenshot {asset['id']}; awaiting Apple processing", flush=True)
    return asset


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
    def identity(asset):
        checksum = asset["attributes"].get("sourceFileChecksum")
        return checksum if checksum is not None else receipts.get(asset["id"])
    if any(identity(s) not in expected for s in existing):
        raise RuntimeError("Unexpected existing screenshot preserved; manual reconciliation needed")
    ordered = []
    for (file, _), checksum in zip(files, expected):
        match = next((s for s in existing if identity(s) == checksum), None)
        asset = match if match else transfer(api, current["id"], file)
        ordered.append(asset["id"])
    return {"display": display, "setID": current["id"], "count": 3,
            "expectedChecksums": expected, "assetIDs": ordered, "checksumsVerified": False, "ordered": False}


def verify_gallery(gallery):
    if gallery["checksumsVerified"]:
        return True
    api = AppleAPI()
    actual = api.all(f"/v1/appScreenshotSets/{gallery['setID']}/appScreenshots?limit=200")
    if any(s["attributes"].get("assetDeliveryState", {}).get("state") == "FAILED" for s in actual):
        raise RuntimeError("Apple rejected an image; preserving it for diagnosis")
    if not all(s["attributes"].get("assetDeliveryState", {}).get("state") == "COMPLETE" for s in actual):
        return False
    assert {s["id"] for s in actual} == set(gallery["assetIDs"])
    checksums = {s["id"]: s["attributes"].get("sourceFileChecksum") for s in actual}
    assert [checksums[i] for i in gallery["assetIDs"]] == gallery["expectedChecksums"]
    api.call("PATCH", f"/v1/appScreenshotSets/{gallery['setID']}/relationships/appScreenshots", {
        "data": [resource("appScreenshots", i) for i in gallery["assetIDs"]]})
    saved = api.all(f"/v1/appScreenshotSets/{gallery['setID']}/appScreenshots?limit=200")
    assert [s["id"] for s in saved] == gallery["assetIDs"]
    gallery.update(checksumsVerified=True, ordered=True)
    return True


def main():
    api = AppleAPI()
    manifest = json.loads((ASSETS / "manifest.json").read_text(encoding="utf-8"))
    report = {"appID": APP_ID, "reviewSubmitted": False, "keywordsAssigned": False, "campaigns": []}
    REPORT.parent.mkdir(exist_ok=True)
    pages = api.all(f"/v1/apps/{APP_ID}/appCustomProductPages?limit=200")
    for campaign in sorted({e["id"] for e in manifest["campaigns"]}):
        api = AppleAPI()
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
        def save_entry(entry):
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
            return {"locale": entry["locale"], "promotionalTextVerified": True, "galleries": galleries}
        with ThreadPoolExecutor(max_workers=4) as executor:
            futures = {executor.submit(save_entry, e): e for e in entries}
            for future in as_completed(futures):
                try:
                    saved_locale = future.result()
                except Exception:
                    for queued in futures:
                        queued.cancel()
                    raise
                result["locales"].append(saved_locale)
                REPORT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
                print(f"Transferred {campaign} {saved_locale['locale']}: six screenshots; delivery not yet verified", flush=True)
    galleries = [g for c in report["campaigns"] for l in c["locales"] for g in l["galleries"]]
    deadline = time.monotonic() + 1800
    while True:
        with ThreadPoolExecutor(max_workers=8) as executor:
            completed = sum(executor.map(verify_gallery, galleries))
        REPORT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"Apple delivery verified: {completed}/{len(galleries)} galleries", flush=True)
        if completed == len(galleries):
            break
        if time.monotonic() >= deadline:
            raise RuntimeError("Apple processing remains pending; preserve receipts and rerun verification")
        time.sleep(15)



if __name__ == "__main__":
    main()

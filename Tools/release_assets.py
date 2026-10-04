"""Inspect release readiness and refresh verified screenshots. Never submits review.

Apple protocol: developer.apple.com/documentation/appstoreconnectapi/uploading-assets-to-app-store-connect
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
import time
import urllib.parse
import urllib.request
from configure_iap import AppleAPI, APP_ID, ROOT, resource, relationship


def wait_asset(api, identifier):
    for _ in range(36):
        asset = api.call("GET", f"/v1/appScreenshots/{identifier}")["data"]
        state = asset["attributes"].get("assetDeliveryState", {}).get("state")
        if state == "COMPLETE":
            return asset
        if state == "FAILED":
            raise RuntimeError("Apple rejected a screenshot; no completion claimed")
        time.sleep(5)
    raise RuntimeError("Screenshot still processing; rerun to verify")


def upload(api, set_id, file):
    content = file.read_bytes()
    checksum = hashlib.md5(content).hexdigest()  # Required Apple transport checksum.
    asset = api.call("POST", "/v1/appScreenshots", {"data": {
        "type": "appScreenshots", "attributes": {"fileName": file.name, "fileSize": len(content)},
        "relationships": {"appScreenshotSet": relationship("appScreenshotSets", set_id)}}})["data"]
    for operation in asset["attributes"]["uploadOperations"]:
        url = urllib.parse.urlparse(operation["url"])
        if url.scheme != "https":
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
        **resource("appScreenshots", asset["id"]),
        "attributes": {"uploaded": True, "sourceFileChecksum": checksum}}})
    return wait_asset(api, asset["id"])


def refresh(api, localization, display, directory):
    manifest = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
    shots = sorted(manifest["screenshots"], key=lambda s: s["order"])
    assert len(shots) == 10 and [s["order"] for s in shots] == list(range(1, 11))
    expected = []
    for shot in shots:
        file = directory / shot["file"]
        assert file.parent == directory and file.suffix == ".png"
        content = file.read_bytes()
        assert content[:8] == b'\x89PNG\r\n\x1a\n'
        size = struct.unpack('>II', content[16:24])
        assert size == ((1320, 2868) if display == 'APP_IPHONE_67' else (2064, 2752))
        assert content[25] == 2, "Opaque RGB PNGs are required"
        assert hashlib.sha256(content).hexdigest() == shot["exportSHA256"]
        expected.append((file, hashlib.md5(content).hexdigest()))
    sets = api.all(f"/v1/appStoreVersionLocalizations/{localization}/appScreenshotSets?limit=200")
    current = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == display), None)
    if current is None:
        current = api.call("POST", "/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display},
            "relationships": {"appStoreVersionLocalization": relationship("appStoreVersionLocalizations", localization)}}})["data"]
    set_id = current["id"]
    existing = api.all(f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=200")
    # Save only non-sensitive IDs/checksums. Original gallery files are preserved in Git.
    backup = [{"id": s["id"], "checksum": s["attributes"].get("sourceFileChecksum")} for s in existing]
    Path(".build").mkdir(exist_ok=True)
    Path(f".build/gallery-before-{display}.json").write_text(json.dumps(backup, indent=2))
    ordered = []
    wanted = {checksum for _, checksum in expected}
    for file, checksum in expected:
        match = next((s for s in existing if s["attributes"].get("sourceFileChecksum") == checksum), None)
        if match is not None:
            ordered.append(wait_asset(api, match["id"])["id"])
            continue
        # Apple limits a display set to ten assets. Free only one obsolete slot at a time.
        if len(existing) >= 10:
            obsolete = next((s for s in existing if s["attributes"].get("sourceFileChecksum") not in wanted), None)
            if obsolete is None:
                raise RuntimeError("No obsolete screenshot slot; preserving gallery")
            api.call("DELETE", f"/v1/appScreenshots/{obsolete['id']}")
            existing.remove(obsolete)
        # Interrupted reservations from a prior run are obsolete on the next run.
        asset = upload(api, set_id, file)
        existing.append(asset)
        ordered.append(asset["id"])
    for old in existing:
        if old["id"] not in ordered:
            api.call("DELETE", f"/v1/appScreenshots/{old['id']}")
    api.call("PATCH", f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots", {
        "data": [resource("appScreenshots", i) for i in ordered]})
    actual = api.all(f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=200")
    assert [s["id"] for s in actual] == ordered
    assert [s["attributes"].get("sourceFileChecksum") for s in actual] == [c for _, c in expected]
    assert all(s["attributes"].get("assetDeliveryState", {}).get("state") == "COMPLETE" for s in actual)
    return {"display": display, "setID": set_id, "count": len(actual), "ordered": True, "checksumsVerified": True}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--upload", action="store_true")
    parser.add_argument("--prepare-testflight", action="store_true")
    parser.add_argument("--build", required=True, help="Processed release build already attached to version 1.0")
    args = parser.parse_args()
    api = AppleAPI()
    versions = api.all(f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200")
    version = next(v for v in versions if v["attributes"]["versionString"] == "1.0")
    build = api.call("GET", f"/v1/appStoreVersions/{version['id']}/build")["data"]
    assert build["attributes"]["version"] == args.build and build["attributes"]["processingState"] == "VALID"
    locales = api.all(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=200")
    primary = next(l for l in locales if l["attributes"]["locale"] == "en-GB")
    report = {"appID": APP_ID, "version": "1.0", "build": args.build, "buildID": build["id"],
              "versionState": version["attributes"]["appStoreState"], "locales": [], "galleries": [], "betaGroups": []}
    for locale in locales:
        attrs = locale["attributes"]
        report["locales"].append({"locale": attrs["locale"], "descriptionSaved": bool(attrs.get("description")),
                                 "keywordsSaved": bool(attrs.get("keywords")), "supportURLSaved": bool(attrs.get("supportUrl"))})
    review = api.call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreReviewDetail", missing=True)
    attrs = review["data"]["attributes"] if review and review.get("data") else {}
    report["reviewMetadata"] = {"notesSaved": bool(attrs.get("notes")),
        "contactSaved": all(bool(attrs.get(field)) for field in ["contactFirstName", "contactLastName", "contactEmail", "contactPhone"]),
        "demoAccountRequired": attrs.get("demoAccountRequired")}
    infos = api.all(f"/v1/apps/{APP_ID}/appInfos?limit=200")
    info = next((i for i in infos if i["attributes"].get("appStoreState") == report["versionState"]), infos[0])
    report["appInfoLocales"] = []
    for item in api.all(f"/v1/appInfos/{info['id']}/appInfoLocalizations?limit=200"):
        attrs = item["attributes"]
        report["appInfoLocales"].append({"locale": attrs["locale"], "nameSaved": bool(attrs.get("name")),
            "subtitleSaved": bool(attrs.get("subtitle")), "privacyPolicyURLSaved": bool(attrs.get("privacyPolicyUrl"))})
    if args.upload:
        assert report["versionState"] == "PREPARE_FOR_SUBMISSION", "Preserving version in review"
        for display, folder in [("APP_IPHONE_67", "en-GB"), ("APP_IPAD_PRO_3GEN_129", "iPad-en-GB")]:
            report["galleries"].append(refresh(api, primary["id"], display, ROOT / "Docs/Store/Screenshots" / folder))
    else:
        for group in api.all(f"/v1/appStoreVersionLocalizations/{primary['id']}/appScreenshotSets?limit=200"):
            shots = api.all(f"/v1/appScreenshotSets/{group['id']}/appScreenshots?limit=200")
            report["galleries"].append({"display": group["attributes"]["screenshotDisplayType"], "setID": group["id"], "count": len(shots)})
    groups = api.all(f"/v1/apps/{APP_ID}/betaGroups?limit=200")
    if args.prepare_testflight:
        group = next((g for g in groups if g["attributes"]["isInternalGroup"] and g["attributes"]["name"] == "Scrap Squad QA"), None)
        if group is None:
            group = api.call("POST", "/v1/betaGroups", {"data": {
                "type": "betaGroups", "attributes": {"name": "Scrap Squad QA", "isInternalGroup": True},
                "relationships": {"app": relationship("apps", APP_ID)}}})["data"]
            groups.append(group)
        testers = api.all(f"/v1/betaGroups/{group['id']}/betaTesters?limit=200")
        if testers:
            raise RuntimeError("Preserving existing testers; no notification or invitation authorized")
        available = api.all(f"/v1/betaGroups/{group['id']}/builds?limit=200")
        if not any(b["id"] == build["id"] for b in available):
            api.call("POST", f"/v1/betaGroups/{group['id']}/relationships/builds", {"data": [resource("builds", build["id"])]})
        notes = (ROOT / "Docs/TESTFLIGHT_NOTES.txt").read_text(encoding="utf-8").strip()
        assert 0 < len(notes) <= 4000
        existing = api.all(f"/v1/builds/{build['id']}/betaBuildLocalizations?limit=200")
        primary_notes = next((n for n in existing if n["attributes"]["locale"] == "en-GB"), None)
        if primary_notes:
            api.call("PATCH", f"/v1/betaBuildLocalizations/{primary_notes['id']}", {"data": {
                **resource("betaBuildLocalizations", primary_notes["id"]), "attributes": {"whatsNew": notes}}})
        else:
            api.call("POST", "/v1/betaBuildLocalizations", {"data": {
                "type": "betaBuildLocalizations", "attributes": {"locale": "en-GB", "whatsNew": notes},
                "relationships": {"build": relationship("builds", build["id"])}}})
        actual = api.all(f"/v1/builds/{build['id']}/betaBuildLocalizations?limit=200")
        report["testingNotesSaved"] = any(n["attributes"].get("whatsNew") == notes and n["attributes"]["locale"] == "en-GB" for n in actual)
        assert report["testingNotesSaved"]
    for group in groups:
        builds = api.all(f"/v1/betaGroups/{group['id']}/builds?limit=200")
        testers = api.all(f"/v1/betaGroups/{group['id']}/betaTesters?limit=200")
        report["betaGroups"].append({"id": group["id"], "internal": group["attributes"]["isInternalGroup"],
            "requestedBuildAvailable": any(b["id"] == build["id"] for b in builds), "testerCount": len(testers)})
    report["betaState"] = api.call("GET", f"/v1/builds/{build['id']}/buildBetaDetail")["data"]["attributes"]
    Path(".build").mkdir(exist_ok=True)
    Path(".build/release-readiness.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Saved non-sensitive release-readiness report; no invitations, review or release performed.")


if __name__ == "__main__":
    main()

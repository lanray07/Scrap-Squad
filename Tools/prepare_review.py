"""Verify build 15 and first-purchase readiness; save current reviewer notes.

First IAP submission requires App Store Connect's website. This tool never
submits a review, accepts an agreement, or changes release/pricing settings.
"""
import json
from datetime import datetime, timezone
from pathlib import Path
from configure_iap import APP_ID, ROOT, AppleAPI, resource


def main():
    api = AppleAPI()
    versions = api.all(f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200")
    version = next(v for v in versions if v["attributes"]["versionString"] == "1.0")
    build = api.call("GET", f"/v1/appStoreVersions/{version['id']}/build")["data"]
    assert build["id"] == "7ea3098a-d081-47eb-9c78-da7c4d182b9f"
    assert build["attributes"]["version"] == "15" and build["attributes"]["processingState"] == "VALID"
    expected = json.loads((ROOT / "Docs/PremiumShop/app-store-status.json").read_text(encoding="utf-8"))["products"]
    products = []
    for p in expected:
        actual = api.call("GET", f"/v2/inAppPurchases/{p['id']}")["data"]
        assert actual["attributes"]["productId"] == p["productID"]
        assert actual["attributes"]["inAppPurchaseType"] == "NON_CONSUMABLE"
        asset = api.call("GET", f"/v2/inAppPurchases/{p['id']}/appStoreReviewScreenshot")["data"]
        assert asset["attributes"]["assetDeliveryState"]["state"] == "COMPLETE"
        locales = api.all(f"/v2/inAppPurchases/{p['id']}/inAppPurchaseLocalizations?limit=200")
        assert len(locales) == 11
        products.append({"id": p["id"], "productID": p["productID"], "state": actual["attributes"]["state"],
                         "reviewScreenshotComplete": True, "localizationCount": len(locales)})
    assert len(products) == 7
    detail = api.call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreReviewDetail")["data"]
    notes = (ROOT / "Docs/Store/REVIEW_NOTES.txt").read_text(encoding="utf-8").strip()
    assert 0 < len(notes) <= 4000
    editable = version["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"
    if editable:
        api.call("PATCH", f"/v1/appStoreReviewDetails/{detail['id']}", {"data": {
            **resource("appStoreReviewDetails", detail["id"]),
            "attributes": {"notes": notes, "demoAccountRequired": False}}})
        detail = api.call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreReviewDetail")["data"]
        assert detail["attributes"]["notes"] == notes
    submissions = api.all(f"/v1/apps/{APP_ID}/reviewSubmissions?limit=200")
    attrs = detail["attributes"]
    report = {"checkedAt": datetime.now(timezone.utc).isoformat(), "appID": APP_ID,
              "versionID": version["id"], "version": "1.0", "build": "15", "buildID": build["id"],
              "versionState": version["attributes"]["appStoreState"],
              "releaseType": version["attributes"].get("releaseType"), "products": products,
              "reviewNotesCurrent": attrs.get("notes") == notes,
              "reviewContactPresent": all(attrs.get(k) for k in ["contactFirstName", "contactLastName", "contactPhone", "contactEmail"]),
              "demoAccountRequired": attrs.get("demoAccountRequired"),
              "submissions": [{"id": s["id"], "state": s["attributes"].get("state"),
                               "platform": s["attributes"].get("platform")} for s in submissions],
              "submissionPerformedByThisTool": False}
    Path(".build").mkdir(exist_ok=True)
    Path(".build/review-preflight.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()

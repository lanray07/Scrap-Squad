"""Idempotent App Store cosmetic metadata setup. Never submits review or accepts agreements."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request

APP_ID = "6818847887"
BASE = "https://api.appstoreconnect.apple.com"
LOCALES = ["en-GB", "es-ES", "fr-FR", "de-DE", "it", "pt-PT", "pt-BR", "ja", "ko", "zh-Hans", "zh-Hant"]
ROOT = Path(__file__).resolve().parents[1]

def resource(kind, identifier):
    return {"type": kind, "id": identifier}

def relationship(kind, identifier):
    return {"data": resource(kind, identifier)}

class AppleAPI:
    def __init__(self):
        import jwt
        key = os.environ["ASC_PRIVATE_KEY"].strip().replace("\\n", "\n")
        if not key.startswith("-----BEGIN"):
            key = base64.b64decode(key).decode()
        now = int(time.time())
        self.token = jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now,
            "exp": now + 1190, "aud": "appstoreconnect-v1"}, key, algorithm="ES256",
            headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})

    def call(self, method, path, body=None, missing=False):
        url = path if path.startswith("https://") else BASE + path
        if urllib.parse.urlparse(url).netloc != "api.appstoreconnect.apple.com":
            raise RuntimeError("Refusing to send Apple authentication to another host")
        payload = json.dumps(body).encode() if body is not None else None
        for attempt in range(5):
            request = urllib.request.Request(url, data=payload, method=method,
                headers={"Authorization": "Bearer " + self.token, "Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(request, timeout=45) as response:
                    data = response.read()
                    return json.loads(data) if data else {}
            except urllib.error.HTTPError as error:
                if missing and error.code == 404:
                    return None
                if method == "GET" and error.code in (429, 500, 502, 503, 504) and attempt < 4:
                    time.sleep(2 ** (attempt + 1)); continue
                # Never log JWTs, keys, pre-signed asset URLs or full response objects.
                try:
                    codes = [item.get("code", "unknown") for item in json.loads(error.read()).get("errors", [])]
                except Exception:
                    codes = []
                raise RuntimeError(f"Apple {method} {urllib.parse.urlparse(url).path}: HTTP {error.code}, codes={codes}") from None

    def all(self, path):
        result = []
        while path:
            page = self.call("GET", path)
            result.extend(page["data"])
            path = page.get("links", {}).get("next")
        return result

def set_price(api, identifier, price):
    schedule = api.call("GET", f"/v2/inAppPurchases/{identifier}/iapPriceSchedule?include=baseTerritory", missing=True)
    if schedule and schedule.get("data"):
        current = schedule["data"]
        base = current.get("relationships", {}).get("baseTerritory", {}).get("data", {}).get("id")
        manual = api.call("GET", f"/v1/inAppPurchasePriceSchedules/{current['id']}/manualPrices?filter[territory]=GBR&include=inAppPurchasePricePoint&limit=200")
        point_prices = {p["id"]: p["attributes"]["customerPrice"] for p in manual.get("included", []) if p["type"] == "inAppPurchasePricePoints"}
        active = [p for p in manual["data"] if not p["attributes"].get("endDate")]
        if base == "GBR" and any(point_prices.get(p["relationships"]["inAppPurchasePricePoint"]["data"]["id"]) == price for p in active):
            return
    points = api.all(f"/v2/inAppPurchases/{identifier}/pricePoints?filter[territory]=GBR&limit=8000")
    point = next((p for p in points if p["attributes"]["customerPrice"] == price), None)
    if point is None:
        raise RuntimeError(f"No exact GBP price point {price}; refusing to choose another price")
    inline = "${base-price}"
    api.call("POST", "/v1/inAppPurchasePriceSchedules", {"data": {"type": "inAppPurchasePriceSchedules", "relationships": {
        "inAppPurchase": relationship("inAppPurchases", identifier), "baseTerritory": relationship("territories", "GBR"),
        "manualPrices": {"data": [resource("inAppPurchasePrices", inline)]}}},
        "included": [{"type": "inAppPurchasePrices", "id": inline, "attributes": {"startDate": None, "endDate": None},
            "relationships": {"inAppPurchaseV2": relationship("inAppPurchases", identifier),
                "inAppPurchasePricePoint": relationship("inAppPurchasePricePoints", point["id"])}}]})

def set_availability(api, identifier, territories):
    existing = api.call("GET", f"/v2/inAppPurchases/{identifier}/inAppPurchaseAvailability", missing=True)
    if existing and existing.get("data"):
        availability = existing["data"]
        actual = api.all(f"/v1/inAppPurchaseAvailabilities/{availability['id']}/availableTerritories?limit=200")
        if {t["id"] for t in actual} == territories and not availability["attributes"]["availableInNewTerritories"]:
            return
        raise RuntimeError("Existing availability differs from the approved regions; refusing an unreviewed override")
    api.call("POST", "/v1/inAppPurchaseAvailabilities", {"data": {"type": "inAppPurchaseAvailabilities",
        "attributes": {"availableInNewTerritories": False}, "relationships": {
            "inAppPurchase": relationship("inAppPurchases", identifier),
            "availableTerritories": {"data": [resource("territories", t) for t in sorted(territories)]}}}})

def upload_review(api, identifier, file):
    contents = file.read_bytes()
    checksum = hashlib.md5(contents).hexdigest()  # Apple's upload protocol requires MD5, not a security signature.
    existing = api.call("GET", f"/v2/inAppPurchases/{identifier}/appStoreReviewScreenshot", missing=True)
    if existing and existing.get("data"):
        asset = existing["data"]
        if asset["attributes"].get("sourceFileChecksum") == checksum and asset["attributes"].get("assetDeliveryState", {}).get("state") == "COMPLETE":
            return
        raise RuntimeError("A different review screenshot already exists; preserve it for explicit review")
    asset = api.call("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots", {"data": {
        "type": "inAppPurchaseAppStoreReviewScreenshots", "attributes": {"fileName": file.name, "fileSize": len(contents)},
        "relationships": {"inAppPurchaseV2": relationship("inAppPurchases", identifier)}}})["data"]
    for operation in asset["attributes"]["uploadOperations"]:
        if urllib.parse.urlparse(operation["url"]).scheme != "https":
            raise RuntimeError("Asset upload must use HTTPS")
        chunk = contents[operation["offset"]:operation["offset"] + operation["length"]]
        headers = {h["name"]: h["value"] for h in operation["requestHeaders"]}
        request = urllib.request.Request(operation["url"], data=chunk, method=operation["method"], headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                response.read()
        except Exception:
            raise RuntimeError("Apple image transfer failed; pre-signed URL omitted") from None
    api.call("PATCH", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{asset['id']}", {"data": {
        **resource("inAppPurchaseAppStoreReviewScreenshots", asset["id"]), "attributes": {"uploaded": True, "sourceFileChecksum": checksum}}})
    for _ in range(24):
        state = api.call("GET", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{asset['id']}")["data"]["attributes"].get("assetDeliveryState", {}).get("state")
        if state == "COMPLETE":
            return
        if state == "FAILED":
            raise RuntimeError("Apple rejected the review screenshot")
        time.sleep(5)
    raise RuntimeError("Review screenshot is still processing; do not claim completion")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--complete", action="store_true")
    parser.add_argument("--build", help="Processed build number required with --complete")
    args = parser.parse_args()
    if args.complete and not args.build:
        parser.error("--complete requires an explicit --build number")
    copy = json.loads((ROOT / "Docs/Store/IAP/localizations.json").read_text(encoding="utf-8"))
    assert len(copy) == len(LOCALES)
    for row in copy:
        assert len(row[1]) <= 35 and len(row[3]) <= 35 and len(row[2]) <= 55 and len(row[4]) <= 55
    if args.complete:
        for name in ["IAP-01-founder-review.png", "IAP-04-styles-review.png"]:
            assert (ROOT / "Docs/Store/IAP" / name).is_file(), "Actual UI-test screenshots are required"
    api = AppleAPI()
    existing = {p["attributes"]["productId"]: p for p in api.all(f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200")}
    territories = {t["id"] for t in api.all("/v1/territories?limit=200")} - {"CHN", "VNM"}
    assert len(territories) == 173, "Review any change in Apple's territory list before expanding availability"
    notes = [
        "Complete onboarding and open Shop. Founder’s Pack is a one-time non-consumable: Founder’s Gold BOLT finish, golden weapon trails and a Founder badge. Tap Equip and enable the two switches after purchase. Finish: Squad and battles; badge: Squad. Restore purchases: bottom of Shop. No power, currency, progression, robot unlock or reward bonuses. No subscription. All cosmetic content is bundled.",
        "Complete onboarding and open Shop. Robot Style Pack is a one-time non-consumable with Aurora BOLT, Cobalt TANK and Rose PATCH finishes. After purchase tap Equip beside each finish; tap Remove to restore its original appearance. TANK and PATCH must still be unlocked through normal gameplay. Finishes are visible in Squad and battles. Restore purchases is at the bottom of Shop. No power, currency, progression or reward bonuses. No subscription. All content is bundled."]
    report = {"appID": APP_ID, "regions": len(territories), "excluded": ["CHN", "VNM"], "products": [], "submittedForReview": False}
    for index, suffix in enumerate(["founder", "styles"]):
        product_id = f"com.ScrapSquad.app.{suffix}"
        name_col, desc_col = (1, 2) if index == 0 else (3, 4)
        name, price = copy[0][name_col], ["2.99", "1.99"][index]
        product = existing.get(product_id)
        if product is None:
            product = api.call("POST", "/v2/inAppPurchases", {"data": {"type": "inAppPurchases",
                "attributes": {"name": name, "productId": product_id, "inAppPurchaseType": "NON_CONSUMABLE", "reviewNote": notes[index], "familySharable": False},
                "relationships": {"app": relationship("apps", APP_ID)}}})["data"]
        identifier = product["id"]
        assert product["attributes"]["inAppPurchaseType"] == "NON_CONSUMABLE"
        api.call("PATCH", f"/v2/inAppPurchases/{identifier}", {"data": {**resource("inAppPurchases", identifier),
            "attributes": {"name": name, "reviewNote": notes[index]}}})
        local = {p["attributes"]["locale"]: p for p in api.all(f"/v2/inAppPurchases/{identifier}/inAppPurchaseLocalizations?limit=200")}
        for locale, row in zip(LOCALES, copy):
            attributes = {"name": row[name_col], "description": row[desc_col]}
            if locale in local:
                if all(local[locale]["attributes"].get(k) == v for k, v in attributes.items()):
                    continue
                lid = local[locale]["id"]
                api.call("PATCH", f"/v1/inAppPurchaseLocalizations/{lid}", {"data": {**resource("inAppPurchaseLocalizations", lid), "attributes": attributes}})
            else:
                api.call("POST", "/v1/inAppPurchaseLocalizations", {"data": {"type": "inAppPurchaseLocalizations",
                    "attributes": {**attributes, "locale": locale}, "relationships": {"inAppPurchaseV2": relationship("inAppPurchases", identifier)}}})
        set_price(api, identifier, price)
        set_availability(api, identifier, territories)
        if args.complete:
            upload_review(api, identifier, ROOT / "Docs/Store/IAP" / ["IAP-01-founder-review.png", "IAP-04-styles-review.png"][index])
        report["products"].append({"id": identifier, "productID": product_id, "name": name, "baseCurrency": "GBP", "basePrice": price, "locales": LOCALES, "reviewScreenshotUploaded": args.complete})
        print(f"Configured {name}: GBP {price}, {len(LOCALES)} locales, {len(territories)} regions")
    if args.complete:
        builds = api.all(f"/v1/builds?filter[app]={APP_ID}&filter[version]={args.build}&limit=200")
        build = next((b for b in builds if b["attributes"].get("processingState") == "VALID"), None)
        assert build is not None, "Requested build has not finished Apple processing"
        versions = api.all(f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]=1.0&limit=200")
        version = next(v for v in versions if v["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION")
        api.call("PATCH", f"/v1/appStoreVersions/{version['id']}/relationships/build", {"data": resource("builds", build["id"])})
        assert api.call("GET", f"/v1/appStoreVersions/{version['id']}/relationships/build")["data"]["id"] == build["id"]
        report["attachedBuild"] = {"version": args.build, "id": build["id"]}
    out = ROOT / ".build/iap-status.json"
    out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

if __name__ == "__main__":
    main()

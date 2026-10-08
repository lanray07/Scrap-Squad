"""Read-only CPP image delivery diagnostics; excludes credentials and transfer URLs."""
import json
from concurrent.futures import ThreadPoolExecutor
from configure_iap import AppleAPI, APP_ID, ROOT

api = AppleAPI()
report = {"appID": APP_ID, "readOnly": True, "campaigns": []}
pages = api.all(f"/v1/apps/{APP_ID}/appCustomProductPages?limit=200")
for page in pages:
    versions = api.all(f"/v1/appCustomProductPages/{page['id']}/appCustomProductPageVersions?limit=200")
    for version in versions:
        locales = api.all(f"/v1/appCustomProductPageVersions/{version['id']}/appCustomProductPageLocalizations?limit=200")
        def inspect(locale):
            client = AppleAPI()
            sets = client.all(f"/v1/appCustomProductPageLocalizations/{locale['id']}/appScreenshotSets?limit=200")
            galleries = []
            for gallery in sets:
                shots = client.all(f"/v1/appScreenshotSets/{gallery['id']}/appScreenshots?limit=200")
                galleries.append({"display": gallery['attributes']['screenshotDisplayType'], "assets": [
                    {"id": s['id'], "file": s['attributes'].get('fileName'), "checksum": s['attributes'].get('sourceFileChecksum'), "delivery": s['attributes'].get('assetDeliveryState')} for s in shots]})
            return {"locale": locale['attributes']['locale'], "galleries": galleries}
        with ThreadPoolExecutor(max_workers=8) as pool:
            result = list(pool.map(inspect, locales))
        report['campaigns'].append({"name":page['attributes']['name'],"versionID":version['id'],"locales":result})
        print(page['attributes']['name'], [(r['locale'], [len(g['assets']) for g in r['galleries']]) for r in result], flush=True)
out=ROOT/'.build/custom-product-pages-status.json'
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')

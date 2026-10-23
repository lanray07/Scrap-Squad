#!/bin/bash
# Separate developer-signed automation helper. Does not build, install or upload the game.
set -euo pipefail
python3 -m venv "$RUNNER_TEMP/device-helper-env"
"$RUNNER_TEMP/device-helper-env/bin/pip" -q install PyJWT cryptography
PYTHONPATH=Tools "$RUNNER_TEMP/device-helper-env/bin/python" - <<'PY'
import base64, os, pathlib, urllib.parse
from configure_iap import AppleAPI
udid = os.environ['QA_DEVICE_UDID'].strip()
assert udid and len(udid) < 60
api = AppleAPI()
devices = api.all('/v1/devices?filter[udid]=' + urllib.parse.quote(udid) + '&limit=200')
if not devices:
    api.call('POST', '/v1/devices', {'data': {'type': 'devices', 'attributes': {
        'name': 'Scrap Squad physical QA iPad', 'platform': 'IOS', 'udid': udid}}})
elif devices[0]['attributes']['status'] != 'ENABLED':
    raise RuntimeError('QA device is disabled; refusing to change its registration')
key = os.environ['ASC_PRIVATE_KEY'].strip().replace('\\n', '\n')
if not key.startswith('-----BEGIN'):
    key = base64.b64decode(key).decode()
path = pathlib.Path(os.environ['RUNNER_TEMP']) / 'DeviceHelperAuth.p8'
path.write_text(key + '\n'); path.chmod(0o600)
print('QA device registration verified; private identifiers omitted')
PY
git clone --quiet --depth 1 --branch v16.15.3 https://github.com/appium/WebDriverAgent.git "$RUNNER_TEMP/scrap-wda"
cd "$RUNNER_TEMP/scrap-wda"
xcodebuild build-for-testing -project WebDriverAgent.xcodeproj -scheme WebDriverAgentRunner \
  -destination 'generic/platform=iOS' -derivedDataPath "$RUNNER_TEMP/scrap-wda-build" \
  -allowProvisioningUpdates -authenticationKeyPath "$RUNNER_TEMP/DeviceHelperAuth.p8" \
  -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Automatic \
  CODE_SIGN_IDENTITY='Apple Development' \
  PRODUCT_BUNDLE_IDENTIFIER=com.ScrapSquad.DeviceTestRunner \
  > "$RUNNER_TEMP/device-helper-build.log" 2>&1 || {
    grep -E 'error:|BUILD FAILED|No profiles|No signing' "$RUNNER_TEMP/device-helper-build.log" | head -20
    exit 1
  }
cd "$GITHUB_WORKSPACE"
mkdir -p .build
ditto -c -k --sequesterRsrc --keepParent \
  "$RUNNER_TEMP/scrap-wda-build/Build/Products/Debug-iphoneos/WebDriverAgentRunner-Runner.app" \
  .build/device-helper.zip
echo 'Developer-signed helper packaged. No game binary or store submission changed.'

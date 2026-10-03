#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
family=${SIMULATOR_FAMILY:-iPhone}
result_name=${UI_RESULT_NAME:-ios-ui-tests}
device=$(xcrun simctl list devices available --json | SIMULATOR_FAMILY="$family" python3 -c '
import json,sys,os
devices=json.load(sys.stdin)["devices"]
for runtime in sorted(devices,reverse=True):
    if "iOS" not in runtime: continue
    for device in devices[runtime]:
        if device.get("isAvailable") and os.environ["SIMULATOR_FAMILY"] in device["name"]:
            print(device["udid"]); sys.exit(0)
sys.exit("No available requested simulator")
')
echo "Testing on simulator $device"
xcrun simctl boot "$device" || true
xcrun simctl bootstatus "$device" -b 2>&1 | tee .build/simulator-boot.log
xcodebuild -project ScrapSquad.xcodeproj -scheme ScrapSquad \
  -destination "platform=iOS Simulator,id=$device" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 90 \
  -maximum-test-execution-time-allowance 240 \
  -derivedDataPath .build/ios-derived \
  -resultBundlePath ".build/$result_name.xcresult" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test 2>&1 | tee ".build/$result_name.log"

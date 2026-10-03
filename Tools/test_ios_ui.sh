#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
device=$(xcrun simctl list devices available --json | python3 -c '
import json,sys
devices=json.load(sys.stdin)["devices"]
for runtime in sorted(devices,reverse=True):
    if "iOS" not in runtime: continue
    for device in devices[runtime]:
        if device.get("isAvailable") and "iPhone" in device["name"]:
            print(device["udid"]); sys.exit(0)
sys.exit("No available iPhone simulator")
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
  -maximum-test-execution-time-allowance 120 \
  -derivedDataPath .build/ios-derived \
  -resultBundlePath .build/ios-ui-tests.xcresult \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee .build/ios-ui-tests.log

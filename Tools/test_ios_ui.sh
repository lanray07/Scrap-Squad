#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
family=${SIMULATOR_FAMILY:-iPhone}
runtime_filter=${SIMULATOR_RUNTIME:-iOS-26-2}
result_name=${UI_RESULT_NAME:-ios-ui-tests}
if [ -n "${SIMULATOR_DEVICE_TYPE:-}" ]; then
  device=$(xcrun simctl create "Scrap Squad layout QA" "$SIMULATOR_DEVICE_TYPE" "com.apple.CoreSimulator.SimRuntime.$runtime_filter")
else
device=$(xcrun simctl list devices available --json | SIMULATOR_FAMILY="$family" SIMULATOR_RUNTIME="$runtime_filter" python3 -c '
import json,sys,os
devices=json.load(sys.stdin)["devices"]
for runtime in sorted(devices,reverse=True):
    if "iOS" not in runtime: continue
    if os.environ["SIMULATOR_RUNTIME"] and not runtime.endswith(os.environ["SIMULATOR_RUNTIME"]): continue
    for device in sorted(devices[runtime], key=lambda d: ("Pro Max" not in d["name"], d["name"])):
        if device.get("isAvailable") and os.environ["SIMULATOR_FAMILY"] in device["name"]:
            print(device["udid"]); sys.exit(0)
sys.exit("No available requested simulator/runtime. StoreKit CLI tests use iOS 26.2 to avoid the iOS 26.3-26.5 StoreKitTest configuration bug.")
')
fi
# Positional arguments also work with macOS Bash 3.2 and nounset when empty.
set --
if [ -n "${UI_TEST_CLASS:-}" ]; then
  set -- "-only-testing:ScrapSquadUITests/$UI_TEST_CLASS"
fi
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
  "$@" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test 2>&1 | tee ".build/$result_name.log"

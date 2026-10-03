#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift test
python3 Tools/localize.py audit
python3 -m unittest discover -s Tools -p 'test_localize.py'
python3 Tools/store_metadata.py
xcodegen generate
xcodebuild -project ScrapSquad.xcodeproj -scheme ScrapSquad \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/ios-derived \
  -resultBundlePath .build/ios-build.xcresult \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | tee .build/ios-build.log

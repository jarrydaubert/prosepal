#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_SCENARIO_COUNT=12
DESTINATION="${PROSEPAL_STOREKIT_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
TEMP_DIRECTORY="$(mktemp -d)"
RESULT_BUNDLE="${PROSEPAL_STOREKIT_RESULT_BUNDLE:-$TEMP_DIRECTORY/ProsePalStoreKitTests.xcresult}"
SUMMARY_PATH="$TEMP_DIRECTORY/summary.json"

cleanup() {
  rm -rf "$TEMP_DIRECTORY"
}
trap cleanup EXIT

if [[ -e "$RESULT_BUNDLE" ]]; then
  echo "StoreKit result bundle path already exists: $RESULT_BUNDLE" >&2
  exit 1
fi

set +e
xcodebuild \
  -project "$REPO_ROOT/prosepal-ios/ProsePal.xcodeproj" \
  -scheme "ProsePal Staging" \
  -destination "$DESTINATION" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -only-testing:ProsePalStoreKitTests/StoreKitSubscriptionClientStoreKitTests \
  test
xcode_status=$?
set -e

if [[ ! -d "$RESULT_BUNDLE" ]]; then
  echo "StoreKit release gate failed: xcodebuild produced no xcresult bundle." >&2
  exit 1
fi

if ! xcrun xcresulttool get test-results summary \
  --path "$RESULT_BUNDLE" \
  > "$SUMMARY_PATH"; then
  echo "StoreKit release gate failed: could not read the xcresult summary." >&2
  exit 1
fi

set +e
python3 "$REPO_ROOT/scripts/storekit_test_result_gate.py" \
  "$SUMMARY_PATH" \
  --expected-count "$EXPECTED_SCENARIO_COUNT"
gate_status=$?
set -e

if [[ $xcode_status -ne 0 || $gate_status -ne 0 ]]; then
  echo "StoreKit release gate remains open (xcodebuild=$xcode_status, result_gate=$gate_status)." >&2
  exit 1
fi

echo "StoreKit app-hosted release gate passed with zero failures and zero skips."

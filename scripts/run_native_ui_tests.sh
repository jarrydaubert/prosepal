#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUITE="${1:-smoke}"
DESTINATION="${PROSEPAL_UI_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=latest}"
TEMP_DIRECTORY="$(mktemp -d)"
DERIVED_DATA_PATH="${PROSEPAL_UI_TEST_DERIVED_DATA:-$TEMP_DIRECTORY/DerivedData}"
RESULT_BUNDLE="${PROSEPAL_UI_TEST_RESULT_BUNDLE:-$TEMP_DIRECTORY/ProsePalNativeUITests.xcresult}"

cleanup() {
  rm -rf "$TEMP_DIRECTORY"
}
trap cleanup EXIT

case "$SUITE" in
  smoke)
    TEST_SELECTION="ProsePalNativeUITests/ProsePalDurableSmokeUITests"
    ;;
  full)
    TEST_SELECTION="ProsePalNativeUITests"
    ;;
  *)
    echo "Usage: $0 [smoke|full]" >&2
    exit 2
    ;;
esac

if [[ -e "$RESULT_BUNDLE" ]]; then
  echo "UI-test result bundle path already exists: $RESULT_BUNDLE" >&2
  exit 1
fi

xcodebuild \
  -project "$REPO_ROOT/prosepal-ios/ProsePal.xcodeproj" \
  -scheme "ProsePal UI Tests" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -parallel-testing-enabled NO \
  -quiet \
  -only-testing:"$TEST_SELECTION" \
  test

echo "Native UI $SUITE suite passed."

#!/bin/bash
# Build the native ProsePal iOS app for the iOS Simulator.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/prosepal-ios"

cd "$APP_DIR"

swift build
xcodebuild -project ProsePal.xcodeproj \
  -target ProsePal \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  build

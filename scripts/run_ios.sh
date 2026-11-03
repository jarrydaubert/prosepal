#!/bin/bash
# Open the native ProsePal Xcode project.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/prosepal-ios/ProsePal.xcodeproj"

if [[ ! -e "$PROJECT/project.pbxproj" ]]; then
  echo "Native Xcode project is missing project.pbxproj: $PROJECT" >&2
  exit 1
fi

open "$PROJECT"

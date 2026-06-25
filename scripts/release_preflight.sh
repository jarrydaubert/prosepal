#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/release_preflight.sh native [--no-env-file]

Checks repo-level native iOS release invariants. Runtime secrets are configured
through Xcode schemes, App Store Connect, Supabase dashboard secrets, or the
guarded staging script; this script must not print or require secret values.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

TARGET="$1"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-env-file)
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$TARGET" != "native" ]]; then
  echo "Invalid target: $TARGET" >&2
  usage
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

require_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Missing required native path: $path" >&2
    exit 1
  fi
}

require_absent_tracked_path() {
  local path="$1"
  if git ls-files --error-unmatch "$path" >/dev/null 2>&1; then
    echo "Legacy path is still tracked: $path" >&2
    exit 1
  fi
}

require_path "prosepal-ios/Package.swift"
require_path "prosepal-ios/ProsePal.xcodeproj/project.pbxproj"
require_path "prosepal-ios/App/ProsePalNativeApp.swift"
require_path "docs/BACKLOG.md"
require_path "docs/NEXT_RELEASE_BRIEF.md"

require_absent_tracked_path "pubspec.yaml"
require_absent_tracked_path "analysis_options.yaml"
require_absent_tracked_path "lib/main.dart"
require_absent_tracked_path "ios/Runner.xcodeproj/project.pbxproj"
require_absent_tracked_path "android/app/build.gradle.kts"
require_absent_tracked_path "supabase/.temp/project-ref"

if git ls-files supabase/.temp supabase/.branches | grep -q .; then
  echo "Supabase CLI temp/link state is tracked. Remove it before release." >&2
  exit 1
fi

if grep -R "RevenueCat" prosepal-ios/Package.swift prosepal-ios/Sources >/dev/null 2>&1; then
  echo "Native app contains a RevenueCat reference; native direction is StoreKit 2." >&2
  exit 1
fi

echo "Native release preflight passed."

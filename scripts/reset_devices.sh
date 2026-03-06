#!/bin/bash
# Clean local artifacts and uninstall the app from tethered iOS/Android devices.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ANDROID_PACKAGE="com.prosepal.prosepal"
IOS_BUNDLE_ID="com.prosepal.prosepal"

DEEP=1
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./scripts/reset_devices.sh [options]

Options:
  --no-clean   Skip local cleanup
  --dry-run    Print actions without executing them
  -h, --help   Show help

Notes:
  - This script cleans local generated artifacts by default.
  - It uninstalls the app from the first tethered Android and iOS devices, if present.
  - It does not launch new flutter run sessions. Keep using separate terminals for:
      ./scripts/run_ios.sh
      ./scripts/run_android.sh
EOF
}

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
    return 0
  fi

  "$@"
}

find_adb() {
  local candidates=(
    "/opt/homebrew/share/android-commandlinetools/platform-tools/adb"
    "$HOME/Library/Android/sdk/platform-tools/adb"
    "/opt/homebrew/bin/adb"
    "/usr/local/bin/adb"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return 0
  fi

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-clean)
      DEEP=0
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

cd "$PROJECT_DIR"

if [[ "$DEEP" -eq 1 ]]; then
  echo "Cleaning local artifacts..."
  run_cmd ./scripts/cleanup.sh --deep
else
  echo "Skipping local cleanup."
fi

echo "Discovering devices..."
devices_output="$(flutter devices 2>/dev/null || true)"

android_device="$(printf '%s\n' "$devices_output" | grep -i "android" | head -1 | awk -F'•' '{print $2}' | xargs || true)"
ios_device="$(printf '%s\n' "$devices_output" | grep -i "iphone\|ipad" | head -1 | awk -F'•' '{print $2}' | xargs || true)"

if [[ -n "$android_device" ]]; then
  adb_bin="$(find_adb || true)"
  if [[ -n "$adb_bin" ]]; then
    echo "Uninstalling Android app from $android_device..."
    run_cmd "$adb_bin" -s "$android_device" uninstall "$ANDROID_PACKAGE" || true
  else
    echo "Android device detected ($android_device), but adb was not found on PATH or known SDK locations."
  fi
else
  echo "No tethered Android device detected."
fi

if [[ -n "$ios_device" ]]; then
  echo "Uninstalling iOS app from $ios_device..."
  run_cmd xcrun devicectl device uninstall app --device "$ios_device" "$IOS_BUNDLE_ID" || true
else
  echo "No tethered iOS device detected."
fi

echo
echo "Reset complete."
echo "Next steps:"
echo "  1. ./scripts/run_ios.sh"
echo "  2. ./scripts/run_android.sh"

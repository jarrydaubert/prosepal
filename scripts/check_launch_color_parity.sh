#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

declare -a FAILURES=()

fail() {
  FAILURES+=("$1")
}

uppercase_hex() {
  printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'
}

extract_flutter_background_hex() {
  local color_file expr alias resolved
  color_file="lib/shared/theme/app_colors.dart"

  expr="$(
    sed -nE 's/^[[:space:]]*static const Color background = ([^;]+);/\1/p' "$color_file" |
      head -n1 |
      tr -d '[:space:]'
  )"

  if [[ -z "$expr" ]]; then
    return 1
  fi

  if [[ "$expr" =~ Color\(0xFF([0-9A-Fa-f]{6})\) ]]; then
    uppercase_hex "${BASH_REMATCH[1]}"
    return 0
  fi

  if [[ "$expr" =~ ^([A-Za-z_][A-Za-z0-9_]*)$ ]]; then
    alias="${BASH_REMATCH[1]}"
    resolved="$(
      sed -nE "s/^[[:space:]]*static const Color ${alias} = Color\\(0xFF([0-9A-Fa-f]{6})\\);/\\1/p" "$color_file" |
        head -n1
    )"
    if [[ -n "$resolved" ]]; then
      uppercase_hex "$resolved"
      return 0
    fi
  fi

  return 1
}

extract_android_app_background_hex() {
  sed -nE 's/.*<color name="app_background">#([0-9A-Fa-f]{6})<\/color>.*/\1/p' \
    android/app/src/main/res/values/colors.xml |
    head -n1 |
    tr '[:lower:]' '[:upper:]'
}

extract_android_splash_value() {
  local file="$1"
  sed -nE 's/.*windowSplashScreenBackground">([^<]+)<\/item>.*/\1/p' "$file" |
    head -n1 |
    tr -d '[:space:]'
}

resolve_android_splash_hex() {
  local raw_value="$1"
  local app_background_hex="$2"

  if [[ "$raw_value" =~ ^#([0-9A-Fa-f]{6})$ ]]; then
    uppercase_hex "${BASH_REMATCH[1]}"
    return 0
  fi

  if [[ "$raw_value" == "@color/app_background" ]]; then
    printf '%s\n' "$app_background_hex"
    return 0
  fi

  return 1
}

extract_ios_storyboard_background_hex() {
  local line red green blue
  line="$(grep 'key="backgroundColor"' ios/Runner/Base.lproj/LaunchScreen.storyboard | head -n1 || true)"

  if [[ -z "$line" ]]; then
    return 1
  fi

  red="$(printf '%s\n' "$line" | sed -nE 's/.*red="([^"]+)".*/\1/p')"
  green="$(printf '%s\n' "$line" | sed -nE 's/.*green="([^"]+)".*/\1/p')"
  blue="$(printf '%s\n' "$line" | sed -nE 's/.*blue="([^"]+)".*/\1/p')"

  if [[ -z "$red" || -z "$green" || -z "$blue" ]]; then
    return 1
  fi

  awk -v r="$red" -v g="$green" -v b="$blue" \
    'BEGIN { printf "%02X%02X%02X\n", int((r * 255) + 0.5), int((g * 255) + 0.5), int((b * 255) + 0.5) }'
}

assert_equal() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  local file="$4"

  if [[ "$actual" != "$expected" ]]; then
    fail "$label mismatch in $file (expected #$expected, found #$actual)"
  fi
}

FLUTTER_BACKGROUND_HEX="$(extract_flutter_background_hex || true)"
if [[ -z "$FLUTTER_BACKGROUND_HEX" ]]; then
  fail "Unable to resolve AppColors.background hex from lib/shared/theme/app_colors.dart"
fi

ANDROID_APP_BACKGROUND_HEX="$(extract_android_app_background_hex || true)"
if [[ -z "$ANDROID_APP_BACKGROUND_HEX" ]]; then
  fail "Unable to resolve @color/app_background from android/app/src/main/res/values/colors.xml"
fi

ANDROID_SPLASH_V31_RAW="$(extract_android_splash_value android/app/src/main/res/values-v31/styles.xml || true)"
ANDROID_SPLASH_NIGHT_V31_RAW="$(extract_android_splash_value android/app/src/main/res/values-night-v31/styles.xml || true)"

ANDROID_SPLASH_V31_HEX="$(resolve_android_splash_hex "$ANDROID_SPLASH_V31_RAW" "$ANDROID_APP_BACKGROUND_HEX" || true)"
ANDROID_SPLASH_NIGHT_V31_HEX="$(resolve_android_splash_hex "$ANDROID_SPLASH_NIGHT_V31_RAW" "$ANDROID_APP_BACKGROUND_HEX" || true)"

if [[ -z "$ANDROID_SPLASH_V31_HEX" ]]; then
  fail "Unable to resolve android:windowSplashScreenBackground in android/app/src/main/res/values-v31/styles.xml"
fi
if [[ -z "$ANDROID_SPLASH_NIGHT_V31_HEX" ]]; then
  fail "Unable to resolve android:windowSplashScreenBackground in android/app/src/main/res/values-night-v31/styles.xml"
fi

IOS_STORYBOARD_BACKGROUND_HEX="$(extract_ios_storyboard_background_hex || true)"
if [[ -z "$IOS_STORYBOARD_BACKGROUND_HEX" ]]; then
  fail "Unable to resolve LaunchScreen storyboard background color in ios/Runner/Base.lproj/LaunchScreen.storyboard"
fi

if ! grep -q '@color/app_background' android/app/src/main/res/drawable/launch_background.xml; then
  fail "android/app/src/main/res/drawable/launch_background.xml must reference @color/app_background"
fi

if [[ -n "$FLUTTER_BACKGROUND_HEX" ]]; then
  assert_equal "$FLUTTER_BACKGROUND_HEX" "$ANDROID_APP_BACKGROUND_HEX" \
    "Android app background" "android/app/src/main/res/values/colors.xml"
  assert_equal "$FLUTTER_BACKGROUND_HEX" "$ANDROID_SPLASH_V31_HEX" \
    "Android splash background (v31)" "android/app/src/main/res/values-v31/styles.xml"
  assert_equal "$FLUTTER_BACKGROUND_HEX" "$ANDROID_SPLASH_NIGHT_V31_HEX" \
    "Android splash background (night-v31)" "android/app/src/main/res/values-night-v31/styles.xml"
  assert_equal "$FLUTTER_BACKGROUND_HEX" "$IOS_STORYBOARD_BACKGROUND_HEX" \
    "iOS launch background" "ios/Runner/Base.lproj/LaunchScreen.storyboard"
fi

if ((${#FAILURES[@]} > 0)); then
  echo "Launch/auth color parity check failed:"
  for item in "${FAILURES[@]}"; do
    echo " - $item"
  done
  echo
  echo "Remediation:"
  echo " - Align launch colors to AppColors.background in:"
  echo "   - lib/shared/theme/app_colors.dart"
  echo "   - ios/Runner/Base.lproj/LaunchScreen.storyboard"
  echo "   - android/app/src/main/res/values/colors.xml"
  echo "   - android/app/src/main/res/values-v31/styles.xml"
  echo "   - android/app/src/main/res/values-night-v31/styles.xml"
  echo "   - android/app/src/main/res/drawable/launch_background.xml"
  exit 1
fi

echo "Launch/auth color parity check passed (canonical #$FLUTTER_BACKGROUND_HEX)."

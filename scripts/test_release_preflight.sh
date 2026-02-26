#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PREFLIGHT_SCRIPT="$PROJECT_DIR/scripts/release_preflight.sh"

expect_failure() {
  if "$@"; then
    echo "Expected command to fail but it passed: $*"
    exit 1
  fi
}

echo "Testing release preflight failure on missing keys..."
expect_failure env -i PATH="$PATH" /bin/bash "$PREFLIGHT_SCRIPT" ios --no-env-file

echo "Testing release preflight failure on placeholder values..."
expect_failure env -i PATH="$PATH" \
  SUPABASE_URL="https://your-project.supabase.co" \
  SUPABASE_ANON_KEY="your_anon_key_here" \
  REVENUECAT_IOS_KEY="appl_your_ios_key_here" \
  GOOGLE_WEB_CLIENT_ID="your_web_client_id.apps.googleusercontent.com" \
  GOOGLE_IOS_CLIENT_ID="your_ios_client_id.apps.googleusercontent.com" \
  /bin/bash "$PREFLIGHT_SCRIPT" ios --no-env-file

echo "Testing release preflight pass on valid iOS keys..."
env -i PATH="$PATH" \
  SUPABASE_URL="https://prod.supabase.co" \
  SUPABASE_ANON_KEY="eyJ-valid" \
  REVENUECAT_IOS_KEY="appl_valid" \
  GOOGLE_WEB_CLIENT_ID="prod-web.apps.googleusercontent.com" \
  GOOGLE_IOS_CLIENT_ID="prod-ios.apps.googleusercontent.com" \
  /bin/bash "$PREFLIGHT_SCRIPT" ios --no-env-file >/dev/null

echo "Testing release preflight pass on valid Android keys..."
env -i PATH="$PATH" \
  SUPABASE_URL="https://prod.supabase.co" \
  SUPABASE_ANON_KEY="eyJ-valid" \
  REVENUECAT_ANDROID_KEY="goog_valid" \
  GOOGLE_WEB_CLIENT_ID="prod-web.apps.googleusercontent.com" \
  /bin/bash "$PREFLIGHT_SCRIPT" android --no-env-file >/dev/null

echo "Release preflight tests passed."

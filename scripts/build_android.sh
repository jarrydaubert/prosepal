#!/bin/bash
# Build Android release with required dart-defines from .env.local

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env.local"
PREFLIGHT_SCRIPT="$PROJECT_DIR/scripts/release_preflight.sh"

"$PREFLIGHT_SCRIPT" android --env-file "$ENV_FILE"

# shellcheck disable=SC1090
source "$ENV_FILE"

# Create debug symbols directory
DEBUG_INFO_DIR="$PROJECT_DIR/build/debug-info/android"
mkdir -p "$DEBUG_INFO_DIR"

echo "Building Android release AAB with obfuscation..."
cd "$PROJECT_DIR"
flutter build appbundle --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_DIR" \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --dart-define=REVENUECAT_ANDROID_KEY=$REVENUECAT_ANDROID_KEY \
    --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID

echo "Done! AAB at: build/app/outputs/bundle/release/app-release.aab"
echo "Debug symbols saved to: $DEBUG_INFO_DIR"
echo "IMPORTANT: Keep debug symbols for crash symbolication!"

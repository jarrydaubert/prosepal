#!/bin/bash
# Build iOS release with required dart-defines from .env.local

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env.local"
PREFLIGHT_SCRIPT="$PROJECT_DIR/scripts/release_preflight.sh"

"$PREFLIGHT_SCRIPT" ios --env-file "$ENV_FILE"

# shellcheck disable=SC1090
source "$ENV_FILE"

# Create debug symbols directory
DEBUG_INFO_DIR="$PROJECT_DIR/build/debug-info/ios"
mkdir -p "$DEBUG_INFO_DIR"
SDK_ROOT="$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)"
EXTRA_DEFINES=()

if [ -n "$SDK_ROOT" ]; then
    echo "Using iOS SDK root: $SDK_ROOT"
    export SDKROOT="$SDK_ROOT"
    EXTRA_DEFINES+=(--dart-define=SdkRoot="$SDK_ROOT")
else
    echo "Warning: Could not resolve iOS SDK path via xcrun; continuing without SdkRoot define."
fi

echo "Building iOS release with obfuscation..."
cd "$PROJECT_DIR"
flutter build ios --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_DIR" \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY \
    --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID \
    --dart-define=GOOGLE_IOS_CLIENT_ID=$GOOGLE_IOS_CLIENT_ID \
    "${EXTRA_DEFINES[@]}"

echo "Done! Open Xcode to archive and submit."
echo "Debug symbols saved to: $DEBUG_INFO_DIR"
echo "IMPORTANT: Keep debug symbols for crash symbolication!"

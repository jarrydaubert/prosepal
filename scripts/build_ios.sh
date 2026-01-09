#!/bin/bash
# Build iOS release with RevenueCat key from .env.local

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env.local not found. Copy .env.example to .env.local and add your keys."
    exit 1
fi

source "$ENV_FILE"

if [ -z "$REVENUECAT_IOS_KEY" ]; then
    echo "Error: REVENUECAT_IOS_KEY not set in .env.local"
    exit 1
fi

if [ -z "$GOOGLE_WEB_CLIENT_ID" ]; then
    echo "Error: GOOGLE_WEB_CLIENT_ID not set in .env.local"
    exit 1
fi

if [ -z "$GOOGLE_IOS_CLIENT_ID" ]; then
    echo "Error: GOOGLE_IOS_CLIENT_ID not set in .env.local"
    exit 1
fi

# Create debug symbols directory
DEBUG_INFO_DIR="$PROJECT_DIR/build/debug-info/ios"
mkdir -p "$DEBUG_INFO_DIR"

echo "Building iOS release with obfuscation..."
cd "$PROJECT_DIR"
flutter build ios --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_DIR" \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY \
    --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID \
    --dart-define=GOOGLE_IOS_CLIENT_ID=$GOOGLE_IOS_CLIENT_ID

echo "Done! Open Xcode to archive and submit."
echo "Debug symbols saved to: $DEBUG_INFO_DIR"
echo "IMPORTANT: Keep debug symbols for crash symbolication!"

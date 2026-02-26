#!/bin/bash
# Run on iOS device with RevenueCat key from .env.local

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env.local not found. Copy .env.example to .env.local and add your keys."
    exit 1
fi

source "$ENV_FILE"

# Validate required environment variables
MISSING=""

if [ -z "$SUPABASE_URL" ]; then
    MISSING="$MISSING SUPABASE_URL"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    MISSING="$MISSING SUPABASE_ANON_KEY"
fi

if [ -z "$REVENUECAT_IOS_KEY" ]; then
    MISSING="$MISSING REVENUECAT_IOS_KEY"
fi

if [ -z "$GOOGLE_WEB_CLIENT_ID" ]; then
    MISSING="$MISSING GOOGLE_WEB_CLIENT_ID"
fi

if [ -z "$GOOGLE_IOS_CLIENT_ID" ]; then
    MISSING="$MISSING GOOGLE_IOS_CLIENT_ID"
fi

if [ -n "$MISSING" ]; then
    echo "Error: Missing required variables in .env.local:$MISSING"
    echo "Copy .env.example to .env.local and fill in all values."
    exit 1
fi

cd "$PROJECT_DIR"

# Find iOS device - extract device ID (second field separated by •)
DEVICE=$(flutter devices | grep -i "iphone\|ipad" | head -1 | awk -F'•' '{print $2}' | xargs)

if [ -z "$DEVICE" ]; then
    echo "No iOS device found. Connect your device and try again."
    flutter devices
    exit 1
fi

echo "Running on iOS device: $DEVICE"
flutter run -d "$DEVICE" \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=REVENUECAT_IOS_KEY="$REVENUECAT_IOS_KEY" \
    --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
    --dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID" \
    "$@"

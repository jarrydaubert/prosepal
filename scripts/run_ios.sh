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

SDK_ROOT="$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)"
EXTRA_DEFINES=()

# Guard against wrapper/alias invocation patterns that pass this script path
# through as a positional arg. If forwarded to flutter run, it is treated as a
# Dart target and causes "Launching ./scripts/run_ios.sh" build failures.
case "${1:-}" in
  "$0"|"./scripts/run_ios.sh"|"scripts/run_ios.sh"|"run_ios.sh")
    shift
    ;;
esac

# Find iOS device - extract device ID (second field separated by •)
DEVICE=$(flutter devices | grep -i "iphone\|ipad" | head -1 | awk -F'•' '{print $2}' | xargs)

if [ -z "$DEVICE" ]; then
    echo "No iOS device found. Connect your device and try again."
    flutter devices
    exit 1
fi

echo "Running on iOS device: $DEVICE"
if [ -n "$SDK_ROOT" ]; then
    echo "Using iOS SDK root: $SDK_ROOT"
    export SDKROOT="$SDK_ROOT"
    export SdkRoot="$SDK_ROOT"
    export FLUTTER_XCODE_SDKROOT="$SDK_ROOT"
    # Native assets in newer Flutter toolchains sometimes resolve iOS SDK root
    # from different define keys depending on build path (xcode_backend vs
    # resident compiler sync). Provide both to avoid intermittent warnings.
    EXTRA_DEFINES+=(--dart-define=SdkRoot="$SDK_ROOT")
    EXTRA_DEFINES+=(--dart-define=SDKROOT="$SDK_ROOT")
    EXTRA_DEFINES+=(--dart-define=FLUTTER_XCODE_SDKROOT="$SDK_ROOT")
    EXTRA_DEFINES+=(--dart-define=XCODE_SDKROOT="$SDK_ROOT")
else
    echo "Warning: Could not resolve iOS SDK path via xcrun; continuing without SdkRoot define."
fi
flutter run -d "$DEVICE" \
    --target=lib/main.dart \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=REVENUECAT_IOS_KEY="$REVENUECAT_IOS_KEY" \
    --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
    --dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID" \
    "${EXTRA_DEFINES[@]}" \
    "$@"

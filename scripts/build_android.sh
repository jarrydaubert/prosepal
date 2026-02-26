#!/bin/bash
# Build Android release with RevenueCat key from .env.local

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env.local not found. Copy .env.example to .env.local and add your keys."
    exit 1
fi

source "$ENV_FILE"

if [ -z "$REVENUECAT_ANDROID_KEY" ]; then
    echo "Error: REVENUECAT_ANDROID_KEY not set in .env.local"
    exit 1
fi

if [ -z "$GOOGLE_WEB_CLIENT_ID" ]; then
    echo "Error: GOOGLE_WEB_CLIENT_ID not set in .env.local"
    exit 1
fi

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

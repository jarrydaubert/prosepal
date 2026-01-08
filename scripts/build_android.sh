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

echo "Building Android release AAB..."
cd "$PROJECT_DIR"
flutter build appbundle --release \
    --dart-define=REVENUECAT_ANDROID_KEY=$REVENUECAT_ANDROID_KEY \
    --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID

echo "Done! AAB at: build/app/outputs/bundle/release/app-release.aab"

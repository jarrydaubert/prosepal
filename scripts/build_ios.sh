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

echo "Building iOS release..."
cd "$PROJECT_DIR"
flutter build ios --release --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY

echo "Done! Open Xcode to archive and submit."

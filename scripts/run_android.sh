#!/bin/bash
# Run on Android device with RevenueCat key from .env.local

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

cd "$PROJECT_DIR"

# Find Android device
DEVICE=$(flutter devices | grep -i "android" | head -1 | awk '{print $NF}' | tr -d '()')

if [ -z "$DEVICE" ]; then
    echo "No Android device found. Connect your device and try again."
    flutter devices
    exit 1
fi

echo "Running on Android device: $DEVICE"
flutter run -d "$DEVICE" --dart-define=REVENUECAT_ANDROID_KEY=$REVENUECAT_ANDROID_KEY "$@"

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

if [ -z "$REVENUECAT_IOS_KEY" ]; then
    echo "Error: REVENUECAT_IOS_KEY not set in .env.local"
    exit 1
fi

cd "$PROJECT_DIR"

# Find iOS device
DEVICE=$(flutter devices | grep -i "iphone\|ipad" | head -1 | awk '{print $NF}' | tr -d '()')

if [ -z "$DEVICE" ]; then
    echo "No iOS device found. Connect your device and try again."
    flutter devices
    exit 1
fi

echo "Running on iOS device: $DEVICE"
flutter run -d "$DEVICE" --dart-define=REVENUECAT_IOS_KEY=$REVENUECAT_IOS_KEY "$@"

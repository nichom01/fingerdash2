#!/bin/bash

# Build and run Fingerdash2 in iOS Simulator
# Usage: ./rundev.sh [simulator-name]

set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_PATH="$SCRIPT_DIR/Fingerdash2.xcworkspace"
SCHEME="Fingerdash2"

# Default simulator (can be overridden with first argument)
SIMULATOR_NAME="${1:-iPhone 17 Pro}"

echo "🚀 Building and running Fingerdash2..."
echo "📱 Simulator: $SIMULATOR_NAME"
echo ""

# Boot simulator if not already booted
xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true

# Open Simulator app
open -a Simulator

# Wait a moment for simulator to be ready
sleep 2

# Build the app
echo "📦 Building app..."
xcodebuild \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -derivedDataPath "$SCRIPT_DIR/.build" \
    clean build

# Get simulator UDID
SIMULATOR_UDID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -oE '\([A-F0-9-]+\)' | head -1 | tr -d '()')

# Find the built app in derived data
APP_PATH=$(find "$SCRIPT_DIR/.build" -name "Fingerdash2.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app. Build may have failed."
    exit 1
fi

# Install the app
echo "📲 Installing app on simulator..."
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"

# Get bundle identifier from Info.plist
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist" 2>/dev/null || echo "com.example.Fingerdash2")

# Launch the app
echo "▶️  Launching app..."
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"

echo ""
echo "✅ Done! App should be running in the simulator."


#!/usr/bin/env bash
# build_app.sh — builds FancyZones.app ready to copy to any Mac
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="FancyZones"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🔨 Building release binary..."
cd "$SCRIPT_DIR"
swift build -c release --product FancyZones

BINARY=".build/release/FancyZones"

echo "📦 Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary
cp "$BINARY" "$MACOS/$APP_NAME"

# Copy Info.plist
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"

echo "✅ Done: $APP_BUNDLE"
echo ""
echo "To run:  open \"$APP_BUNDLE\""
echo "To copy to another Mac: copy the entire FancyZones.app folder"

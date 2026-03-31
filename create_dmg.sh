#!/bin/bash

# Create DMG with proper installer layout

set -e

# Find the latest build in DerivedData (same as package.sh)
DERIVED_DATA_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ScrollCapture-*" -type d -maxdepth 1 | head -1)
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/ScrollCapture.app"

echo "=== Using app from: $APP_PATH ==="

# First run package.sh to embed OpenCV libraries
echo "=== Running package.sh to embed libraries ==="
./package.sh

DMG_NAME="ScrollCapture.dmg"
VOLUME_NAME="ScrollCapture"
DMG_TEMP="dmg_temp"

echo "=== Creating DMG installer ==="

# Create temporary DMG folder
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app (with embedded libraries from DerivedData)
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
rm -f "$DMG_NAME"
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DMG_NAME"

# Cleanup
rm -rf "$DMG_TEMP"

echo ""
echo "✅ DMG created: $DMG_NAME"
ls -lh "$DMG_NAME"
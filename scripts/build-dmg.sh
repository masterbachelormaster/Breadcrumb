#!/bin/bash
set -euo pipefail

# Build DMG installer for Breadcrumb
# Usage: ./scripts/build-dmg.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Extract version from project.yml
VERSION=$(grep '^\s*MARKETING_VERSION:' "$PROJECT_DIR/project.yml" | sed 's/.*"\(.*\)"/\1/')
DMG_NAME="Breadcrumb-v${VERSION}"
APP_NAME="Breadcrumb"

echo "Building ${APP_NAME} v${VERSION}..."

# Clean and build release
rm -rf ~/Library/Developer/Xcode/DerivedData/Breadcrumb-*
xcodebuild -project "$PROJECT_DIR/Breadcrumb.xcodeproj" \
    -scheme Breadcrumb \
    -configuration Release \
    build 2>&1 | tail -3

# Locate built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Breadcrumb-*/Build/Products/Release -name "Breadcrumb.app" -maxdepth 1)
if [ -z "$APP_PATH" ]; then
    echo "Error: Breadcrumb.app not found in DerivedData"
    exit 1
fi

# Prepare output directory
OUTPUT_DIR="$PROJECT_DIR/build"
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/${DMG_NAME}.dmg"

echo "Creating DMG..."

create-dmg \
    --volname "$APP_NAME" \
    --volicon "$PROJECT_DIR/Breadcrumb/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
    --background "$PROJECT_DIR/dmg/background.png" \
    --window-size 660 400 \
    --icon-size 120 \
    --icon "$APP_NAME.app" 170 180 \
    --app-drop-link 490 180 \
    --no-internet-enable \
    "$OUTPUT_DIR/${DMG_NAME}.dmg" \
    "$APP_PATH"

echo ""
echo "Done: $OUTPUT_DIR/${DMG_NAME}.dmg"
ls -lh "$OUTPUT_DIR/${DMG_NAME}.dmg"

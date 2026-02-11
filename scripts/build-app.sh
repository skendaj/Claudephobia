#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Claudephobia"
BUILD_DIR=".build/release"
APP_BUNDLE="dist/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf dist
mkdir -p "${CONTENTS}/MacOS"
mkdir -p "${CONTENTS}/Resources"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${CONTENTS}/MacOS/${APP_NAME}"

# Copy Info.plist
cp Resources/Info.plist "${CONTENTS}/Info.plist"

# Copy app icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${CONTENTS}/Resources/AppIcon.icns"
    echo "App icon included."
else
    echo "Warning: Resources/AppIcon.icns not found. App will have no icon."
fi

# Ad-hoc code sign
codesign --force --deep --sign - "${APP_BUNDLE}"
echo "Ad-hoc signed."

echo ""
echo "Done: ${APP_BUNDLE}"
echo "To create a zip for distribution:"
echo "  cd dist && zip -r ${APP_NAME}.zip ${APP_NAME}.app"

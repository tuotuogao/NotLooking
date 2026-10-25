#!/bin/zsh
# Build the Release app and wrap it in a DMG. Output: dist/NotLooking-<version>.dmg
set -euo pipefail
cd "$(dirname "$0")"
xcodegen generate
xcodebuild -project NotLooking.xcodeproj -scheme NotLooking -configuration Release \
  -derivedDataPath build CODE_SIGN_IDENTITY=- build 2>&1 | tee build.log | grep -E "error:|warning:|BUILD"
APP=build/Build/Products/Release/NotLooking.app
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
STAGE=build/dmg
rm -rf "$STAGE" && mkdir -p "$STAGE" dist
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
DMG="dist/NotLooking-v${VERSION}.dmg"
rm -f "$DMG"
hdiutil create -volname "NotLooking" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"
echo "→ $DMG"

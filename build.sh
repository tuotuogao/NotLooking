#!/bin/zsh
# Generate the Xcode project and build. Output: build/Build/Products/Debug/NotLooking.app
set -euo pipefail
cd "$(dirname "$0")"
xcodegen generate
xcodebuild -project NotLooking.xcodeproj -scheme NotLooking -configuration Debug \
  -derivedDataPath build build 2>&1 | tee build.log | grep -E "error:|warning:|BUILD"
echo "→ build/Build/Products/Debug/NotLooking.app"

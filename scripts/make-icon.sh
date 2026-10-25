#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift scripts/make-icon.swift
icon_dir=$(mktemp -d /tmp/notlooking-icon.XXXXXX)
trap 'rm -rf "$icon_dir"' EXIT
mkdir "$icon_dir/AppIcon.iconset"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" docs/icon.png --out "$icon_dir/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" docs/icon.png --out "$icon_dir/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$icon_dir/AppIcon.iconset" -o NotLooking/Resources/AppIcon.icns

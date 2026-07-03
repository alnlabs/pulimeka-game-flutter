#!/usr/bin/env bash
# iOS LaunchImage.imageset from playstore_icon.png (replaces 1×1 Flutter placeholders).
set -euo pipefail
cd "$(dirname "$0")/.."

ICON="assets/images/playstore_icon.png"
OUT="ios/Runner/Assets.xcassets/LaunchImage.imageset"

if [[ ! -f "$ICON" ]]; then
  echo "Missing $ICON" >&2
  exit 1
fi

mkdir -p "$OUT"
sips -z 256 256 "$ICON" --out "$OUT/LaunchImage.png" >/dev/null
sips -z 512 512 "$ICON" --out "$OUT/LaunchImage@2x.png" >/dev/null
sips -z 768 768 "$ICON" --out "$OUT/LaunchImage@3x.png" >/dev/null

echo "iOS launch images: $OUT (256 / 512 / 768 px from playstore_icon.png)"

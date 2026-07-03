#!/usr/bin/env bash
# Resize iPhone screenshots for App Store Connect.
# Usage:
#   ./scripts/resize_app_store_screenshots.sh [input_dir] [output_dir] [size]
#   size: 6.5 (default, 1242×2688) or 6.7 (1284×2778)
set -euo pipefail
cd "$(dirname "$0")/.."

SIZE="${3:-6.5}"
INPUT="${1:-.}"
if [[ "$SIZE" == "6.7" ]]; then
  W=1284; H=2778
  OUTPUT="${2:-docs/app-store-screenshots/ios-6.7-inch}"
else
  W=1242; H=2688
  OUTPUT="${2:-docs/app-store-screenshots/ios-6.5-inch}"
fi

mkdir -p "$OUTPUT"
count=0
shopt -s nullglob
for src in "$INPUT"/*.{png,PNG,jpg,JPG,jpeg,JPEG,heic,HEIC}; do
  [[ -f "$src" ]] || continue
  base="$(basename "$src")"
  name="${base%.*}.png"
  dest="$OUTPUT/$name"
  tmp="${dest}.tmp.jpg"
  # Exact pixel size for App Store (height width for sips -z)
  sips -z "$H" "$W" "$src" --out "$dest" >/dev/null
  # Flatten alpha → RGB PNG (avoids "wrong format" rejections)
  sips -s format jpeg -s formatOptions 95 "$dest" --out "$tmp" >/dev/null
  sips -s format png "$tmp" --out "$dest" >/dev/null
  rm -f "$tmp"
  echo "  $(basename "$dest") → ${W}×${H}"
  count=$((count + 1))
done

if [[ "$count" -eq 0 ]]; then
  echo "No images in: $INPUT" >&2
  exit 1
fi
echo
echo "Upload to App Store Connect → iPhone ${SIZE}\" Display"
echo "Folder: $(cd "$OUTPUT" && pwd)"

#!/usr/bin/env bash
# Captures board PNGs for each game phase (~15s on macOS desktop).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PHASES_DIR="${BOARD_SCREENSHOT_DIR:-docs/board-screenshots/phases}"
TUTORIAL_DIR="${TUTORIAL_SCREENSHOT_DIR:-docs/board-screenshots/tutorial-pages}"
CAPTURE_TUTORIAL="${CAPTURE_TUTORIAL:-false}"

export BOARD_SCREENSHOT_DIR="$PHASES_DIR"
export TUTORIAL_SCREENSHOT_DIR="$TUTORIAL_DIR"
export CAPTURE_TUTORIAL

mkdir -p "$PHASES_DIR" "$TUTORIAL_DIR"

echo "Capturing → $PHASES_DIR"
if [[ "$CAPTURE_TUTORIAL" == "true" ]]; then
  echo "Also capturing tutorial pages → $TUTORIAL_DIR"
fi

pick_device() {
  if flutter devices 2>/dev/null | grep -q "macos"; then
    echo "macos"
  elif flutter devices 2>/dev/null | grep -q "chrome"; then
    echo "chrome"
  else
    echo ""
  fi
}

DEVICE="$(pick_device)"

if [[ -n "$DEVICE" ]]; then
  echo "Using flutter run -d $DEVICE (fast path)..."
  flutter run -d "$DEVICE" \
    -t lib/tools/capture_screenshots_main.dart \
    --release \
    2>&1 | while IFS= read -r line; do
      if [[ "$line" == Capturing* ]] || [[ "$line" == Saved* ]]; then
        echo "$line"
      fi
    done
else
  echo "No desktop device — using headless widget test..."
  flutter test test/capture_board_screenshots_test.dart --reporter compact
fi

echo ""
echo "Done:"
ls -la "$PHASES_DIR"

# Keep bundled tutorial assets in sync with docs output.
ASSETS_DIR="assets/tutorial/phases"
mkdir -p "$ASSETS_DIR"
cp "$PHASES_DIR"/*.png "$ASSETS_DIR/"
echo "Synced PNGs → $ASSETS_DIR"
if [[ "$CAPTURE_TUTORIAL" == "true" ]]; then
  ls -la "$TUTORIAL_DIR"
fi

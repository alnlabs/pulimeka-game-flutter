#!/usr/bin/env bash
# Physical iPhone: debug (JIT) often crashes on iOS 18.4+ — default is Release.
# Set FLUTTER_DEVICE_ID to override auto-detect (e.g. when iPad + iPhone are connected).
# Mode: --release (default) or --debug
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=_parse_run_mode.sh
source "$(dirname "$0")/_parse_run_mode.sh"
parse_run_mode release "$@"

pick_iphone_device_id() {
  if [ -n "${FLUTTER_DEVICE_ID:-}" ]; then
    echo "$FLUTTER_DEVICE_ID"
    return
  fi
  flutter devices 2>/dev/null | grep -i 'iphone' | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}' | head -1
}

DEVICE_ID="$(pick_iphone_device_id || true)"
if [ -z "$DEVICE_ID" ]; then
  echo "No iPhone found. Connect your iPhone or set FLUTTER_DEVICE_ID."
  echo "  Usage: ./scripts/run_ios_device.sh --help"
  echo
  flutter devices
  exit 1
fi

MODE_LABEL="Debug"
[ "$RUN_MODE" = release ] && MODE_LABEL="Release"
echo "→ Running on iPhone ($DEVICE_ID) in $MODE_LABEL. Keep phone unlocked."
if [ "$RUN_MODE" = debug ]; then
  echo "  Warning: debug on device may crash on iOS 18.4+; try --release if it fails."
else
  echo "  Tip: ./scripts/run_ios_device.sh --debug  for hot reload (may not work on iOS 18+)"
fi
echo "  Trust/signing help: docs/ios-device-run.md"
echo

flutter pub get
(cd ios && pod install)

RELEASE_DEFINES=()
if [ "$RUN_MODE" = release ]; then
  RELEASE_DEFINES=(--dart-define=DB_PREFIX=prod_)
fi

if ! flutter run ${MODE_ARGS+"${MODE_ARGS[@]}"} -d "$DEVICE_ID" "${RELEASE_DEFINES[@]}" ${FLUTTER_RUN_EXTRA+"${FLUTTER_RUN_EXTRA[@]}"}; then
  echo
  echo "Launch failed? On iPhone:"
  echo "  1. Delete Puli Meka app"
  echo "  2. Settings → General → VPN & Device Management → Trust developer"
  echo "  3. Settings → Privacy & Security → Developer Mode → On"
  echo "  4. open ios/Runner.xcworkspace → Product → Run"
  echo "  5. Retry: ./scripts/run_ios_device.sh --release"
  echo "  Full guide: docs/ios-device-run.md"
  exit 1
fi

#!/usr/bin/env bash
# iOS Simulator — Debug only (hot reload). Physical device: ./scripts/run_ios_device.sh
set -euo pipefail
cd "$(dirname "$0")/.."

flutter pub get
(cd ios && pod install)

DEVICE_ID="${FLUTTER_DEVICE_ID:-}"
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID="$(flutter devices 2>/dev/null | grep -i 'simulator' | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}' | head -1 || true)"
fi

if [ -z "$DEVICE_ID" ]; then
  echo "No booted simulator found. Start one in Xcode (Window → Devices and Simulators) or:"
  echo "  open -a Simulator"
  flutter devices
  exit 1
fi

echo "→ Running on simulator ($DEVICE_ID) in Debug"
flutter run -d "$DEVICE_ID" "$@"

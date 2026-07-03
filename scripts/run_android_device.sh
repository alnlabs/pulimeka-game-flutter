#!/usr/bin/env bash
# Run on a physical Android phone (or emulator if no phone is connected).
# Set FLUTTER_DEVICE_ID to override auto-detect.
# Mode: --release (default) or --debug
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=_parse_run_mode.sh
source "$(dirname "$0")/_parse_run_mode.sh"
parse_run_mode release "$@"

pick_android_device_id() {
  if [ -n "${FLUTTER_DEVICE_ID:-}" ]; then
    echo "$FLUTTER_DEVICE_ID"
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    local id
    id="$(flutter devices --machine 2>/dev/null | jq -r '
      ([.[] | select((.targetPlatform // "") | startswith("android")) | select(.emulator == false)][0].id)
      // ([.[] | select((.targetPlatform // "") | startswith("android")) | select(.emulator == true)][0].id)
      // empty
    ')"
    if [ -n "$id" ]; then
      echo "$id"
      return
    fi
  fi

  if command -v python3 >/dev/null 2>&1; then
    local id
    id="$(flutter devices --machine 2>/dev/null | python3 -c '
import json, sys
try:
    devices = json.load(sys.stdin)
except json.JSONDecodeError:
    raise SystemExit
def is_android(d):
    return "android" in (d.get("targetPlatform") or "").lower()
physical = [d for d in devices if is_android(d) and not d.get("emulator")]
emulators = [d for d in devices if is_android(d) and d.get("emulator")]
for group in (physical, emulators):
    if group:
        print(group[0]["id"])
        break
')"
    if [ -n "$id" ]; then
      echo "$id"
      return
    fi
  fi

  flutter devices --machine 2>/dev/null \
    | tr -d '\n' \
    | grep -oE '"targetPlatform": "android[^"]*"[^}]*"emulator": false[^}]*"id": "[^"]+"' \
    | head -1 \
    | sed -n 's/.*"id": "\([^"]*\)".*/\1/p'
}

DEVICE_ID="$(pick_android_device_id || true)"
if [ -z "$DEVICE_ID" ]; then
  echo "No Android device found. Connect a phone (USB debugging on) or start an emulator."
  echo "  Or set FLUTTER_DEVICE_ID to a device id from: flutter devices"
  echo "  Usage: ./scripts/run_android_device.sh --help"
  echo
  flutter devices
  exit 1
fi

MODE_LABEL="Debug"
[ "$RUN_MODE" = release ] && MODE_LABEL="Release"
echo "→ Running on Android ($DEVICE_ID) in $MODE_LABEL."
if [ "$RUN_MODE" = debug ]; then
  echo "  Tip: omit --debug to use release (default)"
else
  echo "  Tip: ./scripts/run_android_device.sh --debug   for hot reload"
fi
echo "  Package: com.alnlabs.pulimekagame (Play Store id; debug adds .debug)"
echo "  USB debugging: Settings → Developer options → USB debugging"
echo "  Play Store upload: docs/PLAY_STORE.md"
echo

flutter pub get

# Old Flutter package id confuses Android Studio / adb launch (pulimeka vs pulimekagame).
if command -v adb >/dev/null 2>&1; then
  "$(dirname "$0")/uninstall_android_packages.sh" "$DEVICE_ID" 2>/dev/null || true
fi

# ${arr+"${arr[@]}"} avoids "unbound variable" when arr is empty under set -u.
if ! flutter run ${MODE_ARGS+"${MODE_ARGS[@]}"} -d "$DEVICE_ID" ${FLUTTER_RUN_EXTRA+"${FLUTTER_RUN_EXTRA[@]}"}; then
  echo
  echo "Launch failed? On the phone / Mac:"
  echo "  1. Enable Developer options + USB debugging"
  echo "  2. Accept the RSA fingerprint prompt on the phone"
  echo "  3. Run: adb devices   (device should show as 'device', not 'unauthorized')"
  echo "  4. ./scripts/uninstall_android_packages.sh && flutter clean"
  echo "  5. Android Studio: use activity com.alnlabs.pulimekagame.MainActivity (not com.alnlabs.pulimeka)"
  echo "  6. Try: FLUTTER_DEVICE_ID=<id> ./scripts/run_android_device.sh --debug"
  exit 1
fi

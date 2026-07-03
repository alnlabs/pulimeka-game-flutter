#!/usr/bin/env bash
# Remove conflicting Android installs (legacy Flutter id vs Play Store id).
# Usage: uninstall_android_packages.sh [device_serial]
#        uninstall_android_packages.sh --all [device_serial]
set -euo pipefail

ALL=0
DEVICE=""
for arg in "$@"; do
  case "$arg" in
    --all) ALL=1 ;;
    *) DEVICE="$arg" ;;
  esac
done

adb_cmd() {
  if [ -n "$DEVICE" ]; then
    adb -s "$DEVICE" "$@"
  else
    adb "$@"
  fi
}

packages=(com.alnlabs.pulimeka)
if [ "$ALL" = "1" ]; then
  packages+=(com.alnlabs.pulimekagame com.alnlabs.pulimekagame.debug)
fi

for pkg in "${packages[@]}"; do
  if adb_cmd shell pm path "$pkg" 2>/dev/null | grep -q package; then
    echo "Uninstalling $pkg ..."
    adb_cmd uninstall "$pkg" || true
  fi
done

echo "Done."

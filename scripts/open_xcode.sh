#!/usr/bin/env bash
# Sync Flutter/Pods, then open the Xcode workspace (never Runner.xcodeproj).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "→ flutter pub get"
flutter pub get

echo "→ pod install"
(cd ios && pod install)

echo "→ Opening Runner.xcworkspace"
open ios/Runner.xcworkspace

echo
echo "Use Runner.xcworkspace only — not Runner.xcodeproj."
echo
echo "Xcode schemes:"
echo "  Runner            → iPhone/iPad + Simulator (Release — default, safe on device)"
echo "  Runner-Simulator  → Simulator only (Debug, hot reload — do not use on real phone)"
echo "  Runner-Device     → Same as Runner (Release on device)"
echo
echo "Physical device from CLI:"
echo "  ./scripts/run_ios_device.sh --release"
echo
echo "Do NOT run Debug on a real iPhone — it crashes (mprotect / JIT not allowed)."

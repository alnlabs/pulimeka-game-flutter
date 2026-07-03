#!/usr/bin/env bash
# Build and export an App Store IPA (recommended — includes Flutter dSYMs).
set -euo pipefail
cd "$(dirname "$0")/.."

flutter pub get
cd ios && pod install && cd ..

flutter build ipa --release \
  --dart-define=DB_PREFIX=prod_ \
  "$@"

echo
echo "IPA: build/ios/ipa/*.ipa"
echo "Upload with Transporter, or open Xcode Organizer if you archived from Xcode."
echo ""
echo "If you use Xcode Archive instead, run first:"
echo "  flutter build ios --release --dart-define=DB_PREFIX=prod_"
echo "  open ios/Runner.xcworkspace → Product → Archive"
echo "Signing: docs/ios-device-run.md"

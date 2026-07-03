#!/usr/bin/env bash
# Build a Play Store–ready App Bundle (same applicationId as published native app).
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f android/keystore.properties ]]; then
  echo "Missing android/keystore.properties — copy android/keystore.properties.example and fill in passwords." >&2
  exit 1
fi

STORE_FILE="$(grep '^storeFile=' android/keystore.properties | cut -d= -f2- | tr -d ' ')"
if [[ -z "$STORE_FILE" ]]; then
  echo "Missing storeFile= in android/keystore.properties" >&2
  exit 1
fi
KEYSTORE_CANDIDATE="android/$STORE_FILE"
if [[ ! -f "$KEYSTORE_CANDIDATE" ]]; then
  echo "Keystore not found: $KEYSTORE_CANDIDATE" >&2
  echo "Put puli-meka-release.jks in android/keystore/ (see android/keystore/README.md)." >&2
  exit 1
fi
EXPECTED_SHA1="84:FB:DB:1F:48:A8:6C:6F:B4:17:FF:D7:EE:48:CD:A9:89:7C:73:E1"
KEY_PASS="$(grep '^storePassword=' android/keystore.properties | cut -d= -f2-)"
KEY_ALIAS="$(grep '^keyAlias=' android/keystore.properties | cut -d= -f2-)"
ACTUAL_SHA1="$(keytool -list -v -keystore "$KEYSTORE_CANDIDATE" -storepass "$KEY_PASS" -alias "$KEY_ALIAS" 2>/dev/null | awk '/SHA1:/{print $2; exit}')"
if [[ "$ACTUAL_SHA1" != "$EXPECTED_SHA1" ]]; then
  echo "Keystore SHA1 mismatch — Play expects $EXPECTED_SHA1 but got ${ACTUAL_SHA1:-unknown}." >&2
  exit 1
fi
echo "Release keystore OK (SHA1 $ACTUAL_SHA1)"

flutter pub get
flutter build appbundle --release \
  --dart-define=DB_PREFIX=prod_ \
  "$@"

VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: *//' | tr -d ' ')"
VERSION_NAME="${VERSION%%+*}"
mkdir -p release
OUT_AAB="release/puli-meka-${VERSION_NAME}-release.aab"
cp -f build/app/outputs/bundle/release/app-release.aab "$OUT_AAB"

echo
echo "Upload this file in Play Console:"
echo "  $(pwd)/$OUT_AAB"
echo "(Gradle also writes: build/app/outputs/bundle/release/app-release.aab — hidden in IDE because build/ is gitignored)"
echo "Package: com.alnlabs.pulimekagame — bump pubspec version before each new upload."
echo "Play warnings (device list / debug symbols): docs/play-store-warnings.md"

#!/bin/sh
# Generate Flutter.framework.dSYM for App Store Connect (engine dSYM not in Flutter 3.22 cache).
set -e
FRAMEWORK="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/Flutter.framework/Flutter"
if [ ! -f "$FRAMEWORK" ]; then
  echo "note: Flutter.framework not embedded yet, skipping dSYM generation"
  exit 0
fi
DEST="${DWARF_DSYM_FOLDER_PATH:-${BUILT_PRODUCTS_DIR}}"
mkdir -p "$DEST"
OUT="${DEST}/Flutter.framework.dSYM"
echo "Generating Flutter dSYM → $OUT"
dsymutil "$FRAMEWORK" -o "$OUT"
dwarfdump --uuid "$OUT" | head -3 || true

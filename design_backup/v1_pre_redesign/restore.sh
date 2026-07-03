#!/usr/bin/env bash
# Restore v1 layout/design from this backup into the active Flutter project.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Restoring design v1 from: $SCRIPT_DIR"
echo "Into project: $ROOT"

cp -R "$SCRIPT_DIR/lib/src/theme" "$ROOT/lib/src/"
cp -R "$SCRIPT_DIR/lib/src/widgets" "$ROOT/lib/src/"
cp -R "$SCRIPT_DIR/lib/src/screens" "$ROOT/lib/src/"
cp -R "$SCRIPT_DIR/lib/src/content" "$ROOT/lib/src/"
cp "$SCRIPT_DIR/lib/src/app.dart" "$ROOT/lib/src/"
cp -R "$SCRIPT_DIR/assets/images" "$ROOT/assets/"
cp -R "$SCRIPT_DIR/assets/fonts" "$ROOT/assets/"

echo "Done. Run: flutter pub get && flutter analyze lib"

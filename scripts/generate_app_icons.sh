#!/usr/bin/env bash
# Generate iOS AppIcon.appiconset and Android mipmap icons from playstore_icon.png.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f assets/images/playstore_icon.png ]]; then
  echo "Missing assets/images/playstore_icon.png" >&2
  exit 1
fi

flutter pub get
dart run flutter_launcher_icons
"$(dirname "$0")/generate_launch_images.sh"
echo "Done. Rebuild the app (delete from home screen on iOS if the icon does not update)."

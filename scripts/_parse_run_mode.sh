# Shared by run_android_device.sh and run_ios_device.sh (do not execute directly).
# parse_run_mode <default: debug|release> "$@"
# Sets: RUN_MODE, MODE_ARGS (empty or --release), FLUTTER_RUN_EXTRA (remaining args).

# Globals (must exist before parse_run_mode for `set -u` + empty arrays on macOS bash 3.2).
RUN_MODE=""
FLUTTER_RUN_EXTRA=()
MODE_ARGS=()

parse_run_mode_usage() {
  cat <<'EOF'
Usage: ./scripts/run_<platform>_device.sh [--debug | --release] [flutter run options...]

  --debug, -d     Debug build with hot reload
  --release, -r   Release build (default on physical devices)

  FLUTTER_RUN_MODE=debug|release   same as flags
  ANDROID_RELEASE=1 / IOS_RELEASE=0   legacy env overrides

Examples:
  ./scripts/run_android_device.sh --debug
  ./scripts/run_android_device.sh --release
  ./scripts/run_ios_device.sh --release
  ./scripts/run_ios_device.sh --debug
EOF
}

parse_run_mode() {
  local default_mode="$1"
  shift

  RUN_MODE=""
  FLUTTER_RUN_EXTRA=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --debug|-d)
        if [ -n "$RUN_MODE" ] && [ "$RUN_MODE" != debug ]; then
          echo "Use only one of --debug or --release." >&2
          exit 1
        fi
        RUN_MODE=debug
        shift
        ;;
      --release|-r)
        if [ -n "$RUN_MODE" ] && [ "$RUN_MODE" != release ]; then
          echo "Use only one of --debug or --release." >&2
          exit 1
        fi
        RUN_MODE=release
        shift
        ;;
      -h|--help)
        parse_run_mode_usage
        exit 0
        ;;
      *)
        FLUTTER_RUN_EXTRA+=("$1")
        shift
        ;;
    esac
  done

  if [ -z "$RUN_MODE" ]; then
    case "${FLUTTER_RUN_MODE:-}" in
      debug|release) RUN_MODE="$FLUTTER_RUN_MODE" ;;
    esac
  fi

  if [ -z "$RUN_MODE" ]; then
    if [ "${ANDROID_RELEASE:-0}" = "1" ]; then
      RUN_MODE=release
    elif [ -n "${IOS_RELEASE:-}" ] && [ "${IOS_RELEASE}" = "0" ]; then
      RUN_MODE=debug
    elif [ -n "${IOS_RELEASE:-}" ] && [ "${IOS_RELEASE}" = "1" ]; then
      RUN_MODE=release
    else
      RUN_MODE="$default_mode"
    fi
  fi

  if [ "$RUN_MODE" = release ]; then
    MODE_ARGS=(--release)
  else
    MODE_ARGS=()
    RUN_MODE=debug
  fi
}

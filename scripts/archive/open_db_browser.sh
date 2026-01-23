#!/bin/bash

# Open Slote SQLite database in DB Browser for SQLite (cross-platform)
# 
# Usage: 
#   ./open_db_browser.sh
#     - If an Android device/emulator is connected and the app is installed:
#       pulls the DB to ./notes.db and opens it.
#     - Otherwise opens the host platform DB file directly (if found).
#
#   ./open_db_browser.sh android [device_id] [output_file]
#     - Force Android mode (pulls DB via ADB).
#
#   ./open_db_browser.sh host [db_path]
#     - Force host mode (opens local DB path, or auto-detects if omitted).
#
#   ./open_db_browser.sh ios
#     - Force iOS simulator mode (booted simulator only).
#
# Requirements:
#   - DB Browser for SQLite installed
#     - macOS: brew install --cask db-browser-for-sqlite
#     - Linux: install `sqlitebrowser` (package name varies)
#     - Windows: install DB Browser for SQLite and/or ensure sqlitebrowser.exe is in PATH
#   - Android mode: adb in PATH
#   - iOS mode: Xcode CLI tools (xcrun)

set -euo pipefail

PACKAGE_NAME="com.example.slote"
DB_NAME="notes.db"
REMOTE_PATH="/data/data/${PACKAGE_NAME}/app_flutter/${DB_NAME}"

die() {
  echo "Error: $*" >&2
  exit 1
}

info() {
  echo "$*" >&2
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_host_platform() {
  case "${OSTYPE:-}" in
    darwin*) echo "macos" ;;
    linux*) echo "linux" ;;
    msys*|cygwin*|win32*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

android_available() {
  command_exists adb || return 1
  adb devices 2>/dev/null | grep -E "device$" >/dev/null 2>&1 || return 1
  return 0
}

android_pick_device() {
  local maybe_device="${1:-}"
  if [ -n "$maybe_device" ]; then
    echo "$maybe_device"
    return 0
  fi

  local devices
  devices="$(adb devices | grep -E "device$" | awk '{print $1}' | head -n1 || true)"
  [ -n "$devices" ] || die "No Android devices connected"
  echo "$devices"
}

android_assert_installed() {
  local device_id="$1"
  adb -s "$device_id" shell pm list packages | grep -q "$PACKAGE_NAME" \
    || die "Package $PACKAGE_NAME is not installed on device $device_id"
}

android_pull_db() {
  local device_id="$1"
  local output_file="$2"

  info "Pulling database from Android device $device_id..."
  adb -s "$device_id" exec-out run-as "$PACKAGE_NAME" cat "$REMOTE_PATH" > "$output_file" \
    || die "Failed to pull database via ADB. (Is this a debuggable build? Does run-as work?)"

  [ -f "$output_file" ] && [ -s "$output_file" ] || die "Pulled database file is missing/empty: $output_file"
  info "Database pulled successfully: $output_file"
}

ios_simulator_db_path() {
  command_exists xcrun || die "xcrun not found. Install Xcode command line tools."

  # Only supports the booted simulator for now.
  local container
  container="$(xcrun simctl get_app_container booted "$PACKAGE_NAME" data 2>/dev/null || true)"
  [ -n "$container" ] || die "No booted iOS simulator with $PACKAGE_NAME installed (or not running)."

  echo "${container}/Documents/${DB_NAME}"
}

host_candidate_db_paths() {
  local host_platform="$1"

  case "$host_platform" in
    macos)
      echo "$HOME/Library/Containers/${PACKAGE_NAME}/Data/Documents/${DB_NAME}"
      ;;
    linux)
      # Path-provider locations can vary; check common candidates.
      echo "${XDG_DATA_HOME:-$HOME/.local/share}/${PACKAGE_NAME}/${DB_NAME}"
      echo "$HOME/.local/share/${PACKAGE_NAME}/${DB_NAME}"
      echo "$HOME/Documents/${DB_NAME}"
      ;;
    windows)
      # When running under Git Bash/MSYS/Cygwin we may have /c/Users/... paths.
      # Try common locations. Users can always pass an explicit path.
      if [ -n "${LOCALAPPDATA:-}" ]; then
        echo "${LOCALAPPDATA//\\//}/${PACKAGE_NAME}/Data/Documents/${DB_NAME}"
      fi
      if [ -n "${APPDATA:-}" ]; then
        echo "${APPDATA//\\//}/${PACKAGE_NAME}/Data/Documents/${DB_NAME}"
      fi
      echo "$HOME/Documents/${DB_NAME}"
      ;;
    *)
      ;;
  esac
}

host_find_db() {
  local host_platform="$1"
  local p
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if [ -f "$p" ]; then
      echo "$p"
      return 0
    fi
  done < <(host_candidate_db_paths "$host_platform")

  return 1
}

open_in_db_browser() {
  local db_path="$1"

  [ -f "$db_path" ] || die "Database file not found: $db_path"

  local host_platform
  host_platform="$(detect_host_platform)"

  # Prefer platform-native openers, then fall back to known CLI names.
  case "$host_platform" in
    macos)
      if [ -d "/Applications/DB Browser for SQLite.app" ]; then
        info "Opening in DB Browser for SQLite..."
        open -a "DB Browser for SQLite" "$db_path"
        return 0
      fi
      ;;
    windows)
      # Git Bash / MSYS: try sqlitebrowser first; then cmd start.
      if command_exists sqlitebrowser; then
        info "Opening in DB Browser for SQLite..."
        sqlitebrowser "$db_path"
        return 0
      fi
      if command_exists cmd.exe; then
        info "Opening in default app..."
        cmd.exe /c start "" "$(cygpath -w "$db_path" 2>/dev/null || echo "$db_path")"
        return 0
      fi
      ;;
    linux)
      if command_exists sqlitebrowser; then
        info "Opening in DB Browser for SQLite..."
        sqlitebrowser "$db_path"
        return 0
      fi
      ;;
  esac

  if command_exists sqlitebrowser; then
    info "Opening in DB Browser for SQLite..."
    sqlitebrowser "$db_path"
    return 0
  fi

  if command_exists db-browser-for-sqlite; then
    info "Opening in DB Browser for SQLite..."
    db-browser-for-sqlite "$db_path"
    return 0
  fi

  die "DB Browser for SQLite not found. Install it, then open manually: $db_path"
}

MODE="${1:-}"

# Web guidance (this script is for native targets; web uses IndexedDB).
if [ "$MODE" = "web" ]; then
  cat >&2 <<'EOF'
Web uses IndexedDB (not a SQLite file), so there is no `notes.db` to open.

Recommended options:
  - Use your browser DevTools -> Application/Storage -> IndexedDB to inspect data.
  - Or add an explicit export feature in-app if you need a SQLite dump.
EOF
  exit 0
fi

case "$MODE" in
  android)
    shift
    device_id="$(android_pick_device "${1:-}")"
    output_file="${2:-$DB_NAME}"

    android_assert_installed "$device_id"
    android_pull_db "$device_id" "$output_file"
    open_in_db_browser "$output_file"
    ;;
  ios)
    shift
    db_path="$(ios_simulator_db_path)"
    open_in_db_browser "$db_path"
    ;;
  host)
    shift
    host_platform="$(detect_host_platform)"
    db_path="${1:-}"
    if [ -z "$db_path" ]; then
      db_path="$(host_find_db "$host_platform" || true)"
      [ -n "$db_path" ] || die "Could not find $DB_NAME on host ($host_platform). Pass an explicit path: ./open_db_browser.sh host /path/to/notes.db"
    fi
    open_in_db_browser "$db_path"
    ;;
  "" )
    # Auto mode: prefer Android if available, otherwise host.
    if android_available; then
      device_id="$(android_pick_device "")"
      output_file="$DB_NAME"
      android_assert_installed "$device_id"
      android_pull_db "$device_id" "$output_file"
      open_in_db_browser "$output_file"
      exit 0
    fi

    host_platform="$(detect_host_platform)"
    if [ "$host_platform" = "unknown" ]; then
      die "Unsupported host OS (\$OSTYPE=${OSTYPE:-unset}). Use explicit mode: android | ios | host."
    fi

    db_path="$(host_find_db "$host_platform" || true)"
    [ -n "$db_path" ] || die "Could not find $DB_NAME on host ($host_platform). Pass an explicit path: ./open_db_browser.sh host /path/to/notes.db"
    open_in_db_browser "$db_path"
    ;;
  *)
    # Backwards compatibility: if a device id is provided as first arg, treat it as Android mode.
    if android_available; then
      device_id="$(android_pick_device "$MODE")"
      output_file="${2:-$DB_NAME}"
      android_assert_installed "$device_id"
      android_pull_db "$device_id" "$output_file"
      open_in_db_browser "$output_file"
    else
      die "Unknown mode '$MODE'. Use: android | ios | host"
    fi
    ;;
esac

info "Done!"

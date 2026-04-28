#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="SoundOutputToggle"
SETTINGS_APP_NAME="SoundOutputToggle Settings"
BUNDLE_ID="com.pdg.SoundOutputToggle"
SETTINGS_BUNDLE_ID="com.pdg.SoundOutputToggle.Settings"
MIN_SYSTEM_VERSION="13.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
ICONS_DIR="$DIST_DIR/icons"

TOGGLE_BUNDLE="$DIST_DIR/$APP_NAME.app"
SETTINGS_BUNDLE="$DIST_DIR/$SETTINGS_APP_NAME.app"
DMG_ROOT="$DIST_DIR/dmg-root"
DMG_PATH="$ROOT_DIR/SoundOutputToggle.dmg"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$TOGGLE_BUNDLE" "$SETTINGS_BUNDLE" "$ICONS_DIR"
mkdir -p "$ICONS_DIR"

swift "$ROOT_DIR/script/generate_icon.swift" "$ICONS_DIR/SoundOutputToggle.icns" "unknown"
swift "$ROOT_DIR/script/generate_icon.swift" "$ICONS_DIR/SoundOutputToggleSettings.icns" "settings"

create_bundle() {
  local bundle_path="$1"
  local bundle_name="$2"
  local bundle_id="$3"
  local icon_name="$4"
  local launch_mode="$5"
  local is_agent="$6"

  local contents="$bundle_path/Contents"
  local macos="$contents/MacOS"
  local resources="$contents/Resources"
  local info_plist="$contents/Info.plist"

  mkdir -p "$macos" "$resources"
  cp "$BUILD_BINARY" "$macos/$APP_NAME"
  chmod +x "$macos/$APP_NAME"
  cp "$ICONS_DIR/$icon_name.icns" "$resources/$icon_name.icns"

  cat >"$info_plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$bundle_id</string>
  <key>CFBundleName</key>
  <string>$bundle_name</string>
  <key>CFBundleDisplayName</key>
  <string>$bundle_name</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>$icon_name</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
PLIST

  if [[ "$launch_mode" == "settings" ]]; then
    cat >>"$info_plist" <<PLIST
  <key>LSEnvironment</key>
  <dict>
    <key>SOT_LAUNCH_MODE</key>
    <string>settings</string>
  </dict>
PLIST
  fi

  if [[ "$is_agent" == "true" ]]; then
    cat >>"$info_plist" <<PLIST
  <key>LSUIElement</key>
  <true/>
PLIST
  fi

  cat >>"$info_plist" <<PLIST
</dict>
</plist>
PLIST
}

create_bundle "$TOGGLE_BUNDLE" "$APP_NAME" "$BUNDLE_ID" "SoundOutputToggle" "toggle" "true"
create_bundle "$SETTINGS_BUNDLE" "$SETTINGS_APP_NAME" "$SETTINGS_BUNDLE_ID" "SoundOutputToggleSettings" "settings" "false"

open_toggle() {
  /usr/bin/open -n "$TOGGLE_BUNDLE"
}

open_settings() {
  /usr/bin/open -n "$SETTINGS_BUNDLE"
}

refresh_icon() {
  /usr/bin/open -n "$TOGGLE_BUNDLE" --args --refresh-icon
}

install_user() {
  local install_dir="$HOME/Applications"
  mkdir -p "$install_dir"
  rm -rf "$install_dir/$APP_NAME.app" "$install_dir/$SETTINGS_APP_NAME.app"
  cp -R "$TOGGLE_BUNDLE" "$install_dir/"
  cp -R "$SETTINGS_BUNDLE" "$install_dir/"
  /usr/bin/open -n "$install_dir/$APP_NAME.app" --args --refresh-icon
  sleep 1
  /usr/bin/mdimport "$install_dir/$APP_NAME.app" "$install_dir/$SETTINGS_APP_NAME.app" >/dev/null 2>&1 || true
  echo "Installed to $install_dir"
}

install_system() {
  local install_dir="/Applications"
  rm -rf "$install_dir/$APP_NAME.app" "$install_dir/$SETTINGS_APP_NAME.app"
  /usr/bin/ditto "$TOGGLE_BUNDLE" "$install_dir/$APP_NAME.app"
  /usr/bin/ditto "$SETTINGS_BUNDLE" "$install_dir/$SETTINGS_APP_NAME.app"
  /usr/bin/open -n "$install_dir/$APP_NAME.app" --args --refresh-icon
  sleep 1
  /usr/bin/mdimport "$install_dir/$APP_NAME.app" "$install_dir/$SETTINGS_APP_NAME.app" >/dev/null 2>&1 || true
  echo "Installed to $install_dir"
}

create_dmg() {
  rm -rf "$DMG_ROOT" "$DMG_PATH"
  mkdir -p "$DMG_ROOT"

  /usr/bin/ditto "$TOGGLE_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
  /usr/bin/ditto "$SETTINGS_BUNDLE" "$DMG_ROOT/$SETTINGS_APP_NAME.app"
  cp "$ROOT_DIR/README_INSTALL_KO.md" "$DMG_ROOT/README.md"
  ln -s /Applications "$DMG_ROOT/Applications"

  hdiutil create \
    -volname "SoundOutputToggle" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

  echo "Created $DMG_PATH"
}

case "$MODE" in
  run|toggle)
    open_toggle
    ;;
  settings|--settings)
    open_settings
    ;;
  refresh-icon|--refresh-icon)
    refresh_icon
    ;;
  install)
    install_user
    ;;
  install-system)
    install_system
    ;;
  dmg|--dmg)
    create_dmg
    ;;
  --debug|debug)
    lldb -- "$TOGGLE_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    open_toggle
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_toggle
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    test -x "$TOGGLE_BUNDLE/Contents/MacOS/$APP_NAME"
    test -x "$SETTINGS_BUNDLE/Contents/MacOS/$APP_NAME"
    test -f "$TOGGLE_BUNDLE/Contents/Resources/SoundOutputToggle.icns"
    test -f "$SETTINGS_BUNDLE/Contents/Resources/SoundOutputToggleSettings.icns"
    ;;
  *)
    echo "usage: $0 [run|toggle|settings|refresh-icon|install|install-system|dmg|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac

#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ClipSpot"
VOLUME_NAME="ClipSpot"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_BUILD_DIR="$DIST_DIR/dmg-build"
STAGING_DIR="$DMG_BUILD_DIR/staging"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_IMAGE="$BACKGROUND_DIR/dmg-background.png"
RW_DMG="$DMG_BUILD_DIR/$APP_NAME-rw.dmg"
FINAL_DMG="$DIST_DIR/$APP_NAME.dmg"
MOUNT_DIR="/Volumes/$VOLUME_NAME"

"$ROOT_DIR/script/build_and_run.sh" --bundle

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

rm -rf "$DMG_BUILD_DIR"
mkdir -p "$BACKGROUND_DIR"

cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/ModuleCache" \
SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/ModuleCache" \
/usr/bin/swift - "$BACKGROUND_IMAGE" <<'SWIFT'
import AppKit

let outputPath = CommandLine.arguments[1]
let size = NSSize(width: 1080, height: 700)
let image = NSImage(size: size)

image.lockFocus()
NSColor(calibratedWhite: 0.985, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()
image.unlockFocus()

guard
    let data = image.tiffRepresentation,
    let representation = NSBitmapImageRep(data: data),
    let png = representation.representation(using: .png, properties: [:])
else {
    fatalError("Failed to render DMG background")
}

try png.write(to: URL(fileURLWithPath: outputPath))
SWIFT

rm -f "$RW_DMG" "$FINAL_DMG"
if ! hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" -ov -format UDRW "$RW_DMG" >/dev/null; then
  hdiutil makehybrid -hfs -hfs-volume-name "$VOLUME_NAME" -o "${FINAL_DMG%.dmg}" "$STAGING_DIR" >/dev/null
  echo "$FINAL_DMG"
  exit 0
fi

if [[ -d "$MOUNT_DIR" ]]; then
  hdiutil detach "$MOUNT_DIR" -quiet || true
fi

hdiutil attach "$RW_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -noverify -noautoopen >/dev/null

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {112, 77, 1192, 777}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set background picture of viewOptions to file ".background:dmg-background.png"
    set position of item "$APP_NAME.app" of container window to {300, 405}
    set position of item "Applications" of container window to {735, 405}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT_DIR" -quiet
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG" >/dev/null
hdiutil internet-enable -no "$FINAL_DMG" >/dev/null

echo "$FINAL_DMG"

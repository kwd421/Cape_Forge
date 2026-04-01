#!/bin/zsh

set -euo pipefail

# Local packaging helper for development builds.
# This creates a lightweight app bundle from the SwiftPM release binary.
# It does not replace the Xcode archive/export flow used for App Store distribution.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
MODULE_CACHE="$PROJECT_DIR/.cache/clang/ModuleCache"
DIST_DIR="$PROJECT_DIR/dist"
APP_EXECUTABLE_NAME="CapeForge"
APP_DISPLAY_NAME="Cape Forge"
APP_DIR="$DIST_DIR/$APP_DISPLAY_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DEFAULT_CURSORS_SOURCE_DIR="$PROJECT_DIR/Sources/Resources/DefaultCursors"
DEFAULT_CURSORS_DEST_DIR="$RESOURCES_DIR/DefaultCursors"

XCODE_PROJECT="$PROJECT_DIR/CapeForge.xcodeproj"
XCODE_SCHEME="CapeForge"

mkdir -p "$MODULE_CACHE"

cd "$PROJECT_DIR"

BUILD_SETTINGS="$(xcodebuild -project "$XCODE_PROJECT" -scheme "$XCODE_SCHEME" -showBuildSettings 2>/dev/null)"

marketing_version="$(
  printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/MARKETING_VERSION = / { print $2; exit }'
)"
current_project_version="$(
  printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/CURRENT_PROJECT_VERSION = / { print $2; exit }'
)"
deployment_target="$(
  printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/MACOSX_DEPLOYMENT_TARGET = / { print $2; exit }'
)"
product_bundle_identifier="$(
  printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/PRODUCT_BUNDLE_IDENTIFIER = / { print $2; exit }'
)"
product_name="$(
  printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/PRODUCT_NAME = / { print $2; exit }'
)"

marketing_version="${marketing_version:-1.0.0}"
current_project_version="${current_project_version:-1}"
deployment_target="${deployment_target:-26.0}"
product_bundle_identifier="${product_bundle_identifier:-com.seinel.capeforge}"
product_name="${product_name:-Cape Forge}"

env \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
  SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE" \
  swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/arm64-apple-macosx/release/$APP_EXECUTABLE_NAME" "$MACOS_DIR/$APP_EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$APP_EXECUTABLE_NAME"

if [[ -d "$DEFAULT_CURSORS_SOURCE_DIR" ]]; then
  mkdir -p "$DEFAULT_CURSORS_DEST_DIR"
  cp -R "$DEFAULT_CURSORS_SOURCE_DIR"/. "$DEFAULT_CURSORS_DEST_DIR"/
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>CapeForge</string>
  <key>CFBundleIdentifier</key>
  <string>${product_bundle_identifier}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${product_name}</string>
  <key>CFBundleDisplayName</key>
  <string>${product_name}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${marketing_version}</string>
  <key>CFBundleVersion</key>
  <string>${current_project_version}</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>${deployment_target}</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "App bundle created at:"
echo "$APP_DIR"
echo
echo "Developer tools in ./tools are not bundled into this app."
echo "For App Store distribution, archive the Xcode target instead of using this script."
echo
echo "To launch:"
echo "open \"$APP_DIR\""

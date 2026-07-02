#!/bin/bash
# Builds Charmera and wraps it in a proper .app bundle so it behaves like a real
# Mac app (Dock icon, menu bar, removable-volume access prompt).
#
# NOTE: This compiles with `swiftc` directly instead of `swift build`, because
# this machine only has the Command Line Tools and its SwiftPM manifest binary
# is broken. `swiftc` itself works fine. Package.swift is kept for Xcode users.
set -e
cd "$(dirname "$0")"

APP="Charmera.app"
BUNDLE_ID="com.charmera.app"
MIN_OS="13.0"
ARCH="$(uname -m)"          # arm64 or x86_64
TARGET="${ARCH}-apple-macosx${MIN_OS}"

# Preflight: SwiftUI's @State/@Binding are macros in the current SDK, and their
# compiler plugin ships only with full Xcode. If only Command Line Tools are
# selected, the build will fail — guide the user instead of dumping a stack.
DEV_DIR="$(xcode-select -p 2>/dev/null || true)"
if [[ "$DEV_DIR" != *"Xcode"* ]]; then
    if [ -d "/Applications/Xcode.app" ]; then
        echo "⚠  Xcode is installed but not selected. Run this once, then re-run build.sh:"
        echo "     sudo xcode-select -s /Applications/Xcode.app"
        exit 1
    else
        echo "✗ Building the SwiftUI app needs full Xcode (for the SwiftUI macro plugin)."
        echo "  Command Line Tools alone can't compile @State/@Binding."
        echo "  Install Xcode from the App Store, then:"
        echo "     sudo xcode-select -s /Applications/Xcode.app && ./build.sh"
        exit 1
    fi
fi

echo "▶ Compiling for $TARGET…"
mkdir -p build
swiftc \
    -swift-version 5 \
    -O \
    -parse-as-library \
    -target "$TARGET" \
    -framework AppKit \
    $(find Sources/Charmera -name '*.swift') \
    -o build/Charmera

echo "▶ Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp build/Charmera "$APP/Contents/MacOS/Charmera"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Charmera</string>
    <key>CFBundleDisplayName</key><string>Charmera</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>Charmera</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIconName</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>$MIN_OS</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Charmera</string>
    <key>NSRemovableVolumesUsageDescription</key>
    <string>Charmera reads photos from your connected camera card.</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS grants a stable identity for the removable-volume prompt.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✓ Built $APP"
echo "  Run it with:  open $APP"

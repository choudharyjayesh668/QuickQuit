#!/bin/bash
# Builds QuickQuit.app using only Apple Command Line Tools.
# Output goes to ./build, or to QUICKQUIT_BUILD_DIR if that is set.
# Set SWIFTFLAGS to pass extra compiler flags (CI uses -warnings-as-errors).
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "QuickQuit only supports macOS." >&2
    exit 1
fi
# xcode-select is checked first because it fails quietly when the tools are
# missing; asking xcrun directly would pop up Apple's install dialog.
if ! xcode-select -p >/dev/null 2>&1 || ! xcrun --find swiftc >/dev/null 2>&1; then
    echo "Apple Command Line Tools (the Swift compiler) were not found." >&2
    echo "Install them, then try again:" >&2
    echo "    xcode-select --install" >&2
    exit 1
fi

# package.json is the single source of truth for the version number.
VERSION="$(plutil -extract version raw -o - package.json)"
MIN_MACOS="13.0"

BUILD_DIR="${QUICKQUIT_BUILD_DIR:-build}"
APP="$BUILD_DIR/QuickQuit.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

# The deployment target makes the compiler check that every API used exists on
# the oldest supported macOS, and keeps the binary in line with Info.plist.
# shellcheck disable=SC2086  # SWIFTFLAGS is intentionally split into words
if ! swiftc -O -swift-version 6 -target "$(uname -m)-apple-macos$MIN_MACOS" ${SWIFTFLAGS:-} \
    Sources/*.swift -o "$APP/Contents/MacOS/QuickQuit"; then
    echo >&2
    echo "The build failed. QuickQuit needs a Swift 6 compiler; this Mac has:" >&2
    swiftc --version 2>&1 | head -n 1 >&2
    echo "If that is older than Swift 6, update Apple Command Line Tools in" >&2
    echo "System Settings → General → Software Update." >&2
    exit 1
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>QuickQuit</string>
    <key>CFBundleDisplayName</key><string>QuickQuit</string>
    <key>CFBundleIdentifier</key><string>local.quickquit.QuickQuit</string>
    <key>CFBundleExecutable</key><string>QuickQuit</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc signature so macOS accepts the locally built app.
codesign --force --sign - "$APP"
case "$APP" in
    /*) echo "Built $APP (version $VERSION)" ;;
    *)  echo "Built $(pwd)/$APP (version $VERSION)" ;;
esac

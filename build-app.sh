#!/bin/sh
# Builds AKeyboardSwitcher.app (release, ad-hoc signed) into ./build
set -eu
cd "$(dirname "$0")"

swift build -c release

APP=build/AKeyboardSwitcher.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/AKeyboardSwitcher" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"

echo "Built $APP"

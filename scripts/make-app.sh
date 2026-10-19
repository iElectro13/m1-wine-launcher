#!/usr/bin/env bash
# Builds a release WineLauncher.app bundle (macOS only). Usage: scripts/make-app.sh [output-dir]
set -euo pipefail

OUT="${1:-build}"
APP="$OUT/WineLauncher.app"

swift build -c release --product WineLauncher
BIN="$(swift build -c release --product WineLauncher --show-bin-path)/WineLauncher"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/WineLauncher"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>WineLauncher</string>
    <key>CFBundleIdentifier</key><string>dev.ielectro.winelauncher</string>
    <key>CFBundleName</key><string>Wine Launcher</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc signature: enough to launch locally; there is no Developer ID behind it.
codesign --force --sign - "$APP"
echo "Built $APP"

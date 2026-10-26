#!/bin/bash
set -e

APP_NAME="FileCraft.app"
BUNDLE_DIR="build/$APP_NAME"

echo "==> Building FileCraft in release mode..."
swift build -c release

echo "==> Creating macOS App Bundle..."
rm -rf "$BUNDLE_DIR"
rm -rf "build/TangerineRea.app"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

if [ -d "Resources" ]; then
    cp -R Resources/* "$BUNDLE_DIR/Contents/Resources/"
fi

cp .build/release/FileCraft "$BUNDLE_DIR/Contents/MacOS/FileCraft"
chmod +x "$BUNDLE_DIR/Contents/MacOS/FileCraft"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"
fi

cat << 'EOF' > "$BUNDLE_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>FileCraft</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aldev.filecraft</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>FileCraft</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.2</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "==> App bundle created successfully at $BUNDLE_DIR"

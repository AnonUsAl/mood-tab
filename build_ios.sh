#!/bin/bash
set -e
PROJECT="/Users/anonusal/Documents/GitHub/mood-tab"
APP_PATH="$PROJECT/build/ios/Release-iphoneos/Runner.app"
DERIVED_APP="/Users/anonusal/Library/Developer/Xcode/DerivedData/Runner-ephimagfnaetmsgmsdeogarcfwaa/Build/Products/Release-iphoneos/Runner.app"

cd "$PROJECT"

# Step 1: Flutter build (Dart/App.framework will build, release_unpack_ios will fail)
echo "=== Flutter build (expected failure at framework step) ==="
flutter build ios --release --no-codesign 2>&1 | grep -E "error|Built|Xcode|Failed|FAIL" | tail -5 || true

# Step 2: Fix Flutter.framework
echo "=== Fixing Flutter.framework ==="
SRC="/opt/homebrew/share/flutter/bin/cache/artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework"
DEST="$PROJECT/build/ios/Release-iphoneos/Flutter.framework"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
xattr -rc "$DEST/" 2>/dev/null || true
codesign -s - --force "$DEST/Flutter" 2>&1
echo "OK"

# Step 3: xcodebuild
echo "=== Xcode build ==="
cd "$PROJECT/ios"
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    PROVISIONING_PROFILE_REQUIRED=NO \
    build 2>&1 | grep -E "BUILD|error" | tail -5

# Step 4: Also copy framework to derived data location
echo "=== Syncing framework to DerivedData ==="
rm -rf "$DERIVED_APP/Frameworks/Flutter.framework" 2>/dev/null || true
mkdir -p "$DERIVED_APP/Frameworks"
cp -R "$DEST" "$DERIVED_APP/Frameworks/"
xattr -rc "$DERIVED_APP/Frameworks/Flutter.framework/" 2>/dev/null || true

# Step 5: Package IPA
echo "=== Packaging IPA ==="
cd "$PROJECT/build"
rm -rf Payload
mkdir -p Payload
cp -R "$DERIVED_APP" Payload/
zip -qr mood_tab_unsigned.ipa Payload
ls -lh "$PROJECT/build/mood_tab_unsigned.ipa"
echo "=== DONE ==="

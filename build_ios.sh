#!/bin/bash
set -e
PROJECT="/Users/anonusal/Documents/GitHub/mood-tab"

cd "$PROJECT"

# Step 1: Flutter build (App.framework will compile, release_unpack_ios will fail)
echo "=== Flutter build (framework step may fail - expected) ==="
flutter build ios --release --no-codesign 2>&1 | grep -E "error|Built|Xcode" | tail -5 || true

# Step 2: Fix Flutter.framework (remove xattr, ad-hoc sign)
echo "=== Fixing Flutter.framework ==="
SRC="/opt/homebrew/share/flutter/bin/cache/artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework"
DEST="$PROJECT/build/ios/Release-iphoneos/Flutter.framework"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
xattr -rc "$DEST/" 2>/dev/null || true
codesign -s - --force "$DEST/Flutter" 2>&1
echo "OK"

# Step 3: Temporarily remove PreActions from scheme so xcodebuild
#        doesn't re-trigger release_unpack_ios
SCHEME="$PROJECT/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
SCHEME_BAK="${SCHEME}.bak"
cp "$SCHEME" "$SCHEME_BAK"

# Remove the PreActions block (between <PreActions> and </PreActions> markers)
python3 -c "
import re
with open('$SCHEME', 'r') as f:
    content = f.read()
# Remove PreActions block
content = re.sub(r'\s*<PreActions>.*?</PreActions>', '', content, flags=re.DOTALL)
with open('$SCHEME', 'w') as f:
    f.write(content)
"

# Step 4: xcodebuild
echo "=== Xcode build ==="
cd "$PROJECT/ios"
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    AD_HOC_CODE_SIGNING_ALLOWED=YES \
    PROVISIONING_PROFILE_REQUIRED=NO \
    build 2>&1 | grep -E "BUILD|error:|Error:" | tail -10

# Step 5: Verify the app exists
APP_PATH="$PROJECT/build/ios/Release-iphoneos/Runner.app"
if [ ! -d "$APP_PATH" ]; then
    # Try derived data
    APP_PATH="/Users/anonusal/Library/Developer/Xcode/DerivedData/Runner-ephimagfnaetmsgmsdeogarcfwaa/Build/Products/Release-iphoneos/Runner.app"
fi
echo "=== App at: $APP_PATH ==="
ls -ld "$APP_PATH" 2>/dev/null | head -1

# Step 6: Package IPA
echo "=== Packaging IPA ==="
cd "$PROJECT/build"
rm -rf Payload
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -qr mood_tab_unsigned.ipa Payload
ls -lh "$PROJECT/build/mood_tab_unsigned.ipa"
echo "=== DONE ==="

# Step 7: Restore scheme
mv "$SCHEME_BAK" "$SCHEME"
echo "=== Scheme restored ==="

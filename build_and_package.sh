#!/bin/bash
set -e
DEST="/Users/anonusal/Documents/GitHub/mood-tab/build/ios/Release-iphoneos"
SRC="/opt/homebrew/share/flutter/bin/cache/artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework"

echo "=== Copying framework ==="
rsync -a --delete --filter '- .DS_Store/' --chmod='Du=rwx,Dgo=rx,Fu=rw,Fgo=r' "$SRC/" "$DEST/Flutter.framework/"
echo "OK"

echo "=== Clearing all xattrs ==="
xattr -rc "$DEST/Flutter.framework/"
echo "OK"

echo "=== Ad-hoc signing ==="
codesign -s - --force "$DEST/Flutter.framework/Flutter"
echo "OK"

echo "=== Build flutter ==="
cd /Users/anonusal/Documents/GitHub/mood-tab
flutter build ios --release --no-codesign
echo "BUILD DONE"

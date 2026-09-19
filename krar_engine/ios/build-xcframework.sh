#!/usr/bin/env bash
# Builds KrarEngine.xcframework (device, plus a universal arm64/x86_64
# simulator slice) from the Rust crate, for the KrarEngine pod the Flutter
# iOS app links.
set -euo pipefail

cd "$(dirname "$0")/.."
export IPHONEOS_DEPLOYMENT_TARGET=15.0

OUT=target/ios-frameworks
rm -rf "$OUT" ios/KrarEngine.xcframework

for target in aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios; do
  cargo build --release --lib --target "$target"
done

# Wraps a dylib as KrarEngine.framework in $1.
make_framework() {
  local dir="$1" dylib="$2"
  local fw="$dir/KrarEngine.framework"
  mkdir -p "$fw"
  cp "$dylib" "$fw/KrarEngine"
  install_name_tool -id @rpath/KrarEngine.framework/KrarEngine "$fw/KrarEngine"
  cat > "$fw/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>KrarEngine</string>
  <key>CFBundleIdentifier</key><string>com.mattathias.KrarEngine</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>KrarEngine</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>${IPHONEOS_DEPLOYMENT_TARGET}</string>
</dict>
</plist>
PLIST
}

make_framework "$OUT/device" target/aarch64-apple-ios/release/libkrar_engine.dylib

mkdir -p "$OUT/sim-universal"
lipo -create \
  target/aarch64-apple-ios-sim/release/libkrar_engine.dylib \
  target/x86_64-apple-ios/release/libkrar_engine.dylib \
  -output "$OUT/sim-universal/libkrar_engine.dylib"
make_framework "$OUT/simulator" "$OUT/sim-universal/libkrar_engine.dylib"

xcodebuild -create-xcframework \
  -framework "$OUT/device/KrarEngine.framework" \
  -framework "$OUT/simulator/KrarEngine.framework" \
  -output ios/KrarEngine.xcframework

echo "Built ios/KrarEngine.xcframework"

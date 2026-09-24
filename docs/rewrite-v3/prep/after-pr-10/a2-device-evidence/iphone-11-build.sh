#!/bin/bash
# Builds the iOS Release probe app on the M1 (no device needed) and captures:
#   iphone-11-pod-install.log, iphone-11-xcodebuild.log  raw tool output, redacted
#   iphone-11-Podfile.lock                                copy of the generated lock
#   iphone-11-pods.txt                                    excerpt composed by this script (pods, build, app facts)
# TEAM (the free personal team ID) comes from the environment. It and the home
# directory are replaced in every retained file ([redacted], ~); see redact().
set -euo pipefail
: "${TEAM:?set TEAM to the personal team ID}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer LANG=en_US.UTF-8
EV=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$EV" rev-parse --show-toplevel)
APP=$ROOT/r1-spike/mobile
DEP=$ROOT/docs/rewrite-v3/prep/after-pr-10/dependency-evidence
TEMPLATE=expo-template-bare-minimum@57.0.26
TEMPLATE_SHA256=6b19d4235ab57c66fac699de7a2c57fe0ea277bf8a355ed45b2a37258bd93366
T=$(mktemp -d)
# Also redacted: the signing identity name, its certificate SHA-1 and the provisioning profile UUID.
redact() {
  TEAM=$TEAM perl -pe 's/\Q$ENV{TEAM}\E/[redacted]/g; s/\Q$ENV{HOME}\E/~/g;
    s/\b[0-9A-F]{40}\b/[redacted]/g;
    s/(PROVISIONING_PROFILE[A-Z_]*\\=)[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}/$1\[redacted]/g;
    s/(Apple(?:\\)? Development:).*?\\?\([A-Z0-9]{10}\\?\)/$1 [redacted]/g'
}
X="mise exec node@24.21.0 --"
cd "$APP"
cmp "$DEP/package.json" package.json && cmp "$DEP/package-lock.json" package-lock.json
rm -rf ios
npm_config_engine_strict=true $X npm ci --ignore-scripts --no-audit --no-fund
$X npm pack "$TEMPLATE" --ignore-scripts --pack-destination "$T"
echo "$TEMPLATE_SHA256  $T/expo-template-bare-minimum-57.0.26.tgz" | shasum -a 256 -c
CI=1 EXPO_NO_TELEMETRY=1 $X node node_modules/expo/bin/cli prebuild --platform ios --no-install \
  --template "$T/expo-template-bare-minimum-57.0.26.tgz"
cmp "$DEP/package.json" package.json && cmp "$DEP/package-lock.json" package-lock.json
(cd ios && $X pod install 2>&1) | redact > "$EV/iphone-11-pod-install.log"
cp ios/Podfile.lock "$EV/iphone-11-Podfile.lock"
set +e
xcodebuild -workspace ios/LokaR1A2.xcworkspace -scheme LokaR1A2 -configuration Release \
  -destination generic/platform=iOS -derivedDataPath ios/build \
  DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates build 2>&1 \
  | redact > "$EV/iphone-11-xcodebuild.log"
rc=${PIPESTATUS[0]}
set -e
echo "xcodebuild exit=$rc" >> "$EV/iphone-11-xcodebuild.log"
{
  echo "observed_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "composed by iphone-11-build.sh; raw logs: iphone-11-pod-install.log, iphone-11-xcodebuild.log"
  echo "DEVELOPER_DIR=$DEVELOPER_DIR"
  echo "xcodebuild: $(xcodebuild -version | tr '\n' ' ')"
  echo "cocoapods=$($X pod --version 2>/dev/null)"
  echo "pod env: $($X pod env 2>/dev/null | grep -E '^ *Ruby :' | sed 's/^ *//')"
  echo "node=$($X node -v) npm=$($X npm -v)"
  echo "install: npm_config_engine_strict=true npm ci --ignore-scripts (package.json and package-lock.json cmp-equal to dependency-evidence before and after prebuild)"
  echo "template=$TEMPLATE sha256=$TEMPLATE_SHA256 (verified)"
  echo "prebuild: expo prebuild --platform ios --no-install --template <that tgz>; then pod install in ios/"
  echo "Podfile.lock sha256=$(shasum -a 256 ios/Podfile.lock | cut -d' ' -f1) (retained as iphone-11-Podfile.lock)"
  echo "--- Podfile.lock: hermes, sqlite, local memory module, cocoapods"
  grep -E '^  - (hermes-engine|hermes-engine/Pre-built|ExpoSQLite|React-Core-prebuilt|ReactNativeDependencies|LokaMemory) \(|^(PODFILE CHECKSUM|COCOAPODS):' ios/Podfile.lock
  echo "--- pod install: hermes artifact"
  grep -F '[Hermes]' "$EV/iphone-11-pod-install.log" || true
  echo "--- xcodebuild: Hermes replacement build phase (script output lines)"
  grep -E '^PhaseScriptExecution .*Replace\\ Hermes|^(Preparing the final location|Extracting the tarball|Done replacing hermes-engine)$' \
    "$EV/iphone-11-xcodebuild.log" | cut -c1-110 || true
  A=ios/build/Build/Products/Release-iphoneos/LokaR1A2.app
  echo "--- app $A (Release, development signing by the free personal team; no IPA)"
  echo "executable sha256=$(shasum -a 256 "$A/LokaR1A2" | cut -d' ' -f1)"
  echo "main.jsbundle sha256=$(shasum -a 256 "$A/main.jsbundle" | cut -d' ' -f1)"
  echo "lipo -archs: $(lipo -archs "$A/LokaR1A2")"
  for k in CFBundleIdentifier DTSDKBuild DTXcodeBuild MinimumOSVersion; do
    echo "Info.plist $k=$(/usr/libexec/PlistBuddy -c "Print :$k" "$A/Info.plist")"
  done
  echo "--- Pods/Headers/Public/ExpoSQLite/sqlite3.h (vendored sqlite3, not SQLCipher)"
  grep -E '^#define SQLITE_(VERSION|SOURCE_ID) ' ios/Pods/Headers/Public/ExpoSQLite/sqlite3.h
  echo "--- Podfile.properties.json"
  cat ios/Podfile.properties.json; echo
  echo "--- xcodebuild exit=$rc"
} > "$EV/iphone-11-pods.txt"
exit "$rc"

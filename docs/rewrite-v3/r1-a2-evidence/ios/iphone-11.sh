#!/bin/bash
# R1-A2 iOS evidence on the M1 (derived from prep/after-pr-10/a2-device-evidence/iphone-11-build.sh and -probe.sh).
#
#   iphone-11.sh build N   clean prebuild + pod install + Release xcodebuild, writes build-N.txt (composed facts:
#                          git HEAD and status, tools, JS bundle / Hermes bytecode / executable / source map
#                          hashes, dSYM UUIDs), build-N-pod-install.log and build-N-xcodebuild.log (raw, redacted).
#                          The app, dSYM and source map are kept in $KEEP/build-N (not retained in git).
#   iphone-11.sh compare   build-compare.txt: which hashes of build-1 and build-2 agree.
#   iphone-11.sh run       installs $KEEP/build-2's app on the attached iPhone 11 (fresh data container),
#                          launches it until summary.json appears (each `kill` case ends the process; this
#                          loop relaunches it), pulls responses.jsonl, faults.jsonl and summary.json, pulls the
#                          app's crash reports (one per kill case, SIGABRT) and symbolicates their app frames
#                          with atos + the dSYM, then runs scripts/check.mjs (differential against the Elixir
#                          runner with one injected mismatch; fault records against the Elixir runner, with
#                          JS stacks symbolicated through the release source map).
#
# Needs TEAM (the free personal team ID) and KEEP (a directory outside the repository) in the environment.
# Every retained file passes through redact(); see below for what it replaces.
set -uo pipefail
: "${TEAM:?set TEAM to the personal team ID}" "${KEEP:?set KEEP to a directory outside the repository}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer LANG=en_US.UTF-8
EV=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$EV" rev-parse --show-toplevel)
APP=$ROOT/r1-spike/mobile
DEP=$ROOT/docs/rewrite-v3/prep/after-pr-10/dependency-evidence
BUNDLE_ID=com.lorecrafting.lokar1a2
TEMPLATE=expo-template-bare-minimum@57.0.26
TEMPLATE_SHA256=6b19d4235ab57c66fac699de7a2c57fe0ea277bf8a355ed45b2a37258bd93366
X="mise exec node@24.21.0 --"
IDS=$TEAM # device identifiers are added by `run`

# Replaced with [redacted]: every value in IDS (team ID; on `run` also UDID, ECID in decimal and hex, serial
# number, device name, CoreDevice identifier), upper-case 40-hex values (certificate SHA-1), provisioning
# profile UUIDs, the signing identity name, MAC addresses, the CoreDevice tunnel IP, crash-report
# crashReporterKey/incident/device-specific keys, and every UUID except the build UUIDs listed in KEEP_UUIDS
# (this covers app-container and LaunchServices UUIDs). Home -> ~; scratchpad and temp paths -> [tmp].
KEEP_UUIDS=
redact() {
  V="$IDS" K="$KEEP_UUIDS" perl -pe 'BEGIN{@v=grep{length}split /\n/,$ENV{V}; %k=map{uc($_)=>1}split /\s+/,$ENV{K}}
    for my $v(@v){s/\Q$v\E/[redacted]/gi}
    s/\Q$ENV{HOME}\E/~/g;
    s#(?:/private)?/(?:tmp|var/folders)/[^\s"'"'"':,)\]]*#[tmp]#g;
    s/\b[0-9A-F]{40}\b/[redacted]/g;
    s/(PROVISIONING_PROFILE[A-Z_]*\\?=)[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}/$1\[redacted]/g;
    s/(Apple(?:\\)? Development:).*?\\?\([A-Z0-9]{10}\\?\)/$1 [redacted]/g;
    s/\b([0-9a-f]{2}:){5}[0-9a-f]{2}\b/[redacted]/gi; s/(Tunnel IP Address: ).*/$1\[redacted]/;
    s/("(?:crashReporterKey|incident|incident_id|sessionID|deviceIdentifierForVendor|bootSessionUUID)"\s*:\s*)"[^"]*"/$1"[redacted]"/g;
    s/(?<![0-9A-Fa-f])([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})(?![0-9A-Fa-f])/$k{uc $1}?$1:"[redacted-uuid]"/ge'
}

build() {
  local N=$1 T K=$KEEP/build-$1
  T=$(mktemp -d)
  rm -rf "$K" && mkdir -p "$K"
  cd "$APP" || exit 1
  cmp "$DEP/package.json" package.json && cmp "$DEP/package-lock.json" package-lock.json || exit 1
  rm -rf ios
  npm_config_engine_strict=true $X npm ci --ignore-scripts --no-audit --no-fund >/dev/null 2>&1 || exit 1
  $X npm pack "$TEMPLATE" --ignore-scripts --pack-destination "$T" >/dev/null 2>&1
  echo "$TEMPLATE_SHA256  $T/expo-template-bare-minimum-57.0.26.tgz" | shasum -a 256 -c >/dev/null || exit 1
  CI=1 EXPO_NO_TELEMETRY=1 $X node node_modules/expo/bin/cli prebuild --platform ios --no-install \
    --template "$T/expo-template-bare-minimum-57.0.26.tgz" >/dev/null 2>&1 || exit 1
  cmp "$DEP/package.json" package.json && cmp "$DEP/package-lock.json" package-lock.json || exit 1
  (cd ios && $X pod install 2>&1) | redact > "$EV/build-$N-pod-install.log"
  # SOURCEMAP_FILE makes react-native-xcode.sh emit the Metro map and compose it with the hermesc map.
  xcodebuild -workspace ios/LokaR1A2.xcworkspace -scheme LokaR1A2 -configuration Release \
    -destination generic/platform=iOS -derivedDataPath ios/build \
    DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic SOURCEMAP_FILE="$K/main.jsbundle.map" \
    -allowProvisioningUpdates build 2>&1 | redact > "$EV/build-$N-xcodebuild.log"
  local rc=${PIPESTATUS[0]}
  echo "xcodebuild exit=$rc" >> "$EV/build-$N-xcodebuild.log"
  local P=ios/build/Build/Products/Release-iphoneos A=ios/build/Build/Products/Release-iphoneos/LokaR1A2.app
  cp -R "$A" "$P/LokaR1A2.app.dSYM" "$K/" 2>/dev/null
  cp "$P/main.jsbundle" "$K/metro.main.jsbundle" 2>/dev/null
  {
    echo "observed_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "composed by iphone-11.sh build $N; raw logs: build-$N-pod-install.log, build-$N-xcodebuild.log"
    echo "git rev-parse HEAD: $(git -C "$ROOT" rev-parse HEAD)"
    echo "git status --porcelain (untracked prebuild output under r1-spike/mobile/ios is gitignored):"
    git -C "$ROOT" status --porcelain | sed 's/^/  /'
    echo "--- end git status"
    echo "DEVELOPER_DIR=$DEVELOPER_DIR"
    echo "xcodebuild: $(xcodebuild -version | tr '\n' ' ')"
    echo "cocoapods=$($X pod --version 2>/dev/null) node=$($X node -v) npm=$($X npm -v)"
    echo "template=$TEMPLATE sha256=$TEMPLATE_SHA256 (verified); package.json and lock cmp-equal to dependency-evidence before and after prebuild"
    echo "Podfile.lock sha256=$(shasum -a 256 ios/Podfile.lock | cut -d' ' -f1)"
    grep -E '^  - (hermes-engine|ExpoSQLite|LokaMemory) \(' ios/Podfile.lock
    echo "--- hashes (sha256)"
    echo "metro_js_bundle (Release-iphoneos/main.jsbundle, before hermesc) $(shasum -a 256 "$P/main.jsbundle" | cut -d' ' -f1)"
    echo "hermes_bytecode (LokaR1A2.app/main.jsbundle) $(shasum -a 256 "$A/main.jsbundle" | cut -d' ' -f1) magic=$(head -c 8 "$A/main.jsbundle" | od -An -tx1 | tr -d ' ')"
    echo "composed_source_map (main.jsbundle.map) $(shasum -a 256 "$K/main.jsbundle.map" | cut -d' ' -f1)"
    echo "executable (LokaR1A2.app/LokaR1A2) $(shasum -a 256 "$A/LokaR1A2" | cut -d' ' -f1)"
    echo "dsym_dwarf (LokaR1A2.app.dSYM/Contents/Resources/DWARF/LokaR1A2) $(shasum -a 256 "$P/LokaR1A2.app.dSYM/Contents/Resources/DWARF/LokaR1A2" | cut -d' ' -f1)"
    echo "--- dwarfdump --uuid (executable, dSYM)"
    xcrun dwarfdump --uuid "$A/LokaR1A2" "$P/LokaR1A2.app.dSYM" | sed 's# /.*/# #'
    echo "lipo -archs: $(lipo -archs "$A/LokaR1A2")"
    for k in CFBundleIdentifier DTSDKBuild DTXcodeBuild MinimumOSVersion; do
      echo "Info.plist $k=$(/usr/libexec/PlistBuddy -c "Print :$k" "$A/Info.plist")"
    done
    echo "--- app files (sha256; signature files depend on signing time and profile)"
    (cd "$A" && find . -type f | LC_ALL=C sort | while read -r f; do echo "$(shasum -a 256 "$f" | cut -d' ' -f1)  $f"; done)
    echo "--- xcodebuild exit=$rc"
  } 2>&1 | KEEP_UUIDS="$(xcrun dwarfdump --uuid "$A/LokaR1A2" 2>/dev/null | awk '{print $2}')" redact > "$EV/build-$N.txt"
  return "$rc"
}

compare() {
  {
    echo "build-1.txt vs build-2.txt, same source commit and clean prebuild each time"
    for k in metro_js_bundle hermes_bytecode composed_source_map executable dsym_dwarf; do
      a=$(grep "^$k " "$EV/build-1.txt" | awk '{print $NF}'); b=$(grep "^$k " "$EV/build-2.txt" | awk '{print $NF}')
      [ "$k" = hermes_bytecode ] && a=$(grep "^$k " "$EV/build-1.txt" | awk '{print $(NF-1)}') && b=$(grep "^$k " "$EV/build-2.txt" | awk '{print $(NF-1)}')
      echo "$k: $([ "$a" = "$b" ] && echo same || echo DIFFERENT) $a $b"
    done
    echo "--- app files whose hashes differ"
    { diff <(sed -n '/^--- app files/,/^--- xcodebuild/p' "$EV/build-1.txt") <(sed -n '/^--- app files/,/^--- xcodebuild/p' "$EV/build-2.txt"); true; } | grep '^[<>]' || echo "(none)"
    echo "--- the same Mach-O files with their code signatures removed (codesign --remove-signature on copies)"
    local T; T=$(mktemp -d)
    for f in LokaR1A2 Frameworks/React.framework/React Frameworks/hermesvm.framework/hermesvm Frameworks/ExpoModulesCore.framework/ExpoModulesCore; do
      for n in 1 2; do cp "$KEEP/build-$n/LokaR1A2.app/$f" "$T/$n"; codesign --remove-signature "$T/$n"; done
      echo "$f: $([ "$(shasum -a 256 < "$T/1")" = "$(shasum -a 256 < "$T/2")" ] && echo same || echo DIFFERENT) $(shasum -a 256 < "$T/1" | cut -d' ' -f1)"
    done
    echo "--- dSYM DWARF: differing bytes (cmp -l offset, octal build-1, octal build-2); Mach-O UUIDs above are equal"
    cmp -l "$KEEP/build-1/LokaR1A2.app.dSYM/Contents/Resources/DWARF/LokaR1A2" "$KEEP/build-2/LokaR1A2.app.dSYM/Contents/Resources/DWARF/LokaR1A2"
    grep -h '^UUID' "$EV/build-1.txt" "$EV/build-2.txt"
  } > "$EV/build-compare.txt"
  cat "$EV/build-compare.txt"
}

run() {
  local K=$KEEP/build-2 T D
  T=$(mktemp -d) D=$KEEP/device
  rm -rf "$D" && mkdir -p "$D/crash"
  xcrun devicectl list devices --json-output "$T/list.json" >/dev/null 2>&1
  read -r CDID UDID NAME < <(python3 -c "import json,sys;d=[x for x in json.load(open(sys.argv[1]))['result']['devices'] if x['hardwareProperties'].get('productType')=='iPhone12,1'][0];print(d['identifier'],d['hardwareProperties']['udid'],d['deviceProperties']['name'].replace(' ','_'))" "$T/list.json")
  NAME=${NAME//_/ }
  ECID=$(python3 -c "import json,sys;d=[x for x in json.load(open(sys.argv[1]))['result']['devices'] if x['identifier']==sys.argv[2]][0];print(d['hardwareProperties'].get('ecid',''))" "$T/list.json" "$CDID")
  SERIAL=$(python3 -c "import json,sys;d=[x for x in json.load(open(sys.argv[1]))['result']['devices'] if x['identifier']==sys.argv[2]][0];print(d['hardwareProperties'].get('serialNumber',''))" "$T/list.json" "$CDID")
  IDS="$TEAM
$CDID
$UDID
$NAME
$ECID
$(printf '%X' "${ECID:-0}")
$SERIAL"
  KEEP_UUIDS=$(xcrun dwarfdump --uuid "$K/LokaR1A2.app/LokaR1A2" | awk '{print $2}')
  {
    date -u +%Y-%m-%dT%H:%M:%SZ
    echo "host=M1 Air; DEVELOPER_DIR=$DEVELOPER_DIR; git HEAD $(git -C "$ROOT" rev-parse HEAD)"
    echo "app: build-2 (build-2.txt); executable sha256 $(shasum -a 256 "$K/LokaR1A2.app/LokaR1A2" | cut -d' ' -f1)"
    echo "hermes_bytecode sha256 $(shasum -a 256 "$K/LokaR1A2.app/main.jsbundle" | cut -d' ' -f1)"
    echo "\$ xcrun devicectl --version"; xcrun devicectl --version
    echo "\$ xcrun devicectl device info details --device [redacted] (selected lines)"
    xcrun devicectl device info details --device "$CDID" 2>&1 | grep -E 'Marketing Name|Product Type|OS Build Update|OS Version|Developer Mode Status|CPU Type'
    echo "\$ xcrun devicectl device uninstall app --device [redacted] $BUNDLE_ID  (fresh data container)"
    xcrun devicectl device uninstall app --device "$CDID" "$BUNDLE_ID" 2>&1 | tail -2
    echo "\$ xcrun devicectl device install app --device [redacted] build-2/LokaR1A2.app"
    xcrun devicectl device install app --device "$CDID" "$K/LokaR1A2.app" 2>&1 | tail -4
    local launches=0 done=0
    while [ $launches -lt 12 ] && [ $done = 0 ]; do
      launches=$((launches + 1))
      echo "\$ xcrun devicectl device process launch --console --terminate-existing --device [redacted] $BUNDLE_ID  (launch $launches)"
      xcrun devicectl device process launch --console --terminate-existing --device "$CDID" "$BUNDLE_ID" > "$T/launch-$launches.txt" 2>&1 &
      local LP=$! t=0
      while [ $t -lt 60 ]; do
        sleep 5; t=$((t + 1))
        if xcrun devicectl device copy from --device "$CDID" --domain-type appDataContainer --domain-identifier "$BUNDLE_ID" \
          --source Documents/summary.json --destination "$D/summary.json" >/dev/null 2>&1; then done=1; break; fi
        kill -0 $LP 2>/dev/null || break
      done
      kill $LP 2>/dev/null; wait $LP 2>/dev/null
      echo "launch $launches ended after ~$((t * 5)) s; process console output (last lines):"
      tail -3 "$T/launch-$launches.txt"
      grep -q 'BSErrorCodeDescription = Locked' "$T/launch-$launches.txt" && { echo "device locked: stopping"; break; }
    done
    echo "launches=$launches done=$done"
    for f in responses.jsonl faults.jsonl summary.json; do
      echo "\$ xcrun devicectl device copy from --device [redacted] --domain-type appDataContainer --domain-identifier $BUNDLE_ID --source Documents/$f --destination device/$f"
      xcrun devicectl device copy from --device "$CDID" --domain-type appDataContainer --domain-identifier "$BUNDLE_ID" \
        --source "Documents/$f" --destination "$D/$f" 2>&1 | tail -1
    done
    echo "\$ xcrun devicectl device copy from --device [redacted] --domain-type systemCrashLogs --source / --destination crash/"
    xcrun devicectl device copy from --device "$CDID" --domain-type systemCrashLogs --source / --destination "$D/crash" 2>&1 | tail -1
  } 2>&1 | redact > "$EV/iphone-11-run.txt"
  [ -f "$D/summary.json" ] || { echo "no summary.json: run incomplete (see iphone-11-run.txt)" >&2; exit 1; }
  cp "$D/responses.jsonl" "$EV/responses.jsonl"; redact < "$D/summary.json" > "$EV/summary.json"
  redact < "$D/faults.jsonl" > "$EV/faults.device.jsonl"
  # Crash reports of this app from this run (newest per kill case), redacted, and their app frames symbolicated.
  local since
  since=$(head -1 "$EV/iphone-11-run.txt")
  mkdir -p "$EV/crash"
  rm -f "$EV/crash/"*
  : > "$EV/kill-stacks-symbolicated.txt"
  find "$D/crash" -name 'LokaR1A2-*.ips' | LC_ALL=C sort | while read -r ips; do
    b=$(basename "$ips")
    python3 - "$ips" "$K/LokaR1A2.app.dSYM" "$since" > "$T/sym.txt" <<'PY'
import json, subprocess, sys
path, dsym, since = sys.argv[1:4]
raw = open(path).read()
head, body = raw.split('\n', 1)
h, r = json.loads(head), json.loads(body)
from datetime import datetime
if datetime.strptime(h['timestamp'], '%Y-%m-%d %H:%M:%S.%f %z') < datetime.fromisoformat(since.replace('Z', '+00:00')):
    sys.exit(0)  # an earlier run's report
imgs = r['usedImages']
t = next(t for t in r['threads'] if t.get('triggered'))
print('=== ' + path.rsplit('/', 1)[1] + ' exception=' + r['exception']['type'] + ' ' + r['exception'].get('signal', ''))
for i, f in enumerate(t['frames']):
    img = imgs[f['imageIndex']]
    name = img.get('name', '?')
    line = '%2d %-22s +0x%x' % (i, name, f['imageOffset'])
    if name == 'LokaR1A2':
        # Caller frames hold return addresses; after a noreturn call (abort) that is past the
        # function's end, so look up the call instruction (address - 1), as symbolicators do.
        addr = img['base'] + f['imageOffset'] - (1 if i > 0 else 0)
        sym = subprocess.run(['xcrun', 'atos', '-o', dsym + '/Contents/Resources/DWARF/LokaR1A2', '-arch', 'arm64',
                              '-l', hex(img['base']), hex(addr)], capture_output=True, text=True).stdout.strip()
        line += '  atos(dSYM uuid ' + img['uuid'] + '): ' + sym
    elif 'symbol' in f:
        line += '  ' + f['symbol']
    print(line)
PY
    [ -s "$T/sym.txt" ] && cat "$T/sym.txt" >> "$EV/kill-stacks-symbolicated.txt" && redact < "$ips" > "$EV/crash/$b"
  done
  redact < "$EV/kill-stacks-symbolicated.txt" > "$T/k" && mv "$T/k" "$EV/kill-stacks-symbolicated.txt"
  cd "$APP" || exit 1
  (cd ../elixir && mise exec elixir@1.20.4 erlang@28.4 -- mix r1.runner < ../mobile/requests.jsonl) > "$T/elixir.jsonl"
  cp "$T/elixir.jsonl" "$EV/elixir-runner.jsonl"
  $X node --no-warnings scripts/check.mjs diff requests.jsonl "$T/elixir.jsonl" "$D/responses.jsonl" > "$EV/differential.txt"; echo "exit=$?" >> "$EV/differential.txt"
  $X node --no-warnings scripts/check.mjs faults "$D/faults.jsonl" "$K/main.jsbundle.map" "$T/faults.jsonl" > "$EV/faults-check.txt"; echo "exit=$?" >> "$EV/faults-check.txt"
  redact < "$T/faults.jsonl" > "$EV/faults.jsonl"
  echo "symbolication: node node_modules/metro-symbolicate/src/index.js <build-2/main.jsbundle.map> < stack (scripts/check.mjs); xcrun atos -o LokaR1A2.app.dSYM/Contents/Resources/DWARF/LokaR1A2 -arch arm64 -l <base> <addr> (kill-stacks-symbolicated.txt)" >> "$EV/faults-check.txt"
}

case "${1:-}" in
  build) build "$2" ;;
  compare) compare ;;
  run) run ;;
  *) echo "usage: iphone-11.sh build N | compare | run" >&2; exit 2 ;;
esac

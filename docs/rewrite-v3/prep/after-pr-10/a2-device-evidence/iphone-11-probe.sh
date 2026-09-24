#!/bin/bash
# Installs the Release app built by iphone-11-build.sh on the attached iPhone 11, launches it and captures:
#   iphone-11-devicectl.txt  raw `devicectl device info details` output, redacted
#   iphone-11-syslog.txt     raw `idevicesyslog -p LokaR1A2` output for the capture window, redacted
#   iphone-11-probe.txt      composed by this script: each command beside its output
# Redacted everywhere ([redacted]): UDID, ECID, serial number, device name, CoreDevice
# identifier, MAC addresses, the CoreDevice tunnel IP, the personal team ID (TEAM, from the environment) and the home directory.
set -u
: "${TEAM:?set TEAM to the personal team ID}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
EV=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$EV" rev-parse --show-toplevel)
A=$ROOT/r1-spike/mobile/ios/build/Build/Products/Release-iphoneos/LokaR1A2.app
UDID=$(idevice_id -l | head -1)
ECID=$(ideviceinfo -u "$UDID" -k UniqueChipID)
SERIAL=$(ideviceinfo -u "$UDID" -k SerialNumber)
NAME=$(ideviceinfo -u "$UDID" -k DeviceName)
T=$(mktemp -d)
xcrun devicectl list devices --json-output "$T/list.json" >/dev/null 2>&1
CDID=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(next(x['identifier'] for x in d['result']['devices'] if x['hardwareProperties'].get('udid')==sys.argv[2]))" "$T/list.json" "$UDID")
ECIDHEX=$(printf '%X' "$ECID")
redact() {
  V="$UDID
$ECID
$ECIDHEX
$SERIAL
$NAME
$CDID
$TEAM" perl -pe 'BEGIN{@v=grep{length}split /\n/,$ENV{V}} for my $v(@v){s/\Q$v\E/[redacted]/gi} s/\Q$ENV{HOME}\E/~/g;
    s/\b([0-9a-f]{2}:){5}[0-9a-f]{2}\b/[redacted]/gi; s/(Tunnel IP Address: ).*/$1\[redacted]/'
}
run() { echo "\$ $*"; "$@" 2>&1; echo "exit=$?"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  echo "host=M1 Air (m1-air-host.txt); DEVELOPER_DIR=$DEVELOPER_DIR"
  run xcrun devicectl --version
  run idevicesyslog --version
  echo "app: $A (built by iphone-11-build.sh; facts in iphone-11-pods.txt)"
  echo "executable sha256=$(shasum -a 256 "$A/LokaR1A2" | cut -d' ' -f1)"
  echo "main.jsbundle sha256=$(shasum -a 256 "$A/main.jsbundle" | cut -d' ' -f1)"
  echo "lipo -archs: $(lipo -archs "$A/LokaR1A2")"
  xcrun devicectl device info details --device "$UDID" 2>&1 | redact > "$EV/iphone-11-devicectl.txt"
  echo "--- xcrun devicectl device info details --device [redacted] > iphone-11-devicectl.txt (hardware/software lines)"
  grep -E 'CPU Count|CPU Type|Marketing Name|Product Type|OS Build Update|OS Version|Developer Mode Status|[Mm]emory|RAM' "$EV/iphone-11-devicectl.txt"
  run xcrun devicectl device install app --device "$UDID" "$A"
  idevicesyslog -u "$UDID" -p LokaR1A2 --no-colors > "$T/syslog.txt" 2>&1 &
  SP=$!
  sleep 3
  run xcrun devicectl device process launch --terminate-existing --device "$UDID" com.lorecrafting.lokar1a2
  sleep 15
  kill "$SP"; wait "$SP" 2>/dev/null
  redact < "$T/syslog.txt" > "$EV/iphone-11-syslog.txt"
  echo "\$ idevicesyslog -u [redacted] -p LokaR1A2 --no-colors > iphone-11-syslog.txt (started before launch, stopped 15 s after)"
  echo "--- probe lines of iphone-11-syslog.txt (JS console.log goes to os_log in Release)"
  sed -n '/LOKA_A2_PROBE/,/^}/p' "$EV/iphone-11-syslog.txt"
} 2>&1 | redact > "$EV/iphone-11-probe.txt"  # the whole composed file passes through redact()

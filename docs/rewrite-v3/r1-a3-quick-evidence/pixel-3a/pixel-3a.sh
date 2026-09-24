#!/bin/bash
# Usage: pixel-3a.sh <app-release.apk> <index.android.bundle.map> <run id>
# Quick R1-A3 on the Pixel 3a (derived from r1-a2-evidence/android/pixel-3a.sh). Installs the
# Actions APK with a fresh data directory, launches it once, waits (bounded) for a3-run.json in
# the app's external files directory while logging LOKA_A3_PROGRESS, pulls a3-samples.csv and
# a3-run.json, and writes beside this script:
#   pixel-3a-run.txt      each command beside its output (battery/thermal before and after)
#   pixel-3a-logcat.txt   raw `adb logcat -d` for ReactNativeJS and ActivityManager
#   a3-samples.csv, a3-run.json  as pulled;  summary.json  scripts/scale-summary.mjs
# Waits: the run fails if 90 minutes pass, if no new progress line appears for 10 minutes,
# if the app logs LOKA_A3_ERROR, if the process dies, or (invalid run) if the screen locks or the
# app leaves the foreground (checked every 10 s).
# redact() replaces the adb serial with [redacted], every UUID with [redacted-uuid], the home
# directory with ~, the repository root with [root] and temp paths with [scratch].
set -uo pipefail
APK=$1 MAP=$2 RUN=$3 PKG=com.lorecrafting.lokar1a2
EV=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$EV" rev-parse --show-toplevel)
FILES=/sdcard/Android/data/$PKG/files
SERIAL=$(adb get-serialno)
T=$(mktemp -d)
redact() {
  S="$SERIAL" R="$ROOT" perl -pe 's/\Q$ENV{S}\E/[redacted]/g; s/\Q$ENV{R}\E/[root]/g; s/\Q$ENV{HOME}\E/~/g;
    s#(?:/private)?/(?:tmp|var/folders)/[^\s"'"'"':,)\]]*#[scratch]#g;
    s/(?<![0-9A-Fa-f])[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}(?![0-9A-Fa-f])/[redacted-uuid]/g'
}
run() { echo "\$ $*"; "$@" 2>&1 | tr -d '\r'; echo "exit=${PIPESTATUS[0]}"; }
power() {
  run adb shell dumpsys battery
  echo "\$ adb shell dumpsys thermalservice (temperatures)"
  adb shell dumpsys thermalservice | tr -d '\r' | grep -E 'Thermal Status|Temperature\{' | sort -u
}
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  echo "git rev-parse HEAD: $(git -C "$ROOT" rev-parse HEAD)"
  echo "git status --porcelain (begin)"; git -C "$ROOT" status --porcelain; echo "(end)"
  run adb version
  echo "apk sha256 $(shasum -a 256 "$APK" | cut -d' ' -f1) bytes $(stat -f %z "$APK") (artifact app-release-apk, run $RUN)"
  echo "source map sha256 $(shasum -a 256 "$MAP" | cut -d' ' -f1) (index.android.bundle.map in artifact a2-android-evidence, run $RUN)"
  run adb shell getprop ro.build.fingerprint
  run adb shell getprop ro.product.model
  echo "--- before"
  power
  run adb install -r "$APK"
  run adb shell am force-stop "$PKG"
  run adb shell pm clear "$PKG"
  run adb logcat -c
  run adb shell am start -n "$PKG/.MainActivity"
  start=$(date +%s) last_change=$start last="" result=running
  while :; do
    sleep 10
    now=$(date +%s)
    if adb shell ls "$FILES/a3-run.json" >/dev/null 2>&1; then result=done; break; fi
    log=$(adb logcat -d ReactNativeJS:V '*:S' | tr -d '\r')
    grep -q LOKA_A3_ERROR <<<"$log" && { result="app error"; break; }
    adb shell pidof "$PKG" >/dev/null 2>&1 || { result="process gone"; break; }
    # The app must stay in the foreground with the screen unlocked, or the run is invalid.
    w=$(adb shell dumpsys window | tr -d '\r')
    grep -q "isKeyguardShowing=false" <<<"$w" || { result="INVALID: screen locked"; break; }
    grep -E "mCurrentFocus=.*$PKG" <<<"$w" >/dev/null || { result="INVALID: app not in foreground"; break; }
    p=$(grep -o 'LOKA_A3_PROGRESS.*' <<<"$log" | tail -1)
    if [ "$p" != "$last" ]; then last=$p last_change=$now; echo "t+$((now - start))s $p"; fi
    [ $((now - last_change)) -gt 600 ] && { result="no progress for 10 min"; break; }
    [ $((now - start)) -gt 5400 ] && { result="90 min limit"; break; }
  done
  echo "result=$result after $(($(date +%s) - start)) s"
  for f in a3-samples.csv a3-run.json; do run adb pull "$FILES/$f" "$T/$f"; done
  echo "--- after"
  power
  echo "\$ adb logcat -d -v threadtime ReactNativeJS:V ActivityManager:I '*:S' > pixel-3a-logcat.txt"
  adb logcat -d -v threadtime ReactNativeJS:V ActivityManager:I '*:S' | tr -d '\r' | grep -E "ReactNativeJS|$PKG" > "$T/logcat.txt"
} 2>&1 | redact > "$EV/pixel-3a-run.txt"
redact < "$T/logcat.txt" > "$EV/pixel-3a-logcat.txt"
[ -f "$T/a3-run.json" ] || { echo "no a3-run.json: run incomplete, see pixel-3a-run.txt" >&2; exit 1; }
cp "$T/a3-samples.csv" "$T/a3-run.json" "$EV/"
cd "$ROOT/r1-spike/mobile" || exit 1
mise exec node@24.21.0 -- node scripts/scale-summary.mjs "$EV/a3-samples.csv" "$EV/a3-run.json" > "$EV/summary.json"

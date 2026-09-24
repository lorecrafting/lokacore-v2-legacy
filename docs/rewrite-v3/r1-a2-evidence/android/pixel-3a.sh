#!/bin/bash
# Usage: pixel-3a.sh <app-release.apk> <index.android.bundle.map> <run id>
# R1-A2 Android evidence on the M1 with the Pixel 3a attached (derived from
# prep/after-pr-10/a2-device-evidence/pixel-3a-probe.sh). Installs the Actions APK with a
# fresh data directory, launches it until summary.json appears (each `kill` case SIGKILLs the
# process; this loop relaunches it, as no OS promises to), pulls responses.jsonl, faults.jsonl
# and summary.json from the app's external files directory, and captures:
#   pixel-3a-run.txt      composed by this script: each command beside its output
#   pixel-3a-logcat.txt   raw `adb logcat -d` for ReactNativeJS and ActivityManager (process deaths)
#   differential.txt      scripts/check.mjs diff: device lines vs the Elixir runner, plus one injected mismatch
#   faults-check.txt      scripts/check.mjs faults: verdicts, Elixir-runner cross-check, symbolication
#   faults.jsonl          the device records plus error.stack_symbolicated (release composed source map)
#   faults.device.jsonl, responses.jsonl, summary.json, elixir-runner.jsonl  as pulled / as produced
# redact() replaces the adb serial with [redacted], every UUID with [redacted-uuid], the home
# directory with ~ and scratchpad/temp paths with [tmp].
set -uo pipefail
APK=$1 MAP=$2 RUN=$3 PKG=com.lorecrafting.lokar1a2
EV=$(cd "$(dirname "$0")" && pwd)
APP=$(git -C "$EV" rev-parse --show-toplevel)/r1-spike/mobile
FILES=/sdcard/Android/data/$PKG/files
SERIAL=$(adb get-serialno)
T=$(mktemp -d)
redact() {
  S="$SERIAL" perl -pe 's/\Q$ENV{S}\E/[redacted]/g; s/\Q$ENV{HOME}\E/~/g;
    s#(?:/private)?/(?:tmp|var/folders)/[^\s"'"'"':,)\]]*#[tmp]#g;
    s/\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b/[redacted-uuid]/g'
}
run() { echo "\$ $*"; "$@" 2>&1 | tr -d '\r'; echo "exit=${PIPESTATUS[0]}"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  echo "git HEAD $(git -C "$APP" rev-parse HEAD)"
  run adb version
  echo "apk sha256 $(shasum -a 256 "$APK" | cut -d' ' -f1) bytes $(stat -f %z "$APK") (artifact app-release-apk, run $RUN)"
  echo "source map sha256 $(shasum -a 256 "$MAP" | cut -d' ' -f1) (index.android.bundle.map in artifact a2-android-evidence, run $RUN)"
  run adb shell getprop ro.build.fingerprint
  run adb install -r "$APK"
  run adb shell am force-stop "$PKG"
  run adb shell pm clear "$PKG"
  run adb logcat -c
  launches=0 done=0
  while [ $launches -lt 12 ] && [ $done = 0 ]; do
    launches=$((launches + 1))
    run adb shell am start -n "$PKG/.MainActivity"
    t=0
    while [ $t -lt 100 ]; do
      sleep 3; t=$((t + 1))
      if adb shell ls "$FILES/summary.json" >/dev/null 2>&1; then done=1; break; fi
      adb shell pidof "$PKG" >/dev/null 2>&1 || break
    done
    echo "launch $launches: done=$done after ~$((t * 3)) s (process $(adb shell pidof "$PKG" >/dev/null 2>&1 && echo alive || echo gone))"
  done
  echo "launches=$launches done=$done"
  for f in responses.jsonl faults.jsonl summary.json; do run adb pull "$FILES/$f" "$T/$f"; done
  echo "\$ adb logcat -d -v threadtime ReactNativeJS:V ActivityManager:I '*:S' > pixel-3a-logcat.txt"
  adb logcat -d -v threadtime ReactNativeJS:V ActivityManager:I '*:S' | tr -d '\r' | grep -E "ReactNativeJS|$PKG" > "$T/logcat.txt"
  echo "--- process deaths in the log (ActivityManager)"
  grep -E "Process $PKG .*has died|Killing .*$PKG" "$T/logcat.txt"
} 2>&1 | redact > "$EV/pixel-3a-run.txt"
redact < "$T/logcat.txt" > "$EV/pixel-3a-logcat.txt"
cp "$T/responses.jsonl" "$EV/responses.jsonl"; cp "$T/summary.json" "$EV/summary.json"; cp "$T/faults.jsonl" "$EV/faults.device.jsonl"
cd "$APP" || exit 1
(cd ../elixir && mise exec elixir@1.20.4 erlang@28.4 -- mix r1.runner < ../mobile/requests.jsonl) > "$EV/elixir-runner.jsonl"
X="mise exec node@24.21.0 --"
$X node --no-warnings scripts/check.mjs diff requests.jsonl "$EV/elixir-runner.jsonl" "$EV/responses.jsonl" > "$EV/differential.txt"; echo "exit=$?" >> "$EV/differential.txt"
$X node --no-warnings scripts/check.mjs faults "$EV/faults.device.jsonl" "$MAP" "$T/faults.jsonl" > "$EV/faults-check.txt"; echo "exit=$?" >> "$EV/faults-check.txt"
echo "symbolication: node node_modules/metro-symbolicate/src/index.js index.android.bundle.map < stack (run by scripts/check.mjs faults)" >> "$EV/faults-check.txt"
redact < "$T/faults.jsonl" > "$EV/faults.jsonl"

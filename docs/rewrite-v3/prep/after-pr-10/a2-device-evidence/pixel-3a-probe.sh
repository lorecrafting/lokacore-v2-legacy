#!/bin/bash
# Usage: pixel-3a-probe.sh <app-release.apk> <run id>
# Installs the CI APK on the attached Pixel 3a, launches the probe and captures:
#   pixel-3a-logcat.txt  raw `adb logcat -d` output for the probe's log tag (ReactNativeJS)
#   pixel-3a-probe.txt   composed by this script: each command beside its output
# The adb serial is replaced with [redacted] in both files.
set -u
APK=$1 RUN=$2 PKG=com.lorecrafting.lokar1a2
SERIAL=$(adb get-serialno)
redact() { sed "s/$SERIAL/[redacted]/g"; }
run() { echo "\$ $*"; "$@" 2>&1 | tr -d '\r' | redact; echo "exit=${PIPESTATUS[0]}"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  run adb version
  echo "apk sha256 $(shasum -a 256 "$APK" | cut -d' ' -f1) bytes $(stat -f %z "$APK") (artifact app-release-apk, run $RUN)"
  run adb shell getprop ro.build.fingerprint
  run adb install -r "$APK"
  run adb shell am force-stop "$PKG"
  run adb logcat -c
  run adb shell am start -n "$PKG/.MainActivity"
  sleep 10
  echo "\$ adb logcat -d -v threadtime ReactNativeJS:V '*:S' > pixel-3a-logcat.txt"
  adb logcat -d -v threadtime ReactNativeJS:V '*:S' | tr -d '\r' | redact > pixel-3a-logcat.txt
  echo "--- pixel-3a-logcat.txt"
  cat pixel-3a-logcat.txt
  echo "\$ adb shell dumpsys package $PKG | grep -E 'versionName|lastUpdateTime'"
  adb shell dumpsys package "$PKG" | tr -d '\r' | grep -E 'versionName|lastUpdateTime'
  echo "\$ adb shell dumpsys meminfo | grep 'Total RAM'"
  adb shell dumpsys meminfo | tr -d '\r' | grep 'Total RAM'
  run adb shell grep MemTotal /proc/meminfo
} > pixel-3a-probe.txt

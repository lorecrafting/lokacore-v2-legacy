#!/bin/bash
# Usage: actions-compare.sh <run-1 dir> <run-2 dir>   (each: `gh run download <id>` output)
# Compares two Actions builds of the same commit and writes build-compare.txt beside this script.
set -u
A=$1 B=$2 EV=$(cd "$(dirname "$0")" && pwd)
h() { shasum -a 256 "$1" | cut -d' ' -f1; }
js() { sed -n '/^--- JS/,/^--- APK entries/p' "$1/a2-android-evidence/apk-facts.txt"; }
entries() { sed -n '/^--- APK entries/,$p' "$1/a2-android-evidence/apk-facts.txt"; }
{
  for d in "$A" "$B"; do grep -E '^(source_commit|run_id|run_attempt|ImageVersion)=' "$d/a2-android-evidence/host.txt" | tr '\n' ' '; echo; done
  echo "apk: $(h "$A/app-release-apk/app-release.apk") vs $(h "$B/app-release-apk/app-release.apk")"
  echo "--- JS bundle / Hermes bytecode / source maps (diff; empty means identical)"
  diff <(js "$A") <(js "$B") && echo "(identical)"
  echo "--- APK entries whose sha256 differs"
  diff <(entries "$A") <(entries "$B") | grep '^[<>]' || echo "(none)"
  echo "--- strings in resources.arsc that differ (unzip -p app-release.apk resources.arsc | strings)"
  diff <(unzip -p "$A/app-release-apk/app-release.apk" resources.arsc | strings -n 3) \
       <(unzip -p "$B/app-release-apk/app-release.apk" resources.arsc | strings -n 3) | grep '^[<>]'
} > "$EV/build-compare.txt"
cat "$EV/build-compare.txt"

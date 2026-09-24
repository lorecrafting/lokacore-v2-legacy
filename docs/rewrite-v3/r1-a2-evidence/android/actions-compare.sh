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
  echo "--- whole-file layout: zip entries before the APK Signing Block, the block's ID-value pairs, central directory + EOCD"
  echo "    (0x7109871a = v2 signature, 0x504b4453 = AGP dependency-info block, 0x42726577 = verity padding)"
  python3 - "$A/app-release-apk/app-release.apk" "$B/app-release-apk/app-release.apk" <<'PY'
import hashlib, struct, sys
def parts(p):
    d = open(p, 'rb').read()
    eocd = d.rfind(b'PK\x05\x06'); cd = struct.unpack('<I', d[eocd + 16:eocd + 20])[0]
    start = cd - struct.unpack('<Q', d[cd - 24:cd - 16])[0] - 8
    out = {'zip entries [0, signing block)': d[:start], 'central directory + EOCD': d[cd:]}
    i = start + 8
    while i < cd - 24:
        n = struct.unpack('<Q', d[i:i + 8])[0]
        out['signing block pair 0x%08x' % struct.unpack('<I', d[i + 8:i + 12])[0]] = d[i + 12:i + 8 + n]
        i += 8 + n
    return out
a, b = parts(sys.argv[1]), parts(sys.argv[2])
for k in a:
    ha, hb = hashlib.sha256(a[k]).hexdigest(), hashlib.sha256(b.get(k, b'')).hexdigest()
    print('%s: %s bytes=%d %s %s' % (k, 'same' if ha == hb else 'DIFFERENT', len(a[k]), ha, hb))
PY
} > "$EV/build-compare.txt"
cat "$EV/build-compare.txt"

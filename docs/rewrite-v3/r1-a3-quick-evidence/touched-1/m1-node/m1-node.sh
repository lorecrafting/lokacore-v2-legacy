#!/bin/bash
# Usage: m1-node.sh
# touched-1 Node preview on the M1 (not phone evidence): regenerates both scale inputs and
# checks them against the committed files (r1-scale-1 = r1-spike/mobile/scale.jsonl, unchanged;
# r1-scale-2 = scale-2.jsonl, which the app bundles), runs the phone timing code
# (r1-spike/mobile/scale.ts) on Node 24 + node:sqlite through scripts/scale-local.mjs, then
# summarizes with scripts/scale-summary.mjs. Writes beside this script:
#   m1-node-run.txt   each command beside its output (host facts, power, load before/after)
#   a3-samples.csv, a3-run.json, summary.json
# redact(): the home directory -> ~, the repository root -> [root], temp paths -> [scratch],
# the pmset battery object id -> [redacted].
set -uo pipefail
EV=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$EV" rev-parse --show-toplevel)
T=$(mktemp -d)
X="mise exec elixir@1.20.4 erlang@28.4 node@24.21.0 --"
redact() {
  R="$ROOT" perl -pe 's/\Q$ENV{R}\E/[root]/g; s/\Q$ENV{HOME}\E/~/g;
    s#(?:/private)?/(?:tmp|var/folders)/[^\s"'"'"':,)\]]*#[scratch]#g;
    s/\(id=\d+\)/(id=[redacted])/g'
}
run() { echo "\$ $*"; "$@" 2>&1; echo "exit=${PIPESTATUS[0]}"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  echo "git rev-parse HEAD: $(git -C "$ROOT" rev-parse HEAD)"
  echo "git status --porcelain (begin)"; git -C "$ROOT" status --porcelain; echo "(end)"
  run sw_vers
  run sysctl hw.model hw.ncpu hw.memsize machdep.cpu.brand_string
  run $X node --version
  echo "--- before"
  run pmset -g batt
  run uptime
  cd "$ROOT/r1-spike/harness" || exit 1
  run $X mix r1.scale --version r1-scale-1 --out "$T/scale-1.jsonl"
  run cmp "$T/scale-1.jsonl" "$ROOT/r1-spike/mobile/scale.jsonl"
  run $X mix r1.scale --version r1-scale-2 --out "$T/scale-2.jsonl"
  run cmp "$T/scale-2.jsonl" "$ROOT/r1-spike/mobile/scale-2.jsonl"
  run shasum -a 256 "$ROOT/r1-spike/mobile/scale.jsonl" "$ROOT/r1-spike/mobile/scale-2.jsonl"
  cd "$ROOT/r1-spike/mobile" || exit 1
  echo "\$ node scripts/scale-local.mjs scale-2.jsonl [scratch] (progress lines omitted)"
  $X node --no-warnings scripts/scale-local.mjs scale-2.jsonl "$T/out" 2>&1 | grep -v LOKA_A3_PROGRESS
  echo "exit=${PIPESTATUS[0]}"
  echo "--- after"
  run pmset -g batt
  run uptime
} 2>&1 | redact > "$EV/m1-node-run.txt"
cp "$T/out/a3-samples.csv" "$T/out/a3-run.json" "$EV/"
cd "$ROOT/r1-spike/mobile" || exit 1
$X node scripts/scale-summary.mjs "$EV/a3-samples.csv" "$EV/a3-run.json" > "$EV/summary.json"

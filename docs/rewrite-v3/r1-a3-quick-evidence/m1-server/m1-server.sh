#!/bin/bash
# Usage: m1-server.sh
# Quick R1-A3 on the M1 server host: regenerates the scale input and checks it equals the
# committed r1-spike/mobile/scale.jsonl, runs `mix r1.scale_timing` (r1-spike/server), then
# summarizes with r1-spike/mobile/scripts/scale-summary.mjs. Writes beside this script:
#   m1-server-run.txt   each command beside its output (host facts, power, load before/after)
#   a3-samples.csv      raw per-step samples (measured steps)
#   a3-run.json         per-model facts (state sizes, final-state hash, checkpoint samples)
#   summary.json        percentiles and gate verdicts
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
  run $X elixir --version
  run $X node --version
  echo "--- before"
  run pmset -g batt
  run uptime
  cd "$ROOT/r1-spike/harness" || exit 1
  run $X mix r1.scale --out "$T/scale.jsonl"
  run cmp "$T/scale.jsonl" "$ROOT/r1-spike/mobile/scale.jsonl"
  run shasum -a 256 "$ROOT/r1-spike/mobile/scale.jsonl"
  cd "$ROOT/r1-spike/server" || exit 1
  echo "\$ mix r1.scale_timing --in scale.jsonl --out [scratch] (progress lines omitted)"
  $X mix r1.scale_timing --in "$ROOT/r1-spike/mobile/scale.jsonl" --out "$T/out" 2>&1 | grep -v LOKA_A3_PROGRESS
  echo "exit=${PIPESTATUS[0]}"
  echo "--- after"
  run pmset -g batt
  run uptime
} 2>&1 | redact > "$EV/m1-server-run.txt"
cp "$T/out/a3-samples.csv" "$T/out/a3-run.json" "$EV/"
cd "$ROOT/r1-spike/mobile" || exit 1
$X node scripts/scale-summary.mjs "$EV/a3-samples.csv" "$EV/a3-run.json" > "$EV/summary.json"

#!/bin/bash
# Usage: checks.sh [diff base seed]
# touched-1 correctness checks on the M1, all against the unchanged fixtures and the Elixir
# runner as a black box. Writes beside this script:
#   checks-run.txt          each command beside its output
#   r1-diff-summary.json    the differential report (regression seeds + 10,000 fresh sequences)
#   a2-local-summary.json   the phone durable host on Node + node:sqlite (scripts/local-check.mjs):
#                           the 139-line differential and the 19 fault cases
# Checks: TypeScript type check and fixture suite (89 fixture tests plus the frozen-input
# sharing test), harness tests, the fast differential, and the A2 local check, whose 139 lines
# are compared byte for byte with `mix r1.runner` (scripts/check.mjs diff) and whose 19 fault
# records are cross-checked with the Elixir runner (scripts/check.mjs faults; no source map on
# Node, so stack symbolication is reported as failed and is not part of the check).
# redact(): the home directory -> ~, the repository root -> [root], temp paths -> [scratch].
set -uo pipefail
EV=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$EV" rev-parse --show-toplevel)
SEED=${1:-20260925}
T=$(mktemp -d)
X="mise exec elixir@1.20.4 erlang@28.4 node@24.21.0 --"
redact() {
  R="$ROOT" perl -pe 's/\Q$ENV{R}\E/[root]/g; s/\Q$ENV{HOME}\E/~/g;
    s#(?:/private)?/(?:tmp|var/folders)/[^\s"'"'"':,)\]]*#[scratch]#g'
}
run() { echo "\$ $*"; "$@" 2>&1; echo "exit=${PIPESTATUS[0]}"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  echo "git rev-parse HEAD: $(git -C "$ROOT" rev-parse HEAD)"
  echo "git status --porcelain (begin)"; git -C "$ROOT" status --porcelain; echo "(end)"
  cd "$ROOT/r1-spike/ts" || exit 1
  run $X node node_modules/typescript/bin/tsc -p .
  echo "\$ node --test 'test/*.test.ts' (summary lines)"
  $X node --test 'test/*.test.ts' 2>&1 | grep -E '^(not ok|ℹ (tests|pass|fail))'
  echo "exit=${PIPESTATUS[0]}"
  cd "$ROOT/r1-spike/elixir" || exit 1
  run $X mix compile
  cd "$ROOT/r1-spike/harness" || exit 1
  run $X mix test
  run $X mix r1.diff --sequences 10000 --seed "$SEED" --report "$T/r1-diff-summary.json"
  cd "$ROOT/r1-spike/mobile" || exit 1
  run $X node --no-warnings scripts/local-check.mjs requests.jsonl "$T/a2"
  echo "\$ (cd ../elixir && mix r1.runner) < requests.jsonl > [scratch]/elixir.jsonl"
  (cd ../elixir && $X mix r1.runner) < requests.jsonl > "$T/elixir.jsonl"
  echo "exit=$?"
  run $X node scripts/check.mjs diff requests.jsonl "$T/elixir.jsonl" "$T/a2/responses.jsonl"
  echo "\$ node scripts/check.mjs faults [scratch]/a2/faults.jsonl /dev/null [scratch]/faults-checked.jsonl"
  $X node scripts/check.mjs faults "$T/a2/faults.jsonl" /dev/null "$T/faults-checked.jsonl" 2>&1
  echo "exit=$?"
} 2>&1 | redact > "$EV/checks-run.txt"
cp "$T/r1-diff-summary.json" "$EV/"
cp "$T/a2/summary.json" "$EV/a2-local-summary.json"

#!/bin/sh
# The real durable runner over a database with a trigger that rewrites every
# stored failed-roll receipt (check_failed -> check_fai1ed). The host's own
# output path is untouched, so only the SQLite read-back differs: the
# differential test must catch it. Run from r1-spike/server after `mix compile`.
set -e
db="$(mktemp -d)/mutant.sqlite"
mix run test/support/mutant_trigger.exs "$db" > /dev/null
exec mix r1.durable_runner --db "$db"

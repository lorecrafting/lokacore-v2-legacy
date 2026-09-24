# Harness notes

## Protocol edge rules

The README's "Protocol edge rules (settled 2026-09-23)" answer the seven questions
this file used to raise. Since r1-gen-2 the generator emits the settled cases as
about 5% of lines (10% of each sequence's extra request):

- extra top-level keys on `rng.next`, `int.divide`, `json.canonical`, `world.run`
  and `composition.evaluate`;
- `world.run` with `commands: []`, with non-object commands (`5`, `null`,
  `"recover"`, `[]`, `true`, `0`) mixed with valid ones, with an invalid `world`
  name or type, and with a non-object `initial`;
- `composition.evaluate` with bad `limits` (zero, negative, non-integer, unknown
  key, `selector_cardinality`, which is a profile limit, and non-object values),
  `advance_target: null`, a non-list `root`, an object `rules`, and an `initial`
  that is empty or missing `clock`;
- blank and whitespace-only lines, including `\r`;
- valid pure-function lines ending in `\r`;
- invalid UTF-8 lines (a lone `0xFF`, an overlong `0xC0 0xAF`, a bare continuation
  byte, a UTF-8-encoded surrogate, a truncated sequence, a trailing `0xFF`, and a
  non-UTF-8 key byte).

Valid `limits` values are now 1 or more, since the README defines 0 as
`invalid_protocol`.

**Still unspecified, never generated:** an `initial` object that isn't a
complete, in-range memory of its world with a nonzero RNG, and revision overflow
past 2^53−1. The generator keeps the initial revision at or below 2^53−1−64.

## Byte handling

Requests go to the runner ports as raw bytes followed by `\n`. The ports run in
stream mode, and the harness splits responses on `\n` itself. Erlang's
`{:line, N}` port mode would also strip a trailing `\r`, which would hide a
runner that ends its lines with `\r\n`. A self-test checks that difference. The
fake test runner is `test/support/fake_runner.py`, because Erlang's line readers
normalise `\r\n` too. Report fields that aren't valid UTF-8 are written as
`"base64:..."`.

## Assumptions

- **Runners are stateless across lines.** Each request is self-contained, so one
  pair of long-lived processes serves the whole run, including minimization.
- **`mix r1.runner` writes nothing to stdout except response lines.** In
  particular, it must not print compiler output. CI compiles `../elixir` before the
  differential step for this reason.
- **The generator makes no assumption about what `look` publishes.** Both runners
  must agree on it; per the model and the TypeScript side, a Lantern `look`
  publishes nothing.

## Generator coverage (measured at r1-gen-1)

Half of the `world.run` sequences are "focused": they follow a scripted path
through the world with little noise. The other half are noisy. I replayed 3,000
sequences through the Python models with a scratch adapter that isn't checked in.
Focused sequences reach `taken`, `check_failed`, tiny `choice_completed` (about
700), lantern `choice_opened`, `activated_with_possession` and
`resolved_carry`/`resolved_leave` (about 85), as well as replays of each. Noisy
sequences cover every rejection code, the four faults, the retryable codes,
`recover` while pending, settle with no pending transaction, and the step errors
`invalid_options`, `unknown_fault`, `invalid_commit_disposition` and
`invalid_command`.

## Retaining a failure

A mismatch writes the `--report` summary before minimization and again after it.
The report holds the origin (`regression`, `fresh` or `replay`), the sequence seed,
the request, both responses and the minimized request. `mix r1.diff --replay SEED`
reruns a single sequence. After a fix has been reviewed, add the seed to
`regression-seeds.json`. Admitting the minimized case as a fixture goes through the
ordinary expected-answer review. Any change to generator output requires a bump to
`Generator.version/0`, because a seed only reproduces its failure under the same
generator version.

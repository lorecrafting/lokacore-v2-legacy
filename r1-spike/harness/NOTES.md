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

## Composition coverage (r1-gen-3)

Every plan starts out valid. It has a guarded reaction chain, `c0`..`c(d-1)` on
`proof.signal`, 1 to 5 rules deep. It may also have a fan-out to `proof.followup`,
an item transfer that a rule on `engine.item_transferred` watches, and a future
job. The rules are shuffled, and all of them are active except sometimes `fan`,
which the root activates. Of all plans:

- about 30% stay valid;
- about 40% get one runtime twist: a small limits override for each budget, two
  rules writing the same fact, a containment cycle, capacity overflow,
  `not_owned`, an unknown destination, a non-future or duplicate job, the
  created-jobs and pending-jobs caps, an advance target, an out-of-bounds fact, or
  an unguarded `proof.followup` loop;
- about 30% get one validation defect.

`test/support/composition_tally.py` runs the plans through `composition_model.py`.
A self-test asserts that 2,000 plans hit every fault code in the model, with the
vocabulary read from the model's source, and at least one accepted result with 3
or more deliveries. Tally for seed 1: ok 567, of which 407 have 3 or more
deliveries; conflicting_write 124; invalid_time 106; unknown_subscription 86;
not_owned 80; budget_reaction_depth 77; invalid_registry 64; nonfuture_job 60;
budget_created_jobs 51; unknown_policy 49; invalid_operation 46; invalid_rule 45;
budget_operations 44; budget_deliveries 44; budget_query_steps 42;
budget_pending_jobs 42; duplicate_job 42; invalid_job 42; invalid_plan 41;
resource_bounds 41; budget_output_bytes 39; invalid_target 39; forbidden_event 35;
unknown_destination 35; unknown_operation 32; budget_events 28;
containment_cycle 26; capacity_exceeded 23; invalid_event 22; invalid_value 14;
unknown_fact 14.

## Retaining a failure

A mismatch writes the `--report` summary before minimization and again after it.
The report holds the origin (`regression`, `fresh` or `replay`), the sequence seed,
the request, both responses and the minimized request. `mix r1.diff --replay SEED`
reruns a single sequence. After a fix has been reviewed, add the seed to
`regression-seeds.json`. Admitting the minimized case as a fixture goes through the
ordinary expected-answer review. Any change to generator output requires a bump to
`Generator.version/0`, because a seed only reproduces its failure under the same
generator version.

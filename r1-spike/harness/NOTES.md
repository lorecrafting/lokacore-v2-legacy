# Harness notes

## Protocol ambiguities

`../README.md` does not settle these cases. The generator does not emit them (it
emits only the unambiguous variants), so a disagreement between runners here
cannot block CI until the README decides. Each one should be settled in the README,
then generated.

1. **Extra top-level request keys**, such as `{"fn":"rng.next","state":[1,2,3,4],"x":1}`.
   Is that a malformed argument (`invalid_protocol`), or is the key ignored?
2. **`world.run` with an empty `commands` list or more than 64 commands.** Should
   the answer be `[]`, the step records, or `invalid_protocol`?
3. **A non-object entry in `commands`**, such as `5`. Is it `invalid_command` for that
   step, or `invalid_protocol` for the whole line? The README lists only an unknown
   `op` and missing or extra fields.
4. **A malformed `initial`**: not an object, missing or extra keys, wrong value types,
   values outside the world's domain (for example `room: "shelter"` in a tiny world,
   which makes the Python model raise `KeyError` on `move`), or an all-zero RNG. That
   RNG makes `take` raise `invalid_rng_state` inside the model's `invoke`, and the
   README has no step error for it. The generator emits only full-shape,
   in-domain states with nonzero RNG words.
5. **Revision overflow.** An accepted step at revision 2^53−1 yields 2^53, and the
   model does not check for it. The generator keeps the initial revision at or below
   2^53−1−64.
6. **Wrong top-level types in `composition.evaluate`**, such as `root` or `rules`
   that aren't lists, or `initial` or `limits` that aren't objects. Is that
   `invalid_protocol`, or the model's `{"kind":"fault","code":"invalid_plan"}`? The
   same question covers `initial` with missing keys, `limits` with unknown keys or
   non-integer or negative values, and `advance_target: null` (explicit null versus
   absent).
7. **Line-level edge cases**: a blank line, invalid UTF-8 bytes (a Node reader
   decoding stdin as UTF-8 would substitute U+FFFD rather than reject), and
   `\r\n` line endings.

## Assumptions

- **Runners are stateless across lines.** Each request is self-contained, so one
  pair of long-lived processes serves the whole run, including minimization.
- **An absent `options.authorized` means authorized.** This matches the model's
  default. The README says `authorized` is optional but gives no default. Most
  generated invokes rely on this.
- **`int.divide`'s `integer_out_of_range` can't be reached through the protocol.**
  Out-of-range integer literals already fail the strict parse, so they get
  `invalid_protocol`. The generator sends them only as deliberately malformed lines.
- **`mix r1.runner` writes nothing to stdout except response lines.** In
  particular, it must not print compiler output. CI compiles `../elixir` before the
  differential step for this reason.

## Generator coverage (r1-gen-1)

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

# Oracle recheck of the A1 correction (PR #24) — 2026-09-23

**Final disposition for the eight-input set at PR #24's head: APPROVE WITH NOTES.**
The one blocking value is corrected to the contract-derived answer; no other
frozen answer in any of the eight inputs moved; the new hash is bound
consistently; the README and ADR wording are accurate. The notes are the ones
already recorded (A2 and the coverage limits in the two earlier reports). No
receipt is filled by this recheck.

## 1. Subject

| Item | Value |
|---|---|
| PR | #24, branch `prep/v3-adverse-fix-a1`, head `3e18cf8eee1d6c64be28b16225aa88515fdf5cfa` (merge of `origin/main` into `f6c69ab`) |
| Base | `origin/main` `80e1b251d16515111d3e365cb88a37af37b54ec0` (merge of PR #23) |
| Scope | `git diff origin/main...origin/prep/v3-adverse-fix-a1`: seven files, 13 insertions, 10 deletions |
| Eighth input | `conformance/adverse-cases.json`, SHA-256 `1b699cf2ce71181a2b09a596ed2253c06caa435aad4b5eb8a8ea9601fbadf5b1` |
| Seven prior inputs | unchanged bytes and hashes |

Reviewer: the same fresh Fable 5.1 agent session as the two earlier reports, under
the owner's account; I did not write or edit any file in PR #24. The PR author is
the Claude Opus implementing session (git attribution "Raymond Luong").

## 2. What changed in the eighth input

- Textual diff: one line. `bad-envelopes`, second step, `"code": "unauthorized"`
  becomes `"code": "invalid_envelope"`.
- Semantic diff (JSON-level comparison of every section, case and step between
  `origin/main` and the PR head): exactly one step differs, in `result.code`
  only; its `state` is identical. All eleven `uniform` rows, the other twelve
  Tiny cases, twenty composition cases and eleven Lantern cases are
  byte-for-byte the values I derived in `2026-09-23-oracle-review-adverse.md`.
- The corrected value is my derivation: 03 §14 validates the bounded envelope
  before authenticate/authorize, and `{}` has no `id`, `actor` or `action`.

## 3. The model reorder moves no frozen answer

`checks/contract_model.py:215-225` now calls `_intent` (envelope validation)
before the harness authorization / actor check. Evidence that no frozen answer
in any of the eight inputs moved:

- The full Python suite (118 tests) compares the models against all eight
  frozen files on the PR head and is green, including `cases.json`,
  `lantern-traces.json` and the unchanged 54 adverse cases.
- Direct probes of the reordered model: `{}` → `invalid_envelope`; a malformed
  request from a foreign actor → `invalid_envelope`; a well-formed request from
  a foreign actor → `unauthorized`; a well-formed request with harness-denied
  authorization → `unauthorized`; none of the four creates a receipt. The two
  frozen `unauthorized` steps (`unauthorized-cannot-read-receipt` steps 4–5) are
  well-formed, so they are unaffected.
- The old check order, applied as a mutant to the corrected model, now fails
  `test_adverse.py` (one failure: the corrected step). The four mutants from the
  previous review (restore RNG after a failed check, publish before commit,
  receipt on definite rollback, remove the unknown-COMMIT fence) are still
  caught (1, 2, 2 and 5 failing cases).

## 4. Binding of the new hash

`1b699cf2…f5b1` is the SHA-256 of the file on the PR head and appears
identically in `prep/after-pr-10/oracle-review.pending.json` (8 inputs),
`prep/after-pr-10/setup.pending.json` (8 inputs) and
`spec_tools/preserved-inputs.json` (12 entries, all matching current bytes).
`setup.pending.json`'s `oracle_review.sha256` (`2bd7533a…`) equals the current
bytes of the pending oracle record. The template keeps eight null-hash entries;
both checkers' input lists are unchanged from PR #22 (eight paths, same order).

## 5. README and ADR wording

- `conformance/README.md` new paragraph: the fact schema (`flag`, `seen` in 0–2
  with no arithmetic; `count` signed 32-bit) matches `composition_model.py:32`
  and the `fact.add` restriction at `:54`; the six `published` event names are
  exactly the names the two frozen `published` lists use; the statement that
  this is fixture vocabulary, not a production schema, is the right status.
  Accurate (closes A3 and A4).
- ADR-069: "plus two rejection-sampling rows the review verified independently;
  it adds no contract behavior" is now accurate (closes A5). The added sentence
  that the model checked authorization before envelope validation, against
  03 §14, and that the model and the one answer were corrected before approval,
  matches what happened (closes A1). Status still says owner acceptance pending,
  which remains true.
- A2 (authority `revision` disclosed in `unauthorized` / `invalid_envelope`
  responses) is left as a recorded note, as the coordinator said; I have no
  objection to that.

## 6. Command results (PR head `3e18cf8`)

| Command | Result | Exit |
|---|---|---|
| `python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py'` | 118 tests OK | 0 |
| `python3 docs/rewrite-v3/checks/release_scope.py --check` | PASS | 0 |
| `python3 docs/rewrite-v3/checks/packet_navigation.py --check` | PASS | 0 |
| `python3 docs/rewrite-v3/checks/readiness.py --check-template` | PASS | 0 |
| `git diff --check` | clean | 0 |
| `mix format --check-formatted` (spec_tools, Elixir 1.20.4 / OTP 28.4 via mise) | clean | 0 |
| `mix compile --warnings-as-errors` | compiled | 0 |
| `mix test` | 25 passed, 3 excluded | 0 |
| `mix test --include comparison` | 28 passed | 0 |
| `mix loka.readiness --check-template` | PASS | 0 |
| Eight `--require-ready` probes (Python and Elixir × A1/A2 × template/`setup.pending.json`) | all NOT READY | all 1 |

Manual work: JSON-level semantic diff of the fixture between main and the PR
head; five model mutants run in a scratch copy of `checks/` against the
unmodified fixture; four direct model probes.

## 7. Remaining

1. Owner: accept the amended revision that carries ADR-069 (its status still
   says acceptance pending).
2. Operator: after 1, fill `oracle-review.pending.json` against the eight
   hashes at PR #24's head (or its merge), citing the three reports.
3. Coverage limits from the two earlier reports stand unchanged (durable outbox
   after a lost acknowledgement, multi-job advance, the listed numeric and
   Tiny/Lantern edges); they are for the differential-testing generator, not a
   condition of this approval.

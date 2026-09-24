# Independent oracle review of the eighth input (adverse cases) — 2026-09-23

**Disposition for the eight-input set: BLOCK, narrowly.** One frozen value in
`conformance/adverse-cases.json` contradicts the normative admission order in
03 §14 (finding A1). Every other value in the file, and every value in the seven
inputs already reviewed, agrees with what I derived from the contracts. The
correction is one expected code (or one removed step) plus the re-hash; after it,
the file can be re-reviewed by checking that step and the new hash alone.

The seven inputs reviewed in `2026-09-23-oracle-review.md` keep their
APPROVE WITH NOTES. No receipt is filled by this review.

## 1. Subject

| Item | Value |
|---|---|
| PR | #22, branch `prep/v3-adverse-fixtures`, head `9b4b056055e6fddaf06d995b844576a9457f9026` (merge of `origin/main` into `8d20500`) |
| Author of the PR | Claude Opus implementing session under the owner's account (coordinator's own statement); git attribution "Raymond Luong" / "lorecrafting" |
| Base when the review started | `origin/main` `a4b5839` (merge of PR #21) |
| Merged before review finished | The owner merged PR #22 by accident as `05ae83123ed337e24f69f2da99b76abd84b97dd5` while this review was in progress. I verified `git diff 9b4b056 05ae831` is empty, so the bytes reviewed are the bytes now on main. The merge is not an acceptance; finding A1 goes to a follow-up correction PR, nothing is reverted |
| New input | `conformance/adverse-cases.json`, SHA-256 `c4c780e3bbf13b15f17cff096c5f92f884efda00d71171cf0c4bbdd7911cc634` |
| Seven prior inputs | unchanged; hashes as in the first report |

The values in the new file were produced by running the Python models; the
coordinator said so. I derived each value from the contracts before comparing.

## 2. Reviewer provenance

Same fresh Fable 5.1 agent session as the first report, spawned by the coordinator
under the owner's account. I did not write or edit any file in PR #22. The owner
has confirmed (per the coordinator) that a fresh Fable agent counts as the
independent oracle reviewer; that confirmation is the owner's to record, not mine.
The subject author is a Claude Opus session under the same account; the same
same-vendor relation disclosed in the first report applies here.

## 3. Findings

### A1 — `bad-envelopes` step 2 freezes `unauthorized` for an empty request (medium; blocks the hash)

- Where: `conformance/adverse-cases.json`, case `bad-envelopes`, second step:
  request `{}` → expected `{"kind":"rejected","code":"unauthorized","revision":0}`.
- Contract: 03 §14 fixes the order "validate bounded request envelope;
  authenticate → authorize access to the logical lineage/actor". 04 §2: the
  gateway supplies authenticated identity and "the server verifies the invocation
  actor is controllable by that session" after the invocation is parsed. An
  empty object has no `id`, `actor` or `action`; it fails envelope validation
  before any actor check can run.
- Expected: `invalid_envelope` (the code the same case gives to `[]`, an unknown
  field and a non-list `targets`). Observed: `unauthorized`.
- Why it is frozen this way: `checks/contract_model.py:219` tests
  `request.get("actor") != "hero"` before `_intent` validates the envelope
  (`:222`). The old assertion (`test_contracts.py:148`) checked only
  `kind == "rejected"`, so the model's order was never held to a code. Freezing
  the model's output turned that order into an expected answer.
- Consequence: a candidate that implements 03 §14's order fails this step.
- Smallest correction: change the step's expected code to `invalid_envelope` and
  make the model validate the envelope before the actor check (or drop the step).
  Re-hash and re-bind. This is the only value I could not derive from the
  contracts.

### A2 — Unauthorized and malformed responses disclose the authority revision (low)

`unauthorized-cannot-read-receipt` steps 4–5 and `bad-envelopes` freeze
`revision: 3` / `revision: 0` inside `unauthorized` and `invalid_envelope`
responses. 03 §14 requires that no receipt be disclosed before authorization; the
current game revision is not a receipt, but freezing it as bytes obliges a
candidate to return it to an unauthenticated caller. Model response shape, not a
contract requirement. Suggest a README sentence that `revision` in rejected
pre-admission responses is fixture shape only, or freeze it as `null` in a later
amendment.

### A3 — Fact schema is implicit (low)

`integer-overflow` (`count` bounded to signed 32-bit) and `enum-arithmetic`
(`fact.add` on `flag` is `invalid_operation`) depend on per-fact types and bounds
declared only in `checks/composition_model.py:32`, not in `composition-profile.json`
or any input. Same class as the first report's F4. One README sentence.

### A4 — `published` freezes a model event vocabulary (low)

`definite-rollback` and `response-loss` fix the names `quest_activated`,
`entity_entered_room`, `check_passed`, `item_acquired`, `quest_resolved`,
`fact_changed` and their order. 04 §9's illustrative chain has
`quest_objective_completed`, which the fixture omits; no input registers the Tiny
event set. The semantic content (nothing before COMMIT, nothing twice on response
loss) is right. Suggest a README sentence naming these as the Tiny fixture's
registered events.

### A5 — ADR-069 wording (info)

"It records what the retained checks already asserted; it adds no behavior" is
slightly off: the first two `uniform` rows use the state `[1,2199679431,3,4]`,
which no retained check asserted (the checks used mocked draws). The values are
correct (see §4). Wording only.

### A6 — Model vocabulary now frozen (info)

`rng_budget_exhausted`, `invalid_bound`, `invalid_rng_state`, `close_choice`,
`exit_unavailable`, `activated_with_possession` and the harness-only
`options.authorized`/`options.fault` are model names that candidates must now map
to. Acceptable as fixture vocabulary; note it in the README so a candidate's typed
error taxonomy (04 §7) is mapped rather than renamed.

## 4. Derivations

**`uniform` (11 rows).** Rows 1–3 recomputed with my own C rendition of
xoshiro128** 1.1: from `[1,2199679431,3,4]` bound 100, the first raw 4294967295
is at or above the threshold 4294967200 and is rejected, the second raw 4294955775
is accepted, value 75, next state `[3817741343,954437125,2199680448,2473519876]`;
with `max_draws: 1` the same state exhausts the budget; from step-4 state
`[27274249,25704967,31982592,12605441]` one draw gives 2031721883, value 83, next
state equals numeric-vectors step 5. Rows 4–7 (`0`, `-1`, `true`, `2^32+1`) violate
"1 <= bound <= 2^32" and "booleans are not integers"; rows 8–11 violate "four
explicit unsigned 32-bit words, not all zero". All eleven correct.

**`tiny` (13 cases).**
- `failed-check-commits-next-rng`: 83 ≥ 50 fails; accepted `check_failed`,
  revision 3, RNG advanced, lantern stays; replay with stale view is byte-stable;
  a new id draws from the advanced state: raw 1637235492, value 92, fails again,
  next state `[1110993931,286554632,2431677446,2165318166]` (my C run). Correct per
  04 §5.0, ATTEMPT-01.
- `rejection-receipt-is-stable`: `not_present` at revision 0 with no change; after
  the world moves to revision 1 the same id replays the rejection with its
  original revision 0. Correct per 03 §14 ("the chosen terminal result then
  replays", replay returns the original revision).
- `unauthorized-cannot-read-receipt`: harness-denied and foreign actor both get
  `unauthorized` with no state change. Correct per 03 §14 and 04 §2 (see A2 for
  the revision field).
- `changed-intent-conflicts`: `maximum_price` input, target order and action
  change conflict; session/seq/route/view changes replay. Correct per 03 §14
  (two digests; transport and freshness fields are not intent) and RECEIPT-05.
- `consumed-choice`: consumed choice replays revision 4 while state stays at 5;
  altered ending conflicts; a new id on the consumed offer is `invalid_choice`.
  Correct per RECEIPT-04/05 and 04 §2 ("never reruns a consumed action").
- `new-stale-invocation`: `stale_view`, no change. Correct per 04 §2 freshness
  validation for NEW attempts.
- `definite-rollback`: nothing published, no receipt, RNG untouched, same id then
  runs fresh and draws 20 from `[1,2,3,4]`. Correct per 04 §5.1, 03 §15, envelope
  §9.
- `unknown-commit-was-committed` / `-not-committed`: fence on every request and on
  recover until settled; committed → durable at revision 3, memory unchanged until
  recover, then replay; not committed → recover at revision 2, then the same id
  runs new. Correct per 03 §15 and RECOVERY-01.
- `commit-before-memory`: `commit_unknown`, durable ahead of memory, fenced retry,
  recover adopts durable, retry replays. Correct per 03 §15.
- `response-loss`: memory adopted and events published once; recover; replay adds
  nothing. Correct per 03 §14 ("Replays never rerun effects").
- `bad-envelopes`: `[]`, unknown field and non-list `targets` → `invalid_envelope`
  with no change; `{}` → see A1.
- `malformed-direction`: `invalid_input`, no change. Correct.

**`composition` (20 cases).** For each `budget-*` case only the named cap is
lowered to 2 (or 1 for jobs) while the others stay at profile values (≥ 32), so on
a self-re-emitting rule that cap is necessarily the first exhausted whatever the
exact accounting; the expected code, unchanged state and empty events follow from
04 §5.4 ("do not commit a truncated chain") and COMPOSE-04. `budget-output-bytes`
(cap 20, one 40-byte payload) faults before any publication. `integer-overflow`
and `enum-arithmetic` are right given the implicit schema (A3). `nonfuture-job`
with target 19 and due 8 follows 04 §5.4 ("strictly later than its target").
`budget-created-jobs`, `budget-pending-jobs`, `duplicate-job`,
`unregistered-operation`, `fact-set-boolean-value`, `guard-boolean-not-integer`
(no delivery; the event is still recorded at position 1), three
`advance-target-*` cases, `competing-transfers` (04 §5.3 "two destinations for the
same item conflict") and `distinct-events-both-delivered` (COMPOSE-01) all match.

**`lantern` (11 cases).** Prefix `lantern-carry[1:8]` is the seven travel/take
steps without `activate`, so revision 7 with the lantern held and the quest
absent; `activate` then credits possession at revision 8 without an RNG draw and
the leave path ends at revision 10 with one narration and one milestone. Prefix
`[0:9]` is the nine steps through `talk`. From there: `drop` moves the lantern to
`landing` and the choice is `not_owned`; `wait 19` moves Bram to green and the
choice is `not_present`; both close to revision 11 with the quest still active.
A choice made before Bram moves replays revision 10 while state stays at 11.
Altered ending conflicts, original replays, one narration. Rollback restores
revision 9 and the choice can resolve. Unknown COMMIT absent/committed and
commit-before-display mirror the Tiny cases with the narration restored exactly
once. Three `look`s change nothing. Stale view and the blocked west exit leave
state at revision 9. All match pre-release-proof.md's adverse list and COMPOSE-06.

## 5. The publication question

The coordinator left `published` unfrozen in `unknown-commit-was-committed` and
`commit-before-memory` (Tiny) on the reading that 04 §5.1 line 271 ("may be …
fanned out according to their registered policy") permits but does not require
fan-out after recovery. I agree, with one refinement.

- The model's `published` list is in-memory post-commit publication. 04 §10
  classes that as an ephemeral post-commit effect: "Notifications/presentation
  hints may be emitted after commit and dropped/reconstructed if necessary."
  04 §5.2 item 8 only says nothing may be published before commit. So after a
  lost acknowledgement the contract does not require the host to re-emit the
  ephemeral fan-out; freezing it either way would over-constrain. Leaving it
  unfrozen is right.
- What the contract does require is the durable side: 03 §15 inserts the
  `effect_outbox` records inside the transaction, and 04 §10 requires at-least-once
  delivery with idempotent application. A real candidate whose take committed
  while the acknowledgement was lost must still deliver those durable effects.
  The Python model has no outbox, so this obligation is not frozen anywhere in the
  eight inputs. That is a coverage limit to record, not a defect in the file.
- Freezing `published` in `definite-rollback` and `response-loss` is the right
  choice: those are the two places where the contract fixes the answer (nothing
  before COMMIT; nothing twice).

## 6. ADR-069, binding and the test

- ADR-069 (`16-decision-register.md:856-860`) is labelled a proposed amendment to
  the accepted R0 contract with owner acceptance pending, which is the honest
  status: a normative file changed after `aaadaff`, so the R0 record's
  `accepted_spec_commit` no longer names a commit that contains this ADR. The
  owner's acceptance of the amended revision is the remaining step, as the ADR
  says. Wording note in A5.
- Binding: `checks/readiness.py` `INPUTS` and `spec_tools/lib/readiness.ex`
  `@inputs` both list eight paths in the same order; the template lists eight
  entries with null hashes; `setup.pending.json` and `oracle-review.pending.json`
  carry identical eight-entry lists whose hashes all match the bytes on the PR
  head; `spec_tools/preserved-inputs.json` has twelve entries, all matching,
  including the new file and the re-hashed template. `setup.pending.json`'s
  `oracle_review.sha256` equals the current bytes of the pending oracle record.
- `checks/test_adverse.py`: replays the format exactly as
  `conformance/README.md` documents it (`op` defaulting to `invoke`, `recover`,
  `settle` with `committed` and a null result, `options.fault` and
  `options.authorized`, `state` as memory, `durable` defaulting to `state`,
  `published` only when present, Lantern `prefix` as a half-open `from`/`to`
  range, composition `limits` overrides and `advance_target`). Its own
  restored-RNG mutant test fails as designed. I additionally ran four in-memory
  mutants of `contract_model.py` against the file: restore RNG after a failed
  check, publish before commit, store a receipt on definite rollback, and remove
  the unknown-COMMIT fence. All four are caught (one, two, two and five failing
  cases respectively). The test does not use `subTest` inside `replay`, so a
  mutant raises rather than being swallowed; that is the right choice for the
  mutant check.

## 7. Command results (PR head `9b4b056`, same tree as main `05ae831`)

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

An earlier attempt at the probe loop recorded exit 0 because of a shell quoting
mistake on my side (the Elixir command never launched); the table above is from
the corrected rerun. Manual derivations: C rendition of the RNG for the three
`uniform` rows and the second failed draw; four Python mutants run in a scratch
copy of `checks/` against the unmodified fixture.

## 8. Adverse behaviour from the original scope still not frozen

- Multi-job explicit advance, `(due_time, job_id)` ordering, due-set cancellation
  (COMPOSE-07) and save-fork/restore: declared unmodeled by 04 §5.4 and
  `conformance/README.md`; remain unfrozen by design.
- Durable outbox obligation after a lost acknowledgement (§5 above).
- Numeric edges: `bound = 1`, `bound = 2^32`, division at `-9007199254740991`.
- Tiny: invalid `wait` targets, `drop`, `choose` with a wrong `continuation_id`
  while a choice is open, `activate` away from Bram, retry of a receipted
  `stale_view` or `invalid_input` rejection.
- Lantern: `talk` without custody, `activate` away from Bram, `wait` beyond 23.

None of these is required for A1 by the contracts as written; list them so that
the differential-testing generator (envelope §3) covers them and any divergence
enters the fixture through ordinary expected-answer review.

## 9. Smallest remaining actionable list

1. Implementer: fix A1 (one expected code plus the model's check order, or drop
   the step), re-hash `adverse-cases.json`, re-bind the four lists.
2. Reviewer (this agent or another fresh one): confirm the changed step and the
   new hash; the rest of the file needs no re-derivation unless other bytes move.
3. Implementer: three README sentences (A2, A3, A4); optionally the A5 wording.
4. Owner: accept the amended revision that carries ADR-069, then the operator
   fills the oracle receipt against the eight hashes.

# Independent expected-answer (oracle) review — 2026-09-23

**Disposition for the expected answers: APPROVE WITH NOTES.**
Every frozen expected value in the seven inputs agrees with what I derived from the
governing contracts before consulting the Python models. No frozen value is wrong.
The notes are coverage gaps and two wording ambiguities; none changes a frozen byte.

This review does not fill `oracle-review.pending.json` or any receipt. Sections 3
and 4 of the review prompt (gate logic, actual setup) are out of scope here.

## 1. Exact subject reviewed

| Item | Value |
|---|---|
| Checkout | worktree `~/dev/lokacore-oracle-review`, branch `review/v3-oracle` from `origin/main` |
| `origin/main` at review time | `762a4240dfad8782230f4aec16a19e9816c6183f` (merge of PR #20) |
| Owner-accepted R0 contract | `aaadaffff02e459dbf04e71d6ddc81d75eacf986` (`prep/after-pr-10/r0-acceptance.pending.json`) |
| Seven inputs | identical bytes at `762a424` and at `aaadaff` (hashes in §4) |

The seven inputs have not changed between the accepted R0 commit and current main;
only the pending-record files changed in between (PR #20).

## 2. Reviewer provenance and independence

- Reviewing agent: a fresh Fable 5.1 agent on Claude Code, spawned by a coordinator
  session running under the repository owner's local account (Raymond Luong). The
  owner nominated Fable; nobody has authenticated or approved this reviewer. There
  is no signature or attestation; `reviewer_id` must not be filled from this report
  without the owner's own check.
- I did not author or revise any of the seven inputs, the Python models, or the
  tests. I did not edit any reviewed file. My only artifacts are this report and
  scratch scripts (a standalone C rendition of the upstream RNG, and two short
  Python derivations) outside the repository.
- Same-vendor relation, disclosed: the last four material revisions of the
  envelope (`b0eb3d6..aaadaff`) were made by Claude sessions under the same
  operator account as my session, per `r0-acceptance.pending.json`
  (`proposal_preparer`) and the prep README. A different session of the same model
  family is not proof of independence; the owner must decide whether that
  separation is sufficient for the envelope row. For the six semantic inputs the
  authors were not Claude sessions (see §3), so my separation from them is a
  different-tool, different-session separation.
- Prior Fable agents: `reviews/2026-09-23-fable-correction-recheck.md` (reviewer of
  the PR #14 readiness-checker corrections) and the PR #14 complete review that
  `reviews/2026-09-23-fable-corrections.md` cites ("no incorrect frozen answers in
  62 probes"). I verified from history that those agents authored no expected
  answer: the one Fable-attributed fix (`5db50a0`) touched only
  `checks/readiness.py` and `checks/test_staged_readiness.py`; `14b5dc3` added
  only the recheck record. I did not read the PR #14 comment thread; the recheck
  record's verdict was not used as input to any derivation here.

## 3. Provenance matrix (from `git log --follow` per file)

| Input | Creating commit and attributed author | Later material revisers |
|---|---|---|
| `r1-acceptance-envelope.md` | `e6a8348` Raymond Luong (v0.1, 2026-09-21) | `c2303ca` R. Luong; `3e0aff9` lorecrafting; `f985ebe` lorecrafting; `d3659ca` "Loka readiness assistant"; `b0eb3d6` lorecrafting; `48f9c4b`, `74832d8`, `aaadaff` Raymond Luong (Claude Code implementing assistant per R0 record) |
| `conformance/numeric-profile.md` | `3e0aff9` lorecrafting (2026-09-22) | none |
| `conformance/numeric-vectors.json` | `3e0aff9` lorecrafting | none |
| `conformance/cases.json` | `3e0aff9` lorecrafting | none |
| `conformance/composition-profile.json` | `d3659ca` "Loka readiness assistant" (2026-09-23, noreply GitHub identity) | none |
| `conformance/composition-cases.json` | `d3659ca` "Loka readiness assistant" | none |
| `conformance/lantern-traces.json` | `d3659ca` "Loka readiness assistant" | none |

Supporting models and tests (not among the seven, but they encode further expected
answers, see F1):

| File | Commits |
|---|---|
| `checks/contract_model.py` | `3e0aff9` lorecrafting; `e1c4143` github-actions[bot] (type guards only; no semantic change, diff inspected) |
| `checks/composition_model.py`, `checks/lantern_model.py` | `d3659ca` "Loka readiness assistant" |
| `checks/test_contracts.py` | `3e0aff9` lorecrafting |
| `checks/test_readiness.py` | `d3659ca`; `e1c4143` bot; `b0eb3d6` lorecrafting; `74832d8` R. Luong |

What the records say about these labels: `pre-release-proof.md` §"Fixed content
intent" states "This assistant authored and self-reviewed them" for the Lantern
traces; the R0 record names "the ChatGPT implementing assistant (post-PR-11)" as the
original R0 proposal preparer. `lorecrafting` commits carry the owner's e-mail.
Git attribution is not an authorship attestation; `subject_author_ids` for the
oracle receipt should be the owner's own identification of who produced
`3e0aff9` and `d3659ca`, not copied from this table.

## 4. The seven input hashes (SHA-256, verified at `762a424` and at `aaadaff`)

| Path | SHA-256 |
|---|---|
| `r1-acceptance-envelope.md` | `11a81f8e4ce4d9c8d4614e08a99469c4f28d086452c87015066516a2889dd5f6` |
| `conformance/numeric-profile.md` | `2fad2bfcb6fe0840b58e9fdcce049b4d441a1be4b9d9d2e82e0879a24c69aa1f` |
| `conformance/numeric-vectors.json` | `85472ae4e7626ca7326b881766e21ae23dd253c82b5c9d4c8d0c86f89ee168c9` |
| `conformance/cases.json` | `fa4969066ed86de5c26c10d23c069d7928f90e8b5064ff751597d30c0c787bcb` |
| `conformance/composition-profile.json` | `f812bf42c97c8b9731da8783dce1ade1e6f6c9fea9b6eab5beb297d4bab5dcdd` |
| `conformance/composition-cases.json` | `26a9fe8f84125477a0c4e340f19355eaf0c3422c2b1c215b370f5dcd435f22ee` |
| `conformance/lantern-traces.json` | `e5aaf947a7978520752f2aeee9665d171a917b97311952b3c347167faf392a89` |

All seven equal the entries in `prep/after-pr-10/oracle-review.pending.json`,
`prep/after-pr-10/setup.pending.json` (the two lists are byte-identical) and
`spec_tools/preserved-inputs.json`. Historical envelope hashes for the record:
v0.3 at `d3659ca` `c404127e08ed1965bad6cece6f707b45641d787791edc650d056a67baa6ea345`.
The six semantic inputs are unchanged since their creating commits (single-commit
history each).

## 5. Method

For each input I read the governing contract first (numeric-profile.md;
04 §2, §5.0–5.4, §21; 03 §14–15; 00a §12; 15 RECEIPT-04, ATTEMPT-01, QST-31,
COMPOSE-01..07, READY-01/02; 16 ADR-065/067/068; pre-release-proof.md §"Concrete
proof"), wrote down the expected result, then compared with the fixture value. Only
afterwards did I run the Python models and read the tests as confirmation. For the
RNG I compiled my own C rendition of the upstream Blackman/Vigna xoshiro128** 1.1
transition and ran it from `[1,2,3,4]`; the profile's own cross-check was not
reused.

## 6. Derivations per input

**numeric-vectors.json.** All five `rng_steps` raw outputs and all five next states
match my C run exactly (11520 / [7,0,1026,12288]; 0 / [12295,1029,1029,25165824];
5927040 / [25179138,12295,540162,2107404]; 70819200 /
[27274249,25704967,31982592,12605441]; 2031721883 /
[15224335,29364750,272377353,1125134346]). Division: all six pairs match truncation
toward zero with `r = a - trunc(a/b)*b` (`-7/3 = -2 r -1`, `7/-3 = -2 r 1`,
`-7/-3 = 2 r -1`, `2^53-1 / 2 = 4503599627370495 r 1`). Invalid JSON: each of the
seven strings is rejected by a rule in the profile (duplicate key, NaN, Infinity,
float, exponent, `2^53` out of range, isolated surrogate). Canonical: keys ordinal,
`-0` to `0`, literal UTF-8, `\n` short escape — correct.

**cases.json** (two-room Tiny, 00a §12 + 04 §5.0 + 03 §14). The one RNG draw in
the whole file is step `c`/`t` (take): `uniform(100)` from `[1,2,3,4]` gives raw
11520 (< threshold 4294967200, no rejection), value 20 < 50, success, next state
`[7,0,1026,12288]` — matches all three cases that draw. Activation, moves, choose
and wait draw nothing (RNG unchanged) — correct per 04 §5.0 and RUN-01. Replays
(`c`, `d`, `w` with `view:0`, and `c` with changed session/seq/route) return the
original revision with `delivery: replay` and no state change — correct per
RECEIPT-04 and 03 §14 (routing and freshness fields are not intent; replay precedes
freshness validation). Event-credit negative control: activation after acquisition
leaves `arrived=false`, quest `active` — correct per QST-31/COMPOSE-02. State-credit
variant resolves on activation without an RNG draw — correct per 04 §5.2 last
paragraph. `wait until 19`: Bram's block is `6-19`, so at 19 he is at green; clock
19; RNG unchanged — correct per 04 §5.4 (advance includes jobs due up to the
target). Revisions increment by one per accepted new attempt only.

**composition-cases.json** (04 §5.2–5.4, ADR-065). Derived and matched, case by
case: same-group successive assignment composes (`flag=2`); root completes before
any delivery and an overlay guard sees the completed root (`seen=1`); emission-time
eligibility means a subscription activated after the emit gets no delivery; opposite
and identical independent writes both fault `conflicting_write` with the whole
proposal discarded (state unchanged, `events: []`); FIFO gives `1:a, 2:b, 3:b`, not
depth-first `1:a, 3:b, 2:b`; registry order is independent of source order
(`1:a, 1:b`); event-payload guard reads the event-time payload; unknown guard
source and engine-owned event emission fail closed; capacity and containment cycle
are aggregate faults that discard the earlier successful transfer; `due == clock`
is `nonfuture_job`; `due = 7` schedules. Positions are 1-based causal positions,
time is the proposal clock 6. All fifteen expected blocks are correct.

**composition-profile.json.** Eleven caps, all positive integers, profile id
`initial-composition-r1@1`, governing link to 04 §5.2. Nothing to derive; the notes
match 04 §5.4 (one shared aggregate budget, fail closed, later-than-target during
advance).

**lantern-traces.json** (pre-release-proof.md, ADR-065). Topology landing–N–green–
E–reed_bank–E–shelter with reciprocals; lantern starts at shelter; Bram at landing
06–19; ordinary actions cost zero time. Both traces: 10 steps, revision 10, RNG
never drawn (there is no check in the Lantern content), quest stays `active` after
`take` (resolves only on choice), `talk` opens `proof-choice:talk`, `carry` keeps
custody and sets `search_plan=player_led`, `leave` transfers the lantern to Bram and
sets `party_led`; both store one narration record and one proof-only terminal
milestone with the same occurrence id. Correct.

**r1-acceptance-envelope.md.** Diffed v0.3 (`d3659ca`) to v0.6 (`aaadaff`). The
diff contains no changed threshold rows (grep for `| Tiny`, `| Medium`, `| Stress`
lines in the diff returns nothing); changes are confined to the version banner, §2
candidate order, §3 randomized differential testing paragraph, §4 host/device table
and the owner-instruction paragraph, §4.1 target wording and stage sentences, the
§9 "Isolated runner death" row label, §11 and §12 candidate wording. The iOS claim:
the envelope replaces "iPhone SE (2nd generation, A13, 3 GB)" with "iPhone 11 (A13,
planned 4 GB class)" and says explicitly that this is a narrower support claim, not
evidence for 3 GB devices, and that RAM/SKU/OS remain to be verified before A2.
Challenged: Apple does not publish RAM; "4 GB" is the industry-reported figure, so
the word "planned" is the right hedge and the A2 inventory must record inspected
RAM. The narrowing is disclosed, not silent. The §3 differential-testing rule keeps
the reviewed fixtures authoritative and routes any minimized divergence through
ordinary expected-answer review, which is consistent with `conformance/README.md`.
No finding against the envelope.

## 7. Findings

Severity scale: high = a frozen value is wrong; medium = a required behavior has no
frozen expected value; low = ambiguity an implementer could resolve two ways; info.

### F1 — Adverse expected answers are not among the hash-bound inputs (medium)

- Where: `checks/test_contracts.py:38-142` (failed roll with next state, receipted
  rejection replay, integrity conflict, stale view, definite rollback, unknown
  COMMIT both dispositions, response loss); `checks/test_readiness.py:55-121`
  (budget exhaustion per cap, output budget, resource bounds, advance-target job
  rule, job caps, selector overflow, competing transfers) and `:169-235` (Lantern
  early possession, drop after choice, moved Bram, stale receipt replay, altered
  choice, rollback, unknown COMMIT with restored narration, commit-before-display).
- Expected: the review scope names these behaviors as oracle subjects (failed
  checks, rejection sampling and budgets, rollback, unknown COMMIT, both Lantern
  outcomes plus early possession, drops, moved Bram, stale/consumed choices).
- Observed: the seven inputs contain exactly one RNG draw, and it succeeds
  (`cases.json:97-101`); no frozen file contains a failed roll, a rejection, a
  conflict receipt, a fault, or a Lantern adverse path. Those expectations exist
  only as Python assertions, which `spec_tools/preserved-inputs.json` and the
  oracle input list do not hash.
- Minimal counterexample: a candidate that restores the RNG after a failed check
  (the exact mutant `test_contracts.py:233` catches) passes every frozen fixture.
- Affected gate: PREP-02 A1 freeze; R1-A1 known-answer parity.
- Smallest correction (implementer, via ordinary expected-answer review): freeze a
  small adverse known-answer file, or add the two test files to the preserved and
  oracle input lists. Values already in the tests that I verified independently:
  failed roll from `[27274249,25704967,31982592,12605441]` draws raw 2031721883,
  value 83 (fails), next state `[15224335,29364750,272377353,1125134346]`.

### F2 — No rejection-sampling or budget known-answer vector (low)

- Where: `conformance/numeric-vectors.json:9-55` has five plain steps; the only
  `uniform()` answer anywhere is implicit in `cases.json`. `test_contracts.py:183-192`
  tests rejection and budget with mocked draws, not a real state.
- Suggested vector for the implementer to consider (derived with my own script from
  the profile; not applied): initial `[1, 2199679431, 3, 4]`, bound 100: first raw
  4294967295 is rejected (threshold 4294967200); second raw 4294955775 is accepted,
  value 75, next state `[3817741343, 954437125, 2199680448, 2473519876]`. Also
  absent: `bound = 1`, `bound = 2^32`, `a = -9007199254740991` with `b = -1` and
  `b = 2`.

### F3 — "Fixture encoding" wording versus the checked-in file layout (low)

- Where: `conformance/numeric-profile.md:9` says "The fixture encoding is UTF-8
  canonical JSON with ASCII object keys in ordinal order, no whitespace"; the seven
  JSON inputs are indented and not key-sorted (`cases.json:1-20`).
- Reading I applied: the canonical encoding governs state/result bytes and digests
  (as `contract_model.canonical` and the tests use it), not the on-disk layout of
  the human-readable fixtures. An implementer could read it the other way and
  canonicalize the files before hashing, which would break the seven hashes.
- Smallest correction: a clarifying sentence in `conformance/README.md` (does not
  touch a frozen byte); amending the profile itself would change its hash.

### F4 — "Canonical compiled registry order" is only shown by example (low)

- Where: `conformance/composition-cases.json:615-711` (`canonical-registry-order`)
  expects `1:a` before `1:b` although the rules are listed `b, a`. 04 §5.2 item 6
  says registry order uses compiled stable semantic IDs but does not say how they
  are ordered; `checks/composition_model.py:156` sorts by rule id.
- Smallest correction: state in `conformance/README.md` that for the initial profile
  registry order is ordinal order of the rule id string.

### F5 — Tiny schedule is one-shot (info)

`cases.json:519-535` expects `job_pending: false` after the 19:00 move; no 06:00
return job is scheduled. This matches doc 14's Tiny definition ("1 scheduled job")
but 00a §12's two-block schedule reads as recurring. Bounded and consistent with
the stated Tiny model; worth one sentence so a candidate does not schedule the
return job and diverge on the frozen state.

### F6 — `lantern-offer-1` is not in the 00a §12 YAML (info)

`cases.json:103` opens a choice on quest resolution that the YAML does not define.
`conformance/README.md` already discloses this as a separate narrow consumed-offer
example. No action.

### F7 — Model limitation, not an expected-answer defect (info)

`checks/contract_model.py:101` raises `ValueError("rng_budget_exhausted")` and
`:174` calls it inside `_decide` without converting it into the typed fault
response 04 §5.2 item 7 describes. Unreachable with bound 100 (needs 1024
consecutive rejected draws). Note for whoever maintains the model.

### F8 — Decision-register text lags the envelope version (info, outside the seven)

`16-decision-register.md:823` (ADR-064) describes envelope v0.4/v0.5; the accepted
envelope is v0.6 and ADR-068 covers the v0.6 additions. Documentation staleness
only.

## 8. Command results

Local execution on macOS arm64, Python 3.9.6; Elixir 1.20.4 / OTP 28.4 via
`mise exec elixir@1.20.4 erlang@28.4` (the local default 1.20.3/OTP 29 does not
satisfy `mix.exs`'s `== 1.20.4`). Repository root unless noted.

| Command | Result | Exit |
|---|---|---|
| `python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py'` | 113 tests OK | 0 |
| `python3 docs/rewrite-v3/checks/release_scope.py --check` | PASS | 0 |
| `python3 docs/rewrite-v3/checks/packet_navigation.py --check` | PASS, 30 menus | 0 |
| `python3 docs/rewrite-v3/checks/readiness.py --check-template` | PASS: incomplete template preserved | 0 |
| `git diff --check` | clean | 0 |
| `mix format --check-formatted` (spec_tools) | clean | 0 |
| `mix compile --warnings-as-errors` (spec_tools) | compiled | 0 |
| `mix test` (spec_tools) | 25 passed, 3 excluded | 0 |
| `mix test --include comparison` (spec_tools) | 28 passed | 0 |
| `mix loka.readiness --check-template` (spec_tools) | PASS: incomplete template preserved | 0 |

Readiness probes (all expected to reject; all did, with "NOT READY: preparation
pending or unsupported candidate work package"):

| Implementation | Stage | Manifest | Exit |
|---|---|---|---|
| Python | A1 | `conformance/r1-run-manifest.template.json` | 1 |
| Python | A1 | `prep/after-pr-10/setup.pending.json` | 1 |
| Python | A2 | template | 1 |
| Python | A2 | `setup.pending.json` | 1 |
| Elixir | A1 | template | 1 |
| Elixir | A1 | `setup.pending.json` | 1 |
| Elixir | A2 | template | 1 |
| Elixir | A2 | `setup.pending.json` | 1 |

Manual derivations (not repository commands): standalone C run of xoshiro128** 1.1
from `[1,2,3,4]` for five steps plus `uniform(100)`; Python derivation of the F2
rejection state using the modular inverses of 5 and 9. No hosted logs were
inspected. No legacy suite, mutation sweep, native build or gameplay was run.

## 9. Coverage limits

- I checked the frozen values and their derivation from the contracts; I did not
  attempt to prove the contracts themselves complete, and a fixture set this small
  cannot prove any candidate correct over all traces.
- No frozen input exercises: a failed roll, rejection sampling, draw-budget
  exhaustion, any composition cap, resource bounds, an advance that runs more than
  one job, `(due_time, job_id)` ordering, due-set cancellation (COMPOSE-07),
  save-fork/restore, or any Lantern adverse path. These remain test-only or
  unimplemented, as the contracts themselves state (04 §5.4, 15 COMPOSE-07, the
  scheduler and save-system limitations in `conformance/README.md`).
- The Elixir comparison suite was executed as a green/red signal only; I did not
  review `spec_tools/lib/codec.ex` line by line.
- Authorship labels come from git and the retained records; I cannot authenticate
  who operated the `lorecrafting`, `Loka readiness assistant` or bot identities.

## 10. Dispositions

| Subject | Disposition |
|---|---|
| Expected answers in the seven inputs | **APPROVE WITH NOTES** (F1–F4 are notes; no frozen value is wrong) |
| Stage-gate logic (sections 3) | not reviewed here (reviewed earlier by other agents) |
| A1 setup, A2 setup, actual A1 authorization | not reviewed here; remain pending |
| Oracle receipt | not filled; requires the owner's authorship identification and independence decision (§2) |

## 11. Smallest remaining actionable list

1. Owner: decide whether a Claude session reviewing an envelope last amended by
   Claude sessions under the same account counts as independent for the envelope
   row; identify `subject_author_ids` for `3e0aff9` and `d3659ca`.
2. Implementer, through ordinary expected-answer review before the A1 freeze:
   freeze a minimal adverse known-answer set (F1) and, optionally, one
   rejection-sampling vector (F2).
3. Implementer: two clarifying sentences in `conformance/README.md` (F3, F4) and
   one on the one-shot Tiny schedule (F5); none touches a frozen byte.
4. Only after 1: the operator fills `oracle-review.pending.json` against the hashes
   in §4 and commit `aaadaff`.

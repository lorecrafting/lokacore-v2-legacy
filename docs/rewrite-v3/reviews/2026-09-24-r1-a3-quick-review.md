# Quick R1-A3 (`touched-1`) and proposed ADR-071/072 review of PR #32 — 2026-09-24

**Disposition at `0fa487f`: APPROVE WITH NOTES, conditional on F1.**

The evidence is sound and honestly reported. Every hash in the four bundles
recomputes. The `touched-1` kernel change only affects performance: the differential
passes (my own 22 regression + 5,000 fresh sequences), all 90 TypeScript tests pass,
and a frozen-input test proves the kernel never mutates its input. I checked that test
bites by reintroducing the old in-place push. The phone timing code measures what the
README says it measures. Every percentile I recomputed from the raw CSVs equals
`summary.json`, the READMEs and the ADR-071 table. The APK is the declared build: its
source map carries byte-identical copies of the `97bccfa` app and kernel sources, and
its native libraries and pins are the same as A2's. The one thing that needs to change
before merge is text in ADR-071 (F1): its deferred list leaves out several envelope
rows and A2 carry-overs, it states an inference as if it were measured, and it does not
say plainly that it departs from envelope §2. **No fix needs the phone.**

This review covers the quick A3 evidence and the two proposals. It does not approve any
unmeasured row, R1 acceptance under §12, or a production step.

## 1. What was reviewed

| Item | Value |
|---|---|
| Subject | PR #32, branch `r1-a3-quick`, head `0fa487feba6dff99986325a420afe73cbb77b55d` (`gh pr view 32`, 16 commits), base `main` `d768e92469f96f9ca5ca60f48f7ebb5ba10261bb` (= merge base) |
| Governing | `r1-acceptance-envelope.md` §1–§3, §5–§7, §10–§12; `r1-work-package.md` rows R1-A3/A4/A5; `r1-spike/README.md` rules 1–4; `2026-09-24-r1-a2-review.md` carry-overs |
| Decisions | `prep/after-pr-10/owner-decision-a3-2026-09-24.md`, `prep/owner-decision-prep-03-2026-09-24.md`, `prep/owner-decision-reviewers-2026-09-24.md`, `prep/downloaded-representation.md` status line |
| Declaration | `r1-a3-quick-evidence/variant-touched-declaration.md` (commit `7444279`) |
| Code | `r1-spike/ts/src/kernel/{codec,world}.ts`, `ts/test/sharing.test.ts`, `mobile/{host,scale,App}.ts(x)`, `mobile/scripts/{scale-local,scale-summary,embed}.mjs`, `harness/.../scale.ex`, `server/.../scale.ex` |
| Bundles | `r1-a3-quick-evidence/` (stateless: 27 indexed), `touched-1/` (31 indexed), `pixel-3a/actions-run-36031156199/` (16), `touched-1/pixel-3a/actions-run-36044635316/` (16) |
| Proposal | `prep/adr-071-072-proposal.md` |
| Protected | `git diff d768e92..r1-a3-quick` on `docs/rewrite-v3/{conformance,checks,spec_tools}`, `r1-acceptance-envelope.md`, `r1-work-package.md`, `16-decision-register.md`, `setup.pending.json`, `r1-spike/elixir`, `ts/src/runner.ts`: empty. Under `ts/test` the only change is the new `sharing.test.ts` |

Paths are relative to `docs/rewrite-v3` unless they start with `r1-spike`.

**Independence.** I am a fresh Claude Opus agent started by the coordinator. I authored
none of the files under review and did not read the coordinator's scratchpad. The owner
ruling notes the limit: the builders were also Opus, so we may share blind spots. To
compensate I reran everything I could, recomputed from raw bytes, and ran two mutants,
instead of relying on any summary.

## 2. Independent verification

### 2.1 Declaration before tuning

- **Commit order.** `git log --graph` puts `7444279` (declaration, 18:43Z) before the
  only `touched-1` code commit, `97bccfa` (18:55Z). After that, `9f84063`, `02ff058`
  and `583afe2` touch only `docs/`: `git diff --stat 97bccfa r1-a3-quick -- r1-spike
  .github` is empty. The declaration has not changed since `7444279`.
- **No sign of build iteration.** Only one Android build exists on `r1-a3-touched`:
  run 36044635316, created 18:55:44Z, at `97bccfa`. This fits "no tuning after
  measurement", but it cannot prove it. Git dates are set by the author, and uncommitted
  local tries leave no trace. (Inferred, not provable.)
- **Implementation against the declaration.**
  - Item 1 (structural sharing, delta from replaced keys) matches `world.ts`.
  - Item 2 (changed-row persistence) matches `host.ts` `stateWrites` and `loadState`,
    and `scale.ts`. Every list-valued key gets element rows, not only large ones, which
    is harmless.
  - Item 3 (full-HOST encode outside the timers) matches `scale.ts`, where it runs
    after `t5` and only on measured steps.
  - The checkpoint is still a full canonical save, read back and validate.
  - Deviations are in F3.

### 2.2 Semantics unchanged

- **Kernel diff, read line by line.**
  - The per-step `clone` became shallow copies plus replace-on-write
    (`withKey`, spread, new narration array).
  - The `canonical(a) !== canonical(b)` delta test became identity plus `equal`.
    `equal` ignores key order and uses `===` on scalars, which gives the same answer
    for every value the strict parser admits.
  - The parser copies literal runs with `slice`, and `quote` has a fast path for
    strings with nothing to escape. Escapes and surrogate checks are unchanged.
  - I found no behavior change. `uniform` returns a new word array and does not mutate
    `state.rng`. Replay still clones the prior result before setting `delivery`.
  - `KEY_ORDER` behaves as before: `Object.assign` copies the symbol, and a new receipt
    key was never added to it before either.
- **Protected paths.** Fixtures, expected answers, checkers and the Elixir kernel are
  byte-identical to `main`.
- **Runs.** TypeScript `tsc` is clean. `node --test` gives 90/90: 89 fixture tests plus
  `sharing.test.ts`. Harness `mix test` gives 11/11.
- **Differential.** `mix r1.diff --sequences 5000 --seed 777001` passes: 22 regression
  seeds plus 5,000 fresh sequences, 10,044 requests, generator `r1-gen-3`. The retained
  report covers seed 20260925 with 10,000 fresh sequences, also a pass.
- **Purity claim.**
  - Replacing the narration spread with the old in-place `.push` makes
    `sharing.test.ts` fail with "Cannot add property 0, object is not extensible".
  - Making `decide` write straight into `memory` also fails it.
  - `mix r1.diff --ts-dir <that mutant>` stops at a mismatch and minimizes it to a
    10-step Lantern sequence. So both the test and the differential catch mutation.
- **A2 set on Node.** `scripts/local-check.mjs` with `node:sqlite` gives 139 lines,
  SHA-256 `79abbb36…69c3`. That equals `mix r1.runner` here and the A2 phones' hash.
  The fault check gives 19/19, with `elixir_agrees=true` on every case.
- **Scale inputs.** `mix r1.scale` regenerates `scale.jsonl` (r1-scale-1) and
  `scale-2.jsonl` byte for byte. `scale.gen.ts` embeds exactly the lines of
  `scale-2.jsonl`.
- **Final state.** The phone and the Node preview end each model with the same final
  state SHA-256 and 2,916 receipts.

### 2.3 Timing method (`mobile/scale.ts`, `server/.../scale.ex`, `scale-summary.mjs`)

- **Warm-up.** The first 1,000 steps are dropped (`i >= warmup`). Every CSV has 2,000
  rows per model, with `i` from 1000 to 2999.
- **Phases.**
  - Admission is the receipt `SELECT`, the parse and building the HOST.
  - Decision is the kernel `step`, including `hostJson` and the delta.
  - Encode is `stateWrites`, the receipt and the events.
  - Commit is `BEGIN IMMEDIATE`…`COMMIT`.
  - Projection is adopting the memory and encoding `{result, events, delta}`.
  - End to end is `t5 − t0`. It equals the sum of the five phases on all 24,000 rows
    I checked (within 0.001 ms).
- **HOST encode.** It runs after `t5` and does not touch any gated timer. The stateless
  `scale.ts` never encoded the full HOST inside a timer either, so the stateless and
  `touched-1` numbers compare like for like on this point (F3c).
- **Percentiles.** Nearest rank, `ceil(p/100·n)`-th smallest, 1-based. My Python
  recomputation matches the script.
- **Classes.** Accepted, rejected and replayed are separated, and replays are
  identified by `delivery`. Gates use the accepted class only. Counts:
  - `touched-1`: 1,278 accepted (644 write state), 683 rejected, 39 replayed per model;
  - stateless: 1,276 (642) / 685 / 39.
- **Checkpoint.** 20 round trips per model, with the maximum gated. The timer covers the
  write, `COMMIT`, read, parse and re-encode. It leaves out the first serialization of
  the state, which both hosts compute once before the loop (F4).

### 2.4 Recomputed from raw samples (ms, accepted, p50 / p95 / p99, max)

| Source | Model | Decision | End to end | Checkpoint p50 / max |
|---|---|---|---|---|
| `touched-1/pixel-3a` | Tiny | 0.358 / 0.431 / 0.488, 1.573 | 5.303 / 6.604 / 7.999 | 4.756 / 5.770 |
| | Medium | 0.404 / 0.549 / 0.708, 1.587 | 8.117 / 10.928 / 17.438, 45.887 | 129.186 / 860.757 (sample 15) |
| | Stress | 0.419 / 0.757 / 0.886, 1.468 | 10.188 / 13.761 / 15.773, 143.113 | 473.090 / 488.070 |
| `pixel-3a` (stateless) | Medium | 215.865 / 219.681 / 222.716 | 319.614 / 329.913 / 336.209 | 216.943 / 242.334 |
| | Stress | 821.935 / 831.111 / 835.060 | 1184.1 / 1216.6 / 1238.3 | 789.510 / 821.445 |
| `m1-server` | Medium | 0.005 / 0.015 / 0.018 | 2.785 / 5.364 / 5.935 | 15.388 / 16.234 |
| | Stress | 0.007 / 0.024 / 0.030 | 15.175 / 26.413 / 40.643 | 74.961 / 117.480 |

Every value equals `summary.json`, the two READMEs and the ADR-071 table. That includes
the rejected and replayed p50/p99 table, the bytes written (p50 189 / p99 198 / max 458
on state writes; 185 / 197 on all accepted steps), the full-HOST encode figures
(67.1 / 73.8 and 257 / 273), and the row counts (11 `mem`; 505 and 2,205 `mem_items`).
ADR-072's "6 to 11 ms p99" matches accepted commit p99 of 6.30 / 9.57 / 10.69.

### 2.5 Evidence integrity and build identity

- **Hashes.** `shasum -a 256 -c SHA256SUMS` passes in all four bundles (27, 31, 16, 16
  × OK), and each `SHA256SUMS.verify.txt` reproduces. The files outside the indexes are
  exactly the READMEs, the index files, the verify files and
  `variant-touched-declaration.md`. The declaration is bound by git only (F9).
- **Stateless evidence retained.** `git diff --quiet cdf8c36 r1-a3-quick` on
  `pixel-3a/`, `m1-server/`, the top README and the top `SHA256SUMS` is empty.
- **Run 36044635316.**
  - `host.txt` records `source_commit=97bccfa`, `workflow_dispatch` and
    `ubuntu-24.04`, image 20260920.314.1.
  - `tools.txt`, `native-config.txt`, the Gradle wrapper, AGP, the Gradle version and
    `prebuild-tree.sha256` are byte-identical to the stateless run and to A2's run
    36024373520. `release-runtime-classpath.txt` differs only in the order of Gradle
    task log lines.
  - Every `.so` hash in `apk-facts.txt` equals the stateless build's. Only the APK hash
    and the JS bundle differ.
  - **Inspected:** the retained `index.android.bundle.map` (SHA `3b2befeb…`, as
    recorded in `pixel-3a-run.txt`) carries `sourcesContent` byte-identical to `97bccfa`
    for `App.tsx`, `scale.ts`, `host.ts`, `scale.gen.ts`, `world.ts`, `codec.ts`,
    `numeric.ts` and `sha256.ts`.
  - **Inferred:** that the Hermes bytecode inside the APK came from that map. They are
    outputs of the same build.
- **Run validity.**
  - `pixel-3a-run.txt` records AC power and 100% battery. The battery went from 33.5 °C
    to 36.5 °C. Thermal status was 0 before and after.
  - The result was `done after 737 s`. The loop would have stopped with `INVALID` on a
    locked screen or a lost focus, checked every 10 s.
  - The logcat shows one process (pid 24890) from `LOKA_A3_PROBE` to `LOKA_A3_DONE`,
    with Hermes Release, bytecode 98 and SQLite 3.50.3 (`delete`, `synchronous=2`).
  - The Pixel 3a stands in for the Galaxy A14 class under
    `owner-decision-a2-2026-09-23.md`.

### 2.6 Leaks

I swept the added lines of the whole diff. No adb serial, UDID, ECID, team ID or
provisioning identifier appears; the script fetches the serial and `redact()` removes
it. No `/Users/<owner>`, `/private/tmp`, `/var/folders`, worktree or scratchpad path
appears. The battery object id reads `[redacted]`. What is left:

- the two RFC 4122 namespace UUIDs inside third-party `uuid` source in the source map;
- `/Users/evanbacon` from the Expo package sources, disclosed in the README;
- GitHub runner paths and host name;
- the public Expo debug-keystore certificate digests in `apk-facts.txt`, as in A2 F7.

None of these identifies the owner's machine or devices.

### 2.7 CI

`gh pr checks 32` at the head:

| Check | Result |
|---|---|
| R1 runners and differential test | pass |
| R1 durable server host (SQLite) and differential test | pass |
| V3 specification checks | pass |
| `android` (run 36047872606) | pass (7m33s), after the first draft of this review (F2) |

The earlier `R1 spike` run at `cdf8c36` (the stateless merge) failed on
`mix format --check-formatted` for `harness/.../scale.ex`. This was formatting only, it
is fixed at the head, and r1-scale-1 still regenerates byte for byte (F10).

## 3. Findings

**F1 — blocking (text in `prep/adr-071-072-proposal.md`; no evidence byte changes).**
ADR-071 is the record that R1-A4 uses to retain failed and unmeasured rows (§11, §12,
work package R1-A4). As written it is incomplete in three ways.

(a) The deferred list leaves out these rows:

- §10 kernel upgrade and save compatibility (A2 review F6 asked A4 to show them or
  record them as unmeasured).
- The iOS clean release build of the `touched-1` host (only iPhone *timing* is listed).
- An on-device mutant, so the phone oracle is shown to catch a mismatch (A2 F9).
- The on-device A2 differential and fault cases with the `touched-1` host. These ran on
  Node only, although the declaration required them.
- The server fault records' retained initial snapshot (A2 F3).
- A result-manifest field for the server's SQLite version (A2 Ruling 4).
- From §7: the integrity-hashing time, durable receipt, trace and job sizes, and a
  checkpoint split into its parts.
- From §6: bytes copied and boundary measures beyond `bytes_written`.
- From §1: representative *large* dirty sets and fan-out. The padding is inert and
  never dirtied, which matters more under `touched-1` (F5).
- From §10 and §11: the report for C on duplicate implementation and test maintenance,
  and the comparison of fault containment.

(b) "A Rust candidate would still move the same bytes through SQLite, so this failure
alone is not a reason to evaluate B" is an inference. The checkpoint was never split
into write, read, parse and encode; the README says so, and it attributes the cost to
Hermes at about 0.6 ms per KB. Label the sentence as inferred, or remove it.

(c) State plainly that selecting C with a failed MUST row is an owner override of
envelope §2 ("If C fails, record results and evaluate B") and of §12's acceptance
requirement. It is not an R1 acceptance. Also name the ADR-004/ADR-005 outcome that
R1-A4 requires.

**Required:** amend ADR-071's deferred list and wording as above in one commit. It is
doc-only, and it does not need the phone.

**F2 — resolved.** The `android` check (run 36047872606) was still running when this
review was first drafted. It then passed on the head (7m33s), so all four checks are
green. No action.

**F3 — non-blocking; record the deviations from the declaration.**
(a) The codec changes (literal-run slicing in the parser, the `quote` fast path, the
regex check for non-ASCII keys) are tuning that the declaration does not name. They
only affect performance, and the differential shows that. The README lists them under
"What changed" but does not call them a deviation.
(b) The declaration required the on-device A2 differential to stay byte-identical. It
was not rerun on the phone, only on Node. The README says so; ADR-071 does not (F1).
(c) Positive: declaration item 3 reads as if the full-HOST encode used to be inside the
timers. In the stateless code it never was, so no timer lost cost when the boundary
moved.
**Action:** add a short "Deviations from the declaration" paragraph to
`touched-1/README.md` (not hash-bound).

**F4 — non-blocking; R6P depends on it.** Both checkpoint timers start after the
pre-save canonical encoding (`pre` is computed once before the loop, in `scale.ts` line
117 and in the server's `scale.ex`). Envelope §7 includes "checkpoint
serialization/write". So the reported round trips understate the full cost by one
encode, inferred at about 34 ms for Medium and 130 ms for Stress on the Pixel. The
verdicts do not change: the phone already fails, and M1 Medium stays a pass. M1 Stress,
117.5 ms plus about 20 to 40 ms, is still under 200, but the "close" there is
understated. **Required at R6P:** time the serialization inside the round trip, report
write, read, parse and encode separately, and say this in ADR-071's re-measure clause.

**F5 — non-blocking; what the quick A3 represents.**

- The padding sits in the never-dirtied `narration` list.
- Look and move make up 1,188 of the 1,278 accepted steps. Only 17 accepted steps are
  talk, choose or wait.
- So nearly every `touched-1` step writes about 190 bytes.
- The one step that dirties the large list is the quest resolve. It costs 46 ms (Medium)
  and 143 ms (Stress) end to end, most of it in projecting the whole-list delta. It is
  the maximum, not the p99, only because it happens once per run.
- A workload with regular large dirty sets would move the p99. The README states that
  the padding is inert, which is honest.

**Action:** list large dirty sets as unmeasured (F1a). Also:

- The replayed class (n = 39) and the rejected class (n = 683) are reported with p99.
  §3 asks for the maximum and the count when a class has fewer than 1,000 samples. They
  are not gated, so this is wording only.
- The `touched-1` README table puts the stateless numbers (r1-scale-1) next to the
  `touched-1` numbers (r1-scale-2). The ADR-071 M1 column is the stateless Elixir host
  on r1-scale-1. Label both with their input.

**F6 — non-blocking, info.** One run of 20 checkpoints. Medium sample 15 took 860.8 ms
while the other 19 took 122 to 182 ms, and nothing explains it. Without the outlier,
Medium would still fail (182 against 50). No action beyond R6P's three runs.

**F7 — non-blocking, info.** Owner quotes. I cannot check any quote against the chat.
Two of them are consistent with their records: "yes lets go with the quick a3 then r2…"
and "ok your recommendation". Three have no owner-decision record of their own and exist
only inside the proposal: "okay lets do option 1" (quoted in the declaration),
"idk i leave it up to you", and "yes please go ahead". The PostgreSQL reconfirmation of
2026-09-24 has no record either. **Action:** retain those three exchanges and the
reconfirmation as owner-decision files, as was done for the others.

**F8 — non-blocking, low.** The stateless `README.md` line 41 says "both hold 2,927
receipts". Every `a3-run.json` and `summary.json`, stateless and `touched-1`, says
2,916. **Action:** fix the number. The README is not hash-bound.

**F9 — non-blocking, info.** `variant-touched-declaration.md` sits outside every
`SHA256SUMS`. Its "before tuning" timing rests only on git commit `7444279`. That is
acceptable because the file has not changed since. Cite the commit hash in ADR-071
next to the declaration link.

**F10 — non-blocking, info.** Commits skipped the pre-commit hook, as the README
discloses. CI caught one formatting defect at `cdf8c36`, and it is fixed at the head.
The stateless evidence was produced by code that differs from the head only in
formatting and in the r1-scale-2 additions, and r1-scale-1 regenerates byte for byte.
No action.

**PREP-03 and the reviewer ruling.** The status-line change in
`downloaded-representation.md` matches `owner-decision-prep-03-2026-09-24.md`. It
claims no store approval and changes no scope. The reviewer ruling states its own
limit. I have no findings on either.

## 4. Opinion (non-blocking): is the checkpoint failure fairly called "not candidate-deciding"?

**Mostly yes on design grounds, not on evidence.**

Under ADR-072 no player action does a whole-state checkpoint. Each action commits about
190 bytes of changed rows, and that path passes with a wide margin. The failing row is
an export or backup operation. The C-side remedies are cheaper than building B:

- a streaming or row-wise export;
- a faster Hermes codec;
- WAL or `synchronous=1` for the export only;
- a native export module.

The M1 Elixir host is itself only "close" at Stress (F4 makes that closer).

The specific argument that Rust would move the same bytes is not supported. The round
trip was never split, and the README puts most of the cost on Hermes string work
(parse and encode), which a native B kernel would largely avoid. So B might pass this
row. That is unmeasured.

The fair statement is: this is a failed MUST row accepted by the owner as a risk;
whether B would pass it is unknown; R6P must re-measure it with the parts split and the
serialization included. Cold restore (3 s) is the related row most likely to bite next.
It rebuilds from about 2,200 rows plus a full parse, and nothing here measures it.

## 5. Commands and exit codes

All run in `~/dev/lokacore` at `0fa487f`, macOS Darwin 25.6.0, through
`mise exec elixir@1.20.4 erlang@28.4 node@24.21.0 --`. Mutant copies and outputs went
to the session scratchpad. The working tree was clean before and after (except for this
file).

| Command | Result | Exit |
|---|---|---|
| `gh pr view 32`; `git merge-base main r1-a3-quick` | head `0fa487f`, base `d768e92` | 0 |
| `git diff --stat d768e92..r1-a3-quick -- <protected>` | only `ts/test/sharing.test.ts` added | 0 |
| `git log --graph d768e92..r1-a3-quick`; `gh run list --branch r1-a3-touched` | declaration before code; one Android build | 0 |
| `shasum -a 256 -c SHA256SUMS` × 4 bundles | 27 / 31 / 16 / 16 OK; verify files reproduced | 0 |
| `tsc -p .` (ts); `node --test 'test/*.test.ts'` | clean; 90/90 | 0 |
| `mix compile` (elixir); `mix test` (harness) | clean; 11 passed | 0 |
| `mix r1.diff --sequences 5000 --seed 777001` | pass, 5,022 sequences | 0 |
| `sharing.test.ts` on the push mutant / on the direct-write mutant | fail / fail (expected) | 1 |
| `mix r1.diff --sequences 2000 --seed 5 --ts-dir <push mutant>` | mismatch, minimized (expected) | 1 |
| `node scripts/local-check.mjs requests.jsonl`; `mix r1.runner < requests.jsonl`; `check.mjs diff`; `check.mjs faults` | 139 lines `79abbb36…`; pass; 19/19 | 0 |
| `mix r1.scale --version r1-scale-1` / `r1-scale-2`; `cmp` | byte-identical to the committed inputs | 0 |
| Python recomputation of every percentile and count from the four `a3-samples.csv` and `a3-run.json` | equals `summary.json`, the READMEs and the ADR-071 table | 0 |
| Source-map `sourcesContent` against `git show 97bccfa:<path>` | 8/8 app and kernel sources identical | 0 |
| Identifier sweep of the added diff lines | no owner or device identifiers (section 2.6) | 0 |
| `gh pr checks 32` | 4 pass (`android` passed after the first draft) | 0 |

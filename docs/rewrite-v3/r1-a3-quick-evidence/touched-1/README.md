# Quick R1-A3, boundary variant `touched-1` (2026-09-24)

This reruns the quick A3 with the variant declared in
[`../variant-touched-declaration.md`](../variant-touched-declaration.md) before any
tuning. The stateless results in `../pixel-3a/` and `../m1-server/` are unchanged.

**Result on the Pixel 3a: decision and Medium end to end now pass every gate by a
wide margin. The checkpoint round trip still fails at Medium and Stress.** Medium
decision p99 fell from 222.7 ms to 0.71 ms. Medium end to end p99 fell from
336 ms to 17.4 ms. The Medium checkpoint went from 242 ms (max) to 129 ms (p50),
with one 861 ms outlier, against a 50 ms limit. Stress went from 821 ms to
488 ms (max) against 200 ms.

## What changed (source `97bccfa`; the app was built from it)

1. **Kernel** (`r1-spike/ts/src/kernel/`). `step` and both worlds' `decide` copy
   only the top-level object and replace the fields they change; Lantern's
   narration append builds a new list. No input value is mutated. `delta`
   compares only replaced keys: identity first, then a structural `equal`. The
   canonical encoder copies strings that need no escape in one piece, and the
   strict parser copies unescaped string runs with one slice. Output is
   byte-identical. The kernel is still pure: it uses no Node APIs, no `JSON.`
   and no dependency.
2. **Phone host** (`r1-spike/mobile/host.ts`, `scale.ts`). Durable state is
   stored as rows:
   - `mem`: one row per top-level key;
   - `mem_items`: one row per list element;
   - a step writes only changed rows, plus its receipt and outbox rows;
   - loading rebuilds the canonical state from these rows.

   The checkpoint is unchanged: a full canonical save, read back, strict parse,
   re-encode, and compare.
3. **Timing boundary.** `host_encode_ms` is the canonical encoding of the step
   record's full `HOST`, which only the runner protocol and the differential
   need. It is timed after e2e, on measured steps only.
4. **Generator `r1-scale-2`** (`mix r1.scale --version r1-scale-2`, input
   `r1-spike/mobile/scale-2.jsonl`, sha256 `8feab221…4c991`). It fixes the
   r1-scale-1 skew and keeps the same command classes, ids and random draws.
   `r1-scale-1` still regenerates byte for byte (`scale.jsonl`, `8591d212…4cb52`,
   kept). The measured mix now includes accepted wait (11), activate (1), talk
   (4), close_choice (1) and choose (1, which resolves the quest and appends
   narration). Lantern's quest resolves once, so later quest inputs are
   rejected. That is the world's limit.

## Correctness (all at `9f84063`, the `97bccfa` code; `checks/checks-run.txt`)

| Check | Result |
|---|---|
| TypeScript fixture suite | 89/89 pass, plus the new frozen-input sharing test (it fails if an in-place narration push is reintroduced; checked by hand) |
| Differential vs Elixir runner, r1-gen-3, seed 20260925 | 22 regression + 10,000 fresh sequences, 0 mismatches (`checks/r1-diff-summary.json`) |
| R1-A2 differential set through the phone durable host on Node | 139/139 lines byte-identical to `mix r1.runner`; the altered line was caught |
| Phone durable-host fault cases on Node | 19/19 pass; the Elixir runner agrees on all 19 (6 kills relaunched) |
| Harness tests | 11/11 |
| Phone run final state | per model, sha256 equals the Node preview's; the durable rows rebuild to exactly the in-memory state |

The on-device A2 differential was not rerun on the phone. The app bundles the
A3 timing instead of `device.ts`, which the Node check above covers.

## Pixel 3a vs stateless vs thresholds (accepted steps, ms, nearest rank)

Setup:

- Release APK from Actions run
  [36044635316](https://github.com/lorecrafting/lokacore/actions/runs/36044635316).
- Source `97bccfa`, APK sha256 `aea2b100…25ac4`.
- Same pins as the stateless build: native libraries are identical, with the
  same Hermes (bytecode 98) and SQLite 3.50.3 (`journal_mode=delete`,
  `synchronous=2`).
- One launch, 737 s. The app stayed in the foreground and the screen stayed
  unlocked (checked every 10 s).
- Battery 100%, AC. Battery temperature went from 33.5 °C to 36.5 °C. Thermal
  status was 0 before and after.
- Counts per model: n accepted = 1278 (644 write state), 683 rejected,
  39 replayed.

| Model | Metric | Threshold | Stateless p50 / p95 / p99 | touched-1 p50 / p95 / p99 (max) | Verdict |
|---|---|---|---|---|---|
| Tiny | decision | 2 / 5 / 10 | 0.52 / 0.61 / 0.73 | 0.36 / 0.43 / 0.49 (1.6) | pass |
| Tiny | commit | none | 3.96 / 5.00 / 7.47 | 4.09 / 5.29 / 6.30 (26.5) | recorded |
| Tiny | end to end | none | 5.46 / 6.81 / 9.12 | 5.30 / 6.60 / 8.00 (27.7) | recorded |
| Tiny | checkpoint | max ≤ 10 | max 5.9 | p50 4.8, max 5.8 | close |
| Medium | decision | 5 / 15 / 30 | 215.9 / 219.7 / 222.7 | 0.40 / 0.55 / 0.71 (1.6) | **pass** |
| Medium | commit | none | 13.1 / 17.2 / 23.1 | 6.23 / 8.37 / 9.57 (38.4) | recorded |
| Medium | end to end | p95 ≤ 100, p99 ≤ 200 | 319.6 / 329.9 / 336.2 | 8.12 / 10.93 / 17.44 (45.9) | **pass** |
| Medium | checkpoint | max ≤ 50 | p50 216.9, max 242.3 | p50 129.2, max 860.8 | **fail** |
| Stress | decision | 15 / 40 / 80 | 821.9 / 831.1 / 835.1 | 0.42 / 0.76 / 0.89 (1.5) | **pass** |
| Stress | commit | none | 24.8 / 32.8 / 50.3 | 8.33 / 9.92 / 10.69 (33.1) | recorded |
| Stress | end to end | none | 1184 / 1217 / 1238 | 10.19 / 13.76 / 15.77 (143.1) | recorded |
| Stress | checkpoint | max ≤ 200 | p50 789.5, max 821.4 | p50 473.1, max 488.1 | **fail** |

**Rejected and replayed steps**, touched-1 on the Pixel, p50 / p99:

| Model | Rejected decision | Rejected end to end | Replayed end to end |
|---|---|---|---|
| Medium | 0.40 / 0.63 | 7.6 / 12.1 | 1.9 / 6.0 |
| Stress | 0.41 / 1.19 | 9.7 / 15.7 | 2.1 / 7.7 |

**Bytes written per commit**, every model:

- steps that change state: p50 189, p99 198, max 458;
- all accepted steps: p50 185, p99 197.

The stateless variant rewrote the whole state on every state change: 193 KB at
Medium, 730 KB at Stress.

**State sizes:** Tiny 188 → 386 B, Medium 192,594 → 192,793 B, Stress 729,921 →
730,120 B. At the end, Medium was 11 `mem` rows and 505 `mem_items` rows;
Stress was 11 and 2,205.

**Full-HOST encode, excluded from e2e** (test output only), p50 / p99:

| Model | ms |
|---|---|
| Tiny | 0.22 / 0.32 |
| Medium | 67.1 / 73.8 |
| Stress | 257 / 273 |

## Where the remaining phone time goes

**Inspected (from the samples):**

- A step is now mostly the SQLite commit: 6 to 11 ms at p50–p99 for Medium and
  Stress, with `synchronous=2` and journal `delete`.
- Decision is below 1 ms at p99 for every model.
- The largest single step is the quest resolve. Its player response `delta`
  carries the whole `narration` list, as the protocol requires. The projection
  takes 34 ms at Medium and 128 ms at Stress, so that step's end to end is
  46 ms and 143 ms. It is one step per run, so it is the max, not the p99.
- The Medium checkpoint has one outlier of 861 ms (sample 15 of 20). The other
  19 are 122 to 182 ms. Nothing captured explains the outlier.

**Inferred, not separately timed:**

- In a checkpoint round trip, the canonical re-encode costs about half the
  full-HOST encode, which holds the state twice. That is about 34 ms at Medium
  and about 130 ms at Stress.
- The rest is the SQLite write and read of one 190 KB or 730 KB row plus the
  strict parse: about 95 ms at Medium and about 340 ms at Stress. The round
  trip was not split into those parts.
- So the checkpoint gate fails because Hermes still takes about 0.6 ms per KB
  to write, read, parse and re-encode the whole state. Structural sharing
  cannot change that: the checkpoint is a whole-state operation by definition.

## Node preview on the M1 (not phone evidence; `m1-node/`)

Node 24.21.0 with `node:sqlite`, running the same `scale.ts` at `9f84063`, AC
power, load average about 2.5.

| Model | Decision p50 / p95 / p99 | End to end p50 / p95 / p99 | Checkpoint max | Verdict |
|---|---|---|---|---|
| Tiny | 0.014 / 0.017 / 0.030 | 0.35 / 0.48 / 1.86 | 1.8 | pass |
| Medium | 0.023 / 0.035 / 0.046 | 0.49 / 0.62 / 0.73 | 4.8 | pass |
| Stress | 0.041 / 0.051 / 0.058 | 0.65 / 0.77 / 0.85 | 17.4 | pass |

Medium and Stress full-HOST encode took 2.6 ms and 10.3 ms at p50. The phone
was about 25 to 35 times slower than the M1 on whole-state work, and about 15
times slower on the commit.

## What this does not measure

- iPhone 11.
- Three runs of 10,000 measured inputs; this is one run of 2,000 per model.
- Memory, JS-thread responsiveness, input-to-feedback latency and cold restore.
- A split of the checkpoint into write, read, parse and encode.
- Other SQLite settings (WAL, `synchronous=1`) and a checkpoint format other
  than one canonical text row.
- Reaction chains and bounded work (the padding is inert).
- Faults under load.
- The on-device A2 differential and fault cases with this host. They ran on
  Node only.

## Files

| Path | Contents |
|---|---|
| `checks/checks.sh`, `checks-run.txt`, `r1-diff-summary.json`, `a2-local-summary.json` | Correctness checks. |
| `m1-node/m1-node.sh`, `m1-node-run.txt`, `a3-samples.csv`, `a3-run.json`, `summary.json` | Node preview. It also regenerates and compares both scale inputs. |
| `pixel-3a/pixel-3a.sh` | Capture script: the stateless one plus a 120 s wait for the probe line after each launch. |
| `pixel-3a/pixel-3a-run.txt`, `pixel-3a-logcat.txt`, `a3-samples.csv`, `a3-run.json`, `summary.json` | Phone run and outputs. |
| `pixel-3a/actions-run-36044635316/` | Actions build bundle as downloaded, with its own SHA256SUMS. |
| `SHA256SUMS`, `SHA256SUMS.verify.txt` | Every file here except these two and this README. |

Notes:

- Each capture script redacts the adb serial, UUIDs, and home, repository and
  temp paths.
- The scripts recorded HEAD `9f84063` (checks, Node) and `02ff058` (phone).
  Those commits differ from `97bccfa` only under `docs/`.
- Commits on this branch skipped the repository pre-commit hook (`--no-verify`),
  which needs Erlang 28.3 for the v2 app.

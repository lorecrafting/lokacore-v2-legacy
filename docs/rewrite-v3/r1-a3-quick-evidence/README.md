# Quick R1-A3 evidence (2026-09-24)

This is a decision-grade smoke measurement, not the full A3. The owner decided to
replace the full A3 program with one check
(`prep/after-pr-10/owner-decision-a3-2026-09-24.md`). The risk under test is that
candidate C's stateless kernels copy, encode and persist the whole state on every
step. Is that too slow at Medium or Stress size on the Pixel 3a?

**Result: on the Pixel 3a, Medium and Stress fail every timing gate by a wide
margin.** Medium decision takes about 216 ms at p50 against a 5 ms threshold.
Medium end to end takes about 336 ms at p99 against 200 ms. The M1 server passes
everything. By the owner's rule, this stops before R2.

## Inputs

- **Generator:** `mix r1.scale` (`r1-spike/harness`), version `r1-scale-1`, seed
  20260924. The committed input is `r1-spike/mobile/scale.jsonl` (sha256
  `8591d212…4cb52`). The M1 run regenerated it and confirmed it byte for byte.
- **World:** Lantern. Tiny is the unpadded initial memory. Medium carries 300
  synthetic entities, 100 typed facts and 100 pending jobs. Stress carries 1,000
  entities, 200 facts and 1,000 jobs.
- **Where the padding sits:** `memory.narration`. Both kernels carry that list
  through every step, and both accept it as valid memory. No kernel, fixture or
  conformance file changed.
- **What the padding measures:** the cost of copying, encoding, hashing and
  persisting state at scale. It does not exercise bounded-work semantics: there
  are no reaction chains, scenes, fan-out or job scheduling.
- **Canonical state size:**

  | Model | Size | Size guide (§7) |
  |---|---|---|
  | Tiny | 189 B | 8 KB |
  | Medium | 192,595 B | 256 KB |
  | Stress | 729,922 B | 1 MB |

- **Commands:** every model gets the same stream of 3,000 commands: 1,000 warm-up
  steps, then 2,000 measured. The mix is envelope §3 with the Tiny substitution.
  Measured outcomes, per model: 1,276 accepted (642 of which write the state),
  685 rejected, 39 replayed.
- **Host agreement:** both hosts ended every model with the same state sha256, and
  both hold 2,916 receipts.
- **Skew in the mix:** in the measured window every wait, activate and choose was
  rejected. The Lantern clock had already reached 23 during the warm-up, and the
  quest was never activated.

## Per-step phases (identical on both hosts)

| Phase | What it covers |
|---|---|
| Admission | Receipt lookup by primary key, then building the kernel HOST value (memory plus that one receipt). |
| Decision | Kernel `step` in process: TypeScript `world.ts` on Hermes, `LokaR1.World.step` on the BEAM. There is no further boundary. |
| Encode | Canonical encoding of the durable state, only when the revision changed, plus the receipt and events. |
| Commit | `BEGIN IMMEDIATE` … `COMMIT`: state row plus receipt row, plus outbox rows on the phone. |
| Projection | Adopt the new memory and encode `{result, events, delta}`. |
| End to end | The sum of all five phases above. |

- **Checkpoint:** 20 round trips per model after the run. Each one writes the
  state, reads it back, parses it and checks canonical equality.
- **Clocks:** `performance.now()` on Hermes, `System.monotonic_time` on the BEAM.
- **Percentiles:** nearest rank, from `r1-spike/mobile/scripts/scale-summary.mjs`.
- **Verdict rule:**
  - pass: every gated percentile is under half its threshold;
  - close: at least one is at or above half, and none is over;
  - fail: at least one is over.
- **Gated class:** gates use the accepted class. Every class is in `summary.json`.

## Hosts

**Pixel 3a** (Android 11, `sargo` RQ2A.210505.002):
- Release APK from Actions run
  [36031156199](https://github.com/lorecrafting/lokacore/actions/runs/36031156199),
  source `2fcd329`, APK sha256 `1d5818a3…23ef5`, same pins as A2. The build bundle
  is in `pixel-3a/actions-run-36031156199/`.
- Hermes: Release build, Static Hermes, bytecode 98.
- expo-sqlite: SQLite 3.50.3, `journal_mode=delete`, `synchronous=2`. This is the
  A2 phone host's default configuration.
- The run took 3,685 s in one launch. The app stayed in the foreground with the
  screen unlocked; the script checked every 10 s.
- Battery was 100%, AC powered, before and after.
- Battery temperature went from 31.5 °C to 37.3 °C. Thermal status was 0 before
  and after.
- The capture script at run time was at `1939304`. App source is identical to
  `2fcd329`: only capture scripts changed in between.

**M1 server** (MacBook Air, MacBookAir10,1, 16 GB, macOS 26.6.2):
- Elixir 1.20.4, OTP 28.4.
- `exqlite` 0.40.0 with SQLite 3.53.4, WAL, `synchronous=FULL` (the A2 store).
- Runs in the calling process; there is no GenServer hop.
- AC powered, 100% battery, load average about 2.0 before and after.
- Source `d841d79`.

## Results (accepted steps, ms, p50 / p95 / p99, nearest rank)

| Model | Host | Metric | Threshold | Observed p50 / p95 / p99 (max) | n | Verdict |
|---|---|---|---|---|---|---|
| Tiny | Pixel 3a | decision | 2 / 5 / 10 | 0.52 / 0.61 / 0.73 (2.2) | 1276 | pass |
| Tiny | Pixel 3a | commit | none separate | 3.96 / 5.00 / 7.47 (24.8) | 1276 | recorded |
| Tiny | Pixel 3a | end to end | none for Tiny | 5.46 / 6.81 / 9.12 (26.2) | 1276 | recorded |
| Tiny | Pixel 3a | checkpoint round trip | max ≤ 10 | p50 4.9, max 5.9 | 20 | close |
| Medium | Pixel 3a | decision | 5 / 15 / 30 | 215.9 / 219.7 / 222.7 (265.4) | 1276 | **fail** |
| Medium | Pixel 3a | commit | none separate | 13.1 / 17.2 / 23.1 (38.8) | 1276 | recorded |
| Medium | Pixel 3a | end to end | p95 ≤ 100, p99 ≤ 200 | 319.6 / 329.9 / 336.2 (376.5) | 1276 | **fail** |
| Medium | Pixel 3a | checkpoint round trip | max ≤ 50 | p50 216.9, max 242.3 | 20 | **fail** |
| Stress | Pixel 3a | decision | 15 / 40 / 80 | 821.9 / 831.1 / 835.1 (840.1) | 1276 | **fail** |
| Stress | Pixel 3a | commit | none separate | 24.8 / 32.8 / 50.3 (73.5) | 1276 | recorded |
| Stress | Pixel 3a | end to end | none for Stress | 1184 / 1217 / 1238 (1309) | 1276 | recorded |
| Stress | Pixel 3a | checkpoint round trip | max ≤ 200 | p50 789.5, max 821.4 | 20 | **fail** |
| Tiny | M1 server | decision | 2 / 5 / 10 | 0.004 / 0.004 / 0.011 | 1276 | pass |
| Tiny | M1 server | commit / end to end | none separate | 0.06 / 0.08 / 0.09 ; 0.08 / 0.10 / 0.11 | 1276 | recorded |
| Tiny | M1 server | checkpoint round trip | max ≤ 10 | max 0.09 | 20 | pass |
| Medium | M1 server | decision | 5 / 15 / 30 | 0.005 / 0.015 / 0.018 | 1276 | pass |
| Medium | M1 server | commit | none separate | 0.19 / 0.46 / 1.04 | 1276 | recorded |
| Medium | M1 server | end to end | p95 ≤ 100, p99 ≤ 200 | 2.78 / 5.36 / 5.93 | 1276 | pass |
| Medium | M1 server | checkpoint round trip | max ≤ 50 | max 16.2 | 20 | pass |
| Stress | M1 server | decision | 15 / 40 / 80 | 0.007 / 0.024 / 0.030 | 1276 | pass |
| Stress | M1 server | commit / end to end | none separate | 1.11 / 2.78 / 2.96 ; 15.2 / 26.4 / 40.6 | 1276 | recorded |
| Stress | M1 server | checkpoint round trip | max ≤ 200 | p50 75.0, max 117.5 | 20 | close |

The M1 row applies the minimum-device thresholds for comparison only. The
envelope gates them on the phone.

### Where the phone time goes (Medium, accepted)

| Phase | Time | What it is |
|---|---|---|
| Decision | about 216 ms | The TypeScript kernel `step` clones the whole HOST several times and, for `delta`, encodes each memory key twice. |
| Encode | about 91 ms | Canonical encoding of the durable state for the write. |
| Commit | about 13 ms | The SQLite transaction. |

- Rejected and replayed steps are not cheap on the phone either. Medium rejected:
  p50 227 ms. Medium replayed: p50 198 ms. Replays still cross the kernel with
  the whole state.
- On the BEAM, the decision costs microseconds because immutable maps share
  structure. There, encoding the state is the main cost.

## What this does not measure

- iPhone 11 timing.
- Three runs of 10,000 measured inputs per device. This is one run of 2,000 per
  model.
- Memory: RSS, heap, retained growth.
- UI and JS-thread responsiveness, and input-to-feedback latency.
- Cold restore to interactive.
- The 100-instance server load, burst load and scheduler impact.
- Reaction chains, scene consequences, bounded-work budgets, fan-out and job
  scheduling semantics. The padding is inert.
- Faults under load.
- Alternative host strategies: retained or touched-state caches, WAL on the phone,
  or skipping the per-key delta encode. None was built or timed.

## Files

| Path | Contents |
|---|---|
| `m1-server/m1-server.sh` | Capture script. |
| `m1-server/m1-server-run.txt` | Host facts, commit, power and load before and after. |
| `m1-server/a3-samples.csv`, `pixel-3a/a3-samples.csv` | Raw measured steps: one row per step, per-phase ms. |
| `m1-server/a3-run.json`, `pixel-3a/a3-run.json` | Per-model facts: sizes, final hash, checkpoint samples in µs, SQLite pragmas; the phone runtime probe. |
| `*/summary.json` | Every class, percentiles and gates. |
| `pixel-3a/pixel-3a.sh` | Capture script. |
| `pixel-3a/pixel-3a-run.txt` | Commands and outputs, battery and thermal readings, the progress timeline. |
| `pixel-3a/pixel-3a-logcat.txt` | Logcat for the app and ActivityManager. |
| `pixel-3a/actions-run-36031156199/` | Actions build bundle: APK facts, composed source map, runner and tool identities. |
| `SHA256SUMS`, `SHA256SUMS.verify.txt` | Index of every file except these two and this README, and its check output. |

Two notes on these files:

- The logcat ring buffer had already wrapped when it was captured, so
  `pixel-3a-logcat.txt` only starts at Stress 250/3000.
  `pixel-3a-run.txt` has the full progress timeline, and the per-model facts are
  in `a3-run.json`.
- The source map contains third-party absolute paths from the Expo package
  sources, such as `/Users/evanbacon/…`, and the Actions files contain runner
  paths. Neither comes from this machine. They are kept byte for byte, as in A2.

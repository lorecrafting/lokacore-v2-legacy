# R1 Acceptance Envelope

**Version:** 0.1 (proposed). **Status:** every number below is *proposed, Raymond to confirm*. Once confirmed, this file is frozen before any spike code exists (document 14 R1). Changing a threshold after the spike starts requires a document 18 entry stating what was measured before the change.

This envelope pre-registers what "acceptable" means for the portable-kernel spike so the result cannot be redefined to favor a candidate. Candidates are document 14 R1: **A** one TypeScript kernel (native in React Native, Erlang Port from BEAM), **B** one Rust kernel (Rustler plus native mobile bindings), **C** dual Elixir/TypeScript with golden-vector parity. Rows marked MUST are gates; rows marked RECORD are measured and reported but do not reject a candidate on their own.

Two packet contradictions found while drafting were recorded and resolved in document 18 §33.

## 1. Models

| Model | Content | Runtime entities (approx.) | Source |
|---|---|---|---|
| Tiny | `00a` §12 hello-world fixture, used as-is: 2 rooms, 1 reciprocal exit, 1 NPC, 1 item, 1 fact, 1 quest, 1 dialogue, 1 player, 1 scheduled job (Bram's schedule), 1 RNG check | 5 | `00a-chapter-one-content.md` §12 |
| Medium | Chapter one complete: 57 rooms, 16 named NPCs, 4 PopulationPlans at their day caps (hounds 4, deer 3, crows 4, rats 5), every §5 item, every §6 fact, 10 quests, all §9 scenes and §10 reactions, 1 player with a 14-slot paper doll | 250 to 400 | `00a` §1 to §10 |
| Stress | Full 109-room design, every named NPC in document 00 §2, 10 PopulationPlans each at its declared cap, all 28 quests instantiated, 30 world days of durable jobs pending, 200 typed facts set, 1 player | at least 600, target 1,000 | `00-first-cartridge-design.md` §3, §4.7 |

The Tiny model now matches the doc 14 R1 tiny model; RNG replay (DET-03) and durable-job determinism are proved at Tiny and again at Medium.

Stress content that does not yet exist as YAML MAY be synthesized by the compiler fixture generator, provided it uses only capabilities in the `00a` §1 lock.

## 2. Command mix per 1,000 commands

Applied identically to every model and every host. Commands are ActionInvocations from a deterministic bot; the order is seeded and recorded.

| Command | Count | Notes |
|---|---|---|
| look (room, detail, item, NPC) | 300 | half are room looks, half target a detail or entity |
| move | 350 | every exit direction; includes rejected moves at barriers and dark rooms |
| take / drop | 100 | includes 20 duplicate invocations that MUST be rejected by receipt |
| talk / choose | 150 | dialogue entry plus one choice; includes stale-choice rejections (DIA-02) |
| wait / advance time | 90 | one world hour each; crosses day/night, tide, and shop-hour boundaries |
| reaction chain trigger | 5 | one command whose committed events fire a ReactionRule chain of depth 3 or more (Medium: ring the bell) |
| scene beat | 5 | one SceneSequence step with a typed world consequence (Medium: a Q2 consequence beat) |

Tiny has no reactions or scenes; its 10 reaction and scene slots become 5 extra looks and 5 extra talks.

Decision output size (StateDelta plus DomainEvents plus Effects, canonical bytes) is RECORDED per command class and per model.

## 3. Target devices

| Class | Proposed device | Why |
|---|---|---|
| Development machine | Apple Silicon Mac, M1 or later, 16 GB | the one machine class the project builds on; measurements here are RECORD only |
| Minimum iOS | iPhone SE 2nd generation (A13, 3 GB), current supported iOS | the lowest-end device Expo SDK 52 targets that is still sold refurbished |
| Minimum Android | Samsung Galaxy A14 (4 GB), Android 13 | a representative budget device with a weak CPU and a JS engine that is not Hermes-optimized by the vendor |

All MUST thresholds below are measured on the two minimum devices, release build, device not plugged in, after a 1,000-command warm-up. The development machine is RECORD only.

## 4. Per-decision latency ceilings (MUST)

One decision = one ActionInvocation from re-resolution through `decide()` to a StateDelta in host memory, including any host boundary crossing the candidate has, excluding the durable commit (measured separately in §7). Milliseconds, on each minimum device.

| Model | p50 | p95 | p99 |
|---|---|---|---|
| Tiny | 2 | 5 | 10 |
| Medium | 5 | 15 | 30 |
| Stress | 15 | 40 | 80 |

Full command round trip (decision plus SQLite commit plus GameView projection) on Medium: p95 at most 100 ms, p99 at most 200 ms. This is the touch-feedback budget for §4.10 of document 00.

Reaction chain and scene beat commands are measured as their own class; their p99 MAY be 3× the row above.

## 5. Serialization budget per decision (MUST where a boundary exists)

Bytes that cross a host boundary per decision, both directions summed, canonical encoding. A candidate is measured on every boundary it actually has: A has a Port boundary on BEAM and none on mobile; B has an FFI boundary on both hosts; C has none. Each candidate MUST benchmark all three strategies from document 07 §6 on each boundary it has, then keep the simplest that passes.

| Strategy | Tiny | Medium | Stress |
|---|---|---|---|
| state-in / state-out (whole state each way) | 16 KB | RECORD | RECORD |
| retained handle + non-mutating delta | 4 KB | 32 KB | 128 KB |
| touched-slice in, delta out | 4 KB | 16 KB | 64 KB |

State-in/state-out is expected to exceed any sane budget above Tiny; it is RECORD at Medium and Stress so the cost of the simplest protocol is known, not a gate. The kept strategy MUST also preserve document 07 §6's list: deterministic replay, crash recovery, snapshot export, transaction ordering, testability. A retained handle MUST NOT become hidden authoritative state (ADR-059, DET-09).

## 6. BEAM boundary (MUST)

| Candidate | Ceiling |
|---|---|
| A, Erlang Port to Node | Port round trip for one Medium decision, p95 at most 5 ms and p99 at most 15 ms on the development machine; a Node runner crash is detected and restarted within 1 s with no committed-state loss; one Node runner serves at least 50 concurrent Medium instances at the p95 above |
| B, Rustler normal NIF | no single normal-NIF call exceeds 1 ms at Stress; any decision that can exceed it MUST run on a dirty CPU scheduler; scheduler responsiveness (a 1 ms `:timer` heartbeat on an unrelated process) degrades by at most 10% under 100 concurrent Medium instances |
| C | no boundary; Elixir decision latency is held to §4 on the development machine as RECORD |

## 7. Save round trip (MUST)

Snapshot (document 03 §18) serialized, written to SQLite, read back, deserialized, and hashed; the hash MUST equal the pre-save hash. On each minimum device.

| Model | Size | Time |
|---|---|---|
| Tiny | 8 KB | 10 ms |
| Medium | 256 KB | 50 ms |
| Stress | 1 MB | 200 ms |

Save happens on every action (document 00 §1). The Medium time above therefore also bounds the per-command commit cost inside §4's round trip.

## 8. Memory over 10,000 commands (MUST)

After the 1,000-command warm-up, run 10,000 more commands from the §2 mix and sample RSS every 500.

| Model | Per-instance ceiling on minimum device | Allowed growth over the 10,000 | Trend |
|---|---|---|---|
| Medium | 32 MB | 5 MB | least-squares slope at most 0.2 KB per command |
| Stress | 96 MB | 10 MB | least-squares slope at most 0.5 KB per command |

A forced GC or snapshot-and-reload at the end MUST return RSS to within 10% of the warm-up value. For A on BEAM, the Node runner's RSS is measured the same way per hosted instance.

## 9. Crash containment (MUST)

A kernel fault (exception, panic, out-of-memory inside the kernel, runner process death) MUST NEVER:

- commit partial state; the authority revision does not advance and the save file's prior snapshot remains valid (OFF-03, OFF-07);
- duplicate a command; at most one receipt exists for the command id, and a retry after restart either commits exactly once or is rejected with the same typed error (OFF-05, RECEIPT-01, DET-11);
- let proposed DomainEvents or projection hints escape as committed (ARCH-09, DET-09);
- take down the host authority without restart from the last committed revision within 1 s (Story: `LocalInstanceAuthority`; Realm: the instance owner);
- lose the trace needed to reproduce it (document 09 §2 repro record is complete for the faulting command).

The spike injects faults at every step of the Tiny golden trace and at 100 random points of a Medium run.

## 10. Build and debug criteria (MUST)

- Expo/EAS builds pass for both platforms in `development` and `production` profiles from a clean CI runner.
- A kernel stack trace from a fault on a minimum device maps to kernel source file and line (A: Hermes source maps; B: symbolicated native frames).
- A: upgrading the kernel package version rebuilds only the JS bundle; no native rebuild is needed. Store shipment still goes through the reviewed app binary (document 10 §14).
- B: the same upgrade requires a native rebuild; the time from kernel tag to installable build on both platforms is RECORD and MUST be under 60 minutes in CI.
- The full spike CI (all hosts, golden trace, conformance mismatch injection) completes in at most 30 minutes.
- A deliberately injected semantic mismatch on one host is caught by conformance CI (document 07 §14 item 9).

## 11. Dependency risk

- B: any third-party binding generator that describes itself as early-development, experimental, or not recommended for production is disqualifying (ADR-005, document 07 §4). Only a stable C ABI with hand-written platform wrappers or a TurboModule/JSI path maintained by the React Native project counts as acceptable.
- A: the kernel package MUST run unchanged on Hermes with no polyfills, MUST contain no native modules, and MUST use integer or fixed-point arithmetic for rule-critical math (A8). The Node runtime version on the server is pinned; the container image size increase is RECORD.
- C: no new dependency. The permanent dual-maintenance cost is RECORD, stated as the count of semantic contract items that had to be implemented twice in the spike.
- All: every pinned toolchain version is listed in the R1 evidence report.

## 12. Comparison procedure

1. **A is built first** against the Tiny model, then Medium, then Stress, on all four hosts (development machine, minimum iOS, minimum Android, BEAM via Port).
2. If A passes every MUST row, the R1 ADR selects A. B and C are not built.
3. If A fails any MUST row, the failing rows and measured values are recorded, then **B** is built and evaluated the same way. Document 07 §14 item 3 (two mobile binding strategies) applies only in this step.
4. If B also fails, **C** is built and evaluated. C has no boundary rows; it must still pass §4, §7, §8, §9, §10.
5. Whichever candidate is kept: the `00a` §12 golden trace hash MUST be identical on every host it runs on, and save/reload on every host MUST preserve that hash (document 07 §14 items 4 to 7). No candidate is accepted on the development machine alone.
6. The evidence report lists, for every row above, the pre-registered threshold and the measured value side by side (document 14 R1). A row that was not measured is a fail, not a pass.
7. The spike is disposable. Only fixtures, benchmarks, the evidence report, and code deliberately chosen for re-implementation leave it.

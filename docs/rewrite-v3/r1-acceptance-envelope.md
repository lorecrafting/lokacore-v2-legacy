# R1 Acceptance Envelope

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** R1 approved targets; setup and results pending.

Read semantic versus synthetic workloads, measurement methods, fault classes and acceptance procedure. Targets are owner-approved; actual setup and measurements are not complete.

<details>
<summary>Sections in this document</summary>

- [1. Two kinds of evidence, not a preliminary engine rebuild](#1-two-kinds-of-evidence-not-a-preliminary-engine-rebuild)
- [2. Candidates and decision rule](#2-candidates-and-decision-rule)
- [3. Corpus, command mix, and sampling](#3-corpus-command-mix-and-sampling)
- [4. Physical devices and reproducible setup](#4-physical-devices-and-reproducible-setup)
- [5. Decision and user-visible latency (MUST)](#5-decision-and-user-visible-latency-must)
- [6. Boundary strategies and common server workload (MUST)](#6-boundary-strategies-and-common-server-workload-must)
- [7. Persistence, checkpoint, and cold restore (MUST)](#7-persistence-checkpoint-and-cold-restore-must)
- [8. Memory and retention (MUST / RECORD)](#8-memory-and-retention-must--record)
- [9. Fault classes and recovery (MUST)](#9-fault-classes-and-recovery-must)
- [10. Build, debug, dependencies (MUST unless RECORD)](#10-build-debug-dependencies-must-unless-record)
- [11. Decision report and remaining gates](#11-decision-report-and-remaining-gates)
- [12. Setup, implementation and acceptance are distinct](#12-setup-implementation-and-acceptance-are-distinct)

</details>
<!-- packet-navigation:end -->

**Version:** 0.5 — original numerical criteria retained; owner-approved staged preparation and delegated hardware selection, 2026-09-23 (ADR-064); proposed A1-only hosted execution host, 2026-09-23 (§4). Amendment review/merge, R0, setup reviews and measurements remain pending. **No candidate has been selected, benchmarked, or accepted.** Freeze accepted envelope bytes, reviewed fixtures and the reproducible A1 execution setup before semantic implementation. Freeze complete native/physical setup and obtain new stage-bound review before A2; preparation may proceed now. Amendments after measurement must identify the earlier measurements and reason; never tune the acceptance rule to rescue a favorite candidate.

R1 is a disposable feasibility experiment in a separate workspace. It is not the production engine or a requirement to implement chapter one twice. The 57-room first release remains unchanged. `pre-release-proof.md` defines a later, small player-facing proof of the fresh engine; that proof is not the R1 microbenchmark.

## 1. Two kinds of evidence, not a preliminary engine rebuild

**R1A — semantic and integration proof.** Implement the corrected two-room `00a` §12 model: one NPC with a two-block durable schedule, one item/check, one offered quest, one fact, one dialogue, and one player. Prove receipt admission, accepted failure, proposed-event containment, deterministic IDs/RNG, commit recovery, projection, and build/debug paths on the candidate hosts. Prepared definitions are allowed: building the production compiler is R4, not a prerequisite to choosing the implementation language.

**R1B — scaling and interaction proof.** Scale data volume and bounded work using the same semantic vocabulary. Add one small reaction-chain and one durable scene-consequence fixture, not the full narrative/population/commerce system. Use synthetic objects, subscriptions, dirty sets, and pending jobs to stress copying, fan-out, serialization, scheduling, and restore. Publish the fixture generator, seed, and exact artifacts; all candidates receive identical inputs.

| Model | Approved target volume | Semantic work |
|---|---|---|
| Tiny | Two rooms, one NPC, one item, one player; one quest/fact/job | Corrected hello trace and explicit negative cases |
| Medium synthetic | 300 runtime entities, 100 typed facts, 100 pending jobs; representative small and large dirty sets | Tiny semantics plus bounded chain/scene fixtures; no requirement to author 57 rooms or ten quests |
| Stress synthetic | 1,000 entities, 200 typed facts, 1,000 pending jobs; maximum supported dirty set/fan-out in the fixture | Same operations at deliberately stressful volume; bounded work is checked |

The full chapter-one artifact is a **later representativeness check** at R10, not an R1 prerequisite; R6P contributes earlier slice-level measurements. If it exposes a missed workload, amend the evidence report rather than asserting that synthetic coverage already proved it.

## 2. Candidates and decision rule

- **A:** one TypeScript kernel, Hermes in React Native, isolated Node runner reached through a BEAM Port.
- **B:** one Rust kernel, native mobile bindings and an explicitly declared BEAM boundary. A Rustler NIF is in-process; an isolated Rust worker is a distinct boundary variant and must be documented/tested as such.
- **C:** independent Elixir and TypeScript implementations against the same semantic corpus.

A is tested first. Passing all applicable MUST gates selects the simplest sufficient A design; B/C need not be built. This is a sufficiency procedure, **not** a claim that unmeasured alternatives are inferior. If A fails, record results and evaluate B; if B fails, evaluate C. Infeasible/unavailable measurements remain unmeasured and cannot pass. Any new boundary variant is recorded before its performance tuning; all common safety and load gates still apply.

Retained runner/native state is only a revision-tagged, reconstructible cache of committed state. It cannot become a second authority or advance irreversibly before host commit. Keep portable rule semantics in the kernel; BEAM owns online admission, serialized ownership, persistence, scheduling coordination and effects.

## 3. Corpus, command mix, and sampling

`conformance/README.md` defines fixture/oracle layers. The small Python contract model is specification evidence only: it is neither a candidate implementation nor cross-host validation. R1 adapters must produce per-step canonical outcome, StateDelta, event/effect, RNG, and state bytes, with hashes derived from those bytes. Comparing final hashes or transcripts alone is insufficient. Candidate outputs must not regenerate their own expected baselines in CI.

Before candidate implementation, freeze the RNG/numeric/encoding profile and known-answer vectors (see `conformance/numeric-profile.md`). Every accepted host must test negative division/remainder, overflow, invalid JSON/numbers, post-draw RNG state, rejected attempts, failed attempts, and restore.

| Class per 1,000 inputs | Count | Required variations |
|---|---|---|
| look/inspect | 300 | Room, entity, detail; projection does not draw RNG |
| move | 350 | Accepted and policy-denied moves; stable target ordering |
| take/drop | 100 | 20 matching duplicate deliveries replay; altered semantic intent conflicts |
| talk/choose | 150 | Activation before credit; stale NEW choice denied; consumed-choice retry replays |
| wait/advance | 90 | Schedule boundaries, due-job dedupe, deterministic time |
| bounded reaction trigger | 5 | Depth at least three; explicit budget failure |
| scene consequence | 5 | Durable continuation and post-commit presentation recovery |

Tiny substitutes five looks and five talks for the final ten inputs. Publish exact valid/invalid/replay counts; do not let cheap rejections hide accepted-command latency. A seeded generator supplies legal setup and records every input, rather than assuming a random action is valid.

Run 1,000 warm-up inputs, then at least 10,000 measured inputs in each of three runs. Collect at least 1,000 samples for each separately gated rare class; otherwise report its maximum and sample count, not a spurious confident p99. Report accepted, rejected, replayed, and faulted paths separately, with p50/p95/p99, sample counts, and the percentile method.

## 4. Physical devices and reproducible setup

| Class | Approved target hardware | Evidence |
|---|---|---|
| Development/server host | Apple Silicon M1-or-later, 16 GB | Exact model, OS, runtime, cores and load recorded; common server tests use the same host |
| A1 semantic execution host (A1 only) | Identified GitHub-hosted Linux runner | Runner label, observed image version, run/attempt, source commit, OS, architecture, cores, RAM and actual runtime versions retained in a checksum-indexed bundle. Correctness and lock replay only: no timing, load or A2 evidence, and the row above still governs common server tests |
| Initial iOS qualification candidate | iPhone 11 (A13, planned 4 GB class) | Owner reports physical availability; actual RAM/SKU/OS and release-build toolchain still need verification before A2 |
| Minimum Android candidate | Galaxy A14, 4 GB | Confirm exact variant, OS and release-build toolchain before freeze |

These are owner-approved qualification classes, not claims about current Expo minimum support, measured support or actual device availability. Record exact Expo/React Native/Hermes, Node/Elixir/OTP, Rust/bindings if used, OS and build identifiers. Use release builds, stable thermal conditions and recorded battery/power state. A simulator or development machine cannot substitute for physical-device acceptance. Cold install/load/restore is measured separately from warm decisions.

The 2026-09-23 owner instruction reports an M1 MacBook Air/16 GB, iPhone 11,
old Pixel of unknown model and BOOX Palma 2, and delegates minimum-target choice.
The selected iOS planning baseline changes from SE 2/3 GB to the available
iPhone 11/4 GB class; no measurements exist to invalidate or conceal. This is a
narrower support claim, not evidence that 3 GB iPhones pass. The Android A14/4 GB
class remains; determine the Pixel SKU/SoC/RAM/OS before considering substitution.
Palma 2 is an optional e-paper usability device, not a replacement phone or new
mandatory platform. Simulators/emulators are development/compatibility tools,
not physical latency or memory qualification. Numerical gates below are unchanged.

### 4.1 Support policy and recorded setup

Qualification targets: physical iPhone 11 (A13, planned 4 GB class); an exactly identified Galaxy A14-class 4 GB Android phone, preferably an A14 5G variant; Android arm64 initially. Record actual SKU/SoC/RAM/OS rather than treating all A14 variants or an iPhone SE 2 as interchangeable. Target iOS 16.4+ and Android 10+ for the initial product planning matrix; recheck the exact native dependencies and distribution constraints at setup freeze and release. These OS choices do not certify every installable device or promise security support for obsolete systems.

Minimum-hardware performance, lowest-target-OS compatibility and latest-stable-OS release smoke are separate coverage rows. Simulators supplement OS compatibility but never replace physical-device timing. The plain readable/touch-first UI must work on the floor; page curls, particles, shaders and 3D transitions are optional enhancements with identical gameplay. R1 adds no consumer-web or advanced graphics milestone.

[The setup manifest template](conformance/r1-run-manifest.template.json) intentionally leaves unknown real devices, toolchain pins, accepted commit and reviewer receipts empty. `checks/readiness.py --require-ready MANIFEST --evidence-root DIR --stage A1` must fail until actual A1 host/runtime/lock evidence and hash-bound contract/input/review records exist. The default or explicit `--stage A2` additionally requires complete native toolchain and physical qualification inventory. Stage-specific review digests prevent reusing A1 approval as A2 approval. Its pass validates preparation records only, not genuine hardware use, timing accuracy or R1 acceptance. Never fill nulls with invented measurements. Build hashes, temperatures/battery and per-run environment go into actual result manifests after implementation; they cannot exist before the candidate is built.

Current official references, rechecked 2026-09-22: [Expo SDK reference](https://docs.expo.dev/versions/latest/) for dependency/OS compatibility and [React Native performance](https://reactnative.dev/docs/performance) for release-build/JS-response distinctions. The reference tables are not a lockfile. Freeze exact stable patches and native module versions, not `latest`, canary or an invented tested version. A necessary support change requires a reviewed amendment, not a silent relaxation after a failed measurement.

## 5. Decision and user-visible latency (MUST)

Decision timing includes NEW-invocation re-resolution, kernel work and any boundary crossing up to a proposal in host memory; it excludes persistence and projection, which are separately timed. Per minimum physical device, milliseconds:

| Model | p50 | p95 | p99 |
|---|---|---|---|
| Tiny | 2 | 5 | 10 |
| Medium synthetic | 5 | 15 | 30 |
| Stress synthetic | 15 | 40 | 80 |

Medium end-to-end authoritative response (admission + decision + actual SQLite commit + projection): p95 <=100 ms, p99 <=200 ms. Reaction/scene decision p99 may be up to 3x the corresponding row, but not by waiving end-to-end or UI responsiveness gates.

During movement, long reactions, time advancement, saving and loading, measure actual input-to-feedback latency and JS-thread responsiveness. Approved target gates: p95 input-to-visible-pending-feedback <=100 ms; no continuous JS unresponsiveness >100 ms on the warm supported workload. A pending indicator is not authoritative success. Record frame stalls, cold-load responsiveness, and p99 feedback. Unchanged animation alone is not evidence that touch processing remained responsive.

Reference: [React Native performance overview](https://reactnative.dev/docs/performance). Sharing TypeScript code does not itself prove a responsive mobile integration.

## 6. Boundary strategies and common server workload (MUST)

Measure bytes copied, encode/decode time, boundary round trips, decision time, and projection time separately. Begin with the simplest stateless state-in/proposal-out strategy. If it passes all gates, do not build elaborate retained handles merely to complete a comparison checklist. If it fails, compare revision-tagged retained cache and/or touched-state slices; explain any strategy omitted for a concrete correctness reason. No candidate may omit its actual boundary overhead.

All candidates receive the same server workload on the same development/server host:

- 100 Medium instances; steady 1 input/second per instance for the measured run;
- a burst of 10 inputs per instance within one second; preserve per-instance order;
- one budget-exhausting instance competing with ordinary instances;
- bounded queues, explicit busy/retry responses and no silent loss or duplicate application.

Approved target server ceilings, including admission/queueing/boundary/decision/projection but excluding PostgreSQL (not built until R14): steady p95 <=25 ms, p99 <=75 ms; burst p99 <=500 ms, no accepted input stranded after the burst drains. Report busy/rejected input counts; overload rejection cannot disguise an inability to sustain the steady workload. Default approved target queue cap: 100 pending inputs per instance. Runtime pool size, runner concurrency and memory footprint are part of the evidence.

For B with NIFs, no normal-scheduler call may exceed 1 ms at Stress; longer work requires an appropriate boundary. Under the same load, an unrelated BEAM heartbeat's p99 delay may degrade by no more than 10% relative to its recorded baseline. Test scheduler impact for A/C too. Dirty scheduling is not process isolation.

This is a portability-host load test, not R14 PostgreSQL certification, R20 shard capacity, or an MMO scalability claim.

## 7. Persistence, checkpoint, and cold restore (MUST)

Time these separately: decision; dirty-state encoding; atomic SQLite write including receipt; projection; checkpoint serialization/write; cold read/deserialize/rebuild; integrity hashing. Persist every accepted attempt, including failed rolls. Do not implement a full export/readback/hash round trip per action unless it is the measured simplest passing design.

| Mutable checkpoint | Approved target size guide (RECORD) | Approved target complete checkpoint round trip ceiling (MUST) |
|---|---|---|
| Tiny | 8 KB | 10 ms |
| Medium | 256 KB | 50 ms |
| Stress | 1 MB | 200 ms |

The round trip reads and validates what was written; its canonical state must equal the pre-save state. It is separate from the ordinary command-commit cost in §5. Immutable definitions/assets are not duplicated into every save. Report durable receipt/trace/job sizes separately; do not omit state needed for recovery to meet a size guide. Test disk-full/write-failure and confirmed rollback as well as lost COMMIT acknowledgement.

Approved target cold Medium restore-to-interactive ceiling: 3 seconds after application launch/resume begins. Record package verification and other startup costs separately and together. No claim is made that a mobile OS will automatically relaunch a killed application.

## 8. Memory and retention (MUST / RECORD)

Record process RSS, attributable live/retained heap, shared runtime baseline, per-instance cache, and disk growth over 10,000 inputs after warm-up. Report A's Node runner as a whole as well as incremental hosted-instance cost; do not divide away fixed overhead.

Approved target live-state/caches ceilings on minimum devices: Medium 32 MB, Stress 96 MB; retained growth above explained durable working-set growth <=5 MB / <=10 MB. Repeated load/unload and snapshot/restore must show no unbounded live-object retention. RSS/allocator high-water marks and GC diagnostics are RECORD, not proof of a leak or mandatory production-GC behavior. Where heap measurement is unavailable, record a justified alternative and obtain review before accepting the row.

Bounded caches/jobs and receipt-retention semantics are checked independently. Erasing receipts to make a memory graph flat is a correctness failure.

## 9. Fault classes and recovery (MUST)

| Fault | Required behavior |
|---|---|
| New attempt rejected by rules | No game-state/RNG/time advancement; terminal-receipt behavior is explicit |
| Valid attempt fails its check | One committed failed outcome and RNG advance; same invocation replays |
| Caught evaluator exception/budget failure | Discard uncommitted proposal; no externally committed events; preserve/rebuild authority |
| Definite persistence rollback | Prior durable state remains; same identity may retry without a hidden RNG advance |
| COMMIT acknowledgement unknown | Fence new decisions; resolve original transaction/receipt on authoritative storage; no speculative retry |
| Isolated runner death | Detect and reconstruct from committed state; proposed state is not authoritative; approved target Tiny worker recovery target <=1 second |
| Fatal native process/BEAM VM failure | Explicitly report blast radius; durable state survives, recovery occurs through process/service restart, not an imaginary in-process exception handler |
| Mobile process kill/OS memory termination | Recover on actual relaunch/resume, within cold-restore budget; no self-relaunch promise |

Inject faults before decision, after decision/before commit, during persistence, after commit/before memory adoption, after adoption/before response, and after response generation/before narrative presentation. Verify both recovered state and a coherent player continuation. Test duplicate delivery while current views/choices are stale.

For reproducible injected faults, retain initial snapshot, ordered input, seed/RNG, fault schedule and artifact/toolchain identities. For abrupt process death/OOM, report the durable pre-fault diagnostic record and missing data honestly: do not promise an in-memory stack trace that may be destroyed. Diagnostic recording must not mutate gameplay semantics or leak private traces by default.

Reference: [Erlang NIF safety warning](https://www.erlang.org/doc/apps/erts/erl_nif.html). A native crash can terminate the VM; dirty schedulers do not add memory protection.

## 10. Build, debug, dependencies (MUST unless RECORD)

Clean development and production builds on both mobile platforms must pass with the exact pinned toolchains. Demonstrate source-mapped/symbolicated injected faults, kernel upgrade, save compatibility, and repeatable build steps. Candidate A must run the same package on Hermes and Node without native modules, host-only APIs, or environment-dependent polyfills inside the semantic kernel. Node/BEAM infrastructure remains host code.

For candidate B, record binding ownership, unsafe code, panic behavior, ABI/versioning and upgrade costs. An experimental generator is not accepted merely because a demo compiles; choose a maintained boundary with demonstrated builds/debugging or reject it. For C, report the actual duplicate semantic implementation and test maintenance.

Separate fast semantic CI (approved target <=30 minutes) from clean platform release builds (duration RECORD); queued CI wait time is recorded separately. Do not require a full four-host native release inside a contradictory fast-test budget. Inject one host mismatch and prove the adapter oracle catches it.

## 11. Decision report and remaining gates

For every applicable row: threshold, exact input/build/device identity, observed value, sample count, pass/fail/unmeasured, and evidence location. Hashes supplement retained canonical bytes; unknowns are not passes. Compare maintenance and fault containment as well as speed. Record why untested candidates were skipped under the A-first sufficiency rule.

R1 cannot approve R0, the production engine, a store submission, or chapter one. Store-rule representation remains ADR-035; physical product proof is R6P; full chapter and certification are R10/R12. Keep only reviewed fixtures, evidence and deliberately reusable work from the disposable spike.

## 12. Setup, implementation and acceptance are distinct

[The work package](r1-work-package.md) tracks PREP-01–03 then R1-A1–A5. Owner approval fixes this envelope's targets; it does not populate the physical inventory, approve independent expected values, complete R0 or choose A. The initial setup manifest has status `preparation_pending` and no results. Do not call a template, a Python model pass or matching headless transcripts a passing experiment.

Hash the retained exact envelope, numeric vectors/profile, composition profile/cases and admitted fixture set in an external setup bundle. Do not put the hash of a self-containing envelope into itself. Record the accepted spec commit and stage-bound A1 manifest review before building candidate semantics; native/physical identities and a new A2 setup approval precede actual-host integration. A1 requires Node, TypeScript, Elixir/full OTP and a retained reproducible execution-host/lock bundle; deferred native fields may be null. All supplied fields remain typed and included in the review digest. Candidate A starts stateless. Any retained-cache/boundary variant is declared before tuning and receives the same safety/load gates; a new variant does not get to revise expected semantics.

R1 acceptance still requires every applicable MUST result, raw retained per-step bytes, independent expected-value review, exact build/device manifests and a reviewed decision report. Failed/missing rows cannot be reclassified as N/A merely to select a favorite implementation. B/C remain unmeasured unless A/B fail in order. No PostgreSQL/Realm/production-engine or store-approval claim follows from R1.

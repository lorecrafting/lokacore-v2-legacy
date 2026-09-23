# 14 — Implementation Plan and Dependency Graph

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Governing milestone tasks and gates.

Use the plain-English R guide first. Numbers are stable labels; R6P pulls selected early slices forward and Realm does not block offline content.

<details>
<summary>Sections in this document</summary>

- [R0 — Specification acceptance](#r0--specification-acceptance)
- [R1 — Disposable portable-kernel feasibility spike](#r1--disposable-portable-kernel-feasibility-spike)
- [R2 — Fresh repository foundation](#r2--fresh-repository-foundation)
- [R3 — Contract/schema foundation](#r3--contractschema-foundation)
- [R4 — Cartridge compiler v1](#r4--cartridge-compiler-v1)
- [R5 — Portable world rules foundation](#r5--portable-world-rules-foundation)
- [R6 — Offline authority and save system](#r6--offline-authority-and-save-system)
- [R6P — Early fresh-engine playable proof](#r6p--early-fresh-engine-playable-proof)
- [R7 — Quest, dialogue, and scenes](#r7--quest-dialogue-and-scenes)
- [R8 — Living-world capability pack](#r8--living-world-capability-pack)
- [R9 — Cartridge Lab v1](#r9--cartridge-lab-v1)
- [R9C — Synthetic V3 Conformance Cartridge](#r9c--synthetic-v3-conformance-cartridge)
- [R10 — First real offline cartridge](#r10--first-real-offline-cartridge)
- [R11 — Builder API v1 and script-surface generalization](#r11--builder-api-v1-and-script-surface-generalization)
- [R12 — Loka app: production Story Mode](#r12--loka-app-production-story-mode)
- [R13 — Commerce and entitlement](#r13--commerce-and-entitlement)
- [R14 — BEAM online authority + Realm Mode skeleton](#r14--beam-online-authority--realm-mode-skeleton)
- [R15 — Online-private deployment](#r15--online-private-deployment)
- [R16 — Repeatable AI factory](#r16--repeatable-ai-factory)
- [R17 — Party/co-op instances](#r17--partyco-op-instances)
- [R18 — Realm Mode persistent social shell](#r18--realm-mode-persistent-social-shell)
- [R19 — Instanced story regions in world geography](#r19--instanced-story-regions-in-world-geography)
- [R20 — Shared zone/shard architecture](#r20--shared-zoneshard-architecture)
- [R21 — Shared-area promotion](#r21--shared-area-promotion)
- [R22 — Persistent text MMORPG expansion](#r22--persistent-text-mmorpg-expansion)
- [Dependency graph](#dependency-graph)
- [Issue sizing rule](#issue-sizing-rule)
- [Agent workflow](#agent-workflow)
- [Sizing](#sizing)
- [Shipping rule](#shipping-rule)
- [Readiness amendment implementation notes](#readiness-amendment-implementation-notes)

</details>
<!-- packet-navigation:end -->

**Status:** draft sequencing derived from v3 architecture.  
**Rule:** no fresh implementation repository should begin substantive engine work until this packet is accepted and Phase R0 is complete.

The full first release remains chapter one: **57 rooms, 10 quests, two endings**. LLM-assisted authoring and reasoning are part of the plan. A separate small **R6P playable proof** tests the from-scratch engine before that release; it is not a reduced chapter or a legacy-engine migration.

[Plain-English milestone guide](R-MILESTONES.md) · [Human/LLM review guide](REVIEW-GUIDE.md). Phase numbers are stable identifiers, not a completion checklist or a strict sequence. R3A/R3B are parts of R3; R12A is part of R12; R6P/R9C are additional named milestones.

[release-scope.md](release-scope.md), generated from the reviewed [release-scope.json](release-scope.json), makes the chapter/proof capability and gate applicability explicit. Detailed catalogs remain design material; a later feature in a phase's catalog is NOT a prerequisite for an earlier release. Applicable safety gates cannot be waived. R0/R1 acceptance and R2 specification cutover remain required before production engine work.

## R0 — Specification acceptance

### Objective

Turn this packet from draft into an implementation contract.

### Tasks

- complete broad Lokacore archaeology;
- complete Evennia review;
- reconcile offline requirements;
- self-review every spec section for contradictions;
- adversarial architecture review;
- correct findings;
- identify unresolved ADRs;
- explicitly accept/reject working decisions.

### Required outputs

- accepted spec commit hash;
- decision register;
- known deferred questions;
- implementation ticket dependency graph.
- specification cutover manifest naming the accepted normative file set + commit hash and the post-R0 amendment authority;
- a compact implementation-facing architecture/invariant index derived from the accepted packet.

### Gate R0

No unresolved contradiction about:

- definition/runtime identity;
- offline execution;
- online authority;
- ActionInvocation/Command/StateDelta/DomainEvent/Effect/GameView model;
- persistence transaction semantics;
- retry/idempotency semantics across reconnect and authority ownership movement;
- durable cross-authority effect redelivery/reconciliation semantics;
- scripting boundary;
- mobile Story session/GameView boundary and the fact that Realm transport is intentionally deferred;
- cartridge versioning.
- specification source-of-truth/cutover rules once the fresh implementation repository exists.

### Readiness closure and authorization boundaries

Owner approval on 2026-09-22 adopts ADR-064–067's recommendations for this amendment. It does not substitute for the accepted R0 commit/cutover record, genuinely independent review, actual setup or measured R1 results. The preparation work may proceed now; substantive candidate semantics require the frozen reviewed A1 setup/contract below. The 2026-09-23 owner-approved sequencing amendment defers complete native/physical setup to A2; it does not grant R0 or candidate acceptance. Production still waits for R0/R1/R2.

| Work item | Dependencies | Deliverable / stop condition |
|---|---|---|
| PREP-01 Contract closure | Review this amendment | 04 initial order/conflict/budget contracts; 05/06 operation/objective/continuation rules; 10/23 run defaults; preserved Tiny oracle; both Lantern traces and adverse cases. Record remaining independent review, do not label self-review independent. |
| PREP-02 Setup and oracle freeze | PREP-01, R0 acceptance record | Two stage-specific freezes using existing records: A1 requires accepted contract, exact seven inputs, independent oracle review and reproducible reviewed Node/TypeScript/Elixir/full-OTP host/lock evidence; A2 adds complete native locks, physical qualification inventory and approved common host. `--require-ready --stage A1` is semantic-only; default/explicit `--stage A2` stays full-native. No synthetic acceptance or inventory. |
| PREP-03 Download representation review | PREP-01; parallel with setup/R1 | Exact permitted payload/capability surface, sample package and policy review notes, unresolved risks, owner disposition before production content scaling; final store gate remains 10 §27. |
| R1-A1 Semantic candidate | PREP-02 A1 freeze | One TypeScript package, stateless prepared definitions, Tiny/per-step known answers and bounded composition fixtures. No production compiler. |
| R1-A2 Actual host adapters | R1-A1, PREP-02 A2 freeze | Hermes physical iOS/Android and isolated Node/BEAM Port; actual SQLite commit, recovery and byte parity. |
| R1-A3 Fault/load evidence | R1-A2 | Full envelope, synthetic generators, worker death, scheduler interference, backlog/overload and mobile interruption/response tests. |
| R1-A4 Reviewed selection | R1-A3 | Retained raw evidence, exact manifests, limits/failures and ADR-004/005 disposition. Passing A stops comparison; failure authorizes B then C with the same contract. |
| R1-A5 Production handoff | R1-A4, R0, PREP-03 investment disposition | R2 sole-source cutover, selected architecture, retained fixtures; deliberately reimplement production rather than carry accidental spike scaffolding. |

The detailed runnable handoff is [r1-work-package.md](r1-work-package.md). It is subordinate to this plan and the envelope. New document headings do not create new top-level R IDs. R3A freezes constitutional schemas; R3B/feature schemas still wait for implementation evidence at the relevant slices.

## R1 — Disposable portable-kernel feasibility spike

### Objective

Prove the hardest new architectural decision before investing in the rebuild.

R1 SHOULD live in a disposable spike repository/workspace, not as compatibility code inside Lokacore and not as the foundation of the production v3 repository. Keep only evidence, benchmarks, fixtures, and code worth deliberately re-implementing after the decision.

### Acceptance envelope is frozen before the spike

R1 is a decision experiment, so its success criteria MUST be recorded **before** implementation results are known.

Create a versioned R1 acceptance-envelope artifact that fixes at least:

- representative tiny, medium, and deliberately stressful portable-state sizes;
- representative command mixes and decision/output sizes;
- supported development and minimum physical-device classes for iOS/Android;
- serialization/FFI bytes copied or retained per decision strategy;
- command latency targets/limits (including p50/p95/p99 where meaningful);
- maximum acceptable normal-NIF scheduler occupancy/latency impact if Rustler is tested;
- snapshot/save round-trip size and latency envelopes;
- memory-growth/leak expectations over long command runs;
- crash/fault containment and recovery expectations for native failures;
- Expo/EAS build, local debugging, symbolication/crash-reporting, upgrade, and CI maintenance criteria;
- third-party binding/toolchain dependency risk that would count as unacceptable operational fragility;
- the comparison procedure against the dual-implementation fallback.

The exact numeric thresholds are an R1 planning artifact rather than permanent architecture prose, but they must be committed/reviewed before the benchmark implementation is tuned. Do not redefine "acceptable" after seeing the result merely to preserve a favored technology choice.

R1 evidence reports both the measured result and the pre-registered threshold.

### Candidates

R1 compares three strategies against the pre-registered envelope. None is selected here. R1A uses Tiny semantics/prepared definitions; R1B uses synthetic volume and bounded chain/scene cases, NOT the whole chapter. C is tested first, then B, then A (ADR-068); this is a first-sufficient experiment, not a ranking of unmeasured candidates. Language and host boundary are separate decisions, including an explicitly evaluated isolated Rust-worker variant if needed.

**A. One TypeScript kernel.** The portable rules are one TypeScript package. React Native runs it natively in its JavaScript engine with no FFI, no native module, and no binding generator. BEAM reaches it through an Erlang Port to a Node process, or an equivalent isolated runner, with JSON or a binary codec across the boundary. Determinism requires integer arithmetic for rule-critical math, `Map` and canonical key ordering rather than object-key order, and a seeded PRNG. Costs: a Node process in the server deployment and per-decision serialization, which is the same state-crossing cost strategy B must benchmark.

**B. One Rust kernel.** One deterministic Rust library behind a pre-registered BEAM boundary (Rustler NIF or isolated worker), an iOS React Native native binding, and an Android React Native native binding. Strongest type system and no runtime dependency inside the kernel; highest build, binding, and debugging cost across four hosts.

**C. Dual implementation.** Pure Elixir online plus TypeScript offline, held to one semantic schema, the golden-vector suite and randomized differential testing. No cross-language boundary on either host and a single Elixir/OTP server runtime; permanent two-implementation maintenance and semantic-drift cost.

The chapter-one mechanics in `00-first-cartridge-design.md` §11 are almost entirely derived state and pure reducers, which keeps a second implementation small and should be the spike's representative workload.

### Tiny model

Definitions:

- 2 rooms;
- 1 exit;
- 1 NPC;
- 1 item;
- 1 player;
- 1 typed fact;
- 1 quest;
- 1 scheduled job;
- 1 RNG check.

Commands:

- inspect;
- move;
- take;
- talk/choose;
- wait/advance time.

### Prove

- canonical serialization and independently reviewed RNG/numeric vectors;
- per-step state/decision/event/RNG bytes and exact trace parity;
- snapshot round-trip;
- deterministic RNG;
- same errors;
- build automation on all hosts;
- boundary overhead/copy behavior at synthetic representative state sizes; later full-chapter validation checks representativeness;
- receipt-before-current-world-validation and safe decide → persist → apply-delta, including uncertain COMMIT;
- deterministic IDs/map ordering/numeric behavior;
- no BEAM scheduler starvation.

### Rejection criteria

Reject a shared-kernel candidate (A or B) if:

- iOS/Android build/release maintenance is unreasonably fragile;
- deterministic representation cannot be stabilized;
- binding overhead dominates realistic command latency;
- debugging across host boundaries is materially worse than dual implementation;
- Expo distribution workflow becomes unacceptable.

### Fallback

Pure Elixir online + TypeScript offline implementations with one semantic schema/golden-vector suite.

Fallback requires explicit acceptance of ongoing dual-implementation cost.

### Gate R1

Architecture Decision Record selects portable execution strategy.

## R2 — Fresh repository foundation

### Objective

Create a clean repository with enforced boundaries and CI.

Suggested shape:

```text
apps/loka_core
apps/loka_content
apps/loka_store
apps/loka_platform
apps/loka_runtime
apps/loka_builder
apps/loka_web
portable/                 # shared portable implementation only if selected by R1
mobile/app
mobile/features/story
mobile/features/realm
mobile/authority/local-story
mobile/authority/remote-realm
mobile/packages/ui
mobile/packages/game-view
protocol/
cartridges/
docs/
```

### Tasks

- Mix umbrella;
- strict compile/dependency boundaries;
- Rust workspace if accepted;
- one minimal Expo app with strict Story/Realm feature and authority-module boundaries, plus shared UI/GameView packages;
- formatter/lint/security configs;
- one unified CI;
- generated-schema drift check;
- ADR directory;
- AGENTS/task routing docs;
- minimal release/dev tooling;
- import the exact R0-accepted normative specification/ADRs into the fresh repository as implementation authority;
- physically separate normative implementation docs from historical archaeology/review/research evidence so agents do not treat every old Lokacore document as peer authority.

### Gate R2

Empty-system CI is green on:

- Elixir;
- TypeScript;
- the R1-selected portable execution implementation;
- the R1-selected iOS/Android integration path;
- mobile portability/binding smoke appropriate to that choice.

If R1 rejects Rust/native bindings, R2 MUST NOT keep Rust-specific gates merely because they appeared in the original hypothesis.

After this cutover, future architecture amendments happen in the fresh implementation repository through its spec/ADR process. The Lokacore v3 packet remains provenance/reference evidence and MUST NOT become a second independently evolving normative specification.

## R3 — Contract/schema foundation

### Objective

Make the irreducible machine-readable contracts exist before features **without prematurely freezing every higher-level feature schema before real implementation/content evidence exists**.

R3 has two layers.

### R3A — Constitutional contracts

These are foundational enough that later features must build on them rather than reinterpret them:

- DefinitionRef and runtime-identity contracts;
- cartridge/deployment/campaign manifest schemas and version envelopes;
- capability registry + exact capability-lock format + semantic residency reporting;
- StateScope/AudiencePolicy plus distinct logical-world and mutation-authority placement identities;
- Action/ActionInvocation registry/schema;
- portable semantic Command registry;
- StateDelta algebra, including canonical mutation-target identity, preconditions, proposal-overlay semantics, deterministic ordering, conflict/composition rules, and canonical serialization;
- DomainEvent registry plus proposed-before-commit versus committed-observable semantics;
- Effect registry and durability/idempotency classifications;
- core policy AST/versioning;
- deterministic TargetResolution result contract (`none | unique | ambiguous`) even if richer selector vocabulary arrives later;
- typed relation/provenance foundation;
- FactSpec / scoped narrative-state foundation;
- portable GameView envelope/freshness contract;
- portable-rules ABI/serialization contract selected by R1;
- canonical serialization/hash/IdSource/RNG/numeric rules;
- diagnostic/error registry;
- account/run binding, Story milestone reports/acceptances and admission requirement envelopes (document 23), separate from gameplay StateScope.

### R3B — Versioned feature envelopes

R3 also reserves machine-readable kind/version/reference/registration envelopes for later composition systems so R4–R6 do not invent incompatible shapes. However, exact production field vocabularies SHOULD be finalized in the phase that first implements/exercises the feature.

Initial envelopes include:

- ActionRecipe/ComposedAction;
- InspectableDetail/description variants;
- Connection/Barrier;
- ReactionRule;
- consequence-operator registry;
- NarrationSpec;
- SceneDefinition/SceneInstance/SceneSpace;
- InstancePlan including explicit closure/import/export policy;
- SpawnBundle/PopulationPlan;
- commerce provider/policy composition;
- Service/Capacity/ServiceJob composition envelope;
- WorldEventPlan.

R5 freezes the v1 ActionRecipe/InspectableDetail/Connection/Barrier and other foundation-world shapes before portable world rules depend on them. R7 freezes each narrative/Scene/consequence shape before its first dependent artifact; InstancePlan freezes when actually pulled. R8 likewise freezes each living-world/population/commerce/service/world-event feature with its first use, not wholesale before chapter one.

This does **not** permit runtime ambiguity. A feature may not ship/use an unstable anonymous map merely because its detailed schema was deferred. It means the final versioned schema is frozen when implementation evidence exists, instead of guessing every field at R3 and carrying accidental compatibility forever.

### Gate R3

From the constitutional registries and currently frozen feature schemas, tooling can generate/check:

- Elixir portable/domain types and validators;
- TypeScript ActionInvocation/GameView/content types used by Story Mode, plus authority-internal semantic Command types only where the local authority adapter needs them;
- capability/schema docs and help excerpts;
- canonical test fixtures;
- a machine-readable capability/residency matrix.

The R3 fixture suite proves StateDelta conflict/composition behavior and that proposed DomainEvents cannot escape before a failed commit.

No handwritten duplicate portable command/event/GameView catalogs.

R3 intentionally does **not** generate Builder/MCP operations or the Realm network protocol. Those contracts are introduced only when R11 and R14 need them.

Do **not** build the generalized Builder operation registry or the full Realm transport protocol in R3. Builder operation schemas belong to R11; Realm protocol/codegen belongs to R14.

## R4 — Cartridge compiler v1

### Objective

Compile a tiny cartridge into an immutable artifact.

### Build

- source loader;
- schema validation;
- namespaces;
- local reference resolver;
- template/mixin expansion;
- capability validation;
- policy compile;
- asset manifest;
- canonical serialization;
- artifact hash;
- structured diagnostics.

### Gate R4

Compile same source twice → identical artifact hash.

Broken references/cycles/unknown capabilities fail deterministically.

## R5 — Portable world rules foundation

### Objective

Establish world/state mechanics needed by everything else.

### Implement portable capabilities

- world state;
- definitions → runtime entities;
- containment/location;
- room/place + coherent Connection/Barrier;
- typed relations/provenance;
- InspectableDetail + conditional descriptions;
- TargetSpec/Search inputs/IDs + deterministic none/unique/ambiguous resolution;
- typed facts and explicitly scoped runtime state;
- logical clock;
- RNG;
- policies;
- ActionSet algebra;
- minimal ActionRecipe/ComposedAction execution over registered consequences;
- inspect/look;
- move;
- take/drop/give;
- simple resources/checks.

### Properties

- one container per item;
- no impossible location cycles;
- deterministic commands;
- unknown capabilities fail;
- ActionSet stable ordering;
- command result bounded.

### Gate R5

Golden vectors pass through the R1-selected portable-rules implementation(s) and every accepted authoritative host path.

## R6 — Offline authority and save system

### Objective

Make a tiny world fully playable offline.

### Build

- LocalInstanceAuthority;
- serialized command queue;
- local SQLite adapter;
- command receipts;
- snapshots;
- save slots;
- app kill/recovery;
- play-time/real-elapsed reconciliation;
- installed cartridge manager;
- durable Story milestone + pending-report capture with local game commit; persistent account/profile binding outside portable hashes; fake synchronization adapter for R6P.

### Gate R6

Airplane mode:

- start new tiny cartridge;
- play;
- kill app during actions;
- resume;
- finish;
- no state corruption.

## R6P — Early fresh-engine playable proof

Implement [pre-release-proof.md](pre-release-proof.md) using the minimum R3–R6 foundation and the selected early R7/R8 slices. R6P does **not** depend on the entirety of R7/R8 or R9; minimal conformance and fault checks accompany each slice from the start. The phase numbers group capabilities, not a mandate to build each group wholesale before feedback.

Gate: a coherent four-place experience with real prose, a consequential choice, a schedule, touch input, atomic local saves, retry/restart safety and device evidence. Keep the resulting regression corpus green as the full chapter is built. A Python contract-model pass is not this gate. No production v3 code is added to legacy Lokacore.

## R7 — Quest, dialogue, and scenes

### Objective

Support real narrative cartridges.

### Build by release applicability

Chapter one includes quest operators actually used by `00a` (including escort and survive), dialogue, current-world scenes and a scoped-overlay dream. InstancePlan, ghost-walk, spell combinations, stances and other later mechanics are catalog entries below, NOT chapter-one dependencies unless a reviewed content amendment pulls them. Freeze each feature schema with its first exercised slice.

- StateMachine primitive;
- QuestInstance;
- quest graph operators;
- quest reducer;
- active-quest event indexing plus automatic/discovered activation indexing;
- typed quest outcome/consequence grammar;
- FactSpec reads/writes with scope validation;
- capability consequence evaluators returning StateDelta/events/effects;
- idempotent rewards/consequences;
- dialogue graph;
- dialogue conditions/actions;
- NarrationSpec;
- SceneDefinition + durable SceneInstance reducer;
- SceneSpace semantics;
- minimal portable InstancePlan for precompiled room-subgraph/private Story spaces under LocalInstanceAuthority, including entry/exit, reconnect/save, teardown and explicit exports;
- text-cutscene beats, choices, checkpoints, and action-control modes;
- player-scoped dream/vision compositions over current-world, overlay, or InstancePlan space with explicit exported consequences;
- quest milestone/scene hooks and scene outcome objectives;
- event-chain bounds;
- branch/world-consequence trace output;
- the R7-phase capabilities pulled by `00-first-cartridge-design.md` §12 and registered in document 21 §28: positions, stances, learn-by-doing skills, spell-word combination, collection log, adjacent-room targeting, ghost-mode death, pose, and the protect/survive/race objective operators.

### Gate R7

Known Lokacore quest-bug class has a regression scenario that cannot reproduce corruption/premature completion.

For chapter one, a quest drives a durable SceneSequence with narration, authoritative choice, crash/reconnect checkpoint, and once-only consequences; its dream proves scoped-overlay isolation and resume. A minimal InstancePlan has its own entry/export/teardown/recovery gate when that feature is first pulled. It is not required just to render the chapter-one overlay dream.

LokaScript is **not** part of R7. No chapter of `00-first-cartridge-design.md` requires it; ADR-018 is deferred until a real cartridge presents a mechanic that ActionRecipe, ReactionRule, Policy, and quest operators cannot express, at which point it is admitted through a CapabilityProposal and its own phase.

## R8 — Living-world capability pack

### Objective

Make the world feel like a MUD, not a branching ebook.

### Build by release applicability

Chapter one requires schedules, behaviors, populations, reactions, day/night, tides, light, topics, immediate shop/inn/ferry transactions and the other features in the generated matrix. It does not require ServiceJob queues/escrow, WorldEventPlan, weather, mounts, crime, property, or mail. The full catalog below is phased by the release matrix and doc 00; do not implement it all before R10.

- typed ReactionRule evaluation;
- NPC role/state profiles;
- deterministic Behavior intent/arbitration contract;
- schedule;
- patrol;
- wander;
- guard/flee/assist/scavenge behavior primitives as demanded by the conformance cartridge;
- ambient emitter;
- shop hours;
- nocturnal/activity windows;
- AreaDefinition authoring grouping distinct from ZoneShard placement;
- SpawnBundle + provenance-safe PopulationPlan;
- spawn/despawn/cleanup policy;
- day/night;
- basic weather;
- fact-driven room/ambient variants;
- fact-driven access/topology policies;
- on-demand temporal state;
- durable local jobs;
- typed commerce/merchant contract: provider, catalog/stock, price/payment, buy/sell admission, liquidity, restock, schedule, atomic immediate trade;
- portable Service/Capacity composition primitives;
- durable local ServiceJob model sufficient to prove queued/timed services;
- WorldEventPlan phase composition sufficient for the first cartridge's scripted living-world events;
- the R8-phase capabilities pulled by `00-first-cartridge-design.md` §12 and registered in document 21 §28: tides, mounts, sense propagation, cursed items, liquids, readables, identify, pets, mob memory/hunt, barter, property, steal, law (crime/witness/wanted/arrest/jail), mail, drives, discovered topics, disguise/recognition, NPC-to-NPC commerce, track, and performance.

### Gate R8

30 simulated days for chapter-one scheduled work, populations and reactions. Additionally test each implemented transaction family:

- service queues/jobs remain bounded and deterministic **when ServiceJob is implemented**;
- escrowed inputs/outputs conserve ownership **when escrow is implemented**;
- merchant stock/payment conservation holds under retries/concurrency;
- no schedule deadlocks;
- Behavior conflict arbitration is deterministic;
- PopulationPlan counts remain bounded and provenance-safe;
- no runaway population;
- bounded jobs;
- required NPCs available per intended design;
- ReactionRule/event chains remain bounded;
- deterministic replay.

## R9 — Cartridge Lab v1

### Objective

Make failures reproducible before content scale.

### Build minimum first

Document 09 §1a and the generated release matrix select the first-release gates. The list below also contains later Lab capabilities: bounded exploration, mutation sensitivity, generalized CoverageManifest and model-proposed scenario import are not chapter-one prerequisites. Small known-answer/fault tests accompany R3 onward; R9 packages them into repeatable certification rather than postponing testing until R9.

- virtual clock;
- seed/RNG controls;
- snapshots/forks;
- branch outcome fork/compare;
- quest world-impact/consequence graph;
- scene/dream/cutscene trace + crash/retry replay;
- target-resolution/provenance/behavior/population/price explanation traces;
- trace viewer data;
- static validator + topology/quest/scene/reaction model-analysis gates;
- CoverageManifest generation;
- bounded state/path/seed exploration;
- reusable capability invariant registry;
- property/fuzz tests;
- mutation-sensitivity fixtures for high-risk gates;
- deterministic bots;
- autonomous simulation;
- adversarial scenario import/generation interface;
- fault injection for local authority;
- cross-host differential/conformance runner;
- semantic-review evidence bundle support;
- content-addressed CertificationEvidenceBundle + repro export.

### Gate R9

For chapter one, every deliberately injected applicable failure yields a retained reproducible scenario. The static/quest/world, per-step determinism, receipt/commit faults, branch/scene coverage and human-smoke obligations of document 09 §1a pass. Export exact artifact/fixture/toolchain identity with the evidence.

Later features add bounded exploration, mutation sensitivity, mounted analysis and other gates when applicable; they are not required merely because they appear in this catalog. A model-proposed attack counts only after deterministic execution against an admitted invariant.

## R9C — Synthetic V3 Conformance Cartridge

### Objective

Create a small permanent **architecture/conformance cartridge** whose job is to stress the engine and Lab, not to be a commercially coherent story.

This separates two different optimization targets:

- the conformance cartridge is intentionally adversarial, compact, and mechanically broad;
- R10 is intentionally player-facing, coherent, and allowed to use only the mechanics its fiction needs.

### Build

The conformance cartridge SHOULD exercise the currently implemented portable foundation. It MUST NOT pull an unneeded future engine feature just to fill a checklist. Only applicable implemented interactions below are required at a given release:

- deterministic text/touch target ambiguity and resolution;
- containment/inventory transfer and retry/crash boundaries;
- coherent bidirectional Barrier state;
- scoped Facts + ReactionRule chains;
- branching Quest outcomes and exactly-once typed consequences;
- SceneSequence crash/reconnect/choice semantics;
- SceneSpace overlay plus minimal InstancePlan entry/export/teardown;
- a LokaScript budget/containment case only if ADR-018 has been admitted by then;
- Behavior intent conflict/arbitration;
- SpawnBundle + provenance-safe PopulationPlan;
- merchant/Commerce conservation;
- ServiceJob queue/escrow/time completion where implemented;
- WorldEventPlan phase/reaction composition;
- logical-time/RNG boundary cases;
- intentionally injectable defects for invariant/mutation-sensitivity checks.

It does not need polished prose, art, catalog metadata, monetization, or a natural narrative reason for every mechanic. Synthetic rooms/entities may exist solely to prove contracts.

Each covered semantic surface SHOULD have small deterministic scenarios and, where useful, a known-bad mutation/fault fixture demonstrating that the intended gate catches the defect.

### Gate R9C

The synthetic cartridge passes its applicable `offline_private` semantic/conformance certification, the currently available R1-selected portable/mobile/host-adapter conformance fixtures, crash/retry cases, and coverage accounting. R9C does not require the production Realm authority that is introduced at R14; once R14 exists, the same cartridge becomes a standing offline-versus-BEAM differential fixture.

A future engine/capability change that breaks a previously proved foundational interaction should fail this cartridge quickly enough to serve as a permanent architecture regression corpus.

The conformance cartridge is **not** evidence that the product is fun, understandable, or commercially shippable. That is R10/R12 work.

## R10 — First real offline cartridge

**Sequencing rule:** prove authoring requirements with a real cartridge before completing the generalized Builder API. Minimal scripts/CLI helpers are allowed, but do not let tooling delay product proof.

### Objective

Prove the **player-facing product and authoring model**, complementing rather than duplicating the synthetic R9C conformance cartridge.

Target scope is **chapter one** of `00-first-cartridge-design.md` (The Fox of Ashmere, §11): 57 places, the Ashmere/Fen/Priory areas, ten quests, two endings, and the chapter-one column of its mechanics table. The full 109-place, 28-quest design is the destination reached by chapters two and three, which are the R16 cartridges. Document 00 §11 is the pull list for R5–R8; its §12 names the capabilities the catalog must add (registered in `21-composable-world-primitives.md` §28), each built in the chapter that first needs it.

The ladder is deliberate: chapter one is the free showcase and proves the foundation plus the cheap derived-state mechanics; chapter two adds the dungeon, magic, death, and companions; chapter three adds economy, crafting, crime, housing, and mounts. R9C still owns synthetic fault/invariant coverage; R10 owns coherence and authoring evidence.

### Important

Hand-author substantial portions first. Do not immediately ask the factory to mass-generate.

R10 exists to answer questions R9C cannot:

- are the primitives pleasant enough to author a coherent game?
- does the composition grammar encourage understandable world design rather than ceremony?
- which operations are repetitive/error-prone enough to deserve Builder verbs?
- which nominally elegant primitive boundaries repeatedly confuse skilled authors/agents?
- does the resulting world feel like a living narrative game rather than a technology demo?

The cartridge MUST still prove that quests and living-world systems interact through typed facts/consequences rather than cartridge-specific hidden mutation scripts.

### Gate R10

Full applicable `offline_private` certification plus a **developer-harness physical-device smoke** using the minimal Expo/native integration established by R1/R2/R6. Polished non-developer product-shell acceptance belongs to R12.

Its two intended endings emit the declared durable `prologue_completed` milestone after the final dawn consequence. Local pending-report capture is part of crash/retry evidence; the public account service is R12A.

The cartridge should be authored primarily through source files/compiler/Lab at this stage. Record every repetitive, confusing, or error-prone authoring operation as evidence for the Builder API rather than prematurely generalizing it.

## R11 — Builder API v1 and script-surface generalization

Here, “script-surface generalization” means the demonstrated typed authoring/composition surface. It does not re-admit deferred LokaScript (ADR-018).

### Objective

Let humans/agents author without raw repo semantics.

### Build

- Builder API operation registry/schema generation;
- workspace/revision;
- capability search/describe;
- content CRUD;
- reference graph;
- compile/validate;
- Lab control;
- batch/dry-run;
- semantic rename;
- audit/idempotency receipts for retry-safe mutations;
- terminal adapter;
- MCP adapter;
- semantic intent-level operations for demonstrated needs such as topology.connect, detail.add, reaction.add, population.add, merchant.configure, scene.create, quest.attach_scene, and world_event.create;
- explainability operations for target resolution, behavior, population, prices, scenes, quest progress, and world-event phase;
- machine-readable role/surface metadata sufficient for an orchestrator to distinguish L3–L6 builders, read-only reviewers and engine-capability escalation;
- typed MISSING_CAPABILITY / CapabilityProposal result path;
- expand ActionRecipe/ReactionRule vocabulary only from concrete R9C conformance gaps, R10 authoring needs, and accepted reusable capability gaps; a demonstrated gap that no composition can close becomes the evidence for admitting ADR-018.

### Gate R11

Astra/another agent can recreate or extend representative R10 product content using only Builder API tools, can manipulate the relevant R9C conformance fixtures through typed Lab/Builder surfaces, and can fix intentionally injected validation failures without shell/Git editing.

## R12 — Loka app: production Story Mode

Can overlap late R10. R12A may start in parallel with R6/content work; it is required before the first public Story release, not before the disposable kernel experiment or R6P.

### R12A — Launch accounts and Story progress

Build the minimal `loka_platform` service and PostgreSQL dev/test/runtime infrastructure for account creation/sign-in, recovery/deletion, authenticated run binding and milestone submission/readback, evidence-labeled acceptance and administrative last-reported progress. Persist local pending reports at R6; implement the real adapter here.

Gate: real-service tests cover offline completion followed by reconnect, duplicate/lost acknowledgements, multi-device non-regression, account switching/guest claiming if supported, account deletion versus in-flight submissions, and new-device progress readback without pretending to restore a full save. Both chapter-one endings qualify. Actual authentication/storage/mobile evidence is required by [document 23](23-accounts-progress-admission.md), not just Python model tests.

### Build

- production app navigation with Story Mode as the shipped gameplay mode;
- shared UI/GameView package extraction only where demonstrated useful;
- catalog shell;
- cartridge install/delete/update;
- save slots;
- generated/validated portable-rules integration or native bindings selected by R1;
- living-book/touch UI refined from old design;
- accessibility;
- settings;
- offline status.

### Gate R12

Non-developer can install the polished build, enter airplane mode, play/finish the free cartridge, resume after app/device restart, and use production cartridge/save UX without developer tooling. R12A also passes: the player can sign in, finish offline, synchronize the completion and read it on the account. Expired credentials/service outages do not block installed gameplay. The first free public release includes accounts/progress; R13 is not required until paid commerce.

## R13 — Commerce and entitlement

### Build

- extend the PostgreSQL and account/progress foundation delivered at R12A;
- add catalog/entitlement/purchase services within `loka_platform`;
- catalog service;
- canonical entitlement;
- Apple/Google product mapping;
- purchase verification;
- signed offline entitlement grant;
- restore;
- download integrity;
- refund/reconnect reconciliation.

### Gate R13

Store sandbox tests on iOS/Android:

- purchase;
- download;
- airplane mode;
- reinstall/restore;
- second device;
- refund/reconnect policy.

## R14 — BEAM online authority + Realm Mode skeleton

### Objective

Run the same cartridge rules online under OTP.

### Build

- Session→existing R12A Account→Character;
- server-side onboarding admission from accepted prologue milestones under versioned deployment policy, never a client flag or save import (document 23);
- InstanceRegistry/Supervisor;
- WorldInstance;
- R1-selected portable-rules adapter/implementation;
- PostgreSQL store;
- transactional command commit;
- command receipts with semantic-command digests and replayable prior results;
- authority ownership/fencing generations for stale-owner protection;
- effect outbox;
- snapshots;
- projection stream sequencing and opaque view-freshness tokens;
- machine-readable Realm transport protocol + Elixir/TypeScript codegen and compatibility fixtures;
- Phoenix typed protocol adapter;
- Realm Mode route/session driver inside the existing Loka app using that protocol;
- reconnect/resync;
- observability.

### Gate R14

Same cartridge golden playthrough matches offline domain trace where host-specific effects are excluded.

Chaos tests around every commit boundary pass. Where the deployment requires prologues, entry and re-entry enforce current account/progress/policy state on the server; duplicate reports, stale client unlock caches and withdrawn evidence cannot bypass admission.

## R15 — Online-private deployment

### Objective

Offer same story as cloud-authoritative run.

### Build

- deployment selection;
- online saves;
- reuse the R12A account identity and server-side prologue requirements for admission;
- online cartridge catalog launch;
- optional online-authoritative achievements.

### Gate R15

Within the same Loka app, the player can choose local Story execution or a connected Realm/private deployment of the same portable cartridge where offered; narrative/rules match.

## R16 — Repeatable AI factory

LLMs may assist content creation, test proposals and review earlier. R16 certifies that heavy automation is repeatable; it is not permission to use an LLM for the first time. Its prerequisites are R11 and demonstrated Story authoring/certification, NOT R14/R15 Realm production.

### Build

- Loka project workflow RoleSpecs/templates for architect/builder/reviewer responsibilities
  where an orchestrator is used; these are not hard-coded Foundry kernel roles;
- context retrieval;
- semantic review;
- automated correction;
- primitive proposal;
- release-candidate packaging.

### Gate R16

Chapters two and three of `00-first-cartridge-design.md` §11 demonstrate campaign continuity and planned capability growth, with separately reviewed engine work before content depends on it. Also build a small unrelated cartridge using the already-proved capability set to test reuse without Ashmere-specific assumptions. Record engine changes, authoring/correction effort and escaped defects, not only generated room count. No unreviewed engine patch may be disguised as a content-only success.

## R17 — Party/co-op instances

### Build

- party model;
- party-scoped quest state;
- party membership/progress/reward policy modes;
- party AudiencePolicy overlays;
- concurrent command handling;
- join/leave/reconnect;
- loot ownership;
- cooperative dialogue/decision policy.

### Gate R17

Full party certification including race/fault tests.

## R18 — Realm Mode persistent social shell

### Boundary

R18 introduces the **minimum single-node shared-hub authority** needed to prove shared presence, overlays, social UX, and scarce-service contention. It does not yet authorize generalized multi-zone partitioning or cross-shard handoff.

The implementation may use one `ZoneShard`-shaped owner for this hub if that is the accepted ownership abstraction, but R20 owns the step from one shared authority domain to a partitioned Realm.

### Build selectively

- single shared-hub/zone player/party overlay projection;
- lazy materialization/cleanup of phased quest actors;
- shared NPC with player-specific dialogue/relationship projections;
- Realm Service/Capacity primitives and durable ServiceJobs;
- online profiles;
- friends;
- presence;
- shared hub;
- chat;
- party discovery;
- achievements/history;
- cartridge portal/quest board.

### Gate R18

Offline cartridges remain independent; same packs can launch from shared hub as private/party adventures. Personal overlays do not leak to unrelated players, and a shared service contention test proves one scarce slot cannot be double-allocated.

## R19 — Instanced story regions in world geography

R19 does **not** invent a second instance model. It integrates the portable/private
InstancePlan semantics already proved for Story Mode with shared Realm geography and
WorldInstance handoff.

### Build

- physical entrance/mount points;
- handoff from realm to private/party WorldInstance;
- return state;
- party admission;
- instance lifecycle.

### Gate R19

MMO player walks from shared town into a previously released storypack without rewriting cartridge content.

## R20 — Shared zone/shard architecture

### Objective

Generalize the R18 single shared-hub authority into multiple explicit ownership domains with recoverable handoff and load/backpressure behavior.

### Build

- RealmCoordinator;
- ZoneShard;
- owner registry;
- shard state;
- cross-shard handoff protocol;
- migration-stable command receipt/idempotency routing across ownership handoff;
- shared durable jobs;
- realm services;
- load/backpressure.

### Gate R20

Synthetic multi-zone concurrency/load + crash/fencing/handoff certification. Cross-zone player/party scoped state placement/routing must be explicitly resolved here rather than inferred from StateScope. A command that commits immediately before ownership moves and then loses its acknowledgement MUST replay from the original receipt after handoff rather than execute again under the destination owner.

## R21 — Shared-area promotion

Select one prior cartridge whose fiction suits a shared area.

### Build

- shared deployment overlay;
- respawn policies;
- economy policy;
- personal/shared quest scope;
- phased/instanced exceptions;
- griefing constraints.

### Gate R21

Full `shared_area` certificate.

This proves cartridge investment can graduate into the MMORPG.

## R22 — Persistent text MMORPG expansion

Only after R20/R21 evidence.

Possible capability packs:

- guilds;
- realm economy;
- crafting markets;
- housing;
- factions;
- world events;
- channels/mail;
- mentorship;
- player governance;
- live operations.

Each remains independently specified/certified.

# Dependency graph

```text
FOUNDATION AND FIRST STORY
R0 -> R1 -> R2 -> minimal R3-R6 + selected early R7/R8 slices
                              -> R6P playable proof
                              -> remaining chapter-one features
                              -> R9 minimum + R9C -> R10 full chapter

STORY RELEASE                       AUTHORING / REUSE
R10 -> R12 (incl. R12A) + free-release gates      R10 authoring evidence -> R11 -> R16
        -> R13 before paid release                            |
                                                     later Story content

REALM (separate track; does not block offline content or Builder)
R14 -> R15 -> R17 -> R18 -> R19 -> R20 -> R21 -> R22
```

This is an orientation map, not a second dependency registry. The Realm track uses the
shared foundation and applicable platform services; it is not an independent rebuild.
R6P deliberately draws only selected early narrative/schedule slices forward. Later
capabilities still satisfy their own phase gates before content can depend on them.


R12 may overlap R10; R12A account/progress work may start in parallel with R6/content. Its real platform persistence/API is required before the first public Story release and is reused by R13/R14, independent of purchase product work. R13 is mandatory before paid releases, not before the proof or an otherwise compliant free chapter release. Both free and paid releases require their applicable store, installation, signing, compatibility and human acceptance gates. Realm gates do not block offline content/Builder/factory work. Phase numbers are stable labels, not an implicit total order.

# Issue sizing rule

Implementation issues SHOULD be small enough that:

- one primary contract changes;
- acceptance tests are explicit;
- independent review can understand the diff;
- rollback is clear.

Avoid tickets like “build quest engine.”

Prefer:

- define QuestInstance schema;
- implement `all` objective reducer;
- add duplicate-domain-event idempotency;
- implement quest reward idempotency receipt;
- add quest trace projection.

# Agent workflow

For every implementation ticket:

```text
read relevant spec
  ↓
write implementation plan
  ↓
implementation agent
  ↓
tests/evidence
  ↓
self-review
  ↓
correction
  ↓
independent/adversarial review
  ↓
correction
  ↓
merge readiness
```

Models should not silently amend architecture during implementation.

# Sizing

Historical ranges for one developer with agent assistance, following the chapter ladder in `00-first-cartridge-design.md` §11. They are not promises or acceptance gates. Re-estimate after R1/R6P using observed engineering and LLM-assisted authoring/correction/review throughput; do not reduce chapter scope to fit an old calendar guess.

| Phase | Range |
|---|---|
| R1 spike | 3 to 5 days for strategy A; 3 to 6 weeks for strategy B |
| R2 to R6 foundation | 8 to 12 weeks |
| R7 narrative, chapter-one tier | 4 to 6 weeks |
| R8 living world, chapter-one tier | 4 to 6 weeks |
| R9 and R9C, minimum gates | 4 to 6 weeks |
| R10 chapter one content | 6 to 10 weeks |
| R12 app shell + R12A accounts/progress | Re-estimate added platform work; old shell-only range was 6 to 10 weeks |
| R13 commerce and entitlement | 3 to 5 weeks |
| **Full free chapter one in the store** | Re-estimate after R6P; R10/R12 and applicable release gates |
| R11 Builder v1 | 4 to 8 weeks |
| Chapter two tier and content | 4 to 7 months after chapter one |
| Chapter three tier and content | 5 to 8 months after chapter two |
| **Full design shipped** | **about 18 to 29 months from R1** |

Realm development is not sized here and may run alongside later chapters. R16 is on the independent Story/Builder track, not a dependency on R14/R15.

# Shipping rule

Prove a small playable experience at R6P, then ship the full chapter rather than build every future catalog feature first.

The first free product gate spans **R10 + R12 (including R12A accounts/progress) plus applicable installation, signing, compatibility, store and human gates**. The first paid cartridge additionally requires R13 purchase/restore/entitlement evidence. Free experience validation and paid-product validation are different, explicit milestones.

The MMORPG path exists in the architecture so that work compounds, not so it blocks shipping.

## Readiness amendment implementation notes

At R6, implement action-driven default time, durable accepted-attempt save, bookmark/fork lineage and referenced-package retention before UI depends on them. R6P uses both Lantern choice traces, early-possession behavior and adverse paths, including required narration recovery. Do not interpret these specification-model tests as completed P1–P6 work.

At R12, include three-bookmark UX, manual export/import, released-save migration/retention fixtures and clearly separated recovery promises (10 §31–33). At R12A, include restored-report/account-lifecycle provenance (23 §11). Optional whole-save backup is not pulled into R1/R6P or made a new mandatory R13 subsystem. R13 still gates paid commerce and published support/sunset policy. The 37-capability chapter-one lock stays unchanged. The generated planning checklist now also carries the RUN public-Story gate for the newly adopted local recovery/export obligations; it does not add those UX requirements to R1/R6P or grant Realm save-import authority.

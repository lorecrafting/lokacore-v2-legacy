# 14 — Implementation Plan and Dependency Graph

**Status:** draft sequencing derived from v3 architecture.  
**Rule:** no fresh implementation repository should begin substantive engine work until this packet is accepted and Phase R0 is complete.

This plan intentionally prioritizes a small shippable offline storypack while proving that the same portable rules can later run under BEAM authority.

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

R1 compares three strategies against the pre-registered envelope. None is selected here.

**A. One TypeScript kernel.** The portable rules are one TypeScript package. React Native runs it natively in its JavaScript engine with no FFI, no native module, and no binding generator. BEAM reaches it through an Erlang Port to a Node process, or an equivalent isolated runner, with JSON or a binary codec across the boundary. Determinism requires integer arithmetic for rule-critical math, `Map` and canonical key ordering rather than object-key order, and a seeded PRNG. Costs: a Node process in the server deployment and per-decision serialization, which is the same state-crossing cost strategy B must benchmark.

**B. One Rust kernel.** One deterministic Rust library behind Elixir/Rustler, an iOS React Native native binding, and an Android React Native native binding. Strongest type system and no runtime dependency inside the kernel; highest build, binding, and debugging cost across four hosts.

**C. Dual implementation.** Pure Elixir online plus TypeScript offline, held to one semantic schema and golden-vector suite. No cross-language boundary on either host; permanent two-implementation maintenance and semantic-drift cost.

The chapter-one mechanics in `00-first-cartridge-design.md` §11 are almost entirely derived state and pure reducers, which is the easiest case for strategy A and should be the spike's representative workload.

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

- canonical serialization;
- exact trace parity;
- snapshot round-trip;
- deterministic RNG;
- same errors;
- build automation on all hosts;
- acceptable FFI overhead/copy behavior at realistic world-state sizes;
- a safe decide → persist → apply-delta protocol;
- deterministic IDs/map ordering/numeric behavior;
- no BEAM scheduler starvation.

### Rejection criteria

Reject shared-Rust approach if:

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
- diagnostic/error registry.

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

R5 freezes the v1 ActionRecipe/InspectableDetail/Connection/Barrier and other foundation-world shapes before portable world rules depend on them. R7 freezes the v1 narrative/Scene/InstancePlan/consequence shapes before R9C/R10 depend on them. R8 freezes the v1 living-world/population/commerce/service/world-event shapes before the conformance and product cartridges depend on them.

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
- installed cartridge manager.

### Gate R6

Airplane mode:

- start new tiny cartridge;
- play;
- kill app during actions;
- resume;
- finish;
- no state corruption.

## R7 — Quest, dialogue, and scenes

### Objective

Support real narrative cartridges.

### Build

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

A quest can drive a durable SceneSequence containing text narration, an authoritative choice, a crash/reconnect checkpoint, and typed world consequences exactly once. A player-scoped dream proves both overlay and minimal InstancePlan composition, isolation, reconnect/save behavior, and explicit export semantics.

LokaScript is **not** part of R7. No chapter of `00-first-cartridge-design.md` requires it; ADR-018 is deferred until a real cartridge presents a mechanic that ActionRecipe, ReactionRule, Policy, and quest operators cannot express, at which point it is admitted through a CapabilityProposal and its own phase.

## R8 — Living-world capability pack

### Objective

Make the world feel like a MUD, not a branching ebook.

### Build initially

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

30 simulated days:

- service queues/jobs remain bounded and deterministic;
- escrowed inputs/outputs conserve ownership;
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

### Build

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

Every seeded injected failure generates a one-command/fixture reproducible report.

A deliberately broken mini-cartridge is detected by the expected static/model/invariant/
mutation-sensitivity gates. The Lab can account for quest/scene/area coverage, explore
declared bounded branches, export an exact evidence bundle, and reproduce a model-proposed
adversarial scenario deterministically without treating the model output itself as pass/fail evidence.

## R9C — Synthetic V3 Conformance Cartridge

### Objective

Create a small permanent **architecture/conformance cartridge** whose job is to stress the engine and Lab, not to be a commercially coherent story.

This separates two different optimization targets:

- the conformance cartridge is intentionally adversarial, compact, and mechanically broad;
- R10 is intentionally player-facing, coherent, and allowed to use only the mechanics its fiction needs.

### Build

The conformance cartridge SHOULD exercise the currently implemented portable foundation broadly enough to cover representative interactions such as:

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

The cartridge should be authored primarily through source files/compiler/Lab at this stage. Record every repetitive, confusing, or error-prone authoring operation as evidence for the Builder API rather than prematurely generalizing it.

## R11 — Builder API v1 and script-surface generalization

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

Can overlap late R10.

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

Non-developer can install the polished build, enter airplane mode, play/finish the free cartridge, resume after app/device restart, and use production cartridge/save UX without developer tooling.

## R13 — Commerce and entitlement

### Build

- introduce PostgreSQL dev/test/runtime infrastructure needed by platform services;
- `loka_platform` account/catalog/entitlement application service boundary;
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

- Session→Account→Character;
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

Chaos tests around every commit boundary pass.

## R15 — Online-private deployment

### Objective

Offer same story as cloud-authoritative run.

### Build

- deployment selection;
- online saves;
- persistent account links;
- online cartridge catalog launch;
- optional online-authoritative achievements.

### Gate R15

Within the same Loka app, the player can choose local Story execution or a connected Realm/private deployment of the same portable cartridge where offered; narrative/rules match.

## R16 — Repeatable AI factory

Only now automate content production heavily.

### Build

- Loka project workflow RoleSpecs/templates for architect/builder/reviewer responsibilities
  where an orchestrator is used; these are not hard-coded Foundry kernel roles;
- context retrieval;
- semantic review;
- automated correction;
- primitive proposal;
- release-candidate packaging.

### Gate R16

Two materially different cartridges produced mostly as content changes without unreviewed engine patches. Chapters two and three of `00-first-cartridge-design.md` §11 are the intended candidates; each introduces its tier of capabilities through reviewed engine work first, then its content through the Builder.

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
R0 spec
 |
R1 portability spike
 |
R2 repo foundation
 |
R3 schemas/contracts
 |
R4 compiler
 |
R5 kernel
 |
R6 offline host
 |
R7 narrative
 |
R8 living world
 |
R9 lab
 |
R9C conformance cartridge
 |
R10 first product cartridge
 |\
 | R11 builder
 |
 R12 mobile shell
 |
R13 commerce
                  |
                 R14 BEAM online
                  |
                 R15 online-private
                  |
                 R16 factory  (also requires R11 Builder API)
                  |
                 R17 party
                  |
                 R18 shared hub
                  |
                 R19 instanced story regions
                  |
                 R20 shards
                  |
                 R21 shared promotion
                  |
                 R22 MMORPG expansion
```

Some implementation can overlap, but gates define what may depend on what.

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

Rough ranges for one developer with agent assistance, following the chapter ladder in `00-first-cartridge-design.md` §11. They are planning inputs, not commitments; revise them after R1 and again after R6.

| Phase | Range |
|---|---|
| R1 spike | 3 to 5 days for strategy A; 3 to 6 weeks for strategy B |
| R2 to R6 foundation | 8 to 12 weeks |
| R7 narrative, chapter-one tier | 4 to 6 weeks |
| R8 living world, chapter-one tier | 4 to 6 weeks |
| R9 and R9C, minimum gates | 4 to 6 weeks |
| R10 chapter one content | 6 to 10 weeks |
| R12 app shell | 6 to 10 weeks |
| R13 commerce and entitlement | 3 to 5 weeks |
| **Chapter one in the store** | **about 9 to 14 months from R1** |
| R11 Builder v1 | 4 to 8 weeks |
| Chapter two tier and content | 4 to 7 months after chapter one |
| Chapter three tier and content | 5 to 8 months after chapter two |
| **Full design shipped** | **about 18 to 29 months from R1** |

R14 onward is not sized here; it starts after chapter one ships and runs alongside chapters two and three.

# Shipping rule

The rebuild has failed if it spends a year building a universal engine without shipping a cartridge.

The first major product gate spans R10 + R12 + R13: **a polished offline purchasable storypack in the production Loka app**.

The MMORPG path exists in the architecture so that work compounds, not so it blocks shipping.

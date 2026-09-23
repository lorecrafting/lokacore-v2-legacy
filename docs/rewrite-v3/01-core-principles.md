# 01 — Core Principles and Non-Goals

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract.

Read authority, determinism and content principles before individual capabilities. Deferred features stay deferred.

<details>
<summary>Sections in this document</summary>

- [1. Product principles](#1-product-principles)
- [2. Architecture principles](#2-architecture-principles)
- [3. BEAM/OTP principles](#3-beamotp-principles)
- [4. Content principles](#4-content-principles)
- [5. AI principles](#5-ai-principles)
- [6. Non-goals for v3 foundation](#6-non-goals-for-v3-foundation)

</details>
<!-- packet-navigation:end -->

## 1. Product principles

### P1. One rules/content model, multiple authority hosts

Offline private cartridges, online private/party instances, shared areas, and the later MUD MUST execute the same portable deterministic cartridge semantics where a capability is declared portable.

Offline authority lives on-device; online authority lives in BEAM/OTP. This host difference MUST NOT fork the quest/action/content rules into unrelated engines.

A feature is not considered offline-cartridge-ready if it requires a server-only capability. A feature is not considered multiplayer-ready if it depends on undeclared single-player/global assumptions.

### P2. Rich primitive library, narrow composition grammar

Loka SHOULD grow a large vocabulary of reusable primitives:

- movement and topology;
- doors/locks/containers;
- inventory/equipment;
- combat/status;
- checks/resources/skills;
- shops/economy;
- factions/reputation;
- schedules/patrol/wander;
- time/weather/environment;
- spawning/despawning;
- dialogue;
- quests/objectives;
- rumors/custom domain events;
- crafting/gathering;
- social actions;
- world and instance events.

Complexity belongs in **what can be composed**, not in having many contradictory ways to mutate the same state.

### P2a. Closed semantics, open composition

Builders SHOULD have extremely broad expressive power through composition while engine authority semantics remain closed and versioned.

Cartridge content may define and combine:

- typed facts/events;
- policies and target selectors;
- Actions;
- ReactionRules;
- Behaviors/state machines;
- population/encounter plans;
- commerce/services;
- dialogue/scenes/quests/world events;
- templates/archetypes;
- bounded LokaScript.

Content MUST NOT gain expressivity by adding hidden persistence paths, arbitrary host callbacks, or a second mutation authority.

The layered primitive model is normative in [21 — Composable World Primitives and Builder Expressivity](21-composable-world-primitives.md).

### P3. Content is not code by default

A new storyline SHOULD normally consist of cartridge source, assets, and tests.

If the author repeatedly needs a new behavior, the factory SHOULD propose a reusable capability rather than hiding bespoke semantics inside arbitrary code.

### P4. Mobile touch and text commands are two views of the same action model

A touch action such as “Inspect altar” and a text command such as `look altar` MUST resolve to the same internal action/command contract.

The active authority resolves currently available actions. In Story Mode that authority is local; in Realm Mode it is the BEAM server. Presentation code is never the rules authority.

### P5. Launch accounts do not make Story gameplay online

The first public Story release provides accounts and durable account-level completion tracking. Installed Story play remains local and usable without a live account session. The platform accepts designated offline milestone reports for onboarding eligibility only; they cannot import competitive Realm progression or purchase entitlement. See [23 — Accounts, Story Progress, and Realm Admission](23-accounts-progress-admission.md). This product principle does not add an account gameplay StateScope.

## 2. Architecture principles

### A1. One authoritative owner per mutable state domain

At any instant, mutable world state MUST have one authoritative owner.

Examples:

- one private world instance process owns its instance state;
- one zone shard owns shared-zone state;
- a session process owns connection-local ephemeral state;
- SQLite/PostgreSQL durably record committed state for their authority host; persistence is not an independent gameplay decision authority.

Two independent writers MUST NOT race on the same logical state without an explicit coordination/transaction protocol.

### A2. Portable pure kernel, actor shell online

Use a portable deterministic kernel for rules that must run both offline and online. Use BEAM processes around online concurrency and lifecycle boundaries; keep decisions pure.

Preferred pattern:

```text
GenServer.handle_call(command)
        |
        v
Domain.decide(state, command, env)
        |
        +--> StateDelta
        +--> domain events
        +--> effects
        |
        v
transactional commit
        |
        v
adopt committed state
```

Online, the BEAM process is the serialization/fault-containment shell. Offline, a local serialized authority shell provides the same command/commit contract. The rule function/kernel is replayable in both and MUST NOT irreversibly advance hidden authoritative state before commit succeeds.

### A3. No direct persistence from domain rules

Domain rules MUST NOT call Ecto, Repo, Phoenix, PubSub, filesystem, HTTP, wall clock, or process-global randomness.

These dependencies arrive through explicit adapters/effects/environment.

### A4. No web dependency in game logic

No module in domain/runtime/content/store MUST depend on `LokaWeb` serializers, sockets, controllers, or LiveView structures.

Transport adapters translate internal results into protocol messages.

### A5. External contracts are generated or checked

The following MUST have machine-readable source-of-truth schemas:

- host-neutral ActionInvocation and GameView contracts;
- portable semantic Commands, StateDelta, DomainEvents, and Effects;
- Realm transport messages/envelopes when Realm Mode is introduced;
- Builder API operations/results/errors;
- cartridge/deployment/campaign manifests;
- content kinds;
- capabilities/components;
- policies/conditions;
- script bindings;
- quest objective operators.

Markdown MAY explain them but MUST be test-checked against implementation.

### A6. Time and randomness are dependencies

Portable game-rule code MUST NOT directly call:

- `DateTime.utc_now/0`;
- `System.system_time/0`;
- process-global `:rand.uniform/1`.

The decision environment supplies a logical clock and explicit RNG state/service.

This is mandatory for deterministic simulation and exact bug reproduction.

### A7. Fail closed at authority boundaries

Unknown:

- capabilities;
- permissions;
- policies;
- protocol variants;
- effect types;
- content references;
- script operations

MUST fail validation rather than silently continue.

User-facing gameplay may degrade gracefully only where the contract explicitly defines a fallback.

### A8. Determinism includes representation, not only algorithms

Portable deterministic rules MUST define:

- canonical map/set iteration order;
- canonical serialization;
- fixed RNG algorithm/version;
- deterministic gameplay ID generation/source. New runtime entities/events created inside a decision should derive IDs from an explicit IdSource (for example a namespaced hash/UUID over instance identity + command/event identity + allocation ordinal), never host entropy. Account/session/request IDs that do not affect portable game semantics may remain host-generated;
- deterministic integer/fixed-point arithmetic for rule-critical calculations where floating-point variation could change outcomes;
- explicit handling/avoidance of NaN/infinity/platform math differences;
- stable sorting/tie-break rules.

Do not rely on language hash-map iteration order or host entropy.

Presentation-only animation/audio calculations may use ordinary platform floating point because they are outside authoritative game state.

### A9. Idempotency at retryable boundaries

Retryable ActionInvocations/Commands, reward operations/effects, purchase reconciliation, scheduled jobs, Builder mutations, and promotion operations MUST have stable IDs or idempotency keys. Reuse of an idempotency identity with a different semantic payload MUST fail as an integrity conflict.

Retries MUST NOT duplicate:

- inventory;
- currency;
- quest rewards;
- world spawns;
- entitlements.

## 3. BEAM/OTP principles

### B1. BEAM processes represent online concurrency boundaries, not object orientation

Use processes for:

- connected sessions;
- private/party world instances;
- shared-world shards;
- schedulers/coordinators;
- external integrations;
- long-running isolated workers.

Do not default to a process per item/NPC/quest.

### B2. Let it crash, but only inside a recoverable boundary

A process may crash on violated internal assumptions if:

- its supervisor can restart it;
- durable state is consistent;
- the triggering command has a receipt or can be retried safely;
- no partial external effect escaped without recovery metadata.

### B3. Prefer supervision to defensive catch-all code

Do not add broad rescue/catch handlers merely to keep corrupted processes alive.

Expected validation errors should be data. Programmer faults should be visible and restartable.

### B4. PubSub is observation/fan-out, not authority

Phoenix PubSub is ideal for:

- client notifications;
- telemetry subscribers;
- world observation;
- non-authoritative ambient fan-out.

It MUST NOT be the sole mechanism guaranteeing durable state transitions or exactly-once rewards.

## 4. Content principles

### C1. Definition and runtime instance are different concepts

Definitions are immutable cartridge content.

Runtime entities are mutable world instances referencing definitions.

The same DB row or struct SHOULD NOT ambiguously represent both.

### C2. Cartridge-local names are allowed

Authors should be free to name a room `tavern` in many cartridges.

Canonical definition identity includes cartridge ID and version.

### C3. Compile-time reuse, runtime flattening

Reusable templates/mixins MAY exist in source authoring, but compilation SHOULD flatten them into explicit definitions.

Runtime rules MUST NOT chase deep prototype inheritance graphs.

### C4. State scope is explicit

Every scoped gameplay truth/progression feature MUST declare or derive one of:

- player;
- party;
- instance;
- realm.

Scope answers **who owns the state**, not which process/table physically hosts it, who can see it, or who contends for a scarce resource. Those are separate contracts.

No implicit “global because it worked in a solo test.”

## 5. AI principles

### AI1. AI is a client of contracts

Astra/Foundry/other models use:

- capability discovery;
- Builder API;
- compiler;
- validators;
- lab;
- trace/replay.

They SHOULD NOT need arbitrary repository access for normal content authoring.

### AI2. Deterministic systems decide correctness first

AI semantic review supplements:

- schema checks;
- graph checks;
- reducer/property tests;
- simulation;
- concurrency tests;
- restart tests.

A model opinion cannot waive a failed invariant.

### AI3. Missing capability is explicit

If an author cannot express a mechanic, the tool returns a missing-capability diagnosis.

The model may propose a new engine capability, but cannot secretly implement new authority semantics inside content.

## 6. Non-goals for v3 foundation

The foundation is NOT trying to provide:

- arbitrary mod execution from untrusted users;
- seamless hot code upgrades across every production deploy;
- multi-region active/active world state;
- blockchain/decentralized ownership;
- a generic 3D engine;
- runtime LLM NPC consciousness;
- user-generated marketplace moderation;
- every Lokacore experimental feature on day one.

The first target is a small, certifiable, purchasable cartridge that proves the architecture.

# Loka Cartridge & Living World Roadmap

**Status:** current working strategic baseline; continuously refined by reviewed v3 specification amendments.
**Scope:** product and architecture direction for turning Loka into a mobile-first cartridge platform that can grow into a persistent multiplayer MUD.

This document owns product sequencing for the cartridge strategy. It does not by itself authorize a large rewrite. Each architecture change still needs a bounded implementation plan, tests, review, and migration path. Existing product notes remain useful research unless they conflict with an explicit decision here.

### Clean-rebuild decision

The working implementation direction is now a **clean-sheet Loka v3 rebuild**, not an in-place refactor or module-by-module port of Lokacore.

The normative draft architecture packet is [`docs/rewrite-v3/README.md`](../rewrite-v3/README.md). Lokacore remains a reference/evidence corpus for requirements, mechanics, tests, failure modes, and selected content semantics. The new implementation should start from accepted v3 contracts rather than preserve legacy APIs or compatibility layers.

The rewrite packet refines this roadmap in one major respect: offline-capable single-player storypacks are locally authoritative and use a portable deterministic rules kernel, while online private/party/shared play is authoritative under the BEAM runtime. The cartridge/content model is shared so storypack work can graduate into the later MMORPG without becoming throwaway work.

## Strategy in one page

Build **one Loka mobile app with two strict authority modes**. Ship small, self-contained story worlds first through **Story Mode**. Add the persistent multiplayer product later as **Realm Mode** in the same app. The modes share rendering, account/catalog surfaces, accessibility, localization, and generated contracts, but they do not share authority:

- **offline private:** local mobile authority + local SQLite;
- **online private/party/shared:** BEAM/OTP authority + PostgreSQL.

The shared portable deterministic rules layer prevents offline storypacks from becoming throwaway work while allowing the online system to use Elixir/OTP where concurrency, supervision, networking, scheduling, and fault recovery matter most.

The capability library should become increasingly expressive: movement, schedules, weather, spawning, combat, dialogue, factions, reputation, inventory, world events, timers, social systems, and other old-school MUD mechanics. The authoring contract should become more constrained and machine-readable: one stable way to invoke each primitive, one canonical schema, deterministic composition, and certification.

The central product rule is:

> New stories should normally add content, not application code. New mechanics should become reviewed capabilities that future stories can reuse.

| Decision | Working direction |
|---|---|
| Implementation | Clean-sheet Loka v3. Lokacore is evidence/reference, not a code-migration target. |
| Online runtime | Elixir/Phoenix on BEAM/OTP, using explicit world/zone authority processes and PostgreSQL. |
| Portable rules | Shared deterministic kernel for mechanics that must run both offline and online; Rust is the provisional language pending the mandatory spike. |
| Story Mode | Offline-first cartridge player inside the Loka app: local authority, local saves, campaigns/expansions, no multiplayer/world-service requirement for ordinary play. |
| Realm Mode | Online-only mode inside the same Loka app: BEAM-authoritative private/party adventures, shared areas, social systems, persistent realm. |
| Reuse boundary | Portable story cartridges may be reused online as private/party adventures or adapted through an explicit promotion workflow; realm-native content may use server-only capabilities. |
| World richness | Preserve and expand a large primitive/capability library. Simplify composition rules, not the world simulation. |
| Quests/world immersion | Quests observe canonical DomainEvents, reach named outcomes, then apply typed scoped consequences. Shared typed facts let NPCs, access, dialogue, schedules, ambience, and follow-up content react coherently without arbitrary quest scripts. |
| Scripting | Declarative capabilities first; Elixir-like LokaScript compiles to portable normalized form interpreted by the shared rules system. No released cartridge executes via `Code.eval_string`. |
| AI authoring | Give builders a generated capability catalog/schema and a canonical Builder API rather than asking models to reconcile engine internals and stale Markdown. |
| Authoring surface | Agents use structured MCP/tool calls; humans may use a thin terminal/CLI over the same Builder API; visual UI is primarily inspection/debugging. |
| Testing | Every cartridge/deployment earns an exact-hash release certificate from static checks, model/property checks, deterministic simulation, bots, chaos/concurrency where relevant, restart/replay, host conformance, semantic review, and mobile smoke. |
| Mobile distribution | One store app. A strict session boundary selects local Story authority or remote Realm authority; shared GameView/UI avoids duplicated clients. |
| Launch monetization | Default hypothesis: free app + free showcase cartridge, then permanent à-la-carte cartridge unlocks; bundles later; subscription only after a reliable content cadence exists. |
| Factory | AI/factory orchestration is build-time tooling, never a gameplay dependency. |

## 1. Product shape: offline stories first, MMORPG later, shared semantics

The earlier product question of isolated interactive stories versus a shared MUD is sequencing rather than a fork, but **offline single-player and online multiplayer use different authority hosts**.

### Phase-one experience

A player installs Loka, enters Story Mode, acquires/downloads a cartridge, and can play it offline. The world is not a branching ebook. It is a real Loka simulation with rooms, NPCs, inventory, time, schedules, quests, dialogue, environmental behavior, and whatever portable capabilities the cartridge declares.

The local mobile authority serializes commands and commits durable state to local SQLite. No ordinary gameplay connection is required after acquisition/download for an offline-capable cartridge.

A cartridge can be thirty minutes or many hours. Multiple cartridges may compose into a versioned campaign with explicit continuity exports/imports.

### Expansion path

The runtime execution profiles remain the four defined by the v3 packet:

1. **offline_private** — one player, local device authority;
2. **online_private** — one player, BEAM WorldInstance authority;
3. **party** — a small group shares a BEAM-hosted instance;
4. **shared_area** — many players under shared Realm authority with multiplayer certification.

Product/topology evolution composes those profiles rather than inventing aliases for them. An **embedded instance** is an online-private/party deployment entered from Realm geography. The eventual **persistent world** is a Realm topology composed from shared-area deployments plus realm services, identity/social/economy systems, and long-lived characters; it is not a fifth execution profile unless a future ADR explicitly adds one.

A successful single-player cartridge can later remain a private/party adventure, become an embedded instanced region, or—when its fiction and mechanics suit it—be promoted into a shared area. We do not force every intimate story into globally shared state.

## 2. Preserve Lokacore's lessons, not its implementation

Lokacore remains valuable evidence for the rebuild. High-value concepts include:

- Phoenix/OTP multiplayer experience and session ideas;
- the entity/component/behavior composition direction;
- rooms, exits, NPCs, items, inventory, combat, quests, dialogue, timers, schedules, and world events;
- reusable living-world ideas such as patrol, wandering, day/night schedules, shop hours, ambient emitters, nocturnal behavior, and timed spawning;
- content validators and dependency/reachability analysis;
- ChannelBot/storyline playthrough testing;
- AI evaluation, balance simulation, and builder/MCP work;
- the constrained-scripting product need;
- React Native touch-oriented game UI experiments.

The new implementation MUST start from v3 contracts rather than reusing Lokacore modules/APIs/process topology. Existing tests, content, and failure cases may be translated into new acceptance fixtures.

### Storage direction

The clean rebuild uses two explicit persistence hosts:

- **offline storypacks:** local SQLite (or equivalent transactional local store);
- **online authority:** PostgreSQL from the start.

The logical cartridge/state/command/snapshot contracts remain host-neutral. Offline and online physical schemas do not need to match byte-for-byte.

### What changes first

Before implementation scale, make the **portable/content semantic contracts** unambiguous and machine-readable:

- capability registry and exact capability locks;
- cartridge/deployment/campaign schemas;
- Action/ActionInvocation, semantic Command, StateDelta, DomainEvent, Effect, and GameView contracts;
- state-scope rules;
- canonical serialization/determinism rules;
- offline/online host-conformance vectors.

Do not front-load every external surface. The generalized Builder operation registry is derived after the first real cartridge exposes authoring pain, and the Realm network protocol is introduced when Realm Mode begins.

An AI builder should not have to decide which era of Lokacore documentation is true.

## 3. Capability catalog and cartridge contract

### 3.1 Capability registry

Engine capabilities should be registered with schemas that tooling can inspect, for example:

```json
{
  "key": "patrol",
  "kind": "behavior",
  "version": 2,
  "targets": ["npc"],
  "config": {
    "route": {"type": "room_ref[]", "required": true},
    "interval": {"type": "duration", "default": 300}
  },
  "emits": ["patrol.departed", "patrol.arrived"]
}
```

The registry should cover at least:

- entity components;
- behaviors;
- actions and effects;
- condition predicates;
- event types;
- quest objective operators;
- script bindings;
- client-visible interaction/rendering capabilities.

Markdown documentation should be generated from or checked against this registry. Documentation explains semantics; the schema is authoritative.

An AI builder should be able to query capabilities by meaning, target type, input/output schema, and examples without loading the entire repository into context.

### 3.2 Cartridge manifest

A cartridge is an immutable compiled content release, not an alternate application:

```yaml
api_version: loka/v3
id: fox_spirit_of_yunmeng
version: 1.2.0

requires:
  kernel_api: ">=1.3 <2.0"
  rule_ir: 1
  content_schema: 1
  capabilities:
    - movement@1
    - dialogue@2
    - quest@3
    - schedule@1
  client_features:
    - contextual_actions_v1
    - dialogue_choices_v1

supported_profiles:
  - offline_private
  - online_private

entry:
  room: rooms/ferry_dock

locales:
  default: en
  available: [en, zh]
```

The compiled artifact should record a content hash and the exact compatibility contract it was certified against.

### 3.3 State scope must be explicit

Every stateful mechanic needs a declared scope so private content can later survive multiplayer:

- `player`
- `party`
- `instance`
- `realm`

Per-player quest progress should be the default. A world boss death, town election, weather system, or shared gate can be explicitly broader.

This prevents one of the classic MUD bugs: content that works with one player but silently assumes global state when twenty players arrive.

### 3.4 Authoring architecture: API-first, terminal-human, MCP-agent

Loka should not maintain a rich visual CRUD application as the primary way to author worlds. The existing repository is already moving in the preferred direction: the old GUI builder was archived, `/admin/builder` is a terminal-first LiveView, and the World Builder already exposes structured MCP tools.

The next step is to make those surfaces converge on **one canonical Builder API**.

The architectural rule is:

> The terminal should not be the API. The canonical typed Builder API should power the terminal, MCP, future CLI, automation, and tests.

Today the repository has partially overlapping paths:

```text
terminal commands → BuilderCommands.* → managers
MCP/AI tools      → ToolExecutor.*    → managers
```

That duplication can drift. Replace it incrementally with one domain operation layer:

```text
                    Canonical Builder API
                           │
              ┌────────────┼────────────┐
              │            │            │
            MCP          Terminal      CLI/tests
           agents         humans        automation
```

A room creation, quest update, script validation, publish, or simulation action should have one schema, one implementation, one result/error model, and one audit trail regardless of caller.

#### Structured tools are the preferred AI surface

A model should not need to type terminal commands and parse prose responses. It should receive typed inputs and machine-readable results, for example:

```json
{
  "ok": false,
  "code": "QUEST_TARGET_UNREACHABLE",
  "path": "objectives[2].target",
  "target": "abandoned_shrine",
  "diagnostic": {
    "from": "ferry_dock",
    "connected_component": 3
  }
}
```

This makes repair loops cheaper, safer, and easier to test than terminal-text automation.

The current MCP tool layer is a useful starting point, but its schemas should eventually be generated from or checked against the same capability/content contracts described above. Loka should not hard-wire the architecture to one model vendor; Astra, Foundry, Claude, or another orchestrator should all see the same stable Builder API.

#### Keep the terminal as a thin human shell

The current terminal-first `BuilderLive` is small and useful. Keep it for:

- direct inspection;
- quick mutations;
- play/debug commands;
- certification commands;
- trace exploration;
- AI conversation when convenient.

Its parser should translate human commands into canonical Builder API operations rather than owning separate mutation semantics.

A future CLI can do the same.

#### Use visual UI for inspection, not duplicated authoring logic

Visual interfaces are valuable where humans gain real leverage from spatial or temporal presentation. Prefer read-heavy/debugging views such as:

- world/zone maps;
- quest graphs;
- dialogue graphs;
- NPC schedule timelines;
- event/causation traces;
- simulation playback;
- cartridge certification dashboards;
- dependency/reachability views.

Avoid rebuilding large form-based editors for rooms, quests, NPCs, scripts, or components unless later user research proves a specific visual editing workflow is substantially better than API/terminal authoring.

The rule is:

> **Author with typed tools/text. Inspect and debug with visuals.**

#### Author in cartridge workspaces, not directly in production state

The factory should normally mutate a bounded candidate workspace, not the live world:

```text
Astra / human
    ↓
cartridge workspace
    ↓
compile + validate
    ↓
Cartridge Lab
    ↓
simulate + review
    ↓
certify exact hash
    ↓
publish/promote
```

An AI builder must be free to make and repair destructive mistakes inside an isolated draft without affecting production players.

The Builder API should therefore make workspace/revision context explicit on mutations. Publishing is a separate promotion operation with certification policy that content authors cannot bypass.

## 4. Quest engine audit: keep the state machine, redesign the mutation path

### Why the StateMachine exists

`Loka.Engine.StateMachine` is a useful pure primitive. Historical Lokacore quest code used lifecycle shapes such as:

`available → accepted → in_progress → objectives_complete → turned_in`

with abandon/failure branches. That history is evidence, not the v3 contract.

V3 deliberately simplifies persisted lifecycle to roughly:

`active → objectives_complete → resolved(outcome_id)`

with explicit failed/abandoned branches and retry policy where allowed. Availability is derived before a QuestInstance exists; acceptance is an activation interaction; turn-in is one possible resolution policy rather than a universal state.

The useful lesson from the old StateMachine remains: explicit persisted states and legal transitions are easier to validate and test than implicit combinations of booleans.

### Why quests can still break

The state machine only answers whether one lifecycle transition is legal. It does not own all the ways quest state changes.

The current quest subsystem still has multiple cooperating paths:

- hook listeners translate movement, item, combat, and dialogue activity;
- objective handlers decide whether an event matches;
- `Progress.update_progress/2` loops active quests and mutates objective state;
- dialogue and manual actions can cause quest progress;
- timers expire objectives;
- turn-in separately applies rewards and moves active state to completed;
- scripts expose quest-related bindings/effects.

The retained `docs/temp/continuation-prompt-quest-bug.md` captures the kind of failure this permits: a dialogue objective was observed as complete before the intended turn-in interaction, causing the bot to skip the node that contained `complete_quest`.

The lesson is not "state machines failed." The lesson is that **lifecycle validation was added without giving one subsystem sole ownership of quest interpretation and mutation**.

### Target: Quest Runtime v3

Use one canonical path:

```text
world action
    ↓
canonical typed Loka event
    ↓
QuestRuntime
    ↓
pure QuestReducer
    ↓
new QuestInstance + typed effects
    ↓
authoritative commit
    ↓
effect execution / UI events
```

#### A. Normalize the existing event system rather than create a second bus

Loka already has `Loka.Engine.Event` and `EventBus`, including event IDs, correlation IDs,
causation, source/target, and payload validation. Quest Runtime v3 should extend and
normalize that path where practical instead of inventing a competing `GameEvent` system.

Every quest-relevant occurrence is represented once with the identity needed for replay,
scope, and deterministic tests, for example:

```elixir
%Loka.Engine.Event{
  id: event_id,
  type: :dialogue_node_reached,
  source: player_id,
  target: npc_id,
  payload: %{
    target_key: "elder_maren",
    node: "after_sacrifice",
    instance_id: instance_id,
    logical_time: logical_time
  },
  correlation_id: correlation_id,
  caused_by: parent_event_id
}
```

The exact fields may evolve, but event identity, causation, scope/instance, and a
test-controllable notion of time must be available. Add explicit event types/schemas
rather than smuggling quest meaning through ad-hoc maps.

Adapters at movement, combat, dialogue, inventory, timers, and scripts may **emit events**.
They do not directly update quest progress.

#### B. Explicit quest instances

Persist an explicit instance per scope:

```text
quest_key
quest_definition_version
scope + scope_id
lifecycle_state
objective_states
variables
accepted_at
revision
processed_event/effect identity needed for idempotency
```

An active save is pinned to the quest/cartridge definition it started against. Publishing a new cartridge version must not silently reinterpret an in-progress quest. If an update needs migration, that migration is explicit and tested.

#### C. Pure reducer

`QuestReducer.reduce(definition, instance, event)` should be side-effect free:

```elixir
{:ok, new_instance, effects}
```

or:

```elixir
:no_change
{:error, invariant_violation}
```

It decides:

- whether the event matches;
- objective progress;
- lifecycle advancement;
- failure/expiry;
- branching variables;
- effects that should occur.

This makes property tests, replay, fuzzing, and diagnosis much easier.

#### D. StateMachine remains the lifecycle guard

Do not delete the shared StateMachine. Use it inside the reducer to validate lifecycle transitions.

For richer quests, objective structure should support composable graph operators rather than requiring script code for common logic:

- `all`
- `any`
- `sequence`
- `optional`
- `count`
- `within`
- conditional activation
- explicit branch/outcome nodes

The lifecycle remains small even when the objective graph is rich.

#### E. Effects happen exactly once

Rewards, item grants, timer scheduling, messages, spawn/despawn, and other mutations are typed effects emitted by the reducer. The authoritative effect layer applies them with idempotency keys.

A retry must not duplicate a rare item or reward gold twice.

Script helpers such as `complete_objective` should either disappear from the preferred authoring surface or be implemented as a typed quest DomainEvent that still passes through the reducer. No script gets a second private path into quest storage.

### Do not require full event sourcing

The objective is **event-replayable quest logic**, not turning the entire game database into an event-sourced system.

Snapshots/current state can remain authoritative. Retain enough normalized event/effect evidence to reproduce failures, test migrations, and produce a compact repro bundle.

## 5. Portable scripting remains useful, with a real semantic boundary

Lokacore proved the value of giving builders a scripting escape hatch, but its current same-BEAM sandbox is reference evidence only. The v3 target is **LokaScript**:

- Elixir-like authoring syntax;
- parsed/validated during cartridge build;
- compiled to a portable normalized AST/bytecode;
- interpreted by the shared deterministic rules system;
- typed binding registry;
- explicit clock/RNG;
- query/effect/event budgets;
- no filesystem/network/process/module escape;
- same semantics offline and online.

Declarative capabilities remain preferred. Repeated script patterns should be promoted into tested capabilities.

Compiled Elixir remains appropriate for **engine capability implementation on the BEAM**, but that is an engine release change—not cartridge code.

Public/untrusted creator scripting remains deferred until the custom interpreter and broader creator security/moderation model receive dedicated review.

## 6. Cartridge Lab: test worlds as products, not YAML files

Build a dedicated **Cartridge Lab** that can boot any cartridge or candidate multiplayer area into an isolated ephemeral instance.

The Lab should support:

- exact cartridge content hash;
- deterministic RNG seed;
- virtual clock: pause, step, fast-forward hours/days;
- state snapshots and rewind;
- player-state presets;
- quest/event/effect trace;
- entity and scope inspector;
- bot spawning and behavior profiles;
- fault injection;
- exportable reproduction bundle.

A developer should be able to reproduce a bug with:

```text
cartridge hash
engine revision
seed
initial snapshot
ordered player/world events
expected invariant
actual invariant
```

### Certification pipeline

A cartridge or shared area is not release-ready because one happy path works. Certification should layer evidence.

#### Gate C1 — compile and static integrity

- schema validation;
- capability/version compatibility;
- broken references;
- room connectivity and intended one-way paths;
- dialogue reachability;
- quest dependency cycles;
- required entity/component presence;
- asset existence;
- script validation;
- no undeclared capabilities.

#### Gate C2 — quest/model checks

For each quest:

- legal lifecycle transitions;
- double-accept/turn-in rejection;
- objective idempotency;
- prerequisite enforcement;
- abandon/reaccept behavior;
- timer expiry behavior;
- reward exactly-once semantics;
- bounded exploration of objective/dialogue branches;
- no required turn-in path that becomes unreachable under its own completion conditions.

Property-based tests should generate event sequences, not merely call one happy-path function.

#### Gate C3 — deterministic playthroughs

Use the real action/channel path where practical.

Run:

- intended main paths;
- alternate branches/endings;
- completionist path;
- minimal/rushing path;
- combat-heavy and noncombat variants where supported.

Record branch/quest/action coverage and a seed.

#### Gate C4 — accelerated world simulation

Run the world for hours or days with no human input and inspect invariants:

- scheduled NPCs can reach destinations;
- shops actually open/close;
- spawn populations remain bounded;
- timed entities despawn correctly;
- required NPCs do not become permanently unavailable;
- item sources/sinks remain viable;
- world loops do not create runaway events.

#### Gate C5 — adversarial and chaos play

Interleave normal progress with:

- death;
- logout/reconnect;
- repeated taps/duplicate commands;
- abandoned quests;
- dropped/destroyed items;
- leaving dialogue mid-conversation;
- unusual quest ordering;
- hostile NPC death at awkward times;
- time advancement;
- restart during active timers/effects.

Assert no invariant corruption and produce minimal repro traces on failure.

#### Gate C6 — multiplayer race and scope testing

For any cartridge that permits party/shared mode, run multiple players concurrently:

- accept/advance same quest simultaneously;
- kill/loot the same entity;
- open/lock shared objects;
- disconnect/reconnect;
- join/leave parties;
- compete for unique resources;
- trigger world events concurrently.

Assert player-, party-, instance-, and realm-scoped state never leak across the wrong boundary.

#### Gate C7 — restart/replay/upgrade

- stop/restart the server at effect boundaries;
- reload the exact cartridge version;
- replay diagnostic events to reproduce quest state;
- prove rewards/effects are not duplicated;
- test save compatibility or explicit migration to the next cartridge/engine version.

#### Gate C8 — semantic review

After mechanical checks pass, a strong reasoning model reviews the compact world model, traces, and coverage for failures that are legal but wrong:

- witness NPC is scheduled away before the murder scene;
- only quest-giver can identify an item but can be permanently killed;
- branches contradict established knowledge;
- a town feels empty because schedules synchronize;
- a choice is technically reachable but nonsensical;
- a multiplayer objective is scoped incorrectly for its narrative intent.

Use Astra or the strongest appropriate reviewer available for this stage. Provider choice is operational; certification inputs/outputs must remain model-independent.

#### Gate C9 — human mobile smoke

A human verifies on actual mobile builds:

- touch interactions;
- readability;
- pacing;
- purchase/download/restore;
- offline/reconnect behavior where promised;
- audio/assets;
- accessibility;
- save resume.

### Release certificate

Certification emits a machine-readable artifact tied to the exact compiled cartridge hash:

```text
cartridge ID/version/hash
engine/schema/script API versions
test revision
static validator result
quest/model coverage
simulation seeds and duration
chaos/concurrency scenarios
restart/replay result
semantic-review result + unresolved warnings
human smoke signoff
```

Only that exact hash is promotable. Editing content after certification creates a new candidate.

## 7. Multiplayer areas use the same certification machinery

A future MUD area is a cartridge with broader instance/scoping permissions.

Before a new shared area reaches the production realm:

1. certify it privately;
2. run multi-bot load/concurrency tests;
3. mount it in a staging realm with copied/non-production accounts;
4. canary it for invited testers;
5. promote the exact certified content hash;
6. retain a rollback pointer to the previous area version and a migration policy for persistent player/world state.

This is safer than editing the live world in place.

## 8. AI game factory

The factory should build against the contract rather than directly improvising across engine internals.

Suggested roles:

```text
creative brief
    ↓
narrative/world architect
    ↓
world + NPC + quest builders
    ↓
cartridge compiler
    ↓
deterministic validators/simulators
    ↓
semantic reviewer
    ↓
correction loop
    ↓
certified release candidate
```

### AI authoring rules

- Builders query the capability registry instead of loading every engine document.
- Generated content should use existing primitives first.
- Missing capability becomes a **primitive proposal**, not hidden custom runtime code.
- A new primitive needs engine tests and independent review before it enters the catalog.
- AI-generated scripts are reviewed, validated, simulated, and certified like all other content.
- A content author cannot weaken certification policy inside the cartridge.
- Factory/orchestrator failure must not affect released gameplay.

External orchestration tooling may coordinate this pipeline, but Loka should not depend on it at runtime.

## 9. App Store / Play Store release and commerce strategy

Store policies change; re-check them before implementation and launch. The current baseline and source links are tracked in [`docs/rewrite-v3/17-research-baseline.md`](../rewrite-v3/17-research-baseline.md).

### 9.1 One app, many stories, one later realm

Ship one long-lived **Loka** app, not separate apps per story or per authority mode.

- **Story Mode** owns cartridge library, offline saves, campaigns, purchase/download/restore, and local authority.
- **Realm Mode** owns online identity/social/party/realm UX and always delegates authority to BEAM.

Individual cartridges remain downloadable content inside Story Mode. Realm Mode can be added later through a normal app update without asking the installed Story player base to migrate to a second product.

### 9.2 Keep downloadable cartridges within shipped capabilities

For the simplest review and maintenance posture:

- do not download arbitrary native libraries or JavaScript executable modules per cartridge;
- portable LokaScript is interpreted by the already-shipped kernel/interpreter;
- cartridge downloads contain definitions, normalized portable script representation, localization, and assets;
- require a client/kernel update when a cartridge needs a genuinely new native/client capability.

Apple currently treats game levels/premium content as IAP content, and non-consumable IAPs are one-time purchases that do not expire. Google Play supports non-consumable one-time products such as additional game levels, while billing programs/policies vary by region and have changed materially in 2025–2026.

### 9.3 Permanent cartridge purchases

Default launch hypothesis:

- free app;
- at least one complete free showcase cartridge;
- premium cartridges map to permanent canonical Loka entitlements;
- optional bundles later;
- subscription only if an ongoing catalog/service cadence eventually justifies it.

### 9.4 Canonical entitlement + offline grant

Do not make Apple/Google product IDs the domain model.

```text
entitlement: cartridge.fox_spirit_of_yunmeng
  apple_product_id: ...
  google_product_id: ...
```

A trusted service verifies purchase provenance and records the canonical entitlement. For offline-capable purchased content it also issues whatever locally verifiable grant/proof the accepted platform implementation uses so normal play does not require periodic connectivity.

Offline saves remain on-device authority for the private story but are not trusted as MMO economy/progression authority.

### 9.5 Cartridge release without app binary release

A content-only cartridge should be releasable without a new client version when:

- the installed app/kernel supports all declared capabilities/client features;
- its product/catalog metadata is available;
- the exact cartridge/deployment hash has the required release certificate.

Apple currently requires the first IAP of a given type to be submitted with a new app version; after approval, later items of that type can be submitted separately when Apple's current conditions are met. Reverify at release time.

### 9.6 Content delivery

Typical paid offline-capable flow:

```text
store/platform purchase
    ↓
trusted verification → canonical entitlement
    ↓
locally verifiable offline grant
    ↓
download signed/hash-addressed cartridge + assets
    ↓
verify compatibility/integrity
    ↓
play locally with LocalInstanceAuthority + SQLite
```

Online-private/party deployment instead enters a BEAM WorldInstance after entitlement and compatibility checks.

### 9.7 Review/staging logistics

Maintain distinct environments:

- local Cartridge Lab;
- automated CI certification;
- internal/staging services;
- TestFlight / Play internal testing;
- production catalog.

Public user-authored cartridges remain deferred because they add moderation, reporting, age-rating, IP, creator security, and marketplace obligations beyond the first-party catalog.

## 10. Roadmap and gates

The older in-place L0–L5 repair sequence is superseded by the clean-rebuild implementation graph in [`docs/rewrite-v3/14-implementation-plan.md`](../rewrite-v3/14-implementation-plan.md).

At strategy level, the checkpoints are:

### S0 — Accept the v3 specification and prove portability

- finish self/adversarial review;
- accept decision register and record the exact normative spec/cutover manifest;
- pre-register the portability spike's measurable acceptance/rejection envelope;
- run the mandatory shared-kernel/mobile/BEAM feasibility spike;
- reject or freeze the provisional Rust/binding choice from evidence.

### S1 — Build the offline cartridge foundation and prove a real game

- fresh repository and strict boundaries, importing the accepted v3 normative contract as the single implementation-era architecture authority;
- machine-readable constitutional portable/content contracts, with higher-level feature schemas frozen as they are implemented/exercised;
- cartridge compiler;
- portable deterministic world rules;
- local authority + SQLite;
- quest/dialogue/LokaScript;
- living-world primitives;
- Cartridge Lab;
- build a small permanent synthetic v3 conformance cartridge for broad architecture/fault/invariant coverage;
- substantially hand-author the first real offline cartridge through source/compiler/Lab;
- record repetitive/error-prone authoring work;
- then generalize the canonical Builder API from that evidence.

**Gate:** the synthetic conformance cartridge catches the intended architecture/fault classes, and a small real cartridge can be completed fully offline, survives app termination/restart, passes applicable deterministic certification, and has produced concrete evidence for the Builder API rather than the Builder API delaying the game.

### S2 — Ship the first commercial cartridge

- polished mobile shell;
- download/install/save lifecycle;
- purchase/restore/offline entitlement;
- device smoke and store review.

**Gate:** a non-developer can buy/download, enter airplane mode, play, resume, and finish.

### S3 — Add BEAM online authority using the same cartridge semantics

- sessions/accounts/characters;
- WorldInstance supervision;
- PostgreSQL transactional command commits;
- command receipts/outbox;
- typed Phoenix protocol;
- online-private deployment.

**Gate:** representative cartridge traces conform between offline and online hosts apart from explicit host-only effects.

### S4 — Scale the factory and social/co-op layer

- AI factory/reviewer loop;
- second and third materially different cartridges;
- party instances;
- shared hub/social identity;
- storypack portals/embedded instances.

### S5 — Grow into the persistent MMORPG

- zone/shard authority;
- cross-shard handoff;
- selected shared-area promotion;
- realm economy/social systems/live operations;
- ongoing cartridge pipeline feeding both instanced adventures and shared regions.

The MMORPG path exists so cartridge work compounds; it must not block shipping S1/S2.

## 11. Metrics that matter

Avoid measuring factory success by raw generated word count or number of YAML files.

Track:

- **content-only ratio:** percentage of a new cartridge diff that is content/assets;
- **uncertified escape rate:** production bugs that certification should have caught;
- **quest invariant failures per simulated run**;
- **branch/state coverage** for quests/dialogue;
- **reproducibility:** percentage of failures that export a deterministic repro;
- **certification runtime and human review time**;
- **primitive reuse:** how often new content uses existing capabilities versus requiring engine work;
- **script reliance:** common script patterns that should become primitives;
- **state migration success** across cartridge/runtime versions;
- **purchase/restore reliability**;
- **completion/abandon points** and player-reported confusion after release.

The strategic factory metric is:

> Can the next good game be made mostly by composing tested capabilities and content, without making the runtime harder to reason about?

## 12. Immediate implementation order

Do **not** start a module-by-module rewrite of Lokacore.

The current order is:

1. finish and accept the v3 specification packet;
2. run the portable-kernel feasibility spike;
3. create the fresh repository only after the spike resolves provisional architecture;
4. establish strict repo/app boundaries and unified CI;
5. establish the constitutional machine-readable contracts before large feature work, while deferring exact higher-level feature schemas until the phase that implements/exercises them;
6. compile one tiny cartridge;
7. make that cartridge deterministic and crash-safe offline;
8. add quests/dialogue/living-world capabilities and the Cartridge Lab;
9. build and certify the permanent synthetic v3 conformance cartridge;
10. substantially hand-author and certify the first real offline cartridge using source/compiler/Lab, recording authoring pain;
11. generalize the canonical Builder API/MCP/terminal adapters from both conformance breadth and real authoring evidence;
12. polish the production Story shell, add commerce/entitlements, and ship the first commercial cartridge before scaling AI generation;
13. add BEAM online authority and prove host conformance, including the standing conformance cartridge as an offline-vs-BEAM differential fixture;
14. then expand factory/co-op/social/shared-world work.

The detailed R0–R22 dependency graph and gates live in [`docs/rewrite-v3/14-implementation-plan.md`](../rewrite-v3/14-implementation-plan.md).

## Related current material

This roadmap consolidates rather than deletes earlier thinking:

- [`open-product-questions.md`](open-product-questions.md) — earlier isolated-story/shared-world options;
- [`world-platform.md`](world-platform.md) — broader platform vision;
- [`../proposals/content-testing-strategy.md`](../proposals/content-testing-strategy.md) — useful precursor to cartridge certification;
- [`../architecture/unified-object-system-v2.md`](../architecture/unified-object-system-v2.md) — current entity architecture;
- [`../architecture/elixir-scripts-design.md`](../architecture/elixir-scripts-design.md) — scripting design history;
- [`../builder-reference/README.md`](../builder-reference/README.md) — current builder references;
- [`../../server/lib/loka/engine/state_machine.ex`](../../server/lib/loka/engine/state_machine.ex) — shared lifecycle primitive;
- [`../../server/lib/loka/framework/quest/progress.ex`](../../server/lib/loka/framework/quest/progress.ex) — current quest progress path;
- [`../../server/lib/loka/engine/script/sandbox.ex`](../../server/lib/loka/engine/script/sandbox.ex) — current constrained Elixir runtime.

Older documents remain historical/design context. When they disagree with this document on product sequencing, the cartridge-first sequence here is the current working direction. Before the v3 cutover, current Lokacore code remains reference reality; after R0/R2 import the accepted normative packet into the fresh v3 repository, implementation-era architecture truth lives there and Lokacore becomes provenance/archaeology rather than a second evolving specification.

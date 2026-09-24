# 16 — Architecture Decision Register

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Decision register: status varies by entry.

Accepted design direction is not R0 approval or implementation completion. Provisional and deferred decisions have separate checkpoints.

<details>
<summary>Sections in this document</summary>

- [Status vocabulary](#status-vocabulary)
- [Decision checkpoints](#decision-checkpoints)
- [ADR-001 — Clean-sheet rebuild](#adr-001--clean-sheet-rebuild)
- [ADR-002 — BEAM/OTP online runtime](#adr-002--beamotp-online-runtime)
- [ADR-003 — Offline-first single-player storypacks](#adr-003--offline-first-single-player-storypacks)
- [ADR-004 — Shared portable deterministic rules kernel](#adr-004--shared-portable-deterministic-rules-kernel)
- [ADR-005 — Mobile binding strategy](#adr-005--mobile-binding-strategy)
- [ADR-006 — PostgreSQL online, SQLite offline](#adr-006--postgresql-online-sqlite-offline)
- [ADR-007 — One online authority owner per world domain](#adr-007--one-online-authority-owner-per-world-domain)
- [ADR-008 — Definition/runtime separation](#adr-008--definitionruntime-separation)
- [ADR-009 — ActionInvocation / Command / StateDelta / DomainEvent / Effect / GameView separation](#adr-009--actioninvocation--command--statedelta--domainevent--effect--gameview-separation)
- [ADR-010 — Transactional command receipts](#adr-010--transactional-command-receipts)
- [ADR-011 — Full event sourcing](#adr-011--full-event-sourcing)
- [ADR-012 — State scopes](#adr-012--state-scopes)
- [ADR-013 — Capability registry](#adr-013--capability-registry)
- [ADR-014 — Cartridge/deployment separation](#adr-014--cartridgedeployment-separation)
- [ADR-015 — Campaign composition layer](#adr-015--campaign-composition-layer)
- [ADR-016 — ActionSet algebra](#adr-016--actionset-algebra)
- [ADR-017 — Quest reducer architecture](#adr-017--quest-reducer-architecture)
- [ADR-018 — LokaScript](#adr-018--lokascript)
- [ADR-019 — Builder API canonical authority](#adr-019--builder-api-canonical-authority)
- [ADR-020 — Visual authoring UI](#adr-020--visual-authoring-ui)
- [ADR-021 — AI runtime dependency](#adr-021--ai-runtime-dependency)
- [ADR-022 — Cartridge release artifact](#adr-022--cartridge-release-artifact)
- [ADR-023 — First monetization model](#adr-023--first-monetization-model)
- [ADR-024 — Public user-authored scripting/content marketplace](#adr-024--public-user-authored-scriptingcontent-marketplace)
- [ADR-025 — Distributed BEAM cluster](#adr-025--distributed-beam-cluster)
- [ADR-026 — Shared MMO area model](#adr-026--shared-mmo-area-model)
- [ADR-027 — Offline entitlement behavior](#adr-027--offline-entitlement-behavior)
- [ADR-028 — Database schema granularity](#adr-028--database-schema-granularity)
- [ADR-029 — Inventory relation](#adr-029--inventory-relation)
- [ADR-030 — Runtime inheritance](#adr-030--runtime-inheritance)
- [ADR-031 — Temporal model](#adr-031--temporal-model)
- [ADR-032 — First shippable milestone](#adr-032--first-shippable-milestone)
- [ADR-033 — Keep the portable kernel deliberately narrow](#adr-033--keep-the-portable-kernel-deliberately-narrow)
- [ADR-034 — Cartridge composition uses explicit ports](#adr-034--cartridge-composition-uses-explicit-ports)
- [ADR-035 — Downloaded rule representation is an App Store release gate](#adr-035--downloaded-rule-representation-is-an-app-store-release-gate)
- [ADR-036 — Prove a real cartridge before generalizing authoring tools](#adr-036--prove-a-real-cartridge-before-generalizing-authoring-tools)
- [ADR-037 — One mobile client, two strict gameplay modes](#adr-037--one-mobile-client-two-strict-gameplay-modes)
- [ADR-038 — Builder has explicit story/realm targets](#adr-038--builder-has-explicit-storyrealm-targets)
- [ADR-039 — One app simplifies entitlement UX without weakening trust](#adr-039--one-app-simplifies-entitlement-ux-without-weakening-trust)
- [ADR-040 — Quests influence the world through typed consequences](#adr-040--quests-influence-the-world-through-typed-consequences)
- [ADR-041 — Typed scoped facts coordinate narrative state](#adr-041--typed-scoped-facts-coordinate-narrative-state)
- [ADR-042 — Prefer reactive/derived world responses over quest puppeteering](#adr-042--prefer-reactivederived-world-responses-over-quest-puppeteering)
- [ADR-043 — Quest sharing uses independent dimensions](#adr-043--quest-sharing-uses-independent-dimensions)
- [ADR-044 — Prefer shared world, then overlay, then instance](#adr-044--prefer-shared-world-then-overlay-then-instance)
- [ADR-045 — Scarce services compose Capacity/Reservation/ServiceJob primitives](#adr-045--scarce-services-compose-capacityreservationservicejob-primitives)
- [ADR-046 — State scope and physical authority placement are independent](#adr-046--state-scope-and-physical-authority-placement-are-independent)
- [ADR-047 — Projection sequencing is not authority revisioning](#adr-047--projection-sequencing-is-not-authority-revisioning)
- [ADR-048 — Online owners require fencing once ownership can move](#adr-048--online-owners-require-fencing-once-ownership-can-move)
- [ADR-049 — Real-elapsed Story time enters through an idempotent authority input](#adr-049--real-elapsed-story-time-enters-through-an-idempotent-authority-input)
- [ADR-050 — Closed semantics, open composition](#adr-050--closed-semantics-open-composition)
- [ADR-051 — Target resolution, details, and coherent barriers are core world contracts](#adr-051--target-resolution-details-and-coherent-barriers-are-core-world-contracts)
- [ADR-052 — Population, reactions, and behaviors compose living-world activity](#adr-052--population-reactions-and-behaviors-compose-living-world-activity)
- [ADR-053 — Commerce is a typed composite contract](#adr-053--commerce-is-a-typed-composite-contract)
- [ADR-054 — SceneSequence is reusable narrative orchestration](#adr-054--scenesequence-is-reusable-narrative-orchestration)
- [ADR-055 — Quests are the narrative spine, not a second world authority](#adr-055--quests-are-the-narrative-spine-not-a-second-world-authority)
- [ADR-056 — Authored geography is independent from Realm authority placement](#adr-056--authored-geography-is-independent-from-realm-authority-placement)
- [ADR-057 — Scene sequencing and spatial instancing are orthogonal](#adr-057--scene-sequencing-and-spatial-instancing-are-orthogonal)
- [ADR-058 — Retry identity survives authority migration](#adr-058--retry-identity-survives-authority-migration)
- [ADR-059 — Decision output is provisional until authoritative commit](#adr-059--decision-output-is-provisional-until-authoritative-commit)
- [ADR-060 — Capability semantic residency is explicit](#adr-060--capability-semantic-residency-is-explicit)
- [ADR-061 — Conformance cartridge and first product cartridge have different jobs](#adr-061--conformance-cartridge-and-first-product-cartridge-have-different-jobs)
- [ADR-062 — Accepted v3 specification cuts over to one implementation-era authority](#adr-062--accepted-v3-specification-cuts-over-to-one-implementation-era-authority)
- [ADR-063 — Launch accounts and onboarding-only Story progress](#adr-063--launch-accounts-and-onboarding-only-story-progress)
- [ADR-064 — Approved R1 targets and explicit preparation gate](#adr-064--approved-r1-targets-and-explicit-preparation-gate)
- [ADR-065 — Precise initial composition and content evidence](#adr-065--precise-initial-composition-and-content-evidence)
- [ADR-066 — Initial run lifetime and local recovery](#adr-066--initial-run-lifetime-and-local-recovery)
- [ADR-067 — Bounded start, early representation review, no speculative expansion](#adr-067--bounded-start-early-representation-review-no-speculative-expansion)
- [ADR-068 — Candidate C first, with randomized differential testing](#adr-068--candidate-c-first-with-randomized-differential-testing)
- [ADR-069 — Adverse known answers are an eighth frozen input](#adr-069--adverse-known-answers-are-an-eighth-frozen-input)

</details>
<!-- packet-navigation:end -->

This register separates accepted direction from provisional choices that still require evidence. **Accepted** describes a design decision within this draft packet; it does not mean that R0, implementation, tests, or a release gate have passed. Read the exact Git revision and each decision's status, not the age or position of its prose.

## Status vocabulary

- **Accepted** — part of the rebuild contract unless amended.
- **Provisional** — preferred direction, but implementation must prove it before freeze.
- **Deferred** — intentionally not decided for current milestone.
- **Rejected** — explicitly not part of the v3 foundation.

## Decision checkpoints

Not every non-Accepted ADR blocks the same milestone.

- **R1 must resolve ADR-004/ADR-005** before the fresh implementation foundation depends on a portable-runtime/binding choice.
- **ADR-023** is a provisional launch business model, not a blocker for core engine architecture.
- **ADR-027** fixes the offline-ownership product principle while leaving the exact platform proof/grant mechanism to implementation evidence.
- **ADR-035** is a release gate: downloadable rule representation must be revalidated against current store policy before commercial submission.
- **ADR-024** remains deferred until public creator content is actually planned.
- **ADR-025** remains deferred until multi-node clustering is justified; R18 may prove one shared authority domain on one node, while R20 must resolve ownership placement/fencing/handoff details needed for partitioned Realm play, including migration-stable command-receipt routing from ADR-058.
- Accepted ADRs may still contain deliberately deferred implementation details, but an implementation ticket must not silently choose one when the detail affects a later normative gate.


## ADR-001 — Clean-sheet rebuild

**Status:** Accepted

Loka v3 is a new implementation from v3 contracts.

Lokacore is a reference/evidence corpus only.

No old module/API/process topology/compatibility layer is carried forward merely to accelerate delivery.

A later one-way content importer may translate selected content into v3-native schemas.

## ADR-002 — BEAM/OTP online runtime

**Status:** Accepted

Online authority is Elixir/OTP/Phoenix.

Use BEAM strengths for:

- supervision;
- process isolation;
- world/zone ownership;
- sessions;
- scheduling orchestration;
- backpressure;
- PubSub fanout;
- fault recovery.

Do not use “process per noun” by default.

## ADR-003 — Offline-first single-player storypacks

**Status:** Accepted

A downloaded offline-capable cartridge must be playable without network after acquisition/install.

Offline saves are locally authoritative for that private campaign only.

Offline competitive/economic state is not trusted as MMO authority.

## ADR-004 — Shared portable deterministic rules kernel

**Status:** Provisional

One portable deterministic semantic contract serves offline mobile and online BEAM hosts. ADR-068 tests dual implementations of it first; a single shared kernel remains a candidate.

R1 compares three candidates against a pre-registered envelope: (A) one TypeScript kernel native in React Native and reached from BEAM through a Port; (B) one Rust kernel behind a pre-registered NIF/isolated-worker BEAM boundary and native mobile bindings; (C) dual Elixir/TypeScript implementations with golden-vector conformance and randomized differential testing. ADR-068 sets the order C, then B, then A.

Must pass the R1 feasibility spike before freeze. Whichever strategy is selected, the portable semantic contract and conformance obligation are the same.

## ADR-005 — Mobile binding strategy

**Status:** Provisional

Evaluate at least:

- stable C ABI + platform wrappers;
- TurboModule/JSI generation;
- relevant Rust binding generator ecosystem.

Do not hard-depend on an early-development binding generator before production-readiness evidence.

## ADR-006 — PostgreSQL online, SQLite offline

**Status:** Accepted

Online durable state: PostgreSQL.

Offline local save: SQLite or equivalent local transactional store.

Both implement the same logical command/snapshot correctness semantics; schemas need not match physically.

## ADR-007 — One online authority owner per world domain

**Status:** Accepted

Initial online private/party world: one WorldInstance owner process.

Later shared world: zone/area shard owners.

No dual mutable authority between DB and actor state.

## ADR-008 — Definition/runtime separation

**Status:** Accepted

Immutable cartridge definitions are not runtime entity rows.

Runtime entities reference versioned DefinitionRefs.

Content keys are cartridge-qualified globally and local within cartridge authoring.

## ADR-009 — ActionInvocation / Command / StateDelta / DomainEvent / Effect / GameView separation

**Status:** Accepted

These concepts have distinct schemas and responsibilities:

- ActionInvocation is host-neutral player/agent intent from a current GameView;
- Command is the authority-constructed semantic request;
- StateDelta is proposed authoritative same-domain mutation;
- DomainEvent describes a fact produced during a decision;
- Effect crosses a post-decision/cross-authority/external boundary or requests typed follow-up work;
- GameView is the host-neutral semantic projection;
- ClientMessage is transport/presentation delivery and is not a DomainEvent.

“Event” is not a universal bucket and Effect is not a second state-write path.

## ADR-010 — Transactional command receipts

**Status:** Accepted

Retryable state-changing commands use stable IDs derived from durable/trusted authority context plus the invocation identity.

Ephemeral session/connection identity MUST NOT be part of semantic idempotency identity; the same committed invocation retried after reconnect must deduplicate.

Online commits atomically cover authoritative state + command receipt + required durable effects/outbox metadata.

Offline authority provides equivalent local commit semantics.

## ADR-011 — Full event sourcing

**Status:** Rejected

Current state/snapshots remain authoritative.

Retain enough traces for diagnostics/replay/certification, not full history replay from genesis.

## ADR-012 — State scopes

**Status:** Accepted

State explicitly belongs to:

- player;
- party;
- instance;
- realm.

This semantic scope does not by itself choose physical authority placement, visibility/audience, spatial instancing, or scarce-resource contention.

No accidental globals.

## ADR-013 — Capability registry

**Status:** Accepted

Components/actions/effects/policies/objective operators/script bindings expose machine-readable versioned contracts.

Generated/checked docs derive from this registry.

## ADR-014 — Cartridge/deployment separation

**Status:** Accepted

Cartridge = reusable story/world semantics.

Deployment = hosting policy/profile/mount/realm integration.

Shared-area promotion creates a separately certified deployment.

## ADR-015 — Campaign composition layer

**Status:** Accepted

Single-player sequels/expansions can compose cartridges through a versioned campaign manifest and explicitly exported/imported continuity state.

No arbitrary predecessor-state access.

## ADR-016 — ActionSet algebra

**Status:** Accepted

Available actions compose through:

- union;
- subtract/remove;
- intersect;
- replace;
- override.

Touch and terminal interfaces use the same action semantics.

## ADR-017 — Quest reducer architecture

**Status:** Accepted

Keep a small StateMachine lifecycle guard.

Quest progress is updated only through canonical DomainEvents -> pure reducer -> typed StateDelta/DomainEvents/Effects with explicit idempotency.

No dialogue/script direct quest-storage mutation.

## ADR-018 — LokaScript

**Status:** Deferred; direction retained

No chapter of the first cartridge (`00-first-cartridge-design.md`) needs general scripting. LokaScript is not built in R7. It is admitted only when a real cartridge presents a mechanic that ActionRecipe, ReactionRule, Policy, and quest operators cannot express, through a CapabilityProposal. If admitted, the preferred representation is a bounded declarative expression tree over registered bindings rather than a general instruction VM, to preserve the ADR-035 store posture.

If built, cartridge scripting is a restricted authoring language compiled to portable normalized AST/bytecode and interpreted by the portable rules system.

No released cartridge execution through `Code.eval_string`.

Deterministic step/query/resource budgets define script semantics. A host wall-time kill switch is defense in depth only; firing it on certified supported input is a runtime/conformance fault, not a valid cartridge branch.

Exact bytecode/AST format is implementation work.

## ADR-019 — Builder API canonical authority

**Status:** Accepted

MCP, terminal, CLI, CI, AI agents, and visual tools are adapters over one typed Builder API.

Workspace/revision context is mandatory for mutation.

## ADR-020 — Visual authoring UI

**Status:** Rejected as primary architecture

Do not build a second rich CRUD authoring application.

Use visuals primarily for:

- map;
- graph;
- trace;
- timeline;
- simulation;
- certification inspection.

## ADR-021 — AI runtime dependency

**Status:** Rejected

Released gameplay must not require Astra/Foundry/LLM inference.

AI is build/review tooling unless a future feature explicitly adds bounded optional AI gameplay.

## ADR-022 — Cartridge release artifact

**Status:** Accepted

Published releases are immutable/hash-addressed and exact-hash certified.

The canonical semantic cartridge/deployment hash covers normalized game semantics and compatibility locks, but excludes certificate/signature/catalog/download-envelope material that is created after that hash exists. Certification/signing attest the semantic hash. Exact downloadable archive bytes may additionally have a separate package/transport hash.

Existing saves remain pinned or use explicit tested migrations.

## ADR-023 — First monetization model

**Status:** Provisional product decision

Working Loka Story Mode launch model:

- one free Loka app with Story Mode available at launch;
- one free showcase cartridge;
- permanent à-la-carte cartridge unlocks;
- optional bundles later;
- subscription deferred.

Store policy/pricing details must be reverified at implementation/submission time.

## ADR-024 — Public user-authored scripting/content marketplace

**Status:** Deferred

First-party factory only for initial product.

Public creator systems require separate moderation/security/IP/product specification.

## ADR-025 — Distributed BEAM cluster

**Status:** Deferred

Initial online production may be one BEAM node + PostgreSQL.

Logical addressing/state ownership must not prevent later clustering.

## ADR-026 — Shared MMO area model

**Status:** Accepted direction

Previously released storypacks enter MMO as:

1. adventure portal/private-party instance;
2. geographically embedded instance;
3. selected shared-area promotion after multiplayer recertification.

No requirement that every private story become a globally shared area.

## ADR-027 — Offline entitlement behavior

**Status:** Accepted product principle; mechanism provisional

A legitimately purchased/downloaded permanent cartridge should remain usable offline without periodic always-online DRM.

Exact signed/local proof design depends on store/platform implementation evidence.

## ADR-028 — Database schema granularity

**Status:** Accepted direction

Prefer typed JSONB component/state payloads plus deliberately indexed/promoted columns.

Do not build generic EAV storage by default.

## ADR-029 — Inventory relation

**Status:** Accepted direction

One canonical containment relation represents item ownership/location.

Inventory lists are derived/indexed views, not a second source of truth.

## ADR-030 — Runtime inheritance

**Status:** Rejected

Source templates/mixins may compose authoring data.

Compiler flattens definitions.

Runtime does not chase deep prototype inheritance.

## ADR-031 — Temporal model

**Status:** Accepted

Classify time behavior as:

- derived/on-demand;
- durable scheduled job;
- ephemeral timer;
- world simulation scheduling.

Do not tick everything.

## ADR-032 — First shippable milestone

**Status:** Accepted

The architecture is not considered successful until it ships a polished offline story cartridge.

MMORPG infrastructure must not block that milestone.


## ADR-033 — Keep the portable kernel deliberately narrow

**Status:** Accepted

The portable kernel owns only deterministic mechanics that must be shared by offline and online cartridge execution.

Do not move online-only orchestration, networking, persistence coordination, sessions, shard ownership, admin, or commerce into Rust merely to reduce language count.

BEAM remains the online application/runtime architecture.

## ADR-034 — Cartridge composition uses explicit ports

**Status:** Accepted

Campaigns, expansions, embedded instances, and shared-area mounts compose through versioned exported ports/extension points.

Cartridge internals are private unless exported.

No ad-hoc global-key cross-cartridge coupling.

## ADR-035 — Downloaded rule representation is an App Store release gate

**Status:** Accepted risk treatment; exact representation provisional

The product requires downloadable offline storypacks, but Apple review treatment of downloadable interpreted rule content must be verified against the implementation.

LokaScript/portable rule IR should be as bounded/declarative as practical and expose only capabilities already shipped in the app.

A dedicated store-review position is required before first App Store submission.

## ADR-036 — Prove a real cartridge before generalizing authoring tools

**Status:** Accepted

After compiler/kernel/offline/narrative/living-world/Lab foundations, substantially hand-author the first real cartridge.

Use observed authoring pain to finish the canonical Builder API.

Do not delay the first game for a generalized world-building platform.


## ADR-037 — One mobile client, two strict gameplay modes

**Status:** Accepted

Loka ships one React Native / Expo application.

It contains two gameplay session modes:

- **Story Mode** — `LocalStorySession` is the UI-facing adapter over `LocalInstanceAuthority`, which owns local serialized mutation + SQLite commit through the selected portable-rules path;
- **Realm Mode** — `RemoteRealmSession` is a Phoenix transport adapter only; BEAM `WorldInstance`/`ZoneShard` owns mutation authority.

Shared UI/GameView/schema packages are reused. Authority implementations remain isolated modules with enforceable dependency boundaries.

Exactly one gameplay authority is active for a running session. Realm Mode never falls back to local authority when disconnected.

This is preferred over two store apps unless future evidence shows binary size, release cadence, store policy, branding, or operational isolation makes a split materially better.

## ADR-038 — Builder has explicit story/realm targets

**Status:** Accepted

Builder workspaces declare target:

- `story` — portable/offline capability set and offline certification;
- `realm` — online multiplayer capability set, including server-only systems;
- `promote` — explicit adaptation of an existing story cartridge into an online deployment.

These are **authority/content targets, not app targets**.

A workspace cannot silently cross target boundaries.

## ADR-039 — One app simplifies entitlement UX without weakening trust

**Status:** Accepted product boundary; future reward policy provisional

Story purchase/library and Realm entry live in one app and may share one authenticated Loka account when online.

However:

- Story Mode may remain playable offline without an active account session after legitimate acquisition;
- local save contents and local entitlement flags never become authoritative Realm progression/economy state;
- Realm unlocks/benefits derived from ownership require explicit server-side verified product rules.

One app simplifies discovery, restore, branding, and account linking; it does not merge the authority models.


## ADR-040 — Quests influence the world through typed consequences

**Status:** Accepted

Quest Runtime observes canonical DomainEvents and owns quest-specific scoped state.

Quest outcomes may affect the world only through registered capability consequence operators that return typed StateDelta/DomainEvents/Effects.

Quests do not receive arbitrary component/database write access.

Same-authority quest/world changes should commit atomically in one decision. Cross-authority Realm consequences use durable idempotent protocols.

## ADR-041 — Typed scoped facts coordinate narrative state

**Status:** Accepted

Durable truths needed by multiple world systems use namespaced, typed, scoped FactSpecs rather than ad-hoc string flags.

Examples include:

- bridge repaired;
- child rescued/dead;
- town faction control;
- player allegiance;
- festival state.

World systems may derive behavior, descriptions, dialogue, access, spawn rules, and follow-up content from facts.

Components remain the home for entity-owned mechanical state such as HP/location.

## ADR-042 — Prefer reactive/derived world responses over quest puppeteering

**Status:** Accepted

When many systems should respond to an outcome, the quest SHOULD set a shared fact or emit a typed DomainEvent and let registered world rules/policies/behaviors respond.

Direct consequences are preferred for local mechanical changes such as opening one gate, spawning one encounter, or granting one item.

This is intended to produce coherent living-world reactions while keeping quest definitions decoupled from subsystem internals.


## ADR-043 — Quest sharing uses independent dimensions

**Status:** Accepted

Multiplayer quest design does not use one instanced/shared boolean.

Progress scope, consequence scope, presence audience, spatial placement, and scarce-resource capacity are independent contracts.

This permits combinations such as personal quest progress with a shared NPC and shared smithy, plus a private phased apparition and later private dungeon.

## ADR-044 — Prefer shared world, then overlay, then instance

**Status:** Accepted

For Realm content, prefer the least-isolated model that preserves correctness:

1. shared world + personal progress;
2. shared world + scoped overlay/phasing;
3. private/party instance;
4. Realm-wide mutation only when intentionally public.

Personal dialogue alone is not a reason to clone an NPC or zone.

## ADR-045 — Scarce services compose Capacity/Reservation/ServiceJob primitives

**Status:** Accepted

Shared bottlenecks are modeled by reusable Service capabilities composed from CapacityPolicy, Reservation/QueuePolicy, optional Escrow, DurationPolicy, CompletionRule, OutputPolicy, and durable ServiceJobs—not by quest-specific timers.

The owning mutation authority owns queueing/reservations, escrow where used, capacity allocation, duration, and completion for the service aggregate.

When inputs/capacity share one mutation authority, allocation + escrow + ServiceJob creation commit atomically. When custody crosses authorities, use an explicit durable idempotent reservation/transfer/reconciliation protocol rather than pretending PostgreSQL creates one distributed authority.

Service period/window policies declare their time basis and boundary/anchor semantics; “per day” is not allowed to inherit device/server local-midnight behavior implicitly.

A service/provider is a domain aggregate, not automatically a dedicated OTP process. Quests observe typed ServiceJob DomainEvents and remain independently scoped.

## ADR-046 — State scope and physical authority placement are independent

**Status:** Accepted

Player/party/instance/realm StateScope describes semantic ownership of gameplay truth.

It does not imply a process/table placement strategy. A shared Realm may route player- or party-scoped state across zone boundaries without making the current ZoneShard its permanent owner.

The exact placement/routing strategy for long-lived cross-zone player/party state must be resolved and certified before multi-zone Realm milestones depend on it.

Logical world/context identity and current mutation-owner placement identity MUST be nominally distinct in schemas/APIs. A logical `instance_id`/Realm identity may not silently double as the current ZoneShard/authority-domain/fencing identity once ownership can move.

## ADR-047 — Projection sequencing is not authority revisioning

**Status:** Accepted

Realm clients order projected GameView updates with a client/subscription projection sequence and may send an opaque view-freshness token with ActionInvocation.

WorldInstance/ZoneShard revisions remain internal authority commit/concurrency tokens.

A busy shared zone may mutate without changing a given player's view, and one mutation may yield several projection messages. Therefore client gap detection MUST NOT assume a one-to-one mapping to authority revision.

## ADR-048 — Online owners require fencing once ownership can move

**Status:** Accepted

When restart overlap, failover, clustering, or operational error could leave more than one process believing it owns the same durable authority domain, persistence commits must validate an ownership/fencing generation or equivalently strong token in addition to ordinary state revisions.

A stale owner cannot resume authoritative writes merely because its data revision appears current.

## ADR-049 — Real-elapsed Story time enters through an idempotent authority input

**Status:** Accepted

For offline cartridges that use real-elapsed time, device wall time is sampled/clamped according to product policy and converted into an explicit resume-time advancement input.

That input follows the normal deterministic decision/commit path and is idempotent across crash/retry.

Systems in hybrid time mode declare their time basis; they do not read wall clock directly from game rules.


## ADR-050 — Closed semantics, open composition

**Status:** Accepted

Loka maximizes builder expressive power through layered composition of registered semantics.

Builders may define and compose facts/events, policies/selectors, Actions/ActionRecipes, ReactionRules, Behaviors, state machines, population plans, commerce/services, scenes, quests, world events, templates, and bounded LokaScript.

Cartridge content cannot introduce arbitrary persistence writes, host callbacks, unregistered mutation/effect types, or a second authority model.

The normative layer map and primitive-graduation rule are in document 21.

## ADR-051 — Target resolution, details, and coherent barriers are core world contracts

**Status:** Accepted direction

Target resolution is deterministic and action-declared, returning none/unique/ambiguous rather than random/source-order choice.

InspectableDetail provides lightweight targetable descriptive world detail without forcing RuntimeEntity identity.

Two faces of one logical door/gate/bridge should share one authoritative Barrier state unless explicitly authored as independent/asymmetric connections.

## ADR-052 — Population, reactions, and behaviors compose living-world activity

**Status:** Accepted direction

SpawnBundle explicitly defines nested spawn composition.

PopulationPlan owns bounded population/replenishment/cleanup through explicit provenance and scope; it does not destructively reset unrelated world state.

ReactionRule is the safe builder-composable replacement for arbitrary special-procedure callbacks: typed trigger + selector + Policy + registered consequences.

Autonomous Behaviors produce typed intents and use deterministic registered arbitration rather than content-source ordering.

## ADR-053 — Commerce is a typed composite contract

**Status:** Accepted direction

Immediate merchant trade composes provider, catalog/stock, price/payment, buy/sell admission, liquidity, restock, schedule, and narration semantics and commits transfers atomically within one mutation authority.

Long-running/scarce work continues to use Service/Capacity/Reservation/ServiceJob primitives.

Merchant NPC code is not a special-case transaction engine.

## ADR-054 — SceneSequence is reusable narrative orchestration

**Status:** Accepted direction

Text cutscenes, dreams, visions, ceremonies, staged conversations, and other authored sequences use typed SceneDefinition/SceneInstance semantics.

Consequential scenes are durable/idempotent, resume safely, use normal ActionSet/authority validation, and may mutate the world only through registered consequences.

Dream/private scene state is isolated; only explicitly declared exports/consequences cross back to ordinary world state.

## ADR-055 — Quests are the narrative spine, not a second world authority

**Status:** Accepted

Quests are the primary authored thread carrying story through exploration, dialogue, scenes, world events, and durable consequences.

Quest Runtime owns quest-specific progress/branch state and observes canonical DomainEvents.

It coordinates the living world through typed facts, SceneSequences, named outcomes, and registered consequences rather than generic component/database writes.

## ADR-056 — Authored geography is independent from Realm authority placement

**Status:** Accepted

AreaDefinition groups authored geography/content for maps, population, environment, and certification.

ZoneShard/WorldInstance describes runtime mutation ownership.

The two concepts are not aliases and future partitioning may map them many-to-one or one-to-many.


## ADR-057 — Scene sequencing and spatial instancing are orthogonal

**Status:** Accepted direction

SceneSequence owns ordered narrative orchestration, waiting, choices, checkpoints and
scene outcomes.

InstancePlan owns scoped spatial simulation instantiated from precompiled definitions,
including participant/admission, entry/exit, population, persistence/reconnect/reset and
teardown policy.

Dreams, visions and flashbacks are content compositions over these primitives:

- presentation-only/current-world SceneSequence;
- SceneSequence + scoped overlay;
- SceneSequence + InstancePlan for fully interactive temporary worlds.

The same InstancePlan primitive serves private dungeons, party puzzles, tutorials,
ritual/trial spaces and other instanced gameplay. There is no separate DreamEngine.

## ADR-058 — Retry identity survives authority migration

**Status:** Accepted

Client-visible mutation idempotency is keyed by a stable logical gameplay lineage + invocation identity, not by the current session, process, shard, or other mutation-owner placement.

If a command commits and ownership moves before its acknowledgement is observed, a retry after handoff MUST discover/replay the original receipt rather than execute under a fresh destination-owner namespace. Receipt access is authenticated before lookup; matching invocation intent is recognized BEFORE current-world action/freshness validation. The original resolved command and semantic outcome are retained, not re-derived from changed state (03 §14).

R20 chooses the concrete durable mechanism—realm-level receipt index, receipt migration, forwarding/tombstones, or an equivalently strong design—but may not weaken this semantic invariant.

## ADR-059 — Decision output is provisional until authoritative commit

**Status:** Accepted

StateDelta, generated DomainEvents, Effects, RNG/logical-time advancement, and projection hints produced during decision evaluation are proposals until the owning authority successfully commits them.

Proposed DomainEvents may drive deterministic in-decision reducers, but they MUST NOT escape through PubSub, client transport, external workers, or another authority as committed facts before persistence succeeds.

StateDelta composition uses registered typed operations, deterministic proposal-overlay ordering, canonical mutation targets, and explicit conflict/composition rules. Implicit authoritative last-writer-wins behavior is rejected.

A rejected decision or definitive transaction rollback discards the entire proposal. An admitted failed roll is a committed attempt, not a rejection; unknown commit outcomes require durable reconciliation before reevaluation (03 §15; 04 §5.0).

## ADR-060 — Capability semantic residency is explicit

**Status:** Accepted

Capability portability and implementation residency are tracked explicitly enough to show where semantic evaluators execute and which host adapters/conformance fixtures cover them.

The residency view distinguishes portable semantics, Realm-only pure semantic evaluators, authority-host coordination, client presentation, and authoring/certification responsibilities.

This prevents portable-kernel creep into BEAM-native orchestration and prevents offline-required rules from hiding in host-specific implementations without parity evidence.

## ADR-061 — Conformance cartridge and first product cartridge have different jobs

**Status:** Accepted

Before the first commercial-quality Story cartridge, v3 maintains a small synthetic conformance cartridge designed to exercise broad architectural interactions, deterministic regressions, fault cases, and invariant sensitivity.

The first real Story cartridge is optimized for a coherent player experience and authoring evidence. It is not required to include every available primitive solely to exercise architecture.

R11 Builder generalization uses evidence from both: synthetic breadth from the conformance cartridge and real authoring/usability pain from the product cartridge.

## ADR-062 — Accepted v3 specification cuts over to one implementation-era authority

**Status:** Accepted

R0 records the exact accepted normative specification commit/file set. R2 imports that accepted contract into the fresh v3 implementation repository.

After cutover, implementation-era architecture amendments occur in the fresh repository through reviewed spec/ADR changes. Lokacore remains a read-only archaeology/reference corpus and MUST NOT evolve as a second normative specification.

Normative implementation docs should be physically separated from historical review/research/reference material so humans and agents cannot mistake evidence for peer architectural authority.

## ADR-063 — Launch accounts and onboarding-only Story progress

**Status:** Accepted product direction by owner, 2026-09-22; implementation and R0 evidence pending.

The first public Story release includes accounts and durable account-level completion tracking. Local milestone/pending-report capture is atomic with gameplay; later authenticated synchronization records evidence-labeled platform acceptance. Installed Story play does not require a live login or network. Account is not a new gameplay scope.

Designated offline-client reports can satisfy account-wide prologue prerequisites under server-owned admission policy. They do not prove human comprehension and cannot grant currency, inventory, statistics, purchase entitlement or competitive Realm rewards. Requirement IDs are stable and map to approved release/milestone alternatives; a client cannot grant itself access. Both intended completed endings qualify by default.

R12A brings the minimal account/platform database and progress API before the first free public release. R13 extends it with commerce; R14/R15 enforce actual Realm admission. R6P uses a fake sync adapter, not production identity. See [document 23](23-accounts-progress-admission.md) and ACCOUNT-01–12 for binding, deletion, idempotency and multi-device semantics. Mandatory sign-in before first acquisition versus guest-first UX is not decided by this ADR; after acquisition, installed offline play remains guaranteed under its entitlement policy.

## ADR-064 — Approved R1 targets and explicit preparation gate

**Status:** Owner-approved readiness direction, 2026-09-22; amendment review/merge, setup freeze, independent oracle review and R1 measurements remain pending.

The 2026-09-23 owner-approved sequencing amendment uses envelope v0.4, and v0.5 adds only an A1-only hosted execution-host row (§4): numerical ceilings are unchanged, but accepted contract, exact inputs, independent oracle and reproducible A1 execution-setup review precede stateless semantics; complete native locks, physical phones, common host and new A2 setup review precede integration. A1 approval cannot be relabeled A2. Under the owner's delegated target choice, initial iOS qualification is iPhone 11/4 GB instead of SE 2/3 GB, with no claim that the earlier RAM class passed. Android A14/4 GB remains pending exact Pixel inventory/substitution; Palma 2 is supplementary. Expo previews and emulators are permitted development tools, not qualification evidence. The candidate order is set by ADR-068. No candidate is selected before its gates pass. R0 acceptance and R2 production cutover remain separate. See `r1-work-package.md` and the retained owner instruction.

## ADR-065 — Precise initial composition and content evidence

**Status:** Owner-approved readiness direction, 2026-09-22; executable specification examples, not measured engine evidence.

04 §5.2–5.5 defines root sequence then FIFO proposed-event dispatch, emission-time subscription eligibility, current-overlay guards, explicit writer groups/conflicts, aggregate validation and bounded durable waiting. 05/06/08 supply operation ownership, source maps, objective/continuation and author explanations. Only the admitted subset is frozen; do not create a general theorem prover, scripting language or future capability catalog for R1.

The Ferryman's Lantern uses a current-possession objective to support finding the lantern before accepting. Both choices resolve the quest with different typed outcomes; actual custody/presence is checked at each NEW choice. Tiny's strict acquisition-event case stays unchanged. Conformance cases are extended, never replaced by candidate-generated expectations.

## ADR-066 — Initial run lifetime and local recovery

**Status:** Owner-approved product/readiness direction, 2026-09-22; implementation and release evidence pending.

Story defaults to action-driven time, durable accepted-attempt autosave, three manual bookmarks and exact release/capability pins. Valid public v3 saves remain openable on supported environments through compatibility or certified rollback-safe local migration; no rolling latest-two-app expiration. Old-branch continuation creates explicit lineage; receipt/crash recovery does not. Campaign branch choice is independent of account completion.

Manual bounded export/import is part of R12's first public release. Whole-save cloud backup remains optional later, separate from mandatory R12A progress sync and not a new hard R13 gate. Support/end-of-service promises are published before paid launch without promising perpetual new-platform or store availability. See 10 §31–33 and 23 §11.

## ADR-067 — Bounded start, early representation review, no speculative expansion

**Status:** Owner-approved sequencing direction, 2026-09-22; R0 acceptance not asserted.

Close the readiness checklist, freeze oracles/A1 execution setup then native/physical setup at A2, run disposable R1, then R2 and the minimal production slices leading to R6P. Full chapter one remains 57 rooms, 10 quests and two endings. No production engine work in legacy Lokacore; no generalized Builder/Foundry/Realm/scripting/proof-language prerequisite. Begin exact downloadable-representation review alongside R1 and resolve its investment risk before scaling production content; retain current-policy/exact-app review before the first public store release. A green portability or model test is not store approval.

## ADR-068 — Candidate C first, with randomized differential testing

**Status:** Owner-approved sequencing direction, 2026-09-23; amendment review, R0 acceptance and R1 measurements pending.

The owner wants the online server to stay a single Elixir/OTP runtime, without a Node process beside the BEAM. R1 therefore tests C first: pure Elixir online and TypeScript on the phone, held to one semantic schema, the reviewed known-answer fixtures and randomized differential testing (`r1-acceptance-envelope.md` §3). If C fails a MUST row, evaluate B, a single Rust kernel with a declared BEAM boundary; if B fails, evaluate A. Numerical ceilings, stages and preparation gates are unchanged.

A 2026-09-23 feasibility probe (`probes/elixir-wasm/`, not R1 evidence) found that the Hermes version in the retained lock has no WebAssembly, SharedArrayBuffer, Atomics or Worker, so an Elixir kernel cannot run in React Native's engine; the hidden-WebView alternative was declined by the owner. C accepts permanent two-implementation maintenance; differential testing and shared fixtures are its drift control, not a proof of correctness.

## ADR-069 — Adverse known answers are an eighth frozen input

**Status:** Proposed amendment to the accepted R0 contract `aaadaffff02e459dbf04e71d6ddc81d75eacf986`, 2026-09-23, chosen by the owner after the independent oracle review; expected-answer review and owner acceptance pending.

The oracle review of the seven inputs (`reviews/2026-09-23-oracle-review.md`, finding F1) found that they freeze only success paths. Failed checks, rejections, conflicts, stale views, rollback, unknown COMMIT, response loss, budgets, bounds, rejection sampling and the adverse Lantern paths existed only as Python assertions, which no input hash binds; a candidate that restores the RNG after a failed check passed every frozen fixture. `conformance/adverse-cases.json` now freezes those answers as data, in the existing `cases.json`, `composition-cases.json` and `lantern-traces.json` shapes, and becomes the eighth input bound by both readiness checkers, the setup and oracle records and `spec_tools/preserved-inputs.json`. It records what the retained checks already asserted, plus two rejection-sampling rows the review verified independently; it adds no contract behavior. The review of those bytes (`reviews/2026-09-23-oracle-review-adverse.md`, A1) found the model checked authorization before envelope validation, against 03 §14; the model and the one affected answer (`bad-envelopes`, request `{}` → `invalid_envelope`) were corrected before approval. Publication is frozen only where the contract requires it (nothing before COMMIT, no duplicate on response loss), because document 04 §2 permits but does not require fan-out of committed events after recovery. Selector overflow stays a model-level check: no registered operation reaches it.

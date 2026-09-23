# 02 — BEAM Runtime Architecture

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: online host.

Account/progress service arrives at R12A; gameplay hosting at R14. Review ownership and recovery without pulling shared-world work forward.

<details>
<summary>Sections in this document</summary>

- [1. Proposed repository shape](#1-proposed-repository-shape)
- [2. Supervision topology](#2-supervision-topology)
- [3. Offline versus online authority](#3-offline-versus-online-authority)
- [4. Session, account, character, instance](#4-session-account-character-instance)
- [5. Online private/party world owner](#5-online-privateparty-world-owner)
- [6. Why not one GenServer per entity by default](#6-why-not-one-genserver-per-entity-by-default)
- [7. Shared MUD evolution](#7-shared-mud-evolution)
- [8. BEAM distribution](#8-beam-distribution)
- [9. Gateway/runtime separation](#9-gatewayruntime-separation)
- [10. Restart behavior](#10-restart-behavior)
- [11. Schedulers: use three temporal strategies](#11-schedulers-use-three-temporal-strategies)
- [12. Backpressure and overload](#12-backpressure-and-overload)
- [13. BEAM-specific review questions](#13-beam-specific-review-questions)
- [14. Early platform service is not early Realm simulation](#14-early-platform-service-is-not-early-realm-simulation)

</details>
<!-- packet-navigation:end -->

## 1. Proposed repository shape

Use a Mix umbrella to make dependency direction mechanically obvious.

```text
loka/
├── apps/
│   ├── loka_core/       # pure domain types/rules/capability contracts
│   ├── loka_content/    # cartridge parsing/compiler/definition registry
│   ├── loka_store/      # Ecto/PostgreSQL persistence adapters
│   ├── loka_platform/   # accounts, catalog, entitlements, purchase/restore services
│   ├── loka_runtime/    # OTP world/session/scheduling authority
│   ├── loka_builder/    # workspaces, Builder API, lab, certification
│   └── loka_web/        # Phoenix HTTP/channels/admin/MCP adapter
├── kernel/              # portable rules implementation (language and boundary selected by R1)
├── mobile/              # React Native / Expo + local authority/persistence
├── protocol/            # external machine-readable schemas/codegen
├── cartridges/          # first-party source cartridges in development
└── docs/
```

This exact split MAY be adjusted after a compile-dependency spike, but dependency rules are normative:

- `loka_core` depends only on portable/domain contracts and the narrow portable-rules adapter/port selected by R1.
- `loka_content` depends on `loka_core`; it owns compile-time cartridge definitions/registries, not runtime authority.
- `loka_store` depends on `loka_core`; it implements persistence ports and contains no game rules.
- `loka_platform` depends on `loka_core` plus persistence/platform adapters; it owns account/catalog/entitlement/purchase-restore application rules, not world simulation.
- `loka_runtime` depends on `loka_core`, `loka_content`, and persistence ports; it owns online world/session/scheduler authority.
- `loka_builder` depends on content/compiler/Lab contracts and may orchestrate runtime test hosts; production runtime MUST NOT depend on builder.
- `loka_web` depends inward on application/runtime/builder interfaces and is an external transport adapter only.

`loka_core` MUST NOT depend on Phoenix, Ecto, filesystem, network, or runtime processes. Portable rule semantics that must execute offline MUST cross the narrow portable-rules port selected by R1; whether that port reaches one shared native implementation or a conformant host implementation is an implementation decision, not a domain dependency.

`loka_store` may depend on core/domain data contracts but MUST NOT contain game rules.

`loka_platform` MUST NOT own world simulation or cartridge mechanics.

`loka_web` MUST NOT become a source of game or commerce truth.

Boundary enforcement SHOULD use separate umbrella apps plus compile-time boundary checks/tests.

## 2. Supervision topology

Draft topology:

```text
Loka.Runtime.Supervisor
├── SessionRegistry
├── SessionSupervisor
│   └── SessionProcess[player/session]
├── InstanceRegistry
├── InstanceSupervisor
│   └── WorldInstance[instance_id]
├── RealmSupervisor               # dormant/limited before shared-world phase
│   └── RealmCoordinator
│       └── ZoneShard[zone_id]
├── SchedulerSupervisor
│   ├── DurableJobScheduler
│   └── EphemeralTimerScheduler
└── EffectSupervisor
    └── EffectDispatcher workers
```

All dynamic processes MUST be addressable by stable IDs through Registries rather than hidden process dictionary conventions.

## 3. Offline versus online authority

The BEAM runtime described in this document is the **online authority host**. Offline private cartridges use a local authority shell and the same portable semantic contract through the R1-selected implementation strategy, as specified in [07 — Offline Storypacks and the Path to the MMORPG](07-offline-storypacks-to-mmo.md).

Do not attempt to embed a BEAM node in the mobile app merely to preserve architectural symmetry.

## 4. Session, account, character, instance

Keep these concepts separate.

```text
Client connection
      |
   Session
      |
   Account
      |
  Character
      |
 World Instance / Realm
```

### Session

Connection-local and ephemeral:

- socket/session ID;
- device/client metadata;
- last acknowledged protocol sequence;
- UI-specific ephemeral state where appropriate;
- currently controlled character;
- reconnect bookkeeping.

Session state MUST NOT contain irreplaceable quest/inventory/world state.

An account MAY have multiple sessions later.

### Account

Durable identity:

- authentication;
- entitlements;
- account settings;
- account-level moderation/permissions.

### Character

Durable game identity:

- stats/progression intended to survive cartridges where product rules allow;
- cosmetics/profile;
- world membership;
- cartridge-local character snapshot refs.

### World instance

Authority for one private or party play space:

- cartridge release ref;
- logical clock;
- explicit RNG state/seed;
- runtime entities;
- scoped world variables;
- scheduled game jobs;
- instance revision.

## 5. Online private/party world owner

For online private/party cartridges, one `WorldInstance` GenServer SHOULD own the mutable in-memory state of the instance.

Why:

- player commands become naturally serialized;
- multi-entity operations inside an instance are easier to make atomic;
- deterministic simulation is straightforward;
- snapshot/replay has one coordination boundary;
- NPC schedules can be managed collectively;
- a crashed instance can reload from durable state.

The instance process routes commands through the shared DecisionCoordinator. Portable rules execute through the R1-selected portable-rules implementation/adapter; server-only Realm capabilities execute as pure Elixir rule evaluators. Both return typed StateDelta/DomainEvent/Effect proposals into the same decision and commit boundary. Neither path may persist directly.

It SHOULD NOT block on slow external I/O while holding command serialization. Persistence commits should be bounded and synchronous where correctness requires; non-authoritative notifications are effects.

### Action/command lifecycle

```text
1 client ActionInvocation arrives
2 gateway authenticates + validates transport/protocol
3 invocation is routed to the owning WorldInstance/ZoneShard
4 authority verifies actor/receipt access and trusted logical retry identity
5 matching intent replays its stored outcome BEFORE current ActionSet/freshness checks;
  only NEW invocations resolve current actions/targets and construct the typed Command
6 DecisionCoordinator evaluates portable + server-only rules into one proposal
7 store transaction commits affected durable records + command receipt + effect outbox
8 in-memory state advances to committed revision
9 response/projection notifications are emitted
10 durable outbox effects are dispatched/retried
```

The exact transaction strategy may batch entity changes, but step 7 must prevent a crash from producing half a logical action. The transaction rechecks the receipt/unique identity. An uncertain COMMIT fences new decisions until durable reconciliation; see document 03 §§14–15. A replay returns its historical outcome without replacing the current GameView.

## 6. Why not one GenServer per entity by default

Lokacore's entity-process approach provides useful isolation but makes operations like “move item from room to inventory and advance quest” cross multiple authorities.

A v3 item usually does not need independent concurrency.

Use a process per entity only when an entity truly owns concurrent autonomous work that cannot cleanly belong to its world shard. Such exceptions MUST be justified.

NPC autonomous behavior SHOULD usually be scheduled as commands/events to the world owner, not a permanently ticking process per NPC.

## 7. Shared MUD evolution

Do not distribute the private-instance architecture prematurely.

When a persistent realm needs more concurrency, partition by **ownership domain**, likely zone/area.

```text
RealmCoordinator
  ├── ZoneShard(town)
  ├── ZoneShard(forest)
  ├── ZoneShard(dungeon-1)
  └── SharedServices(economy/guilds/etc)
```

An entity belongs to one shard at a time.

Cross-shard movement MUST use an explicit handoff protocol:

1. source validates move;
2. durable transfer intent is recorded;
3. destination accepts/imports entity state;
4. ownership pointer commits;
5. command-receipt/idempotency continuity is preserved so a lost-response retry cannot become fresh work merely because routing now reaches the destination owner;
6. source removes local authority;
7. recovery reconciles incomplete transfers.

Do not rely on “send two PubSub messages and hope.”

### Shared online services are authorities too

Realm-wide services such as guild banks, auctions, mail, global economy ledgers, or social organizations own their own durable state domains.

A ZoneShard MUST NOT mutate another service's authoritative tables/state directly.

Cross-authority operations use explicit idempotent protocols—transfer intent, command receipt, outbox/saga/reconciliation as appropriate—so a crash cannot leave both authorities believing they own or transferred the same value.

Avoid distributed transactions as an implicit design assumption. Each authority commits its own state and participates in a recoverable protocol with traceable causation.

## 8. BEAM distribution

Initial production SHOULD run on one BEAM node plus PostgreSQL unless measured scale requires clustering.

The architecture MUST avoid assumptions that prevent later clustering:

- IDs are global UUIDs;
- Registries have an adapter boundary;
- world owners are addressed by logical IDs;
- persistent state is not stored only in local ETS;
- effects and jobs are durable when required.

Do not add Horde/Swarm/distributed Registry solely because BEAM clustering is possible.

## 9. Gateway/runtime separation

Borrow the **principle**, not the literal implementation, of a network-facing portal separate from game logic.

`loka_web` owns:

- HTTP;
- WebSocket/Phoenix channels;
- authentication;
- protocol validation;
- rate limiting;
- transport serialization.

`loka_runtime` owns:

- sessions as game-facing abstractions;
- world authority;
- commands;
- scheduling;
- durable gameplay coordination.

A production deploy MAY later split gateway and runtime into different releases/nodes, but the first implementation SHOULD keep them in one deployment unless operational evidence justifies separation.

## 10. Restart behavior

WorldInstance restart:

1. supervisor restarts process;
2. process loads last committed state/snapshot and pending durable jobs;
3. it verifies command/effect receipts;
4. it reconstructs explicit RNG/logical-clock state;
5. it resumes.

A client may receive a transient retry/resync response. It MUST NOT observe duplicated durable rewards.

## 11. Schedulers: use three temporal strategies

Do not use one timer mechanism for every feature.

### A. Derived/on-demand temporal state

For states whose intermediate stages have no side effects:

- plant growth;
- cooldown remaining;
- decay stage;
- shop “currently open?” if no transition action is needed.

Store `state_at_t0` + logical timestamp and derive current state when queried.

This avoids unnecessary ticks.

### B. Durable scheduled jobs

For events that MUST happen even across restart:

- quest deadline consequence;
- auction/market settlement;
- paid construction completion;
- scheduled world event with side effects.

Persist job identity, explicit `time_basis`, due value, payload, status, and idempotency key.

The time basis is part of job semantics (for example logical play time, accepted real-elapsed Story time, or an authoritative Realm/service clock). A job processor must not infer its clock source from host environment or deployment mode.

### C. Ephemeral timers

For disposable local behavior:

- short combat timeout;
- animation/UI pacing;
- ambient emote cadence.

These may be recreated after restart rather than persisted.

## 12. Backpressure and overload

Every externally reachable command path SHOULD have bounded queues/rate limits.

World owners SHOULD expose telemetry for:

- mailbox length;
- command latency;
- commit latency;
- commands/sec;
- effect backlog;
- scheduled-job backlog.

If an instance is overloaded, the gateway should reject/throttle new non-critical commands rather than allowing unbounded mailbox growth.

## 13. BEAM-specific review questions

Every proposed process must answer:

- What state does it exclusively own?
- Why does this state require independent concurrency?
- What supervisor restarts it?
- How is state recovered?
- What messages can it receive?
- What is its mailbox/backpressure policy?
- What happens if it crashes between decision and effect?
- Can this be a pure module instead?

If the last answer is yes, prefer the pure module.

## 14. Early platform service is not early Realm simulation

R12A introduces the account lifecycle and Story progress service before the first public Story release, reusing the `loka_platform` boundary and PostgreSQL. R13 adds commerce to that foundation; R14 later adds WorldInstance gameplay hosting. Authentication, accepted account milestones and Realm admission policy never execute inside the portable rules kernel. Account/profile binding is host metadata. See [document 23](23-accounts-progress-admission.md).

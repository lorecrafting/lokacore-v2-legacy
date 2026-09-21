# 04 — Action Invocations, Commands, State Deltas, Domain Events, Effects, and Client Protocol

## 1. Six concepts, six responsibilities

Loka v3 MUST distinguish:

### ActionInvocation

A host-neutral gameplay intent emitted by shared UI, text parsing, bots, or accessibility tooling from a currently advertised GameView action.

Example:

```json
{
  "invocation_id": "uuid",
  "action_key": "talk",
  "actor_id": "uuid",
  "target_ids": ["uuid"],
  "input": {},
  "view_freshness_token": "view-token-9201"
}
```

An ActionInvocation is **not yet an authoritative Command**.

- Story Mode: `LocalStorySession` forwards the invocation to `LocalInstanceAuthority`; the local mutation owner resolves/revalidates it against committed local state and constructs the typed Command.
- Realm Mode: `RemoteRealmSession` sends the invocation to BEAM; the server mutation owner re-resolves/revalidates the advertised action and constructs the typed Command.

The shared renderer MUST NOT construct authority-specific command payloads.

### Command

An authority-side typed request to change/inspect game state.

Commands have two allowed origin classes:

1. **invocation-derived** — produced after a player/agent ActionInvocation is authenticated, re-resolved, and revalidated;
2. **authority-internal** — produced by trusted world machinery such as a durable scheduler/job, selected BehaviorIntent, PopulationPlan reconciliation, or WorldEventPlan transition.

Authority-internal Commands MUST:

- use registered typed Command variants;
- carry stable causation/idempotency identity;
- be reconstructible/retryable where durable;
- pass through the same pure decision, invariant, StateDelta/DomainEvent/Effect, and commit contracts;
- never be directly constructible by an untrusted client as a way to skip ActionInvocation validation.

Examples:

- move north;
- take item;
- choose dialogue option;
- attack NPC;
- buy item;
- accept quest;
- execute a due ServiceJob completion;
- reconcile a PopulationPlan;
- advance an autonomous NPC behavior intent.

### StateDelta

A typed, non-committed proposal describing authoritative state changes inside the current mutation authority.

Examples:

- move an entity between containers;
- update a typed fact;
- advance a QuestInstance;
- create a same-authority ServiceJob or scheduled job.

StateDelta is produced by pure decision logic and becomes authoritative only after the host commit succeeds. It is not a transport message and not an Effect.

### Domain Event

A typed fact emitted by deterministic decision evaluation and made externally true only when the enclosing authoritative commit succeeds.

Examples:

- entity_entered_room;
- item_acquired;
- npc_killed;
- dialogue_node_reached;
- quest_objective_completed.

Events explain what happened and drive other deterministic rules.

### Effect

An instruction produced by a decision that must be applied/executed.

Examples:

- wake/notify a scheduler after a durable job was committed;
- emit an ephemeral client notification;
- enqueue an external push;
- request an idempotent cross-authority entity transfer.

Authoritative same-domain changes—including creation of a durable scheduled-job record owned by the current authority—belong in StateDelta/commit data. Effects are not a second backdoor to mutate arbitrary state.

### Client Message

A transport-facing projection.

Examples:

- room_snapshot;
- entity_actions_changed;
- dialogue_view;
- combat_update;
- quest_update;
- toast/narrative line.

Client messages are not domain events.

## 2. Action invocation and command semantics

Portable gameplay may resolve to the same logical Command types offline and online, but shared mobile UI speaks **ActionInvocation**, not internal Command structs.

The ActionSet/GameView is the affordance contract: it advertises valid action keys, target/input schema, labels, and relevant presentation hints.

Authority always revalidates because the GameView can be stale.

### External Realm gameplay envelope

```json
{
  "protocol_version": 3,
  "client_seq": 184,
  "session_id": "uuid",
  "instance_id": "uuid",
  "invocation": {
    "invocation_id": "uuid",
    "action_key": "move",
    "actor_id": "uuid",
    "target_ids": [],
    "input": {"direction": "north"},
    "view_freshness_token": "view-token-9201"
  }
}
```

The gateway supplies authenticated account/session identity; the client cannot claim arbitrary actor authority. The server verifies the invocation actor is controllable by that session and re-resolves the action against current state. The logical idempotency scope is derived from trusted Story/Realm lineage and controlled-actor context, not from an untrusted client-selected routing/owner identifier.

`invocation_id` is the client-visible stable retry identity used to derive/recover semantic Command idempotency. `client_seq` is a transport/order diagnostic and MUST NOT become mutation identity; it may restart after reconnect according to protocol rules. `view_freshness_token` is an opaque view-freshness token, not a promise that the client knows the authority's database revision.

The server then creates or recovers the internal Command ID/idempotency identity. The invocation ID is retained for client retry/correlation.

## 3. Canonical command representation

After Realm invocation validation/action resolution—or Story local invocation resolution—the authority host constructs a **semantic Command** plus host-only execution metadata.

```elixir
%Command{
  id: stable_command_id,
  type: :move,
  actor: character_id,
  instance_id: instance_id,
  payload: %Move{direction: :north}
}

%CommandContext{
  invocation_id: invocation_id,
  idempotency_scope_id: trusted_logical_scope,
  authenticated_session_id: session_id,
  expected_authority_revision: optional_revision,
  received_at_monotonic: ...
}
```

All payload variants are typed structs.

The semantic Command is the portable/replayable input. Host-only context is used for authentication, admission, tracing, freshness/concurrency checks, and transport behavior; it MUST NOT make portable game semantics depend on an ephemeral session ID or host monotonic timestamp.

The stable Command ID is derived/reused from the persistence contract's logical idempotency scope + invocation ID. That scope is stable across reconnect and, where ownership may move, across shard/process/authority handoff; current routing/owner identity MUST NOT turn one invocation into a second mutation.

Unknown command types fail before reaching game rules.

## 4. Decision environment

The host-neutral decision layer / R1-selected portable-rules implementation receives explicit environment:

```elixir
%DecisionEnv{
  definition_registry: ...,
  logical_time: ...,
  rng: rng_state,
  capabilities: ...,
  policy_context: ...
}
```

They do not read wall clock/network/database.

## 5. Decision result

```elixir
{:ok,
 %Decision{
   state_delta: delta,
   rng: new_rng,
   domain_events: events,
   effects: effects,
   client_projection_hints: hints
 }}
```

or:

```elixir
{:reject, %GameError{code: :exit_locked, data: %{...}}}
```

Expected gameplay failure is data, not exception control flow.

### 5.1 Proposal-state semantics and StateDelta composition

Decision output is **provisional** until the authority commit succeeds.

During one decision, the coordinator may feed proposed DomainEvents into other deterministic reducers so quests, reactions, scenes, and capabilities can compose in one atomic semantic action. Those values are still **proposed facts**, not externally observable committed facts.

Before commit succeeds:

- proposed DomainEvents MAY drive deterministic in-decision reducers;
- proposed DomainEvents MUST NOT be published to Phoenix PubSub, client transports, external workers, analytics, or another authority as though they already happened;
- ephemeral presentation derived from the proposal MUST NOT escape in a form the client can treat as authoritative success;
- a rejected decision or failed persistence commit discards its StateDelta, proposed DomainEvents, Effects, RNG/logical-time advancement, and projection hints.

After commit succeeds, the same accepted event values become committed DomainEvents and may be traced, projected, and fanned out according to their registered policy. Cross-authority/external work still leaves through typed Effects/outbox semantics rather than direct event publication during evaluation.

StateDelta composition is a first-class deterministic contract, not "merge some maps":

- every delta operation is a registered typed operation with a canonical mutation target/identity;
- operations declare the state they read/write strongly enough for deterministic conflict detection and diagnostics;
- evaluators see a deterministic **proposal overlay** containing earlier accepted delta operations from the same decision;
- operation ordering is registry/semantic order, never source-file order, map iteration order, process scheduling, or arrival timing;
- two writes to the same authoritative target require a registered composition rule or the decision fails with a typed conflict;
- implicit last-writer-wins is forbidden for authoritative state;
- create/delete/transfer/containment operations define explicit preconditions and failure behavior;
- generated runtime identities use the deterministic IdSource contract;
- final invariant validation runs over the composed proposal before persistence.

R3 freezes the generic delta algebra, target identity, conflict/composition rules, and canonical serialization. Individual capabilities may add versioned delta operators later, but they cannot invent a second mutation path.

## 6. Online hybrid decision coordination

Realm commands may involve both portable capabilities and server-only Elixir capabilities. They MUST still form one logical decision.

The `WorldInstance` / `ZoneShard` uses a **DecisionCoordinator**:

```text
typed Command
   ↓
ordered capability/rule dispatch
   ├─ portable evaluators → portable-rules implementation
   └─ server-only evaluators → pure Elixir rule modules
   ↓
proposal overlay
   + StateDelta
   + DomainEvents
   + Effects
   + RNG/logical-time updates
   ↓
final invariants
   ↓
one authoritative transaction
```

Rules:

- evaluators MUST NOT persist or publish directly;
- every evaluator sees a deterministic proposal-state view containing prior accepted deltas in the current decision;
- event subscribers are dispatched in deterministic registry order, with explicit priority only where the capability contract declares it;
- conflicting writes to the same authoritative field either use a declared composition rule or fail as an invariant/capability conflict;
- portable and server-only events share the same bounded event-chain/cycle limits;
- only after the full decision succeeds does the host commit state, receipts, traces, and durable effects.

This is the online extension point that lets BEAM-native Realm systems coexist with portable cartridge mechanics without reintroducing multiple mutation authorities.

## 7. Game error taxonomy

Every rejection has stable machine code:

```text
not_found
not_present
not_owned
permission_denied
invalid_target
invalid_state
stale_view
stale_revision
insufficient_resource
exit_locked
quest_requirement
cooldown
rate_limited
unsupported_capability
...
```

Human text is localized/rendered separately.

Agents and mobile clients should never need to parse an English error string to decide what happened.

## 8. Domain event envelope

```elixir
%DomainEvent{
  id: uuid,
  type: :item_acquired,
  instance_id: ...,
  scope: {:player, character_id},
  actor_id: ...,
  subject_id: item_id,
  logical_time: ...,
  causation_id: command_id,
  correlation_id: correlation_id,
  payload: %ItemAcquired{...}
}
```

Event types and payloads are registered/machine-readable.

A DomainEvent's semantic scope is **not** a client-broadcast audience. Events may contain authority-internal facts or drive player/party-scoped reducers without being exposed verbatim to clients. ClientMessage/GameView projection applies its own AudiencePolicy and redaction rules.

Events SHOULD be immutable values.

## 9. Event processing model

Within one command, deterministic event reactions may form a bounded chain:

```text
take item
  -> item_acquired
     -> quest reducer advances objective
        -> quest_objective_completed
           -> quest_resolved(outcome_id)
```

This chain runs as part of the same decision/commit where possible.

The runtime MUST impose:

- maximum event-chain depth;
- maximum generated event count;
- cycle detection where applicable;
- deterministic ordering.

This prevents script/rule loops.

## 10. Effect types

Authoritative same-domain changes are **StateDelta/commit data**, not Effects. Examples include entity/quest/fact changes and same-authority durable scheduled-job rows.

Actual Effects are registered and typed in two broad categories:

### Durable asynchronous effects

Use the outbox. These cross a boundary that cannot be completed atomically with the current authority commit.

Outbox delivery MUST be designed as **at-least-once delivery with idempotent application**, unless a stronger mechanism is actually proven for a particular boundary. A lost acknowledgement may cause the same effect to be delivered multiple times; the receiver uses the stable effect/idempotency identity so the authoritative consequence is not applied twice. The specification MUST NOT describe network/outbox transport itself as "exactly once."

A durable effect also declares its terminal-failure/reconciliation behavior. Exhausted retries cannot silently disappear if the effect represents a required gameplay consequence, custody transfer, entitlement change, or other authoritative obligation.

### Ephemeral post-commit effects

Notifications/presentation hints may be emitted after commit and dropped/reconstructed if necessary.

Every effect declares:

- durability;
- idempotency requirement;
- retry policy;
- terminal-failure/reconciliation policy for durable effects;
- allowed origin capabilities;
- schema.

## 11. Causation and correlation

All command-derived events/effects/messages share a correlation ID.

```text
command c1
  event e1 caused_by c1
    event e2 caused_by e1
      effect f1 caused_by e2
      client msg m1 caused_by e2
```

The trace viewer must reconstruct this graph.

## 12. Protocol source of truth for online transport

External protocol definitions MUST live in a language-neutral machine-readable schema source under `protocol/`.

Potential format: JSON Schema plus a small manifest.

Generate/check:

- TypeScript types;
- Elixir validation/struct mappings;
- protocol docs;
- compatibility tests;
- sample fixtures.

No hand-maintained duplicate `Room` interfaces.

## 13. Version negotiation

Client join request includes:

```json
{
  "protocol_version": 3,
  "client_version": "1.7.0",
  "client_features": [
    "dialogue_choices_v1",
    "minimap_v1"
  ]
}
```

Server responds with:

- accepted protocol version;
- required minimum app version;
- enabled feature set;
- instance/cartridge client requirements.

If incompatible, return a typed upgrade error before joining game state.

## 14. Client projection

The client SHOULD receive view models, not internal DB/entity structs.

Example room view:

```json
{
  "room": {
    "id": "uuid",
    "key": "ferry_dock",
    "title": "Old Ferry Dock",
    "description": "...",
    "exits": [
      {"direction": "north", "available": true}
    ],
    "entities": [
      {
        "id": "uuid",
        "name": "Old Ferryman",
        "kind": "npc",
        "actions": [
          {"key": "talk", "label": "Speak"},
          {"key": "inspect", "label": "Inspect"}
        ]
      }
    ]
  },
  "instance_revision": 9202
}
```

Internal component state is not dumped wholesale to mobile.

## 15. Portable game-view projection

Game-semantic view construction that must match offline and online SHOULD be defined once over portable committed state and cartridge definitions.

Realm-only capabilities MAY contribute additional Realm-only GameView fields/actions through registered pure projection evaluators on the server. Those evaluators use the same typed GameView schema, deterministic ordering, policy checks, and fail-closed capability registry; they do not cause React Native to reimplement Realm rules. A portable cartridge hosted online must still project the same portable semantics for equivalent portable state.

Examples:

- resolved ActionSet for an entity;
- visible room contents;
- quest journal state;
- dialogue choices currently available;
- shop/container semantic contents;
- map-discovery state;
- localized string IDs plus interpolation data.

The portable projector returns a host-neutral **GameView** / projection model.

Online:

```text
portable GameView
  -> Elixir protocol adapter
  -> Phoenix client message
```

Offline:

```text
portable GameView
  -> native/mobile binding
  -> React Native projection store
```

React Native owns presentation, animation, layout, accessibility, and localization rendering. It MUST NOT reimplement policy/action/quest visibility rules.

Host-only views—account catalog, entitlement, social realm presence, admin—remain outside the portable projector.

This avoids a second semantic fork where the server and offline client disagree about what the player can see/do.

## 16. Snapshot, projection sequence, and freshness model

On join/resync, server sends an authoritative semantic GameView snapshot.

Subsequent projection messages carry a monotonically ordered **projection sequence** for that client/subscription stream. If the client detects a projection-sequence gap or the server requests resync, it discards/reconciles local view state from a fresh snapshot.

A projected view/action may also carry an opaque **view freshness token** (`view_freshness_token` in the current schema) used when submitting ActionInvocations. The authority re-resolves current legality and may use the token to diagnose/reject stale interaction.

Do **not** require the projection sequence or view token to equal the WorldInstance/ZoneShard database revision. In a shared zone, unrelated authoritative mutations may occur without changing one player's projection, and one authoritative mutation may yield several projection messages.

Authority revisions remain internal concurrency/commit tokens. Projection sequence is transport ordering. View token is interaction freshness. They may be correlated for diagnostics but are distinct contracts.

The client store is a cache of authority projection, not authority.

## 17. Text commands

Text parser is an adapter:

```text
"give jade amulet ferryman"
   ↓ parse
ActionIntent(:give, item query, target query)
   ↓ canonical Search service resolves IDs
ActionInvocation(action_key=:give, targets=[...])
   ↓ active GameSession
authoritative Command
```

Touch UI creates the same ActionInvocation directly from GameView action metadata.

## 18. Search/target resolution

One canonical Search service supports:

- current room;
- inventory;
- equipment;
- nearby/zone scope where explicitly allowed;
- aliases;
- keywords;
- display names;
- ordinal disambiguation;
- exact IDs for tools/admin.

Ambiguous search returns structured candidates.

No transport-specific duplicated keyword lookup helpers.

## 19. Action availability

The active authority exposes resolved ActionSets so touch/text adapters do not reinvent conditions.

Action definitions include:

```text
key
label key/localization
target kind
priority
input schema
policy/conditions
cooldown/resource hints
accessibility description
```

The same metadata can feed terminal help.

## 20. Protocol tests

CI MUST include fixtures asserting both Elixir and TypeScript agree on:

- every command;
- every server message;
- error shape;
- version negotiation;
- representative snapshots.

Breaking protocol changes require version bump and compatibility policy.


## 21. Offline command conformance

The portable semantic Command schema is also machine-readable. Every authoritative host implementation MUST serialize equivalent semantic commands into the same canonical portable representation. Host-only CommandContext fields such as authenticated session identity or receipt timestamp are excluded from portable command equivalence.

Golden conformance fixtures cover command -> decision/event/effect output independent of network transport. Online protocol code wraps these semantics; it does not redefine them.

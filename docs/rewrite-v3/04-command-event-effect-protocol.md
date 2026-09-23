# 04 — Action Invocations, Commands, State Deltas, Domain Events, Effects, and Client Protocol

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: decisions and projections.

Read sections 1-10 for semantic execution. Network protocol sections apply when Realm transport is introduced.

<details>
<summary>Sections in this document</summary>

- [1. Six concepts, six responsibilities](#1-six-concepts-six-responsibilities)
- [2. Action invocation and command semantics](#2-action-invocation-and-command-semantics)
- [3. Canonical command representation](#3-canonical-command-representation)
- [4. Decision environment](#4-decision-environment)
- [5. Decision result](#5-decision-result)
- [6. Online hybrid decision coordination](#6-online-hybrid-decision-coordination)
- [7. Game error taxonomy](#7-game-error-taxonomy)
- [8. Domain event envelope](#8-domain-event-envelope)
- [9. Event processing model](#9-event-processing-model)
- [10. Effect types](#10-effect-types)
- [11. Causation and correlation](#11-causation-and-correlation)
- [12. Protocol source of truth for online transport](#12-protocol-source-of-truth-for-online-transport)
- [13. Version negotiation](#13-version-negotiation)
- [14. Client projection](#14-client-projection)
- [15. Portable game-view projection](#15-portable-game-view-projection)
- [16. Snapshot, projection sequence, and freshness model](#16-snapshot-projection-sequence-and-freshness-model)
- [17. Text commands](#17-text-commands)
- [18. Search/target resolution](#18-searchtarget-resolution)
- [19. Action availability](#19-action-availability)
- [20. Protocol tests](#20-protocol-tests)
- [21. Offline command conformance](#21-offline-command-conformance)

</details>
<!-- packet-navigation:end -->

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

Authority revalidates NEW attempts because the GameView can be stale. It first authenticates and authorizes receipt access, then recognizes an existing invocation by trusted lineage/actor identity and canonical intent digest. A matching retry replays the prior semantic outcome before current-world ActionSet, target-presence, or freshness validation. It never reruns a consumed action. Altered intent under an existing identity is an integrity conflict. Document 03 §14 defines the two-digest contract and §15 the transactional recheck and uncertain-COMMIT recovery.

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

### 5.0 Rejection is not a failed attempt

A **rejection** means the action was not admitted (for example no eligible target or insufficient resources). It consumes no gameplay RNG, time, or costs. A terminal rejection receipt may be recorded without advancing game revision (03 §14).

An **admitted attempt with an unsuccessful game outcome** (miss, failed luck check, resisted spell) returns an accepted Decision with a typed failure outcome. Its declared RNG consumption, time, costs, narration record, and other state changes commit exactly like a successful attempt. Inventory need not change. Retrying the same invocation replays that failed attempt; a genuinely new invocation makes a new attempt against the advanced RNG state. Do not implement a failed roll as `{:reject, ...}` and restore the RNG.

A **definitive transaction rollback** discards the entire proposal. An **unknown commit outcome** instead fences admission and reconciles the original receipt and durable state before any reevaluation (03 §15). Neither case permits a new ID to evade retry identity.

### 5.1 Proposal-state semantics and StateDelta composition

Decision output is **provisional** until the authority commit succeeds.

During one decision, the coordinator may feed proposed DomainEvents into other deterministic reducers so quests, reactions, scenes, and capabilities can compose in one atomic semantic action. Those values are still **proposed facts**, not externally observable committed facts.

Before commit succeeds:

- proposed DomainEvents MAY drive deterministic in-decision reducers;
- proposed DomainEvents MUST NOT be published to Phoenix PubSub, client transports, external workers, analytics, or another authority as though they already happened;
- ephemeral presentation derived from the proposal MUST NOT escape in a form the client can treat as authoritative success;
- a rejected decision or definitively rolled-back persistence transaction discards its StateDelta, proposed DomainEvents, Effects, RNG/logical-time advancement, and projection hints; an uncertain commit is reconciled under 03 §15, not presumed rolled back.

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

### 5.2 Initial immediate-composition profile

ADR-065 fixes the following observation order for the initial portable profile. It refines §5.1 rather than introducing a second evaluator. Capabilities and later profiles may add versioned semantics, never silently change an existing lock.

1. Authenticate receipt access and recognize matching intent before current-world action, target or freshness checks. Reconcile unknown commit outcomes before admitting any new decision. An existing receipt returns its historical outcome, not a replacement for current state.
2. Serialize a new input. Drain already-due jobs according to the declared logical-time admission policy before NEW-action resolution; each job is a typed internal command through the same authority spine. No due-job work is required merely to replay a known receipt.
3. Bind typed targets and pure eligibility queries against committed state. Construct an isolated proposal with explicit clock, RNG and deterministic IdSource. No live persistence, publication or platform/network handles enter evaluation.
4. Execute the root's explicit ordered operation sequence against the proposal overlay. Each operation observes prior operations in that sequence. Append emitted events to a FIFO queue; do not recursively call subscribers from inside an operation.
5. At **event emission**, record its monotonic causal position, bounded event-time payload, and eligible subscription identities. Eligibility includes lifecycle/activation at that position. At delivery, visit that captured set in canonical compiled registry order and evaluate each rule's declared guard against the current overlay and/or explicit event payload. A newly activated quest cannot receive an earlier event merely because delivery occurs later. An activation-trigger-counts exception must be declared by the quest capability, not inferred.
6. Each eligible delivery executes one explicit sequence as a distinct writer group; append its emitted events to the same queue. Registry order uses compiled stable semantic IDs, not source-file enumeration, map iteration or host scheduling. Priorities exist only in a registered capability arbitration contract. Changing a semantic ordering ID requires a new certified artifact.
7. Reach quiescence, validate composed operations and final aggregate invariants, and commit once with the result, receipt, RNG/time, required continuation/narration and durable outbox records. Budget/conflict/evaluator faults discard the **whole** uncommitted proposal; they are not ordinary failed rolls. Unknown COMMIT follows 03 §15.
8. Only after commit may the host adopt state and publish/project accepted results. Rendering, localization, scrolling and historical narration replay are read-only. They never repeat consequences or consume RNG.

A root sequence's order is semantic data. An unrelated subscriber's deterministic execution order is **not** permission to win a conflicting write. Event-time payload and current-overlay queries are distinct typed inputs; observers cannot assume an event subject still exists or remains at its event-time location. Capture only bounded required event data, not a full world copy per event.

A state-based possession objective may evaluate on activation. This is not historical event replay. Strict acquisition objectives still require an eligible post-activation acquisition position, even inside one decision. The existing Tiny event/state fixtures retain these separate meanings; R6P's different content intent is explicit in its work package.

### 5.3 Minimal operation and conflict matrix

Operation names below are semantic contracts, not permission for content to call arbitrary database/component setters. Exact wire schemas freeze at R3A/R3B for the admitted subset. An explicit sequence carries a coordinator-assigned writer-group identity. Independent reaction deliveries cannot copy that identity to evade conflict detection; footprint checking resolves actual runtime targets and aggregate owners.

| Operation family | Required reads and writes | Initial composition rule |
|---|---|---|
| Fact compare/assign | Declared typed fact key + scope + subject; expected value; allowed transition | Opposite or repeated independent assignments conflict. A same-group explicit sequence may perform successive legal transitions. No implicit same-value coalescing; a future idempotent ensure operator needs its own event/no-op contract. |
| Conserved transfer | Stable item identity; current source; destination and containment/capacity ancestry | One independent owner of the transfer. Two destinations for the same item conflict. Validate custody, conservation, acyclic containment and destination capacity; different items do not waive aggregate constraints. |
| Resource adjustment | Typed bounded resource; current value and bounds; declared integer arithmetic | Initial operators apply in explicit sequence, check every step, and never silently clamp. Independent writers conflict unless a versioned commutative operator explicitly specifies composite/intermediate bounds. |
| Lifecycle transition | Owning quest/scene/barrier instance and current state; named legal transition | Only owner capability changes its internals. Explicit unlock-then-open may compose; two unrelated next-state choices conflict. |
| Choice/continuation resolution | Stable instance, beat/occurrence, bound roles, pending choice and expected revision | Resolve exactly one pending choice through the owning capability; consequence, continuation and required narration join the same decision. |
| Schedule/create/cancel job | Job identity, due time, declared time basis, lifecycle | Stable occurrence identity, explicit conflict/dedupe rule, bounded queue. Same-time recursive scheduling is forbidden in the initial authored profile. |
| Event emission | Registered payload schema, emission permission, event-time data, causal position | Content may emit only declared custom events; it cannot forge engine-owned transfer/completion/account evidence. Events do not directly write state. |

Pure selectors/policies cannot mutate, draw RNG, perform I/O, or trigger hidden historical replay. A selector that promises all matches fails explicitly on cardinality overflow; truncation is allowed only for an explicitly named bounded-selection operator with defined ordering. Unknown operations, policies, event types or scope grants fail validation, never default to permissive behavior.

Footprints are conservative declared read/write sets plus actual target checks. They are not a general static theorem prover. Final invariants can reject combinations whose writes are disjoint. Domain details beyond the initial fixtures are frozen when their capabilities are implemented, not prebuilt for R1.

### 5.4 Bounded causality and durable waiting

One immediate decision shares aggregate operation/query/event/delivery/output budgets across root and all descendants. Reaction depth also remains bounded. Exhaustion returns a typed evaluation fault with source/causal diagnostics; do not commit a truncated chain. R1 records exact deterministic caps in [the composition profile](conformance/composition-profile.json). These are experiment safety limits, not measured production capacity or a mandate to support that many authored entities in every cartridge.

Every wait becomes typed persisted state: stable definition/instance/beat IDs, bound roles, expected event/time, and declared missing-participant policy. No saved closures, sleeping process or timer reference is semantic state. A wait on an already-satisfied condition must either advance within the same remaining budget or use a legitimate later input; it is not an unlimited fresh-fuel yield.

Admission also bounds pending jobs and automatic resumes. The initial authored profile requires a newly scheduled job to be strictly later than current logical time. Process due jobs in `(due_time, stable_job_id)` order. Resume/advance has a fixed total due-job allowance. Evaluate its entire due-job set in an isolated proposal; over-limit work discards the whole advance, including time and jobs. Choose smaller explicit advances or report a content/runtime fault. Do not starve player input behind an endless same-timestamp queue. Later catch-up batching needs a separately tested durable continuation/ordering contract.

Action time costs are explicit operations. In the initial profile, an explicit advance snapshots its due set up to the requested target, evaluates those registered job commands in `(due_time, stable_job_id)` order inside the same proposal, then sets the target time. During that advance, newly scheduled jobs must be strictly later than its target, not merely later than a visited due timestamp. Events retain their causal position and visited logical time; reactions follow §5.2. This bounded profile may require smaller advances for recurring work, but may not silently skip jobs or partially commit time. Already-due jobs at ordinary input admission use serialized internal commands; they cannot mutate concurrently. R6P uses zero-time ordinary actions and explicit wait, so reading does not move Bram.

The advance snapshot is a candidate list of `(job_id, occurrence_generation, due_time)`, not unconditional permission to execute every entry. Before each entry, re-read its lifecycle/generation in the current overlay. A prior job or reaction that cancelled, completed or rescheduled that occurrence makes the old entry ineligible; never resurrect it. Each admitted job runs its root sequence and drains its FIFO reactions to quiescence **before the next due job**, sharing the advance's aggregate budget and proposal. Distinct job roots/deliveries have distinct coordinator-assigned writer groups; a capability that needs repeated writes across those groups must declare a versioned composition/fold rule rather than relying on the queue order. Re-evaluate final invariants only at the whole-advance boundary, and commit that advance once. No job receipt or success escapes ahead of the enclosing commit. This does not change the separate serialized decisions used at ordinary admission.

Host watchdog timeout is a runtime fault, not an alternate game result. Cooperative yielding may retain an isolated proposal under serialized ownership; it may not expose half-state or admit competing mutations.

### 5.5 Explanation and evidence obligations

Diagnostics retain source location, expanded recipe, bound targets, operation version, writer group, event position and the violated invariant/budget. Player messages must not expose private facts. `preview` evaluates an isolated snapshot through the same semantics; it cannot consume live RNG or promise that a sampled outcome is guaranteed. A missing capability produces a proposal/escalation, not an engine-write grant.

[Composition cases](conformance/composition-cases.json) specify small known-answer queue/conflict/activation examples. Their Python model checks only those contracts. Actual selected-host byte parity, SQLite recovery, scheduler load, device responsiveness and human play remain the R1/R6P evidence obligations; a passing model is not a production proof.

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

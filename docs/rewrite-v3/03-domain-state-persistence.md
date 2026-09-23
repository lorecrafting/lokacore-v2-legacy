# 03 — Domain State and Persistence

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: state and durability.

Start with identities and scope, then sections 14-18 on receipts, commits, outbox and snapshots. Online table sketches are not local-save requirements.

<details>
<summary>Sections in this document</summary>

- [1. Core state model](#1-core-state-model)
- [2. Definition identity](#2-definition-identity)
- [3. Runtime entity identity](#3-runtime-entity-identity)
- [4. Component state](#4-component-state)
- [5. Persistent vs ephemeral state](#5-persistent-vs-ephemeral-state)
- [6. State scopes](#6-state-scopes)
- [7. Typed world facts and narrative memory](#7-typed-world-facts-and-narrative-memory)
- [8. Persistence by authority host](#8-persistence-by-authority-host)
- [9. Proposed online durable schema families](#9-proposed-online-durable-schema-families)
- [10. World instance row](#10-world-instance-row)
- [11. Runtime entity rows](#11-runtime-entity-rows)
- [12. Quest instance rows](#12-quest-instance-rows)
- [13. Scoped facts and durable ServiceJobs](#13-scoped-facts-and-durable-servicejobs)
- [14. Command receipts and retry admission](#14-command-receipts-and-retry-admission)
- [15. Transactional command commit and uncertain outcomes](#15-transactional-command-commit-and-uncertain-outcomes)
- [16. Effect outbox](#16-effect-outbox)
- [17. Event trace is not full event sourcing](#17-event-trace-is-not-full-event-sourcing)
- [18. Snapshots](#18-snapshots)
- [19. Optimistic concurrency](#19-optimistic-concurrency)
- [20. Persistence adapters](#20-persistence-adapters)
- [21. Migration rules](#21-migration-rules)
- [22. Deletion semantics](#22-deletion-semantics)
- [23. Inventory/location invariant](#23-inventorylocation-invariant)
- [24. Definition cache](#24-definition-cache)
- [25. Offline save lineage and trust](#25-offline-save-lineage-and-trust)
- [26. Story milestones and platform acceptance](#26-story-milestones-and-platform-acceptance)
- [27. Initial run-lifetime persistence obligations](#27-initial-run-lifetime-persistence-obligations)

</details>
<!-- packet-navigation:end -->

## 1. Core state model

Loka v3 separates four concepts that Lokacore often blurred:

1. **Definition** — immutable content from a specific cartridge release.
2. **Runtime entity** — mutable world instance created from a definition.
3. **Scoped state** — state owned by player/party/instance/realm rather than a physical entity.
4. **Durable platform state** — accounts, accepted Story milestones, onboarding policy, entitlements, release catalog, audit/certification metadata.

These MUST have distinct identities and storage semantics.

## 2. Definition identity

A definition reference is globally stable:

```elixir
%DefinitionRef{
  cartridge_id: "fox_spirit_of_yunmeng",
  cartridge_version: "1.2.0",
  kind: :npc,
  key: "old_ferryman"
}
```

A human-readable canonical form MAY be:

```text
fox_spirit_of_yunmeng@1.2.0:npc/old_ferryman
```

Local content may reference `npc/old_ferryman`; the compiler qualifies it.

Definition references are immutable. Updating source creates a new cartridge release/hash.

## 3. Runtime entity identity

Runtime entities use UUIDs:

```elixir
%RuntimeEntity{
  id: uuid,
  instance_id: world_instance_uuid,
  definition: DefinitionRef.t(),
  kind: :npc,
  location_id: room_uuid,
  state: %{...typed component state...},
  tags: [...],
  revision: 17
}
```

Two goblins from the same definition share a definition ref but have different runtime IDs/state.

The runtime entity MUST NOT also act as the canonical definition record.

## 4. Component state

Components are typed and registered.

A component contract includes:

```elixir
%ComponentSpec{
  key: "health",
  version: 1,
  applies_to: [:character, :npc],
  definition_schema: ...,
  runtime_schema: ...,
  merge_policy: :replace,
  migration_hooks: ...
}
```

Unknown component keys fail cartridge compilation.

Runtime component values SHOULD be represented by structs internally after loading/validation, not arbitrary nested maps everywhere.

Content-originated keys MUST NOT create atoms dynamically.

## 5. Persistent vs ephemeral state

Every state field must answer: does it survive process restart?

### Durable

Examples:

- character inventory;
- quest progress;
- currency;
- world door state if intended persistent;
- instance variables;
- spawned/despawned persistent entities;
- durable scheduled jobs;
- RNG state if exact replay/recovery requires it.

### Ephemeral

Examples:

- socket ref;
- temporary UI menu state;
- cached search results;
- ambient-emote timer refs;
- derived pathfinding caches;
- transient combat animation timing.

Ephemeral state may be reconstructed after restart.

## 6. State scopes

State scope is a first-class semantic type:

```elixir
@type scope ::
  {:player, character_id}
  | {:party, party_id}
  | {:instance, instance_id}
  | {:realm, realm_id}
```

Quest instances, typed facts, reputation tracks, world events, and similar state MUST declare a scope.

No helper may default to realm/global scope merely because an ID was omitted.

### Scope is not physical authority placement

State scope answers who owns/experiences a gameplay truth; it does **not** by itself decide which process or table physically hosts that state.

Private Story/WorldInstance execution may naturally co-locate player, party, and instance state under one authority. A persistent Realm may instead place or route player-, party-, instance-, and realm-scoped state through different authority domains as the world is partitioned.

The exact long-lived placement/routing strategy for cross-zone player/party state MUST be decided and acceptance-tested before the corresponding shared-Realm milestones. Schemas and APIs MUST NOT assume that player or party scope is permanently owned by the current ZoneShard.

### Logical world identity is not mutation-owner placement

Schemas and APIs MUST distinguish the identity of the **logical world/context** from the identity of the process/domain that currently owns mutation authority for part of it.

Representative concepts:

- `WorldContextId` / `WorldInstanceId` — the logical simulation/save/deployment context in which state exists;
- `AuthorityDomainId` — the current serialized mutation-ownership domain;
- `ZoneShardId` — one possible Realm placement/routing identity for an authority domain;
- `RealmId` — the broader persistent Realm identity.

The exact names are implementation work, but the types MUST NOT be interchangeable.

A private WorldInstance may initially have a one-to-one mapping between world context and authority domain. A partitioned Realm will not: one logical Realm/world can contain many authority domains, and player/party state may move or be routed independently of the ZoneShard that currently hosts a character.

Therefore:

- an `instance_id` or logical world ID MUST NOT silently double as a fencing/owner/shard token;
- command idempotency identity MUST remain stable when `AuthorityDomainId` changes;
- durable rows that need both context and current mutation placement MUST model both explicitly;
- projection, routing, and persistence APIs must not infer one identity from the other once partitioning is supported.

R20 selects the concrete placement/routing mechanism, but R3 must reserve distinct nominal contracts so the earlier schema does not make that later design impossible.

### Multiplayer state uses independent axes

Do not overload one `scope` field to answer every multiplayer question.

For multiplayer content, distinguish at least:

1. **progress/state scope** — who owns quest/fact/progression state;
2. **authority/instance scope** — which WorldInstance/ZoneShard owns the simulated entity/resource;
3. **audience/visibility scope** — who is allowed to perceive/interact with a runtime entity/projection;
4. **resource/contention scope** — who competes for a scarce service, stock, spawn, reservation, or cooldown.

Examples:

| Example | Progress | Authority | Audience | Contention |
|---|---|---|---|---|
| Personal quest in shared town | player | shared ZoneShard | public/shared NPCs | none |
| Personal quest NPC only quester sees | player | shared ZoneShard | player | none |
| Party dungeon | party | private party WorldInstance | instance/party | instance |
| Public world boss, personal quest credit | player | shared ZoneShard | public | realm/zone spawn |
| One smithy can forge one sword/day | player quest | shared ZoneShard/service | public | realm/service queue |
| Story Mode smithy one sword/day | player | local Story instance | player | local instance |

A compiler/Builder MUST require each nontrivial multiplayer mechanic to be explicit about the axes it uses rather than infer them from quest scope.

### Audience / visibility policy

Runtime entities and projections MAY declare an audience policy independent of state ownership:

```text
public
player(character_id)
party(party_id)
instance(instance_id)
audience_set(...)
```

Audience controls:

- inclusion in GameView;
- search/target resolution;
- interaction/action resolution;
- narrative/ambient projection.

It is not merely UI filtering. The authority MUST reject interactions from actors outside the audience.

Use audience scoping when content should coexist in shared geography without being visible to everyone.

### Scoped runtime entities

A quest-specific actor may be a real RuntimeEntity owned by the shared ZoneShard but visible only to one player/party.

Example:

```text
definition: npc/ghost_child
authority: zone/shard town_square
audience: player(A)
lifecycle: until quest resolved
```

Player B in the same room receives no projection for that entity and cannot target it by forged ID.

This is useful for:

- personal apparitions;
- quest witnesses;
- temporary guides;
- personal enemies;
- quest-only objects/clues.

Do not create a full private WorldInstance merely to hide one NPC.

### Projection override versus separate entity

If the “different NPC” is actually the same physical public actor with personalized dialogue/actions, prefer a **shared entity plus player-scoped projection/relationship/fact rules**.

Use a separate scoped RuntimeEntity only when the actor needs independent:

- presence/location;
- health/lifecycle;
- combat;
- schedule;
- containment;
- spawn/despawn state.

This avoids one physical blacksmith becoming 5,000 duplicate runtime entities just because every player sees different dialogue.

## 7. Typed world facts and narrative memory

Cross-system story/world state MUST NOT become an untyped bag of string flags.

Cartridges/capabilities may declare typed, namespaced **FactSpecs**:

```yaml
facts:
  village.child_status:
    type: enum
    values: [missing, rescued, dead]
    default: missing
    scope: instance

  temple.allegiance:
    type: enum
    values: [unknown, abbot, rebels]
    default: unknown
    scope: player
```

A fact has:

- namespaced key;
- versioned type/schema;
- default value;
- allowed scope(s);
- optional transition constraints;
- documentation/meaning;
- incoming/outgoing reference graph.

Facts are useful for durable truths that several systems need to observe:

- who controls the town;
- whether the bridge is repaired;
- whether a secret has been discovered;
- a player's allegiance;
- whether the festival has started;
- whether a service is available.

Facts are NOT the right storage for:

- current HP;
- an NPC's coordinates;
- arbitrary temporary UI state;
- values already owned by a typed component.

Those remain component/entity/session state.

Changing a fact produces a typed `fact_changed` DomainEvent with old/new values and scope so reactive world rules can respond without polling.

### Relationship and personal NPC memory

Player-specific NPC reactions SHOULD use scoped relationship/memory state rather than mutate a shared NPC globally.

Example logical key:

```text
relationship(player_id, npc_id):
  trust
  fear
  affinity
  memories[]
```

The exact storage may be a typed scoped component rather than a generic fact table, but its scope must remain explicit.

## 8. Persistence by authority host

Online v3 SHOULD use PostgreSQL from the beginning in all realistic server environments.

Reasons:

- eventual concurrent shared-world writes;
- robust transactional semantics;
- row/constraint/index tooling;
- operational backup/replication maturity;
- fewer production-only surprises than switching from SQLite later;
- Ecto support is excellent.

Tests MAY use sandboxed PostgreSQL. Server development SHOULD use PostgreSQL too, preferably via a simple container/dev setup, so database behavior does not drift.

Offline private storypacks use local SQLite (or an equivalent transactional local store) behind a local persistence adapter. The logical save/snapshot formats and command-receipt semantics MUST remain compatible with the portable kernel, but local tables do not need to mirror the server schema byte-for-byte.

## 9. Proposed online durable schema families

Exact migrations are implementation work, but the logical model should include:

### Platform

```text
accounts
story_run_bindings
story_milestone_reports
story_milestone_acceptances
onboarding_requirement_policies
characters
entitlements
catalog_entries
cartridge_releases
cartridge_certificates
```

### Runtime

```text
world_instances
runtime_entities
scoped_facts
quest_instances
service_jobs
scheduled_jobs
command_receipts
effect_outbox
event_traces
state_snapshots
```

### Authoring

```text
builder_workspaces
workspace_revisions
build_artifacts
certification_runs
```

First-party source may primarily live in Git; authoring tables can reference Git/workspace revisions rather than replacing version control.

## 10. World instance row

Logical fields:

```text
id UUID
release_id
mode private|party|shared
realm_id nullable
status creating|running|paused|completed|failed|archived
revision bigint
logical_time
rng_algorithm
rng_state
snapshot_version
created_at
updated_at
```

The instance revision increments with committed authoritative commands/batches.

## 11. Runtime entity rows

Logical fields:

```text
id UUID
instance_id UUID
definition_namespace
definition_version
definition_kind
definition_key
kind
location_id nullable
state_scope_type nullable
state_scope_id nullable
presence_mode shared|overlay
audience_policy JSONB nullable
materialization_key nullable
state JSONB
tags/search columns as needed
revision bigint
created_at
updated_at
```

JSONB is acceptable for typed component state if schemas/migrations validate it. Frequently queried/indexed fields may be promoted to columns deliberately.

Shared entities normally omit scoped-presence fields. Player/party overlay entities use explicit state scope and AudiencePolicy metadata. Lazily materialized actors may be reconstructed from durable quest/fact state plus a stable materialization key rather than persisted forever.

The logical `instance_id`/world-context reference is not by itself the current mutation-owner identity. Once ownership can move, persistence/routing metadata MUST carry an explicit authority-domain/fencing reference rather than overloading the logical world identifier.

Do not create an EAV table for every component field by default.

## 12. Quest instance rows

Keep quest runtime separate enough to query, migrate, and certify:

```text
id UUID
instance_id
scope_type
scope_id
quest_definition_ref
lifecycle_state
activation_mode
activated_logical_time
outcome_id nullable
objective_state JSONB
variables JSONB
event_delivery_state_or_ref nullable
revision
ended_at nullable
```

A unique constraint should prevent duplicate active quest instances where the quest's repeatability rules disallow them.

## 13. Scoped facts and durable ServiceJobs

### Scoped facts

Logical fields:

```text
instance_or_realm_id
scope_type
scope_id
fact_key
fact_version
value JSONB
revision
updated_at
```

Unique identity is the owning authority/context plus scope and fact key.

Facts may also be stored inside a versioned aggregate when that is more efficient, but the logical semantics remain typed and scoped.

### Durable ServiceJobs

Logical fields:

```text
id UUID
authority_id
service_ref
capacity_scope_type
capacity_scope_id
requester_id
beneficiary_type
beneficiary_id
service_key
input_escrow JSONB/reference
submitted_logical_time
time_basis
scheduled_start
scheduled_finish
status
queue_sequence
slot_key nullable
idempotency_key
output_state/reference
revision
created_at
updated_at
```

The exact physical schema may normalize escrow/output separately.

When the service capacity and required inputs are owned by the **same mutation authority**, capacity allocation + input escrow + ServiceJob creation MUST be one authoritative transaction.

If input custody crosses an authority boundary—for example a realm-wide service accepting an item currently owned by another shard—do not pretend the operation is one database transaction merely because both authorities use PostgreSQL. Use an explicit idempotent reservation/transfer protocol with durable intent, custody proof, cancellation/timeout, and reconciliation. The ServiceJob cannot enter a state that consumes the inputs until the owning service authority can prove the required custody/reservation step completed.

Capacity allocation must have a database/authority invariant sufficient to prevent double allocation under concurrent submissions.

## 14. Command receipts and retry admission

Every admitted gameplay attempt has a stable invocation/command identity. An attempt may succeed or fail under the game rules; both outcomes are durable. A retry is delivery of that same attempt, not another roll.

### Authenticate, recognize a retry, then validate NEW gameplay

The order is normative:

```text
validate bounded request envelope; authenticate
  -> authorize access to the logical lineage/actor and its receipts
  -> derive trusted logical idempotency scope + invocation identity
  -> compute canonical invocation-intent digest
  -> lookup original receipt
       matching intent -> replay original semantic outcome, no re-resolution
       altered intent  -> idempotency/integrity conflict, no mutation
       no receipt      -> resolve current action, freshness, targets and policies
                          -> typed semantic Command -> decide -> commit
```

Current actor/account authorization still applies before any receipt is disclosed. Receipt authorization must not depend on a lantern still being on the ground, a consumed choice remaining available, or an old view still being fresh. Ordinary rate/size limits may protect this endpoint but must not mint a new mutation identity.

A scope is a trusted logical gameplay lineage plus controlled actor, for example a Story save lineage/character or Realm/character. It outlives connection, session, process, shard, and owner placement. The same rule applies to registered internal commands using their durable job/command identity. A client cannot choose another actor's receipt namespace.

After handoff, original receipts must remain discoverable. R20 chooses a durable index, migration, forwarding/tombstones, or an equivalent mechanism. Current routing/owner identity cannot turn one invocation into a fresh mutation.

### Two digests, two responsibilities

- **Invocation-intent digest:** canonical action key, actor, ordered semantic target bindings, validated input, and semantic constraints such as offer/choice/continuation identity or a maximum price. It is computed without resolving against changed world state. Unknown fields fail before normalization. Do not sort a target list whose order is meaningful.
- **Semantic-command digest:** canonical resolved command originally admitted, with its pinned definition/capability context. Store the resolved command or a durable reference alongside this digest; do not recreate it using current world state during retry recognition.

Intent normalization/version is explicit and retained with the receipt. A retry uses that original supported schema/digest contract, not current catalog defaults or display aliases. A deployment/app update must not reinterpret a pending invocation as different intent.

Transport sequence, connection/session ID, routing/owner identity, receipt time, and diagnostic correlation fields do not change intent. A pure view-freshness token is admission metadata, not intent. A token that selects an offer, target, or narrative continuation IS semantic and must be included in the intent digest. Its role is declared by schema, never guessed from its field name.

For an existing receipt, compare the incoming intent digest and replay the recorded semantic command/outcome. For an internal command that already has canonical semantics, also require the incoming semantic digest to match. Neither path recomputes an old command from a changed ActionSet.

Logical receipt fields:

```text
idempotency_scope_id
invocation_id or internal_command_id
command_id
origin_authority_id
actor_id
intent_schema_version / intent_digest_version
invocation_intent_digest
semantic_command_digest (nullable for a pre-command terminal rejection)
resolved_command_payload_or_ref
outcome_class / result_code
committed_revision (unchanged for a terminal rejection)
response_payload_or_ref
result_digest
created_at
```

Unique external lookup key: `(idempotency_scope_id, invocation_id)`. The derived command identity also has the existing `(idempotency_scope_id, command_id)` uniqueness constraint. Internal commands use their registered identity. A digest alone is not a replayable response.

A replay returns the original semantic outcome and its revision. A current GameView is projected separately with current stream sequencing; a replayed historical response must not roll the client back to an old snapshot. Replays never rerun effects, narration consequences, costs, RNG, or quest credit.

An authenticated, structurally valid invocation that reaches a terminal gameplay rejection may be durably receipted without changing game revision/RNG/time; the chosen terminal result then replays. Malformed/unauthorized requests do not create gameplay receipts. Transient admission failures (`busy`, rate limiting, storage unavailable, or commit pending) are explicitly retryable and are not mistaken for durable terminal outcomes.

Receipt retention must preserve the no-reexecution guarantee. Evicting an old receipt and then accepting the same identity as new is forbidden; retention requires a safe high-water/tombstone/lineage policy or fail-closed admission. This does not require an unbounded in-memory ID set.

## 15. Transactional command commit and uncertain outcomes

For a new admitted attempt:

```text
BEGIN
  recheck unique invocation/command receipt
  if present: compare original intent and replay; NO gameplay mutation
  else:
    verify current authority revision and ownership/fencing generation
    apply composed StateDelta (including a failed attempt's rule-defined changes)
    update authority revision + RNG/logical state
    insert receipt with original intent, resolved command and stable outcome
    insert required diagnostic trace and durable effect_outbox records
COMMIT
```

The ingress lookup in §14 improves correctness of retry admission; the transactional lookup and unique constraint remain necessary to close races. A receipted terminal rejection changes only receipt metadata, not gameplay state/revision. Two simultaneous deliveries cannot both apply a mutation.

Only after confirmed commit does the in-memory owner adopt the committed revision. Definitive rollback discards the proposal. Same-authority job creation and consequences remain inside this transaction, not asynchronous write paths.

**A timeout or broken connection during COMMIT is not proof of rollback.** While outcome is uncertain, fence further decisions from stale in-memory state. Reconcile against the authoritative durable store, not a stale replica: resolve the transaction outcome and original receipt, then reload committed state. Receipt present means replay/recover. Only confirmed non-commit permits retrying the original identity. An initially missing receipt while the original transaction may still commit is insufficient. No new command ID, second RNG draw, or duplicate reward may be used to hide uncertainty.

Durability on every authoritative action does not require exporting, rereading, and hashing the whole Snapshot on every action. Whole-state or changed-row persistence may be selected by measurement. Benchmark decision, encoding, durable commit, projection, checkpoint export, and cold restore separately; whatever representation is chosen preserves this transaction contract.

## 16. Effect outbox

External/delayed effects that cannot safely occur inside the DB transaction use an outbox.

Examples:

- push notification;
- analytics export;
- email;
- entitlement webhook reconciliation;
- cross-shard handoff message;
- asset/catalog publication side effect.

Gameplay state that can be represented atomically inside the same instance SHOULD be part of the decision/transaction, not unnecessarily asynchronous.

Outbox rows have:

```text
effect_id
idempotency_key
kind
payload
status pending|running|done|failed
attempt_count
next_attempt_at
causation_id
```

Workers MUST tolerate crash/reclaim/redelivery. Durable outbox transport is assumed to be at-least-once: the same effect may reach a receiver more than once after an acknowledgement loss, so the receiving authority/service must deduplicate by the stable idempotency identity before applying authoritative state. A `failed` row representing a required authoritative obligation is not permission to discard it; retry exhaustion transitions into the effect's explicit terminal reconciliation/operator-visible disposition.

## 17. Event trace is not full event sourcing

The current durable state remains authoritative.

Event traces exist to support:

- debugging;
- correlation;
- deterministic repro;
- audits;
- semantic review;
- certification evidence.

The system MUST NOT require replaying the entire history from genesis to boot a world.

Periodic snapshots plus current state are sufficient.

## 18. Snapshots

A snapshot captures enough state to recreate an instance deterministically:

```text
instance revision
cartridge release/hash
logical clock
RNG state
runtime entities
quest/scoped state
durable scheduler state reference
```

Snapshots are useful for:

- Lab rewind;
- bug reproduction;
- save checkpoints;
- migrations;
- staging copies.

Snapshot format must be versioned.

## 19. Optimistic concurrency

World owners serialize normal commands, reducing contention.

Database revisions still protect against:

- duplicate owners after failover bugs;
- admin/manual writes;
- cross-shard coordination;
- stale maintenance jobs.

Updates SHOULD include expected revisions.

When more than one runtime process could plausibly claim the same durable authority domain—because of restart overlap, failover, clustering, or an operational bug—the store MUST also validate an ownership/fencing generation (or an equivalently strong lease/owner token). A stale process with a valid-looking state revision must not be allowed to resume writing after ownership has moved.

A revision or fencing conflict is an invariant signal, not something to silently overwrite.

## 20. Persistence adapters

`loka_core` defines ports/protocols such as:

```elixir
@callback commit(CommandCommit.t()) :: {:ok, CommitReceipt.t()} | {:error, term()}
@callback load_instance(id) :: {:ok, snapshot} | ...
```

`loka_store` implements them with Ecto.

The Cartridge Lab can provide an in-memory deterministic adapter where appropriate, while integration certification uses PostgreSQL too.

## 21. Migration rules

### Engine schema migration

Database migrations are normal application deploy concerns and must support rollback/forward procedures.

### Cartridge definition migration

An active world/quest is pinned to a cartridge release.

New release does NOT automatically reinterpret old saves.

Allowed strategies:

- continue on old release;
- explicit compatible migration function;
- complete/archive old instance;
- clone to new version via tested migration.

### Component migration

Each component version transition that changes persisted runtime state must register a deterministic migration.

For state that can exist in `offline_private` portable saves, the migration path itself must be executable by the supported mobile/portable compatibility path (or the app must retain the older interpreter/runtime). A server-only Elixir migration is not sufficient for an offline save that may update with no network.

No “read old shape and guess.”

## 22. Deletion semantics

Deleting content source never invalidates an already published immutable release.

Deleting a runtime entity must define containment semantics.

No generic `delete(entity)` may recursively delete contents unless the caller explicitly chooses a policy such as:

- cascade;
- move contents to parent/location;
- orphan prohibited;
- archive.

This prevents surprising inventory/world loss.

## 23. Inventory/location invariant

An item has one authoritative containment/location relation.

Do not separately store:

- item.location_id = player
- AND player.inventory = [item]
as two independent truths.

Choose one canonical relationship and derive/cache the other.

Recommended direction:

```text
RuntimeEntity.container_id
```

Rooms, characters, chests can all be containers.

Inventory is a query/index over contained item IDs.

Equipment adds an equipment-slot relation/assignment but does not duplicate ownership.

## 24. Definition cache

Compiled cartridge definitions are immutable and may be aggressively cached in ETS/`:persistent_term` or application memory.

Because they are content-hash/version keyed, invalidation is simple.

Runtime mutable state must not use the same cache semantics.


## 25. Offline save lineage and trust

Offline save identity includes a lineage/ancestor revision so cloud backup can detect divergent branches.

Two independently advanced offline branches MUST NOT be auto-merged unless a cartridge provides an explicit deterministic merge strategy. Preserve both and ask the user to select.

Offline runtime state is user-controlled and MUST NOT be imported as authoritative MMO economy/competitive progression. Designated milestone reports may satisfy non-competitive account onboarding prerequisites only under [document 23](23-accounts-progress-admission.md); they are not a save-state import or verified-human-play claim.

## 26. Story milestones and platform acceptance

A rule-owned terminal milestone and its host-side pending report persist atomically with the local gameplay outcome. Report/account binding and delivery state survive recovery but are not portable gameplay inputs or part of the canonical gameplay hash. Platform acceptance is a separate authenticated, idempotent transaction; it cannot retroactively roll back local Story completion. Account/progress records arrive with R12A, not R13/R14. Record and lifecycle semantics are owned by [document 23](23-accounts-progress-admission.md); account is not an additional gameplay scope.

## 27. Initial run-lifetime persistence obligations

Document 10 §31–33 governs action-driven Story time, per-accepted-attempt durability, three manual bookmarks, immutable package references, rollback-safe migrations and bounded export/import. Keep current head, immutable restore points and migration staging distinct. Document 23 §11 governs inherited report provenance when restoring/forking; a new lineage is not a replay of all historical effects. Actual storage/fault evidence belongs at R6/R12; account acceptance remains a separate server record.

# 06 — Quests, Dialogue, Actions, and Scripting

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: narrative and interaction.

Quests/actions: sections 1-22. Custom events/scenes: 30-38 and 41-42. LokaScript sections 23-27 and 29 remain deferred; multiplayer scenes are later.

<details>
<summary>Sections in this document</summary>

- [1. Quest Runtime](#1-quest-runtime)
- [2. Quest definition](#2-quest-definition)
- [3. Objective operators](#3-objective-operators)
- [4. Quest instance](#4-quest-instance)
- [5. Quest event processing](#5-quest-event-processing)
- [6. Exactly-once rewards](#6-exactly-once-rewards)
- [7. Quest subscriptions/indexing](#7-quest-subscriptionsindexing)
- [8. Quest invariants](#8-quest-invariants)
- [9. Quest/world contract](#9-questworld-contract)
- [10. Quest outcomes and typed consequences](#10-quest-outcomes-and-typed-consequences)
- [11. Prefer facts for broad narrative consequences](#11-prefer-facts-for-broad-narrative-consequences)
- [12. Opening and changing areas](#12-opening-and-changing-areas)
- [13. NPC state, schedules, relationships, and memory](#13-npc-state-schedules-relationships-and-memory)
- [14. Reactive world rules](#14-reactive-world-rules)
- [15. Consequence scope and escalation](#15-consequence-scope-and-escalation)
- [16. Branches should leave durable world consequences](#16-branches-should-leave-durable-world-consequences)
- [17. Dialogue definition](#17-dialogue-definition)
- [18. Dialogue state](#18-dialogue-state)
- [19. ActionSet algebra](#19-actionset-algebra)
- [20. Action definition](#20-action-definition)
- [21. Policies/conditions](#21-policiesconditions)
- [22. Text command parser](#22-text-command-parser)
- [23. Scripting goals](#23-scripting-goals)
- [24. LokaScript allowed model](#24-lokascript-allowed-model)
- [25. Portable script binding registry](#25-portable-script-binding-registry)
- [26. Script budgets](#26-script-budgets)
- [27. Deterministic scripts](#27-deterministic-scripts)
- [28. Trusted compiled Elixir extensions](#28-trusted-compiled-elixir-extensions)
- [29. Script lifecycle](#29-script-lifecycle)
- [30. Cartridge custom domain events](#30-cartridge-custom-domain-events)
- [31. State machine use outside quests](#31-state-machine-use-outside-quests)
- [32. Quest as the narrative spine](#32-quest-as-the-narrative-spine)
- [33. SceneSequence: reusable narrative orchestration](#33-scenesequence-reusable-narrative-orchestration)
- [34. Scene step vocabulary](#34-scene-step-vocabulary)
- [35. Text cutscenes](#35-text-cutscenes)
- [36. Dreams, visions, memories, and other private sequences](#36-dreams-visions-memories-and-other-private-sequences)
- [37. Scene control and player agency](#37-scene-control-and-player-agency)
- [38. Quest-to-scene integration](#38-quest-to-scene-integration)
- [39. Scripted world events and WorldEventPlan](#39-scripted-world-events-and-worldeventplan)
- [40. Multiplayer scene semantics](#40-multiplayer-scene-semantics)
- [41. Journal, reveal, hints, and story readability](#41-journal-reveal-hints-and-story-readability)
- [42. Narrative robustness and certification](#42-narrative-robustness-and-certification)
- [43. Terminal milestones are game facts, not account writes](#43-terminal-milestones-are-game-facts-not-account-writes)
- [43. Initial objective, choice and narration contracts](#43-initial-objective-choice-and-narration-contracts)

</details>
<!-- packet-navigation:end -->

## 1. Quest Runtime

Quest correctness is a primary v3 requirement. Quests are also the primary authored narrative thread that carries story through the living world; scenes, dreams, cutscenes, and scripted world events extend that thread without giving quests a second mutation authority.

The persisted lifecycle remains deliberately small:

```text
active
  -> objectives_complete
  -> resolved(outcome_id)

branches:
  active/objectives_complete -> failed(outcome_id?)
  active/objectives_complete -> abandoned
  abandoned/failed -> active   # only if retry policy permits
```

**Availability/eligibility is derived**, not a persisted QuestInstance lifecycle state. An offered/discovered/automatic quest normally has no QuestInstance until activation.

**Acceptance is an activation interaction**, not a permanent lifecycle layer. Offered quests record activation metadata when a QuestInstance is created.

**Turn-in is a resolution policy**, not a universal terminal state. The terminal success state is `resolved` with a named outcome.

A state-machine validator guards lifecycle transitions.

Complexity belongs in objective graphs/outcomes/consequences, not dozens of lifecycle states.

## 2. Quest definition

Example:

```yaml
kind: quest
key: missing_child
scope: player
giver: npcs/old_ferryman
turn_in: npcs/old_ferryman

prerequisites:
  all:
    - quest_state:
        quest: village_arrival
        state: resolved

objectives:
  all:
    - id: learn_name
      event:
        type: dialogue_node_reached
        target: npcs/child_mother
        node: tells_name

    - id: find_tracks
      event:
        type: discovered
        target: clues/river_tracks

    - any:
        - id: rescue
          event:
            type: npc_escorted
            target: npcs/missing_child
        - id: discover_fate
          event:
            type: discovered
            target: clues/child_fate

activation:
  mode: offered

resolution:
  mode: turn_in

outcomes:
  ...
```

### Activation modes

Quest availability SHOULD normally be derived from prerequisites/facts rather than creating persistent QuestInstances for every locked quest.

Supported activation patterns should include:

- `offered` — player explicitly accepts from an NPC/object/action;
- `automatic` — becomes active when prerequisites/world condition becomes true;
- `discovered` — activates when the player discovers a place/clue/event.

**Journal visibility/reveal is a separate axis from activation.** A quest may be visible immediately, hidden until a typed reveal condition/event, or intentionally absent from the normal journal. Do not encode presentation visibility as another activation mode.

Activation prerequisites are revalidated by the authority at the activation transition. After a QuestInstance becomes active, prerequisites are not continuously treated as a hidden deactivation rule. If losing a condition should fail/pause/branch an active quest, the definition must express that as an explicit failure/sustain rule.

### Resolution modes

Supported completion patterns should include:

- `turn_in` — objectives complete, then a valid turn-in action resolves the quest;
- `automatic` — resolving objective/outcome resolves immediately;
- `choice` — a final dialogue/action choice selects outcome and resolves.

The resolved outcome ID is durable quest state.

A quest giver and turn-in target are therefore optional content roles, not hard engine requirements.

## 3. Objective operators

Quest grammar SHOULD support:

- event match;
- current-state/fact predicate;
- scene outcome;
- world-event phase/outcome;
- all;
- any;
- sequence;
- count;
- optional;
- within/time window;
- condition-gated activation;
- branch;
- repeatable counter;
- explicit failure condition.

Each operator has a pure reducer and schema.

### Objective credit/causation policy

In multiplayer, matching the event is not enough. Each objective type MUST define who is eligible to receive credit.

Common policies:

- `actor` — only the event actor;
- `party` — eligible members of the actor's party;
- `participants` — entities recorded as participants/contributors;
- `witness` — scoped characters who actually witnessed/observed the event according to world rules;
- `scope_any` — any eligible quest instance in the declared instance/realm scope.

Policies may add constraints such as:

- same instance/zone;
- within distance;
- contribution threshold;
- alive/present.

For event-observation objectives, **post-activation credit is the default**: events that happened before the QuestInstance activated are not silently replayed into progress. If author intent is “already possess X / already know Y / current fact is Z,” model that as an explicit current-state predicate evaluated at activation or as a separately declared retroactive/history operator with bounded evidence semantics.

Credit is deterministic data derived from event/state, not a transport/UI guess.

Story Mode normally collapses to actor/player semantics, but uses the same contract.

Do not add arbitrary scripting for common quest logic.

## 4. Quest instance

```elixir
%QuestInstance{
  id: ...,
  definition_ref: ...,
  scope: {:player, character_id},
  lifecycle: :active,
  activation_mode: :offered,
  activated_at: logical_time,
  outcome_id: nil,
  objectives: typed_state,
  variables: %{},
  revision: 8,
  event_delivery_cursor_or_dedupe: authority-defined idempotency state
}
```

Definition version is pinned.

Quest event delivery MUST be idempotent without relying on an unsafe forever-growing or arbitrarily evicted set of event IDs. The authority may use durable delivery receipts, monotonic per-source cursors where valid, or a bounded dedupe structure only when its pruning rule cannot make an old retry executable again.

## 5. Quest event processing

Quest Runtime consumes canonical DomainEvents, including proposed events inside the enclosing decision (04 §5.1). Quest/reaction/consequence deltas join the same atomic commit; external consumers see only committed events. This is not a post-commit quest-write pipeline.

Activation records a deterministic event-position boundary, not just a wall/logical timestamp. An event ordered before activation is not retroactively delivered merely because both occurred in one command or at the same logical time. Already-known/owned state is an explicit current-state predicate. A discovered activation may use its trigger as evidence only under an explicitly declared operator policy; no implicit historical replay is allowed.

Movement code does not call “increment quest.”

Dialogue does not call “complete objective.”

Scripts do not directly edit quest JSON.

```text
world DomainEvent
   ↓
matching active quest instances by scope/subscription
   ↓
QuestReducer.reduce()
   ↓
Quest StateDelta
   + quest DomainEvents
   + typed outcome-consequence requests
   ↓
capability consequence evaluators
   ↓
combined world StateDelta / DomainEvents / Effects
   ↓
one authority commit
```

The quest engine never receives generic write access to entity/component storage.

## 6. Exactly-once rewards

Quest completion produces reward state/effects with stable idempotency keys:

```text
quest_instance_id + completion_revision + reward_key
```

Retry/restart cannot grant twice.

## 7. Quest subscriptions/indexing

Do not evaluate every active quest against every event if scale grows.

Maintain two conceptually distinct indexes:

1. **active-instance subscriptions** — which existing QuestInstances may consume an event;
2. **activation subscriptions** — which quest definitions with no QuestInstance yet may need to evaluate automatic/discovered activation when a relevant event/fact transition occurs.

At compile/load/activation time build indexes by event type, fact dependency, target, and scope where possible.

Example:

```text
active {:death, "goblin"} -> [quest instance ids]
active :dialogue_node_reached -> [...]
activate {:discovered, "hidden_shrine"} -> [quest definition refs]
activate {:fact_changed, "village.arrived"} -> [quest definition refs]
```

Offered quest availability may be derived on interaction/projection; automatic/discovered activation must not require pre-creating locked QuestInstances.

Private cartridges may begin with simpler scans, but the semantic API must distinguish activation candidates from active-instance delivery.

## 8. Quest invariants

Certification MUST check:

- references exist;
- prerequisite graph acyclic unless explicit repeat loop;
- completion can be reached;
- required turn-in entity can be reachable under expected branches;
- objective IDs unique;
- no reward without valid terminal transition;
- no objective completes from unrelated target/topic;
- duplicate event is idempotent;
- version migration explicit;
- state scope intentional.

## 9. Quest/world contract

A quest is not a private world-mutation engine.

It has three responsibilities:

1. **observe** typed world DomainEvents and current scoped facts/state;
2. **remember** quest-specific objective/lifecycle/branch state;
3. **declare outcomes/consequences** through registered capability operations.

The world remains responsible for applying its own semantics.

This creates a feedback loop:

```text
WORLD
 movement / NPC schedules / combat / weather / dialogue / economy
       ↓ DomainEvents
QUEST
 objectives / branches / outcome
       ↓ typed consequences
WORLD STATE
 facts / entity states / topology / relationships / spawned actors
       ↓ reactive rules + changed policies
WORLD
 new dialogue / new routes / changed schedules / rumors / ambience
       ↓
future DomainEvents
```

A quest can therefore cause meaningful world change without bypassing world invariants.

Multiplayer ownership, phasing, instancing, personal quest actors, shared bottlenecks, and durable shared-service queues are specified normatively in [19 — Quest Sharing, Phasing, Instancing, and Scarce World Services](19-quest-sharing-instancing-capacity.md).

## 10. Quest outcomes and typed consequences

Quest definitions SHOULD name explicit outcomes rather than encode all consequences in arbitrary scripts.

Example:

```yaml
outcomes:
  rescued:
    when:
      branch_completed: rescue

    consequences:
      - fact.set:
          key: village.child_status
          value: rescued
          scope: instance

      - connection.set_state:
          target: exits/shrine_road
          state: open
          scope: instance

      - relationship.adjust:
          npc: npcs/old_ferryman
          subject: quest_actor
          trust: 10
          scope: player

      - event.emit:
          type: village/child_returned
          scope: instance
```

Each consequence operator is registered by a capability and declares:

- valid target types;
- input schema;
- allowed scopes;
- portability;
- whether it produces StateDelta, DomainEvents, Effects, or a bounded combination;
- idempotency semantics;
- conflict/composition behavior;
- certification rules.

A consequence may not write arbitrary component fields.

### Same-authority consequences

When quest state and affected world state share one authority owner, quest completion and its StateDelta-producing consequences SHOULD commit atomically in the same decision.

Example in Story Mode:

```text
quest outcome = rescued
+ village.child_status = rescued
+ shrine road = open
+ mother role state = relieved
--------------------------------
one local SQLite commit
```

### Cross-authority Realm consequences

A quest running in one ZoneShard may need to affect another authority such as:

- realm economy;
- guild state;
- another shard;
- global event service.

Those cannot pretend to be one database transaction.

The local quest/outcome commits first with a durable, idempotent cross-authority Effect/outbox record. The receiving authority applies its own command/protocol and reconciliation rules.

Delivery may repeat after acknowledgement loss; the stable effect identity makes remote authoritative application idempotent rather than assuming exactly-once transport. A required remote consequence that exhausts ordinary retry remains a durable unresolved/reconciliation obligation and MUST NOT silently disappear while the local quest presents the cross-authority work as successfully settled.

Certification must test failure, duplicate delivery, terminal retry disposition, and reconciliation at that boundary.

## 11. Prefer facts for broad narrative consequences

If many independent systems need to know the same durable story truth, prefer a typed scoped Fact instead of directly editing each subsystem.

Example:

```text
village.child_status = rescued
```

may drive:

- mother's dialogue;
- mother's daily schedule;
- ferryman ambient lines;
- guard disposition;
- town description variants;
- rumor availability;
- shop inventory;
- follow-up quest prerequisites;
- festival attendance;
- access to the northern road.

This is more coherent than a quest directly issuing eight unrelated edits.

Use direct consequence operators when the mechanical change is inherently local:

- open this gate;
- move this NPC;
- grant this item;
- spawn this encounter;
- reveal this map location.

The rule of thumb:

> **Facts express truths. Consequences express actions. Reactive world rules express how the world responds to truths/actions.**

## 12. Opening and changing areas

Quest-gated exploration SHOULD normally use precompiled topology/content plus runtime access/activation state.

Preferred patterns:

### Access policy

The exit/portal already exists but is inaccessible until a condition becomes true:

```yaml
connection:
  to: rooms/mountain_pass
  when:
    fact_equals:
      key: village.pass_open
      value: true
```

Useful for personal/player-scoped unlocks.

### Stateful connection

A gate/bridge/door has runtime state:

```text
collapsed → repairing → open
```

The corresponding capability controls whether movement/action is available.

Useful when the world itself physically changes.

### Content activation

A precompiled encounter/location group is inactive until a typed capability activates it.

Useful for:

- cave-in reveals;
- temporary festival spaces;
- invasion camps;
- post-quest settlements.

Do not make ordinary quest progression dynamically generate arbitrary new definitions at runtime.

### Map discovery

A location can exist physically while the player's map/journal does not reveal it until discovery.

Map visibility and physical accessibility are separate concerns.

### Multiplayer scope

In Realm Mode, “unlock this area for me” normally uses player/party policy or instancing/phasing.

A player-scoped quest MUST NOT silently open a realm-shared gate for everyone.

A true realm-wide unlock requires explicit realm scope and shared-area certification.

## 13. NPC state, schedules, relationships, and memory

Quest consequences should change **runtime state/profile**, not replace NPC definitions.

Useful capability patterns:

### NPC role/state machine

```text
mother:
  searching → grieving
  searching → relieved
  relieved  → rebuilding_life
```

Transitions can be triggered by facts/events and validated by a state machine.

### Behavior/schedule profiles

An NPC definition can provide profiles:

```yaml
schedule:
  profiles:
    searching:
      ...
    normal:
      ...
    mourning:
      ...
```

The active profile may derive from world facts instead of requiring the quest to manually rewrite schedule entries.

### Player-specific relationship state

Shared NPC:

```text
relationship(player, ferryman).trust += 10
```

does not alter the ferryman's global personality toward every Realm player.

Dialogue/action availability can query that scoped relationship.

### NPC memory

Important narrative interactions may create typed personal memories:

```text
memory:
  key: player_returned_child
  subject: player_id
  value: true
```

A memory should have bounded schema/meaning, not become unlimited free-form model-generated history.

## 14. Reactive world rules

World systems may register deterministic reactions to DomainEvents/fact changes.

Example:

```yaml
react:
  on:
    fact_changed:
      key: village.child_status

  when:
    fact_equals:
      key: village.child_status
      value: rescued

  apply:
    - behavior.select_profile:
        target: npcs/child_mother
        behavior: schedule
        profile: normal

    - ambient.enable:
        group: child_returned_lines
```

At runtime these compile into registered capability evaluators inside the same bounded event/decision model.

Rules:

- no polling every frame just to discover a fact changed;
- reactions produce typed StateDelta/DomainEvents/Effects;
- event chains remain bounded and deterministic;
- cycles are detected/budgeted;
- all referenced facts/capabilities/targets are compile-validated.

Whenever possible, prefer **derived behavior** over mutation. For example, a room description may select its variant directly from facts/time/weather with no stored “current description” field.

## 15. Consequence scope and escalation

Quest scope and consequence scope are related but NOT automatically identical.

A player-scoped quest may safely produce:

- player-scoped facts;
- personal relationships;
- personal map discovery;
- personal ActionSet/access changes.

It may also affect instance/party/realm state only when the consequence explicitly declares that broader scope and the target profile permits it.

Compiler/certification MUST flag scope escalation such as:

```text
player-scoped quest
   ↓
realm-scoped gate unlock
```

unless explicitly authored and certified.

No consequence operator defaults to realm/global scope because scope was omitted.

## 16. Branches should leave durable world consequences

Meaningful quest branches SHOULD differ in more than reward text.

Possible consequences include:

- alternate NPC role states;
- different faction reputation;
- different schedules;
- destroyed/repaired locations;
- permanent access differences;
- prices/services available;
- ambient descriptions;
- rumors;
- follow-up quests;
- companion availability;
- weather/world-event triggers;
- campaign continuity memories.

The Cartridge Lab should be able to fork before the branch and compare resulting world states/simulations.

A branch does not need to change everything. The requirement is that intended consequences are represented as typed world state rather than hidden in prose only.

## 17. Dialogue definition

Dialogue is a graph of nodes with typed conditions/actions.

```yaml
kind: dialogue
key: ferryman

entry: greeting

nodes:
  greeting:
    text: dialogue.ferryman.greeting
    choices:
      - id: ask_missing_child
        text: dialogue.ferryman.ask_child
        when:
          quest_available:
            quest: quests/missing_child
        next: missing_child_offer
```

Dialogue selection emits canonical DomainEvents such as `dialogue_node_reached`.

## 18. Dialogue state

Session may track which dialogue UI is open, but authoritative dialogue/quest state that matters after reconnect belongs to world/player state as defined by the feature.

Do not make socket assigns the only location of consequential branch state.

## 19. ActionSet algebra

Adopt a formal composition model inspired by mature MUD command-set systems and Lokacore's existing Action Resolver.

Sources produce action contributions:

```text
entity base
equipment
status effects
skills
quest grants
room policy
world state
scripts
transformation/modal state
```

Operations:

- `union`
- `subtract`
- `intersect`
- `replace`
- `override`

Stable action key is identity.

After composition, evaluate policies/conditions and sort by priority/presentation group.

## 20. Action definition

```yaml
key: talk
label: actions.talk
target: npc
command: talk
priority: 100
policy:
  all:
    - target_present: true
```

Actions may require additional input schema.

The same action supports touch and terminal adapters.

### Composed actions / ActionRecipe

A builder MAY define a cartridge-local Action whose semantics are entirely composed from registered primitives rather than requiring a new engine command implementation.

Representative recipe:

~~~yaml
key: ring_bell
aliases: [ring, bell]
target:
  kind: inspectable_detail
  ref: details/temple_bell
policy:
  all:
    - target_present: true
outcomes:
  success:
    events:
      - temple/bell_rung
    narration:
      actor: narration.bell.actor
      observers: narration.bell.room
~~~

A richer recipe may include typed costs, a Check, result bands, cooldown/duration, and registered consequence operators.

The compiled recipe is immutable, schema-validated, bounded, and deterministic. The active authority still re-resolves the action and executes it through the normal semantic Command/decision path.

ActionRecipe is preferred over LokaScript for simple new verbs. If the verb requires a genuinely new invariant or mutation semantic, add a versioned engine capability instead.

The same action supports touch and terminal adapters.

## 21. Policies/conditions

Policy AST is typed and fail-closed.

Core operators:

```text
all
any
not
permission
owner/self
tag
has_item
fact_compare
stat_compare
resource_compare
quest_available
quest_state
quest_outcome
faction_compare
time_window
target_present
scope_matches
```

`quest_state` refers to persisted QuestInstance lifecycle state. Availability is derived and therefore uses `quest_available`; named terminal branches use `quest_outcome`. Broad narrative truths use typed facts rather than generic string flags.

A policy evaluator is pure.

Policy definitions may be reused by exits, actions, dialogue choices, builder operations, and publication rules where semantics match.

## 22. Text command parser

Text parsing is not game logic.

Flow:

```text
raw text
 -> tokenize/parse
 -> identify action alias
 -> Search resolve target(s)
 -> build ActionInvocation
 -> active GameSession
 -> authority re-resolves/revalidates
 -> typed semantic Command
```

The text parser is an input adapter just like touch UI; it MUST NOT bypass the ActionInvocation authority boundary.

Parser should support classic MUD conveniences:

- aliases;
- abbreviations where unambiguous;
- ordinal/multi-match selection;
- inventory/current-room search;
- quoting names;
- helpful ambiguity errors.

## 23. Scripting goals

> **Deferred design:** ADR-018 defers LokaScript until a demonstrated composition gap is admitted. This retained design is not a chapter-one build requirement; it constrains that feature if admitted.

We want a powerful AI-friendly escape hatch without reintroducing unrestricted runtime code.

V3 SHOULD define **LokaScript**, an Elixir-looking restricted language whose released form is portable across offline mobile and online BEAM hosting.

Key idea:

> Parse Elixir-like syntax during authoring into a portable normalized AST/bytecode, then interpret that representation inside the shared deterministic kernel. Do not execute cartridge source with `Code.eval_string`.

This keeps syntax familiar to Elixir-capable models while creating a real semantic boundary.

## 24. LokaScript allowed model

Potential allowed forms:

- literals;
- maps/lists/tuples;
- boolean operators;
- comparisons;
- `if` / `case` over bounded values;
- bounded `for`/collection transforms only if interpreter budgets them;
- calls to registered script bindings;
- local immutable variable binding.

Forbidden:

- module calls;
- `apply`;
- process operations;
- receive/send/spawn;
- filesystem/network;
- code loading;
- macros;
- module definitions;
- anonymous recursion;
- arbitrary Erlang BIF access;
- wall clock/global randomness.

## 25. Portable script binding registry

Bindings are capabilities:

```text
query.entity
query.fact
query.quest
query.time
query.weather
emit.say
emit.message
fact.set
world.spawn
world.move
combat.damage
combat.heal
job.schedule
event.emit
rng.chance
rng.pick
```

Each binding has input/result schema, cost, and portability classification. Offline cartridges may call portable bindings only.

Mutation-like bindings return typed StateDelta/DomainEvents/Effects according to their registered capability contract; they do not write DB directly.

## 26. Script budgets

Each execution has deterministic semantic limits such as:

- max AST/interpreter steps;
- max queries;
- max emitted StateDelta operations/events/effects;
- max spawn count;
- max scheduled jobs;
- max result size;
- max collection size.

Exceeding a deterministic semantic limit is a typed script error and trace.

A host MAY also enforce a conservative **wall-time safety guard** to protect the process/device, but that guard is not part of cartridge semantics. Certification MUST demonstrate that valid scripts hit deterministic step/resource budgets before wall time can create host-dependent behavior and that supported hosts complete certified workloads comfortably inside the outer guard. If the outer wall guard fires unexpectedly, treat it as a host/runtime fault/conformance failure rather than a normal deterministic script branch.

## 27. Deterministic scripts

Scripts receive:

- logical time;
- explicit RNG;
- immutable view/query context.

Given the same compiled script, state/event, logical time, and RNG state they MUST produce the same canonical result on mobile and server hosts.

No hidden wall-clock access.

## 28. Trusted compiled Elixir extensions

Engine developers MAY implement new capabilities as normal compiled Elixir modules.

That is different from cartridge scripting and normally requires engine release/version change.

Repeated LokaScript patterns SHOULD be candidates for promotion into compiled capabilities.

## 29. Script lifecycle

```text
source
 -> parse to AST
 -> schema/binding validation
 -> static budget/forbidden-form validation
 -> compile to normalized interpreted form
 -> cartridge hash
 -> Lab execution
 -> semantic review
 -> release
```

Runtime never executes unvalidated raw source.

## 30. Cartridge custom domain events

Cartridges may declare namespaced custom DomainEvents for loosely coupled world behavior:

```text
fox_spirit/bell_rung
village/guard_alerted
festival/started
ferry/arrived
```

These are ordinary typed DomainEvents, not a separate signal bus.

Rules:

- event keys/schemas are registered by the cartridge/capability compiler;
- unknown events fail validation where statically knowable;
- event emission uses the same bounded event chain, causation/correlation, and deterministic ordering as engine events;
- scripts use `event.emit` and receive no direct PubSub/database escape hatch.

## 31. State machine use outside quests

Small state machines remain useful for:

- combat phase;
- doors;
- NPC high-level modes;
- crafting jobs;
- sessions;
- cartridge lifecycle.

Use them when states/transitions are explicit.

Do not force every behavior into a state machine when a pure function/derived state is simpler.


## 32. Quest as the narrative spine

Quests are the primary authored **narrative thread** that carries a story through a living world, but a quest is not a second world authority.

A robust quest may coordinate:

- exploration;
- dialogue;
- combat or non-combat encounters;
- investigations and discoveries;
- timers/windows;
- services/jobs;
- NPC role and schedule changes;
- SceneSequences;
- dream/vision sequences;
- text cutscenes;
- map/location reveals;
- world-event phase changes;
- named outcomes;
- durable cross-system facts;
- follow-up quest activation.

The quest owns its own objective/branch/lifecycle state and observes the world. It coordinates other mechanics through typed events, facts, scenes, and consequences.

This allows the quest to feel like the thread making the world/story alive without giving it generic component/database write access.

### Stages and milestones

Long quests may define named **stages/milestones** as authoring structure over the objective graph.

A stage may:

- group objectives;
- expose journal text;
- start a SceneSequence;
- reveal content;
- change active hints;
- emit a milestone DomainEvent.

Stage/milestone is not automatically another persisted QuestInstance lifecycle dimension. Where possible it compiles to ordinary objective/branch state plus named milestone events.

### Storyline/arc grouping

A **Storyline/ArcDefinition** MAY group several quests, scenes, expected branches, entry conditions, and endings for authoring, Lab coverage, catalog presentation, and certification.

It is not another gameplay authority or mandatory progress store. Runtime truth remains in QuestInstances, scoped Facts, SceneInstances, and world state.

This gives a long narrative a visible high-level spine without creating one giant monolithic quest.

## 33. SceneSequence: reusable narrative orchestration

A **SceneSequence** is a registered narrative orchestration primitive reusable by quests and non-quest world events.

Use it for:

- text-based cutscenes;
- dreams and visions;
- ceremonies;
- staged conversations;
- travel interludes;
- scripted reveals;
- tutorials;
- dramatic event beats;
- player choices that happen inside a controlled scene.

A scene is not a raw script and is not a new authority.

Player scene choices/continuations are ordinary Actions: touch/text emits ActionInvocation, authority re-resolves/revalidates, and a typed Command advances the SceneReducer. Automatic scene progress is driven only by deterministic immediate beats or explicit typed events/jobs/inputs.

Conceptual flow:

~~~text
quest/reaction/world event
   -> start SceneSequence
   -> SceneReducer advances registered beats
   -> Narration / choices / waits / typed consequence requests
   -> DomainEvents
   -> quest/world reactions
~~~

A consequential scene has a durable SceneInstance so app kill, server crash, reconnect, or retry cannot replay consequential beats incorrectly.

Representative state:

~~~text
SceneInstance
  id
  definition_ref
  scope
  participants
  scene_space
  control_mode
  current_beat
  local_variables
  checkpoint
  revision
  completed_outcome
~~~

Definition version is pinned.

### Scene roles and durable participant bindings

A SceneDefinition MAY declare named semantic roles such as:

~~~text
player
old_master
witness
guard_captain
ritual_officiant
~~~

Each role declares a typed selector/cardinality and whether it must resolve at scene start,
may resolve later, or may be absent.

When a consequential scene starts, the authority resolves required roles inside the
declared SceneSpace/InstancePlan context and persists **SceneRoleBindings** in the
SceneInstance.

Later beats target the bound runtime identity, not a fresh display-name search.

This prevents:

- reconnect binding to another copy of the same NPC definition;
- respawn causing a scene to jump actors;
- shared Realm players accidentally targeting another participant's phased actor;
- ambiguous aliases selecting a different entity halfway through a cutscene.

If a bound participant disappears/dies/becomes invalid, the definition must declare a
missing-participant policy such as:

- wait;
- branch;
- fail scene;
- substitute an explicitly compatible role;
- re-resolve through a named policy when rebinding is genuinely intended.

Silent arbitrary rebinding is forbidden.

## 34. Scene step vocabulary

Scene steps are registered and typed.

Foundation candidates:

- **narrate** — emit localized NarrationSpec;
- **dialogue** — enter/use a dialogue node;
- **choice** — present typed choices and wait for one authoritative selection;
- **check** — perform a registered deterministic/stat/RNG check;
- **branch** — choose next beat from state/check result;
- **present** — presentation hint such as image/audio/animation metadata where supported;
- **await_ack** — wait for player acknowledgement/continue;
- **await_event** — wait for a matching typed DomainEvent;
- **await_action** — wait for an allowed Action;
- **advance_time** — request explicit logical-time advance only where the profile permits it;
- **consequence** — request a registered typed consequence operator;
- **overlay** — set/clear scene presentation or scoped visibility overlay through registered semantics;
- **checkpoint** — persist a safe resume point;
- **end** — complete with an optional named scene outcome.

A step MUST NOT contain arbitrary state-field writes.

A scene does not block a BEAM process or mobile thread while waiting. It persists/derives a waiting state and resumes from a new ActionInvocation, DomainEvent, logical-time input, or scheduled job.

## 35. Text cutscenes

Text-first cutscenes are a first-class SceneSequence rendering mode.

A cutscene should support:

- ordered narrative beats;
- actor/target/observer-aware NarrationSpec;
- paragraph/page grouping;
- optional player choices;
- optional acknowledgement between beats;
- skip/replay policy;
- accessibility-friendly plain text;
- mobile enhancement without changing semantics.

Example conceptual sequence:

~~~text
narrate: temple doors slam shut
narrate: incense smoke coils into a human shape
dialogue: abbot_warning
choice:
  - kneel
  - challenge
branch on choice
consequence: relationship.adjust / fact.set
end
~~~

The semantic scene remains valid on a terminal client even if a mobile client adds art, sound, vibration, or animation.

## 36. Dreams, visions, memories, and other private sequences

Dream/vision content SHOULD use explicit scene-space semantics instead of pretending a shared Realm character physically teleported into ordinary shared geography.

SceneSequence does not own spatial simulation. It references the generic SceneSpace/InstancePlan primitives from document 21.

Recommended scene spaces:

- **current_world** — scene happens in the ordinary current simulation;
- **scoped_overlay** — current shared geometry remains, but presentation/entities/actions differ for eligible participants;
- **instance** — a generic InstancePlan creates an isolated temporary/private/party spatial simulation from precompiled room/area definitions.

Scene space does not itself choose a new mutation authority. In Story Mode the LocalInstanceAuthority may own the scoped subspace directly. In Realm Mode, genuinely separate physical simulation uses the existing private/party WorldInstance instancing semantics from document 19; a purely perceptual dream should prefer a scoped overlay.

A dream/vision is therefore a **content composition**, not another engine subsystem.

A dream may:

1. trigger from sleep/rest/quest/world state;
2. start a SceneInstance and choose current-world, overlay, or generic InstancePlan space;
3. when interactive space is needed, instantiate precompiled rooms/entities/populations just like any other scoped dungeon/instance;
4. expose dream-only actions/entities/details;
5. progress choices/checks;
6. end;
7. export only explicitly declared typed consequences/facts/memories back to the owning world/quest.

No accidental dream loot/entity may leak into Realm state unless an explicit certified consequence creates the corresponding real-world result.

Dream-local temporary state can disappear on scene teardown while declared narrative memory survives.

## 37. Scene control and player agency

A scene declares its control mode.

Representative modes:

- **free** — scene narration occurs while ordinary actions remain available;
- **restricted** — ActionSet is intersected with a declared allowed set while the scene is active;
- **modal** — only scene continuation/choice actions are available;
- **presentation_only** — no authoritative input required; scene advances through deterministic immediate beats or explicit acknowledgement.

Restrictions MUST use normal ActionSet composition/policy rather than a transport/UI-only lock.

A scene also declares:

- whether it is skippable;
- what skip means semantically;
- whether it can be replayed as non-authoritative history;
- what happens on disconnect;
- any timeout behavior and time basis.

Skipping presentation MUST NOT skip required authoritative consequences unless the definition explicitly maps skip to a deterministic terminal scene outcome.

## 38. Quest-to-scene integration

A quest may reference scenes at explicit hooks such as:

- activation;
- milestone/stage entry;
- objective completion;
- branch choice;
- failure;
- objectives complete;
- final resolution;
- post-resolution epilogue.

A scene may emit typed DomainEvents that the quest observes.

A quest may wait on a scene outcome as an objective:

~~~text
scene_completed(dream_of_river, outcome = accepted_oath)
~~~

Scene start/resume/completion must be idempotent.

A command retry must not:

- start duplicate dream instances;
- replay a one-time reward;
- emit the same consequential scene beat twice;
- resolve a quest twice.

## 39. Scripted world events and WorldEventPlan

Not every scripted event belongs inside a quest.

A **WorldEventPlan** is a higher-level composition for multi-phase living-world events such as:

- festival;
- storm;
- invasion;
- siege;
- rebuilding effort;
- election;
- pilgrimage;
- disaster response.

It composes existing primitives:

~~~text
trigger
 -> scoped phase/state machine
 -> facts
 -> PopulationPlans / activation groups
 -> behavior/schedule changes
 -> merchant/service changes
 -> scenes/narration
 -> quests
 -> typed outcomes
~~~

A WorldEventPlan is not another mutation authority and SHOULD NOT become a universal kitchen-sink runtime manager. It compiles/coordinates ordinary scoped state machines, facts, reactions, populations, schedules, services, scenes, and quests under their existing authority contracts.

Quests may:

- start a world event through a typed consequence;
- observe its phase/events;
- contribute progress;
- branch based on its outcome.

World events may also exist independently of quests.

## 40. Multiplayer scene semantics

Realm scenes MUST declare participant/audience semantics independently from quest progress scope.

Possible participant models:

- one player;
- party snapshot;
- current eligible participants;
- instance population;
- explicit realm-event participants.

Possible synchronization models:

- **independent** — each participant advances their own player-scoped scene;
- **leader_driven** — one authorized participant chooses for the group;
- **barrier** — scene advances when all/required participants acknowledge;
- **shared_choice** — an explicit voting/selection policy chooses one result.

Disconnect/late-join/party-leave behavior must be declared.

Do not hold an entire shared ZoneShard hostage to one player's modal cutscene.

## 41. Journal, reveal, hints, and story readability

A robust quest system also needs presentation metadata distinct from authoritative progress.

Useful contracts include:

- journal title/summary;
- stage-specific journal text;
- discovered/revealed entries;
- optional objectives;
- hints with reveal policies;
- completed/failed summary;
- named outcome recap;
- related people/places/map links;
- replayable non-authoritative scene transcript where product design wants it.

These are projections of quest/world state, not alternate lifecycle truth.

## 42. Narrative robustness and certification

Quest/scene certification should test more than objective completion.

Required relevant scenarios include:

- app/server crash at every consequential scene beat;
- retry of scene choice/start/completion;
- skip versus non-skip semantic equivalence where skip is allowed;
- disconnect/reconnect during modal scene;
- dream/private-scene teardown with no leaked temporary state;
- declared dream consequence exported exactly once;
- branch-specific world mutations visible after scene/quest completion;
- scheduled scripted event firing once;
- quest objective waiting on scene/world-event outcome;
- scene/action restriction enforced by authority, not client only;
- multiplayer scene participant semantics;
- cross-authority scene consequence recovery;
- bounded scene/reaction/event chains.

The Cartridge Lab SHOULD show a unified narrative trace:

~~~text
ActionInvocation
 -> Command
 -> DomainEvents
 -> quest objective/milestone
 -> SceneSequence beat
 -> choice
 -> scene outcome
 -> quest outcome
 -> world consequences
 -> reactions
 -> resulting GameView
~~~

This makes complex authored story behavior explainable and reproducible rather than opaque script execution.

## 43. Terminal milestones are game facts, not account writes

Quest/scene terminal consequences may reach a declared cartridge milestone through registered narrative operations. Both intended chapter-one endings reach `prologue_completed` after the final `dawn_on_the_green` consequence. Rules cannot upload reports, inspect account authentication, or directly grant Realm access. The local authority adapter commits the pending synchronization record atomically with the milestone; [document 23](23-accounts-progress-admission.md) owns account association and platform acceptance. Readable completion feedback must survive a crash before credits or final narration is displayed.

## 43. Initial objective, choice and narration contracts

The exact initial queue/overlay/activation boundary is 04 §5.2. Objectives declare evidence policy: strict post-activation events, current-state evaluation, or another explicitly registered policy. Delivery after activation does not retroactively qualify an earlier event. R6P's lantern objective is current possession; the Tiny acquisition-event fixture intentionally remains strict. A historically completed acquisition does not authorize giving an item the actor no longer owns.

Persist stable scene/choice occurrence IDs, typed variables, current beat, bound participant identities, selected outcomes and wait state. Missing participants follow explicit wait/branch/failure/rebinding policy; name lookup must not silently bind a replacement. A stale NEW choice revalidates actual custody/presence. Replaying a committed choice first uses its receipt, even after the participant leaves. The player must be able to close an unavailable interaction without mutating its outcome or being trapped in a modal screen.

Required narration is committed with its consequence as a stable record containing pinned text keys and bindings sufficient to redisplay it coherently. Read/scroll position is presentation state. Redisplay after a crash, history replay or presentation skipping never repeats consequences; skipping cannot omit required costs or state transitions. A retry may return historical narration plus a separately current GameView, but never resurrect a consumed choice. Repeatable scenes use distinct occurrence IDs rather than an unbounded forever-seen-event set.

[The R6P work package](pre-release-proof.md) and its frozen expected traces exercise both outcomes, early acquisition, lost custody, participant movement, rejection/replay and interrupted presentation. They are content-specific examples over the shared contracts, not a separate narrative engine.

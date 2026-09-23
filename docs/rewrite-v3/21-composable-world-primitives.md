# 21 — Composable World Primitives and Builder Expressivity

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design boundaries plus capability catalog.

Read sections 1-3 and 24-26 for composition/graduation. Check release scope before treating a catalog entry or candidate as current work.

<details>
<summary>Sections in this document</summary>

- [1. Core rule: closed semantics, open composition](#1-core-rule-closed-semantics-open-composition)
- [2. Where builder expressive power lives](#2-where-builder-expressive-power-lives)
- [3. Expression mechanisms available to builders](#3-expression-mechanisms-available-to-builders)
- [4. Foundation world primitives](#4-foundation-world-primitives)
- [5. Spatial and topology primitives](#5-spatial-and-topology-primitives)
- [6. Perception and descriptive-world primitives](#6-perception-and-descriptive-world-primitives)
- [7. Action and interaction primitives](#7-action-and-interaction-primitives)
- [8. Item, inventory, equipment, and material primitives](#8-item-inventory-equipment-and-material-primitives)
- [9. Character and embodiment primitives](#9-character-and-embodiment-primitives)
- [10. Autonomous behavior primitives](#10-autonomous-behavior-primitives)
- [11. Reaction primitives](#11-reaction-primitives)
- [12. Population, encounter, and lifecycle primitives](#12-population-encounter-and-lifecycle-primitives)
- [13. Commerce primitives](#13-commerce-primitives)
- [14. Service primitives](#14-service-primitives)
- [15. Crafting, gathering, and production primitives](#15-crafting-gathering-and-production-primitives)
- [16. Social-world primitives](#16-social-world-primitives)
- [17. Environmental and ecological primitives](#17-environmental-and-ecological-primitives)
- [18. Narrative primitives](#18-narrative-primitives)
- [19. Spatial instance and scene primitives](#19-spatial-instance-and-scene-primitives)
- [20. Scene and sequence primitives](#20-scene-and-sequence-primitives)
- [21. WorldEventPlan composite](#21-worldeventplan-composite)
- [22. Examples of emergent domain composites](#22-examples-of-emergent-domain-composites)
- [23. Builder semantic operations](#23-builder-semantic-operations)
- [24. Primitive graduation rule](#24-primitive-graduation-rule)
- [25. Builder expression test](#25-builder-expression-test)
- [26. Choosing the right composition shape](#26-choosing-the-right-composition-shape)
- [27. Additional immersive-world capability candidates](#27-additional-immersive-world-capability-candidates)
- [28. Capabilities graduated by the first cartridge](#28-capabilities-graduated-by-the-first-cartridge)
- [29. Readiness subset and author decision guide](#29-readiness-subset-and-author-decision-guide)

</details>
<!-- packet-navigation:end -->

**Status:** normative v3 architecture for composition boundaries; the primitive catalog includes both foundation requirements and later capability candidates.  
**Purpose:** give builders enormous expressive power without giving cartridge content arbitrary runtime authority.

## 1. Core rule: closed semantics, open composition

Loka should maximize what a builder can express while keeping the runtime authority model small and mechanically testable.

> **Engine capabilities define semantic atoms. Builders compose them into arbitrarily rich worlds. Content cannot invent a second persistence, concurrency, or mutation model.**

A builder may freely compose registered semantics into:

- entities and areas;
- policies;
- target selectors;
- actions;
- reactions;
- behavior/state machines;
- population plans;
- commerce/services;
- dialogue;
- scenes;
- quests;
- world events;
- templates/archetypes;
- bounded LokaScript;
- tests/simulation scenarios.

When these cannot express a requested mechanic, the Builder must report a missing-capability boundary. Engine developers then add a versioned capability with schemas, rules, tests, conformance fixtures, and certification obligations.

This is the v3 replacement for both hardcoded profession/quest-specific subsystems and arbitrary Diku-style special procedures.

## 2. Where builder expressive power lives

Builder power lives primarily **above the authority substrate and below finished content**.

~~~text
L6  CARTRIDGES / CAMPAIGNS / REALM DEPLOYMENTS
     authored games and persistent-world regions

L5  NARRATIVE + WORLD ORCHESTRATION
     quests, scenes, world events, encounters, chapters, consequences

L4  DOMAIN COMPOSITES
     merchant, smithy, inn, ferry, guard post, rumor network,
     faction territory, weather ecology, crafting station

L3  COMPOSITION GRAMMAR
     policy, selector, reaction, sequence, state machine, schedule,
     arbitration, capacity, queue, cooldown, population plan, templates

L2  SEMANTIC PRIMITIVES / CAPABILITIES
     containment, connection, fact, resource, relationship, damage,
     inventory transfer, spawn, status, commerce transaction, narration

L1  WORLD MODEL CONTRACTS
     DefinitionRef, RuntimeEntity, Relation, StateScope, Audience,
     time, RNG, Action, DomainEvent, StateDelta, Effect, GameView

L0  AUTHORITY / TRANSACTION SUBSTRATE
     LocalInstanceAuthority or BEAM owner, idempotency, commit,
     receipts/outbox, persistence, fencing, deterministic execution
~~~

### Who extends which layer

- **Cartridge builders/AI** normally work at L3–L6.
- **Engine capability developers** extend L2 and, where needed, L3 combinators.
- **Platform/runtime developers** own L0–L1 invariants.
- Builders MUST NOT pierce downward into L0 to gain expressivity.

A useful test:

> If two very different mechanics can be expressed by composing the same lower primitives, the decomposition is probably healthy.

## 3. Expression mechanisms available to builders

Builders SHOULD have several complementary forms of composition.

### 3.1 Declarative capability configuration

The default.

~~~yaml
components:
  schedule:
    profile: market_day
  merchant:
    catalog: village_goods
    price_policy: friendly_variable
~~~

### 3.2 Policy/condition algebra

Pure predicates answer whether something is visible, legal, eligible, active, targetable, or available.

Policies can compose through:

- all;
- any;
- not;
- comparisons;
- reusable named policies.

### 3.3 Target selectors

Typed selectors answer **which entities/details/scopes** a rule applies to.

Examples:

~~~text
self
actor
action_target
quest_actor
entities.in_room
entities.with_tag
party.members
service.provider
relationship.subject
population.instances_of
~~~

Selectors MUST be bounded and deterministic. A selector is not a raw database query language.

### 3.4 ReactionRule

Reactive glue:

~~~text
DomainEvent / fact transition
  -> selector
  -> policy
  -> typed consequences
~~~

This is the primary replacement for one-off special procedures.

### 3.5 State machines

Useful where explicit durable modes and legal transitions matter:

- door/bridge;
- NPC role;
- encounter phase;
- world event;
- service job;
- scene;
- quest lifecycle.

### 3.6 Sequences/scenes

Ordered, recoverable narrative or mechanical orchestration built from registered steps.

### 3.7 Templates, mixins, archetypes, and recipes

Authoring-time reuse compiles down to flat definitions.

A project may create high-level recipes such as:

~~~text
village_blacksmith
night_watch_guard
pilgrim_inn
haunted_shrine
festival_vendor
~~~

without creating runtime inheritance.

### 3.8 Bounded LokaScript

> **Deferred design:** ADR-018 defers LokaScript until a demonstrated composition gap is admitted. This retained design is not a chapter-one build requirement; it constrains that feature if admitted.

LokaScript is the flexible expression layer for logic that is awkward in static YAML but still fits existing semantics.

It may:

- query exposed deterministic state;
- compute;
- branch;
- iterate within budgets;
- choose through explicit RNG;
- request registered consequence operations.

It may not:

- write persistence;
- spawn BEAM processes;
- call arbitrary modules;
- access filesystem/network/wall clock;
- mutate unknown component fields;
- bypass Action/Command/StateDelta/DomainEvent/Effect contracts.

### 3.9 Custom facts and domain events

Cartridges may define typed namespaced Facts and DomainEvents.

This allows semantic vocabulary such as:

~~~text
temple.bell_rung
village.child_status
pilgrimage/started
ferry/arrived
dream/omen_seen
~~~

without requiring a new engine feature for every story noun.

Custom facts/events add **meaning and coordination**, not new mutation authority.

## 4. Foundation world primitives

The following are foundation-level concepts or strong candidates for early portable capabilities.

### Identity and provenance

- DefinitionRef;
- RuntimeEntity ID;
- source cartridge/deployment;
- spawn/population provenance;
- scope owner;
- authority revision;
- tags;
- aliases/keywords;
- stable local keys.

### Typed relations

- location/containment;
- equipment;
- connection/topology;
- ownership;
- custody;
- membership;
- following/escort;
- beneficiary/requester;
- participation/contribution;
- relationship links.

Relations must be capability-owned and typed; Loka is not an untyped graph database.

### StateScope

- player;
- party;
- instance;
- realm.

### AudiencePolicy

- all;
- player;
- party;
- participants;
- policy-defined audience.

### Time

- logical clock;
- world calendar;
- real-elapsed resume input where allowed;
- time windows;
- duration;
- schedule;
- cooldown;
- deadline;
- recurrence.

### Deterministic RNG

- chance;
- weighted choice;
- shuffle/sample with bounded collections;
- explicit/versioned RNG semantics.

### Fact

Typed, namespaced, scoped durable truth.

### Resource

Generic bounded numeric or quantity state such as health, stamina, currency, charges, favor, or optional survival needs. Resource mutation remains typed by the owning capability.

### Policy

Pure condition tree.

### StateMachine

Typed state + legal transitions.

### DomainEvent

Typed fact about an accepted/committed decision.

### NarrationSpec

Audience-aware localized presentation generated from semantic outcomes.

## 5. Spatial and topology primitives

### Place/Room

A navigable spatial container with:

- descriptions/variants;
- contents;
- connections;
- environmental context;
- details;
- tags;
- access/presence policy.

### AreaDefinition

Authoring/geographical grouping used for:

- maps;
- environment defaults;
- population plans;
- certification;
- world-impact inspection.

It is NOT a mutation authority and is NOT synonymous with ZoneShard.

### Connection

A typed traversable relationship between places.

Supports:

- directed/undirected semantics;
- labels/aliases;
- travel policy;
- travel cost/duration;
- traversal mode;
- barrier state;
- destination/mount port.

### Barrier

Shared mutable state for a logical door/gate/bridge/barricade:

- open/closed;
- locked/unlocked;
- access/key policy;
- damaged/repaired;
- blocked/unblocked.

Bidirectional faces reference one barrier state unless explicitly modeled as independent.

### Portal/Transition

A connection whose destination may be another place, an instance entrance, cartridge port, deployment mount, or private scene transition.

### Map discovery

Separate from physical reachability.

### Terrain / travel cost

Data consumed by movement/pathfinding/schedule behaviors rather than hardcoded room flags.

## 6. Perception and descriptive-world primitives

Immersion depends heavily on what a player can perceive, not only on what exists.

### InspectableDetail

Lightweight keyed detail attached to a place/entity/connection.

Fields may include:

- aliases;
- localized description;
- condition variants;
- perception policy;
- reveal fact;
- optional contextual Actions.

Promote to a RuntimeEntity only when independent mechanical identity is required.

### DescriptionVariant

Select prose/presentation from deterministic context such as:

- facts;
- time;
- weather;
- actor relationship;
- quest state;
- damage/state machine;
- season.

Prefer derived variants over mutating current-description state.

### PerceptionPolicy

Candidate dimensions:

- visibility;
- lighting;
- concealment;
- detection;
- hearing/audibility;
- distance/adjacency;
- magical/special perception where capability-defined.

The first implementation may support only a subset; the contract should allow expansion without making visibility an ad-hoc check everywhere.

### Recognition / displayed identity

A shared NPC may be rendered differently according to what the viewer knows.

Potential later capability:

~~~text
unknown traveler -> scarred swordsman -> General Wei
~~~

without changing canonical entity identity.

### SenseCue / ambient observation

Typed ambient cues such as sound, scent, temperature, visual ambience, or tactile/environmental cues. These are projection/interaction inputs, not independent authority.

## 7. Action and interaction primitives

### Action

Advertised affordance with:

- stable key;
- aliases;
- target spec;
- input schema;
- policy;
- cost/preconditions;
- presentation metadata.

### TargetSpec / TargetResolution

Declares candidate scopes and accepted kinds/capabilities.

Candidate scopes may include:

- self;
- inventory;
- equipped;
- room contents;
- room occupants;
- connections;
- InspectableDetails;
- party;
- explicitly privileged/global tool scope.

Resolution is deterministic:

~~~text
none | unique(target) | ambiguous(candidates)
~~~

No random tie-breaking.

### ActionRecipe / ComposedAction

Builders may define new local verbs without adding engine code when the verb is only a composition of existing semantics.

A compiled ActionRecipe may declare:

- stable action key + aliases;
- TargetSpec/input schema;
- visibility/availability Policy;
- costs/requirements;
- optional Check;
- success/failure/result bands;
- typed consequences;
- custom DomainEvents;
- NarrationSpec;
- cooldown/duration/interrupt policy where supported.

Examples:

~~~text
ring bell
pray at altar
search rubble
knock on gate
offer incense
study inscription
challenge guard
~~~

The authority resolves the advertised action to the immutable compiled recipe and constructs a typed semantic invocation/command path. Recipe execution remains bounded and deterministic.

One ActionRecipe executes as one logical decision. Same-authority costs/checks/outcomes/consequences join the proposal and commit atomically. Cross-authority work becomes explicit typed Effects/outbox work under the normal rules.

If the mechanic must wait for later input/time/events, use SceneSequence, ServiceJob, a scheduled job, or another explicit durable state machine rather than hiding asynchronous continuation inside an ActionRecipe.

ActionRecipe MUST NOT become an untyped effect list. Every operation/result is registered and schema-validated.

Use a dedicated engine capability instead when the action requires genuinely new semantic invariants.

### Check

Typed resolution primitive:

- deterministic threshold;
- opposed check;
- explicit RNG roll;
- difficulty;
- modifiers;
- result bands.

### Cost

Potential reusable operation:

- resource cost;
- item requirement/consumption;
- cooldown;
- time/duration;
- charge use.

### Interaction duration/channel

For actions that are not instantaneous:

- fixed duration;
- interrupt conditions;
- completion event;
- cancellation policy.

Long durable work should normally use ServiceJob or another durable job rather than a hidden timer.

## 8. Item, inventory, equipment, and material primitives

### Containment

One canonical location/containment relation.

### Quantity / stacking

Typed stack identity and conservation rules.

### Equipment

- slots;
- compatibility policy;
- equip/unequip;
- granted capabilities/actions/modifiers.

### Durability/condition

Optional capability for pristine/worn/broken or numeric durability plus repair policy.

### Charges/ammunition

Explicit resource semantics.

### Material/quality

Potential crafting/economy metadata, preferably typed rather than arbitrary tag strings where mechanics depend on it.

### Ownership versus custody

Ownership, current containment, escrow custody, and authority placement are distinct.

## 9. Character and embodiment primitives

Candidate capability vocabulary:

- attributes/stats;
- skills;
- resources;
- status effects;
- posture;
- injury/wounds;
- healing;
- death;
- respawn/recovery;
- level/progression where desired;
- movement modes;
- carrying capacity;
- fatigue;
- hunger/thirst/temperature exposure where a cartridge wants survival mechanics.

Not every cartridge enables every system.

Avoid a mandatory giant RPG character schema.

## 10. Autonomous behavior primitives

Behaviors produce intents; they do not directly write world state.

After deterministic arbitration, the owning authority validates the selected BehaviorIntent and turns it into a registered authority-internal semantic Command (or equivalent explicitly registered world-simulation Command). That Command follows the same decision/StateDelta/DomainEvent/Effect/commit path as other mutations.

Candidate behaviors:

- schedule;
- patrol;
- wander;
- guard;
- follow;
- escort;
- pursue;
- flee;
- assist;
- aggressive/hostile engagement;
- scavenge;
- forage;
- seek item/place/entity;
- work;
- rest/sleep;
- socialize;
- use service;
- trade;
- seek shelter;
- weather response;
- fact/event reaction;
- role/profile selection.

### Behavior intent arbitration

Multiple behaviors may be eligible simultaneously.

Each capability declares:

- intent channel/type;
- priority model;
- interruptibility;
- preconditions;
- conflict/composition rule;
- stable tie-break.

Example channels might include locomotion, combat, interaction, work, and social.

The exact channel taxonomy is capability-registry work, but behavior file order MUST NOT silently decide conflicts.

An entity with no movement behavior stays where authored unless another rule moves it.

## 11. Reaction primitives

A ReactionRule is a reusable intermediate primitive:

~~~yaml
on:
  event: village/bell_rung

select:
  entities:
    tag: village_guard

when:
  fact_equals:
    key: village.alert
    value: true

apply:
  - behavior.select_profile:
      behavior: patrol
      profile: emergency
~~~

Reaction rules may observe:

- DomainEvents;
- fact transitions;
- state-machine transitions;
- service completion;
- scheduled/logical-time boundary DomainEvents;
- population transitions;
- scene/quest milestones.

A wall clock or hidden timer never fires a reaction directly; temporal triggers enter authority through the normal scheduler/command/event semantics.

Reactions produce only registered typed consequences.

This is one of the main builder-expression layers.

### Shared consequence vocabulary

ActionRecipes, ReactionRules, quests, scenes, and world events SHOULD reuse one registered consequence vocabulary rather than each inventing a mutation API.

Candidate operators include:

- fact.set / fact.clear;
- relationship.adjust;
- reputation.adjust;
- resource.adjust;
- status.apply / status.remove;
- containment.transfer / item.grant through registered inventory semantics;
- connection.set_state;
- map.reveal;
- activation.enable / activation.disable;
- behavior.select_profile;
- population.enable / population.disable;
- spawn/despawn within bounded registered semantics;
- scene.start;
- world_event.start / world_event.transition where valid;
- schedule/profile selection;
- narration.emit;
- event.emit.

Every operator declares target types, allowed scopes, portability, idempotency, StateDelta/DomainEvent/Effect production, conflict/composition rules, and certification tests.

There is deliberately no generic set-component-field operator.

## 12. Population, encounter, and lifecycle primitives

### SpawnBundle

Named explicit nested spawn composition.

Example conceptual tree:

~~~text
bandit_captain
  inventory:
    purse
    sealed_letter
  equipment:
    sword
    leather_armor
~~~

References are explicit; there is no last-loaded-mobile context.

### PopulationPlan

Defines:

- SpawnBundle/definition;
- target Area/Place selector;
- desired/min/max count;
- count scope;
- replenishment/respawn policy;
- schedule/time basis;
- activation policy;
- placement policy;
- cleanup policy;
- provenance;
- uniqueness constraints.

Population reconciliation is initiated through a registered authority-internal Command/world-simulation step with stable causation where retries matter. A PopulationPlan never writes persistence directly.

### EncounterPlan

Higher-level composition that may coordinate:

- participant population;
- activation;
- phase state machine;
- victory/failure conditions;
- scene/narration;
- cleanup;
- rewards/consequences.

### ActivationGroup

Precompiled content that becomes present/active based on facts/events/policy.

Useful for festival setup, invasion camps, revealed caves, and post-quest settlements.

### Cleanup/decay

Typed lifecycle policy for ephemeral entities/items.

Never delete state merely because it differs from initial content unless provenance and policy explicitly grant ownership of that lifecycle.

## 13. Commerce primitives

A real commerce contract should be built from:

### CommerceProvider

Provider identity and authority aggregate.

### Offer/Catalog

What can be purchased and under what conditions.

### Stock

- infinite/produced;
- finite inventory;
- per-scope stock;
- generated/restocked stock.

### PricePolicy

Inputs may include base price, relationship/reputation, faction, scarcity, time, actor traits, and world facts.

### Currency/PaymentPolicy

Typed accepted payment resources/items.

### PurchaseAdmissionPolicy

Who may buy.

### SellAcceptancePolicy

What the provider will buy.

### LiquidityPolicy

How much currency/value the provider can spend buying from players.

### RestockPolicy

- scheduled;
- derived;
- population/supply driven;
- finite no-restock.

### CommerceTransaction

Immediate buy/sell/barter transfer commits atomically within one authority.

Cross-authority commerce uses explicit transfer protocol, not a pretend transaction.

### Presentation/Narration

Catalog/list/value/buy/sell responses derive from the same contract for text and touch UI.

## 14. Service primitives

Existing v3 service composition remains the model for non-instant or scarce work:

- AdmissionPolicy;
- CapacityPolicy;
- CapacityScope;
- Queue/ReservationPolicy;
- InputEscrow;
- DurationPolicy;
- CompletionRule;
- OutputPolicy;
- CancellationPolicy;
- Cooldown/RatePolicy;
- ServiceJob.

Examples include smithy, healer, trainer, ferry, inn room, ritual altar, processor, and auction window.

Commerce and Service may compose but are not identical.

## 15. Crafting, gathering, and production primitives

Candidate decomposition:

- ResourceNode;
- HarvestPolicy;
- RegenerationPolicy;
- Recipe;
- IngredientRequirement;
- ToolRequirement;
- Transformation;
- QualityPolicy;
- Byproduct;
- ProductionStation;
- ServiceJob/Duration;
- OutputOwnership.

A crafting station should not become a giant bespoke subsystem if recipes + services + containment can express it.

## 16. Social-world primitives

### Dialogue

Typed graph with policies/actions/events.

### SocialAction / Emote

Data-driven actor/target/observer narration plus optional typed semantic consequences where explicitly allowed.

### Relationship

Scoped relationship values such as trust, affinity, fear, debt, or respect.

### Memory

Typed durable remembered fact involving a subject.

### Faction

- membership;
- standing/reputation;
- faction relationships;
- policy hooks.

### Party/group

Membership and leadership semantics distinct from quest progress.

### Rumor

Potential reusable composite:

~~~text
source fact/event
 -> rumor item/topic
 -> eligible carriers/channels
 -> spread/acquisition rule
 -> dialogue/ambient availability
~~~

A first implementation can be simple fact-driven rumor availability; later simulation can become richer.

### Witness/knowledge

Potential primitive for who actually observed/knows an event, useful for quests, crime, rumor, and social reactions.

### Crime/law/jurisdiction

Later capability candidate composed from offense event, witness/knowledge, jurisdiction, faction/law policy, wanted/reputation fact, and guard ReactionRules.

Do not hardcode a universal crime system into the foundation.

## 17. Environmental and ecological primitives

Candidate library:

- world calendar;
- day/night/light;
- weather;
- season;
- temperature;
- terrain;
- water/swimming;
- hazard;
- shelter;
- ambient emitters;
- region modifiers;
- plant/growth state;
- resource regeneration;
- migration/population patterns;
- decay/spoilage;
- fire/flood or other hazards where a cartridge requires them.

Prefer derived/on-demand state where possible instead of universal ticking.

## 18. Narrative primitives

Narrative is not separate from the world; it coordinates world primitives.

Foundation narrative vocabulary should include:

- Fact;
- DomainEvent;
- QuestDefinition;
- QuestInstance;
- objective operators;
- activation/reveal;
- named outcomes;
- typed consequences;
- Dialogue;
- SceneDefinition;
- SceneInstance;
- NarrationSpec;
- WorldEventPlan;
- journal/hint/reveal metadata;
- map discovery;
- campaign continuity ports.

Detailed quest/scene semantics live in [06 — Quests, Dialogue, Actions, and Scripting](06-quests-dialogue-actions-scripting.md).

## 19. Spatial instance and scene primitives

### InstancePlan / scoped spatial instance

Interactive temporary spaces are a spatial primitive, not a special dream mechanic.

An **InstancePlan** describes how precompiled spatial definitions are instantiated for a
bounded participant/scope and lifecycle.

Candidate fields:

- source AreaDefinition / room-subgraph / exported entry port;
- instancing closure/import bindings;
- participant/admission policy;
- semantic progress/consequence scope;
- audience;
- authority placement policy;
- entry/exit/mount bindings;
- initial SpawnBundles / PopulationPlans / ActivationGroups;
- persistence policy;
- reset/re-entry policy;
- teardown/expiry policy;
- reconnect policy;
- explicit export/continuity rules.

Examples:

- private quest dungeon;
- party puzzle;
- dream world;
- memory/flashback;
- tutorial simulation;
- trial/ritual space;
- temporary event arena.

An InstancePlan creates **runtime instances of immutable definitions**. It does not
dynamically invent uncertified room definitions.

### Instancing closure and anti-cloning rules

"Instantiate this area" MUST NOT mean "deep-copy every referenced runtime thing."

The compiler/runtime determines an explicit **instancing closure**:

- definitions inside the closure that declare compatible instancing semantics create
  new instance-scoped runtime entities/state;
- references to shared/external entities, services, account state, Realm facts, or other
  authorities use explicit import/binding semantics;
- singleton/unique/non-instantiable definitions cannot be cloned merely because they are
  referenced by an instanced room;
- player/account-owned inventory is transferred/represented only through its owning
  authority contract, never duplicated into the instance;
- shared merchants/services/factions may be referenced as shared services only when the
  deployment explicitly allows that interaction; otherwise the instance uses its own
  authored provider/entity;
- exports on teardown are explicit typed consequences/continuity data, not arbitrary
  copying of temporary state back to the parent world.

The compiler should reject an InstancePlan whose closure/import/export semantics are
ambiguous.

This prevents an interactive dream, dungeon, or flashback from accidentally cloning a
unique Realm NPC, duplicating a player's sword, or creating a second authoritative copy
of shared economy/state.

In Story Mode, a local authority may host the scoped subspace inside the same local
world authority when that preserves one mutation owner.

In Realm Mode, genuinely independent physical simulation uses the existing
WorldInstance/private-party instancing contract. The plan does not imply that each room
or scene receives its own process.

### SceneSpace

A SceneSequence chooses a **SceneSpace** independently from its narrative beats:

- `current_world` — ordinary current world geometry/state;
- `scoped_overlay` — shared geometry with participant-specific presence/presentation/actions;
- `instance` — an InstancePlan-created temporary/private/party spatial simulation.

This lets one SceneSequence primitive support both a two-paragraph vision and a fully
interactive dream dungeon without conflating sequencing with spatial simulation.


## 20. Scene and sequence primitives

A **SceneSequence** is a reusable, recoverable orchestration primitive for:

- text cutscenes;
- dream/vision sequences;
- conversations with staged actions;
- ceremonies;
- travel interludes;
- scripted reveals;
- tutorial moments;
- quest milestones.

SceneSequence may also use durable named SceneRoleBindings resolved inside its SceneSpace,
as specified in document 06. Scene beats should target semantic roles/bound runtime
identities rather than repeatedly searching player-facing names.

Potential registered step vocabulary:

- narrate;
- dialogue;
- present detail/image/audio hint;
- choice;
- check;
- branch;
- wait for player acknowledgement;
- await typed DomainEvent;
- advance logical time where explicitly permitted;
- request typed consequence;
- set/clear presentation overlay;
- checkpoint;
- end.

Scene steps do not directly edit arbitrary state.

A consequential SceneInstance is durable/idempotent and can resume after crash/reconnect.

## 21. WorldEventPlan composite

A world event is a higher-level composition, not a new authority.

Examples include festival, storm, siege, plague response, election, rebuilding effort, invasion, and pilgrimage.

A WorldEventPlan may compose:

- activation trigger;
- scoped state machine/phases;
- facts;
- PopulationPlans;
- schedule changes;
- merchant/service changes;
- ambient/narration;
- scenes;
- quests;
- completion/failure outcomes.

This pattern lets a builder create large living-world changes from existing primitives.

## 22. Examples of emergent domain composites

### Merchant

~~~text
NPC/provider
+ CommerceProvider
+ Catalog/Stock
+ PricePolicy
+ Purchase/Sell policies
+ Currency
+ Schedule
+ Relationship/reputation modifiers
+ Narration
~~~

### Smithy

~~~text
Merchant/offer
+ recipe/input requirements
+ CapacityPolicy
+ Reservation/Queue
+ Escrow
+ Duration
+ ServiceJob
+ OutputPolicy
~~~

### Ferry

~~~text
Schedule
+ Capacity
+ Reservation
+ fare CommerceTransaction
+ participant set
+ connection/transport transition
+ Scene/Narration
~~~

### Inn

~~~text
Merchant
+ finite room/resource stock
+ reservation
+ duration/occupancy
+ access policy
+ rest/sleep action
+ optional dream Scene trigger
~~~

### Guard checkpoint

~~~text
Connection/Barrier
+ guard population
+ perception
+ faction/reputation policy
+ Dialogue
+ ReactionRule
+ optional Commerce/permit
~~~

### Haunted shrine

~~~text
InspectableDetails
+ time/weather perception variants
+ player-scoped apparition overlay
+ ReactionRules
+ dream SceneSequence
+ quest facts/outcomes
~~~

### Festival

~~~text
WorldEventPlan
+ area activation groups
+ temporary PopulationPlans
+ merchant overlays
+ ambience
+ schedules
+ services
+ quests/scenes
~~~

### Siege

~~~text
WorldEventPlan phase machine
+ faction state
+ PopulationPlans/encounters
+ shared resources/services
+ connection/barrier states
+ quests
+ participant credit
+ narration/scenes
~~~

The value of the primitive architecture is that none of these require one giant hardcoded subsystem.

## 23. Builder semantic operations

The Builder API SHOULD expose intent-level operations in addition to generic CRUD.

Candidate operations:

~~~text
topology.connect
topology.disconnect
topology.make_barrier
detail.add
detail.reveal
policy.attach
action.add
action_recipe.create
reaction.add
behavior.add
behavior.configure
spawn_bundle.create
population.add
encounter.create
merchant.configure
service.configure
recipe.create
relationship.define
faction.define
rumor.define
scene.create
scene.add_beat
quest.attach_scene
world_event.create
world_event.add_phase
~~~

These operations:

- expand to ordinary workspace source edits;
- validate cross-file invariants;
- preserve revision/idempotency semantics;
- support dry-run/diff;
- are available to terminal/MCP/AI through the same canonical API.

## 24. Primitive graduation rule

Do not make every brainstormed concept a foundation requirement.

A candidate becomes an engine primitive when evidence shows that it:

1. recurs across multiple content uses;
2. has important invariants that should not be reimplemented in scripts;
3. benefits from machine-readable Builder discovery;
4. needs deterministic cross-host semantics;
5. needs specialized certification/property tests;
6. materially reduces bespoke content logic.

Otherwise keep it as a composition recipe, template/archetype, ReactionRule, quest/scene pattern, or bounded LokaScript.

This prevents primitive from becoming another word for every possible feature.

## 25. Builder expression test

Before accepting the v3 primitive layer, an advanced builder should be able to express—without engine-code changes—examples such as:

- a ferryman whose availability depends on tide/time and reputation;
- a shop whose prices and inventory change after a quest outcome;
- guards who lock gates at night and respond to an alarm;
- a rare herb that regrows after several world days;
- a smithy with one shared forge slot and overnight work;
- a personal ghost visible to one player in a shared square;
- a dream entered after sleeping at a specific shrine;
- a ritual requiring three participants and escrowed offerings;
- a town festival that changes schedules, merchants, ambience, and quests;
- a branching rescue quest that permanently alters NPC relationships, routes, rumors, and follow-up content;
- a text cutscene that pauses safely, survives reconnect, offers a choice, and mutates world state through typed consequences;
- an invasion event with phases, populations, services, and public progress.

If such content requires arbitrary host code despite all needed semantic atoms already existing, the composition layer is too weak.

If expressing it requires bypassing typed authority semantics, the composition layer is too powerful in the wrong way.


## 26. Choosing the right composition shape

Builder tooling SHOULD guide authors toward the smallest semantic shape that fits the mechanic.

| Author intent | Preferred shape | Why |
|---|---|---|
| One player verb with immediate bounded outcome | **ActionRecipe / ComposedAction** | Defines target, policy, costs/check, consequences/events, narration in one authority decision. |
| "When X happens, react with Y" | **ReactionRule** | Event/fact/state-transition driven glue with typed consequences. |
| Autonomous actor routine/decision | **Behavior** | Produces an intent that deterministic arbitration turns into an internal Command. |
| Explicit durable modes and legal transitions | **StateMachine** | Makes phase/state invariants inspectable and testable. |
| Ordered multi-beat interaction that may wait for input/events | **SceneSequence** | Durable checkpoints, choices, narration, restricted actions, crash/reconnect recovery. |
| Long-running/scarce work | **Service + ServiceJob** | Capacity, reservation, escrow, duration, completion, cancellation. |
| Replenishing/maintaining world population | **PopulationPlan** | Scoped counts, provenance, placement, replenishment, cleanup. |
| Coordinated encounter with participants/phases/cleanup | **EncounterPlan** | Composes population, phase state, conditions, scenes, rewards. |
| Goal/progress/branch thread for a character/party/world | **Quest** | Observes events/state, remembers progress, produces named outcomes/consequences. |
| Multi-phase public or regional living-world change | **WorldEventPlan** | Coordinates ordinary populations, schedules, services, scenes, quests, facts. |
| Reusable authoring pattern with no new runtime semantics | **Template / mixin / archetype / recipe** | Compile-time reuse; flattened before runtime. |
| Small pure calculation/branching awkward in declarative data | **LokaScript** | Bounded deterministic escape hatch over already-registered semantics. |
| Repeated mechanic with new invariants not expressible above | **New versioned Capability** | Moves genuine semantic power into engine-owned, tested contracts. |

### Escalation rule

Do not choose a more powerful layer merely because it is convenient.

Prefer:

~~~text
declarative configuration
  -> ActionRecipe / ReactionRule / Behavior / StateMachine
  -> SceneSequence / PopulationPlan / Service / Quest / WorldEventPlan
  -> bounded LokaScript
  -> new engine Capability
~~~

The ordering is not a strict hierarchy of runtime cost; it is an **escape-hatch discipline**. Use the most specific typed construct that captures the invariant.

## 27. Additional immersive-world capability candidates

The following families are worth preserving in the design vocabulary, but they are **not all foundation requirements**. They graduate under §24 only when real cartridge/Realm evidence justifies them.

### Knowledge, secrecy, and information flow

Potential primitives/composites:

- KnowledgeFact / discovery state: what a player/NPC is known to know;
- WitnessRecord: who actually perceived an event;
- Concealment / reveal / investigation;
- Evidence / clue;
- RumorTopic and propagation;
- Secret/access classification;
- Recognition/identity knowledge;
- map/topology knowledge separate from actual topology.

These support mysteries, crime, diplomacy, rumors, NPC memory, and discovery-heavy quests without treating omniscient world state as universally known.

### Language and communication

Potential capability family:

- Language/Comprehension;
- speech/listen range or channel policy;
- whisper/shout/emote/social actions;
- written text/readability;
- Message/Letter/Courier/Mail;
- public board/notice;
- party/guild/channel communication in Realm;
- translation/interpreter effects.

Semantic communication events should remain distinct from transport/socket messages.

### Households, roles, institutions, and obligations

Potential composable concepts:

- Household/group membership;
- Role/Office/Occupation;
- Institution/Guild/Temple/Clan;
- Duty/Shift assignment;
- Contract/Promise/Oath;
- Debt/Obligation/Favor;
- Property ownership/lease/access;
- reputation/standing per institution.

These can be built on typed relationships, facts, schedules, commerce, services, and policies rather than one giant society subsystem.

### Travel and transportation

Potential capabilities:

- Vehicle/Mount;
- passenger/cargo containment;
- route/stop;
- timetable;
- fare/payment;
- capacity/reservation;
- travel duration;
- boarding/disembarkation;
- journey scene/encounter hooks;
- weather/terrain restrictions.

A ferry, caravan, train, ship, elevator, or palanquin should share lower primitives wherever fiction permits.

### Property, housing, and persistent places

Potential composition:

- ownership/lease relation;
- access policy;
- storage/container;
- occupancy;
- rent/service;
- customization slots;
- guest permissions;
- upkeep/decay if desired.

Property is gameplay ownership/control; it does not imply a new mutation authority.

### Economic production and supply

Beyond individual merchants/crafting:

- Producer/Consumer;
- Stockpile;
- ProductionRecipe;
- Input/Output flow;
- transport/cargo;
- restock source;
- scarcity/price signals;
- wages/payments;
- market/order mechanism where a cartridge needs it.

Start with simple deterministic stock/restock. Simulated supply chains should be added only when they create meaningful play rather than background complexity.

### Needs, drives, and utility-based behavior

Optional NPC simulation may expose typed Drives such as:

- hunger/thirst/rest;
- safety/fear;
- duty/work;
- social affiliation;
- shelter;
- curiosity/goal pursuit.

Drives do not directly act. They contribute bounded, explainable scores/eligibility to Behavior intent arbitration.

This can make NPCs feel less clockwork while retaining deterministic traceability.

### Navigation and spatial reasoning

Potential reusable services/capabilities:

- path query;
- reachability;
- travel-cost model;
- route preference;
- hazard avoidance;
- territory restriction;
- pursuit/escape routing.

Pathfinding is a pure query/service to Behaviors and tools; it is not authority.

### Hazards, traps, and environmental interactions

Potential primitives:

- Hazard;
- exposure;
- trigger;
- detection/disarm;
- resistance/protection;
- periodic/derived effects;
- environmental transformation;
- fire/flood/collapse/spread where explicitly supported.

Prefer reusable trigger/check/status/consequence composition over bespoke trap code.

### Historical trace and world memory

Not full event sourcing, but selected durable history may be useful for:

- memorials/chronicles;
- NPC memory;
- rumor/evidence;
- statistics/achievements;
- world-event aftermath;
- procedural descriptions.

Only explicitly retained semantic records become gameplay inputs. Telemetry/log history is not silently queryable game state.

### Companion and follower systems

Can compose:

- Relationship;
- membership/party;
- follow/escort relation;
- Behavior;
- orders/Actions;
- trust/loyalty;
- inventory/equipment;
- dialogue/memory;
- separation/rejoin policy;
- death/recovery policy.

A companion should not require a separate engine architecture.

### Books, documents, and authored information objects

Potential capability:

- readable pages/sections;
- language/comprehension;
- annotations;
- clue/knowledge grants;
- ownership/copying;
- provenance/forgery where needed.

This supports lore-heavy worlds without encoding every book as arbitrary script.

### Ritual and multi-participant interaction

Potential composition:

- participant selector/set;
- roles/positions;
- prerequisites;
- offerings/escrow;
- synchronized actions;
- SceneSequence;
- duration;
- interruption;
- outcome/consequences.

This generalizes beyond "rituals" to ceremonies, performances, group crafting, debates, or cooperative mechanisms.

### Governance and territory

Later Realm candidates:

- jurisdiction/territory;
- office/role;
- rule/policy set;
- election/appointment;
- taxation/fees;
- public project/resource;
- faction control;
- law/crime reactions.

Use facts, institutions, relationships, commerce, WorldEventPlan, and policies first. Add dedicated semantics only where concurrency/invariants demand them.

The purpose of this catalog is to make future composition opportunities visible—not to make R3/R5 a checklist for an entire simulated civilization.

## 28. Capabilities graduated by the first cartridge

`00-first-cartridge-design.md` pulls the following capabilities that §4–§27 name only as candidates or not at all. They graduate under the §24 rule on the strength of one real cartridge, which is the weakest admissible evidence, so each entry must ship with its invariants and Lab fixtures in the phase that builds it. Exact field vocabularies freeze in that phase per document 14 R3B, not here.

Layer refers to §2. Portability is `portable` unless stated; the first cartridge is `offline_private`, so nothing here may be `server_only`.

| Capability | Layer | Core invariant | Required fixture |
|---|---|---|---|
| `tide@1` | L2 | tide state is derived from the calendar, never stored or ticked; a `(tide)` Connection is traversable iff the derived state permits | replay across a tide boundary at arbitrary save points yields identical traversal results |
| `mount@1` | L3 | a mount is a RuntimeEntity in a follow relation; rider location equals mount location while mounted; a mount cannot enter a Connection whose traversal mode excludes it | dismount forced at a fen edge; mount HP and hunger persist through save; no duplicate mount on reconnect |
| `sense_cue@1` | L2 | cues are projection only; propagation range is declared per cue; no authoritative state | bell rung in belfry appears in every z0 Ashmere room's projection and nowhere in Harrowgate |
| `skills@1` learn-by-doing | L2 | increment happens only inside the committed decision of a successful Check; bounded per world day | 1,000 retried checks under crash injection never double-increment |
| `spell_words@1` | L3 | combination table is compiled cartridge data; an unknown pair fails closed | `ward + light` produces sanctuary on every host; `ward + chill` is a typed rejection |
| `position@1` | L2 | one position per character; combat and regen read it; sleeping characters take double damage and cannot act | wake on damage exactly once; save mid-sleep resumes asleep |
| `collection@1` | L2 | player-scoped facts; projection only; never a policy input for gameplay legality | bestiary counts survive death and ironman reset rules as declared |
| `equipment@1` cursed | L2 | a cursed item's unequip Action is absent from the ActionSet until the curse status is removed | forged unequip invocation rejected (ACT-09 pattern) |
| `liquid@1` | L2 | a container holds one liquid kind and a quantity; fill/pour conserve quantity; spoilage is derived time | pour-into-self, overfill, and mixed-kind pours are typed rejections |
| `readable@1` | L2 | pages are definition content; boards and mail are runtime readables with author provenance; reading may grant topics/facts exactly once | re-reading never re-grants |
| `identity_knowledge@1` | L2 | player-scoped map of definition → known/unknown; unknown items project a placeholder name and hide affects | `reveal` word and library identify both flip the same fact once |
| TargetSpec adjacent-room scope | L1 | candidate scope may include rooms one Connection away when the Action declares it; resolution remains none/unique/ambiguous | bow shot into a dark room without light resolves `none` |
| `stance@1` | L2 | three states; modifier table is registry data; changing stance is an Action with a cooldown | stance persists through save and combat rounds |
| `pet@1` | L3 | growth stages derive from logical time since adoption; loyalty is a Relationship; a dead pet is a corpse, not a respawn | 30-day simulation: pup reaches adult exactly once; feeding gaps apply declared penalties |
| `hunt@1` | L3 | a Behavior that reads Memory of the last attacker and pursues within area bounds for a declared duration | wight follows through two rooms then forgets after the window |
| `death@1` ghost policy | L2/L3 | on death the character enters a ghost ActionSet (move, look, recall, touch corpse); corpse is a container with a cleanup policy; resurrection is a Service; ironman maps death to a terminal save state | crash at every boundary of death → ghost → corpse touch → restore; inventory never duplicated or lost |
| `commerce@1` barter | L4 | an offer may be item-for-item with no currency path; acceptance is one CommerceTransaction | conservation holds; partial acceptance is impossible |
| `property@1` | L4 | ownership is a typed relation; access policy on the property's Connections and containers reads it; furniture slots are containment with a slot key | buying twice is a typed rejection; a wanted player's cottage remains theirs |
| `steal@1` | L3 | a Check whose failure emits a `crime_witnessed` event to every NPC in the room whose PerceptionPolicy passes; success moves the item and sets a `stolen` flag | sneaking with no witnesses never emits; a blind NPC never witnesses |
| `law@1` | L4 | wanted state is a per-faction player-scoped fact set only by `crime_witnessed` reactions; arrest is a guard Behavior that requires adjacency and the wanted fact; jail is a SceneSpace overlay with a restricted ActionSet and a duration; trial is a SceneSequence | escape via lockpick sets wanted again; serving the term clears exactly once; a Priory-wanted player is not arrested by the Crown |
| `mail@1` | L4 | sending creates a ServiceJob whose completion places a runtime readable in the recipient's inbox container; NPC replies are ReactionRules on delivery | app closed across delivery time: exactly one letter on resume |
| `drives@1` | L3 | drives are bounded scores derived from resources and time; they contribute to Behavior arbitration and never act directly | noon hunger sends Peg to the inn on every host in the same round |
| `topics@1` | L2 | player-scoped set; a topic is added by dialogue nodes, details, and readables that declare it; "Ask about" chips project only known topics; saying an unknown topic is still legal in the text drawer | topic learned once cannot be unlearned except by declared consequence |
| `recognition@1` | L3 | NPC recognition of a character is a Memory keyed by displayed identity; disguise changes displayed identity for a duration; guard arrest reads recognition, not the wanted fact directly | disguised wanted player passes the gate; recognition Check on close inspection strips the disguise |
| NPC-to-NPC `commerce@1` job | L4 | a scheduled authority-internal Command performs a CommerceTransaction between two providers; stock moves, currency is conserved | 90-day simulation: chandler herb stock equals Sedge's sales; no item created from nothing |
| `quest@1` protect / survive / race | L3 | protect: named entity alive when the window closes; survive: actor alive and present through the window; race: actor reaches target before a declared event fires; all three are pure reducers over existing events | each has a pass, a fail, and a retry-after-crash fixture |
| `track@1` | L3 | a trail is a set of player-scoped facts on Connections that decay by derived time; the track Check reveals the next Connection only | trail from fox hollow to reed bank replays identically on every host |
| speech pose | L2 | a pose is a per-character NarrationSpec fragment included in room projection until changed or the character moves | pose survives save; clears on movement |
| `performance@1` | L3 | an ActionRecipe pattern that applies a room-scoped timed status to eligible listeners; requires an instrument item | two bards in one room compose by the registered rule, not last-writer-wins (ARCH-10) |

Two rules apply to every row:

1. none of these introduce a second mutation path; each is Actions, ReactionRules, Behaviors, Services, or derived state over existing authority contracts;
2. a later cartridge that does not pull a capability here does not pay for it; the certification registry's capability-triggered class (document 09 §20) scopes its gates to cartridges whose lock includes it.

## 29. Readiness subset and author decision guide

The initial executable subset follows 04 §5.2–5.5, not the entire candidate catalog above. Use a pure query/derived description when nothing must be remembered; a typed fact for distinct narrative history; an ActionRecipe for one bounded immediate verb; a reaction for a registered event; a quest/scene/job for persisted continuation. Reuse a named source-mapped recipe before requesting a new capability. R6P's two choices exercise the same registered transfers, lifecycle transitions and facts. A shrine offering or witness testimony can be a paper-level second composition example; a scarce smithy queue still waits for its actual capacity/job capability rather than being faked with generic setters.

Capabilities graduate on demonstrated need, coherent reusable semantics, bounded execution, clear ownership, migration/invariant fixtures and author diagnostics. This amendment does not expand the chapter-one capability lock or make any future catalog family an R1 prerequisite.

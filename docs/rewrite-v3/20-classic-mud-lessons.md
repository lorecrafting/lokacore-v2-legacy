# 20 — Classic MUD Design Review: DikuMUD, CircleMUD, and TinyMUD

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Informative prior-art evidence.

Study patterns and tradeoffs, not source code or a mandate to build every classic mechanic before the first release.

<details>
<summary>Sections in this document</summary>

- [1. Summary](#1-summary)
- [2. What Loka already gets right](#2-what-loka-already-gets-right)
- [3. Diku/Circle: prototype + population recipe is the important pattern](#3-dikucircle-prototype--population-recipe-is-the-important-pattern)
- [4. Diku/Circle: tiny orthogonal NPC behavior is powerful](#4-dikucircle-tiny-orthogonal-npc-behavior-is-powerful)
- [5. Diku special procedures: preserve the power, reject the escape hatch](#5-diku-special-procedures-preserve-the-power-reject-the-escape-hatch)
- [6. Circle extra descriptions: world density without entity inflation](#6-circle-extra-descriptions-world-density-without-entity-inflation)
- [7. Circle door halves expose an invariant Loka should fix](#7-circle-door-halves-expose-an-invariant-loka-should-fix)
- [8. Circle shops validate data-driven commerce](#8-circle-shops-validate-data-driven-commerce)
- [9. Circle socials and TinyMUD success/failure messages: audience-aware narration](#9-circle-socials-and-tinymud-successfailure-messages-audience-aware-narration)
- [10. TinyMUD: relationships are more important than a universal object type](#10-tinymud-relationships-are-more-important-than-a-universal-object-type)
- [11. TinyMUD matching: target resolution is game UX](#11-tinymud-matching-target-resolution-is-game-ux)
- [12. TinyMUD locks validate a compact policy grammar](#12-tinymud-locks-validate-a-compact-policy-grammar)
- [13. TinyMUD builder verbs: author intent should be semantic](#13-tinymud-builder-verbs-author-intent-should-be-semantic)
- [14. What not to copy](#14-what-not-to-copy)
- [15. Conformance cartridge suggested by this review](#15-conformance-cartridge-suggested-by-this-review)
- [16. Sources reviewed](#16-sources-reviewed)

</details>
<!-- packet-navigation:end -->

**Status:** informative/reference evidence for the v3 architecture.  
**Review baseline:** original/preserved DikuMUD and TinyMUD source plus CircleMUD builder documentation reviewed for architectural and world-building lessons.

This review is clean-room design evidence. Loka v3 does not copy classic source code, file formats, content, numeric identifiers, process loops, or storage models.

## 1. Summary

The classic codebases are complementary:

- **DikuMUD/CircleMUD** are strongest at curated RPG mechanics, prototype/instance distinction, area building, population recipes, data-driven shops/socials, and a compact vocabulary of reusable NPC behavior.
- **TinyMUD** is strongest at world manipulability: a small relational object model, location/containment, ownership/control, locks, search scopes, and builder verbs that manipulate the world directly.

Loka v3 should borrow their **contracts and conventions**, not their C-era implementations.

The strongest additions suggested by this review are:

1. first-class deterministic target resolution;
2. lightweight inspectable details;
3. coherent connection/barrier state;
4. explicit SpawnBundle + PopulationPlan composition;
5. typed ReactionRule as the safe descendant of Diku special procedures;
6. deterministic Behavior arbitration;
7. authored geography separated from runtime shard ownership;
8. a real commerce/merchant contract;
9. semantic Builder verbs in addition to CRUD;
10. a small classic-MUD mechanics conformance cartridge with heavy quest/story coverage.

These are specified normatively in [21 — Composable World Primitives and Builder Expressivity](21-composable-world-primitives.md) and the relevant existing v3 documents.

## 2. What Loka already gets right

Several v3 decisions are already modernized versions of durable classic-MUD ideas.

### Definition versus runtime instance

Diku/Circle load mobile/object prototypes and instantiate runtime copies. Loka formalizes this as immutable cartridge definitions plus mutable runtime entities.

Keep the v3 model. Do not carry forward:

- global numeric VNUM identity;
- mutable prototype tables as runtime truth;
- file-position/index identity;
- implicit latest-installed references.

### Content packages and areas

Circle areas/zones are authoring modules containing geography, mobs, objects, shops, and population/reset instructions. Builders were encouraged to keep zones reasonably self-contained because unnecessary cross-zone dependencies reduced portability.

Loka cartridges and explicit composition ports are a stronger package boundary.

However, a cartridge may contain several coherent authored geographical regions. V3 should support an **AreaDefinition** concept without equating it with an OTP ZoneShard.

### Builder versus coder

Circle explicitly separates world builders from engine coders. Builders author data; coders add engine mechanics.

This maps directly to v3:

- normal story/world creation uses registered capabilities and composition;
- repeated missing semantics become an engine capability proposal;
- arbitrary code is not the normal content format.

Loka should preserve this separation while giving builders substantially more expressive composition tools than classic data files provided.

## 3. Diku/Circle: prototype + population recipe is the important pattern

Classic Diku world boot separates:

- room definitions;
- mobile prototypes;
- object prototypes;
- runtime mobile/object instances;
- a zone reset command table that composes those prototypes into an inhabited world.

Circle documents reset commands such as:

- load mobile;
- load object;
- give/equip object;
- put object inside another object;
- set door state;
- cap how many copies may exist.

The positional reset language itself is not suitable for Loka. It has hidden context such as last-mobile-loaded, global counts, and destructive reset assumptions.

The useful architectural idea is:

> A world needs a declarative population/composition plan distinct from the definitions being instantiated.

### Loka adaptation

Use explicit typed concepts:

- **SpawnBundle** — a named nested composition such as NPC + inventory + equipment + contained objects;
- **PopulationPlan** — desired population, scope, placement, replenishment, activation policy, cleanup policy, schedule, and provenance;
- **EncounterPlan** — optional higher-level coordinated encounter composition built from PopulationPlan + policies/reactions.

No implicit previous command. Every dependency has a named reference.

Population reconciliation owns only instances created under that population provenance. It must never reset an area by deleting unrelated player-owned or independently mutated state.

## 4. Diku/Circle: tiny orthogonal NPC behavior is powerful

Original Diku mobile activity combines small behavior conventions such as:

- sentinel/stationary;
- scavenging;
- wandering;
- stay within area/zone;
- aggression;
- flee/wimpy behavior.

The important lesson is not the exact flags. It is that believable behavior often emerges from **small orthogonal primitives**.

### Loka adaptation

Represent behavior as typed capability data:

- schedule;
- patrol;
- wander;
- guard;
- pursue;
- flee;
- assist;
- scavenge;
- work;
- sleep/rest;
- seek-service;
- socialize;
- react to weather/facts/events.

Do not encode these as bitvectors. Do not make absence of one flag imply hidden behavior.

Multiple active Behaviors need deterministic **intent arbitration** rather than accidental source-order precedence.

## 5. Diku special procedures: preserve the power, reject the escape hatch

Diku special procedures let rooms, mobiles, and objects execute custom C behavior and intercept commands. This enabled highly memorable local mechanics:

- trainers;
- shops;
- mayors;
- puzzle rooms;
- scripted NPCs;
- unusual object behavior.

This gave builders enormous expressive power once a coder supplied the procedure.

It also bypassed ordinary semantics and turned local mechanics into arbitrary callbacks.

### Loka adaptation

The safe descendant is a **ReactionRule** plus registered capabilities.

A ReactionRule:

1. observes a typed DomainEvent or fact transition;
2. optionally matches a target/selector;
3. evaluates a typed Policy;
4. requests registered consequence operations;
5. runs inside the normal bounded deterministic decision/event chain.

It does not:

- intercept raw transport text;
- call persistence;
- call PubSub;
- use filesystem/network;
- mutate arbitrary component fields;
- invent new authority semantics.

If a mechanic needs new semantic power, an engine developer adds a versioned capability. Once registered, builders can compose it freely.

That preserves the expressive benefit of special procedures without creating a hidden second engine.

## 6. Circle extra descriptions: world density without entity inflation

Circle rooms and objects support keyed extra descriptions. A room can mention a mural, crack, window, statue, stain, bookshelf, or distant landmark without each detail becoming a full simulation object.

This is an important immersion primitive.

### Loka adaptation

Add **InspectableDetail**:

- stable local key;
- aliases/keywords;
- localized description;
- visibility/perception policy;
- conditional variants;
- optional presentation actions;
- optional facts/reveal state.

A detail is not a RuntimeEntity by default.

Promote it to an entity only when it needs independent mutable identity such as:

- containment/inventory;
- combat;
- ownership;
- movement;
- durable mechanical state;
- independent targeting by many capabilities.

This lets builders author dense environments without creating thousands of meaningless entities.

## 7. Circle door halves expose an invariant Loka should fix

Classic room formats generally store direction/door state on each room side. Builder documentation warns about keeping reverse sides coherent.

### Loka adaptation

Treat a bidirectional door/gate/bridge as one logical **Connection/Barrier aggregate** with two presentation faces.

One authoritative mutable state controls:

- open/closed;
- locked/unlocked;
- lock/access policy;
- damage/repair state if supported;
- traversal state.

Explicitly asymmetric or one-way connections remain valid.

The invariant is:

> One semantic barrier must not acquire contradictory state merely because it is rendered from two rooms.

## 8. Circle shops validate data-driven commerce

Classic shops separate much of merchant behavior into data:

- provider/shopkeeper;
- produced/offered items;
- categories accepted for purchase;
- buy/sell price multipliers;
- opening hours;
- who the shop trades with;
- merchant messages.

The C implementation is old; the decomposition is still useful.

### Loka adaptation

Define commerce from reusable primitives:

- CommerceProvider;
- Offer/Catalog;
- Stock;
- PricePolicy;
- Currency/PaymentPolicy;
- PurchaseAcceptancePolicy;
- SellAcceptancePolicy;
- LiquidityPolicy;
- RestockPolicy;
- Schedule;
- AdmissionPolicy;
- Transaction/Narration policy.

Immediate buying/selling is one authoritative transaction.

Long-running services such as forging use the existing Service/Capacity/Reservation/ServiceJob family instead.

## 9. Circle socials and TinyMUD success/failure messages: audience-aware narration

Classic systems frequently distinguish:

- actor message;
- target/victim message;
- observer/room message;
- success/failure variants.

This is a durable text-world convention.

### Loka adaptation

Use **NarrationSpec** as presentation metadata attached to semantic outcomes.

Narration may define localized variants for:

- actor;
- target;
- eligible observers;
- private/system audience.

The projection layer applies AudiencePolicy/redaction.

Narration is not a DomainEvent and must not become gameplay authority.

The same semantic event can drive:

- terminal prose;
- mobile event log;
- animation/sound/haptics;
- accessibility narration.

## 10. TinyMUD: relationships are more important than a universal object type

TinyMUD uses a small object record with overloaded fields for Rooms, Things, Exits, and Players. Loka should not reproduce this physical model.

What matters is how much gameplay emerges from explicit relations:

- location;
- contents;
- exits/links;
- home/drop destination;
- owner/control;
- lock/access.

### Loka adaptation

Prefer reusable typed relationships over subsystem-local duplicate truth.

Important relations include:

- containment/location;
- equipment;
- topology/connection;
- ownership/custody;
- relationship/reputation;
- membership;
- follow/escort;
- service reservation/beneficiary;
- quest participation.

Each relation still has a capability-owned schema. This is not an untyped graph database.

## 11. TinyMUD matching: target resolution is game UX

TinyMUD explicitly searches different namespaces depending on the command:

- possessions;
- neighbors/current-room contents;
- exits;
- self;
- current room;
- privileged absolute/player search.

It can also return nothing or ambiguous.

This is the right conceptual direction, but old match paths can resolve collisions by random choice. Loka must not do that.

### Loka adaptation

Target resolution is a first-class deterministic contract.

An Action declares:

- accepted target kinds/capabilities;
- candidate scopes;
- visibility requirements;
- cardinality;
- whether ordinal selection is allowed;
- alias/keyword matching policy.

Resolution returns:

~~~text
none | unique(target) | ambiguous(candidates)
~~~

No random tie-breaking.

The authority re-resolves the final ActionInvocation against current state.

Touch may send stable IDs; text uses the same resolver.

## 12. TinyMUD locks validate a compact policy grammar

TinyMUD boolean locks show how much authoring power comes from a small compositional predicate language.

Loka's typed Policy AST is the correct modern version.

Builders should be able to combine:

- all/any/not;
- inventory;
- facts;
- quest state/outcomes;
- relationships/reputation;
- faction;
- stats/resources;
- permissions;
- time;
- target/location/presence;
- state-machine state;
- scope/audience conditions.

Unknown operators fail closed.

The key lesson is ergonomic:

> This gate requires the bronze seal or the ferryman's trust should be easy to express without scripting.

## 13. TinyMUD builder verbs: author intent should be semantic

TinyMUD exposed domain verbs such as dig/open/link/describe/lock rather than asking builders to edit raw database fields.

### Loka adaptation

Builder API should support both precise CRUD and higher-level semantic operations such as:

- topology.connect;
- topology.make_barrier;
- detail.add;
- policy.attach;
- reaction.add;
- population.add;
- merchant.configure;
- service.configure;
- quest.add_scene;
- scene.add_beat;
- world_event.configure.

Semantic operations validate invariants and can expand to several source edits.

This is especially important for AI builders: the API should speak world design, not storage layout.

A future in-world builder can be another adapter over the same Builder API rather than making live Realm state the source artifact.

## 14. What not to copy

| Classic pattern | Loka decision |
|---|---|
| global VNUM/dbref identity | cartridge-qualified DefinitionRef + runtime IDs |
| universal object struct with overloaded fields | typed components/relations |
| global linked lists/arrays | authority-owned state/indexes |
| fixed pulse scanning every mobile | derived time + schedulers + bounded simulation |
| destructive zone reset | provenance-safe PopulationPlan reconciliation |
| global max-existing count | explicit population/count scope |
| bitvector mechanic flags | typed capability schemas |
| type-dependent positional value fields | named typed fields |
| arbitrary special-procedure callback | ReactionRule + capability evaluator |
| raw text-command interception | ActionInvocation + authority Command |
| source-order abbreviation behavior | unique deterministic alias resolution |
| random target tie-break | explicit ambiguity |
| independent mutable door halves | shared Connection/Barrier state |
| owner conflated with process authority | gameplay ownership/control separate from mutation owner |
| production runtime edits as source content | Builder workspace + immutable cartridge release |

## 15. Conformance cartridge suggested by this review

Create one deliberately small original cartridge—not copied classic content—that stresses the primitive vocabulary.

It should include at least:

- 8–15 places;
- several InspectableDetails that are not entities;
- one coherent bidirectional locked barrier;
- target-name ambiguity requiring explicit disambiguation;
- NPC schedule;
- patrol/wander;
- scavenge or acquire-interesting-object behavior;
- aggression/flee/assist interaction;
- merchant with hours, stock, price/admission policy;
- SpawnBundle with equipment/contained items;
- PopulationPlan with scoped replenishment;
- one queued/timed ServiceJob;
- one ReactionRule;
- actor/target/observer narration;
- a multi-step quest that launches scenes, mutates world state, and produces visibly different branch outcomes.

Run the same portable semantics under local Story authority and online-private BEAM authority and compare traces/GameViews.

The purpose is not nostalgia. It is to prove that Loka can reproduce the useful expressive range of mature text worlds from clean typed contracts.

## 16. Sources reviewed

Primary/reference sources used for this design pass include:

- preserved TinyMUD 1.5.4.1 source: https://github.com/josefcub/tinymud154
- preserved DikuMUD source lineage: https://github.com/sneezymud/dikumud
- DikuMUD Gamma archive: https://github.com/DikuMUDOmnibus/DikuMUD-Gamma
- CircleMUD Builder's Manual: https://www.circlemud.org/pub/CircleMUD/3.x/uncompressed/current/doc/building.pdf
- CircleMUD Documentation Project builder guidance: https://www.circlemud.org/cdp/building/building-1.html
- current tbaMUD/Circle lineage source where useful for comparison: https://github.com/tbamud/tbamud

Later derivatives may contain useful ideas, but this review tries to attribute a pattern to original/early sources when practical rather than projecting later MUSH/MUX or trigger-system features backward onto TinyMUD/Diku.

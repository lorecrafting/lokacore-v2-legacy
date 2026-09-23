# 12 — Evennia Design Review: What Loka v3 Should Learn

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Informative prior-art evidence.

Read as dated reasoning behind decisions, not as instructions to import Evennia or implement every listed feature.

<details>
<summary>Sections in this document</summary>

- [1. Summary](#1-summary)
- [2. Portal/Server separation](#2-portalserver-separation)
- [3. Typeclasses, Attributes, and Components](#3-typeclasses-attributes-and-components)
- [4. CmdSets are highly relevant to touch-first Loka](#4-cmdsets-are-highly-relevant-to-touch-first-loka)
- [5. Locks and fail-closed policy](#5-locks-and-fail-closed-policy)
- [6. Sessions, Accounts, and puppeting](#6-sessions-accounts-and-puppeting)
- [7. Tags and aliases](#7-tags-and-aliases)
- [8. Search is a feature, not a utility afterthought](#8-search-is-a-feature-not-a-utility-afterthought)
- [9. Prototypes and OLC](#9-prototypes-and-olc)
- [10. Protfuncs: controlled power for builders](#10-protfuncs-controlled-power-for-builders)
- [11. Scripts, tickers, tasks, and OnDemandHandler](#11-scripts-tickers-tasks-and-ondemandhandler)
- [12. Commands and automatic help](#12-commands-and-automatic-help)
- [13. Batch processors](#13-batch-processors)
- [14. Contrib ecosystem](#14-contrib-ecosystem)
- [15. Evennia ideas useful later](#15-evennia-ideas-useful-later)
- [16. Core contrast: Evennia object-centric vs Loka instance-centric](#16-core-contrast-evennia-object-centric-vs-loka-instance-centric)
- [17. Extended rooms: details without entity explosion](#17-extended-rooms-details-without-entity-explosion)
- [18. Safe barter/trade is worth adopting later](#18-safe-bartertrade-is-worth-adopting-later)
- [19. Independent escape/adventure instances validate the cartridge model](#19-independent-escapeadventure-instances-validate-the-cartridge-model)
- [20. Wilderness virtualization](#20-wilderness-virtualization)
- [21. XYZ-grid and route finding](#21-xyz-grid-and-route-finding)
- [22. RP recognition and language systems](#22-rp-recognition-and-language-systems)
- [23. Traits/buffs/cooldowns support the typed component direction](#23-traitsbuffscooldowns-support-the-typed-component-direction)
- [24. Crafting recipe/tool model](#24-crafting-recipetool-model)
- [25. Auditing and reports](#25-auditing-and-reports)
- [26. Batch processing validates source-controlled world building](#26-batch-processing-validates-source-controlled-world-building)
- [27. Contrib architecture validates capability packs—but not dynamic plugin chaos](#27-contrib-architecture-validates-capability-packsbut-not-dynamic-plugin-chaos)
- [28. Evennia feature ideas triage](#28-evennia-feature-ideas-triage)
- [29. Sources reviewed](#29-sources-reviewed)

</details>
<!-- packet-navigation:end -->

**Review baseline:** current Evennia documentation and main-branch architecture reviewed 2026-09-17.

Evennia is a mature Python/Twisted MUD/MU* framework. Loka v3 should not clone it, but its long operational history makes it valuable evidence about which abstractions survive years of text-world development.

## 1. Summary

### Adopt strongly

- Session → Account → Character separation.
- Command/action sets that compose with union/intersection/replacement.
- Fail-closed lock/access semantics.
- Indexed tags/aliases separate from arbitrary state.
- Explicit persistent vs non-persistent state.
- On-demand temporal computation instead of universal ticking.
- Persistent task/ticker concepts for work that really needs scheduling.
- Builder-safe controlled functions rather than arbitrary code.
- Prototype validation and builder-friendly templates.
- Search/disambiguation/aliases as first-class MUD UX.
- Generated help from command/capability definitions.
- Offline/batch building workflows.
- Transport/game-logic separation.

### Adapt to Elixir/BEAM

- Typeclasses → typed components/capabilities, not inheritance-heavy runtime classes.
- Portal/Server → gateway/runtime architectural boundary; only split OS processes if needed.
- Idmapper cache → one OTP world/shard owner plus explicit persistence, not model-instance magic.
- Scripts/TickerHandlers → world schedulers + derived time + durable jobs.
- Prototypes → compile-time templates/mixins flattened into cartridge definitions.
- REST object editing → canonical Builder API with workspace/revision boundaries.

### Do not copy

- arbitrary pickled/persistent attribute values;
- global dbrefs as content identity;
- deep runtime typeclass/prototype inheritance;
- executable batch code as normal content tooling;
- implicit database writes hidden behind object attribute assignment;
- one general event/ticker mechanism for every temporal need.

## 2. Portal/Server separation

Evennia splits network-facing Portal and game Server into separate Twisted processes. The Portal handles telnet/websocket/SSH and can remain connected while the game server reloads.

### Lesson

Transport must not know game internals, and game logic must not care how the player connected.

### Loka adaptation

Keep `loka_web` and `loka_runtime` as separate OTP/application boundaries.

Do **not** immediately duplicate Evennia's two-OS-process topology. OTP supervision and modern rolling deploys solve different problems; adding another network hop solely for reload continuity is premature.

Later, gateway/runtime can be deployed separately if uptime or protocol aggregation warrants it.

## 3. Typeclasses, Attributes, and Components

Evennia's central abstraction is a database model wrapped by a Python typeclass. Arbitrary persistent Attributes and non-persistent NAttributes attach state to objects. Evennia also has a Components contrib to move reusable functionality away from deep inheritance.

### What this validates

MUD entities need:

- extensible state;
- reusable behavior;
- persistent and ephemeral values;
- searchable labels.

### Loka adaptation

Prefer:

```text
Definition
  components: typed declarative capability data

Runtime Entity
  state: typed component state
  tags: indexed labels
  ephemeral: owner-process memory
```

Do not recreate arbitrary “anything goes” persistent Attributes. They are flexible but weaken validation, code generation, migration, and AI authoring.

## 4. CmdSets are highly relevant to touch-first Loka

Evennia CmdSets can merge through set operations such as Union, Intersect, and Replace. They allow available commands to change with game state without nesting endless conditionals.

Lokacore independently evolved something similar in its Action Resolver.

### Loka adaptation: ActionSet algebra

Formalize it.

An entity/context produces candidate actions from:

1. base definition;
2. equipment;
3. statuses;
4. quest/relationship grants;
5. scripts/capabilities;
6. room/zone restrictions;
7. account/character permissions.

Merge operations:

- **union** — add actions;
- **subtract** — remove actions;
- **intersect** — whitelist;
- **replace** — transformation/modal state;
- **override** — same action key with higher-priority implementation.

Then evaluate typed conditions and return an authority-resolved `ActionSet` (local Story authority or BEAM Realm authority).

This serves both:

- text commands;
- mobile contextual buttons.

The ActionSet should also be introspectable by the builder and test lab.

## 5. Locks and fail-closed policy

Evennia attaches lock strings to objects/commands and evaluates named lock functions. Missing access is denied by default.

### Loka adaptation

Use a typed Policy AST rather than free-form executable lock strings:

```yaml
policy:
  all:
    - permission: builder
    - any:
        - has_item: shrine_key
        - quest_outcome:
            quest: temple_intro
            outcome: completed
```

Required operators may include:

- all / any / not;
- permission/role;
- self/owner;
- tag;
- attribute/stat comparison;
- inventory ownership;
- quest availability/lifecycle/outcome;
- faction/reputation;
- world scope;
- time/window.

Unknown policy operators MUST fail closed.

Policies should protect exits/actions/content publication/builder tools as appropriate.

## 6. Sessions, Accounts, and puppeting

Evennia distinguishes physical connection Session, durable Account, and in-world Object/Character. It supports multiple sessions and different multi-puppeting modes.

### Loka adaptation

Keep Session, Account, Character separate from v3 day one.

Benefits:

- reconnect without corrupting character state;
- future multi-device support;
- guest/account upgrade;
- one account owning multiple characters;
- admin/session messaging;
- account-level entitlements and permissions;
- cartridge-local world state remains separate from connection lifecycle.

## 7. Tags and aliases

Evennia Tags are indexed markers shared across objects; aliases/permissions reuse similar infrastructure.

### Loka adaptation

Use indexed tags for:

- biome;
- faction membership labels;
- content queries;
- capability discovery;
- zone/category lookup;
- builder search.

Keep typed state in components, not tags.

Aliases/keywords are a separate searchable field used by the MUD command parser and accessibility tooling.

## 8. Search is a feature, not a utility afterthought

Traditional text interfaces need robust target resolution:

- local location + inventory scope by default;
- aliases/keywords;
- disambiguation among multiple matches;
- stable IDs for tools;
- optional global/admin search.

The touch client can bypass textual ambiguity by sending IDs, but the terminal, bots, and builders still benefit from a canonical Search service.

Loka v3 SHOULD have one target-resolution contract rather than ad-hoc “find by keyword” helpers in transport modules.

## 9. Prototypes and OLC

Evennia prototypes provide per-instance customization without requiring a class for every variation. They support inheritance, validation, permissions, controlled prototype functions, and OLC.

### Loka adaptation

The useful idea is **authoring-time reuse**, not runtime inheritance.

Support source-level templates/mixins such as:

```yaml
use:
  - npc.humanoid
  - behavior.shopkeeper
  - schedule.day_worker
```

The compiler:

1. resolves them;
2. applies deterministic merge rules;
3. detects cycles;
4. validates capability compatibility;
5. records provenance;
6. emits a fully flattened definition.

Runtime never needs to resolve an inheritance chain.

Avoid open-ended multiple inheritance semantics unless evidence shows it is necessary.

## 10. Protfuncs: controlled power for builders

Evennia deliberately does not let in-game prototype data contain arbitrary Python. Instead, trusted functions can be exposed through named prototype functions.

This is directly relevant to AI authoring.

### Loka adaptation

Cartridge source may call registered **compiler functions/capabilities** with typed schemas, for example:

```yaml
description:
  template: weathered_object
  args:
    material: bronze
```

The function registry is engine-owned and testable.

Do not let arbitrary compilation-time Elixir escape into the filesystem/network.

## 11. Scripts, tickers, tasks, and OnDemandHandler

Evennia has several temporal tools rather than forcing one model:

- persistent/non-persistent Scripts;
- subscription TickerHandler;
- persistent TaskHandler;
- OnDemandHandler for state derived only when observed.

The OnDemand idea is especially important.

### Loka adaptation

Classify time-driven behavior:

**Derived time**  
No job at all. Store baseline + timestamp and compute now.

**Durable job**  
Persisted, idempotent scheduled effect.

**Ephemeral cadence**  
In-memory timer recreated on restart.

**World simulation step**  
Processed by the authoritative world/shard scheduler.

Do not tick every NPC/plant/shop each second.

## 12. Commands and automatic help

Evennia command definitions carry aliases, access locks, parsing expectations, and help text; the help system can automatically derive command help.

### Loka adaptation

Every player action and Builder API operation SHOULD expose metadata:

- key;
- aliases;
- argument/input schema;
- policy;
- description;
- examples;
- result/error schema.

Generate:

- terminal help;
- AI capability descriptions;
- docs;
- possibly mobile accessibility labels

from the same metadata.

## 13. Batch processors

Evennia supports offline batch commands and also powerful batch Python execution, the latter explicitly considered a security risk.

### Loka adaptation

Our cartridge compiler and Builder API supersede raw batch command files.

We should support:

- batch operation plans;
- dry-run;
- transaction/workspace preview;
- machine-readable per-operation results;
- rollback before publication.

Normal authoring SHOULD NOT run arbitrary Elixir files as batch content.

## 14. Contrib ecosystem

Evennia keeps many optional mechanics as isolated contrib packages rather than bloating core.

### Loka adaptation

Long term, define **capability packs**:

- combat pack;
- crafting pack;
- social pack;
- survival pack.

But packs must:

- declare dependencies;
- register typed capabilities;
- include tests;
- participate in compatibility/versioning;
- be compiled into a known engine release.

Do not start v3 with a dynamic plugin marketplace.

## 15. Evennia ideas useful later

Potentially valuable but not foundation blockers:

- channels/comms;
- roleplaying recognition/sdesc systems;
- object poses/emotes;
- safe barter/trade contracts;
- achievements;
- builder OLC ideas;
- web admin patterns;
- full multi-session puppeting.

These belong in later capability packs unless needed by the first cartridge.

## 16. Core contrast: Evennia object-centric vs Loka instance-centric

Evennia's long-lived design centers powerful persistent objects.

Loka v3 should center the **world instance/shard authority** because:

- cartridges are bounded worlds;
- deterministic simulation is a primary feature;
- atomic multi-entity commands matter;
- BEAM actors are natural ownership boundaries;
- the mobile client needs coherent snapshots;
- certification needs repeatable state.

Entities remain important data, but the world owner coordinates them.

That is the major architectural divergence.


## 17. Extended rooms: details without entity explosion

Evennia's `extended_room` contrib supports:

- time/season/state-dependent room descriptions;
- small inspectable `details` that do not require creating a full database object;
- random echoes.

This is highly relevant.

### Loka adaptation

Add a portable **RoomDetail** definition:

```yaml
components:
  details:
    altar:
      aliases: [stone altar, shrine]
      description: room.shrine.altar
      actions: [inspect, pray]
```

A detail is targetable/searchable but not automatically a full RuntimeEntity.

Promote to a RuntimeEntity only if it needs independent:

- containment;
- movement;
- state;
- ownership;
- lifecycle.

This can dramatically reduce world-object bloat while preserving old-school MUD richness.

Room prose may support declarative variants based on:

- time;
- weather;
- state;
- quest/personal projection.

The variant resolver must stay deterministic and typed.

## 18. Safe barter/trade is worth adopting later

Evennia's barter contrib explicitly avoids the dangerous “you give yours, then I give mine” pattern by holding both sides until agreement.

For the future MMO, Loka SHOULD implement trade as a transaction state machine:

```text
proposed
  -> both editing offers
  -> A confirms
  -> B confirms
  -> atomically commit exchange
  -> completed
```

Changing either offer invalidates prior confirmation.

No player owns both sides mid-transaction.

This belongs in a later online social/economy capability pack, but the acceptance pattern should be remembered.

## 19. Independent escape/adventure instances validate the cartridge model

Evennia's EvscapeRoom contrib supports independently spawned multiplayer puzzle-room instances.

This is strong precedent for our:

- cartridge WorldInstance;
- party adventure;
- MMO portal into an instanced storypack.

Loka's model goes further by making this the core product path instead of an optional contrib.

## 20. Wilderness virtualization

Evennia's wilderness contrib creates large conceptual spaces without persisting a unique room object for every coordinate.

Potential Loka use later:

- forests;
- oceans;
- deserts;
- procedural travel;
- large overworlds.

Design a `VirtualRegion` capability in the future where a coordinate/cell is derived from:

- region definition;
- seed;
- coordinates;
- persistent exceptions/landmarks.

Do not make this a v3 foundation blocker, but avoid architecture that requires every traversable location to have a static authored room definition.

## 21. XYZ-grid and route finding

Evennia's XYZ-grid demonstrates the usefulness of explicit spatial coordinates, fast route finding, and limited-view map rendering.

Loka SHOULD keep topology independent from presentation:

- graph identity is canonical;
- coordinates are optional metadata/region model;
- pathfinder is a service/pure capability;
- map projection can render only discovered/nearby nodes.

This fits mobile minimap and NPC schedules.

## 22. RP recognition and language systems

Evennia's `rpsystem` includes:

- short descriptions;
- recognizing/renaming people from a player's perspective;
- persistent poses;
- masks/disguises;
- language comprehension/garbling;
- whispers partly overheard;
- rich in-emote references.

These are excellent ideas for a later text-MMORPG because they exploit text as a medium rather than imitate a graphical MMO.

Potential capability packs:

- recognition;
- disguise;
- language;
- pose;
- rich emote references;
- overhearing.

They are intentionally deferred from the first offline cartridge unless a story needs one.

## 23. Traits/buffs/cooldowns support the typed component direction

Evennia's contribs separately model:

- traits: bounded/modifiable values;
- buffs: timed modifiers/code triggers;
- cooldowns: lightweight persistent queried timers.

Loka v3 SHOULD make these typed portable concepts rather than generic attributes:

```text
Stat/Resource
Modifier/Status
Cooldown
```

Cooldowns are a good candidate for **derived temporal state**: store expiry logical time and query remaining duration rather than scheduling a tick.

## 24. Crafting recipe/tool model

Evennia's crafting contrib separates:

- recipes;
- consumed ingredients;
- required non-consumed tools;
- output.

This maps well to a future Loka portable crafting capability.

Keep recipe semantics declarative and deterministic. Duration/offline progression uses the v3 temporal model.

## 25. Auditing and reports

Evennia includes both I/O auditing and player report systems.

Loka already plans a richer correlated command trace.

Future MMO operations SHOULD also include a player-facing report flow that can attach bounded contextual evidence, with privacy/retention rules.

Do not automatically log all private conversation forever solely for moderation convenience.

## 26. Batch processing validates source-controlled world building

Evennia's batch processor applies version-controlled static files to create game content.

This strongly supports Loka's choice to treat cartridge source/Git as durable authoring history and compile/promote immutable artifacts, rather than make a mutable admin database the only source of truth.

Unlike Evennia's executable batch-Python option, Loka's Builder batch plan remains typed and bounded.

## 27. Contrib architecture validates capability packs—but not dynamic plugin chaos

Evennia currently ships dozens of optional contrib systems across base systems, game systems, grid, RPG, tutorials, and utilities.

The useful lesson is organizational:

- keep core small;
- make game-type-specific systems optional;
- document dependencies;
- test systems in isolation.

Loka adaptation:

```text
core portable capabilities
+
optional engine capability packs
+
cartridge-declared requirements
```

Do not copy a runtime plugin marketplace for the first rebuild.

## 28. Evennia feature ideas triage

| Evennia idea | Loka v3 disposition |
|---|---|
| Portal/server separation | adapt as gateway/runtime boundary |
| Session/account/character | adopt strongly |
| Typeclasses | do not copy; use definitions/components |
| Components contrib | validates composition |
| Attributes/NAttributes | replace with typed durable/ephemeral state |
| Tags/aliases/permissions | adopt as separate indexed/search/policy concepts |
| CmdSets | adopt ActionSet algebra |
| Locks | adopt typed fail-closed policies |
| Prototypes | adapt to compile-time templates/mixins |
| Protfuncs | adapt to registered compiler functions |
| OLC/build menus | terminal/API first; visual inspection |
| Scripts | split into derived state/durable jobs/portable scripts |
| TickerHandler | scheduler subscription pattern where needed |
| TaskHandler/delay | durable-job equivalent |
| OnDemandHandler | adopt strongly |
| ExtendedRoom details | adopt RoomDetail concept |
| Wilderness | later virtual-region capability |
| XYZGrid | later map/region capability |
| Barter | later atomic trade state machine |
| Crafting | later recipe capability |
| Cooldowns | portable derived state |
| Traits/buffs | portable typed stats/statuses |
| Mail/channels | later MMO social pack |
| RP recognition/languages | later differentiating text-MMO feature |
| Achievements | later account/character profile |
| Player reports | later moderation/ops |
| REST API | Builder/game APIs are typed and purpose-specific |
| Contrib packaging | capability-pack organizational model |
| In-game Python | explicit cautionary evidence for not executing arbitrary builder code |

## 29. Sources reviewed

Primary/current Evennia documentation areas reviewed include:

- Core Components overview: <https://www.evennia.com/docs/latest/Components/Components-Overview.html>
- Portal and Server: <https://www.evennia.com/docs/latest/Components/Portal-And-Server.html>
- Accounts: <https://www.evennia.com/docs/latest/Components/Accounts.html>
- Tags: <https://www.evennia.com/docs/latest/Components/Tags.html>
- CmdSet API: <https://www.evennia.com/docs/latest/api/evennia.commands.cmdset.html>
- Locks/lock functions: <https://www.evennia.com/docs/latest/api/evennia.locks.lockfuncs.html>
- Prototypes/Spawner: <https://www.evennia.com/docs/latest/Components/Prototypes.html>
- Prototype functions: <https://www.evennia.com/docs/latest/api/evennia.prototypes.protfuncs.html>
- TickerHandler: <https://www.evennia.com/docs/latest/api/evennia.scripts.tickerhandler.html>
- TaskHandler: <https://www.evennia.com/docs/latest/api/evennia.scripts.taskhandler.html>
- OnDemandHandler: <https://www.evennia.com/docs/latest/Components/OnDemandHandler.html>
- REST API: <https://www.evennia.com/docs/latest/Components/Web-API.html>
- Contrib overview (53 bundled contribs at review time): <https://www.evennia.com/docs/latest/Contribs/Contribs-Overview.html>
- Components contrib: <https://www.evennia.com/docs/latest/Contribs/Contrib-Components.html>

The intent was not to reproduce Evennia exhaustively; it was to review mature patterns and feature categories for architectural evidence.

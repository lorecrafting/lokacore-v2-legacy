# 13 — Lokacore Feature Inventory and Rebuild Disposition

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Informative legacy inventory.

Use for feature archaeology and disposition, never as a module-by-module porting checklist.

<details>
<summary>Sections in this document</summary>

- [1. Source snapshot](#1-source-snapshot)
- [2. Disposition vocabulary](#2-disposition-vocabulary)
- [3. Architectural substrate](#3-architectural-substrate)
- [4. Persistence and state](#4-persistence-and-state)
- [5. World and spatial systems](#5-world-and-spatial-systems)
- [6. Action system](#6-action-system)
- [7. Search and command parsing](#7-search-and-command-parsing)
- [8. Conditions and access](#8-conditions-and-access)
- [9. Quests](#9-quests)
- [10. Dialogue](#10-dialogue)
- [11. Cutscenes and storylines](#11-cutscenes-and-storylines)
- [12. Inventory, containers, and equipment](#12-inventory-containers-and-equipment)
- [13. Combat and death](#13-combat-and-death)
- [14. Resources, stats, skills, progression](#14-resources-stats-skills-progression)
- [15. Economy and shops](#15-economy-and-shops)
- [16. Crafting and gathering](#16-crafting-and-gathering)
- [17. Timers and temporal systems](#17-timers-and-temporal-systems)
- [18. NPC living-world behavior](#18-npc-living-world-behavior)
- [19. Weather, day/night, atmosphere, visual/sound state](#19-weather-daynight-atmosphere-visualsound-state)
- [20. Scripting](#20-scripting)
- [21. Script templates](#21-script-templates)
- [22. Social/emote systems](#22-socialemote-systems)
- [23. Sessions](#23-sessions)
- [24. Broadcasting](#24-broadcasting)
- [25. Builder terminal](#25-builder-terminal)
- [26. MCP builder](#26-mcp-builder)
- [27. Provider-specific AI chat](#27-provider-specific-ai-chat)
- [28. Builder audit/observability](#28-builder-auditobservability)
- [29. Content validation](#29-content-validation)
- [30. Bot testing](#30-bot-testing)
- [31. AI evaluation](#31-ai-evaluation)
- [32. Balance simulation](#32-balance-simulation)
- [33. Admin dashboard](#33-admin-dashboard)
- [34. React Native living-book UI](#34-react-native-living-book-ui)
- [35. Minimap](#35-minimap)
- [36. Authentication](#36-authentication)
- [37. Health, telemetry, Sentry/Prometheus](#37-health-telemetry-sentryprometheus)
- [38. CI](#38-ci)
- [39. Spark companion](#39-spark-companion)
- [40. Plugin system](#40-plugin-system)
- [41. Old client/platform experiments](#41-old-clientplatform-experiments)
- [42. Documentation corpus](#42-documentation-corpus)
- [43. World content](#43-world-content)
- [44. Highest-value things to preserve](#44-highest-value-things-to-preserve)
- [45. Highest-value things not to preserve](#45-highest-value-things-not-to-preserve)
- [46. Rebuild extraction rule](#46-rebuild-extraction-rule)

</details>
<!-- packet-navigation:end -->

**Purpose:** ensure the rebuild does not accidentally discard useful work or blindly reproduce transitional architecture.

This is an architectural inventory, not a promise to ship every historical feature.

## 1. Source snapshot

At audit time, Lokacore contains approximately:

- 1,250 repository files;
- 39 Engine modules;
- 42 Framework modules;
- 12 Game action-layer files;
- 25 World Builder modules;
- 38 dedicated testing modules;
- 30 React Native source files;
- 330 files under `server/priv/world/`;
- roughly 236 room content files;
- quest/storyline/script/balance content and substantial historical design documentation.

The rebuild should treat this as a design corpus.

## 2. Disposition vocabulary

- **FOUNDATION** — required in v3 architecture before first commercial cartridge.
- **PORTABLE CORE** — should run in both offline and online hosts.
- **ONLINE CORE** — required online/BEAM feature, not necessarily offline.
- **FIRST CARTRIDGE** — implement when needed by the initial vertical slice.
- **LATER** — valuable but not a foundation blocker.
- **REFERENCE** — preserve concept/docs/tests but redesign implementation.
- **DROP** — do not reproduce unless future evidence revives the product need.

## 3. Architectural substrate

| Lokacore concept | Current implementation | v3 disposition | Notes |
|---|---|---|---|
| Unified entity | one Entity struct/DB table represents prototypes and instances | FOUNDATION, redesign | split immutable definitions from mutable runtime entities |
| EntityServer per entity | active GenServer cache/authority | REFERENCE | replace default with world-instance/shard authority; processes only at ownership boundaries |
| EntityRegistry | active entity lookup + room index | REFERENCE | v3 registry tracks instance/shard/session owners; runtime entity lookup mostly state/index |
| EntitySupervisor | DynamicSupervisor per entities | REFERENCE | retain OTP supervision pattern, change granularity |
| Entity seeder | YAML → DB prototypes | REFERENCE | replace with deterministic cartridge compiler/artifact loading |
| Spawner | prototype → runtime instance | PORTABLE CORE | preserve semantics through compiled definition refs |
| StateMachine | lightweight transition validator | PORTABLE CORE | preserve as pure finite-state primitive |
| Hooks | callback extension points | REFERENCE | replace many implicit hooks with typed command/event/capability contracts; keep explicit interception where needed |
| Event/EventBus | typed-ish events + PubSub | REFERENCE | retain causation ideas; separate domain events from PubSub observation/client messages |
| Locks | parsed access expression language | PORTABLE CORE, redesign | typed fail-closed Policy AST |
| Formula evaluator | configurable formulas | PORTABLE CORE if needed | compile/validate formulas into deterministic portable expressions |
| WorldGraph | room connectivity | PORTABLE CORE | important for maps, reachability, AI, certification |
| LayoutManager | map coordinates/layout | FIRST CARTRIDGE | preserve mapping value, move to pure/derived layer |
| Zone | reset/zone definitions | LATER/shared | deployment/shard-aware redesign |
| ContentValidator plugins | modular validation | FOUNDATION | evolve into compiler/certification gates |
| Boundary package/tests | partial architectural enforcement | FOUNDATION | use umbrella app boundaries + strict checks from start |

## 4. Persistence and state

| Feature | v3 disposition | Design |
|---|---|---|
| SQLite server DB | DROP for online | PostgreSQL online |
| SQLite local | FOUNDATION | offline story save |
| JSON components | PORTABLE CORE | retain extensibility but schemas/typed structs required |
| tags table | PORTABLE/ONLINE CORE | indexed labels/categories, inspired also by mature MUD systems |
| optimistic revision | FOUNDATION | world/save revisions + entity/state revisions where useful |
| periodic entity autosave | DROP as primary model | command-level transactional commit/snapshots |
| command receipt | NEW FOUNDATION | idempotent retry |
| effect outbox | NEW ONLINE FOUNDATION | durable external effects |
| snapshots | NEW FOUNDATION | offline saves, recovery, Lab rewind |
| event traces | FOUNDATION | diagnostic/certification evidence, not full event sourcing |
| V1 compatibility APIs | DROP | importer only; no compatibility code in v3 runtime |
| dynamic string-to-atom content | DROP | fixed registries/string IDs only |

## 5. World and spatial systems

### Preserve/rebuild as portable

- rooms/locations;
- exits/connections;
- cardinal and custom directions/actions;
- doors;
- locks;
- keys;
- containers;
- location/container ownership;
- room tags/biomes;
- world graph;
- pathfinding/search;
- map/minimap data;
- zones/regions as content metadata.

### Improve

A room does not need an independent process.

Mutable shared door/room state belongs to the authority host.

A private offline instance and online private instance use the same topology definitions.

Shared realm deployments mount regions into zone shards.

### Zone resets

Lokacore includes DikuMUD-style zone resets for mobs, objects, doors, and removals.

Disposition: **LATER/shared capability**, but preserve the concepts:

- spawn policy;
- population cap;
- respawn policy;
- door reset;
- cleanup.

Do not reproduce the current global-count behavior; v3 counts must be scope/instance/shard aware.

## 6. Action system

Lokacore's Action Resolver is one of the strongest concepts to keep.

Current layers include:

- entity base actions;
- equipment-granted actions;
- script-granted actions;
- status blocks;
- script blocks;
- room restrictions;
- replacement transformations;
- condition filtering.

Disposition: **FOUNDATION / PORTABLE CORE**.

Formalize ActionSet algebra:

- union;
- subtract/remove;
- intersect;
- replace;
- override by priority.

Use the same resolved actions for:

- touch UI;
- terminal commands;
- bots;
- accessibility;
- help;
- AI simulation.

Remove current coupling where `Loka.Game.Actions` calls `LokaWeb` serializers.

## 7. Search and command parsing

Current text command parser supports navigation, targeting, inventory, builder commands, and classic MUD interaction.

Disposition: **PORTABLE/ONLINE PRESENTATION FOUNDATION**.

Rebuild around one Search/TargetResolver:

- aliases;
- keywords;
- local scope;
- inventory;
- ordinal disambiguation;
- exact IDs for tools;
- structured ambiguous-result error.

Text parser and touch UI both produce host-neutral ActionInvocations. The active authority re-resolves/revalidates them and constructs canonical semantic Commands.

Touch UI can supply exact IDs from GameView action metadata; text input reaches the same boundary through Search/TargetResolver.

## 8. Conditions and access

Current `Conditions.Evaluator` and `Locks` overlap in semantic territory.

Disposition: **merge into one typed Policy/Condition algebra**.

Core conditions:

- typed fact comparison;
- not;
- all/any;
- stat/resource compare;
- has item;
- quest state;
- faction/reputation;
- tag;
- time window;
- target/location relation;
- permission/role;
- owner/self.

Unknown operator fails closed.

## 9. Quests

Current system includes:

- definition adapter;
- objective registry;
- handlers for kill/talk/go-to/get-item/craft;
- progress tracking;
- rewards;
- journal;
- timer manager;
- listeners;
- admin/metrics;
- state-machine tests.

Disposition: **FOUNDATION / PORTABLE CORE, complete redesign around reducer**.

Preserve objective semantics and useful tests.

Do not carry forward these implementation patterns:

- multiple direct mutation paths;
- dialogue/manual bypasses;
- implicit event maps;
- current active/completed JSON map shape.

Add:

- typed QuestInstance;
- graph operators;
- event subscriptions;
- idempotent processed events/rewards;
- definition version pin;
- explicit scope.

## 10. Dialogue

Current dialogue supports:

- nodes;
- choices;
- conditions;
- quest-sensitive variants;
- actions;
- NPC-associated dialogue.

Disposition: **PORTABLE CORE**.

Rebuild as typed graph.

Keep:

- conditional starts;
- choices;
- actions/effects;
- history/presentation;
- quest integration via domain events.

Do not let dialogue directly mutate quests.

## 11. Cutscenes and storylines

Lokacore has content types/managers for both.

### Cutscenes

Disposition: **FIRST CARTRIDGE if used**.

Treat as a presentation/narrative sequence capable of emitting controlled commands/events at defined points.

Avoid a second scripting system.

### Storyline

Disposition: **FOUNDATION as authoring metadata, not runtime authority**.

A storyline groups:

- quests;
- expected arcs;
- entry conditions;
- testing goals;
- endings.

Useful for certification/bot strategies and catalog metadata.

## 12. Inventory, containers, and equipment

Current modules:

- Inventory;
- Equipment;
- Equipable;
- Container;
- Stacking.

Disposition: **PORTABLE CORE**.

Major redesign:

- one canonical containment relationship;
- inventory derived from contained items;
- atomic move/transfer;
- equipment slot assignment;
- stackable definition/value semantics;
- no duplicated item location plus inventory-list truth.

Certification properties:

- item has one owner/container;
- transfer atomic;
- stack quantities conserved;
- equipment constraints preserved.

## 13. Combat and death

Current:

- combat framework;
- game action module;
- damage/heal mechanics;
- combat stats;
- respawn manager;
- ghost/death behavior.

Disposition:

### Basic combat
**FIRST CARTRIDGE / PORTABLE CORE** if initial story needs it.

### Death/ghost system
**REFERENCE/FIRST CARTRIDGE only if product wants it**.

Keep interesting ghost-mode concepts, but do not make them foundational.

### Mechanics

Preserve pure layers:

- resource pool;
- damage;
- heal;
- checks;
- configurable balance.

Move RNG/time into portable explicit environment.

## 14. Resources, stats, skills, progression

Current:

- resource pools;
- combatant component;
- skill manager;
- progression;
- YAML balance config.

Disposition: **PORTABLE CORE**.

Need a typed Stat/Resource model rather than arbitrary nested map lookups.

Balance formulas should be versioned with cartridge/engine rules and deterministic.

Do not force one global character progression model on every cartridge.

A cartridge may define local progression; online MMO character has separately governed persistent progression.

## 15. Economy and shops

Current:

- wallet;
- Economy;
- EconomyLog;
- shop action;
- transactions migration.

Disposition:

- **portable shop/economy primitive** for private cartridges;
- **ONLINE LATER** for persistent realm economy.

Private offline economy is untrusted and isolated.

Realm economy must have:

- transactional ledger;
- source/sink reason codes;
- duplication protection;
- shared stock semantics;
- auditability.

Never import offline currency/items into MMO.

## 16. Crafting and gathering

Current evidence includes:

- gathering action;
- recipe/resource content;
- crafting validator;
- persistent timer system intended for crafting/gathering.

Disposition: **LATER unless first story requires**.

Design as capabilities over:

- ingredients/resources;
- checks;
- station policy;
- duration;
- outputs;
- durable/derived time.

Offline/online portable where possible.

## 17. Timers and temporal systems

Current:

- persistent timer GenServer;
- script timers;
- quest timer manager;
- cooldown component;
- day/night/schedule scripts;
- periodic zone reset.

Disposition: **FOUNDATION temporal architecture**, but consolidate.

Use:

1. derived/on-demand temporal state;
2. durable jobs;
3. ephemeral cadence;
4. world-simulation scheduling.

Avoid a timer per thing.

This incorporates a strong lesson from mature MUD frameworks' on-demand/time-handler patterns.

## 18. NPC living-world behavior

Current builder docs expose:

- patrol;
- day/night schedule;
- shopkeeper hours;
- wander;
- ambient emitter;
- nocturnal;
- time-conditioned spawn.

Disposition: **PORTABLE CORE / FIRST CARTRIDGE**.

These are exactly the living-world primitives to retain.

Expand over time with:

- guard;
- follow;
- flee;
- hunt;
- work;
- rest;
- eat;
- scavenge;
- rumor;
- witness;
- relationship reaction;
- faction role.

But implement using world scheduler + declarative capabilities, not one uncontrolled script/timer per NPC.

## 19. Weather, day/night, atmosphere, visual/sound state

Lokacore has atmosphere docs/code, time-aware traits, historical environmental systems, but current RN serializer also contains placeholders indicating some V2 weather/day-night pieces were removed.

Disposition: **REIMPLEMENT CLEANLY**.

Portable model:

- logical calendar/time;
- phase;
- weather state;
- environmental tags/effects.

Derived presentation:

- description variants;
- visual asset state;
- soundscape.

Do not treat stale current placeholders as implementation truth.

## 20. Scripting

Current sandbox includes:

- AST/source validator;
- restricted bindings;
- timeout;
- ActionQueue;
- effect limits;
- script content entities;
- reusable templates;
- event/hook integration.

Disposition: **KEEP PRODUCT IDEA, REPLACE RUNTIME**.

V3:

- Elixir-like LokaScript source;
- compile to portable normalized AST/bytecode;
- custom interpreter in portable kernel;
- typed binding registry;
- budgets;
- deterministic clock/RNG;
- effects, not DB writes.

Current same-BEAM `Code.eval_string` implementation is not carried forward.

## 21. Script templates

Lokacore has 15 builder templates including:

- message on enter;
- once-only message;
- conditional exit block;
- spawn on enter;
- item reward;
- trigger dialogue;
- traps;
- ambient messages;
- lock/unlock;
- quest start;
- time message;
- weather effect;
- NPC reaction;
- death/respawn.

Disposition: **valuable design corpus**.

Most should become:

- declarative capability compositions;
- Builder API recipes/examples;
- compiler macros;

rather than generated scripts.

## 22. Social/emote systems

Current code/docs include social commands/substitution and extensive design notes for:

- emotes;
- moods;
- poses;
- reactions;
- presence;
- relationships;
- parties;
- guilds;
- channels;
- mail;
- boards;
- journals;
- witness/oath concepts;
- personal/shared spaces.

Disposition:

### Foundation for eventual MUD
- emote;
- say/tell/chat protocol;
- presence/session abstractions;
- party scope contract.

### Later
- guilds;
- mail;
- boards;
- housing;
- witness/oaths;
- mentorship/lineage;
- player governance.

Do not put the entire social vision into v3 foundation.

## 23. Sessions

Current Session Registry/Server/Supervisor separates client connections and supports multi-client/reconnect concepts.

Disposition: **ONLINE FOUNDATION**.

Keep conceptual separation:

```text
Session -> Account -> Character -> WorldInstance
```

Improve:

- session is transport-independent;
- no game authority stored only in session;
- reconnect/resync through instance revisions;
- typed outbound projection.

## 24. Broadcasting

Current framework/session/PubSub have several messaging routes.

Disposition: **CONSOLIDATE**.

Use:

- domain events internally;
- client projections/messages;
- PubSub for non-authoritative fanout;
- Session gateway for connected clients.

Do not have multiple semantically equivalent room-message buses.

## 25. Builder terminal

Current `/admin/builder` is already terminal-first.

Disposition: **KEEP UX IDEA, rebuild as thin adapter**.

No separate CRUD semantics.

Useful commands:

- inspect;
- create/update;
- graph;
- validate;
- simulate;
- trace;
- certify;
- map.

## 26. MCP builder

Current custom MCP server/tools are strategically valuable.

Disposition: **FOUNDATION ADAPTER**.

Generate MCP tool schemas from canonical Builder API.

Do not keep current duplicate `ToolExecutor` versus terminal manager paths.

## 27. Provider-specific AI chat

Current builder embeds Anthropic client/conversation/model choice.

Disposition: **DROP FROM CORE**.

AI providers are external clients/orchestrators.

Optional terminal chat UI may connect to an external agent later.

## 28. Builder audit/observability

Current audit log and AI observability logger are useful.

Disposition: **FOUNDATION**.

Move to canonical operation receipts/traces.

## 29. Content validation

Current testing modules include validators for:

- prototype lint;
- world;
- quests;
- dialogues;
- quest/dialogue chain;
- storylines;
- reachability;
- crafting;
- cutscenes;
- UI.

Disposition: **FOUNDATION**.

These should be mined for exact failure cases and rebuilt as compiler/certification diagnostics.

## 30. Bot testing

Current ChannelBot, strategies, assertions, state inspector, random walker, storyline runner are especially valuable.

Disposition: **FOUNDATION / rebuild these concepts early**.

New gameplay bots target the canonical ActionInvocation/GameSession path rather than Phoenix-specific behavior unless explicitly testing transport. Lower-level deterministic fixtures may target semantic Commands where appropriate.

Keep a protocol integration bot separately.

## 31. AI evaluation

Current AI eval system includes:

- structural;
- narrative;
- content-quality rubrics;
- dialogue/quest/script/world scenarios;
- reports/log analysis.

Disposition: **FOUNDATION semantic-review inspiration**.

Rebuild outputs as structured evidence tied to cartridge hash.

Provider-independent.

## 32. Balance simulation

Current:

- combat simulator;
- progression simulator;
- report generator.

Disposition: **LATER / capability-specific certification**.

Strong pattern to preserve.

## 33. Admin dashboard

Current admin areas include dashboard, players, quests, testing, audit.

Disposition: **MINIMAL ONLINE OPS UI**.

Build only views that improve operations/debugging.

Do not recreate a giant content-authoring GUI.

Preferred visual tools:

- instance inspector;
- trace viewer;
- certification dashboard;
- map/quest graph;
- outbox/jobs;
- sessions;
- release catalog.

## 34. React Native living-book UI

Current RN client contains:

- parchment/book visual style;
- page curl;
- bottom bar;
- compass/minimap;
- room page;
- dialogue page;
- entity page;
- menu;
- shop;
- container;
- page sounds/effects.

Disposition: **REFERENCE / preserve product feel where desired**.

Do not reuse current protocol/store code because it has drifted from the server contract.

Rebuild client over generated protocol + offline kernel.

The “living book” aesthetic is independent of architecture and can be iterated after the vertical slice works.

## 35. Minimap

Disposition: **FIRST CARTRIDGE likely useful**.

Derive from visited/known topology.

Offline save may track discovered map state.

Shared realm may have different discovery policy.

## 36. Authentication

Current Phoenix auth/JWT/magic-link/mobile flow exists.

Disposition: **ONLINE FOUNDATION**, but can use clean Phoenix auth patterns.

Offline free cartridge should not necessarily require login.

Paid entitlement/download may require platform/account verification during acquisition, but offline launch should not require network.

## 37. Health, telemetry, Sentry/Prometheus

Current app has health endpoints, PromEx, Sentry, telemetry.

Disposition: **ONLINE FOUNDATION**.

Rebuild minimally, then expand with command/kernel/instance metrics.

## 38. CI

Current two overlapping Elixir workflows plus no RN CI is transitional.

Disposition: **REBUILD**.

One coherent pipeline covering:

- Elixir;
- Rust kernel;
- Rustler wrapper;
- iOS/Android binding compile;
- TypeScript/mobile;
- schema generation drift;
- cross-host golden conformance;
- cartridge compiler;
- certification smoke;
- security audits.

## 39. Spark companion

Lokacore has historical Spark tables/actions while migrations later dropped Spark tables.

Disposition: **DROP from v3 foundation**.

Preserve design docs if useful.

Any AI companion returns as an explicit product feature after core shipping.

## 40. Plugin system

Historical docs discuss plugins/migrations.

Disposition: **NO dynamic plugin system in foundation**.

Use compile-time capability packs with explicit version/dependency registration.

This is enough for internal modularity.

## 41. Old client/platform experiments

Archived:

- Godot migration decision;
- Rust book client;
- pageflip experiments;
- prior UI migrations.

Disposition: **REFERENCE only**.

React Native/Expo remains current working mobile choice unless the offline-kernel spike exposes a concrete blocker.

## 42. Documentation corpus

Lokacore documentation is both valuable and inconsistent.

Disposition:

- archive historical decision/docs rather than delete immediately;
- restate only still-valid semantic contracts in v3-native terms;
- machine-generate/check contract docs;
- mark reference docs as historical;
- never feed the entire historical corpus to an implementation agent without routing.

## 43. World content

Existing 200+ rooms and arcs are valuable test/import material.

Disposition:

- do not rebuild all historical content at foundation stage;
- choose one compact coherent arc as importer/vertical-slice target;
- build one-way importer/diagnostics;
- use remaining old content as fuzz/reference corpus;
- preserve lore separately from old schema.

## 44. Highest-value things to preserve

If everything else were lost, keep these ideas:

1. rich MUD primitive ambition;
2. authoritative server orientation for multiplayer;
3. entity/component composition idea;
4. action resolution/algebra;
5. state machines for bounded lifecycle;
6. YAML/data-friendly authoring;
7. reusable NPC traits/schedules;
8. constrained scripting escape hatch;
9. world graph and reachability;
10. quest/dialogue model tests;
11. ChannelBot/storyline playthrough concept;
12. AI semantic evaluation;
13. terminal/MCP builder direction;
14. mobile touch contextual actions;
15. living-book presentation experiments;
16. social/MUD feature research corpus.

## 45. Highest-value things not to preserve

1. one Entity abstraction doing definition + instance + persistence compatibility;
2. V1 compatibility code in the new runtime;
3. two mutable authorities (DB and entity process) for the same state;
4. one GenServer per noun by default;
5. Framework↔Content dependency cycle;
6. relaxed architectural catch-all boundary;
7. tuple client events mixed with domain events;
8. hand-maintained server/mobile protocol types;
9. direct web serializer dependency from game logic;
10. dynamic atom creation from content;
11. `Code.eval_string` cartridge execution;
12. separate terminal/MCP mutation implementations;
13. global content keys that collide across cartridges;
14. cloud-only assumption for single-player;
15. production state imported from offline saves;
16. duplicated/contradictory historical docs as “authority.”

## 46. Rebuild extraction rule

For every old feature considered for the rebuild, an implementation issue must answer:

- What player/product need does this feature satisfy?
- Is it required by the current milestone?
- What is the v3 capability contract?
- Is it portable offline or server-only?
- What scope does its state use?
- What commands/events/effects does it own?
- How is it tested deterministically?
- What old tests/content demonstrate expected behavior?
- What old architecture must NOT be copied?

No Lokacore module, API, schema, compatibility shim, or process topology is carried forward merely because it exists. The new implementation starts from v3 contracts; old code is consulted only to recover requirements, examples, edge cases, tests, and content semantics.

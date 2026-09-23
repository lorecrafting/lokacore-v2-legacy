# 07 — Offline Storypacks and the Path to the MMORPG

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: two authority modes and portability.

Read sections 1-14 for the shared boundary, then continuity and Realm reuse. The target envelope is owner-approved; exact setup and measured acceptance remain pending.

<details>
<summary>Sections in this document</summary>

- [1. Requirement](#1-requirement)
- [2. One client, two strict authority modes](#2-one-client-two-strict-authority-modes)
- [3. Execution profiles](#3-execution-profiles)
- [4. Portable rules contract and R1 candidates](#4-portable-rules-contract-and-r1-candidates)
- [5. Portable rules boundary](#5-portable-rules-boundary)
- [6. Portable state and commit boundary](#6-portable-state-and-commit-boundary)
- [7. Server execution](#7-server-execution)
- [8. Offline execution](#8-offline-execution)
- [9. Offline persistence](#9-offline-persistence)
- [10. Offline time](#10-offline-time)
- [11. Offline scripts](#11-offline-scripts)
- [12. Capability portability classification](#12-capability-portability-classification)
- [13. Conformance suite](#13-conformance-suite)
- [14. Architecture spike gate](#14-architecture-spike-gate)
- [15. Campaigns, sequels, and single-player expansions](#15-campaigns-sequels-and-single-player-expansions)
- [16. Cartridge versus deployment](#16-cartridge-versus-deployment)
- [17. Three ways a single-player cartridge enters the MMO](#17-three-ways-a-single-player-cartridge-enters-the-mmo)
- [18. Quest design for future reuse](#18-quest-design-for-future-reuse)
- [19. Shared NPC versus personal narrative](#19-shared-npc-versus-personal-narrative)
- [20. Death and permanence](#20-death-and-permanence)
- [21. Economy boundary](#21-economy-boundary)
- [22. What may transfer from offline](#22-what-may-transfer-from-offline)
- [23. Online-authoritative cartridge mode](#23-online-authoritative-cartridge-mode)
- [24. Cloud save for offline storypacks](#24-cloud-save-for-offline-storypacks)
- [25. Offline entitlement](#25-offline-entitlement)
- [26. Cartridge update while offline](#26-cartridge-update-while-offline)
- [27. Offline download/package integrity](#27-offline-downloadpackage-integrity)
- [28. Local privacy](#28-local-privacy)
- [29. Why this still uses BEAM's strengths](#29-why-this-still-uses-beams-strengths)
- [30. Product progression](#30-product-progression)
- [31. Prologue-to-Realm journey](#31-prologue-to-realm-journey)

</details>
<!-- packet-navigation:end -->

## 1. Requirement

First-generation single-player cartridges SHOULD be fully playable offline after installation/download.

This changes a major assumption in the earlier roadmap: a private cartridge cannot depend on a cloud-hosted BEAM process for ordinary play.

At the same time, Loka MUST avoid creating a disposable “single-player engine” that is later replaced by the MMORPG.

The solution is to separate:

- **portable deterministic game semantics**;
- **the authority shell that hosts those semantics**.

Offline, the authority shell lives on the device.

Online, authority lives in BEAM/OTP.

For a **portable Story cartridge**, the same compiled cartridge definitions and portable simulation semantics run in both places. Realm-native cartridges may add or depend on server-only capabilities and are not required to execute offline.

## 2. One client, two strict authority modes

Loka uses one mobile application with two session modes.

### Story Mode

Responsibilities:

- cartridge catalog/download;
- permanent story purchases;
- offline local authority;
- local SQLite saves;
- campaigns/sequels/expansions;
- first-release accounts and account-level Story milestone synchronization;
- optional cloud-save backup, separate from progress tracking;
- portable GameView rendering.

Ordinary Story play MUST NOT require:

- Phoenix world sessions;
- realm chat/presence;
- guild/economy services;
- shard handoff;
- server authority.

### Realm Mode

Responsibilities:

- authenticated online session;
- Phoenix protocol;
- BEAM-authoritative world/party instances;
- persistent online characters;
- chat/presence/social;
- shared zones and later realm systems;
- server-authoritative economy/progression.

Realm Mode MUST NOT:

- create a local authoritative fallback when disconnected;
- treat Story SQLite saves as online world authority;
- derive competitive/persistent Realm value directly from editable local Story state.

### The session boundary

The app selects exactly one gameplay authority for a running session:

```text
                    Loka UI / GameView renderer
                              |
                         GameSession
                         /         \
                        /           \
             LocalStorySession   RemoteRealmSession
                    |              Phoenix transport
          LocalInstanceAuthority          |
             portable rules            BEAM
             local SQLite             server state
```

The shared renderer receives host-neutral `GameView` data and emits host-neutral `ActionInvocation` values through the active session. It never constructs authority-internal Commands. It MUST NOT contain separate copies of quest/action/policy semantics.

Switching modes MUST close/commit the current gameplay session/authority before another authority is activated. No save/world may be concurrently authoritative locally and remotely.

The Story portable-rules implementation may physically exist in the same binary while Realm Mode is active, but Realm Mode MUST never trust local rule execution for authoritative decisions. Local simulation/prediction for Realm is deferred unless separately specified.

### One app, modular code

Do not solve one-app maintenance by creating one giant conditional client.

The mobile codebase SHOULD keep explicit packages/modules for:

- app shell/navigation;
- Story session/LocalInstanceAuthority/SQLite/portable-rules bridge;
- Realm session/Phoenix transport;
- shared GameView renderer;
- shared UI/design system;
- localization;
- generated schemas/types;
- Story library/commerce;
- Realm social/chrome.

Import-boundary tests SHOULD prevent Realm authority code from mutating Story saves and Story authority code from bypassing the Realm transport.

## 3. Execution profiles


Each cartridge/deployment declares supported profiles.

### `offline_private`

- one local player;
- no network required after entitlement/content acquisition;
- local durable save;
- only portable capabilities;
- local deterministic simulation kernel;
- no authoritative transfer of competitive state to MMO.

### `online_private`

- one player;
- BEAM WorldInstance is authoritative;
- may use server-only capabilities;
- server/cloud save;
- eligible for online-authoritative progression integrations if product policy allows.

### `party`

- several players;
- BEAM WorldInstance authoritative;
- shared party-scoped state.

### `shared_area`

- many players;
- BEAM zone/shard authority;
- explicit player/party/realm scopes;
- multiplayer/economy/abuse certification required.

A cartridge can support more than one profile.

## 4. Portable rules contract and R1 candidates

### Problem

Offline Story authority and online BEAM authority must implement the same portable gameplay semantics. Independently maintained rule implementations create an ongoing semantic-drift cost as the primitive library grows.

### Normative direction

Define one **portable deterministic semantic contract**: canonical commands, state/deltas, RNG/time behavior, rule IR, errors, and conformance vectors. Every supported authoritative host must conform to it.

R1 tests candidate C first (ADR-068): separate Elixir and mobile implementations organized around the same schemas and held to golden cross-host conformance and randomized differential testing. A shared portable kernel, candidate B and then A, is evaluated only after a documented C failure.

### R1 candidates

R1 compares three candidates against the pre-registered acceptance envelope in `r1-acceptance-envelope.md`. **None is selected before the spike.** `14-implementation-plan.md` R1 and ADR-004 are the authority for the candidate set.

- **A. One TypeScript kernel** — one TypeScript package run natively in React Native's JavaScript engine, reached from BEAM through an Erlang Port to an isolated runner.
- **B. One Rust kernel** — one deterministic Rust library behind a declared BEAM boundary (Rustler NIF or explicitly evaluated isolated worker) and native iOS/Android React Native bindings. Language selection does not silently select a crash-isolation boundary.
- **C. Dual Elixir/TypeScript** — pure Elixir online plus TypeScript offline, held to one semantic schema, a golden-vector parity suite and randomized differential testing.

The comparison procedure builds C first; B is evaluated only if C fails a MUST row, and A only if B also fails (`r1-acceptance-envelope.md` §2).

Candidate B additionally depends on a mobile binding strategy. Current React Native/Expo supports custom native modules, React Native provides typed TurboModule/JSI native integration, and Rustler provides an Elixir/Rust NIF bridge. Rust-to-React-Native binding generators also exist, but at least one prominent reviewed option describes itself as early-development and not yet recommended for production. Therefore **both of candidate B's host-binding strategies remain provisional until R1**, and the architecture must not depend on any one third-party binding generator.

### What stays Elixir/BEAM-native

Selecting one shared portable kernel does NOT move the online system out of BEAM.

BEAM/OTP still owns the online system:

- world-instance and shard processes;
- supervision;
- sessions;
- networking/Phoenix;
- process registries;
- backpressure;
- scheduling orchestration;
- database transactions;
- outbox/effect workers;
- distributed-world evolution;
- observability integration;
- admin/builder services.

Whichever candidate R1 keeps owns only deterministic portable simulation semantics; BEAM/OTP still owns everything in the list above. Under candidate C the Elixir implementation obeys the same portable semantic contract and conformance fixtures as the TypeScript one.

This is analogous to using a physics/rules library inside an actor-oriented server.

## 5. Portable rules boundary

Input:

```text
compiled cartridge definitions / capability tables
current portable world state
typed command or scheduled portable event
logical time
explicit RNG state
execution budget
```

Output:

```text
accepted/rejected
StateDelta proposal
new RNG state
domain events
portable effects
portable game-view/projection hints
trace data
```

An implementation may materialize a candidate state internally for efficient evaluation, but the host-visible authority contract is a non-committed proposal until persistence succeeds.

The portable rules implementation MUST NOT:

- access network;
- access filesystem directly;
- access database;
- know Phoenix;
- know App Store/Play Store;
- use wall clock;
- use process-global RNG;
- create OS threads as gameplay authority;
- make entitlement decisions.

It is a pure deterministic engine boundary.

## 6. Portable state and commit boundary

Every R1 strategy MUST preserve the same semantic proposal/commit protocol:

```text
authority owns committed revision
        |
portable rules decide(committed state/view, semantic command, env)
        |
        +--> StateDelta
        +--> DomainEvents
        +--> Effects
        +--> new RNG/logical state
        |
authority transactionally persists delta + receipt
        |
on success: adopt/apply committed result in memory
on definitive rollback: discard proposal
on uncertain COMMIT: fence admission, reconcile receipt and reload
```

The portable rules layer MUST NOT irreversibly advance hidden authoritative state before host commit succeeds.

For any candidate with a host boundary, begin with the simplest strategy and measure actual bytes/copy/latency. Compare more complex alternatives only if the simple strategy fails the reviewed envelope; record correctness reasons for any exclusion:

- stateless serialized state-in/state-out;
- long-lived native state handle + non-mutating decision/delta;
- compact touched-state slices/deltas.

If R1 selects separate conformant host implementations, each still obeys the same non-mutating proposal/commit boundary and canonical trace contract.

Choose the simplest accepted strategy that preserves:

- deterministic replay;
- crash recovery;
- snapshot export;
- transaction ordering;
- acceptable host-boundary cost;
- testability.

Do not freeze a hidden mutable native/NIF resource design before this evidence.

## 7. Server execution

Online:

```text
Realm ActionInvocation
   ↓
BEAM authority re-resolves + constructs semantic Command
   ↓
WorldInstance / ZoneShard DecisionCoordinator
   ↓
portable rules decide(...)
   ↓
DecisionBatch
   ↓
PostgreSQL transaction + command receipt/outbox
   ↓
BEAM adopts committed state
   ↓
GameView projection / effects
```

The BEAM process serializes authority and provides resilience.

If R1 selects a Rust/Rustler implementation, short bounded calls may use a normal NIF only when measured safe for scheduler latency. Heavy Lab/model-check simulations MUST use appropriate dirty scheduling or isolated workers. Non-Rust strategies must provide equivalent host-safety isolation for heavy work.

## 8. Offline execution

On device:

```text
touch/text input
   ↓
ActionInvocation
   ↓
LocalInstanceAuthority re-resolves + constructs semantic Command
   ↓
portable rules decide(...)
   ↓
DecisionBatch
   ↓
local SQLite transaction
   ↓
local state adopted
   ↓
portable GameView → React Native projection
```

`LocalInstanceAuthority` serializes local commands just as `WorldInstance` does online.

It need not emulate OTP. It only must enforce the same command/commit semantics.

## 9. Offline persistence

Use a local transactional database, normally SQLite.

Local save stores:

```text
save slot ID
cartridge ID/version/hash
instance revision
logical clock
RNG state
portable world state/snapshot
quest/scoped state
durable local scheduled jobs
command receipts needed for crash-safe retry
save format version
lineage/ancestor revision for cloud sync
```

A command is locally committed before UI treats it as durable.

A crash cannot leave “item removed from room but not placed in inventory.”

## 10. Offline time

Cartridge declares its time policy.

### `play_time`

Logical world time advances only through explicit authority-controlled game-time advancement while the game is actively running.

### `real_elapsed`

On resume, the local authority samples wall-clock evidence once, applies the cartridge's documented clamp/rollback policy, and converts the accepted elapsed interval into an explicit idempotent **resume-time advancement input**. That input is then processed through the normal deterministic decision/commit path.

A crash/retry during resume MUST NOT apply the same elapsed interval twice.

### `hybrid`

Specific systems declare which named time basis they use—for example gameplay time versus accepted real-elapsed time. A system may not silently read wall time simply because the cartridge is hybrid.

The save records enough checkpoint/time-basis metadata to make resume reconciliation deterministic after the wall-clock sample has been accepted.

No background process is required to simulate every second while the app is closed.

Use on-demand derivation and process due durable jobs on resume. Device wall time is an input to local private play, not a trusted Realm/competitive clock.

## 11. Offline scripts

> **Deferred design:** ADR-018 defers LokaScript until a demonstrated composition gap is admitted. This retained design is not a chapter-one build requirement; it constrains that feature if admitted.

Offline-capable cartridges may use only **portable LokaScript** and portable bindings.

Therefore LokaScript cannot depend on Elixir runtime execution.

Preferred pipeline:

```text
Elixir-like source syntax
  ↓
authoring compiler parses permitted syntax
  ↓
portable normalized AST/rule IR
  ↓
R1-selected portable rules interpreter/implementation
  ↓
same semantics on mobile + server
```

The authoring compiler MAY use Elixir's parser during build time to convert syntax to the portable representation, but released portable runtime execution occurs through the R1-selected portable rules path.

Engine-native compiled Elixir capabilities are server-only unless an equivalent portable capability is registered and conformance-certified for Story hosts.

## 12. Capability portability classification

Every capability declares:

```text
portable
server_only
client_presentation_only
```

`offline_private` compilation rejects `server_only` gameplay capabilities.

Example:

```text
movement@1           portable
inventory@1          portable
quest@3              portable
schedule@1           portable
combat@2             portable
guild_market@1       server_only
cross_realm_chat@1   server_only
haptics@1            client_presentation_only
```

The first storypacks SHOULD target the portable capability set.

## 13. Conformance suite

The portable-execution contract creates a critical new invariant:

> The same input state, semantic command, logical time, RNG state, and cartridge hash MUST produce byte-for-byte/canonically equivalent domain results on every supported authoritative host.

After R1 selects the execution strategy, CI runs golden vectors through every required host implementation/adapter:

- the direct portable-rules implementation;
- the BEAM authority adapter/implementation;
- the iOS Story authority path;
- the Android Story authority path.

Under candidate A these concretely become the TypeScript kernel plus an Erlang Port runner and the React Native JavaScript engine on both devices; under candidate B, a Rust core plus its declared BEAM boundary and iOS/Android native bindings. If R1 selects candidate C, tested first, the same conformance obligation applies to the accepted Elixir and mobile implementations instead.

Any semantic divergence blocks release. Retain and compare per-step canonical state, decision, event/effect and RNG bytes as well as hashes; see `conformance/README.md`. Final transcript/hash agreement alone is insufficient.

## 14. Architecture spike gate

Before writing the full engine, implement a tiny vertical spike:

Definitions:

- two rooms;
- one NPC;
- one item;
- one quest;
- one RNG check;
- one scheduled event.

Commands:

- move;
- take;
- talk;
- advance/resume time.

Prove:

1. the candidate kernel runs the exact scenario;
2. the BEAM host produces the canonical trace hash (an Erlang Port runner for candidate A, the explicitly selected NIF/isolated-worker boundary for candidate B, the native Elixir implementation for candidate C);
3. for candidate B, pre-register its mobile and BEAM boundaries, demonstrate the simplest sufficient build/debug path, and document why alternatives were or were not implemented;
4. iOS React Native host produces same trace hash;
5. Android React Native host produces same trace hash;
6. local SQLite save/reload preserves hash;
7. the BEAM spike adapter preserves canonical state across export/reload using its declared test store; real PostgreSQL transaction/recovery proof remains mandatory at R14, not an unbuilt R1 prerequisite;
8. 10,000 deterministic command runs show acceptable latency;
9. a deliberately injected mismatch is caught by conformance CI;
10. chosen mobile integration approach has a credible Expo/EAS build, upgrade, crash-debugging, and maintenance story.

The procedure for comparing the three candidates is `r1-acceptance-envelope.md` §§2–3 and §11; candidate C, dual Elixir/TypeScript implementations with mandatory golden-vector parity and randomized differential testing, is tested first (ADR-068).

## 15. Campaigns, sequels, and single-player expansions

A **cartridge** is the smallest independently versioned/certified world-content unit. A **campaign** is an optional composition layer that lets multiple cartridges/chapters form one continuing offline adventure.

Example:

```text
Campaign: Riverlands Chronicle

Chapter 1
  fox_spirit_of_yunmeng@1.2.0

Chapter 2
  monastery_beneath_the_bell@1.0.0

Expansion
  ghosts_of_the_southern_road@1.1.0
```

The campaign manifest pins exact compatible cartridge releases for a save lineage.

### Campaign state classes

Continuing stories need state that outlives one cartridge without making everything global.

Use explicit classes:

```text
cartridge_local
  facts/entities/quest state meaningful only inside one cartridge

campaign_character
  portable character stats/equipment only when the campaign rules declare them shared

campaign_memory
  narrative facts: who lived, faction choice, ending, promises, discoveries

account_memory
  optional non-competitive profile/lore achievements that may sync later

realm/MMO state
  online authoritative only; never sourced from offline campaign economy
```

A cartridge declares which continuity keys it exports and which it accepts.

Example:

```yaml
continuity:
  exports:
    - memory.saved_ferryman
    - memory.temple_allegiance
  imports:
    - memory.village_ending

  character:
    mode: campaign
    schema: riverlands_character_v1
```

Do not let a sequel read arbitrary internal state from its predecessor.

### Continuity record

On cartridge completion/checkpoint, the portable rules layer can emit a typed continuity record:

```text
campaign ID
source cartridge/release/hash
campaign save lineage
exported narrative memories
portable campaign-character snapshot if allowed
schema versions
```

The next cartridge validates/imports only declared fields.

This makes sequels deterministic and migration-friendly.

### Standalone compatibility

A sequel/expansion SHOULD define one of:

- `requires_prior`;
- `prior_optional_with_defaults`;
- `standalone`.

If prior state is optional, the content explicitly defines default continuity rather than guessing.

### Expansion installation

An expansion may:

1. add a new independent chapter;
2. add optional content to a campaign map;
3. add side-adventure portals;
4. extend a previous cartridge through an explicit composite deployment.

It MUST NOT mutate an already certified cartridge artifact in place.

A campaign save pins the exact release set it was using. Installing an expansion changes the campaign composition through a versioned campaign/deployment manifest and migration if needed.

### Character continuity versus MMO continuity

Offline campaign-character state is trusted only within that local campaign lineage.

If the future MMO includes the same hero/story continuity, use explicit translation such as:

- narrative memories;
- cosmetic badges;
- unlocked dialogue variants;
- account lore.

Do not automatically import offline levels, gold, items, or power into realm authority.

Online-private versions of the campaign may later use an online-authoritative character and therefore can participate in MMO progression under explicit product rules.

### Why this helps the MMORPG

A campaign becomes a curated set of reusable adventure modules.

Later the MMO can expose:

- Chapter 1 as a private quest-board adventure;
- Chapter 2 as a party dungeon;
- the expansion road as an instanced region;
- selected geography as a shared promoted zone.

Campaign ordering/continuity is product metadata; cartridge content remains reusable.

## 16. Cartridge versus deployment

Separate reusable story/content from how it is hosted.

### Cartridge

Contains:

- world definitions;
- NPCs/items;
- quest/dialogue;
- portable scripts;
- narrative;
- assets.

### Deployment

Defines how a cartridge is instantiated in a product context.

Example:

```yaml
deployment: offline
cartridge: fox_spirit_of_yunmeng@1.2.0
mode: offline_private
persistence: local
entry: rooms/ferry_dock
```

A shared-world deployment may say:

```yaml
deployment: yunmeng_realm
cartridge: fox_spirit_of_yunmeng@1.2.0
mode: shared_area
realm: main
mount:
  parent_zone: southern_riverlands
  entry_connection: ferry_road
policies:
  npc_death: respawn
  economy: realm
```

Deployment is separately hashed and certified.

## 17. Three ways a single-player cartridge enters the MMO

This is the central reconciliation mechanism.

### A. Adventure portal — preferred first reuse

A player in the MMO launches the original cartridge as a private or party adventure.

```text
Shared Town
   |
Quest Board / Boat / Portal
   |
new private/party WorldInstance
   |
exact certified cartridge
```

The story does not need to become globally shared.

Advantages:

- zero narrative rewrite;
- no shared-NPC races;
- exact quest assumptions preserved;
- co-op can be added via party mode;
- same cartridge continues to earn value after MMO launch.

### B. Instanced region embedded in geography

The cartridge's entrance exists physically in the MMO map, but crossing the boundary creates a private/party instance.

Example: everyone sees the ruined monastery entrance, but each party explores its own story state inside.

This gives geographical cohesion without sacrificing narrative correctness.

### C. Shared-area promotion

Only some content should become truly shared.

Create a shared deployment overlay and recertify for:

- concurrent players;
- shared NPC life/death;
- spawn/respawn;
- shared doors/resources;
- economy;
- griefing;
- unique items;
- quest scope;
- world event semantics;
- shard transfers.

This is an explicit adaptation/certification step, not an automatic boolean mode switch.

## 18. Quest design for future reuse

Default story quest scope SHOULD be `player`.

That allows the same shared NPC to participate in different players' quest progress.

Quest authors must not assume that changing the shared NPC object itself is the only way to represent personal story state.

For personal consequences, use:

- player-scoped state;
- private phasing/projection where supported;
- instanced sub-area;
- party scope.

Use realm scope only for intentional world events.

## 19. Shared NPC versus personal narrative

An NPC definition can be reused across modes, but deployment policy decides runtime multiplicity.

Offline:

```text
one ferryman inside local world
```

Private online:

```text
one ferryman per instance
```

Shared MMO:

```text
one shared ferryman per zone shard
```

Player-specific dialogue/quest knowledge lives in player-scoped state rather than mutating the shared ferryman into contradictory global states.

## 20. Death and permanence

A story may allow the ferryman to die permanently.

That does not mean the shared-world deployment must.

Deployment/capability policy can choose:

- permanent in private instance;
- respawn in shared area;
- invulnerable/shared service NPC;
- private quest duplicate;
- phased replacement.

Any semantic change requires multiplayer semantic review.

## 21. Economy boundary

Offline saves are user-controlled and therefore untrusted for competitive MMO value.

Offline-earned:

- gold;
- equipment;
- stats;
- crafting materials;
- rare drops

MUST NOT be imported as authoritative MMO economy state.

This is a security boundary, not an accusation against players.

## 22. What may transfer from offline

Optional low-stakes synchronization may include:

- completion marker;
- endings seen;
- lore/journal unlocks;
- accessibility/preferences;
- cosmetic “memory” badges;
- narrative choices used only for flavor.

Because offline saves can be modified, anything transferred MUST be treated as non-competitive/untrusted unless independently verified.

## 23. Online-authoritative cartridge mode

Later, a player may choose to run the same cartridge in `online_private` mode.

Because BEAM is authoritative, such a run MAY integrate with MMO progression/rewards if product design wants it.

This gives a clean distinction:

```text
Offline Story Mode
  play anywhere
  local save
  no valuable MMO-state import

Realm Mode / online-private deployment
  same story/content
  server-authoritative
  may interact with persistent account/MMO systems
```

Do not require Realm online-private deployment for launch.

## 24. Cloud save for offline storypacks

Cloud backup is optional convenience, not runtime authority.

When online:

```text
local save branch
   ↓
upload encrypted/authenticated snapshot metadata
   ↓
cloud backup
```

If two devices diverge from a common ancestor, DO NOT attempt arbitrary semantic merge.

Preserve both branches and let the player choose, or use an explicit cartridge-specific merge only if defined/tested.

## 25. Offline entitlement

After a paid cartridge is legitimately acquired and downloaded, ordinary offline play SHOULD not require periodic connectivity.

Store a locally verifiable signed entitlement grant or equivalent platform-backed durable purchase proof.

Server revocation/refund state takes effect when the device next reconnects according to product policy.

Exact Apple/Google implementation must be re-verified at commerce implementation time.

## 26. Cartridge update while offline

A save is pinned to exact cartridge release/hash.

If a new release is downloaded:

- existing save may continue with old installed artifact;
- or user may run an explicit tested migration;
- old artifact can be reclaimed only after no local save needs it.

Never silently load a v1.2 save with v1.3 definitions.

## 27. Offline download/package integrity

Downloaded cartridge package is signed/hashed.

Client verifies:

- catalog identity;
- artifact hash;
- engine/kernel compatibility;
- client feature compatibility;
- entitlement where required.

Corrupt/partial download never becomes playable state.

## 28. Local privacy

Offline gameplay SHOULD stay local unless user/account sync features require upload.

Do not upload full private play traces by default solely because the Lab uses rich traces in development.

Telemetry policy can be opt-in/configurable and privacy-minimized.

## 29. Why this still uses BEAM's strengths

Offline mode cannot use BEAM because the mobile app should not embed an entire Erlang VM merely to play a story.

Online architecture remains intentionally BEAM-native.

The split is:

```text
PORTABLE PURE RULES
       |
  +----+-------------------+
  |                        |
mobile local authority     BEAM online authority
SQLite                     OTP + PostgreSQL
                           supervisors
                           processes
                           Phoenix
                           PubSub
                           shards
                           durable workers
```

BEAM is used exactly where its concurrency/fault-tolerance model creates leverage.

The portable rules contract exists because the product explicitly requires disconnected execution while preserving reusable semantics online.

## 30. Product progression

Recommended evolution:

### Stage 1

Offline private storypacks with first-release accounts and durable Story milestone tracking (R12A). Installed play remains offline.

### Stage 2

Optional cloud-save backup and richer catalog/continuity features. Completion synchronization is already required at Stage 1; it does not imply full-save backup.

### Stage 3

Online private versions of same packs, with server-side prologue prerequisites where declared.

### Stage 4

Party/co-op instances.

### Stage 5

Shared social hub/world.

### Stage 6

Storypacks accessible as MMO adventures/instanced regions.

### Stage 7

Selected cartridges promoted to certified shared areas.

### Stage 8

Persistent modern text MMORPG where the cartridge pipeline continuously supplies new adventures and regions.

At no stage is the original cartridge investment discarded.

## 31. Prologue-to-Realm journey

[Document 23](23-accounts-progress-admission.md) requires account-level prologue progress from the first public Story release. Offline completion is recorded locally and synchronized later. The platform labels accepted reports with their real evidence source and maps approved milestones to account-wide onboarding requirements. Realm checks those requirements on the server. This narrow admission policy is not permission to import offline items, gold, levels or competitive rewards. Account-service outages and expired login sessions cannot disable installed local play.

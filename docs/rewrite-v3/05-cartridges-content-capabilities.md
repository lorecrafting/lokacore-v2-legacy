# 05 — Cartridges, Content, and Capabilities

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: content format and capability boundary.

Follow definitions, compilation, versioning and immutable releases. Deployment/extension details have their own applicability.

<details>
<summary>Sections in this document</summary>

- [1. Cartridge definition](#1-cartridge-definition)
- [2. Source layout](#2-source-layout)
- [3. Manifest](#3-manifest)
- [4. Local keys and qualified identity](#4-local-keys-and-qualified-identity)
- [5. Content envelope](#5-content-envelope)
- [6. Capability registry](#6-capability-registry)
- [7. Capability discovery API](#7-capability-discovery-api)
- [8. Compile stages](#8-compile-stages)
- [9. Authoring-time templates/mixins](#9-authoring-time-templatesmixins)
- [10. Controlled compiler functions](#10-controlled-compiler-functions)
- [11. Assets](#11-assets)
- [12. Immutability](#12-immutability)
- [13. Dependencies between cartridges](#13-dependencies-between-cartridges)
- [14. Capability packs](#14-capability-packs)
- [15. Definition versus state](#15-definition-versus-state)
- [16. Spawn model](#16-spawn-model)
- [17. World topology](#17-world-topology)
- [18. Localization](#18-localization)
- [19. Content migrations](#19-content-migrations)
- [20. Cartridge artifact](#20-cartridge-artifact)
- [21. Promotion states](#21-promotion-states)
- [22. Cartridge/deployment split](#22-cartridgedeployment-split)
- [23. Cartridge ports and extension points](#23-cartridge-ports-and-extension-points)
- [24. Realm-native cartridges and portable Story reuse](#24-realm-native-cartridges-and-portable-story-reuse)
- [25. Composable world-primitive contract](#25-composable-world-primitive-contract)
- [27. Cartridge completion milestones](#27-cartridge-completion-milestones)
- [28. Operation ownership and recipe expansion](#28-operation-ownership-and-recipe-expansion)

</details>
<!-- packet-navigation:end -->

## 1. Cartridge definition

A cartridge is an immutable, versioned, compiled bundle of game definitions and assets that Loka can instantiate.

A cartridge is not:

- a separate executable app;
- arbitrary mobile code;
- a second server engine;
- a mutable live directory.

## 2. Source layout

Recommended source form:

```text
cartridges/
└── fox_spirit_of_yunmeng/
    ├── cartridge.yaml
    ├── rooms/
    ├── npcs/
    ├── items/
    ├── quests/
    ├── dialogues/
    ├── scripts/
    ├── systems/
    ├── localization/
    │   ├── en/
    │   └── zh/
    ├── assets/
    └── tests/
```

Source YAML is human/LLM friendly. The compiler normalizes it into typed definitions.

## 3. Manifest

Example:

```yaml
api_version: loka/v3
id: fox_spirit_of_yunmeng
version: 1.2.0
title: The Fox Spirit of Yunmeng

requires:
  kernel_api: ">=1.3 <2.0"
  rule_ir: 1
  content_schema: 1
  capabilities:
    - movement@1
    - dialogue@2
    - quest@3
    - schedule@1
    - weather@1
  client_features:
    - contextual_actions_v1
    - dialogue_choices_v1

supported_profiles:
  - offline_private
  - online_private

entry:
  room: rooms/ferry_dock

locales:
  default: en
  available: [en, zh]
```

### Compatibility versions

`kernel_api` describes portable semantic capabilities implemented by the installed kernel. `rule_ir` versions the normalized LokaScript/rule representation. `content_schema` versions compiled definition structure.

Published cartridges pin exact `rule_ir` and `content_schema` versions and declare a `kernel_api` compatibility range. Their compiled lock data pins exact capability versions, and their certificate records the exact portable-rules/kernel implementation revision(s) actually tested. Compatibility and migrations MUST be explicit; host/app upgrades may not reinterpret old rule IR or capability semantics implicitly.

### Version vocabulary

These version fields are intentionally separate:

| Field | Owns |
|---|---|
| `api_version` | Human/LLM-authored source document/schema family. |
| `kernel_api` | Portable deterministic semantics implemented by the installed kernel. |
| `rule_ir` | Normalized interpreted LokaScript/rule representation. |
| `content_schema` | Compiled definition/artifact structure. |
| `protocol_version` | Realm Mode network command/message compatibility; not required for offline Story execution. |
| `client_features` | Presentation/input capabilities available in the installed Loka app. |
| capability `key@version` | Semantic contract for one reusable capability. |

Do not use one version number as a proxy for another.

A cartridge certificate records the exact versions/ranges that were compiled and tested.

## 4. Local keys and qualified identity

Within a cartridge:

```text
rooms/ferry_dock
npcs/old_ferryman
quests/missing_child
```

Compiler resolves to:

```text
fox_spirit_of_yunmeng@1.2.0:room/ferry_dock
```

No global content-key namespace.

## 5. Content envelope

Every definition uses a standard envelope:

```yaml
api_version: loka/v3
kind: npc
key: old_ferryman
tags: [human, ferryman]

components:
  description:
    short: Old Ferryman
    long: ...
  schedule:
    ...
  dialogue:
    ref: dialogues/ferryman
```

Fields outside registered schemas are errors unless explicitly allowed under extension metadata.

## 6. Capability registry

A capability is an engine-supported reusable semantic feature.

### Canonical capability vocabulary

Use these terms consistently in v3:

| Term | Meaning |
|---|---|
| **Capability** | Versioned feature contract registered by the engine. Owns schemas and the commands/events/effects/policies/rules it introduces. |
| **Component** | Typed definition/runtime data attached to an entity or scoped state. A component is data/state, not an independent authority. |
| **Behavior** | Declarative autonomous rule configuration supplied by a capability, such as patrol or schedule. Behaviors produce typed intents/proposals and never bypass the authority decision path. |
| **ReactionRule** | Builder-composable event/fact/state-transition reaction: typed trigger + selector + Policy + registered consequences. The safe replacement for arbitrary special-procedure callbacks. |
| **Action** | Player/agent affordance advertised in GameView; invocation is revalidated by the active authority and resolved into a typed Command. |
| **ActionRecipe / ComposedAction** | Immutable builder-defined Action semantics assembled from registered TargetSpec/Policy/cost/check/consequence/narration primitives; useful for new local verbs without engine-code changes. |
| **Policy / condition** | Pure predicate tree deciding whether an action/content path is allowed/visible. |
| **Command** | Request to authoritative game semantics. |
| **DomainEvent** | Immutable fact produced during a decision. |
| **StateDelta** | Proposed authoritative state change accumulated before commit. |
| **Effect** | Typed post-decision instruction whose durability/retry semantics are explicit; not a hidden DB mutation path. |
| **GameView** | Host-neutral semantic projection consumed by mobile rendering. |
| **Fact** | Typed, namespaced, scoped durable narrative/world truth intended for cross-system observation. |

`trait` is historical Lokacore terminology and SHOULD NOT be a separate v3 schema concept. Old trait ideas become Behaviors/capabilities.

Likewise, a generic runtime `signal` is not a fifth event system. Cartridge-local notifications compile to registered/namespaced DomainEvents.

Examples:

```text
movement
container
equipment
combatant
merchant
schedule
patrol
wander
ambient
weather_reaction
dialogue
quest_giver
faction_member
reputation
status_effect
crafting_station
inspectable_detail
reaction
population
commerce
scene
narration
perception
```

Capability metadata includes portability classification:

```elixir
%CapabilitySpec{
  key: "schedule",
  version: 1,
  portability: :portable,
  applies_to: [:npc, :system],
  definition_schema: ...,
  runtime_components: [...],
  commands: [...],
  events: [...],
  effects: [...],
  consequence_operators: [...],
  policies: [...],
  dependencies: [...],
  docs: ...,
  examples: [...]
}
```

The registry is engine-owned and enumerable.

### Capability version immutability

A published capability contract `key@version` is immutable in meaning.

Once a certified/published cartridge depends on `schedule@1`, a later engine release MUST NOT silently change `schedule@1` semantics.

Breaking semantic/schema changes require a new capability version.

Published cartridges/deployments pin exact capability versions in their compiled lock data. Deprecation may prevent **new** content from selecting an old version, but supported old artifacts either:

- continue to execute that version;
- receive an explicit certified migration;
- or are covered by a documented compatibility-support policy.

This rule applies to both portable and server-only capabilities.

Portability is one of `:portable`, `:server_only`, or `:client_presentation_only`. An `offline_private` cartridge cannot compile if a gameplay dependency is server-only.

If one immutable cartridge release declares both `offline_private` and an online profile, its **base gameplay semantics MUST remain portable**. Realm-only mechanics belong in a separate deployment/adaptation overlay or a Realm-native cartridge, not a hidden profile branch that changes the meaning of the offline artifact.

Server-only does **not** mean side-effectful arbitrary Elixir. Server-only gameplay capabilities MUST participate in the same command/event/delta/effect decision contract as portable capabilities. They return proposed state deltas/events/effects to the online decision coordinator and MUST NOT write Repo/PubSub/external services directly from rule evaluation.

### Capability semantic residency matrix

Portability classification answers **where a cartridge is allowed to run**. The implementation must also keep an explicit architecture-level residency map answering **where each semantic evaluator and host responsibility lives**.

At minimum, the generated/checked residency view distinguishes:

| Residency class | Owns | Must not own |
|---|---|---|
| portable semantic foundation | canonical deterministic value types, delta/event/error semantics, time/RNG/ID rules | persistence, network, sessions, shard ownership |
| portable capability implementation | capability rules that must behave identically in Story and Realm hosts | host authority, database commits, transport |
| Realm-only semantic capability | pure server-only rule evaluators that join DecisionCoordinator | direct Repo/PubSub/external writes |
| authority-host coordination | serialization, receipts, transactions, persistence, scheduling orchestration, fencing, handoff | cartridge-specific hidden game semantics |
| client presentation | rendering/input/accessibility/haptics and other non-authoritative presentation | gameplay legality or authoritative mutation |
| authoring/certification | compiler, Builder, Lab, evidence production | ordinary released gameplay authority |

This matrix exists to prevent two opposite failures:

1. **kernel creep** — moving BEAM-native sessions, persistence, orchestration, commerce platform work, or shard coordination into the portable implementation merely to reduce language count;
2. **semantic drift** — leaving an offline-required gameplay rule in host-specific code without a portable implementation/conformance obligation.

For every registered capability version, tooling SHOULD be able to report its portability, semantic implementation residency, host adapters, and conformance fixtures. If R1 selects Rust, the portable implementation SHOULD remain modular by capability/package rather than becoming one monolithic native game server hidden behind FFI. If R1 selects dual implementations, the same residency map identifies every semantic contract that requires golden cross-host parity.

Host services such as PostgreSQL commit coordination or Phoenix sessions are not made into gameplay capabilities merely to appear in this matrix.

## 7. Capability discovery API

Builder tools support:

```text
capabilities.search(query)
capabilities.get(key, version)
capabilities.examples(key)
capabilities.compatible_with(kind)
capabilities.dependencies(key)
```

This replaces giant LLM manuals.

## 8. Compile stages

```text
source load
  ↓
syntax/schema parse
  ↓
template/mixin expansion
  ↓
local ref resolution
  ↓
capability validation
  ↓
policy/action/script validation
  ↓
graph validation
  ↓
localization/assets validation
  ↓
normalization
  ↓
canonical serialization
  ↓
content hash
  ↓
compiled cartridge artifact
```

Every stage emits structured diagnostics.

## 9. Authoring-time templates/mixins

Reuse is useful, but runtime inheritance is not required.

Example:

```yaml
use:
  - template: templates/humanoid_npc
  - mixin: mixins/day_worker

components:
  description:
    short: Old Ferryman
```

Merge rules MUST be deterministic per field/capability.

Recommended defaults:

- scalar: child replaces;
- map: schema-directed deep merge;
- keyed collections: merge by declared key;
- ordinary list: replace unless schema says append;
- tags: union;
- policies/actions: merge by stable key according to defined algebra.

Compiler records provenance for debugging.

Cycles are compile errors.

Compiled definition is flat.

## 10. Controlled compiler functions

Some dynamic authoring conveniences may use registered compiler functions similar to safe macro/prototype functions.

Example:

```yaml
components:
  loot:
    table:
      generate:
        function: weighted_loot
        args:
          tier: village
```

Compiler functions:

- are engine-registered;
- have typed inputs/outputs;
- have no arbitrary filesystem/network access;
- are deterministic unless explicitly seeded;
- are testable;
- run before hash generation.

## 11. Assets

Compiled artifact includes manifest of asset hashes, sizes, media type, locale/variant.

Large binary assets SHOULD live in object storage/CDN referenced by hash.

A cartridge content hash covers:

- normalized definitions;
- canonical compiled/normalized rule IR (and source digest/provenance where desired);
- asset manifest;
- localization manifest;
- compatibility requirements and exact capability lock.

Runtime semantics are keyed to the normalized artifact, not to host-specific compiler output bytes.

### Hash domains and attestations

The canonical **cartridge/content hash** identifies the immutable semantic payload above. It MUST exclude signatures, certificate references/copies, catalog metadata, download-envelope metadata, and other values that can only be created after the semantic hash exists.

Certification records reference the semantic hash. Signatures/attestations may sign that hash plus explicitly versioned release metadata. A downloadable archive MAY also have a separate **package/transport hash** covering its exact bytes.

Do not create a self-referential hash cycle where adding `certificate-ref.json` or a signature changes the cartridge hash that the certificate/signature is supposed to attest.

## 12. Immutability

Published cartridge release cannot be edited in place.

For a published cartridge ID, a semantic version identifies exactly one immutable artifact hash. A different hash MUST NOT later be published under the same `cartridge_id@version`; fixes require a new version/release.

Catalog may point new purchases/instances to the latest compatible release while old active saves remain pinned.

## 13. Dependencies between cartridges

Avoid cross-cartridge dependencies in the first release.

Later, if needed, dependencies must be explicit:

```yaml
dependencies:
  - cartridge: loka_core_folklore
    version: "^1.0"
```

Compiler resolves exact versions into release lock data.

Do not allow “whatever latest happens to be installed.”

## 14. Capability packs

Engine features may be grouped into versioned capability packs, but capabilities remain individually introspectable.

Examples:

- core-world;
- combat;
- crafting;
- social;
- economy.

A cartridge declares what it uses.

This helps certification choose relevant test suites.

## 15. Definition versus state

Definitions describe initial/default behavior.

Runtime state belongs to world/quest/entity state.

Bad:

```yaml
npc:
  current_hp: 17
```

as mutable published content.

Good:

```yaml
components:
  combatant:
    max_hp: 50
```

Runtime entity state stores current HP.

## 16. Spawn model

Spawn operations reference definitions and create runtime entities under an instance owner.

Spawn must declare:

- definition ref;
- destination/container;
- scope/instance;
- optional allowed overrides;
- deterministic spawn identity policy if needed.

Overrides are validated against capability schemas.

## 17. World topology

Rooms and exits are definitions; runtime exits may carry mutable state such as lock/open status.

Compiler validates:

- target exists;
- direction semantics;
- intended reciprocal links;
- reachability rules;
- orphan regions;
- inaccessible required quest targets.

Custom named connections MAY exist; mobile UI renders action labels instead of assuming cardinal directions only.

## 18. Localization

Content strings SHOULD use stable string IDs for production-ready cartridges, even if authoring allows inline defaults.

Compiler can extract inline prose into locale catalogs later, but the format should anticipate:

```text
title_key
description_key
action_label_key
dialogue_text_key
```

Certification checks missing locale entries.

## 19. Content migrations

A new content release may include explicit migration declarations.

Migrations MUST be deterministic and testable against snapshots.

No runtime content loader should infer renamed keys from similarity.

## 20. Cartridge artifact

Potential logical artifact:

```text
manifest.json
definitions.bin/json
scripts.bin
localization/
asset-manifest.json
schema-lock.json
certificate-ref.json (optional release-envelope material; excluded from semantic cartridge hash)
```

Packaging format is implementation detail. The semantic cartridge hash must be reproducible from normalized inputs; exact archive bytes may additionally use a separate package/transport hash.

## 21. Promotion states

```text
draft workspace
  ↓
compiled candidate
  ↓
certification candidate
  ↓
certified hash
  ↓
staging
  ↓
published catalog release
  ↓
deprecated/withdrawn (still available to pinned saves as policy allows)
```

Authors cannot skip from draft directly to production.


## 22. Cartridge/deployment split

The cartridge defines reusable story/world semantics. A deployment defines how that exact cartridge is hosted: offline private, online private, party, embedded instance, or shared realm area.

Deployment overlays may change hosting policy—such as realm mount point, NPC respawn policy, or economy integration—but any semantic override is separately hashed and certified. This is the mechanism for reusing a storypack inside the later MMORPG without pretending every private-world assumption is globally shareable.


## 23. Cartridge ports and extension points

Cartridges that may participate in campaigns or the later MMORPG SHOULD expose explicit composition ports rather than encourage arbitrary cross-cartridge references.

Examples:

```yaml
ports:
  entries:
    ferry_road:
      room: rooms/ferry_dock
  exits:
    northern_road:
      room: rooms/north_gate
  continuity:
    exports:
      - memory.saved_ferryman
  extension_points:
    village_notice_board:
      accepts: [quest_hook, rumor_source]
```

A campaign/deployment may bind ports:

```yaml
mounts:
  - from: chapter_1:exits/northern_road
    to: chapter_2:entries/southern_road
```

Rules:

- ports are versioned cartridge API;
- internal definition keys remain private unless exported;
- extension points declare accepted contribution kinds/schemas;
- binding validation happens at campaign/deployment compile time;
- published cartridge artifacts remain immutable;
- adding an expansion changes the composite campaign/deployment manifest, not the old artifact.

This creates a stable module boundary for chapters, side adventures, and MMO region mounting.


## 24. Realm-native cartridges and portable Story reuse

`cartridge` is the generic immutable content/rules artifact in v3; it does not mean “must be purchasable offline.”

There are two common forms:

### Portable Story cartridge

- built with target `story`;
- portable capabilities only;
- may certify `offline_private`;
- may later be hosted online unchanged for private/party use where semantics fit;
- Realm-only additions are deployment/adaptation overlays.

### Realm-native cartridge

- built with target `realm`;
- may depend on server-only capabilities;
- need not run offline;
- still uses the same content namespaces, capability registry, compiler, hashes, references, and certification machinery.

This preserves one content toolchain without pretending all Realm content is portable.


## 25. Composable world-primitive contract

The normative layered composition model is defined in [21 — Composable World Primitives and Builder Expressivity](21-composable-world-primitives.md).

The capability/content system MUST be able to represent, version, validate, and introspect at least the foundation shapes needed for:

- deterministic TargetSpec/TargetResolution;
- typed relations rather than duplicated subsystem-local truth;
- InspectableDetail and description variants;
- coherent Connection/Barrier state;
- ReactionRule;
- Behavior intent/arbitration metadata;
- SpawnBundle and provenance-safe PopulationPlan;
- commerce provider/catalog/stock/price/admission/liquidity/restock semantics;
- NarrationSpec;
- SceneDefinition/SceneInstance + SceneSpace;
- InstancePlan instancing/import/export semantics;
- WorldEventPlan composition.

Not every item in the broader primitive catalog is an R3/R5 implementation requirement. The primitive-graduation rule in document 21 determines when a repeated composition should become an engine capability.

### Authored area versus runtime shard

An **AreaDefinition** is a content/geography organization concept.

A **ZoneShard** is a Realm mutation-owner placement concept.

They MUST NOT be synonyms. A deployment may place multiple authored areas in one shard or partition one large authored area across authority domains if later topology requires it.

### Population provenance

A PopulationPlan may replenish/clean up only the lifecycle state that its explicit provenance/policy owns.

It MUST NOT reset an area to definition defaults by deleting or rewriting unrelated player-owned, quest-owned, or independently mutated entities/state.

### Coherent connections

Where two room faces represent one logical door/gate/bridge, they SHOULD reference one authoritative Barrier state.

The compiler should reject contradictory duplicated mutable barrier definitions unless the author explicitly declares independent/asymmetric semantics.

## 27. Cartridge completion milestones

A source manifest may declare versioned milestone keys with rule-owned triggers and allowed outcomes. Chapter one's `prologue_completed` covers either intended ending after the durable terminal scene consequence, not a client credits-screen event. The compiler validates declarations and their narrative-capability dependencies when the R3/R7 schema freezes. Milestone events use the normal typed decision/commit pipeline.

A cartridge declaration does not grant an account entitlement or authorize Realm admission. An independently administered platform mapping selects approved exact release/milestone/outcome combinations for onboarding requirements. See [document 23 sections 3 and 7](23-accounts-progress-admission.md#3-declare-completion-once-independently-of-the-platform-unlock).

## 28. Operation ownership and recipe expansion

For the initial composition profile (04 §5.2–5.4), every registered operation declares versioned input/result types, canonical target identity, permitted scope, preconditions, read/write footprint, failure modes, generated-event permissions, deterministic cost and invariant obligations. Distinct custom namespaces do not grant permission to impersonate engine-owned events. A schema-valid `item_transferred` payload is not evidence of conserved transfer unless its owning capability produced it.

Recipe/template expansion is compile-time, deterministic and source-mapped. Non-semantic file/map reordering leaves canonical artifacts unchanged; explicit sequence order and semantic ordering IDs remain hashed semantics. Store authored-source → expanded-node → operation mappings for actionable diagnostics. An ActionRecipe composes supported operations; it cannot invent a persistence/concurrency model or call a generic component-path setter.

Facts should represent distinct narrative truth, not shadow canonical containment, quest/scene lifecycle, entitlements or platform admission. Query an owning capability or derive prose/actions when no independent history is required. Knowledge, testimony and physical truth use distinct typed meanings when admitted by content. This does not add new capability families to the chapter-one lock.

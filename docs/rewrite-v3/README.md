# Loka v3 Rebuild Specification Packet

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Packet overview and authority map.

Start with the review guide and milestone guide; section 8 defines the document authority/conflict rules.

<details>
<summary>Sections in this document</summary>

- [1. Why this packet exists](#1-why-this-packet-exists)
- [2. Normative language](#2-normative-language)
- [3. Product invariant](#3-product-invariant)
- [4. Architecture in one diagram](#4-architecture-in-one-diagram)
- [5. BEAM-native design rule](#5-beam-native-design-rule)
- [6. Working top-level decisions](#6-working-top-level-decisions)
- [7. Packet index](#7-packet-index)
- [8. Specification authority map](#8-specification-authority-map)
- [9. What this packet deliberately does not do](#9-what-this-packet-deliberately-does-not-do)
- [10. Reference implementation policy](#10-reference-implementation-policy)
- [11. Specification change discipline](#11-specification-change-discipline)
- [12. R0 cutover and implementation-facing specification organization](#12-r0-cutover-and-implementation-facing-specification-organization)
- [13. Launch identity and the prologue journey](#13-launch-identity-and-the-prologue-journey)

</details>
<!-- packet-navigation:end -->

**Status:** Draft — audit-corrected review candidate; R0 acceptance and independent review remain pending; not implementation authorization

**Last housekeeping pass:** 2026-09-22

**Source system:** `lorecrafting/lokacore`  
**Strategic parent:** `docs/product/CARTRIDGE-ROADMAP.md`  
**Purpose:** define a clean-room rebuild of Loka as one mobile product with two strictly separated authority modes—offline-first **Story Mode** and BEAM-authoritative **Realm Mode**—while preserving portable cartridge semantics where reuse is valuable and removing transitional Lokacore architecture.

## 1. Why this packet exists

Lokacore has accumulated several generations of otherwise reasonable architecture:

- V1 and V2 entity APIs coexist;
- persistence can be mutated through both database APIs and active EntityServer state;
- Engine and Framework boundaries document known dependency violations and disable outbound enforcement;
- Content and Framework form a dependency cycle;
- gameplay uses both structured `Loka.Engine.Event` values and separate tuple events returned by `Loka.Game.Actions.Result`;
- terminal-builder and MCP-builder paths overlap but do not share one canonical operation layer;
- builder documentation contains historical contracts that disagree with current code;
- the React Native client and Phoenix channel protocol have drifted;
- first-party scripting is useful but the current same-BEAM `Code.eval_string` sandbox is not a strong hostile-code boundary.

Repairing these individually is possible. A clean rebuild is attractive because the product direction is also changing: Loka is now intended to launch as a cartridge platform and grow into a persistent modern MUD.

The rebuild MUST therefore be **specification-first**. The implementation model, whether Astra, Foundry, another coding agent, or a human developer, should implement explicit contracts rather than infer architecture from historical code.

## 2. Normative language

This packet uses:

- **MUST / MUST NOT** — architectural invariant; violating it requires an explicit spec amendment.
- **SHOULD / SHOULD NOT** — strong default; exceptions require documented evidence.
- **MAY** — permitted variation.

When code and this packet disagree in the future, accepted amendments and tests determine the contract. Markdown alone must not become a second unverified source of truth for machine-readable schemas.

### Do not conflate product, authoring, and runtime axes

| Axis | Values | Meaning |
|---|---|---|
| **App mode** | Story Mode / Realm Mode | Which authority adapter the one Loka mobile app is using now. |
| **Builder target** | `story` / `realm` / `promote` | Which authoring constraints and certification policy apply to the workspace. |
| **Execution profile** | `offline_private` / `online_private` / `party` / `shared_area` | How a compiled cartridge/deployment is hosted at runtime. |
| **Artifact type** | cartridge release / deployment / campaign | Immutable content module, hosting policy, or composition/continuity manifest. |

These axes interact but are not aliases.

### Canonical gameplay pipeline

Every authoritative gameplay mutation MUST converge on the same semantic decision/commit spine.

Player/agent input uses ActionInvocation; trusted autonomous world work uses a typed authority-internal Command origin:

```text
touch/text/player-agent/test-bot
  -> ActionInvocation
  -> authorize + recognize receipt (matching retry returns prior outcome)
  -> NEW attempt: authority re-resolves + revalidates
  -> typed semantic Command
                         \
scheduler / durable job  \
BehaviorIntent arbitration -> typed internal Command
Population reconciliation  /
world-event/system trigger /
                         /
  -> DecisionCoordinator / portable decision layer
  -> StateDelta + DomainEvents + Effects
  -> authoritative commit + receipt/outbox
  -> committed state
  -> GameView projection
  -> client presentation
```

Adapters MAY collapse implementation steps, but they MUST NOT collapse the semantic boundaries. In particular:

- shared UI/text/player-agents/test bots emit `ActionInvocation`, not authority-internal Commands;
- schedulers/autonomous Behaviors/population reconciliation/world-event machinery may originate only registered authority-internal Commands with stable causation/idempotency and must use the same decision/commit path;
- authoritative same-domain mutations are represented by `StateDelta`, not hidden Effects;
- DomainEvents describe facts produced by a decision; they are not transport messages;
- Effects cross a post-decision boundary or request explicitly typed follow-up work; they are not an alternate state-write path;
- GameView is a semantic projection, not a dump of persistence structs.

### Authority vocabulary

Use these terms consistently:

- **authority host** — the environment running authoritative gameplay: local Story authority or BEAM Realm authority;
- **GameSession adapter** — the UI-facing Story/Realm session abstraction; `LocalStorySession` delegates to local authority while `RemoteRealmSession` delegates over transport and is never Realm authority;
- **mutation owner** — the serialized owner of one mutable state domain, such as `LocalInstanceAuthority`, `WorldInstance`, or `ZoneShard`;
- **durable store** — SQLite/PostgreSQL persistence for committed state; durability does not make the database a second decision authority;
- **state scope** — who owns a fact/progression value: player, party, instance, or realm;
- **audience** — who may perceive/interact with a projection/entity;
- **capacity owner/scope** — who competes for a scarce resource or service;
- **service aggregate/provider** — the domain object whose queue/capacity is modeled; it does **not** automatically imply a dedicated OTP process;
- **authority revision** — concurrency/version token for committed authoritative state;
- **idempotency scope** — stable logical gameplay lineage used to deduplicate retryable mutations; it outlives session/process/shard ownership so a handoff cannot mint a fresh mutation identity;
- **projection sequence/view token** — client-facing ordering/freshness token for one projected stream. It is not necessarily the authority revision.

State scope, audience, capacity scope, and physical authority placement are deliberately independent. A player-scoped quest in a shared Realm zone, for example, does not imply that the player becomes a new mutation authority.

Examples:

- Story Mode normally runs an `offline_private` profile built with target `story`.
- Realm Mode can run `online_private`, `party`, or `shared_area`.
- A `promote` workspace takes a certified Story cartridge and produces a new Realm deployment/adaptation; it does not change the app mode or mutate the source artifact.

## 3. Product invariant

Loka v3 is one game platform with one content/capability framework and a portable deterministic subset serving:

1. offline private storypacks in Loka Story Mode;
2. online private/party adventures in Loka Realm Mode;
3. certified shared areas in Loka Realm Mode;
4. eventually, a persistent text-first multiplayer world.

These modes MUST use the same compiled cartridge contracts and portable deterministic rule semantics where the cartridge declares offline support. Single-player is not a disposable engine: the authority host changes from local mobile to BEAM as content moves online.

A released cartridge MUST remain playable without an AI model or authoring factory online.

## 4. Architecture in one diagram

```text
                         ONE LOKA APP
                              |
                         GameView UI
                              |
                         GameSession
                        /           \
                       /             \
          LocalStorySession       RemoteRealmSession
                 |                  Phoenix transport
       LocalInstanceAuthority            |
          portable rules                BEAM
          local SQLite          WorldInstance / ZoneShard
                                      |
                              DecisionCoordinator
                               /              \
                    portable rules       server-only
                                         Elixir rules
                               \              /
                                StateDelta/events/effects
                                         |
                                     PostgreSQL

AUTHORING PLANE
Astra / Foundry / human terminal / CI
             |
        loka_builder
 story | realm | promote workspaces
             |
 compiler -> Cartridge Lab -> certificate
```

The mobile shell and `GameSession` interface are shared; **authority is not**.

`LocalStorySession` is an adapter over `LocalInstanceAuthority`, which resolves/commits Story play locally. `RemoteRealmSession` is a transport adapter only: it sends ActionInvocations to BEAM, where `WorldInstance`/`ZoneShard` owns Realm mutation authority. It never treats any embedded/local rules execution as Realm authority.

The transport, authoring, runtime, domain, and persistence planes MUST remain separable.

## 5. BEAM-native design rule

The rebuild MUST use the strengths of Elixir/OTP intentionally:

- supervision for restart and fault containment;
- processes for independently concurrent **owners/services**, not automatically for every noun;
- message passing across ownership boundaries;
- DynamicSupervisor/Registry for dynamic world instances and sessions;
- Phoenix PubSub for fan-out notification, not as the authoritative mutation mechanism;
- explicit process state for hot working sets;
- crash/restart recovery from durable state;
- telemetry attached to command/event/effect causation.

The rebuild MUST NOT turn every room, item, quest, or NPC into a GenServer merely because the BEAM makes processes cheap.

The online authority/orchestration layer SHOULD remain idiomatic Elixir/OTP. Rules that must execute both offline and online MUST follow the portable deterministic semantic contract selected by R1. A shared native kernel is the working hypothesis; if R1 selects the documented dual-implementation fallback, golden conformance preserves the same contract. Server-only orchestration and capability adapters remain Elixir.

## 6. Working top-level decisions

| Topic | Current draft direction |
|---|---|
| Online language/runtime | Elixir on BEAM/OTP |
| Portable offline rules | One deterministic portable semantic contract; the shared-kernel candidate is chosen by the R1 spike, with dual-implementation golden conformance as the fallback |
| Server UI/API | Phoenix |
| Mobile | One React Native / Expo app with strict Story Mode (local authority) and Realm Mode (remote BEAM authority) session boundaries |
| Persistence | PostgreSQL for online/platform durability when those phases arrive; offline Story saves use local SQLite |
| Game authority | offline: local serialized authority; online: BEAM server authoritative |
| Offline private authority | local serialized instance authority + local SQLite |
| Online private concurrency | one authoritative BEAM world-instance owner process |
| Shared-world concurrency | zone/area shard owners under a realm coordinator |
| Content | source YAML/JSON-like data -> compiled immutable cartridge |
| Runtime identity | cartridge-qualified definition refs + UUID runtime instance IDs |
| State correctness | single mutation authority + transactional persistence/outbox |
| Game decisions | pure/replayable functions with injected clock and RNG |
| Scripting | Declarative composition only for the first cartridge; LokaScript deferred (ADR-018) until a real cartridge demonstrates a gap |
| Builder | canonical typed Builder API; MCP/terminal/CLI are adapters |
| Realm transport protocol | one machine-readable external schema with generated TypeScript/Elixir validation, introduced with Realm Mode |
| Release | exact certified semantic cartridge/deployment hash |
| AI | author/reviewer/tool client, never runtime authority |
| Accounts and prologue tracking | Required at first public Story launch (R12A); offline-first gameplay; authenticated reports may satisfy onboarding-only Realm prerequisites (ADR-063, document 23) |

### Intentionally unresolved evidence gates

Two choices remain deliberately provisional rather than being papered over by the specification:

1. **portable kernel technology/binding** — three candidates (A one TypeScript kernel, B one Rust kernel, C dual Elixir/TypeScript implementation) are compared against `r1-acceptance-envelope.md`; A is built first, and none is selected before the spike;
2. **App Store treatment of downloadable rule content** — the product requires downloadable offline stories, but the exact bounded rule representation must survive current store-review constraints.

Implementation MUST NOT treat either provisional choice as settled before its evidence gate passes.

## 7. Packet index

**Start with [the human/LLM review guide](REVIEW-GUIDE.md).** It explains the reading order, the different ID systems, and how to leave review findings. [Every R milestone in plain English](R-MILESTONES.md) is the roadmap companion; [document 14](14-implementation-plan.md) still governs phase tasks and gates.

| Review area | Documents |
|---|---|
| Product and release scope | [00 — Full Ashmere design](00-first-cartridge-design.md), [00a — Chapter one](00a-chapter-one-content.md), [R6P — Earlier playable proof](pre-release-proof.md), [generated release scope](release-scope.md) |
| Core architecture | [01 — Principles](01-core-principles.md), [07 — Story/Realm and portability](07-offline-storypacks-to-mmo.md), [02 — Online runtime](02-beam-runtime-architecture.md), [03 — State and persistence](03-domain-state-persistence.md), [04 — Decision and protocol contracts](04-command-event-effect-protocol.md) |
| Content and mechanics | [05 — Cartridge/capability contracts](05-cartridges-content-capabilities.md), [21 — Composition vocabulary](21-composable-world-primitives.md), [06 — Narrative and actions](06-quests-dialogue-actions-scripting.md), [19 — Sharing, instances, capacity](19-quest-sharing-instancing-capacity.md) |
| Authoring and release assurance | [08 — Builder/factory](08-builder-api-ai-factory.md), [09 — Lab/certification](09-cartridge-lab-certification.md), [10 — App/commerce/release](10-mobile-commerce-release.md), [11 — Security/operations](11-security-observability-operations.md) |
| Decisions, plan and evidence gates | [16 — Decision register](16-decision-register.md), [14 — Implementation plan](14-implementation-plan.md), [15 — Acceptance scenarios](15-acceptance-scenarios.md), [R1 — Proposed experiment envelope](r1-acceptance-envelope.md) |
| Reference evidence, not current implementation instructions | [12 — Evennia](12-evennia-lessons.md), [20 — Classic MUDs](20-classic-mud-lessons.md), [22 — Ink](22-ink-runtime-lessons.md), [13 — Legacy inventory](13-lokacore-feature-inventory.md), [17 — Research baseline](17-research-baseline.md), [18 — Review history](18-review-record.md) |

For implementation, use [INDEX.md](INDEX.md) to locate governing contracts, not to replace them. The [planning matrix](release-scope.json) generates the release checklist; the [contract corpus](conformance/README.md) explains the small executable specification model and the separate future host-evidence obligations. [Index cut candidates](INDEX-cut-candidates.md) are review suggestions, not approved deletions or permissions to omit invariants.

File numbers, R milestones, and review order are different axes. The thematic grouping above does not rename files or change their authority.

[Accounts, Story Progress, and Realm Admission](23-accounts-progress-admission.md) — launch identity, offline completion synchronization, and server-owned prologue prerequisites.

## 8. Specification authority map

This packet is intentionally comprehensive, but not every document has the same authority.

### Normative architecture

Implementation MUST conform to:

- `01-core-principles.md`
- `02-beam-runtime-architecture.md`
- `03-domain-state-persistence.md`
- `04-command-event-effect-protocol.md`
- `05-cartridges-content-capabilities.md`
- `06-quests-dialogue-actions-scripting.md`
- `07-offline-storypacks-to-mmo.md`
- `08-builder-api-ai-factory.md`
- `09-cartridge-lab-certification.md`
- `10-mobile-commerce-release.md`
- `11-security-observability-operations.md`
- `19-quest-sharing-instancing-capacity.md`
- `21-composable-world-primitives.md`
- `23-accounts-progress-admission.md`
- accepted decisions in `16-decision-register.md`

### Normative content pull list

- `00-first-cartridge-design.md` — the full design and release ladder;
- `00a-chapter-one-content.md` — chapter-one content details, read with that ladder.

Document 00 does not define architecture. It defines which capabilities the first product cartridge requires, and therefore which parts of the R5–R8 catalog are mandatory before R10 and which are deferred. Where document 00 names a mechanic the catalog lacks, `21-composable-world-primitives.md` §28 registers it. A capability in the catalog that document 00 does not pull is not an R10 requirement.

### Normative gates and sequencing

- `14-implementation-plan.md`
- `15-acceptance-scenarios.md`

These define what evidence is required before later phases may depend on earlier work. Exact ticket decomposition may evolve without changing architecture.

### Informative/reference evidence

- `12-evennia-lessons.md`
- `20-classic-mud-lessons.md`
- `22-ink-runtime-lessons.md`
- `13-lokacore-feature-inventory.md`
- `17-research-baseline.md`
- `18-review-record.md`
- historical Lokacore documents linked from the product roadmap

These explain why decisions were made but do not override normative contracts.

### Companion status

`pre-release-proof.md` is the proposed R6P work package referenced by document 14. `release-scope.json` is reviewed planning input; `release-scope.md` is generated from it, not a runtime capability registry or certificate. The proposed R1 envelope and numeric profile still require their recorded acceptance gates. `checks/` and `conformance/` are specification-model tooling and fixtures, not the production engine.

`REVIEW-GUIDE.md`, `R-MILESTONES.md`, per-document navigation, and `INDEX.md` are reading aids. They do not introduce new requirements, resolve contradictions by precedence, or mark any gate complete. Dated `reviews/` records and `INDEX-cut-candidates.md` are informative.

### Conflict rule

Two normative documents disagreeing is a **specification defect**. Implementation MUST stop at that boundary until the packet is reconciled. Do not invent an implicit precedence rule, pick whichever text is convenient, or treat newer prose as silently overriding an accepted ADR.

Machine-readable schemas/registries become the executable source of truth for their defined contracts once implemented; this packet governs their intended semantics.

## 9. What this packet deliberately does not do

It does not:

- preserve Lokacore module names for compatibility;
- require an in-place migration of the current application;
- require full event sourcing;
- promise arbitrary public/user scripting;
- design a general-purpose game engine for every genre;
- require distributed BEAM clustering for the first cartridge release;
- make AI inference part of moment-to-moment game rules;
- require every future feature to be anticipated now.

The clean implementation SHOULD begin in a fresh repository only after this packet receives self-review, adversarial review, corrections, and explicit acceptance.

## 10. Reference implementation policy

Lokacore MUST be retained during the rebuild as a read-only design corpus/reference implementation.

It is useful for:

- feature archaeology;
- extracting content semantics and examples;
- studying successful tests;
- identifying historical failure modes;
- recovering world-building primitives;
- comparing new behavior against the old reference implementation where useful.

The v3 implementation MUST be a clean-sheet codebase. It MUST NOT copy, import, wrap, preserve compatibility with, or depend on Lokacore modules/APIs merely to accelerate the rebuild. Lokacore is evidence, not a codebase migration target.

A later one-way content importer MAY translate selected old world/content files into v3 source formats, but the imported result must satisfy v3 schemas exactly and must not require legacy runtime compatibility.

## 11. Specification change discipline

Every major implementation slice MUST cite the relevant spec section in its issue/PR.

If implementation proves a contract wrong:

1. produce evidence;
2. amend the spec first;
3. review the amendment;
4. then update code.

This prevents the specification from silently becoming fiction as happened with historical builder and event documentation.

## 12. R0 cutover and implementation-facing specification organization

Lokacore is the place where the v3 architecture is being designed and reviewed. It is **not** intended to remain a second normative architecture repository after the clean implementation starts.

R0 MUST record:

- the exact accepted v3 commit hash;
- the exact normative file set;
- accepted/provisional/deferred ADR state;
- unresolved evidence gates;
- a compact architecture/invariant index;
- the cutover rule for later amendments.

R2 then imports the accepted normative contracts into the fresh v3 implementation repository.

After that cutover:

- the fresh repository is the implementation-era source of truth for architecture/spec amendments;
- Lokacore and this packet remain provenance, archaeology, and review evidence;
- a change MUST NOT be made independently in both places and reconciled later;
- an implementation agent must never choose between a newer implementation-repo contract and stale Lokacore prose.

The fresh repository SHOULD physically separate concise normative material from explanatory evidence. A representative organization is:

~~~text
docs/
  spec/
    ARCHITECTURE.md          # compact constitutional overview/invariant map
    normative/               # authority, semantics, content, narrative, builder, certification
  decisions/                 # accepted ADRs
  gates/                     # implementation milestones + acceptance scenarios
  reference/
    lokacore-archaeology/
    external-research/
    review-history/
~~~

The exact directory names MAY change, but the authority distinction may not.

The compact implementation-facing architecture should link each important invariant to its machine-readable schema/registry and its governing acceptance/certification checks. The long review record, Evennia/classic-MUD studies, historical architecture, and external research remain valuable evidence, but they do not become peer sources of truth merely because they are detailed.

This organization is intended to make the architecture **harder to misimplement**, not to discard the rationale that produced it.

## 13. Launch identity and the prologue journey

Read [23 — Accounts, Story Progress, and Realm Admission](23-accounts-progress-admission.md) alongside mobile/state/security contracts. Accounts and milestone tracking arrive at the first public Story release, including the free chapter. Installed local gameplay survives offline/auth outages; accepted low-stakes reports satisfy explicitly mapped account onboarding prerequisites, never Realm currency/items/stats or purchase entitlement. R12A is a subdivision of R12; all existing top-level R IDs and the full first-chapter scope remain unchanged.

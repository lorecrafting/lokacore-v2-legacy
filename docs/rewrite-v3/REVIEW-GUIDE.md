# Reviewing the Loka v3 packet

**Purpose:** help a human or LLM read the same packet without confusing the game, engine contracts, implementation sequence, or historical evidence. This guide is informative; [README §8](README.md#8-specification-authority-map) governs document authority.

## Start here

Read [every R milestone in plain English](R-MILESTONES.md) before the detailed phase plan. Then use the passes below. Each numbered document now has a short reader context and a collapsible section menu; filenames and section numbers remain stable.

**The scope is not being reduced.** V3 is a from-scratch engine. The first chapter remains 57 rooms, 10 quests, and two endings. R6P is an earlier playable proof; it is not the first commercial chapter. Powerful LLM-assisted world creation and reasoning are part of the plan, not something forbidden until R16.

**Status matters.** The packet is a draft candidate for review. An ADR marked Accepted records a design direction; a merged PR or a passing specification-model test does not establish R0 acceptance, R1 feasibility, production-engine completion, or device/playtest evidence. Use an exact Git commit when recording findings.

## Four kinds of document

| Kind | How to read it |
|---|---|
| Governing design contracts | These specify intended engine/host/content semantics. Their applicability depends on the feature/profile being built, and the packet still needs R0 acceptance. |
| Product scope and gates | These say which game/mechanics a release needs and what evidence permits advancement. A comprehensive catalog is not automatically a first-release backlog. |
| Reading aids and generated planning views | This guide, the R guide, INDEX, navigation, and the release checklist help locate details. They cannot silently change those details. |
| Informative evidence and history | Prior-art studies, legacy inventory, old review conclusions, and cut candidates explain reasoning. They are not another implementation contract. |

The full classification, including proposed/generated companions and the conflict rule, is in [README §8](README.md#8-specification-authority-map).

## A complete human reading route

### Pass 1 — What are we making?

Read [00](00-first-cartridge-design.md), especially the pitch and §11 chapter ladder; then [00a](00a-chapter-one-content.md), [R6P](pre-release-proof.md), and [release scope](release-scope.md).

**Review questions:** Is the intended experience coherent? Does each chapter's mechanic tier match its actual content? Are the proof and full release unmistakably different? Read the full-campaign “Done means” targets as campaign targets, not extra chapter-one requirements.

### Pass 2 — Who is allowed to change the world?

Read [01 — Principles](01-core-principles.md), [07 — Story/Realm and portability](07-offline-storypacks-to-mmo.md), [02 — BEAM runtime](02-beam-runtime-architecture.md), [03 — State/persistence](03-domain-state-persistence.md), and [04 — Decisions/protocol](04-command-event-effect-protocol.md).

**Review questions:** Is there one mutation owner? Can a retry find its old result before current-world validation? What happens before, during, and after a commit? Are local Story and remote Realm authority distinct? Do not let an online-specific section become a requirement to run BEAM on a phone.

### Pass 3 — How do authors express a world?

Read [05 — Cartridges/capabilities](05-cartridges-content-capabilities.md), [21 — Composition vocabulary](21-composable-world-primitives.md), [06 — Narrative/actions](06-quests-dialogue-actions-scripting.md), and [19 — Sharing/instances/capacity](19-quest-sharing-instancing-capacity.md).

**Review questions:** Can the intended mechanics be composed without hidden engine writes? Can you distinguish a fact, reaction, action, quest, scene, and spatial instance? Which later features are just candidates? LokaScript is deferred under ADR-018; retained scripting designs do not re-admit it. The smithy is an example of reusable capacity/service mechanisms, not a required hardcoded subsystem.

### Pass 4 — How do we build and certify content?

Read [08 — Builder/factory](08-builder-api-ai-factory.md), then [09 — Lab/certification](09-cartridge-lab-certification.md). Start document 09 with §1a's chapter-one minimum before reviewing its broader assurance design.

**Review questions:** Can an author use the tools without engine-source authority? What makes evidence valid for an exact artifact? Which gates apply to the actual features used? Keep candidate-authored tests, deterministic engine checks, semantic model review, and human feedback distinct.

### Pass 5 — What must a player be able to trust?

Read [23 — Accounts/progress/admission](23-accounts-progress-admission.md), [10 — App/commerce/release](10-mobile-commerce-release.md), and [11 — Security/observability/operations](11-security-observability-operations.md).

**Review questions:** Are accounts available at the first free launch without turning installed play always-online? Can accepted offline reports unlock onboarding but not competitive value? Is progress sync distinct from full-save backup? Does offline ownership work as promised? Are save compatibility and recovery explicit? Which release requires purchase infrastructure? Which operational sections belong to later Realm hosting? Store policy and toolchain research must be reverified at their recorded evidence gates, not assumed current because the prose is still here.

### Pass 6 — What gets implemented, and what remains undecided?

Read [16 — Decisions](16-decision-register.md), [14 — Plan](14-implementation-plan.md), [15 — Acceptance scenarios](15-acceptance-scenarios.md), and the owner-approved target [R1 envelope](r1-acceptance-envelope.md). Cross-check using [INDEX](INDEX.md) and the [contract-corpus explanation](conformance/README.md).

**Review questions:** Are the dependencies justified? Does a scenario actually test the claimed invariant? Are approved targets distinguished from actual setup and measurements? Record any missing gate rather than treating a prose example as a test result.

### Pass 7 — Read the supporting evidence last

Read [12 — Evennia](12-evennia-lessons.md), [20 — Classic MUDs](20-classic-mud-lessons.md), [22 — Ink](22-ink-runtime-lessons.md), [13 — Legacy feature inventory](13-lokacore-feature-inventory.md), and [17 — Research baseline](17-research-baseline.md). Consult [18 — Review history](18-review-record.md), [the prior audit follow-through](reviews/2026-09-22-audit-follow-through.md), and [cut candidates](INDEX-cut-candidates.md) for specific questions.

These are dated evidence. Some historical reviews intentionally describe decisions that were later changed. Neither a prior “no blocker” conclusion nor a suggested deletion overrides current contracts.

## The different identifiers

| Label | Meaning | Example |
|---|---|---|
| `00`–`23`, including `00a` | Stable document numbers, not phases. | Document 14 contains the phase plan. |
| `R0`–`R22`, plus `R6P`, `R9C` | Rebuild milestones. | R6P is the early playable proof. |
| `R3A`, `R3B`, `R12A` | Subdivisions, not additional top-level releases. | R3 contracts; R12A launch accounts/progress. |
| `L0`–`L6` | Architectural/authoring layers in document 21. | L0 is authority; L6 is finished content. |
| `ADR-…` | Architecture decisions in document 16. | ADR-018 records LokaScript's deferral. |
| `DET-…`, `OFF-…`, `QST-…`, etc. | Acceptance scenario IDs in document 15. | DET-02 concerns cross-host equivalence. |
| `P1`–`P6` in the R6P work package | Local proof implementation tickets. | These are not the P-prefixed principles in document 01. |
| Chapters 1–3 | Player-facing releases of the Ashmere campaign. | They are not R1/R2/R3. |

Always qualify a short label with its document or family when ambiguity is possible.

## Vocabulary to keep beside you

| Term | Plain meaning |
|---|---|
| Cartridge | An immutable compiled game-content release, not a new app or engine. |
| Capability | A versioned mechanic the engine knows how to execute. Content configures and composes it. |
| Authority / mutation owner | The component allowed to serialize and commit changes for a state domain. |
| ActionInvocation | The player's requested action, before the authority validates it as new work or recognizes a retry. |
| Command | The typed semantic request evaluated by the rules. |
| StateDelta | Proposed same-authority changes that are not yet committed. |
| DomainEvent | A typed fact produced by a decision; externally observable as committed only after commit succeeds. |
| Effect | Work crossing a post-decision boundary, not a backdoor for same-domain state writes. |
| Receipt / idempotency | A durable result and identity that let a repeated request return its prior outcome instead of acting twice. |
| GameView | The semantic player-visible projection; the UI presents it rather than deciding game rules. |
| SceneSequence / InstancePlan | A narrative continuation versus a scoped spatial world; a dream may compose them, but they are not synonyms. |
| Gate / conformance | Required advancement evidence versus agreement with a specified behavior/representation. Neither means “the game is fun.” |

For precise definitions, use [INDEX §3](INDEX.md#3-vocabulary) and its governing references.

## A reading protocol for LLMs

Start with this guide, INDEX, the relevant phase, and release scope. Load the governing sections for the specific task plus their acceptance cases; do not use a compact summary instead of the contract. Retrieve dependency sections when state ownership, retries, time, scope, or capabilities cross a boundary.

Keep four things separate in findings: **observed text**, **inferred risk**, **proposed change**, and **evidence needed**. Cite file/section and the exact revision. Do not turn a historical example, future feature, or source-shaped YAML illustration into an already-frozen schema. Do not mark model tests as device or database evidence. Do not call a second pass by the same assistant independent review.

## Two concrete content questions to resolve

| Source | What disagrees | Decision needed |
|---|---|---|
| [00 §5](00-first-cartridge-design.md#5-quest-list) and [§7](00-first-cartridge-design.md#7-scope) | Five main quests plus 28 side quests are listed, but the campaign summary says 28 quests total. | Reconcile the intended full-campaign inventory/count. Chapter one's ten quests are unchanged. |
| [00a §4](00a-chapter-one-content.md#4-npcs) and [§11](00a-chapter-one-content.md#11-chapter-one-certification) | The 14:00 ambiguity scenario requires both novices in the cloister, but Hale's schedule puts him in the kitchen garden. | Choose the intended NPC schedule or scenario time/location; do not certify the contradictory fixture. |

These are unresolved content findings, not new engine requirements. They are also flagged beside their source text. This presentation sweep is not a claim that all remaining semantic/content contradictions have been found.

## How to record your human review

For each issue, record the source revision; file and heading; the claim or behavior you are questioning; whether it is product intent, ambiguity, contradiction, missing evidence, or presentation; the smallest proposed correction; and the affected gate or decision.

Use **“unresolved”** for questions you have not decided. A review note is not automatically a new requirement. Preserve stable IDs when proposing edits so existing references and acceptance cases remain traceable. The conflict rule is unchanged: conflicting normative statements require reconciliation, not silent precedence.

### Readiness handoff (2026-09-22)

Read [the R1 work package](r1-work-package.md) and ADR-064–067. The R1 numerical/device-class **targets are now owner-approved**, not measured. Actual setup/independent oracle review, R0 acceptance, R1 selection and R2 cutover remain gates. The composition, Lantern intent and run-lifetime amendments live in their existing governing documents, not in the earlier standalone discussion proposal.

For work after merged PR #10, read the [bounded preparation handoff](prep/after-pr-10/README.md)
and [tooling coverage map](spec_tools/README.md). No new milestone or production authorization is implied.

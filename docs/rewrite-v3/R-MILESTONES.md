# R milestones — the rebuild in plain English

**Reading aid, not a new implementation contract.** [Document 14](14-implementation-plan.md) owns the detailed tasks, dependencies, and gates. [Back to the review guide](REVIEW-GUIDE.md).

“R” labels identify rebuild milestones. They do not identify documents, releases, completed work, or mandatory calendar order. This guide contains all **25 named milestones**: R0–R22 plus R6P and R9C. R3A/R3B are parts of R3; R12A is the launch-account subdivision of R12, explained below.

**The intended first chapter remains 57 rooms, 10 quests, and two endings.** The earlier R6P proof is a separate, smaller engineering/player-feedback step on the new engine.

## How to read the roadmap

Follow the foundation to the early proof and full chapter. Then distinguish Story release, authoring automation, and Realm development. R16 is grouped beside Builder work below because it does not wait for R14/R15. That presentation changes neither the phase IDs nor their contracts. A gate describes evidence required to proceed; the existence of its document is not a passing result.

## 1. Agree on the rebuild and prove the technology

| Milestone | In ordinary language | What is built or decided | What it proves |
|---|---|---|---|
| [R0](14-implementation-plan.md#r0--specification-acceptance) | **Accept the specification** | Review the contracts, resolve blocking contradictions, identify deliberately deferred decisions, and accept an exact packet revision. | An accepted contract and cutover manifest, not merely a merged documentation PR. |
| [R1](14-implementation-plan.md#r1--disposable-portable-kernel-feasibility-spike) | **Test the portable-kernel options** | Use a disposable experiment to test the same small rules on mobile and a BEAM host, then test synthetic scale. Compare TypeScript first, Rust if needed, and the dual implementation fallback under the reviewed envelope. | A justified execution/binding decision with reproducible measurements; not the production engine. |
| [R2](14-implementation-plan.md#r2--fresh-repository-foundation) | **Start the new codebase** | Create the fresh repository, dependency boundaries, CI, and minimal mobile integration; import the accepted specification there. | A clean foundation with green build checks and one home for subsequent specification changes. |
| [R3](14-implementation-plan.md#r3--contractschema-foundation) | **Define the shared contracts** | Create machine-readable identities, commands, outcomes, state changes, events, effects, capability envelopes, and player-view contracts. | Generated or checked types and fixtures instead of independently maintained catalogs. |

### R3 has two parts

**[R3A](14-implementation-plan.md#r3a--constitutional-contracts) — Constitutional contracts.** Define the shared identities and meaning of actions, state changes, events, outcomes, scope, determinism, and persistence boundaries. These are the contracts later systems must not reinterpret.

**[R3B](14-implementation-plan.md#r3b--versioned-feature-envelopes) — Versioned feature envelopes.** Reserve typed/versioned registration shapes for later mechanics, but finalize their detailed fields when the implementing feature slice supplies evidence. This is not permission to ship unvalidated maps.

## 2. Build the basic engine and an early playable proof

| Milestone | In ordinary language | What is built or decided | What it proves |
|---|---|---|---|
| [R4](14-implementation-plan.md#r4--cartridge-compiler-v1) | **Compile cartridge content** | Turn authored source into a validated, immutable cartridge with stable references and a deterministic hash. | The same source produces the same artifact; invalid references and capabilities fail clearly. |
| [R5](14-implementation-plan.md#r5--portable-world-rules-foundation) | **Build reusable world rules** | Implement the required world, containment, movement, facts, targeting, policies, actions, time, and randomness primitives. | Known-answer scenarios agree across the selected host paths. |
| [R6](14-implementation-plan.md#r6--offline-authority-and-save-system) | **Make offline play durable** | Add local authority, SQLite, receipts, saves, recovery, and atomic milestone/pending-sync records with host-side account binding. | A tiny world survives airplane-mode play, interrupted actions, app termination, and resume. |
| [R6P](14-implementation-plan.md#r6p--early-fresh-engine-playable-proof) | **Play a small piece of the fresh engine** | Build The Ferryman's Lantern: four places, one quest, a schedule, and a consequential touch-driven choice using selected early R7/R8 slices. | Human-readable, restart-safe device play before the full release. This does not shrink chapter one. |

## 3. Complete chapter-one mechanics and prove the game

| Milestone | In ordinary language | What is built or decided | What it proves |
|---|---|---|---|
| [R7](14-implementation-plan.md#r7--quest-dialogue-and-scenes) | **Add quests, dialogue, and scenes** | Build objective operators, outcome consequences, dialogue choices, durable scenes, and the narrative features the current release actually uses. | Correct quest/scene progression, once-only consequences, and recovery; LokaScript stays deferred. |
| [R8](14-implementation-plan.md#r8--living-world-capability-pack) | **Make the world behave and react** | Implement required schedules, behaviors, populations, reactions, time-derived state, and immediate commerce. Add queued services or later systems only when their release needs them. | Bounded, deterministic world behavior and conservation tests for implemented transactions. |
| [R9](14-implementation-plan.md#r9--cartridge-lab-v1) | **Build the testing laboratory** | Provide controllable time and randomness, reproducible traces, static checks, bots, fault injection, and applicable certification evidence. | The chapter-one minimum gates catch relevant failures and produce reproducible evidence. |
| [R9C](14-implementation-plan.md#r9c--synthetic-v3-conformance-cartridge) | **Keep a synthetic engine test cartridge** | Create deliberately artificial situations that stress already-implemented mechanics and their interactions. | A permanent regression corpus. Passing it does not prove that the real game is enjoyable. |
| [R10](14-implementation-plan.md#r10--first-real-offline-cartridge) | **Build the full first chapter** | Author and certify The Missing Child: 57 rooms, 10 quests, and two endings, while recording real authoring pain. | A complete player-facing chapter with applicable certification and developer-harness device smoke; R12 supplies the polished product shell. |

## 4. Ship Story Mode and improve authoring

| Milestone | In ordinary language | What is built or decided | What it proves |
|---|---|---|---|
| [R11](14-implementation-plan.md#r11--builder-api-v1-and-script-surface-generalization) | **Build the typed authoring tools** | Generalize demonstrated authoring operations into the Builder API, CLI/terminal/MCP adapters, capability discovery, and safe review/escalation surfaces. | Humans or agents can author representative content and fix validation problems through the API rather than editing engine source. |
| [R12](14-implementation-plan.md#r12--loka-app-production-story-mode) | **Finish the player-facing app** | Polish Story UI and offline saves; include R12A accounts, recovery/deletion and completion sync in the first public release. | A non-developer plays/resumes offline, then synchronizes completion to the account; outages never block installed Story play. |
| [R13](14-implementation-plan.md#r13--commerce-and-entitlement) | **Enable paid ownership and restoration** | Extend the R12A account/platform foundation with purchases, entitlements, offline grants, download integrity, restore and refunds. | Real store-sandbox purchase/restore evidence before paid releases; not a prerequisite for R6P. |
| [R16](14-implementation-plan.md#r16--repeatable-ai-factory) | **Prove repeatable AI-assisted production** | Combine Builder and Lab workflows with context retrieval, semantic review, corrections, and packaging. Use later Ashmere chapters plus a small unrelated cartridge to test growth and reuse. | Measured repeatability without hidden engine changes. LLM assistance is allowed earlier; production Realm is not a prerequisite. |

## 5. Add Realm hosting, cooperation, and a shared world

| Milestone | In ordinary language | What is built or decided | What it proves |
|---|---|---|---|
| [R14](14-implementation-plan.md#r14--beam-online-authority--realm-mode-skeleton) | **Build online authority** | Host rules under BEAM with transactional storage/protocol/recovery; enforce account prologue requirements at Realm admission. | Online/offline semantic agreement for portable content and recovery at real server commit boundaries. |
| [R15](14-implementation-plan.md#r15--online-private-deployment) | **Offer private online adventures** | Make an individually hosted, cloud-authoritative cartridge available from the same app, with online saves and account links. | The same portable adventure can be offered locally or online without confusing their authorities. |
| [R17](14-implementation-plan.md#r17--partyco-op-instances) | **Add party/cooperative adventures** | Define party progress, membership changes, rewards, loot, shared decisions, and concurrent interactions. | Party-specific race, reconnect, scope, and fault tests pass. |
| [R18](14-implementation-plan.md#r18--realm-mode-persistent-social-shell) | **Create a persistent social hub** | Add a single shared-hub authority, presence/social features, personal overlays, and shared-service contention. | Players coexist without leaking private state or allocating the same scarce slot twice; generalized sharding is not yet required. |
| [R19](14-implementation-plan.md#r19--instanced-story-regions-in-world-geography) | **Connect adventures to world geography** | Let a player or party enter a private story region from a shared-world entrance and return safely. | Recoverable handoff, admission, return state, and instance lifecycle using the existing InstancePlan semantics. |
| [R20](14-implementation-plan.md#r20--shared-zoneshard-architecture) | **Partition the shared world** | Introduce multiple explicit ownership domains with routing, fencing, backpressure, and recoverable cross-shard handoff. | Load/fault tests demonstrate safe ownership changes and retries that still find their original receipt after movement. |
| [R21](14-implementation-plan.md#r21--shared-area-promotion) | **Promote a suitable cartridge into a shared area** | Adapt prior content with shared/personal quest policies, respawn, economy, and abuse constraints rather than simply changing a mode flag. | A shared_area certificate for the actual adapted deployment. |
| [R22](14-implementation-plan.md#r22--persistent-text-mmorpg-expansion) | **Expand the persistent multiplayer game** | Add separately specified and certified systems such as guilds, housing, markets, factions, and live operations after the shared-world foundation is proved. | Feature-by-feature evidence, not permission to prebuild the entire future MMORPG. |

## Distinctions worth keeping in view

**R1 vs. R6P vs. R10:** a technology experiment, an early playable proof, and the full chapter. They answer different questions.

**R9 vs. R9C:** the Lab is the test environment; the conformance cartridge is content designed to exercise it and the engine.

**R10 vs. R12 vs. R13:** the full game content, the polished app, and paid-purchase infrastructure. The free release needs R10/R12 plus applicable release gates; paid releases also need R13.

**R11 vs. R16:** safe authoring tools versus repeatable automated production through those tools. Neither makes an LLM the gameplay or certification authority.

**R14/R15 vs. R17/R18:** online hosting is not the same as cooperative play or a persistent shared social space.

**R19 vs. R20 vs. R21:** geographic entry into private adventures, multi-owner world partitioning, and adapting content for shared-world use.

For a full human review, continue with [REVIEW-GUIDE.md](REVIEW-GUIDE.md). For actual implementation, return to the linked phase and its governing contracts rather than implementing from this summary alone.

## R12A: accounts exist at public Story launch

**[R12A](14-implementation-plan.md#r12a--launch-accounts-and-story-progress) — Launch accounts and Story progress.** This subdivision can begin in parallel with local-engine/content work. It provides registration/sign-in, recovery/deletion, real platform storage and authenticated milestone acceptance/readback before the first free public release. R6P uses a fake adapter; R13 adds purchases later. [Document 23](23-accounts-progress-admission.md) distinguishes client-reported onboarding completion from verified play or competitive rewards. Optional guest-first UX and optional full-save backup do not make launch account support optional.

### Readiness handoff (2026-09-22)

Read [the R1 work package](r1-work-package.md) and ADR-064–067. The R1 numerical/device-class **targets are now owner-approved**, not measured. Actual setup/independent oracle review, R0 acceptance, R1 selection and R2 cutover remain gates. The composition, Lantern intent and run-lifetime amendments live in their existing governing documents, not in the earlier standalone discussion proposal.

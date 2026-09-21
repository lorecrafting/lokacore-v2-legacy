# Loka v3 Specification Review Record

**Scope:** `docs/rewrite-v3/` plus the v3 reconciliation of `docs/product/CARTRIDGE-ROADMAP.md`  
**Review state:** self-review and adversarial architecture review performed before opening the stacked specification PR.

This file records important challenges raised against the draft and the resulting corrections. It is evidence about the specification process, not a substitute for the normative contracts.

## 1. Rewrite versus port ambiguity

**Finding:** Early inventory wording used “porting disposition,” which could instruct an implementation agent to migrate Lokacore module-by-module.

**Risk:** legacy APIs, compatibility layers, process topology, and architectural debt survive into the supposedly clean system.

**Resolution:** corrected throughout.

The specification now requires:

- a clean-sheet v3 implementation;
- no old modules/APIs/shims/process topology carried forward merely for speed;
- Lokacore used only as requirements/evidence/reference material;
- optional future one-way content translation into v3-native schemas.

## 2. Offline requirement contradicted original server-authoritative roadmap

**Finding:** The first roadmap assumed even single-player cartridges ran on the Phoenix server.

**Risk:** no true offline play; single-player product tied to cloud uptime; later attempt to add offline mode would require a second rules implementation.

**Resolution:** architecture changed to two authority hosts over shared portable semantics:

- offline: local serialized authority + SQLite;
- online: BEAM/OTP authority + PostgreSQL.

The product roadmap was rewritten to match.

## 3. Shared kernel could undermine the BEAM-native goal

**Finding:** Moving too much into a portable Rust kernel could accidentally turn Elixir into a thin web wrapper.

**Risk:** lose OTP supervision/process/message-passing advantages and increase FFI complexity.

**Resolution:** kernel boundary is deliberately narrow.

Portable kernel owns deterministic mechanics required by both offline and online play. BEAM owns online:

- sessions;
- WorldInstance/ZoneShard authority;
- supervision;
- networking;
- scheduling coordination;
- persistence transactions;
- outbox workers;
- backpressure;
- observability;
- future distributed topology.

ADR-033 records this constraint.

## 4. Rust/mobile bridge maturity was overstated

**Finding:** Rustler is mature on BEAM, but current Rust→React Native tooling varies in maturity; one prominent generator currently warns against production use.

**Risk:** lock the rebuild to fragile mobile tooling before testing Expo/EAS release ergonomics.

**Resolution:**

- Rust is provisional;
- mobile binding strategy is provisional;
- R1 is a disposable feasibility spike;
- compare at least stable C ABI/platform wrappers and TurboModule/JSI approaches;
- do not make a third-party generator an architectural dependency without evidence.

Fallback remains dual Elixir/TypeScript implementations with mandatory golden conformance, if the shared-kernel approach fails the spike.

## 5. “Same seed” was not a complete determinism contract

**Finding:** Cross-host replay can still diverge through map iteration, ID generation, sorting, floating-point boundaries, or host entropy.

**Risk:** offline and online versions of the same cartridge subtly behave differently.

**Resolution:** normative determinism now covers:

- canonical collection ordering;
- canonical serialization;
- fixed/versioned RNG;
- deterministic ID source;
- stable tie-breaks;
- integer/fixed-point rule-critical arithmetic where host floating point could alter outcomes.

Acceptance scenarios DET-06 onward test these boundaries.

## 6. Native kernel state could become a hidden second authority

**Finding:** A long-lived mutable native state handle could advance before PostgreSQL/SQLite commit.

**Risk:** database and in-memory game state disagree after commit failure or crash.

**Resolution:** the spec defines a proposal/commit protocol:

```text
decide against committed state
  → StateDelta/events/effects
  → host transaction commits
  → only then apply committed delta in memory
```

If post-commit in-memory application fails, reload from durable committed state.

R1 must benchmark several state-crossing strategies instead of assuming a hidden mutable NIF resource.

## 7. Cartridge expansion/composition was underspecified

**Finding:** Campaign chapters and future MMO mounts could otherwise start reaching into each other's internal keys.

**Risk:** global namespace coupling and cartridges that cannot evolve independently.

**Resolution:** added explicit cartridge ports/extension points:

- exported entries/exits;
- continuity exports/imports;
- typed extension points;
- campaign/deployment mount bindings.

Unexported internals remain private.

## 8. Single-player sequel continuity could become accidental MMO state

**Finding:** “Reuse cartridges later” did not specify which state is allowed to survive between offline chapters.

**Risk:** arbitrary internal state coupling or later temptation to import offline gold/items into the MMO.

**Resolution:** introduced explicit continuity classes:

- cartridge-local state;
- campaign-character state;
- campaign-memory state;
- optional account memory;
- online realm/MMO state.

Offline campaign economy/power never becomes authoritative realm state.

## 9. App Store treatment of downloadable scripts was too optimistic

**Finding:** Calling downloaded rules “bytecode” does not make them automatically compatible with current Apple downloadable-code rules.

**Risk:** architecture works technically but creates avoidable review risk.

**Resolution:**

- downloadable LokaScript IR must be bounded/typed and limited to capabilities already shipped in the app;
- no downloaded native/JS modules per cartridge;
- dedicated App Review position spike before first submission;
- if necessary, restrict the representation further into a declarative rule graph.

The product requirement for downloadable offline storypacks remains; the representation is a release gate.

## 10. General Builder API was scheduled before proving a real game

**Finding:** The original implementation graph built the generalized Builder API before the first real cartridge.

**Risk:** repeat the historical pattern of building a world-building platform before discovering what a shippable story actually needs.

**Resolution:** reordered milestones:

- R9 Cartridge Lab;
- R10 first real offline cartridge, substantially handcrafted;
- R11 generalized Builder API derived from observed authoring pain;
- R16 factory automation later.

## 11. Event terminology was overloaded in Lokacore

**Finding:** Lokacore has structured `Loka.Engine.Event` plus tuple events returned to transports.

**Risk:** the clean rebuild accidentally recreates one generic “event” bucket.

**Resolution:** v3 separates:

- Command;
- DomainEvent;
- Effect;
- ClientMessage.

Each has its own schema and responsibility.

## 12. Definition and runtime entity were conflated historically

**Finding:** Lokacore stores prototypes and runtime instances through the same broad entity abstraction/table/API.

**Risk:** cartridge namespaces/version pinning and runtime mutation become difficult to reason about.

**Resolution:** immutable DefinitionRef and mutable RuntimeEntity are separate concepts with separate lifecycles.

## 13. One-process-per-entity was not justified by the new product

**Finding:** Lokacore's EntityServer model creates many cross-authority operations.

**Risk:** item transfers, quest updates, and multi-entity actions need coordination across many actors and durable writes.

**Resolution:** processes represent concurrency ownership domains:

- private/party WorldInstance;
- later shared ZoneShard;
- Session;
- schedulers/workers.

Entities are data unless they genuinely require independent concurrent ownership.

## 14. Temporal features could create timer/tick explosions

**Finding:** MUD worlds invite schedules, plants, cooldowns, shops, weather, respawns, and ambient events.

**Risk:** one timer/tick process per object creates unnecessary load and hard-to-replay behavior.

**Resolution:** four temporal strategies:

- derived/on-demand state;
- durable scheduled jobs;
- ephemeral cadence;
- world/shard simulation scheduling.

This incorporates a particularly useful lesson from Evennia's OnDemandHandler.

## 15. Private story → MMORPG reuse needed more than a single “shared” switch

**Finding:** many intimate narratives are not semantically valid when all players share one copy of every NPC/quest.

**Risk:** forced shared-state conversion ruins the story or creates quest races.

**Resolution:** three reuse modes:

1. adventure portal to private/party instance;
2. geographically embedded private/party instance;
3. selected shared-area promotion with a separately certified deployment overlay.

Shared promotion is optional.

## 16. Mobile/server protocol drift must not recur

**Finding:** current RN client/server disagree on join parameters, event names, and view-model shapes.

**Risk:** two independently maintained contracts drift again.

**Resolution:** one language-neutral machine-readable online protocol source generates/checks Elixir and TypeScript contracts and fixtures.

Portable kernel commands have their own host-neutral conformance schema.

## 17. CI and documentation authority

**Finding:** Lokacore has overlapping CI and stale architecture/builder docs.

**Risk:** implementation agents trust conflicting historical sources.

**Resolution:**

- one coherent CI in v3;
- schema/registry generated or checked documentation;
- accepted spec + decision register govern architecture;
- historical Lokacore docs stay reference-only.

## 18. Review conclusion

No finding currently requires abandoning the clean-rebuild strategy.

The highest-risk unresolved decision is the **shared portable kernel technology/binding strategy**. It remains intentionally provisional and is the first implementation evidence gate (R1).

The second important release risk is **App Store treatment of downloaded rule content**; the architecture has been constrained to minimize that risk, but current review policy must be tested/reverified before commercial submission.

The specification should not be considered implementation-final until this PR itself receives external/adversarial review and any resulting corrections.


## 19. Self-review corrections after PR opening

A fresh PR self-review found:

- stale pre-v3 manifest fields still present in the roadmap;
- no explicit portable GameView/projection contract for offline versus online;
- deterministic gameplay IDs required but underspecified;
- R10 mobile smoke wording depended on the later polished R12 shell;
- overly broad “portable bytecode” wording.

Corrections:

- roadmap manifest aligned to v3 kernel/capability profiles;
- host-neutral GameView projection added so React Native does not reimplement game visibility/action rules;
- deterministic gameplay IDs now come from an explicit deterministic IdSource;
- R10 uses a developer mobile harness, R12 owns polished product-shell acceptance;
- downloadable rules are described as bounded portable rule IR.

## 20. Adversarial review after self-review

The next pass assumed long-lived commercial offline saves, automatic app updates, real command retries, signing-key rotation, and later MMO concurrency.

Findings and corrections:

1. **Old saves versus app auto-update** — added explicit kernel/rule-IR/content-schema compatibility matrix, local migrations/rollback, and acceptance scenarios.
2. **Command receipts could not actually replay a response** — receipt now stores committed revision plus response payload/reference, not only a digest.
3. **Commerce/account logic had no domain home** — introduced `loka_platform`; `loka_web` remains adapter-only.
4. **Artifact signing had no key-rotation contract** — added signing key IDs/trust-set rotation/revocation semantics.
5. **General scripting was too front-loaded** — R7 now builds only the interpreter core/minimal bindings needed to prove containment and the first cartridge; R11 generalizes from observed authoring needs.
6. **Portable projection could drift** — corrected during self-review and now covered as a host-neutral GameView.
7. **Cartridge/app compatibility is now part of certification**, not a support afterthought.

No adversarial finding currently requires abandoning the clean-sheet/offline-first architecture. The shared-kernel decision remains the primary R1 evidence gate.


## 21. Product-boundary interruption: separate Stories and Online clients

During adversarial review, the product boundary was challenged again: offline single-player and persistent multiplayer have sufficiently different trust, release, UX, and state requirements that one client risks becoming condition-heavy.

Decision:

- **Loka Stories** is a separate offline-first cartridge/campaign app;
- **Loka Online** is a separate online-only multiplayer/MUD app;
- both live in one monorepo and share UI/GameView/schema packages where valuable;
- the Online client does not become a local simulation authority;
- the Stories client does not carry realm/social/shard responsibilities.

The Builder API now has explicit `story`, `realm`, and `promote` targets.

This reduces architecture coupling at the cost of two app-store/release tracks and a deliberate cross-client entitlement/account policy. The latter is intentionally not assumed to be automatic.


## 22. Review round two: revisit the two-client decision

After PR #4 merged, the client split was challenged again from a maintenance/product perspective.

### Finding

Two separate store apps preserved authority separation, but duplicated:

- store listings/review tracks;
- release/version management;
- navigation/onboarding;
- design/accessibility shell;
- account/catalog/purchase/restore UX;
- analytics/support surface;
- installed-user migration path when Realm launches.

The authority problem did not actually require two binaries.

### Revised decision

Use **one Loka app with two strict gameplay session modes**:

- `LocalStorySession` — local kernel + SQLite;
- `RemoteRealmSession` — Phoenix/BEAM.

The common renderer consumes host-neutral GameViews. Exactly one session authority is active at a time. Realm never accepts local simulation as authority.

The mobile codebase keeps separate Story and Realm feature/authority modules so “one app” does not become pervasive `if online?` conditionals.

### Why this is simpler

- one store presence and installed user base;
- one design/accessibility/localization system;
- one cartridge/account/catalog experience;
- Realm can arrive later as an app update;
- no cross-app entitlement problem;
- Story cartridges can open online adventures/Realm portals without deep-linking to another product.

### New cost

Online development cadence can force more frequent app updates, so offline save/kernel/rule-IR backward compatibility becomes even more important. The existing compatibility contract already treats this as a release invariant.

### Builder decision retained

`story`, `realm`, and `promote` remain distinct Builder targets because they represent authority/trust/certification semantics, not clients.

## 23. Review round two: master-plan clarity

The packet has grown large enough that an implementation model could confuse research/history with requirements.

Correction: the packet index now explicitly labels:

- normative architecture;
- normative sequencing/acceptance gates;
- informative/reference evidence.

A disagreement between normative documents is itself a spec defect and blocks implementation until reconciled; there is no implicit “pick the newest paragraph” rule.

Certification is now explicitly target-driven:

- Story workspaces select portable/offline/save-compatibility gates;
- Realm workspaces select online/concurrency/security/load gates;
- Promote workspaces retain the immutable Story artifact and add explicit multiplayer adaptation plus Realm certification.


## 24. Review round two: quests as living-world participants

The master-plan review revisited how quests should create immersive, persistent world change.

### Problem

A traditional quest engine can become a second scripting/mutation authority:

- objective completes;
- quest script edits a door;
- separately rewrites an NPC;
- separately changes dialogue;
- separately spawns actors;
- separately flips arbitrary flags.

This is brittle, hard to replay, and encourages world systems to depend on quest implementation details.

### Revised contract

Quests now follow:

```text
world DomainEvents
  → QuestReducer
  → named quest outcome
  → typed capability consequences
  → combined StateDelta/DomainEvents/Effects
  → authority commit
  → reactive world rules
```

Typed scoped **Facts** coordinate broad narrative truths across systems.

Example:

`village.child_status = rescued`

can drive schedules, dialogue, ambience, access, follow-up quests, and descriptions without the quest directly rewriting each subsystem.

Direct consequence operators remain available for mechanical actions such as opening a gate or spawning an encounter.

### Scope safety

Quest scope does not automatically authorize world scope.

Player-scoped Story/Realm progression cannot silently mutate Realm-global state. Broader consequences require explicit scope and matching certification.

### Builder/Lab implications

Builder gains consequence/fact/reference/impact tools.

The Lab must fork quest branches, compare world state, and simulate forward after outcomes.

The first real cartridge is now required to prove at least:

- a quest-gated area/access change;
- an NPC state/schedule/dialogue reaction;
- an ambient/environmental reaction;
- branch comparison and forward simulation.

This turns “living and breathing” from an aspiration into an architecture and certification requirement.


## 25. Review round two: quest tracking, phasing, instancing, and bottlenecks

The review then challenged a common MMORPG ambiguity: whether a quest is simply “instanced” or “shared.”

That binary is insufficient.

The architecture now separates five independent dimensions:

- progress scope;
- consequence scope;
- presence/audience;
- spatial placement;
- capacity scope.

This permits, for example:

- player-scoped quest progress;
- one shared blacksmith NPC;
- one shared service queue for a scarce world service;
- a private apparition visible only to the questing player;
- a private party dungeon later in the same quest.

A dedicated normative specification now defines these combinations.

### Scarce-service bottleneck

The one-sword-per-day smithy is only a worked example. The architecture uses generic Service/Capacity/Reservation/ServiceJob primitives that can also model ferries, healers, trainers, ritual altars, inns, processors, and other scarce services.

The quest observes work-order completion; it does not own the overnight timer or queue.

Inputs can be escrowed, allocation is atomic, capacity is inspectable, and Realm fairness/retry semantics can be certified.

### Phasing

Personal quest actors use scoped AudiencePolicy/overlay presence under the shared ZoneShard rather than requiring whole-zone instancing.

Shared NPCs remain shared when only dialogue/relationship differs.

Full private instances are reserved for incompatible physical simulations such as destructive branches, exclusive bosses, puzzle resets, or heavily private scripted sequences.


## 26. Draft 0.3 spec-integrity audit of the complete merged packet

**Baseline:** `main@33c32e8d77e68dd3c5ab6eba9547f8588208063f` after PR #5.  
**Scope:** all normative v3 documents, implementation/acceptance gates, decision register, informative architecture evidence where it could contradict the normative packet, and `docs/product/CARTRIDGE-ROADMAP.md`.

This pass treated the packet as a clean-room implementation contract rather than a prose review. It looked specifically for places where a future implementation agent could make two different reasonable interpretations and still believe it had followed the spec.

### 26.1 Canonical gameplay pipeline was present conceptually but not stated once

**Finding:** Individual documents described touch actions, text parsing, Commands, decisions, Effects, persistence, and GameView, but not one canonical end-to-end pipeline. The quest/action document still allowed text parsing to appear to construct a Command directly.

**Risk:** touch, text, bots, and Realm transport acquire subtly different authority/security semantics.

**Correction:** the packet index now states one semantic spine:

```text
input
  -> ActionInvocation
  -> authority re-resolution/revalidation
  -> semantic Command
  -> decision
  -> StateDelta + DomainEvents + Effects
  -> authoritative commit/receipt/outbox
  -> GameView
```

Text and gameplay bots now cross the same ActionInvocation boundary as touch clients. StateDelta is first-class and Effects are explicitly not a second state-write path.

### 26.2 Authority, scope, audience, capacity, and placement were overloaded

**Finding:** “authority,” “scope,” “service owner,” and client revision terminology could be read as aliases.

**Risk:** a player-scoped quest could accidentally imply player-owned mutation state; a service aggregate could acquire an unnecessary GenServer; a client projection revision could be coupled to a busy ZoneShard database revision.

**Correction:** the packet now distinguishes:

- authority host;
- mutation owner;
- durable store;
- semantic StateScope;
- AudiencePolicy;
- capacity scope/owner;
- service aggregate/provider;
- authority revision;
- projection sequence;
- opaque view-freshness token.

StateScope is independent from process/table placement, audience, instancing, and contention policy.

### 26.3 Idempotency did not fully survive reconnect or payload mismatch

**Finding:** earlier examples mixed session identity into Command context and required stable IDs, but did not explicitly forbid ephemeral session identity from semantic idempotency. They also did not define what happens if an ID is reused with a different payload.

**Risk:** a lost acknowledgement followed by reconnect can duplicate a state change, or an accidental/malicious ID collision can return the wrong prior response.

**Correction:** semantic Command identity derives from durable/trusted authority context + controlled actor + invocation identity, never ephemeral session identity. Receipts store a semantic-command digest and replayable prior response/reference.

- same identity + same digest -> replay prior committed result with no mutation;
- same identity + different digest -> integrity/idempotency conflict.

The transaction pseudocode now has an explicit early duplicate-replay path rather than “match and continue.”

Builder mutations and atomic batch plans receive the same retry discipline.

### 26.4 Online stale-owner protection needed fencing, not revisions alone

**Finding:** optimistic state revision checks do not prevent a previously valid process from writing again after ownership has moved if its state revision still appears current.

**Risk:** split-brain/failover corruption in the future shared Realm.

**Correction:** any authority domain whose ownership may move requires an ownership/fencing generation or equivalently strong token at persistence commit. R20 explicitly owns the generalized multi-zone placement/fencing/handoff proof.

### 26.5 Client projection ordering was incorrectly close to world revisioning

**Finding:** the mobile protocol could be implemented as though every WorldInstance/ZoneShard revision maps 1:1 to one client's projection delta.

**Risk:** false gap detection in busy shared zones, or hidden coupling between persistence and transport.

**Correction:** three separate concepts are now normative:

- authority revision: persistence/concurrency;
- projection sequence: ordering for one client/subscription stream;
- view-freshness token: stale-interaction evidence.

They may correlate for diagnostics but are not required to be equal.

### 26.6 Quest activation, availability, visibility, and history needed sharper boundaries

**Findings:**

- `hidden` had been mixed into activation modes even though it is a journal/presentation concern;
- automatic/discovered quests need to react before a QuestInstance exists;
- prerequisites after activation had no explicit sustain semantics;
- pre-activation events could be interpreted as retroactive objective credit;
- older roadmap/reference prose still showed the historical Lokacore lifecycle as though it were v3.

**Corrections:**

- activation is `offered | automatic | discovered`;
- journal visibility/reveal is a separate axis;
- activation indexes definitions separately from active QuestInstance event subscriptions;
- prerequisites are revalidated at activation but do not silently deactivate an active quest;
- event-observation objectives are post-activation by default;
- “already have/know/current fact” uses explicit current-state predicates or declared history semantics;
- the roadmap now labels the old lifecycle as historical and restates the v3 `active -> objectives_complete -> resolved(outcome_id)` model.

### 26.7 Real-elapsed offline time had an implicit side channel

**Finding:** “compare wall clock on resume” was directionally correct but did not specify crash/retry identity or hybrid-system clock choice.

**Risk:** overnight jobs/deadlines can advance twice after an app crash, or portable systems read different clocks on different hosts.

**Correction:** accepted real-elapsed time becomes an explicit idempotent resume-time advancement input processed through normal decision/commit semantics. Hybrid systems declare a named time basis; game rules do not read wall clock directly.

### 26.8 Scarce services needed authority-aware escrow and precise time windows

**Findings:**

- the smithy example risked turning one illustrative bottleneck into a special subsystem;
- “service owner” could imply one process per service;
- “allocation + escrow + job creation in one transaction” is only true when all state shares one mutation authority;
- “one per day” was underspecified.

**Corrections:**

- Service/Capacity/Reservation/ServiceJob remains generic and composable;
- a service is a domain aggregate, not automatically an OTP process;
- same-authority allocation + escrow + job creation is atomic;
- cross-authority custody uses a durable idempotent reservation/transfer/proof/cancellation/reconciliation protocol;
- period/window policies declare time basis, rolling/fixed/calendar semantics, and anchors where needed;
- new acceptance scenarios cover both custody recovery and period-boundary behavior.

### 26.9 Artifact identity and signing had a potential self-reference cycle

**Finding:** the artifact layout included certificate reference/signature metadata while also describing the cartridge hash as covering the artifact.

**Risk:** certification/signing changes the hash it is supposed to attest.

**Correction:** the packet now separates:

- semantic cartridge/deployment hash — normalized game semantics + compatibility locks;
- certificate/signature/release envelope — attests the semantic hash;
- optional package/transport hash — exact downloadable archive bytes.

A published `cartridge_id@version` cannot later be rebound to a different semantic hash.

### 26.10 Download/install parsing needed explicit hostile-input treatment

**Finding:** signed/hash-addressed content alone does not protect against archive traversal, decompression bombs, duplicate-path ambiguity, or pathological allocations.

**Correction:** cartridge ingestion now requires bounded extraction/allocation, normalized paths, duplicate-path rules, media/type validation where relevant, and atomic staging-before-activation even for signed first-party packages.

### 26.11 LokaScript wall-time timeout conflicted with cross-host determinism

**Finding:** the script budget listed wall execution time beside deterministic AST/query/effect budgets.

**Risk:** the same valid cartridge can “fail normally” on a slower phone while succeeding on a server.

**Correction:** deterministic step/resource budgets define script semantics. A host wall-time kill switch remains defense in depth only; firing it on certified supported input is a runtime/conformance failure, not a cartridge-visible branch.

Mutation bindings were also renamed away from `effect.spawn/move/damage/...` so the scripting surface does not reintroduce Effect as a generic mutation bucket.

### 26.12 The Rust hypothesis leaked into permanent requirements

**Finding:** several conformance/certificate/CI passages still hard-coded Rust/Rustler/iOS/Android even though ADR-004/005 are provisional.

**Risk:** R1 could “reject Rust” on paper while later gates still require it.

**Correction:** permanent requirements now describe the portable semantic/conformance obligation first. Rust/Rustler/native bindings become the concrete host matrix only if R1 accepts the shared-Rust strategy. The dual-implementation fallback has the same golden-conformance obligation.

### 26.13 The product roadmap drifted from normative sequencing

**Findings:**

- roadmap immediate order generalized Builder API before the first real cartridge, contradicting the reviewed R10 -> R11 strategy;
- roadmap vocabulary invented `persistent_world` as though it were another execution profile;
- old quest lifecycle wording survived;
- R18 appeared to use shared-zone architecture before R20 introduced shard architecture.

**Corrections:**

- substantially hand-author/certify the first real cartridge before generalizing Builder API;
- runtime profiles remain `offline_private | online_private | party | shared_area`; embedded instances/persistent world are compositions/topologies, not silent extra profiles;
- quest vocabulary is reconciled;
- R18 now proves one single-node shared-hub authority; R20 generalizes to multiple ownership domains, placement/routing, fencing, and cross-zone handoff.

### 26.14 Semantic AI review needed an evidence model rather than pretend determinism

**Finding:** exact-hash certification included semantic model review without distinguishing deterministic gates from stochastic reviewer output.

**Risk:** “reproducible certificate” could incorrectly mean re-running a future model must produce the same prose/verdict.

**Correction:** semantic review is auditable evidence after deterministic gates. The certificate retains reviewer/model identity where applicable, rubric/prompt policy revision, evidence-bundle hash, findings/output hash, and blocker/waiver disposition. Models do not publish, waive, or mutate content by themselves.

### 26.15 Decision register now records the newly important invariants

The accepted register was updated to make the following explicit rather than leaving them scattered in prose:

- ActionInvocation / Command / StateDelta / DomainEvent / Effect / GameView separation;
- session-independent idempotency;
- StateScope independent from physical placement;
- projection sequencing independent from authority revision;
- stale-owner fencing once ownership may move;
- idempotent real-elapsed Story resume inputs;
- semantic artifact hash separated from attestation/package envelopes;
- deterministic script budgets versus host safety timeout;
- same-authority versus cross-authority scarce-service transactions.

A checkpoint map also identifies which provisional/deferred ADRs actually block which future milestones.

### 26.16 External assumption recheck

The portability/release assumptions were rechecked against current official material during this pass. The result did not justify reversing R1:

- Expo development builds continue to support custom native code;
- React Native continues to document cross-platform native/C++ module paths;
- Rustler remains a viable BEAM/Rust bridge with scheduler constraints that the spike must measure;
- downloadable rule/software treatment remains a current App Store review question, so the packet correctly keeps bounded rule representation/store review as an evidence gate rather than assuming approval.

The stable architecture therefore remains abstraction-first and avoids selecting a production binding generator in the specification.

### 26.17 Remaining deliberate open gates

This audit does **not** paper over questions that require implementation or release evidence:

1. **R1 / ADR-004/005:** shared Rust kernel versus the accepted dual-implementation fallback, including mobile bridge maintenance, FFI/state-crossing cost, debugging, determinism, and Expo/EAS release ergonomics.
2. **ADR-035 / commercial release:** exact downloadable rule representation and current App Store review posture.
3. **R20:** long-lived cross-zone placement/routing for player/party state once the Realm is genuinely partitioned; StateScope alone intentionally does not decide this.
4. **Product policy details:** monetization/pricing, revocation UX, and later creator-marketplace policy remain product/release decisions rather than engine invariants.

### 26.18 Audit conclusion

The packet does not need a wholesale architectural rewrite.

Its core direction remains coherent:

- clean-sheet implementation;
- offline-first Story authority;
- BEAM-native Realm authority;
- a narrow portable deterministic semantic layer;
- explicit state scopes and ownership domains;
- immutable certified cartridges/deployments;
- facts/consequences instead of quest puppeteering;
- shared-world overlays before unnecessary instancing;
- reusable service/capacity primitives instead of feature-specific bottleneck code;
- prove a real game before over-generalizing authoring/factory tooling.

The Draft 0.3 branch tightens the places where a competent implementation agent could previously choose materially different semantics. It should receive an independent high-reasoning adversarial pass before R0 acceptance.


## 27. Classic MUD / builder-expression / narrative-depth review

### 27.1 Why this pass was run

After the Draft 0.3 integrity audit, the remaining question was not whether Loka needed another authority-model rewrite. It was whether the **middle layer between low-level engine semantics and finished story content** was expressive enough to build a dense, living MUD without falling back to arbitrary scripting.

A focused design archaeology pass reviewed preserved DikuMUD/TinyMUD source plus CircleMUD builder conventions.

### 27.2 Finding: v3 execution contracts were stronger than the classic engines, but world-composition grammar was under-specified

The classic systems repeatedly derive useful expressivity from:

- prototype/instance separation;
- explicit spatial/containment relations;
- target matching/search scopes;
- compact locks/policies;
- data-driven shops/socials;
- small orthogonal NPC behavior;
- declarative area population/reset recipes;
- highly semantic builder operations;
- special procedures as a local behavior escape hatch.

V3 already had better authority, determinism, scoping, packaging, testing, and portability boundaries, so none of the classic storage/loop architecture was adopted.

Instead the pass added an explicit layered composition model.

### 27.3 Correction: closed semantics, open composition

Document 21 now makes the builder-expression boundary normative.

The stack is:

~~~text
authority/transactions
 -> world model contracts
 -> semantic capabilities
 -> composition grammar
 -> domain composites
 -> narrative/world orchestration
 -> cartridges/campaigns/deployments
~~~

Builders normally operate in the upper layers and may create custom facts/events, policies/selectors, Actions/ActionRecipes, ReactionRules, state machines, Behaviors, population plans, commerce/services, scenes, quests, world events, templates, and bounded scripts.

They cannot introduce hidden persistence or authority semantics.

### 27.4 Correction: safe descendants of TinyMUD/Diku patterns

The packet now explicitly defines/adopts the direction for:

- deterministic TargetResolution rather than arbitrary/first/random match;
- InspectableDetail for rich environmental detail without entity inflation;
- one coherent Barrier state for one logical door/gate;
- SpawnBundle + provenance-safe PopulationPlan instead of destructive zone reset;
- ReactionRule instead of arbitrary special-procedure callbacks;
- deterministic Behavior intent arbitration rather than source-order behavior;
- AreaDefinition separate from ZoneShard ownership placement;
- audience-aware NarrationSpec;
- typed commerce/merchant composition.

### 27.5 Correction: builders can invent new verbs safely

A major adversarial question was whether builders could create actions such as “ring bell,” “pray,” “search rubble,” or “offer incense” without either:

1. asking for a new compiled engine command; or
2. hiding behavior in a script.

The answer is now **ActionRecipe / ComposedAction**.

An immutable compiled recipe combines TargetSpec, Policy, costs, optional Check/result bands, typed consequences/events, and NarrationSpec inside one normal authority decision.

Asynchronous multi-step behavior is intentionally not smuggled into ActionRecipe; SceneSequence/ServiceJob/state-machine primitives own durable continuation.

### 27.6 Correction: quest becomes the narrative spine without becoming world authority

Quest architecture was expanded substantially.

Quests may now coordinate:

- stages/milestones;
- SceneSequences;
- text cutscenes;
- dreams/visions/private scenes;
- scripted world events;
- dialogue;
- services;
- population/world reactions;
- world-state mutation through typed consequences;
- named branch outcomes and follow-up content.

SceneDefinition/SceneInstance provides durable, idempotent narrative orchestration with crash/reconnect recovery, authority-enforced control modes, choices, checkpoints, scene-space semantics, and typed consequence export.

WorldEventPlan composes multi-phase events from ordinary primitives rather than creating another authority.

### 27.7 Correction: merchant/shop is a reusable composite

Merchant behavior is no longer left as a placeholder concept.

The spec now decomposes immediate commerce into:

- provider;
- offers/catalog;
- stock;
- PricePolicy;
- payment/currency;
- purchase/sell admission;
- liquidity;
- restock;
- schedule;
- narration.

Immediate trade is one transactional Commerce decision. Scarce/long-running fulfillment composes with existing ServiceJob primitives.

### 27.8 Primitive catalog is intentionally broader than the first milestone

Document 21 brainstorms a much larger immersive-world vocabulary—perception, recognition, materials, survival, social memory, rumor, witness/knowledge, crime/law, ecology, crafting, world events, etc.

This is **not** a mandate to implement all of them before the first cartridge.

A primitive graduates into engine semantics only when repeated use, invariants, determinism, Builder discovery, or certification needs justify it. Otherwise prefer a recipe/template/reaction/scene/script composition.

This keeps the design expressive without turning R3/R5 into an attempt to prebuild every future game feature.

### 27.9 Implementation and acceptance gates were updated

R3/R5/R7/R8/R9/R10/R11 now explicitly prove the new layers.

The first real cartridge now stresses:

- several connected quests;
- branch consequences;
- text cutscene;
- dream/private narrative sequence;
- scripted world event/reaction;
- inspectable details;
- target ambiguity;
- coherent barrier;
- population plan;
- merchant behavior;
- behavior arbitration.

New acceptance scenarios cover ActionRecipe retry safety, TargetResolution, details, barrier coherence, population provenance, behavior conflicts, reactions, commerce, SceneSequence crash/retry, dream isolation, quest/scene integration, and multi-phase WorldEventPlan behavior.

### 27.10 Review conclusion

The classic-MUD pass strengthens rather than overturns the v3 architecture.

The desired synthesis is:

> **TinyMUD-style relational/manipulable world + Diku/Circle-style reusable curated mechanics + Loka's typed deterministic authority + a powerful composition/narrative layer.**

The remaining implementation discipline is to resist both extremes:

- do not hardcode every immersive feature as a new subsystem;
- do not collapse all unusual behavior into an arbitrary scripting escape hatch.

The middle layer is now explicit enough to guide that tradeoff.


### 27.11 Autonomous world work must not fabricate player invocations

**Finding:** once Behavior, PopulationPlan, ServiceJob, and WorldEventPlan became explicit, the earlier simplified canonical diagram could be read as requiring autonomous world machinery to manufacture fake player ActionInvocations.

**Risk:** either internal systems spoof player intent, or they bypass the Command/decision/commit spine entirely.

**Correction:** the packet now distinguishes two Command origins:

1. player/agent/test-bot interaction: ActionInvocation -> authority re-resolution/revalidation -> semantic Command;
2. trusted autonomous world work: scheduler/job, selected BehaviorIntent, population reconciliation, and world-event/system transitions -> registered authority-internal Command.

Both converge on the same DecisionCoordinator/pure decision -> StateDelta + DomainEvents + Effects -> commit path.

Internal Commands are typed, carry stable causation/idempotency where retryable, and cannot be submitted by an untrusted client to bypass ActionInvocation validation.

### 27.12 Primitive selection needed an escape-hatch discipline

**Finding:** a large primitive catalog can paradoxically make authoring worse if builders do not know whether a mechanic should be an ActionRecipe, ReactionRule, Behavior, SceneSequence, ServiceJob, Quest, script, or engine capability.

**Correction:** document 21 now includes a decision table and escalation rule.

The preferred discipline is to use the most specific typed construct that captures the invariant and escalate toward LokaScript/new engine capabilities only when lower-level composition is genuinely insufficient.

The same section records additional immersive-world candidate families—knowledge/secrecy, language/communication, institutions/obligations, transport, property, supply, drives, navigation, hazards, selected world history, companions, documents, rituals, and governance—without turning them into first-cartridge requirements.


## 28. Scene-space, release-assurance, and Foundry portability review

### 28.1 SceneSequence was being asked to carry two different responsibilities

**Finding:** dreams/visions were described as SceneSequence use cases, but an interactive
dream may contain ordinary movement, rooms, NPCs, combat, puzzles and population between
narrative beats.

**Risk:** SceneSequence becomes a mini-world engine or dream receives a bespoke spatial
runtime.

**Correction:** SceneSequence now owns narrative sequencing only. Generic InstancePlan
owns scoped spatial instantiation from precompiled definitions. SceneSpace chooses
current world, scoped overlay, or InstancePlan.

A dream/vision/flashback is therefore a content composition. The same InstancePlan serves
private dungeons, party puzzles, tutorials and ritual/trial spaces.

### 28.2 Existing Lab gates were strong but partial/test evidence could be confused with release proof

**Finding:** static checks, branch simulation, property tests, bots, chaos, semantic review
and exact-hash certificates already existed, but the packet did not fully specify the
progression from edit-time checks to frozen-candidate release assurance or account for
what authored surfaces remained unexercised.

**Correction:** document 09 now adds:

- explicit certification pyramid;
- freeze-first exact-candidate evidence binding;
- machine-readable CoverageManifest;
- static topology/quest/scene/reaction model analysis;
- bounded state/path/seed/interleaving exploration;
- reusable invariant registry;
- mutation-sensitivity testing;
- differential/metamorphic testing;
- model-proposed adversarial scenarios executed deterministically;
- explicit blocker classes;
- content-addressed CertificationEvidenceBundle;
- regression ratchet.

Partial area/quest/component preflights remain useful but are not release certificates.

### 28.3 LLM review is useful only as a separate evidence layer

High-reasoning models may inspect exact graphs/traces/branch comparisons and identify
causal contradictions, knowledge leaks, implausible schedules, dead-feeling areas,
misleading choices or missing adversarial scenarios.

Their findings must cite evidence and cannot waive deterministic/security failures.

Model-proposed gameplay attacks become typed Lab scenarios before they count as evidence.

### 28.4 Jev is positioned as optional fast triage, not certification

Current TypeSafe material presents Jev as a typed probabilistic decision model intended
for structured workflows.

Loka records it only as a candidate for high-volume semantic routing/triage after held-out
evaluation. It may prioritize evidence or classify likely anomaly type, but cannot turn
an untested candidate green, suppress mandatory review, establish independence, or
publish.

### 28.5 Loka now exposes the boundaries an orchestrator such as Foundry should enforce

The Builder document now records representative role surfaces:

- world builder: L3–L6 Builder/Lab authoring, normally no engine-source/shell;
- quest/story builder: narrower content surface;
- engine-capability developer: explicitly admitted L2 source-code work;
- semantic reviewer: read/simulate only;
- certification/release role: exact-hash evidence/publication surface only.

MISSING_CAPABILITY returns a CapabilityProposal. It does not grant the builder permission
to edit engine code.

Context routing follows the admitted role. A model may act in different roles, but role
labels/sessions do not mint authority or reviewer independence.

Foundry remains optional: Loka's Builder API, Lab, capability registry and certificate
contracts define the semantic/evidence truth even when Foundry orchestrates them.


## 29. Post-composition self-review and adversarial review

This round reviewed the classic-MUD/composable-world additions, Foundry/Astra role
integration, SceneSequence/InstancePlan decomposition, and expanded Cartridge Lab release
assurance as one combined contract.

### 29.1 Self-review findings corrected

**Stale dream-space vocabulary.** One acceptance case still named a
`private_scene_instance` after SceneSpace had been generalized.

**Correction:** the case now uses SceneSequence + SceneSpace `instance` + InstancePlan.

**Certification profile drift.** Document 09 described CoverageManifest, model analysis,
invariants, exploration and evidence bundles, but the explicit Story/Realm profile
minimums had not yet named those gates.

**Correction:** the profile requirements now include frozen-candidate identity,
model-analysis/coverage/invariants/exploration, profile-selected mutation sensitivity,
evidence-bundle binding, and mounted/soak obligations where relevant.

**Instance sequencing gap.** InstancePlan appeared in narrative/runtime prose after R3
without an explicit registry/schema obligation and after the first Story milestone in
some readings.

**Correction:** R3 now includes SceneSpace/InstancePlan schema; R7 proves a minimal
portable Story InstancePlan before R19 integrates the same semantics into shared Realm
geography.

### 29.2 Adversarial authority findings corrected

**Instance deep-copy ambiguity.** "Instantiate an area" could be misread as recursively
cloning referenced shared/singleton/account-owned runtime state.

**Correction:** InstancePlan now has explicit instancing closure/import/export semantics.
Non-instantiable/shared/account-owned state must bind through a supported authority
contract or fail; temporary state exports only through declared typed consequences.

**Scene actor re-resolution ambiguity.** A scene could otherwise repeatedly search a
display name/definition and bind another NPC after reconnect, respawn or phasing.

**Correction:** consequential scenes persist SceneRoleBindings with cardinality and
missing-participant policy. Silent arbitrary rebinding is forbidden.

**Autonomous-work input ambiguity.** New Behavior/Population/WorldEvent mechanisms made it
important to distinguish player ActionInvocation from trusted internal world work.

**Correction:** schedulers/jobs/selected BehaviorIntents/population/world-event machinery
originate registered authority-internal Commands and converge on the same
DecisionCoordinator/StateDelta/DomainEvent/Effect/commit spine.

### 29.3 Adversarial certification findings corrected

**Self-reported coverage.** Candidate content could otherwise claim a branch was covered
or excluded.

**Correction:** certification tooling generates CoverageManifest from the frozen artifact
plus observed/proved receipts. Candidate exclusions require policy validation/disposition.

**Model-authored test oracle.** An LLM-generated adversarial scenario could otherwise
invent its own expected invariant and thereby mint a release failure/pass.

**Correction:** model-proposed properties become governing only when they map to an
existing registered/profile invariant or are separately reviewed/admitted.

**Candidate-authored checker.** Cartridge-authored tests could otherwise present a friendly
green suite as release evidence.

**Correction:** authored tests are supplemental candidate-controlled evidence and cannot
replace or weaken engine/profile gates.

**Impact-analysis false negative.** Dynamic script/selectors/custom-event edges may make
static dependency analysis incomplete.

**Correction:** ImpactSet is fail-conservative; unknown dependency widens required checks
rather than allowing stale receipt reuse.

**Waivable hard blocker.** Mechanical/security failures could be misread as ordinary
review findings.

**Correction:** ordinary author/reviewer/release/model waivers cannot clear
mechanical/security blockers. Changing their classification requires an explicit reviewed
certification/architecture policy revision.

### 29.4 Area/release robustness added

The Lab now distinguishes:

- edit-time checks;
- isolated AreaDefinition assurance;
- mounted dependency-closure assurance;
- frozen cartridge certification;
- deployment/shared-area certification;
- commercial release evidence.

Whole-cartridge/deployment certification remains mandatory even if every area passes in
isolation.

Change-impact analysis accelerates author feedback but cannot shrink protected release
truth. Final living-world candidates also receive profile-appropriate long-horizon soak
simulation to find slow population/economy/job/state leaks.

### 29.5 Foundry/Astra boundary review

The Loka docs now expose machine-readable role/surface intent but do not make Foundry
part of gameplay or certification truth.

Representative orchestration roles remain project vocabulary:

- world/quest builder: typed L3–L6 Builder/Lab authoring;
- engine-capability developer: separately admitted L2 source work;
- semantic reviewer: read/simulate only;
- release role: exact-certified-artifact surface only.

MISSING_CAPABILITY yields a CapabilityProposal/escalation; it does not grant the builder
engine-code authority.

The corresponding Foundry strategy work must enforce capability grants outside prompts,
derive API scope from authenticated assignment identity, protect reviewer independence by
durable lineage, and keep broader escalated engine work in a separately admitted
assignment.

### 29.6 Adversarial conclusion

No new reason was found to replace the v3 authority architecture.

The main hardening result is stronger separation of concerns:

~~~text
narrative sequence != spatial instance
project role name != authority
candidate tests != certification authority
semantic model opinion != deterministic gate
area preflight != release certificate
unknown dependency != safe evidence reuse
~~~

The remaining high-risk unknowns are still the deliberate evidence gates already recorded:
portable implementation/binding choice, store-review posture for downloaded rule content,
and later multi-zone Realm placement/routing.

## 30. Final closure adversarial review

A fresh high-reasoning closure pass was run after the §29 self/adversarial review instead
of treating the prior "no blocking issue" conclusion as sufficient. The pass focused on
retry identity during ownership movement, distributed-effect delivery semantics, and
cross-document vocabulary that could still cause two implementations to diverge.

### 30.1 Command retry identity could fracture across authority handoff

**Finding:** command receipts were keyed/described in terms of the current authority/
instance. Reconnect retry was covered, and shard handoff was covered, but the two cases
were not composed. A command could commit on ZoneShard A, move the character to ZoneShard
B, lose its acknowledgement, and then be retried through normal routing after B became
owner. An implementation that derived idempotency from the current owner could treat the
retry as fresh work.

**Correction:** external mutation idempotency now uses a logical gameplay lineage/
controlled-actor scope that outlives session/process/shard ownership. Receipt lookup must
remain reachable after ownership movement. R20 may choose a realm-level receipt index,
receipt migration, forwarding/tombstones, or an equivalently durable mechanism, but
ownership movement cannot mint a new command identity.

The runtime architecture, persistence contract, command protocol, R20 gate, acceptance
suite, and ADR register now all carry this invariant. ACT-14 specifically tests a lost
acknowledgement after a handoff.

### 30.2 Cross-authority delivery accidentally implied exactly-once transport

**Finding:** the architecture correctly used outbox/idempotency for cross-authority work,
but one acceptance scenario said the remote operation was retried "exactly once." That
wording could cause an implementation to assume a transport property that the architecture
cannot generally guarantee after acknowledgement loss.

**Correction:** durable asynchronous effects are now explicitly at-least-once delivery
with idempotent authoritative application. Duplicate delivery is expected and tested.
Durable effects also declare terminal-failure/reconciliation behavior; required gameplay,
custody, entitlement, or similar obligations cannot silently disappear when ordinary retry
is exhausted.

Quest cross-authority consequences and the outbox acceptance scenarios now use the same
semantics.

### 30.3 Certification profile vocabulary had drifted from execution-profile vocabulary

**Finding:** runtime docs use the canonical execution profiles:

~~~text
offline_private
online_private
party
shared_area
~~~

but Builder/certification/implementation prose still used older
`offline_private_story`, `online_private_story`, and `party_story` labels in a few
normative places.

**Risk:** schema authors could create a second parallel profile enum or require ad-hoc
mapping between authoring, runtime and certification.

**Correction:** gameplay certification now reuses the canonical execution-profile names.
Capability-pack and mobile-app-release certification profiles remain separate because they
are not gameplay execution profiles.

### 30.4 Closure result

The corrections above do not change the v3 product or authority architecture. They close
three remaining implementation-ambiguity classes:

~~~text
owner movement != new idempotency identity
at-least-once delivery != duplicate authoritative application
certification profile != second gameplay-profile vocabulary
~~~

No additional blocking contradiction was found in the final cross-document pass.

The deliberate evidence gates remain deliberate:

- R1 portable implementation/binding selection;
- current-store review posture for downloaded rule representation;
- R20 concrete long-lived placement/routing/handoff mechanism, now constrained by
  migration-stable retry identity;
- later capability candidates that must graduate from real content evidence.

This review is still part of the repository's specification process, not independent
third-party approval. With these corrections applied, the PR is internally ready to leave
draft status and proceed to human merge/acceptance.

## 31. Fresh post-closure architecture audit

A fresh whole-packet audit was run after the Draft 0.3 closure review. The review compared the v3 contracts against both the merged packet and concrete current-Lokacore failure surfaces rather than assuming the previous review conclusion was sufficient.

### 31.1 Result: no new foundational rewrite is justified

The audit found no reason to replace the clean-sheet/Story+Realm/portable-semantics/BEAM-authority architecture.

Concrete current-Lokacore code reinforces the rebuild rationale: entity processes retain dirty mutable state with periodic persistence while action/framework code also performs direct multi-step writes; gameplay action results mix state changes with transport-oriented tuple events; the scripting sandbox ultimately executes validated source through `Code.eval_string`; and Builder terminal/MCP surfaces have overlapping hand-maintained operation semantics.

V3's one-authority, proposal/commit, typed-schema and canonical-Builder contracts solve real accumulated architecture problems rather than aesthetic ones.

### 31.2 StateDelta composition and pre-commit DomainEvent visibility were still too implicit

**Finding:** StateDelta existed as a first-class proposal and deterministic event chains were specified, but two details were easy to implement differently:

- how two evaluators writing the same authoritative target compose or conflict;
- whether a DomainEvent generated during an in-transaction decision may be externally observed before the transaction commits.

**Correction:** document 04 now makes the proposal overlay explicit. Delta operations use canonical typed targets, deterministic ordering, registered composition/conflict rules and no implicit last-writer-wins. In-decision DomainEvents are proposed facts; they may drive other deterministic reducers but cannot escape through PubSub/client/external authority paths until the commit succeeds.

Acceptance cases ARCH-09/10 cover these boundaries.

### 31.3 Logical world identity and authority placement needed nominal separation

**Finding:** StateScope was already independent from physical placement, but an implementation could still overload an `instance_id` as both logical world identity and current ZoneShard/authority owner.

**Risk:** early schemas could make later partitioning/handoff/fencing awkward or accidentally alter semantic/idempotency identity when placement changes.

**Correction:** document 03 and ADR-046 now require distinct logical world/context and mutation-owner placement identities. R20 still selects the concrete placement mechanism.

### 31.4 Portable-kernel scope needed an inspectable residency contract

**Finding:** the packet correctly says to keep the portable kernel narrow, but a large capability library creates two symmetric risks: BEAM host/orchestration logic can creep into the native kernel, or offline-required semantic logic can remain hidden in one host implementation.

**Correction:** the capability architecture now requires an inspectable semantic-residency view across portable semantics, Realm-only pure evaluators, host coordination, client presentation and authoring/certification. The same view identifies conformance obligations under either shared-Rust or dual-implementation R1 outcomes.

### 31.5 R1 needed pre-registered quantitative decision criteria

**Finding:** R1 listed important acceptance/rejection dimensions but terms such as "acceptable FFI overhead" or "unreasonably fragile" could be reinterpreted after a favored implementation had already been built.

**Correction:** R1 now requires a reviewed acceptance-envelope artifact before spike implementation results are known. It records representative state/command sizes, target devices, latency/scheduler/memory/save expectations, crash/debug/release criteria, dependency risk, and fallback comparison procedure.

The permanent architecture does not guess numeric thresholds; R1 freezes them before measurement.

### 31.6 R3 was at risk of freezing too much too early

**Finding:** the packet correctly says to prove a real cartridge before over-generalizing authoring, but R3 simultaneously listed production schemas for many high-level systems that would not be implemented/exercised until R7/R8.

**Risk:** guessed fields become compatibility commitments before evidence exists.

**Correction:** R3 now distinguishes constitutional contracts (identity, command/delta/event/effect, determinism, scope, manifests, registry, GameView, etc.) from versioned feature envelopes. Foundation-world composition schemas freeze as R5 implements them; narrative/instance schemas freeze with R7; living-world/population/commerce/service/world-event schemas freeze with R8 before downstream artifacts depend on them.

This preserves early machine-readable structure without treating every brainstormed field as permanent API.

### 31.7 Architecture torture testing and product design are now separate cartridges

**Finding:** R10 required one small first story to simultaneously be a coherent product and contain nearly every architectural stress feature—dream/InstancePlan, merchant, PopulationPlan, Behavior conflict, WorldEventPlan, target ambiguity, barrier and more.

**Risk:** the first game's fiction gets distorted by the test checklist, while regression coverage remains entangled with one product story.

**Correction:** R9C now creates a permanent synthetic V3 Conformance Cartridge optimized for broad deterministic/fault/invariant coverage. R10 becomes the first real player-facing Story cartridge and uses mechanics because they serve the game.

R11 Builder generalization uses both synthetic breadth and real authoring pain.

### 31.8 Builder complexity should be progressively disclosed

**Finding:** ActionRecipe, ReactionRule, Behavior, StateMachine, SceneSequence, ServiceJob, PopulationPlan, Quest, WorldEventPlan and related shapes are individually defensible, but forcing every author/model to select among them before stating intent would turn the composition grammar into a usability tax.

**Correction:** Builder now explicitly prefers intent-oriented operations and can suggest/explain the smallest typed composition shape. Material authority/persistence/scope differences are surfaced rather than guessed. Repeated R10 author confusion becomes Builder/primitive-boundary evidence.

### 31.9 Certification needed explicit applicability classes

**Finding:** the Lab architecture is intentionally rigorous, but without a registry-level applicability classification the system risks either running irrelevant expensive checks everywhere or relying on humans/content to remember which hard gates apply.

**Correction:** certification gates now classify as always-mandatory, capability-triggered, risk/profile-triggered, or commercial-release-only. Applicability derives from the frozen artifact/deployment/profile and fails conservative.

This changes scheduling/cost, not correctness authority: applicable mandatory gates remain mandatory.

### 31.10 The accepted specification needs a single post-R0 home

**Finding:** current Lokacore already contains valuable but historically inconsistent architecture documentation. Leaving the accepted v3 packet in Lokacore while a fresh implementation repository independently evolves its own docs would recreate the same multi-era source-of-truth problem.

**Correction:** R0 records the exact accepted normative commit/file set and a cutover manifest. R2 imports that contract into the fresh implementation repository. Thereafter implementation-era amendments happen there; Lokacore remains reference/provenance.

The fresh repository should physically separate compact normative architecture/ADRs/gates from archaeology, review history and external research so detail does not imply equal authority.

### 31.11 Audit conclusion

The strongest remaining threat to v3 is no longer an incoherent authority model. It is **surface-area risk**: freezing abstractions before evidence, making the portable layer too broad, letting a rich composition grammar become hard to use, or building certification/tooling so comprehensively that it delays the first game.

The corrections in this round therefore preserve the central architecture while making it smaller and harder to misimplement:

~~~text
one semantic spine
+ explicit proposal/commit visibility
+ explicit semantic residency
+ pre-registered architecture-spike evidence
+ constitutional contracts before feature-schema freeze
+ synthetic conformance cartridge separate from product cartridge
+ intent-first Builder
+ applicability-driven certification
+ one post-R0 normative specification authority
~~~

No new reason was found to create a V4 architecture before implementation evidence exists. The remaining deliberate evidence gates remain R1, store-review treatment of downloaded rule content, R20 placement/handoff mechanics, and capability graduation from real content.

This review is repository design evidence and still requires the project's normal independent/adversarial review process before R0 acceptance.

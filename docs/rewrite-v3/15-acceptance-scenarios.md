# 15 — Adversarial Acceptance Scenarios

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Governing acceptance scenarios.

Locate the scenario family for a claim. A listed scenario is a requirement/example for implementation evidence, not proof it has run.

<details>
<summary>Sections in this document</summary>

- [A. Portable rules and determinism](#a-portable-rules-and-determinism)
- [B. Offline lifecycle](#b-offline-lifecycle)
- [C. Containment and inventory](#c-containment-and-inventory)
- [D. Quest correctness](#d-quest-correctness)
- [E. Dialogue](#e-dialogue)
- [F. Actions and policy](#f-actions-and-policy)
- [G. Scripting](#g-scripting)
- [H. Living world and time](#h-living-world-and-time)
- [I. Cartridge/compiler](#i-cartridgecompiler)
- [J. Builder/AI](#j-builderai)
- [K. Mobile protocol](#k-mobile-protocol)
- [L. Online transaction and recovery](#l-online-transaction-and-recovery)
- [M. Session/account/character](#m-sessionaccountcharacter)
- [N. Offline-to-MMO reconciliation](#n-offline-to-mmo-reconciliation)
- [O. Commerce](#o-commerce)
- [P. Operations](#p-operations)
- [Q. Architecture tests](#q-architecture-tests)
- [R. Definition of a regression](#r-definition-of-a-regression)
- [S. Cartridge composition](#s-cartridge-composition)
- [T. Long-lived offline compatibility and signing](#t-long-lived-offline-compatibility-and-signing)
- [U. Receipt and platform boundaries](#u-receipt-and-platform-boundaries)
- [V. Client mode and builder target separation](#v-client-mode-and-builder-target-separation)
- [W. Quest sharing, phasing, and scarce services](#w-quest-sharing-phasing-and-scarce-services)
- [X. Composable world primitives and classic-MUD conformance](#x-composable-world-primitives-and-classic-mud-conformance)
- [Y. Quest scenes, dreams, cutscenes, and scripted world events](#y-quest-scenes-dreams-cutscenes-and-scripted-world-events)
- [Z. Release assurance and orchestrated role boundaries](#z-release-assurance-and-orchestrated-role-boundaries)
- [Audit follow-through acceptance cases](#audit-follow-through-acceptance-cases)
- [Account and prologue progress acceptance](#account-and-prologue-progress-acceptance)
- [Readiness closure: initial composition and run lifetime](#readiness-closure-initial-composition-and-run-lifetime)

</details>
<!-- packet-navigation:end -->

These scenarios turn architecture claims into observable behavior.

They are intended to seed automated tests, Cartridge Lab repros, architecture reviews, and implementation issues.

Scenario IDs are stable.

## A. Portable rules and determinism

### DET-01 — Same command, same state

Given identical:

- cartridge hash;
- deployment;
- state snapshot;
- logical time;
- RNG state;
- command

the portable rules layer returns a canonically identical result across repeated runs.

### DET-02 — Cross-host equivalence

Run the same fixture through every host implementation/adapter required by the R1-selected portable-execution strategy.

For a shared native kernel this includes direct/native, BEAM, iOS, and Android host paths. For the dual implementation, tested first (ADR-068), compare the accepted Elixir and mobile implementations instead.

Domain-result hash MUST match.

### DET-03 — RNG replay

A randomized skill check is replayed from snapshot/seed and produces identical rolls/outcome.

### DET-04 — Wall clock ignored

Changing host system clock does not affect a `play_time` cartridge command result.

### DET-05 — Unknown capability

Artifact references unknown capability/version.

Compile/launch fails closed with typed diagnostic.

### DET-06 — Deterministic map ordering

Two hosts construct logically equivalent state maps/sets in different insertion orders.

Canonical decision/trace hash is identical.

### DET-07 — Deterministic IDs

A scripted spawn under identical instance/command/RNG/ID-source state produces the same canonical identity sequence across hosts.

### DET-08 — Numeric boundary

Rule-critical arithmetic at rounding/threshold boundaries produces identical results on ARM mobile and server host.

No platform floating-point difference changes quest/combat/economy outcome.

### DET-09 — Portable-rules proposal is non-mutating before commit

Decision returns a proposal/delta.

Host simulates persistence failure.

Subsequent decision observes the original committed state.

### DET-10 — Post-commit in-memory apply failure

Persistence commits the delta, then an injected in-memory authority/portable-state adoption failure occurs.

Authority restarts/reloads committed state and does not execute command twice.

### DET-11 — Portable implementation fault boundary

An injected portable-rules implementation failure—including a native panic when the R1-selected strategy uses native code—cannot silently produce committed game state.

Host returns failure/restarts as applicable.

## B. Offline lifecycle

### OFF-01 — Airplane mode launch

Previously acquired/downloaded paid cartridge starts with no network.

### OFF-02 — Airplane mode full play

Player can complete representative cartridge without network.

### OFF-03 — App killed before local commit

Kill after decision but before SQLite transaction completion.

On restart state is previous committed revision.

### OFF-04 — App killed after local commit

Kill after SQLite commit but before UI update.

On restart new committed state appears once.

### OFF-05 — Duplicate local command

Same command ID is retried after crash.

Effect occurs once.

### OFF-06 — Low storage

SQLite write fails due simulated storage error.

UI does not advance durable state; user gets recoverable error.

### OFF-07 — Corrupt snapshot

Snapshot checksum/format invalid.

System attempts known-good prior snapshot/recovery path or reports typed save corruption; it does not invent state.

### OFF-08 — Long absence

Real-elapsed cartridge resumes after 30 days with many due jobs.

Jobs reconcile deterministically without freezing UI indefinitely or duplicating effects.

### OFF-09 — Clock rollback

Device clock is moved backward.

Elapsed-time policy handles according to defined rule; no negative timer corruption.

### OFF-10 — Divergent devices

Device A and B continue same cloud-backed save independently.

Sync preserves both branches and requests selection; no arbitrary merge.

### OFF-11 — Cartridge update

Save pinned to v1.2; v1.3 installed.

Save still opens with v1.2 or performs explicit certified migration.

### OFF-12 — Old artifact garbage collection

Attempt to delete v1.2 artifact while save requires it.

Deletion blocked or save migration/deletion explicitly required.

### OFF-13 — Resume-time advancement retry

A real-elapsed Story save resumes after an absence. The authority samples/clamps elapsed time and commits a resume-time advancement input, then the app crashes before presenting the updated view.

Restart/retry does not apply the same elapsed interval twice; scheduled jobs/deadlines observe exactly one accepted advancement.

## C. Containment and inventory

### INV-01 — Atomic pickup

Take item.

After commit item is in exactly one container: player inventory.

### INV-02 — Crash during pickup

Crash at every boundary.

Never observe item in neither room nor inventory or in both after recovery.

### INV-03 — Duplicate pickup

Two identical command retries.

One item acquired.

### INV-04 — Give item

Transfer player A→B online.

Ownership changes atomically.

### INV-05 — Shared race

Two players attempt same ground item concurrently.

Exactly one succeeds; loser receives typed stale/not-present response.

### INV-06 — Container deletion

Delete/despawn container.

Explicit containment policy applied; contents never silently vanish due generic recursive delete.

### INV-07 — Equipment ownership

Equipped item remains owned/contained consistently and cannot also be equipped by another character.

## D. Quest correctness

### QST-01 — Offered activation

An eligible offered quest has no QuestInstance before acceptance. Accepting it creates exactly one active QuestInstance with activation metadata through a legal transition.

### QST-02 — Double activation

Retrying the offered/automatic/discovery activation event does not create a duplicate QuestInstance.

### QST-03 — Wrong NPC talk

Talking to different NPC does not complete targeted objective.

### QST-04 — Wrong dialogue node

Talking to correct NPC but wrong node does not complete node-specific objective.

### QST-05 — Premature turn-in regression

Objective observation cannot cause the historical class of bug where turn-in action is skipped because quest was marked complete too early.

### QST-06 — Duplicate domain event

Same event ID processed twice.

Objective/reward advances once.

### QST-07 — Reward crash

Crash after quest completion decision before/after durable commit/effect.

Reward exists exactly once.

### QST-08 — Abandon/reaccept

Definition's retry policy honored; stale objective state does not leak unexpectedly.

### QST-09 — Deadline offline

Timed quest expires according to declared logical-time policy while app is closed and reconciles deterministically on resume.

### QST-10 — Quest version pin

Quest v2 published while v1 active.

Existing QuestInstance continues v1 until explicit migration/finish.

### QST-11 — Giver death

Quest giver permanently dies in private story.

Quest either intentionally fails or has certified alternate completion; player is not silently hard-locked unless intended ending.

### QST-12 — Player-scoped shared quest

Two MMO players talk to same shared NPC.

Their quest states remain independent.

### QST-13 — Party scope

Party quest progresses according to explicit party membership/policy and does not leak to another party.

### QST-14 — Realm event

Realm-scoped event intentionally changes all eligible players/world state; certification verifies this broad scope is explicit.

### QST-15 — Automatic discovery quest

Player discovers a hidden shrine whose prerequisite facts are satisfied.

Before the discovery trigger there is no QuestInstance. The activation index identifies the definition as a candidate, the quest activates without an NPC giver, records the discovery event once, and its journal visibility follows the separate reveal/visibility policy. It can resolve automatically without a turn-in NPC.

### QST-16 — Multiplayer kill credit

Player A and Player B share a zone. A kills a quest target.

For an `actor` credit objective, only A progresses.

For an eligible `party` policy, configured party members progress.

An unrelated nearby player does not progress unless the objective explicitly uses witness/scope policy.

### QST-17 — Witness credit requires actual observation

An objective credits witnesses to a public event.

A player in another room/instance does not progress merely because the DomainEvent exists globally.

### QST-18 — World-caused quest event

A quest target dies due to world simulation or another NPC rather than the player.

The quest follows its authored failure/alternate-outcome rule instead of assuming every relevant event has the questing player as actor.

### QST-19 — Quest unlocks area atomically

Completing a Story quest outcome opens a stateful gate/connection in the same local authority.

Crash is injected before and after commit.

After recovery, quest outcome and gate state are either both old or both committed; never split.

### QST-20 — Personal unlock does not leak

In Realm Mode, player A completes a player-scoped quest that grants access to a hidden passage.

Player A can use the passage. Player B, who has not met the condition, cannot.

The shared Realm connection/entity is not accidentally opened globally.

### QST-21 — Fact-driven world reaction

Quest sets `village.child_status = rescued`.

Without direct quest edits to each subsystem:

- mother dialogue changes;
- mother schedule/profile changes;
- ferryman ambient line set changes;
- follow-up quest becomes available;
- town description variant changes.

All reactions are explainable through fact/reference graphs.

### QST-22 — NPC branch state

Two branch forks end in `rescued` versus `dead`.

The mother's typed role state becomes `relieved` versus `grieving`; each state selects a valid schedule/dialogue profile and remains deterministic after seven simulated days.

### QST-23 — Consequence exactly once

Quest outcome grants item, sets fact, opens gate, and emits a custom DomainEvent.

Duplicate triggering event/retry cannot grant the item twice or re-run non-idempotent consequences.

### QST-24 — Consequence scope escalation rejected

A player-scoped quest contains an undeclared Realm-scoped consequence.

Compilation/certification rejects the quest rather than inferring global scope.

### QST-25 — Explicit Realm-wide consequence

A shared-area quest intentionally changes a Realm-scoped festival state.

The broader scope is explicit and multiplayer-certified; all eligible players observe the intended shared change.

### QST-26 — Cross-authority consequence retry

A quest outcome in ZoneShard A produces an idempotent effect intended for a Realm-wide service.

Crash/failure occurs after local outcome commit but before remote acknowledgement.

Outbox delivery may occur more than once. Every retry carries the same stable effect/idempotency identity; the Realm-wide service applies the authoritative consequence at most once and returns/reconstructs the same acknowledgement. If retry policy reaches terminal failure, the required reconciliation path remains durable and visible rather than silently dropping the consequence. The local quest outcome is not duplicated or implicitly rolled back.

### QST-27 — Area unlock preserves reachability

A branch closes one road and opens another.

Static graph checks plus branch simulation prove the player is not trapped away from required content unless the branch explicitly defines that ending.

### QST-28 — Branch world comparison

The Lab forks immediately before a major choice.

Its comparison report correctly identifies differing facts, access, NPC states, dialogue/action sets, spawned actors, and follow-up quests.

### QST-29 — Prerequisite changes after activation

A quest activates while prerequisite fact A is true. Later A becomes false for an unrelated world reason.

The active QuestInstance does not silently disappear/deactivate. It changes lifecycle only if the quest explicitly declares a sustain/failure/branch rule for that condition.

### QST-30 — Pre-activation events do not leak into progress

The player kills a target before accepting a normal event-observation quest, then activates the quest.

The old kill event does not retroactively advance the new QuestInstance. A quest that intends to credit already-satisfied state must use an explicit current-state or retroactive/history operator.

## E. Dialogue

### DIA-01 — Conditional choice

Choice appears only when policy true.

### DIA-02 — Stale choice

Mobile shows choice; state changes before selection.

Server/local authority revalidates and rejects stale choice if no longer legal.

### DIA-03 — Reconnect mid-dialogue

Online reconnect reconstructs consequential dialogue state or safely restarts according to definition.

### DIA-04 — Offline resume

Local save mid-dialogue resumes without quest inconsistency.

### DIA-05 — Branch reachability

Certification proves intended endings reachable.

### DIA-06 — Knowledge leak

Semantic review flags dialogue revealing information before the player can learn it.

## F. Actions and policy

### ACT-01 — Union

Equipment grants action without removing base actions.

### ACT-02 — Remove

Stun removes attack action.

### ACT-03 — Intersect

Meditation room permits only whitelist.

### ACT-04 — Replace

Transformation replaces normal ActionSet.

### ACT-05 — Priority override

Two sources provide same action key; deterministic priority/override rule chooses one.

### ACT-06 — Unknown policy

Unknown policy operator denies/fails compilation; never defaults allow.

### ACT-07 — Touch/text equivalence

Touch “Talk” and terminal `talk ferryman` resolve to same command semantics.

### ACT-08 — Ambiguous text target

Two guards match “guard.”

Parser returns structured candidates, not arbitrary target.


### ACT-09 — Forged hidden action invocation

Client submits an ActionInvocation for an action key not present in its current GameView.

Local Story authority or BEAM Realm authority re-resolves current ActionSet and rejects it unless independently legal. Hidden UI is never the security boundary.

### ACT-10 — Stale action invocation

Client submits an invocation carrying stale view-freshness token V41 after relevant authoritative state changed and a newer GameView would carry V42. The action is no longer legal.

Authority returns a typed stale/invalid-action result and fresh projection/resync guidance; it does not execute based solely on the old view.

### ACT-11 — Invocation retry

Client retries the same invocation after losing the acknowledgement.

The active authority maps it into the command/idempotency contract so a state-changing action cannot execute twice.

### ACT-12 — Realm local-rules forgery

A modified one-app client computes a favorable local result for a Realm action and submits it.

The server ignores local decision output and accepts only the ActionInvocation, then performs its own authoritative resolution/decision.

### ACT-13 — Invocation retry after reconnect

A Realm ActionInvocation commits, the acknowledgement is lost, and the client reconnects under a new session ID before retrying the same invocation ID.

The authority derives the same semantic Command/idempotency identity and returns the prior result. The action executes once; ephemeral session identity does not mint a new mutation.

### ACT-14 — Invocation retry after authority handoff

A Realm ActionInvocation commits on ZoneShard A and causes the controlled character to hand off to ZoneShard B. The acknowledgement is lost after commit/ownership transfer.

Retrying the same invocation ID through normal post-handoff routing reaches/reconstructs the original receipt and returns the prior result. ZoneShard B MUST NOT derive a fresh mutation identity from its new ownership and execute the action a second time.

## G. Scripting

### SCR-01 — Allowed binding

Portable script returns the registered typed StateDelta/DomainEvent/Effect result and behaves identically offline/online.

### SCR-02 — Filesystem escape

Attempt to open/read file is rejected at compile/interpreter boundary.

### SCR-03 — Module call

Attempt arbitrary Elixir/Rust/module invocation rejected.

### SCR-04 — Infinite loop

Interpreter step budget terminates script deterministically.

### SCR-05 — Effect flood

Script attempts 10,000 spawns.

Budget rejects/halts before resource exhaustion.

### SCR-06 — Query flood

Budget enforced.

### SCR-07 — Event recursion

Script emits a custom DomainEvent that recursively causes itself.

Event-chain depth/cycle controls terminate with diagnostic.

### SCR-08 — RNG script

Same RNG state gives same script branch offline/online.

### SCR-09 — Server-only binding in offline cartridge

Compilation fails portability gate.

### SCR-10 — Wall-time guard is not game semantics

A certified script has deterministic step/query/resource limits and runs on both a slower supported mobile host and the server.

Both hosts produce the same semantic result or deterministic budget error. A host wall-time kill switch cannot produce a normal cartridge-visible branch on one host while the other succeeds; if the outer guard fires, conformance/runtime health fails instead.

## H. Living world and time

### WORLD-01 — NPC schedule

NPC wakes/works/sleeps over simulated day and reaches valid rooms.

### WORLD-02 — Closed route

Door schedule makes NPC route impossible.

Certification reports schedule/path conflict.

### WORLD-03 — Synchronized emptiness

All marketplace NPCs leave simultaneously.

Semantic/liveliness review may flag undesirable synchronized schedule.

### WORLD-04 — On-demand growth

Plant state after 7 days derived correctly without 7 days of ticks.

### WORLD-05 — Population leak

30-day simulation proves spawn count bounded.

### WORLD-06 — Shop hours

Offline resume at night reports shop closed from logical time without requiring background execution.

### WORLD-07 — Weather deterministic

Seed/time produces repeatable weather sequence for portable weather capability.

## I. Cartridge/compiler

### CAR-01 — Namespace collision

Two cartridges both define `rooms/tavern`.

Both coexist because canonical refs differ.

### CAR-02 — Broken reference

Quest references missing NPC.

Compilation fails with field-path diagnostic.

### CAR-03 — Template cycle

A→B→A mixins fail compile.

### CAR-04 — Reproducible build

Same source/compiler version produces same artifact hash.

### CAR-05 — Mutation after certificate

Source changes one byte.

Artifact hash changes; old certificate cannot promote new artifact.

### CAR-06 — Missing locale

Required localization key missing.

Certification profile handles as error/warning according to locale policy.

### CAR-07 — Unsupported client feature

Installed app lacks required renderer capability.

Offline launch fails gracefully before save mutation; online catalog blocks/requests update.

### CAR-08 — Hostile package structure

A signed or unsigned cartridge archive attempts path traversal, duplicate-path confusion, or decompression far beyond declared resource limits.

Install fails in staging before activation; no filesystem escape or unbounded extraction occurs.

### CAR-09 — Published version cannot be rebound

`story@1.2.0` is already published at hash H1.

A different artifact H2 attempts publication under the same cartridge ID/version.

Publication fails; a new semantic version/release is required.

### CAR-10 — Certificate/signature does not change semantic identity

A compiled candidate has semantic cartridge hash H.

Certification produces a certificate referencing H and release signing adds signature/certificate metadata.

The semantic cartridge hash remains H. An exact archive/package hash may differ after envelope material is added, and verification can prove both domains without circular hashing.

## J. Builder/AI

### BLD-01 — Revision conflict

Two builders edit same workspace revision.

Second mutation receives conflict; no silent overwrite.

### BLD-02 — Semantic rename

Rename NPC key.

Typed incoming references updated; diff shown; validation passes.

### BLD-03 — Dry-run delete

Delete quest giver dry-run lists affected quest/dialogue refs.

### BLD-04 — Agent missing capability

Agent requests possession mechanic not supported.

Builder returns structured MISSING_CAPABILITY; agent cannot bypass with hidden raw code.

### BLD-05 — Reviewer permissions

Review agent cannot publish.

### BLD-06 — Publication policy

Author agent cannot bypass failed certification.

### BLD-07 — MCP/terminal parity

Same Builder operation via MCP and terminal produces same underlying workspace result.

### BLD-08 — Lost Builder response retry

A mutating Builder operation commits revision 43, but the caller loses the response and retries the same `operation_id` with its original expected revision 42.

The Builder returns the original committed result/revision without applying the mutation again.

### BLD-09 — Reused Builder operation ID with different payload

An already committed `operation_id` is retried with different semantic input.

The Builder returns an idempotency/integrity conflict and does not apply either a second mutation or a misleading replay response.

## K. Mobile protocol

### PROTO-01 — Generated parity

Elixir and TypeScript fixtures decode same message schema.

### PROTO-02 — Old client

Unsupported protocol version rejected with typed upgrade response.

### PROTO-03 — Projection-sequence gap

Client misses a projected delta/message.

It detects a gap in its projection stream sequence and resyncs from a fresh GameView snapshot. Unrelated ZoneShard authority revisions do not by themselves create false client-gap detection.

### PROTO-04 — Stale local projection

Client button remains visible after server policy changes.

Server revalidates command; client receives typed rejection/new ActionSet.

### PROTO-05 — Unknown server message

Versioned handling does not crash app; incompatible required semantics force resync/update.

## L. Online transaction and recovery

### ONL-01 — Duplicate network command

Client retries after timeout.

Command receipt returns existing result; state/effects once.

### ONL-02 — DB failure

PostgreSQL commit fails.

WorldInstance does not adopt uncommitted state.

### ONL-03 — Crash after DB commit

WorldInstance crashes before reply.

Restart loads committed revision; retry returns receipt.

### ONL-04 — Outbox retry

External durable effect commits locally, delivery succeeds remotely, but the acknowledgement is lost.

The outbox may redeliver the effect with the same idempotency key. The receiver applies the authoritative consequence once, returns/reconstructs the prior acknowledgement on duplicate delivery, and the sender eventually marks the effect complete. Network delivery itself is not assumed to be exactly once.

### ONL-05 — World owner duplicate

Injected split-brain/stale owner attempts to write after ownership moved.

DB revision plus ownership/fencing-generation guard rejects the stale writer, including the case where its state revision would otherwise appear current.

### ONL-06 — Mailbox overload

World instance crosses queue threshold.

Gateway throttles/rejects non-critical commands; BEAM remains responsive.

## M. Session/account/character

### SES-01 — Two mobile sessions

Same account connects from two devices per configured policy; character control rules explicit.

### SES-02 — Disconnect

Session dies; character/world durable state remains.

### SES-03 — Reconnect

New session reattaches/resyncs.

### SES-04 — Entitlement not character field

Deleting/recreating character does not erase purchased cartridge entitlement.

## N. Offline-to-MMO reconciliation

### MMO-01 — Adventure portal

Previously released offline storypack is launched from shared hub as online private instance with same content semantics.

### MMO-02 — Embedded instance

Player crosses physical MMO entrance into party-specific story instance and returns.

### MMO-03 — No offline loot import

Modified local save claims 1,000,000 gold/legendary sword.

MMO account gains none.

### MMO-04 — Narrative memory import

Offline ending marker may sync only to explicitly non-competitive profile/memory field.

### MMO-05 — Shared promotion

Private cartridge gains shared deployment overlay.

It must pass new shared-area certification; private certificate alone is insufficient.

### MMO-06 — Shared NPC personal quests

100 players share ferryman NPC while each has independent quest/dialogue progress.

### MMO-07 — Shared NPC death policy

Private story allows permanent ferryman death; shared deployment defines respawn/immortality/instance policy explicitly.

### MMO-08 — Resource competition

Shared promoted zone handles simultaneous harvest/loot according to declared shared semantics.

### MMO-09 — Cross-shard handoff

Character moves zone A→B and crash occurs at each handoff boundary.

After recovery exactly one shard owns character.

## O. Commerce

### PAY-01 — Purchase then offline

Purchase verified, pack downloaded, airplane mode, launch succeeds.

### PAY-02 — Restore

Fresh device restores entitlement and downloads pack.

### PAY-03 — Refund while device offline

Device may remain playable per offline policy; on reconnect entitlement reconciles predictably without deleting save unexpectedly.

### PAY-04 — Tampered package

Hash/signature mismatch prevents launch.

### PAY-05 — Wrong product mapping

Platform SKU cannot directly unlock arbitrary cartridge without canonical server mapping.

## P. Operations

### OPS-01 — PostgreSQL unavailable

Readiness fails; liveness may remain; authoritative mutations unavailable rather than pretending success.

### OPS-02 — AI provider unavailable

Gameplay and cartridge runtime unaffected.

### OPS-03 — Builder unavailable

Published gameplay unaffected.

### OPS-04 — Backup restore

Restore staging environment from backup and prove known instance/catalog/entitlement state.

### OPS-05 — Portable-rules/API version deploy

Incompatible active instance is checkpointed/migrated/kept on compatible runtime according to explicit release policy; never silently reinterpret state.

## Q. Architecture tests

### ARCH-01

Portable gameplay rules have no network/filesystem/database side channels; all required host inputs cross explicit ports/contracts.

### ARCH-02

Core/domain layer cannot import Phoenix/Ecto/web adapters.

### ARCH-03

`loka_web` is an external Realm transport adapter only; game rules cannot import serializers/socket structs.

### ARCH-04

No production content path uses dynamic atom creation from content strings.

### ARCH-05

No Builder adapter bypasses canonical Builder API mutation layer.

### ARCH-06

No online gameplay path mutates durable world state outside authority/store commit boundary.

### ARCH-07

No offline gameplay path mutates durable local save outside LocalInstanceAuthority commit boundary.

### ARCH-08

No published cartridge uses raw `Code.eval_string` or arbitrary downloaded executable code.

### ARCH-09 — Proposed event cannot escape failed commit

A command decision produces a DomainEvent and downstream quest/reaction proposal, then the authoritative persistence commit is forced to fail. No PubSub/client/external-authority observer receives that DomainEvent as committed; no projection reports success; retry executes from the last committed state.

### ARCH-10 — StateDelta conflict is explicit

Two deterministic evaluators propose incompatible writes to the same canonical authoritative target in one decision without a registered composition rule. The decision fails with a typed conflict instead of resolving by source order, map order, process scheduling, or implicit last-writer-wins.

A separately registered composable case produces the same canonical result on every supported host.

### ARCH-11 — Logical world identity is not authority placement

A Realm state record retains the same logical world/Realm context while authority placement moves from one ZoneShard/AuthorityDomain to another. Routing/fencing metadata changes; semantic StateScope, logical identity, and mutation idempotency identity do not silently change.

A schema/API that requires `instance_id == current_shard_id` fails the architecture test.

### ARCH-12 — Capability residency is inspectable

For every registered capability used by the conformance cartridge, tooling can report portability, semantic implementation residency, host adapter(s), and required conformance fixtures.

A portable capability implemented only in one host-specific path without the required parity implementation/evidence is rejected.

### ARCH-13 — Post-cutover specification authority is singular

After R2 imports the R0-accepted specification into the fresh v3 repository, a stale Lokacore architecture document disagrees with a reviewed implementation-repository ADR.

Implementation tooling/issues/PRs resolve the implementation-repository contract as normative and treat Lokacore only as provenance/reference. No automated context loader presents both as peer sources of truth.

## R. Definition of a regression

Any bug affecting state correctness should result in:

- new scenario or refinement of an existing scenario;
- deterministic repro fixture if possible;
- permanent test in the relevant profile.

The acceptance suite should grow monotonically with real failures.


## S. Cartridge composition

### COMP-01 — Campaign port binding

Chapter 1 exported exit is bound to Chapter 2 entry through campaign manifest.

Compiler resolves connection without exposing unrelated internals.

### COMP-02 — Private internal key

Expansion attempts to reference non-exported internal room from prior cartridge.

Compilation fails.

### COMP-03 — Extension point schema

Expansion contributes a quest hook to an exported extension point with wrong schema.

Compilation fails with typed diagnostic.

### COMP-04 — Immutable prior artifact

Installing expansion does not modify prior cartridge hash.

Only composite campaign/deployment manifest changes.

### COMP-05 — MMO mount

Shared realm mounts a certified cartridge through declared entry/exit ports.

No ad-hoc global-key reference is required.


## T. Long-lived offline compatibility and signing

### COMPAT-01 — App auto-update with old save

Device has cartridge/save pinned to older supported kernel API/rule-IR/content-schema versions.

App auto-updates with no network available.

Save opens and plays through backward-compatible execution or a fully local deterministic migration.

### COMPAT-02 — Failed save migration rollback

Injected crash/write failure occurs during local compatibility migration.

Original save and old artifact remain recoverable; no half-migrated save becomes authoritative.

### COMPAT-03 — Unsupported version removal gate

Release attempts to remove the only interpreter/migration path for a still-supported published cartridge.

Release certification blocks until compatibility/migration policy is satisfied.

### COMPAT-04 — Signing-key rotation

Cartridge A was signed with old trusted key K1. New catalog content uses K2 after rotation.

A remains verifiable while K1 is still in the supported verification keyset; new content verifies with K2.

### COMPAT-05 — Revoked signing key

On reconnect, client learns K1 is revoked due compromise.

Current product/security policy is applied explicitly; client does not silently equate signing-key revocation with deleting local saves.

### COMPAT-06 — Tampered key ID/signature metadata

Artifact substitutes key ID or signed metadata without valid signature.

Verification fails before launch.

### COMPAT-07 — Capability version remains semantically pinned

A published cartridge is certified against `schedule@1`.

The engine later introduces `schedule@2` with different semantics.

The old cartridge continues to execute `schedule@1` semantics or follows an explicit certified migration; merely installing the newer engine/app does not reinterpret the old artifact.

## U. Receipt and platform boundaries

### RECEIPT-01 — Retry returns stable committed response

Online state-changing command commits, client times out before receiving reply, then retries same command ID.

Runtime does not execute again and returns the original stable committed result/ack (or a reconstruction explicitly equivalent under the protocol), not merely “already processed.”

### RECEIPT-02 — Receipt/result corruption

Receipt claims processed command but durable response reference is missing/corrupt.

Runtime raises an integrity fault/resync path rather than re-executing mutation.

### RECEIPT-03 — Reused idempotency identity with different command

A previously committed Command ID/invocation identity is submitted again with a different semantic command payload.

The stored semantic-command digest does not match. Runtime rejects with an idempotency/integrity conflict; it neither executes the new payload nor pretends the old response belongs to the different request.

### PLATFORM-01 — Web adapter cannot grant entitlement directly

Attempt to mutate entitlement from Phoenix controller/channel without going through `loka_platform` application service/policy.

Architecture test fails.

### PLATFORM-02 — Entitlement service unavailable

Offline already-downloaded cartridge remains playable.

New purchase/restore may fail gracefully, while world simulation and unrelated online game instances remain isolated from the platform-service failure according to deployment topology.


## V. Client mode and builder target separation

### MODE-01 — Story Mode has no online world dependency

With all Loka online services unavailable, an installed offline-capable cartridge launches in Story Mode, plays, saves, and resumes.

### MODE-02 — Realm Mode has no local authority fallback

Realm Mode loses server connectivity during authoritative play.

It does not continue mutating a local authoritative copy. It reconnects/resyncs or presents disconnected status according to policy.

### MODE-03 — Exactly one active gameplay authority

While a Story session is active, the user switches to Realm Mode.

The Story session commits/closes before RemoteRealmSession becomes active. No world/save is simultaneously authoritative locally and remotely.

The reverse transition has the same guarantee.

### MODE-04 — Local rules execution cannot authorize Realm state

A modified client invokes whatever Story portable-rules implementation is embedded locally while connected to Realm Mode and fabricates favorable results.

BEAM ignores those results; only server-resolved ActionInvocations and committed Realm decisions can mutate Realm state.

### MODE-05 — Shared GameView parity

Equivalent portable cartridge state rendered through LocalStorySession and an online-private RemoteRealmSession yields semantically equivalent GameView action/quest/dialogue visibility.

Presentation chrome may differ.

### MODE-06 — Realm code cannot mutate Story saves

Realm session/social/transport code attempts to write a Story save or local world revision.

Architecture/boundary test fails.

### MODE-07 — Story authority cannot bypass Realm transport

Story/local authority code attempts to mutate Realm character/economy/session state.

Architecture/boundary test fails.

### MODE-08 — Realm-specific UI is not on Story critical path

Guild/presence/shard services are unavailable or uninitialized.

Ordinary Story Mode launch/play remains functional.

### MODE-09 — App update preserves offline saves while Realm evolves

An app update changes Realm protocol/client features but leaves a supported Story save installed.

The Story save still opens through the documented portable-rules/rule-IR compatibility path.

### MODE-10 — Optional Story account, required Realm account

A legitimately acquired cartridge remains playable in Story Mode while signed out/offline.

Entering Realm Mode requires authenticated online identity and server-checked prologue prerequisites where configured. The historical title refers to an optional active login during installed Story play, not optional account support in the first public release. R12A/ACCOUNT-01–12 govern launch identity and completion tracking.

### BUILDTARGET-01 — Story rejects server-only capability

A `story` workspace attempts to add `guild_market@1` or another server-only capability.

Compilation fails with a portability/target diagnostic.

### BUILDTARGET-02 — Realm permits server-only capability

A `realm` workspace may use a registered server-only capability and receives the corresponding multiplayer certification obligations.

### BUILDTARGET-03 — Realm state scope must be explicit

A realm quest/door/world event omits required multiplayer state scope where ambiguity exists.

Validation fails rather than defaulting to global.

### BUILDTARGET-04 — Promotion preserves source artifact

A `promote` workspace adapts a certified Story cartridge.

Original cartridge hash remains unchanged; promotion creates a new deployment/adaptation artifact and certificate.

### BUILDTARGET-05 — Promotion surfaces multiplayer questions

Promotion of a cartridge containing a permanently killable quest giver, unique loot, and player-local access facts returns structured required decisions for respawn, contention, and scope before shared-area certification can pass.

### ENTITLEMENT-01 — Local ownership is not Realm authority

The app has a locally cached verified Story entitlement and a modified local save.

Realm Mode may use server-verified entitlement/account rules to unlock content, but it does not grant competitive/persistent value from the local save or an unverified local ownership flag.


## W. Quest sharing, phasing, and scarce services

### SCOPE-01 — Personal progress in shared world

Players A and B share the same town and ferryman.

A accepts a player-scoped quest. B does not.

Only A's QuestInstance progresses while both continue to see/interact with the shared ferryman.

### SCOPE-02 — Party progress membership snapshot

A party activates a quest using snapshot membership.

A late joiner does not retroactively become an owner/recipient unless the definition explicitly allows it.

Leaving/rejoining cannot duplicate progress or rewards.

### SCOPE-03 — Party dynamic-present credit

A party quest using dynamic-present credit advances only eligible present members according to the objective's credit policy.

### SCOPE-04 — Instance-scoped puzzle

Two parties enter separate instances of the same dungeon.

Solving the puzzle in one instance changes only that instance.

### SCOPE-05 — Realm-scoped public event

A certified Realm event advances shared reconstruction progress once and is visible consistently to all eligible players.

### PHASE-01 — Personal quest NPC invisible to others

Player A is eligible for a quest apparition in a shared room.

A's GameView/search/action resolution includes it.

Player B's does not.

### PHASE-02 — Phased actor cannot leak shared effects

A player-scoped quest NPC dies and drops an item.

The drop remains player-scoped by default and cannot be looted or targeted by unrelated players.

### PHASE-03 — Lazy materialization survives cleanup

A personal quest actor is materialized while the player is nearby, then cleaned up after leaving.

On return, durable quest/fact state reconstructs the correct actor state without duplication.

### PHASE-04 — Shared NPC stays shared

Two players interact with the same shared smith NPC but have different trust/dialogue/quest actions.

Only one world NPC exists; per-player projections differ correctly.

### PHASE-05 — Overlay provenance

Developer/Lab trace can explain which shared/party/player layer caused a visible NPC, action, exit, or description variant.

### INSTANCE-01 — Private destructive branch

Player A destroys a bridge inside a private quest instance.

Shared Realm geography and Player B's experience remain unchanged.

### INSTANCE-02 — Instance reconnect

Player disconnects from a private/party quest instance and reconnects.

The correct instance identity and state are restored; a duplicate instance is not created.

### INSTANCE-03 — Instance teardown

Completed/expired private instance tears down ephemeral entities while explicitly exported rewards/memories survive according to policy.

### SERVICE-01 — Shared service slot race

Two Realm players submit requests for the only available slot on a shared service concurrently. The smithy forge case is one fixture.

Exactly one order receives that slot; the other is queued/rejected according to policy.

### SERVICE-02 — Same-authority ServiceJob input escrow

When the requester inventory and service aggregate are owned by the same mutation authority, submitting a sword order moves required materials into escrow atomically with capacity allocation/ServiceJob creation.

Crash at every boundary cannot duplicate or lose inputs. Cross-authority custody uses SERVICE-10 instead.

### SERVICE-03 — ServiceJob completion exactly once

Scheduler retries the completion job after a crash.

Sword output is created/claimed once and the completion DomainEvent is idempotent.

### SERVICE-04 — Personal quest observes shared ServiceJob

Player A's personal quest requires the sword.

Player B also uses the same smithy.

Only completion of A's eligible ServiceJob progresses A's quest.

### SERVICE-05 — Capacity semantics are precise

Content declaring one start per day behaves differently from one concurrent one-day slot and one completion per day, and certification fixtures prove the selected rule.

### SERVICE-06 — Queue persists through restart

Realm service/ZoneShard restarts with queued and active ServiceJobs.

Queue order, reservations, escrow, and scheduled completion remain correct.

### SERVICE-07 — Story overnight forge

Story Mode submits an overnight order, app closes, and the cartridge's declared time policy is applied on resume.

The order completes or remains pending deterministically according to real-elapsed/play-time policy.

### SERVICE-08 — Cancellation and refund

Cancelling a queued/in-progress order applies the configured cancellation/escrow/refund policy once and cannot be exploited for material duplication.

### SERVICE-09 — Queue abuse limits

A character/account attempts to monopolize the smithy with excessive queued orders.

Configured max-outstanding/admission policy is enforced transactionally.

### SERVICE-10 — Cross-authority input escrow

A realm-wide service reserves scarce capacity while a required item is still owned by another authority domain.

Crashes/retries are injected before and after reservation, custody transfer, acknowledgement, and ServiceJob activation.

Recovery yields exactly one of: the requester still owns the item with no active consuming job, or the service owns/proves custody with one valid job. The item is never duplicated, lost, or spendable under both authorities, and stale provisional capacity is eventually released/reconciled.

### SERVICE-11 — Period boundary semantics

Two otherwise identical services declare `1/day`, but one uses a rolling 24-hour window and the other uses a fixed world-calendar day.

Requests near the boundary produce the intentionally different certified outcomes. Story and Realm hosts agree because the policy declares time basis, window kind, and anchor/calendar semantics rather than reading device/server local midnight implicitly.

### MIXED-01 — Personal quest + shared bottleneck + phased NPC

One quest simultaneously uses:

- player-scoped progress;
- shared service using the smithy fixture;
- player-beneficiary ServiceJob;
- player-phased quest apparition;
- shared town geometry.

All scopes remain independent and correct.

### MIXED-02 — Promote Story smithy to Realm

A portable Story cartridge with local overnight smithing is promoted.

Promotion explicitly chooses whether Realm deployment uses personal capacity, an instanced service, or a genuinely shared service queue and runs the matching certification gates.


## X. Composable world primitives and classic-MUD conformance



### ACTIONRECIPE-01 — Builder-defined verb without engine code

A cartridge defines ring-bell as an ActionRecipe over an InspectableDetail.

The action emits typed narration + temple/bell_rung DomainEvent and drives a ReactionRule/quest objective identically on Story and Realm hosts without adding a bespoke engine command.

### ACTIONRECIPE-02 — Composed action cost/check/retry

A search-rubble ActionRecipe consumes an allowed resource cost, performs a deterministic Check, and reveals a clue on success.

Retry after an unknown response cannot charge twice or reveal twice; all operations are registered and bounded.

### TARGET-01 — Deterministic target ambiguity

Two visible targets share the same player-facing alias.

Text input resolves to an explicit ambiguous result with stable candidates rather than random/first-source-order selection. An explicit ordinal/disambiguation then produces one ActionInvocation, which authority revalidates.

### TARGET-02 — Touch and text target parity

Touch selects a stable target ID while text resolves an alias to the same entity.

Both paths resolve to the same semantic Command and outcome.

### DETAIL-01 — Inspectable detail without entity inflation

A room contains a mural InspectableDetail with aliases and a fact-dependent description.

Look/examine can target it through TargetResolution, but it has no fake inventory/location identity and does not appear as a RuntimeEntity.

### BARRIER-01 — Bidirectional barrier coherence

North and south room faces reference one logical gate.

Opening/locking/damaging the gate from either side changes one Barrier state and both projections agree after commit/reconnect.

### AREA-01 — Authored area is not authority placement

One AreaDefinition is hosted across two Realm ownership domains in a test deployment, while a second deployment hosts several small areas under one WorldInstance/ZoneShard.

Content semantics do not depend on AreaDefinition == ZoneShard.

### POP-01 — Population provenance-safe replenishment

A PopulationPlan creates two wolves. One dies; a player drops an unrelated item and a quest mutates a nearby NPC.

Reconciliation may replenish the owned wolf population but cannot delete/reset the unrelated item/NPC/quest state.

### POP-02 — SpawnBundle explicit nesting

A captain SpawnBundle creates equipment, inventory, and an item inside a container.

All references are explicit and deterministic; there is no hidden previous-spawn context.

### POP-03 — Scoped population cap

The same population definition uses different player/instance/realm count scopes in certified fixtures.

The cap is applied only in the declared scope; no accidental global max-existing behavior appears.

### BEHAVIOR-01 — Deterministic intent conflict

An NPC is simultaneously eligible to patrol east, flee west, and assist an ally.

Registered arbitration semantics choose the same intent on every host independent of content file order.

### BEHAVIOR-02 — No implicit wandering

An NPC with no locomotion behavior remains in place indefinitely unless moved by another explicit rule.

### REACT-01 — Typed reaction replaces special procedure

A fact/event triggers a ReactionRule that changes guard behavior, emits narration, and opens an allowed action.

The reaction uses typed consequences through the bounded decision chain and has no persistence/transport callback escape hatch.

### REACT-02 — Reaction cycle bounded

A pair of custom events/reactions would recursively trigger each other.

Compile/runtime cycle/budget handling rejects or terminates deterministically without runaway event production.

### NARRATE-01 — Actor/target/observer projection

One social/interaction outcome produces different localized actor, target, and eligible-observer text from one NarrationSpec without changing game semantics.

### COMMERCE-01 — Atomic immediate purchase

A merchant with hours, admission policy, stock, price policy, and currency sells the final finite item.

Payment + stock/item transfer commit once; concurrent/retried purchase cannot duplicate item or currency.

### COMMERCE-02 — Merchant buys under policy/liquidity

Player attempts to sell accepted, rejected, and over-liquidity items.

SellAcceptancePolicy and LiquidityPolicy produce deterministic results without bespoke shopkeeper code.

### COMMERCE-03 — Quest changes merchant world behavior

Quest outcome changes a durable fact/reputation.

Merchant catalog, price, or admission changes through derived policy/reaction semantics; the quest does not directly rewrite merchant internals.

## Y. Quest scenes, dreams, cutscenes, and scripted world events



### INSTANCEPLAN-01 — Interactive dream reuses generic instance semantics

A quest launches a dream using SceneSequence + InstancePlan over precompiled rooms.

The player may move, inspect, talk, fight or solve a puzzle between scene beats through
ordinary Actions/Commands. Dream entities/population obey normal instance invariants and
only declared exports survive teardown.

### INSTANCEPLAN-02 — Same plan machinery supports non-dream dungeon

A party dungeon and a player dream use the same InstancePlan lifecycle/entry/reconnect/
teardown contracts with different content and audience policies.

No dream-specific persistence or spatial authority path exists.

### INSTANCEPLAN-03 — Runtime cannot invent uncertified room definitions

A script/scene attempts to create a brand-new arbitrary room schema at runtime.

Validation/runtime refuses it; InstancePlan may instantiate only compiled definitions or
registered bounded generation semantics explicitly supported by a capability.



### INSTANCEPLAN-04 — Shared singleton is not cloned into instance

An instanced dream/dungeon room references a Realm-unique NPC/service outside its declared
instancing closure.

The compiler/runtime requires an explicit supported import/binding or rejects the plan.
It never silently creates a second authoritative copy.

### INSTANCEPLAN-05 — Player-owned item is not duplicated by entry

A player enters an InstancePlan while carrying a unique sword.

Entry/reconnect/teardown preserve one authoritative custody/ownership path. The sword
cannot exist simultaneously in the parent world and as an independent deep-copied
instance item.

### INSTANCEPLAN-06 — Temporary state exports only through declared contract

Player acquires dream-only temporary objects and one declared narrative memory.

On teardown, temporary objects disappear with the instance. The declared memory exports
exactly once. No other instance-local state leaks back.

### SCENE-05 — Scene actor binding survives reconnect and duplicate definitions

Two runtime NPCs share the same definition/display alias in different scoped spaces.

A scene binds `old_master` to the eligible instance-local actor at start. After reconnect,
the next beat targets the same runtime actor; it does not re-resolve by name/definition
and jump to the other copy.

### SCENE-06 — Missing bound actor follows explicit policy

A bound scene actor dies/disappears before a later beat.

The scene follows its declared wait/branch/fail/substitute/rebind policy. It never silently
selects another matching NPC.

### SCENE-01 — Text cutscene survives crash

A consequential text SceneSequence crashes after a checkpoint and before the next acknowledgement.

Resume restores the exact SceneInstance beat; already committed narration/consequences are not re-applied.

### SCENE-02 — Choice idempotency

Player chooses one branch, response is lost, and the same choice ActionInvocation is retried.

Exactly one scene branch/outcome commits and downstream quest/world consequences occur once.

### SCENE-03 — Modal/restricted authority enforcement

During a restricted scene, client attempts an ordinary action hidden by the scene ActionSet restriction.

Authority rejects/revalidates it even if a modified client sends it directly.

### SCENE-04 — Skip policy preserves semantics

A skippable presentation-heavy cutscene is completed normally and through skip.

Both paths reach the definition's declared equivalent semantic checkpoint/outcome while optional presentation beats differ.

### DREAM-01 — Private dream isolation

Player enters a dream using SceneSequence + SceneSpace `instance` backed by an InstancePlan.

Dream-only entities/items/actions never become shared Realm state. On completion, only declared typed memory/fact/relationship consequences export exactly once.

### DREAM-02 — Dream resume

Story app closes or Realm player disconnects mid-dream.

Resume restores the correct participant/SceneInstance state or follows the declared abandonment/restart policy without duplicating dream consequences.

### QUESTSCENE-01 — Quest milestone starts scene

A quest objective reaches a named milestone that starts one SceneSequence.

Duplicate delivery/retry does not start a second scene. Scene completion emits a typed event that advances the intended objective/outcome.

### QUESTSCENE-02 — Scene mutates world through typed consequences

A cutscene choice results in a named quest outcome that changes a Fact, relationship, Barrier state, NPC behavior profile, and merchant availability.

Same-authority changes commit atomically where applicable; no scene/quest directly edits component storage.

### QUESTSCENE-03 — Branches leave visibly different worlds

Lab forks before a quest branch and completes both paths.

World-state comparison shows the intentionally different facts, NPC schedules/relationships, access, population/ambient/merchant behavior, follow-up quests, and narration projections.

### WORLDEVENT-01 — Multi-phase scripted event

A WorldEventPlan drives a festival/invasion fixture through phases using PopulationPlans, schedule changes, services/commerce, scenes, and quests.

Every phase transition is typed, replayable, and deterministic; the plan is not a new mutation authority.

### WORLDEVENT-02 — Quest contributes to shared event without owning it

A player/party quest contributes typed progress to an instance/realm WorldEventPlan.

Quest progress scope, event progress scope, participant credit, and scene audience remain explicit and independent.

### SCENE-MP-01 — Shared scene does not block shard

One party runs a barrier-synchronized scene while unrelated players continue using the same ZoneShard.

Disconnected participant handling follows declared scene policy; the shard itself remains responsive.

### NARRATIVE-TRACE-01 — Unified explainable story trace

Cartridge Lab can trace:

~~~text
ActionInvocation
 -> Command
 -> DomainEvents
 -> quest objective/milestone
 -> SceneSequence beat/choice
 -> quest outcome
 -> world consequences
 -> ReactionRules
 -> resulting GameView
~~~

so a builder can explain why the story/world changed without reading arbitrary runtime script state.


## Z. Release assurance and orchestrated role boundaries

### CERT-01 — Frozen-candidate evidence binding

Full certification begins on semantic hash H1.

Content changes to H2 after some gates pass.

H1 receipts cannot certify H2; affected gates rerun against H2 and the final certificate
binds one exact evidence bundle/candidate hash.

### CERT-02 — Coverage gap blocks required branch

CoverageManifest shows one required quest outcome/SceneSequence terminal branch was never
exercised or proven reachable.

Release remains blocked until the branch is exercised/proven or explicitly reclassified
under reviewed certification policy.

### CERT-03 — Exhaustive claim requires actual exhaustion

A small finite quest/scene model is fully enumerated and may report exhaustive coverage.

A large bounded search reports its actual limits/path/seed counts and must not label "no
failure found" as exhaustive proof.

### CERT-04 — Mutation sensitivity

A disposable mutant removes a quest prerequisite and another breaks Barrier coherence.

The designated gates fail. If a mutant survives the gate expected to catch it, the
certification/test suite itself is deficient and release blocks until addressed or
the sensitivity obligation is explicitly revised.

### CERT-05 — Model-generated adversarial case becomes deterministic evidence

An LLM proposes a strange legal action/timing sequence that may soft-lock a storyline.

The proposal alone changes no verdict. Lab converts it into typed state/actions/time/fault
inputs, executes it deterministically, and stores either a counterexample regression or a
passing scenario receipt.

### CERT-06 — Semantic reviewer cannot waive mechanical blocker

Semantic reviewer says a cartridge looks coherent while a deterministic invariant reports
duplicate unique reward.

Candidate remains failed.

### CERT-07 — Fast Jev triage failure degrades safely

Optional Jev-style triage is unavailable, stale, low-confidence or malformed.

No mandatory evidence disappears. Certification falls back to deterministic/full-review
routing and cannot become easier to pass.

### CERT-08 — Evidence bundle explains pass

Given a release certificate, an operator can resolve every mandatory gate to exact
candidate/profile/check identity, coverage/exploration evidence, semantic finding
disposition and relevant repro artifacts.

A green summary with missing underlying required evidence is invalid.

### FOUNDRY-01 — World builder cannot edit engine

An orchestrated world_builder assignment receives Builder/Lab capabilities for L3–L6.

It attempts engine-source modification or arbitrary shell use.

The operation is unavailable/denied by the admitted role surface; no candidate engine
change is created.

### FOUNDRY-02 — Missing capability escalates without grant expansion

A quest builder requests a mechanic not expressible by registered primitives.

Builder returns MISSING_CAPABILITY/CapabilityProposal. The builder's existing grant is
unchanged. Any engine-capability task requires a separate protected assignment.

### FOUNDRY-03 — Same model different role does not share ambient authority

The same model identity is used first as world_builder and later as engine developer.

Each assignment receives only its admitted role surface. Credentials/tool access from the
engine assignment are not ambiently available to the world-builder assignment.

### FOUNDRY-04 — Role rename does not fake independent review

A model that authored a frozen candidate is relaunched under a different role label/session
and attempts to satisfy an independence-required semantic review.

Protected orchestration rejects the independence claim from durable principal/candidate
lineage.

### FOUNDRY-05 — Reviewer cannot mutate candidate

Semantic reviewer discovers a broken scene and tries to fix the workspace directly.

Review surface is read/simulate/comment only. It returns findings; correction requires a
separately authorized author assignment and renewed exact-candidate evidence.



### CERT-09 — Area passes alone but fails mounted closure

Area A's isolated fixture passes all local quest/path/population checks.

When mounted next to Area B, a duplicate target alias makes a required text action
ambiguous and a cross-area schedule route closes at night.

Mounted dependency-closure certification catches both; area isolation cannot certify the
release.

### CERT-10 — Impact analysis cannot waive mandatory release gate

A builder changes a quest outcome FactSpec and ImpactSet initially appears small.

Protected release policy determines that consumers/reactions/branch world comparison must
rerun. The author/model cannot reuse stale receipts merely by claiming the change is local.

### CERT-11 — Long-horizon leak detection

A PopulationPlan/merchant/restock interaction is correct for two days but slowly creates
unbounded items/currency over 90 simulated days.

Frozen-candidate soak certification detects invariant growth and blocks release.


### CERT-12 — Candidate cannot self-report coverage

Cartridge source claims a required branch is covered/excluded, but trusted Lab receipts
show it was never exercised/proven and the profile does not authorize the exclusion.

Generated CoverageManifest records the gap and release remains blocked.

### CERT-13 — Model cannot invent a release invariant

An LLM adversarial tester proposes a scenario and says "this outcome should be impossible."

Lab executes the scenario, but the proposed expectation is not a registered/profile
invariant.

The result is retained as exploratory semantic evidence; it cannot fail or pass the
release until the property is separately reviewed/admitted.


### CERT-14 — Opaque dependency widens impact set

A changed Fact/event is consumed through a dynamic script/selector edge that static
analysis cannot prove local.

Impact analysis marks the dependency boundary unknown and widens required authoring/
release checks according to policy. It never reuses stale downstream receipts on the
assumption that no static edge means no dependency.


### CERT-15 — Friendly cartridge tests cannot replace mandatory gates

A cartridge ships custom scenario tests that all pass but omits the failure path that
duplicates a unique reward.

Engine/profile mandatory invariant and mutation-sensitivity gates still run and fail the
candidate. The cartridge's green custom suite is supplemental evidence only.

### CERT-16 — Commercial semantic reviewer cannot own the candidate

For a commercial release profile requiring independent semantic review, the candidate-
authoring principal attempts to submit the semantic review under a new model/session/role.

Independence validation rejects it from durable candidate/principal lineage; a separate
review assignment must inspect the frozen candidate.

### CERT-17 — Unknown gate applicability fails conservative

A frozen candidate contains a semantic surface whose certification-registry applicability
cannot be resolved because of an unknown/dynamic dependency.

Certification does not silently classify the relevant gate as unnecessary. It widens the
required evidence set or blocks for explicit certification-policy disposition. Candidate
metadata cannot mark its own hard gate inapplicable.

### CERT-18 — Conformance breadth is not product certification

The synthetic R9C conformance cartridge passes broad architecture/invariant coverage.

A separate R10 Story cartridge does not inherit release approval from R9C, and R10 is not
forced to include an unused merchant, dream, ServiceJob, PopulationPlan, or other mechanic
merely because R9C exercises it.

R10 certification selects the mandatory gates implied by its own frozen semantic surface,
profile, and release level while shared engine invariants remain covered by the regression
corpus.


## Audit follow-through acceptance cases

### RECEIPT-04 — Replay before current-world validation

Commit take/choice/purchase, lose its response, then retry through an authorized new session/route with a stale view and consumed target/offer. Replay the original semantic outcome before current legality checks; no second mutation/RNG/effect. The current GameView remains current. Revoked/foreign actor access is denied before receipt disclosure.

### RECEIPT-05 — Changed intent is not a retry

Reuse invocation identity with changed actor/target order/input/price constraint or semantic continuation binding: integrity conflict. Changes only to connection, diagnostic sequence, routing and pure freshness metadata do not alter intent. A semantic offer token is not excluded merely because its name contains "token".

### ATTEMPT-01 — Valid failed roll versus rejected attempt

A valid 50% attempt that fails commits its next RNG state and failure receipt. Matching retry makes no draw; a new invocation follows the next deterministic draw. An unavailable action or definite rollback does not advance game RNG/time/resources. Retrying a receipted terminal rejection replays the chosen terminal result.

### RECOVERY-01 — Missing acknowledgement does not prove rollback

Lose COMMIT acknowledgement while the original transaction is still unresolved. Fence new decisions; an initially absent receipt is not permission to rerun. Test both eventual commit and eventual rollback on the real store. Committed disposition reloads and replays; only confirmed non-commit permits retry of the same identity.

### QST-31 — Activation and knowledge are different from historical events

The hello fixture activates before acquisition. Its negative control acquires before activation and receives no retroactive event credit; an explicit current-state variant does credit possession. In chapter one, Q2 consumes the knowledge/fact established by Q1 rather than demanding Q1's already-consumed dialogue event again.

### PROOF-01 — Proof does not shrink the first release

R6P is a separate cartridge/save lineage on the fresh engine. Its device/human evidence does not certify chapter one. The full release retains 57 rooms, ten quests and two endings and all applicable feature gates. Python specification checks alone cannot satisfy R6P/R1/R10.

### SCOPE-02 — Capability families do not imply every later feature

Immediate ferry/shop operations trigger transactional tests now; they do not trigger unimplemented ServiceJob escrow. Conversely, a future artifact that actually uses escrow or an unknown dynamic feature cannot skip its gate using chapter-one labels or candidate-controlled metadata.

### TOPOLOGY-01 — Transport and conditional reachability

The 57-room chapter's island is reachable through the ferry, not ordinary exits alone. Separately test payment, schedule, policy and return travel under declared scenarios. Do not label a structurally linked but unaffordable/never-available required target playable, or impose six-direction reciprocal exits on all future engine connections.

## Account and prologue progress acceptance

Governing contract: [document 23](23-accounts-progress-admission.md); ADR-063. These require real implementation evidence at their phase, not merely a specification-model pass.

### ACCOUNT-01 — Launch identity and offline independence

The first free public build offers accounts, recovery/deletion and completion synchronization. Finish/resume an installed story with expired credentials or an unavailable service. Only sync waits; local gameplay succeeds. R6P may use a fake adapter; it does not discharge the real R12A gate.

### ACCOUNT-02 — Atomic completion and report capture

For both chapter-one endings, crash before/during/after the terminal dawn commit. Either the outcome and milestone/pending report are all absent, or all durable. Credits display is not the trigger. A restored backup requeues safely. Test real local transactions; model atomic assignment is insufficient.

### ACCOUNT-03 — Duplicate reports and lost acknowledgement

Repeat the same authenticated report after server acceptance loses its response. Replay its stable receipt and credit once. Changed canonical payload under the same ID conflicts; a new ID for the same bound run/milestone also cannot credit twice. Conflicting terminal outcomes are visible conflicts.

### ACCOUNT-04 — Authenticated binding and account switching

Account A records a completion, signs out, and account B signs in. The pending upload remains bound to A; server rejects access/reassignment by B. Payload account IDs do not authenticate. Guest claiming, if offered, consumes an unclaimed run once and cannot transfer an already-bound run.

### ACCOUNT-05 — Multi-device non-regression

Accept completion on one run/device, then receive older starts/checkpoints from another and restore/reset/delete a local save. Account completion remains true. Separate run state from completed-at-least-once; client timestamps and last-write-wins do not determine completion.

### ACCOUNT-06 — Onboarding-only evidence

A known approved offline completion may satisfy an onboarding prerequisite. Unknown release/milestone/outcome, arbitrary unlock flags, oversized/unknown fields, caller-selected server evidence and currency/XP/purchase payloads fail. An offline report cannot satisfy a requirement restricted to stronger evidence.

### ACCOUNT-07 — Equivalent prologues and account-wide admission

Approved old/new prologue release milestones can satisfy one stable requirement. Both intended endings qualify without side-quest completion. The same account need not repeat onboarding for each Realm character. An unapproved R6P proof or arbitrary content-declared requirement grants nothing.

### ACCOUNT-08 — Realm entry is server-owned

Forge a client unlock cache; join/rejoin with a missing requirement, withdrawn evidence, unknown policy or stale progress version. Server denies or requests a fresh decision before attaching gameplay. Test progress/policy change at admission; do not trust the UI or bypass on resume.

### ACCOUNT-09 — Deletion serializes against ingestion

Delete the account while a report is queued or in flight. Revoke authentication, recheck lifecycle at acceptance commit, and prevent old reports/credentials recreating progress. A new account with the same email is distinct; old bound reports are not implicitly guest-claimed. Local save disposition is explicit.

### ACCOUNT-10 — Synchronization is not save backup or analytics

On a new device, read accepted completions without claiming the full game save is restored. Admin state distinguishes no report from known incomplete activity. Sampled/lost analytics cannot erase or grant admission; offline completion remains unknown until received.

### ACCOUNT-11 — Withdrawn acceptance stays withdrawn on replay

Explicitly withdraw a record through an authorized correction. Retry its old report: historical receipt may replay, but eligibility uses the current effective record and stays withdrawn. Ordinary cartridge updates, report order and save resets cannot implicitly revoke prior accepted completion.

### ACCOUNT-12 — Launch scope cannot be deferred to paid or Realm phases

Before public free Story release require R12A real authenticated sync/storage/lifecycle/device evidence. R13 reuses its database/accounts; R14/R15 add admission. Pure Lab and R6P do not require production identity, but both test local milestone/retry behavior. No account gameplay StateScope is introduced.

## Readiness closure: initial composition and run lifetime

These scenarios extend existing RECEIPT/ATTEMPT/QST/COMPAT/ACCOUNT families without replacing their known answers. The new Python examples cover only the explicitly listed abstract contracts; all host/UI/save evidence remains required at its owning milestone.

### COMPOSE-01 — Root sequence, FIFO and semantic ordering

Emit an event then change the root overlay. A current-overlay guard observes the completed root sequence; an event-payload guard observes the earlier payload. Child events append behind already queued events. Reordering source files/rule input order does not change canonical registry dispatch; reversing an explicit operation sequence does change semantics. Two distinct events are not deduped as one transaction delivery. Evidence: composition known answers now; selected-host bytes at R1, compiled expansion/source maps at R3/R4.

### COMPOSE-02 — Activation position precedes credit

Emit acquisition before activation, then activate before dispatch. Strict event credit is denied. Activate then emit permits credit. Explicit current-possession credit recognizes an earlier-acquired item without replaying history. Preserve Tiny's separate event/state cases and R6P's declared possession intent. Evidence: model cases now; actual narrative/reaction integration at R7/R6P.

### COMPOSE-03 — Independent conflicts and aggregate invariants

Opposite or identical independent assignments cannot use registry order as last-writer-wins. Explicit same-group legal transitions may compose. Competing destinations cannot duplicate an item; different items still obey container capacity and acyclic containment. A mid-sequence fault leaves all input state unchanged and publishes no provisional event. Source-map diagnostics identify both writers. Evidence: bounded model examples now; actual operation registry, conservation properties and SQLite commit faults at R3/R5/R6.

### COMPOSE-04 — Shared fuel and legitimate waiting

A child reaction cannot reset aggregate fuel. Immediate cycles exhaust a declared cap with full rollback. Selector all-matches overflow fails, never silently truncates. New jobs must be later than current time, or later than the requested target during a bounded advance. Pending jobs, due jobs, created jobs and automatic scene advances each have caps; an already-true wait cannot escape to fresh fuel forever. Legitimate cycles across new external inputs still work. Evidence: selected abstract budget/job/selector cases now; real advance/scene/scheduler and fairness cases at R1/R7/R8.

### COMPOSE-05 — Engine events and author authority

Unknown operation/policy/event/scope fails closed. Declaring the schema of an engine-owned event does not grant emission permission. Unknown capability produces an actionable escalation, not generic state writes or engine-source access. Preview leaves live RNG/state unchanged and private-state diagnostics are redacted. Evidence: abstract unknown-operation/policy/emission checks now; compiler/grants/preview/security at R3/R4/R11.

### COMPOSE-06 — Lantern choice recovery

Run both frozen four-place traces. Test early pickup, dropping the item, Bram moving, closing a stale interaction, duplicate/altered choice IDs and stale NEW views. Crash before commit, after commit before memory, and before narrative display. Recover one coherent narration/milestone without repeating transfer or resurrecting a consumed choice. General evaluator integration must match the hand-authored cases; a special story-specific Python model is not P4/P6 completion. Evidence: model examples now; real compiler/SQLite/mobile/human proof at R6P.

### RUN-01 — Reading and absence do not advance default Story time

Read slowly, resize text, view history, background and return after a week. Default Story clock/RNG/consequences do not advance. Explicit action costs/wait do; a later real-elapsed profile is disclosed and separately certified. Evidence: abstract look check now; actual lifecycle/UI at R6/R12.

### RUN-02 — Bookmarks and package retention

Create three named bookmarks, update the app, and run package garbage collection offline. Current save, bookmarks and recovery copies retain every required release/capability dependency. A deliberate old-branch restore creates a new lineage; same-state recovery/retry does not. A completed-account badge is not treated as a backup. Evidence: real storage/package/UI integration at R6/R12, not implemented by this model amendment.

### RUN-03 — Interrupted migration and missing dependency

Inject failure before/after migration staging, validation and atomic head adoption. The original save remains recoverable; no partial new head is used. Missing packages or unsupported versions preserve the working run and produce a precise recovery error. Every released public save/continuation shape has a fixture before breaking app release. Evidence: real local migration/release compatibility tests at R6/R12.

### RUN-04 — Hostile export import and privacy

Export contains no tokens or purchase grant. Import malformed/oversized/unknown-version/cross-account payloads in isolation; no live head changes before validation. A valid checksum is not honest-play evidence. A blank device lacking the cartridge receives a dependency error rather than a false offline-restore promise. Evidence: real import/security tests before first public Story release at R12.

### RUN-05 — Forked milestones retain provenance

Restore a bookmark with already accepted or pending milestone history. Preserve the original occurrence/report/run/account identity for inherited history; genuinely new post-fork occurrences use the new run. Do not regrant, rebind, resurrect deleted accounts/withdrawn eligibility or let report order choose the campaign branch. Extend ACCOUNT-01–12 with actual restore/fork integration at R6/R12A; existing account-model passes alone are insufficient.

### RUN-06 — Optional snapshot backup divergence

Only when backup is delivered: concurrently continue two offline snapshots, upload out of order, delete/replace a backup and replay stale uploads. Preserve divergent branches and use causal latest-pointer checks; no last-writer-wins world merge or resurrection. Quota/outage does not erase the only working local state or disable offline play. Evidence: optional-backup integration/release tests, not an R1/R6P prerequisite.

### READY-01 — Incomplete setup cannot authorize candidate work

The checked-in empty setup template and actual pending setup must fail both `--require-ready --stage A1` and `--stage A2`. Default readiness remains A2/full-native. A1 requires accepted R0 contract/cutover rule, exact seven retained inputs, identified authors, independent oracle and stage-bound setup reviews, actual execution-host details, Node/TypeScript/Elixir/full-OTP versions and retained reproducible lock evidence. Unknown native/device details may remain null only at A1. A2 additionally requires complete native/physical inventory and approved common host; iOS qualification is explicitly iPhone 11/4 GB, not inferred SE 2/3 GB support. Reject cross-stage approval reuse even with full fields, malformed deferred entries, changed hashes/configuration, unknown stages/fields/statuses, version ranges and self-review. A complete synthetic temporary record tests structure only; it is not hardware, identity or R1 evidence. Evidence: both-language stage-gate tests now; actual stage-appropriate independent approvals at PREP-02.

### READY-02 — Gate separation and candidate selection

Owner-approved thresholds plus green Python checks cannot become selected runtime, production-repository authorization, physical-device pass, store approval or chapter release. C receives all applicable actual-host gates. Failures remain visible; B and then A are evaluated only in order and unmeasured candidates are not ranked. R0/R1/R2 records are distinct, with exact cutover authority. Evidence: reviewed setup/result/selection/cutover records at PREP-02/R1/R2.


### COMPOSE-07 — Due-set cancellation and reaction visibility

An explicit advance includes job A followed by job B. A's reaction cancels B's snapshotted occurrence or reschedules it beyond the target. The authority drains A's reactions before testing B's current occurrence/generation; B's stale snapshot entry does not run. Also test a later job reading a fact established by an earlier job's reaction, shared budget exhaustion after an earlier job, and conflicting independent writes. Faults preserve the entire pre-advance state/time and expose no partial receipt. Evidence: actual scheduler/capability conformance at R1/R6/R8 as applicable; the current Python scheduling-operation example does not implement this scheduler.

# 23 — Accounts, Story Progress, and Realm Admission

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: first-release accounts and onboarding.

Start with the journey and three authorities. Completion sync is mandatory at public launch, full-save backup is optional, and offline reports are onboarding-only evidence.

<details>
<summary>Sections in this document</summary>

- [1. Player journey and launch requirement](#1-player-journey-and-launch-requirement)
- [2. Three authorities, no new gameplay scope](#2-three-authorities-no-new-gameplay-scope)
- [3. Declare completion once, independently of the platform unlock](#3-declare-completion-once-independently-of-the-platform-unlock)
- [4. Commit locally, synchronize later](#4-commit-locally-synchronize-later)
- [5. Minimal records and API boundary](#5-minimal-records-and-api-boundary)
- [6. Evidence policy: onboarding, not competitive rewards](#6-evidence-policy-onboarding-not-competitive-rewards)
- [7. Stable prerequisites and server admission](#7-stable-prerequisites-and-server-admission)
- [8. Multiple devices, progress views and analytics](#8-multiple-devices-progress-views-and-analytics)
- [9. Recovery, deletion and privacy](#9-recovery-deletion-and-privacy)
- [10. Roadmap and acceptance](#10-roadmap-and-acceptance)
- [11. Restored and forked run provenance](#11-restored-and-forked-run-provenance)

</details>
<!-- packet-navigation:end -->

**Status:** owner-approved product direction (2026-09-22); implementation contract candidate, not R0 acceptance or evidence of a running service.

## 1. Player journey and launch requirement

Loka provides user accounts and account-level Story milestone tracking in the **first public Story release, including the free chapter**. A player can complete introductory cartridges locally, synchronize their completion, and satisfy account-wide prerequisites for later Realm entry. This moves a small platform service forward; it does not move multiplayer simulation forward.

The full first chapter remains **57 rooms, 10 quests, and two endings**. R6P remains a smaller engineering/player proof on the from-scratch engine, not a replacement release.

Offer account creation early with the benefit explained. A local guest option MAY precede registration; it is not required to prove the kernel. An authenticated account is required for account synchronization and Realm entry. Requiring sign-in before initial acquisition, or offering guest-first play, is an explicit launch UX decision; neither may turn installed Story gameplay into an always-online product. Do not interpret launch-day accounts as a requirement to authenticate every game action.

## 2. Three authorities, no new gameplay scope

| Concern | Owner | Not allowed |
|---|---|---|
| Identity, account lifecycle, accepted progress | `loka_platform` with authenticated APIs and durable platform storage | A client-selected account ID is not authentication. |
| Offline game state and reached milestones | Local Story authority and transactional local storage | No account/network calls from portable decision rules. |
| Realm admission | Server-side deployment/admission policy using accepted account milestones | No client `unlocked` flag or raw save import. |

Account IDs, authentication credentials, network retries and server timestamps are host/platform metadata, not portable decision inputs or sources of gameplay randomness. Keep AccountId, local profile, StoryRunId/save lineage, and Realm CharacterId distinct. Account progress is **not** a fifth `StateScope` and is not a second authority over Story saves.

All intended completed endings qualify by default, including tragic endings. Side quests, collectibles and a particular moral choice are not prerequisites unless the product explicitly declares them. Completion means an authored terminal milestone, not viewing credits or tapping a client button.

## 3. Declare completion once, independently of the platform unlock

A cartridge declares versioned milestone keys and their rule-owned terminal conditions. Reaching a milestone produces a typed, deterministic `story.milestone_reached` DomainEvent and a durable milestone marker through the normal decision/commit path. The compiler validates its key, trigger, outcome coverage and capability dependencies. Existing narrative capabilities may own this operation; no general scripting or account capability is added to the portable kernel.

For chapter one, declare a single `prologue_completed` milestone after the committed `dawn_on_the_green` terminal consequence for either intended ending, not merely when both quests become eligible for the scene. Starting the run can similarly record `story_started`. Additional onboarding checkpoints are optional, with explicit definitions rather than inferred screen-view analytics. Save/restart before and after the terminal consequence must neither lose nor duplicate the milestone.

The exact field vocabulary freezes with the R3/R7 feature schema. `prologue_completed` is content semantics, not an instruction to grant a Realm entitlement. The R6P fixture has a separate release identity and is **not** implicitly approved as a production prologue.

## 4. Commit locally, synchronize later

```text
rule reaches declared milestone
  -> local transaction: gameplay result + durable milestone + pending report
  -> continue offline
  -> authenticated host synchronization when connected
  -> platform validation + accepted report in one server transaction
  -> server-side Realm admission checks accepted milestones
```

The local authority/store adapter persists the milestone and pending report with the gameplay outcome atomically. The host binds the local run to an account/profile outside portable semantics; no network call occurs inside the transaction. Account binding and pending delivery survive local crash/restore, but are excluded from canonical portable gameplay hashes.

Report identity is stable across retry and restore of the same milestone occurrence. A restored backup may requeue an already delivered report: server idempotency and per-run/milestone deduplication must tolerate it. Exactly-once application is not a claim of exactly-once network delivery.

On loss of connectivity, expired credentials or account-service outage, keep the report queued. Installed Story gameplay remains available under its entitlement policy. Retry with bounded backoff/batches when the app runs with connectivity; mobile background delivery is not guaranteed. Persist `pending`, `accepted`, and actionable `rejected`/`needs_attention` dispositions. Do not drop a completion silently after a retry limit.

A report accepted by the platform has its durable response recorded before acknowledgement. If the response is lost, retry returns that response without crediting twice. Local acknowledgement is also persisted; uncertain local/server commit recovery follows document 03 rather than assuming a timeout means rollback.

## 5. Minimal records and API boundary

| Record | Required meaning |
|---|---|
| Account | Server-owned, non-reused identity/lifecycle; authentication and recovery information only as needed. |
| Story run | Stable run/save lineage; exact cartridge release; local profile and eventual account binding; separate from a Realm character. |
| Local milestone/report | Milestone key, stable occurrence/report ID, run and release identity, permitted outcome, observed game revision, pending-delivery state. |
| Platform acceptance | Authenticated principal, canonical payload digest, exact recognized release/milestone, server receipt time, evidence source, acceptance-policy revision, durable result. |
| Admission rule | Versioned platform-owned requirement IDs and approved milestone equivalences for a deployment. |

Representative operations are bind/claim a run, submit a bounded milestone batch, read account progress, and evaluate admission. Freeze their strict schemas before use. Authentication supplies the account; an account label in a payload never grants authority. Reject unknown fields, oversized input, unknown release hashes/milestones, invalid outcomes and attempts to select a stronger evidence class. Do not accept arbitrary world-save blobs as progress reports.

The server enforces a run's immutable account association and exact cartridge release after registration/claim. Migrating a run to another release requires an explicit lineage/migration policy; a progress submission cannot silently repin it. Record an account binding in the local queue and verify it on upload. A report queued for account A must not be rebound to account B on sign-out/sign-in. Guest claiming, when supported, is explicit and transactional, consumes an unclaimed run once, and cannot relabel an already-bound run. Device-local ownership checks alone are insufficient; a guessed run identifier is not authorization. Device IDs alone are not recovery credentials.

A first-time offline report is still client-controlled evidence: binding/checks prevent accidental cross-account delivery and known-run reassignment, not a malicious client fabricating a fresh run. This limitation is acceptable only for the low-stakes policy in section 6.

Deduplicate by authenticated account lifecycle + report ID; a reused ID with a different canonical payload is an integrity conflict. Also enforce uniqueness of the accepted milestone per bound run so different report IDs cannot grant it twice. A semantic fork/new replay has a distinct run identity. Conflicting outcomes for the same terminal milestone require a visible conflict disposition, not last-writer-wins.

## 6. Evidence policy: onboarding, not competitive rewards

The initial platform accepts authenticated offline completion reports for explicitly designated **onboarding requirements only**. It labels them `offline_client_report`; acceptance is a policy decision, not proof of human reading, learning, honest device state or server-observed play.

Later evidence classes may be `server_replayed_trace` or `server_authoritative_run`. Only the corresponding trusted server workflow can assign them. An authenticated client cannot upgrade its own evidence class. Cryptographic package integrity or device attestation is not proof that a human played or understood the story. Deterministic replay can establish a valid submitted trace, not human attention.

No first-release server replay service, full command-log upload or new device-attestation requirement is introduced here. These reports **MUST NOT** import currency, inventory, statistics, XP, competitive achievements, purchase entitlement or other Realm value. Any future non-onboarding use needs a separately accepted product/security policy.

## 7. Stable prerequisites and server admission

Define stable requirement IDs such as `onboarding.loka_fundamentals@1`. Platform policy maps exact approved `(cartridge release hash, milestone key, outcome)` combinations to these requirements; an equivalently approved updated prologue can satisfy the same requirement without erasing the original evidence.

Begin with a bounded conjunction of named requirements; each requirement may have explicit alternative qualifying milestones/releases. No general policy language or progression platform is required. Validate unknown requirements, empty/malformed alternative sets and unknown evidence classes at deployment configuration time. An intentionally ungated deployment is explicit, not an accidental empty policy.

Realm admission MUST authenticate the account and evaluate its effective accepted records on the server. It returns eligible or a typed explanation of missing requirements, policy version and progress version. A stale client eligibility cache is never authorization. When progress changes during join, the admission boundary uses a coherent account/progress/policy version or rechecks before creating/attaching the Realm session. Define re-admission after disconnect; do not use client resume as a bypass. Changing a policy does not retroactively eject active players unless a separate revocation policy says so.

Requirements are account-wide by default, not repeated per character. Ownership of a cartridge and completion of a prologue are separate checks. Unknown/malformed policy fails closed for Realm entry, **not** for installed offline play.

Ordinary content updates and save resets do not revoke accepted completions. Withdrawal for fraud, correction or a materially changed onboarding requirement is a separate authorized, auditable policy operation. Replaying an old report returns its historical receipt but must not reactivate withdrawn eligibility. Admission always evaluates current effective records under the current declared policy.

## 8. Multiple devices, progress views and analytics

Store distinct playthroughs and derive **completed at least once** from accepted terminal milestones. Reports may arrive out of order; a late `started` or checkpoint from another run/device cannot overwrite completion. Replaying, rolling back, abandoning or deleting a local save does not erase account completion. Aggregate progress merges milestone membership, not game state or an untrusted device clock.

The library distinguishes `Completed on this device — sync pending` from `Completed — accepted on your account`. Before Realm entry, attempt bounded foreground synchronization and then check server eligibility. On failure, explain sign-in, pending synchronization or a missing prerequisite; do not tell the player to replay a story simply because its report has not arrived.

An administrative view distinguishes no run reported, in progress as last reported, and accepted completion, with server last-received time. **No completion reported is not proof of non-completion.** Offline activity may be unknown. A client-reported timestamp may be displayed with provenance but cannot resolve ordering or establish trustworthy duration.

Operational progress is not best-effort analytics. Authentication/admission uses the durable progress service, not an analytics pipeline. Optional analytics aggregates these records with appropriate disclosure and minimization. It does not require uploading private story prose, complete command logs or the world save.

## 9. Recovery, deletion and privacy

Account recovery restores access to accepted milestones, not necessarily the exact game save. Cloud-save backup remains separate and optional; divergent world states are not merged. A new device can show completed prologues without containing the original saved game.

Ship account recovery, sign-out and account deletion with the initial account feature. Deletion invalidates authentication and cancels account-bound upload eligibility. Old credentials/queued reports must not recreate deleted progress or bind to a newly registered account that happens to use the same email. Account IDs/lifecycle bindings are not recycled. Recheck lifecycle at server commit to serialize deletion against in-flight ingestion.

On reconnect, a deleted-account response stops that queue and prompts the user; it must not silently convert old account-bound reports into guest reports. Preserve or explicitly delete local saves according to a clearly disclosed user choice; do not silently erase them or silently upload them to another account. Local account/profile switching must protect access to private progress/history on shared devices.

The launch plan includes secure token storage, revocation/recovery handling, authenticated per-account access, bounded/rate-limited requests, TLS, data minimization, a retention/deletion policy, and current store/privacy review for the chosen sign-in methods. These are implementation/release gates, not fulfilled by this specification. Full traces are opt-in support evidence, not the default progress payload.

## 10. Roadmap and acceptance

| Phase | Obligation |
|---|---|
| R3 | Run/milestone/acceptance/admission contract envelopes; account binding stays host-side. |
| R6 | Atomic local milestone and pending report, persistent binding, retry/recovery. |
| R6P | Exercise offline completion/delayed sync with a fake adapter; production auth is not a proof dependency. |
| R7/R10 | Declare and test actual cartridge terminal milestones, including both chapter-one endings. |
| R12A (part of R12) | Real account lifecycle, platform database/API, progress acceptance/readback and administrative visibility before the first public Story release. May begin in parallel with R6/content work. |
| R13 | Add purchase/entitlement features to the existing platform/account foundation. |
| R14/R15 | Require server-side prologue admission where configured before public Realm entry. |

All existing top-level R labels remain stable. R12A is a subdivision, not a new release or permission to move Realm earlier. The free release requires account/progress evidence as well as R10/R12 game/device evidence; R13 still gates paid commerce.

The governing scenario family is [ACCOUNT-01 through ACCOUNT-12](15-acceptance-scenarios.md#account-and-prologue-progress-acceptance). The specification-model tests exercise policy, receipt and queue invariants only. Production authentication, real storage transactions/races, devices, privacy workflows and live Realm admission require separate implementation evidence.

## 11. Restored and forked run provenance

A semantic restore/fork creates a distinct run identity with an explicit parent snapshot and immutable account/release binding. It does not turn every inherited milestone into a new completion report. Preserve the original milestone occurrence/report identity and originating run/account lifecycle; retry already-pending historical reports under that identity, and read back existing acceptance instead of manufacturing a new grant. New milestones reached after the fork use the new run's identity.

Ordinary crash recovery and matching retries continue the same run. A migration changes only declared schema/release lineage under a reviewed migration policy; it cannot mint platform evidence or rebind an account. A guest claim consumes an actually unclaimed lineage once; an imported account-bound save cannot be claimed by another account merely because it was copied. The server's binding/lifecycle checks remain authoritative.

Completion-at-least-once persists despite local rollback/reset. Forked outcomes are separate playthrough history, not an integrity conflict within one run or an instruction to semantic-merge world state. Campaign continuation uses the player's selected branch, not report arrival order. Account deletion/withdrawal still wins over stale restored queues; restoration never resurrects eligibility. These rules complement the local export/bookmark contract in 10 §31–33 without treating offline reports as honest-play proof.

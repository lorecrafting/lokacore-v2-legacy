# 10 — Mobile, Commerce, and Release

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: app and release.

Separate offline play, free release, paid entitlements and later Realm. Review save compatibility and downloaded-content gates explicitly.

<details>
<summary>Sections in this document</summary>

- [1. One React Native client, two session modes](#1-one-react-native-client-two-session-modes)
- [2. Mobile structure](#2-mobile-structure)
- [3. Online connection lifecycle](#3-online-connection-lifecycle)
- [4. Offline launch lifecycle](#4-offline-launch-lifecycle)
- [5. Local state](#5-local-state)
- [6. One app, many cartridges, later Realm Mode](#6-one-app-many-cartridges-later-realm-mode)
- [7. Client/kernel feature negotiation](#7-clientkernel-feature-negotiation)
- [8. Catalog](#8-catalog)
- [9. Entitlements](#9-entitlements)
- [10. Purchase lifecycle](#10-purchase-lifecycle)
- [11. Offline entitlement policy](#11-offline-entitlement-policy)
- [12. Restore/refunds/revocation](#12-restorerefundsrevocation)
- [13. Initial monetization](#13-initial-monetization)
- [14. Store executable-code boundary](#14-store-executable-code-boundary)
- [15. Content delivery](#15-content-delivery)
- [16. Local package management](#16-local-package-management)
- [17. Cloud backup](#17-cloud-backup)
- [18. Offline versus online characters](#18-offline-versus-online-characters)
- [19. Narrative continuity](#19-narrative-continuity)
- [20. Release environments](#20-release-environments)
- [21. Cartridge rollout](#21-cartridge-rollout)
- [22. App binary compatibility](#22-app-binary-compatibility)
- [23. Mobile CI](#23-mobile-ci)
- [24. Deep links](#24-deep-links)
- [25. Privacy/data minimization](#25-privacydata-minimization)
- [26. Current technology feasibility note](#26-current-technology-feasibility-note)
- [27. Store-review gate for downloadable rule content](#27-store-review-gate-for-downloadable-rule-content)
- [28. App/kernel upgrades must not strand offline saves](#28-appkernel-upgrades-must-not-strand-offline-saves)
- [29. Account, entitlement, and mode boundary](#29-account-entitlement-and-mode-boundary)
- [30. First-public-release account gate](#30-first-public-release-account-gate)

</details>
<!-- packet-navigation:end -->

## 1. One React Native client, two session modes

Loka v3 ships one React Native / Expo application.

The app has two strict gameplay modes:

### Story Mode

Offline-first cartridge play. Uses `LocalStorySession`, the portable-kernel bridge, local SQLite, save slots, cartridge library, campaigns, and offline entitlement proof. First-release accounts and durable Story milestone synchronization are a separate host/platform feature under [document 23](23-accounts-progress-admission.md); no active login is required for installed offline play.

### Realm Mode

Online multiplayer/MUD play. Uses `RemoteRealmSession` over Phoenix/BEAM and renders server-authoritative GameViews. It has no local authoritative world save.

### GameSession boundary

Shared gameplay UI talks to a small session interface using host-neutral ActionInvocations, not directly to SQLite, Rust, Phoenix, Ecto, or internal Command structs.

Conceptually:

```text
start(context)
invoke(action_invocation)
current_view()
subscribe()
close()
```

The exact API may differ, but there MUST be one active authority implementation per gameplay session:

- `LocalStorySession`
- `RemoteRealmSession`

Mode-specific UI such as cartridge library or guild chat lives outside the common GameView canvas.

## 2. Mobile structure

Recommended:

```text
mobile/
├── app/                     # one Expo application / navigation shell
├── features/
│   ├── story/               # library, saves, local-session UX
│   └── realm/               # login, social, realm-session UX
├── authority/
│   ├── local-story/         # kernel bridge + SQLite authority
│   └── remote-realm/        # Phoenix transport + resync
├── packages/
│   ├── ui/
│   ├── game-view/
│   ├── localization/
│   └── generated/
├── native/
│   └── portable-kernel/
└── test/
```

Use lint/build architecture rules so shared packages cannot import either authority implementation.

The presence of the local kernel in the app binary does not weaken Realm authority because the server revalidates every Realm command and owns all committed Realm state.

## 3. Online connection lifecycle


```text
authenticate
  ↓
open socket
  ↓
protocol/version handshake
  ↓
select/enter character + online instance
  ↓
receive authoritative snapshot
  ↓
commands + revisioned deltas
  ↓
disconnect/reconnect
  ↓
resume + resync
```

Client MUST tolerate server process restart by reconnecting/resyncing.

## 4. Offline launch lifecycle

```text
select downloaded cartridge/save
  ↓
verify artifact hash/signature + local entitlement proof
  ↓
check kernel/client compatibility
  ↓
load local SQLite snapshot
  ↓
initialize portable kernel
  ↓
reconcile elapsed-time policy/due jobs
  ↓
play with no network
```

Network services must not be touched on the critical path after verification.

## 5. Local state

Mobile persists:

- save slots;
- cartridge release pins;
- local command receipts;
- logical clock/RNG state;
- local scheduled jobs;
- downloaded asset/content manifests;
- auth/entitlement proof where needed;
- preferences.

Online server projections are cache only.

## 6. One app, many cartridges, later Realm Mode

The Loka binary contains the Story runtime foundation from launch:

- portable rules implementation/version selected by R1;
- local authority + SQLite save support;
- supported render/action capabilities;
- catalog/purchase/download UI;
- first-release account/progress synchronization adapters;
- optional full cloud-save backup adapter.

Cartridges are separately downloadable data/assets/bounded portable rule IR compatible with installed kernel/client features.

Normal story release SHOULD NOT require a new app binary.

Realm Mode MAY ship later through an app update. Once present, Realm-specific UI/protocol code can evolve while offline-save compatibility remains a release invariant.

## 7. Client/kernel feature negotiation

Cartridge manifest declares:

```yaml
requires:
  kernel_api: ">=1.3 <2.0"
  rule_ir: 1
  content_schema: 1
  client_features:
    - contextual_actions_v1
    - dialogue_choices_v1
```

Offline launch verifies locally.

Online server also verifies client feature compatibility.

A cartridge needing new native kernel/client functionality waits for app update.

## 8. Catalog

Catalog entry includes:

```text
cartridge ID
display title/description
art
current purchasable release
supported languages
estimated playtime
age/content metadata
price/entitlement mapping
required app/kernel version
offline capable?
online modes
download size
availability
```

Catalog metadata is independent of immutable runtime release records.

## 9. Entitlements

Canonical domain entitlement:

```text
cartridge.fox_spirit_of_yunmeng
```

Mapping:

```text
Apple product ID -> canonical entitlement
Google product ID -> canonical entitlement
promo/admin grant -> canonical entitlement
```

Game/catalog rules query canonical entitlement only.

## 10. Purchase lifecycle

```text
client begins store purchase
  ↓
platform returns purchase proof
  ↓
server/trusted verifier confirms
  ↓
server records entitlement + provenance
  ↓
server issues locally verifiable offline grant
  ↓
client downloads signed/hash-addressed cartridge
  ↓
offline play available
```

Never trust a client boolean `purchased=true`.

## 11. Offline entitlement policy

Product goal: a permanently purchased/downloaded cartridge remains usable during long disconnected periods.

The implementation SHOULD use a locally verifiable signed grant or robust platform purchase proof.

A refund/revocation that occurs while a device never reconnects cannot be instantly enforced. That is an explicit tradeoff for true offline ownership-like usability.

When the device reconnects, current entitlement/revocation state is reconciled.

Do not build invasive always-online DRM into the offline storypack experience.

## 12. Restore/refunds/revocation

System handles:

- reinstall;
- new device;
- restore purchases;
- refund;
- revoked platform purchase where applicable;
- account merge/support correction.

Entitlement history is auditable.

Product policy must decide what happens to installed saves after revocation; implementation must not silently delete player saves.

## 13. Initial monetization

Working launch hypothesis:

- free app;
- one complete free showcase cartridge;
- permanent à-la-carte cartridges;
- optional bundles after catalog exists;
- no manipulative consumable economy required for initial product;
- subscription deferred until ongoing content cadence justifies it.

## 14. Store executable-code boundary

For the simplest initial review posture:

- cartridge assets/data/bounded portable rule IR are interpreted by capabilities already shipped in the app;
- do not download arbitrary JavaScript/native libraries per cartridge;
- server-only compiled Elixir remains on server;
- kernel changes ship through reviewed app binary.

Store policies must be re-verified before the review-position experiment and immediately before submission. Deferring LokaScript reduces the exposed surface but is not approval evidence: serialized JSON or declarative rule graphs may still encode behavior. The exact representation and review path remain ADR-035, not a green-test inference.

Primary policy source for the review-position check: [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), rechecked 2026-09-22. This source is policy evidence, not approval of Loka.

## 15. Content delivery

Use content-addressed package/asset manifests:

```text
semantic cartridge/content hash
optional exact package/transport hash
signature/attestation envelope
kernel compatibility
manifest
definition/rule-IR blobs
asset hashes
locale files
```

The semantic cartridge hash excludes the certificate/signature envelope that attests it. The optional package hash covers exact downloadable bytes and may therefore change if packaging metadata changes without changing game semantics.

Download can be resumable.

Incomplete/corrupt package never becomes active.

## 16. Local package management

Maintain installed releases needed by saves.

A save references exact hash.

Garbage collection may remove a cartridge release only when:

- no save requires it;
- no active download/reference requires it;
- replacement migration is complete.

User may explicitly delete a save/cartridge subject to normal confirmation.

## 17. Cloud backup

Cloud save is optional convenience.

Upload:

- encrypted/authenticated save snapshot;
- lineage metadata;
- cartridge hash;
- revision.

On divergent branches, keep both.

Do not semantic-merge arbitrary quest/world state.

## 18. Offline versus online characters

Default safety rule:

- offline story saves are local/private;
- MMO character state is online authoritative.

Do not import offline gold/items/stats into MMO.

Later, an online-private cartridge mode may intentionally use the authoritative online character and grant persistent rewards.

## 19. Narrative continuity

Account-level Story completion tracking is required in the first public Story release. It uses authenticated, retry-safe milestone submissions and accepted platform records as specified in [document 23](23-accounts-progress-admission.md). Optional richer memories such as ending details, journal/lore or cosmetics are separate product policies.

Locally asserted milestones may satisfy explicitly designated onboarding requirements only. They do not prove honest device state or human comprehension and cannot grant competitive Realm value.

## 20. Release environments

```text
local
CI/Lab
staging
TestFlight / Play internal
production
```

Cartridge candidate promotion uses same hash across environments.

No rebuilding content differently for production.

## 21. Cartridge rollout

Support:

- hidden/internal;
- invited beta;
- general availability;
- withdrawn;
- deprecated.

Installed offline releases remain available according to entitlement/product policy.

## 22. App binary compatibility

Catalog/server maintains:

```text
minimum supported client version
current recommended version
protocol compatibility matrix
kernel compatibility matrix
client feature flags
```

Hard-block online only when safety/correctness requires it.

Offline existing saves should continue on their compatible installed app/kernel whenever technically possible.

## 23. Mobile CI

Every PR touching kernel bindings/protocol/mobile runs the relevant subset of:

- clean install;
- TypeScript;
- lint/format;
- unit tests;
- generated schema/protocol drift;
- native module compile targets;
- portable conformance vectors;
- Story authority-boundary tests;
- Realm authority-boundary tests where Realm exists;
- representative offline save roundtrip;
- supported old-save compatibility corpus;
- Realm protocol fixtures/reconnect tests where Realm exists;
- Expo config validation.

Every production mobile release runs the full supported Story compatibility suite even if the release was motivated only by Realm work.

Pre-release adds real iOS/Android internal-build smoke for every enabled gameplay mode.

## 24. Deep links

Later:

```text
loka://cartridge/fox_spirit_of_yunmeng
```

Deep link never bypasses entitlement/version checks.

## 25. Privacy/data minimization

Offline gameplay SHOULD remain local by default.

Telemetry should avoid:

- auth tokens;
- full receipts;
- private chat unnecessarily;
- complete private story traces unless opt-in/needed for support.

Crash reporting can send minimized technical state with user consent/configuration.

## 26. Current technology feasibility note

As of this spec's 2026-09-17 research baseline:

- Expo supports custom native modules for iOS/Android;
- modern React Native uses the New Architecture/JSI-native module model;
- React Native provides Turbo Native Module/codegen mechanisms for native integration and also documents a pure cross-platform C++ module path;
- Rustler provides a mature Rust/BEAM NIF bridge;
- Rust-to-React-Native generator projects exist, but current ecosystem maturity varies and at least one prominent option warns against production use today.

Therefore a shared Rust kernel is feasible enough to justify a spike, but **neither Rust nor a particular React Native binding generator is frozen by this document**. The spike must prove build/release ergonomics, crash/debug behavior, Expo/EAS integration, upgrade burden, and deterministic cross-host parity first.


## 27. Store-review gate for downloadable rule content

Apple's current Guideline 2.5.2 says apps may not download/install/execute code that introduces or changes app features/functionality, while Guideline 4.7 separately permits certain non-binary software categories such as mini games under additional rules.

Therefore the architecture MUST NOT assume that calling a downloaded payload “bytecode” or “script” makes it acceptable.

Before the first App Store submission, run a dedicated review-position spike:

1. characterize cartridge rule content as bounded game data/rules over pre-shipped capabilities;
2. ensure it cannot expose new native APIs or general computation;
3. provide App Review with clear notes/demo content explaining downloadable game levels;
4. determine whether the exact implementation is reviewed under ordinary game-content/IAP expectations, Guideline 4.7, or another current interpretation;
5. if necessary, further restrict/compile LokaScript into a declarative rule graph rather than a general instruction VM.

The product goal—downloadable offline storypacks—remains; the precise portable rule representation must be compatible with current store review policy.


## 28. App/kernel upgrades must not strand offline saves

Automatic app updates create a compatibility obligation that is independent of cartridge updates.

A new app/kernel release MUST NOT make a previously valid installed save within the published support policy unopenable merely because code was replaced. The policy must be published before commercial release and cannot be silently shortened to excuse missing migration/recovery work.

The release process therefore tracks a compatibility matrix across:

- save format version;
- cartridge content schema;
- rule-IR version;
- kernel API version;
- client feature set;
- exact capability lock / capability-version requirements.

Allowed strategies for an older installed save/package:

1. **backward-compatible execution** — new kernel still understands the pinned versions;
2. **explicit deterministic migration** — package/save is migrated locally with rollback-safe backup;
3. **bundled compatibility interpreter** — retain an older rule-IR interpreter path when practical.

The implementation MAY define a supported compatibility window, but it must be long enough for commercial offline ownership expectations and must be visible in release policy.

Before removing old kernel/rule-IR support:

- inventory locally installed/published cartridge requirements;
- provide/certify migrations where needed;
- verify user saves;
- retain recovery backup;
- never silently rewrite a save during app startup without a recoverable migration transaction.

An app update with no network must still open supported offline saves.



## 29. Account, entitlement, and mode boundary

One app removes the need for cross-app purchase portability, but it does not remove trust boundaries.

Default rules:

- The first public Story release MUST provide accounts, recovery/deletion, and durable completion synchronization.
- Story Mode remains playable without an active account session after legitimate acquisition/download; offline-first does not mean account-free.
- Realm Mode requires an authenticated online identity.
- canonical cartridge entitlement may be cached locally for offline Story access and also known server-side when purchase evidence has been verified;
- editable Story save contents never grant authoritative Realm gold, items, levels, or competitive progression; designated account onboarding unlocks are separately authorized under document 23;
- owning a Story cartridge MAY unlock a Realm adventure, cosmetic, badge, or account feature only through an explicit server-side product rule—not because Realm reads the local save.

A user uses the same Loka identity for accepted Story milestones and later Realm admission. Full-save backup and purchases remain separate features. Pending reports stay bound to their originating account/profile; signing into another account cannot relabel them. Guest claiming, when offered, is explicit. See document 23 for deletion, multi-device and admission behavior.

## 30. First-public-release account gate

R12A delivers authentication/recovery/deletion, platform persistence, run binding, milestone acceptance/readback, pending/synced player feedback and a minimal administrative progress view. Test offline finish then reconnect, duplicate delivery, stale reports, account switching, deleted credentials and new-device readback. Unknown offline activity is not reported as failure to finish. Full-save restore is not implied by a completed-account badge.

R6P uses a fake progress adapter and is not delayed by production identity. The free public release must pass R12A; paid purchase infrastructure remains R13; authoritative Realm admission is R14/R15. Exact requirements and trust limits are in [document 23](23-accounts-progress-admission.md).

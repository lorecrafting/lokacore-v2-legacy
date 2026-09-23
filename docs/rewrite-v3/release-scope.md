# Generated release scope

Generated from `release-scope.json`; edit that reviewed planning input, then run
`python3 docs/rewrite-v3/checks/release_scope.py --write`.

**Full chapter one remains 57 rooms, 10 quests, two endings.** R6P is a separate early proof.
This is planning applicability, not a release certificate or a frozen engine registry.

## proof

| Capability | First slice | Phase | Gates |
|---|---|---|---|
| `movement@1` | proof | R5 | TOPOLOGY |
| `barrier@1` | proof | R5 | TOPOLOGY |
| `containment@1` | proof | R5 | TRANSACTION |
| `inspectable_detail@1` | proof | R5 | RULES |
| `description_variant@1` | proof | R5 | RULES |
| `target_resolution@1` | proof | R5 | RULES |
| `policy@1` | proof | R5 | RULES |
| `fact@1` | proof | R5 | RULES |
| `check@1` | proof | R5 | RULES |
| `quest@1` | proof | R7 | QUEST |
| `dialogue@1` | proof | R7 | QUEST |
| `scene@1` | proof | R7 | SCENE |
| `action_recipe@1` | proof | R5 | RULES |
| `reaction@1` | proof | R8 | WORLD |
| `behavior@1` | proof | R8 | WORLD |
| `schedule@1` | proof | R8 | WORLD |
| `calendar@1` | proof | R8 | WORLD |
| `narration@1` | proof | R7 | SCENE |

**Engine/device/human planning gates:** AUTHORITY, DETERMINISM, DEVICE, HUMAN, QUEST, RULES, SCENE, STATIC, TOPOLOGY, TRANSACTION, WORLD.

## chapter_one

| Capability | First slice | Phase | Gates |
|---|---|---|---|
| `movement@1` | proof | R5 | TOPOLOGY |
| `barrier@1` | proof | R5 | TOPOLOGY |
| `containment@1` | proof | R5 | TRANSACTION |
| `equipment@1` | chapter_one | R5 | TRANSACTION |
| `inspectable_detail@1` | proof | R5 | RULES |
| `description_variant@1` | proof | R5 | RULES |
| `target_resolution@1` | proof | R5 | RULES |
| `policy@1` | proof | R5 | RULES |
| `fact@1` | proof | R5 | RULES |
| `resource@1` | chapter_one | R5 | TRANSACTION |
| `attributes@1` | chapter_one | R5 | RULES |
| `position@1` | chapter_one | R5 | RULES |
| `skills@1` | chapter_one | R7 | RULES |
| `status@1` | chapter_one | R7 | RULES |
| `check@1` | proof | R5 | RULES |
| `combat@1` | chapter_one | R7 | RULES |
| `death@1` | chapter_one | R7 | RULES |
| `quest@1` | proof | R7 | QUEST |
| `dialogue@1` | proof | R7 | QUEST |
| `scene@1` | proof | R7 | SCENE |
| `action_recipe@1` | proof | R5 | RULES |
| `reaction@1` | proof | R8 | WORLD |
| `behavior@1` | proof | R8 | WORLD |
| `schedule@1` | proof | R8 | WORLD |
| `population@1` | chapter_one | R8 | WORLD |
| `commerce@1` | chapter_one | R8 | TRANSACTION |
| `service@1` | chapter_one | R8 | TRANSACTION |
| `calendar@1` | proof | R8 | WORLD |
| `tide@1` | chapter_one | R8 | WORLD |
| `light@1` | chapter_one | R8 | WORLD |
| `liquid@1` | chapter_one | R8 | TRANSACTION |
| `readable@1` | chapter_one | R8 | RULES |
| `topics@1` | chapter_one | R8 | QUEST |
| `relationship@1` | chapter_one | R8 | QUEST |
| `faction@1` | chapter_one | R8 | QUEST |
| `narration@1` | proof | R7 | SCENE |
| `sense_cue@1` | chapter_one | R8 | WORLD |

**Engine/device/human planning gates:** AUTHORITY, DETERMINISM, DEVICE, HUMAN, QUEST, RULES, SCENE, STATIC, TOPOLOGY, TRANSACTION, WORLD.

**Additional public-app/platform gates (not pure cartridge certification):** ACCOUNT, RUN.

## Feature-level applicability

| Feature | Capability | First need | Phase | Evidence |
|---|---|---|---|---|
| quest.escort | `quest@1` | chapter_one | R7 | Q2 Wren and S3 patrol require escort now; not deferred to chapter two. Gates: QUEST. |
| quest.survive | `quest@1` | chapter_one | R7 | S27 survival and S3 patrol. Gates: QUEST, WORLD. |
| scene.overlay | `scene@1` | chapter_one | R7 | Dream overlay; not a spatial InstancePlan. Gates: SCENE. |
| service.immediate | `service@1` | chapter_one | R8 | Ferry fare/transport and immediate inn services. Gates: TRANSACTION, TOPOLOGY. |
| commerce.immediate | `commerce@1` | chapter_one | R8 | Shop, food and drink; retry/crash conservation applies now. Gates: TRANSACTION. |
| schedule.durable | `schedule@1` | proof | R8 | Durable schedule jobs are required; these are not ServiceJob escrow. Gates: WORLD, AUTHORITY. |
| death.shrine | `death@1` | chapter_one | R7 | Corpse and shrine respawn, without ghost-walk. Gates: RULES, AUTHORITY. |
| death.ghost | `death@1` | chapter_two | R7 | Later chapter-two ghost-walk policy. Gates: RULES, AUTHORITY. |
| quest.protect_race | `quest@1` | chapter_two | R7 | Later objective operators. Gates: QUEST. |
| scene.spatial_instance | `scene@1` | realm | R7 | Explicit InstancePlan gate before use/R19; not required by chapter-one overlay. Gates: INSTANCE. |
| world.phased_event | `reaction@1` | chapter_two | R8 | WorldEventPlan composition for Wight Night and later events. Gates: WORLD. |
| service.escrow_jobs | `service@1` | chapter_three | R8 | Queued/timed craft jobs and custody, not immediate ferry fare. Gates: ESCROW, TRANSACTION. |
| commerce.barter | `commerce@1` | chapter_three | R8 | Owner placed barter in chapter three. Gates: TRANSACTION. |
| commerce.npc_trade | `commerce@1` | chapter_three | R8 | NPC stock movement, not an implicit early restock engine. Gates: TRANSACTION, WORLD. |

## Gate meanings

- **STATIC:** Manifest/schema/reference/lock/localization/install artifact validation.
- **DETERMINISM:** Per-step canonical state/result/RNG and frozen numeric vectors.
- **AUTHORITY:** Receipt admission, accepted failure, rollback, uncertain commit, recovery.
- **RULES:** Applicable capability invariants and invalid input boundaries.
- **TOPOLOGY:** Structural and scenario-achievable traversal including ferry, barriers and policies.
- **WORLD:** Deterministic bounded scheduling, population and reaction work.
- **QUEST:** Activation/credit, branching, resolution, scope and reward-once.
- **SCENE:** Durable choices/consequences and coherent presentation recovery.
- **TRANSACTION:** Applicable immediate item/payment/resource ownership conservation.
- **DEVICE:** Actual iOS/Android build, input responsiveness, offline and save evidence.
- **HUMAN:** Readability, discoverability, consequence comprehension and authoring feedback.
- **INSTANCE:** Spatial instancing closure, entry/export/teardown/recovery before feature use.
- **ESCROW:** Queued ServiceJob custody, capacity, retry/fault and reconciliation before use.
- **ACCOUNT:** R12A first-public-app account lifecycle and real milestone sync; local capture/model adapter in proof; admission at R14/R15 (doc 23).
- **RUN:** R12 first-public-Story bookmarks, pinned-save compatibility, rollback-safe migrations and bounded manual export/import (doc 10 sections 31-33, RUN-01-05). Optional backup has separate RUN-06 evidence when delivered.

## Limits and later scope

The chapter-one lock is exhaustive; later entries are feature-planning examples, not frozen chapter-two/three manifests.
Production certification derives used features and transitive dependencies from the frozen compiled artifact and engine-owned registry; unknown applicability blocks/widens evidence.
Native bindings, commercial purchase/review, hostile ingestion, compatibility and multiplayer gates also apply when those host/release risks exist; this planning list cannot waive them.
R6P uses only each capability slice it exercises; a later feature of the same capability does not become an early dependency.
ACCOUNT is a first-public-app/platform obligation, not an engine capability or a live-service prerequisite for pure cartridge certification. R6P tests a fake sync adapter.
RUN is a public Story app/recovery obligation, not a portable capability, a cloud-backup requirement, or an extra R1/R6P implementation dependency. Realm gameplay does not inherit offline save-import authority.

Later proposed new capability families: spell_words, stance, collection, identity_knowledge, pet, hunt, drives, mount, property, steal, law, mail, recognition, track, performance.

# Implementation-readiness amendment review

**Baseline:** `lorecrafting/lokacore@8ca4baf3bcbb265e15bfe889ff0a748e4716b047` (PR #9 merged).
**Owner request:** apply the readiness review recommendations and open a PR, 2026-09-22 Honolulu.
**Scope:** specification, hand-authored fixtures and standard-library specification checks only. No legacy or production engine, database service, mobile app, real player data, dependency install or physical-device benchmark is changed/run.

## Decisions and disposition

The amendment adopts the bounded composition profile, TypeScript-first R1 target envelope, explicit setup/oracle gate, current-possession Lantern objective with both traces, and player-run defaults. It integrates them into existing governing documents and ADR-064–067. `r1-work-package.md` is subordinate to document 14/envelope, not a competing architecture source.

The full chapter remains 57 rooms, 10 quests and two endings. Old Tiny/numeric/account models and their expected files remain unchanged. Manual export/import and three bookmarks are first-public-release work; cloud snapshot backup stays optional rather than adding a hard paid-launch requirement. Initial sign-in/guest UX, actual device inventory, lockfile/provider choice and support quotas remain explicit scoped work.

## Self-review and corrections

| Finding | Correction |
|---|---|
| Native-kernel working-hypothesis wording contradicted the A-first decision procedure. | Reconciled the overview and mobile note; A first, B/C on failure only, none preselected. |
| Approval of targets could be mistaken for acceptance of an actual setup or R1 result. | Envelope v0.3, blank setup template, fail-closed retained-record checker, separate R0/setup/result gates. |
| Adding sections collided with historical numbering/references. | Used new terminal section numbers; regenerated checked menus; preserved the existing content-migration reference. |
| Initial scheduling prose mixed atomic advance with partially drained follow-up work. | Defined a bounded atomic due set, future-beyond-target scheduling, ordered tentative evaluation and full rollback. Actual scheduler evidence remains future work. |
| Required build hashes cannot exist before candidate code. | Preparation pins contract/fixtures/devices/toolchain; actual result manifests later record build hashes and thermal/load conditions. |
| Generic required backup could pull a platform into the proof. | Mandatory local export at public launch, optional cloud snapshot backup; R12A milestone sync unchanged. |

## Adversarial self-review and further corrections

| Attack / counterexample | Result and correction |
|---|---|
| Emit before activation, deliver after activation. | Fixed emission-time eligible subscription snapshot; explicit known-answer negative control. |
| Two independent writers rely on sorted registry order to choose a winner. | Exclusive writer-group conflict; same-value independent writes also conflict in initial profile. Known-bad last-writer-wins variant detected. |
| Two distinct item writes exceed one container's capacity. | Final aggregate invariants reject the entire proposal. Known-bad partial-state-return variant detected. |
| Cyclic child reactions repeatedly obtain fresh fuel. | One aggregate budget plus depth limit; explicit fault rollback tests. |
| Python boolean/integer equality equates true with 1 in a guard. | Canonical typed JSON equality; added regression test. Enum arithmetic is rejected rather than treated as a resource. |
| A broad status-word edit calls provisional events/state “approved target” events/state. | Restored proposed-event/proposed-state terminology and added document regression assertions. |
| A template claims devices, reviewer independence or measurements it does not have. | Template stays empty and fails readiness. Tests use temporary records labeled synthetic. Checker validates hashes/record cross-links, not human identity or genuine device use. |
| Review receipt points at old inputs or setup changes after review. | Verify retained hashes, complete input set and external non-self-referential setup digest. Missing/tampered/changed records fail. |
| Crash after choice commit but before display. | One persisted narration/terminal occurrence recovers; original receipt replays without another transfer or story effect. |

These are two passes by the same assistant, **not independent approval**. Four controlled in-memory composition mutants establish sensitivity only to named defects; they are not exhaustive mutation analysis. The Lantern model reuses the abstract receipt/fault model but is deliberately story-specific specification code. R6P must prove that real compiled content uses the shared evaluator, not copy a special FerrymanEngine.

## Validation at reviewed local candidate

- 94 standard-library unit/specification tests passed (58 existing + 36 added test methods).
- Release-scope, chapter-one capability lock, generated checklist and selected summary links passed; the original capability lock and numeric/Tiny expected files were not changed. The planning scope adds the RUN public-Story recovery/export gate, without imposing it on R1/R6P or Realm authority.
- 30 generated reader menus, local Markdown links and milestone coverage passed.
- `readiness.py --check-template` passed. Running `--require-ready` on the checked-in template failed as intended: preparation remains pending.
- Changed-file whitespace and Python syntax checks passed.

Remote exact-head CI and reviewed-file hash comparison are reported on the PR after publication; this record does not predeclare their results or identify a yet-uncreated commit hash.

## Remaining evidence and next work

This is the readiness amendment, not a completed engine, R0 acceptance, runtime choice, physical device pass, store approval or production authorization. PREP-02 still needs actual device/SKU/OS/toolchain records, an accepted R0 commit/cutover and genuinely independent expected-value/setup review. Then R1-A1–A4 performs the real Hermes/Node/BEAM/SQLite experiment. R2 establishes the fresh production repository, and P1–P6 prove player-facing continuity on devices before full chapter production.

Manual-save/migration/import, optional-backup, live account/fork/deletion and true scheduler integration scenarios are listed but not simulated away by these checks. Current official Expo/React Native/Apple sources were rechecked during the continuation review on 2026-09-22 Honolulu for setup/release requirements; no external documentation proves Loka's actual compatibility or approval.

## Continuation review and corrections

Recovered the interrupted authored patch from its eight uploaded Git blobs and verified the reassembled XZ checksum before applying it against the same baseline. Reran the original recovered 92-test suite before changing it. Recovery/materialization workflows are temporary transport branches only; they must not be part of the final PR tree or ancestry. Persistent CI remains read-only.

| Finding | Correction and evidence boundary |
|---|---|
| Public bookmarks/export could disappear from the generated checklist while remaining mandatory in prose. | Added RUN to public Story platform gates, retained all 37 portable capabilities, excluded proof/Realm and added deletion/misapplication regression checks. Optional cloud backup remains optional. |
| A malformed input entry could raise an AttributeError instead of the readiness check's controlled diagnostic. | Validate record types before field access and normative-file types before set operations; malformed/null/scalar/list entries and a malformed retained R0 list now fail with ValueError. |
| A snapshotted due job could be executed after an earlier job cancelled/rescheduled it; reaction visibility between jobs was implicit. | Specify occurrence/generation revalidation and drain each job's reactions before the next due job under one aggregate budget/commit. COMPOSE-07 requires actual scheduler evidence later; no new scheduler implementation is claimed. |
| “Independently authored” expected values could be confused with independent review approval. | State explicitly that this assistant authored and self-reviewed the examples; PREP-02 still requires genuinely independent oracle approval. |

The resulting 94 tests, scope/navigation/template checks, intentional not-ready check, syntax and whitespace validation passed locally. The preparation template still contains no actual device, toolchain, acceptance or review receipts. A PR merge accepts this amendment, not a fabricated R0/R1 completion record.

# R1: first implementation assignment

[Packet home](README.md) · [Governing implementation plan](14-implementation-plan.md) · [Acceptance envelope](r1-acceptance-envelope.md)

**Status:** owner-approved readiness direction, 2026-09-22; amendment review/merge, R0 acceptance, exact setup and measurements pending. This is a bounded work package under document 14, not another architecture authority, completed experiment or authorization to modify the legacy engine.

## Goal and non-goals

Build one disposable semantic/host experiment. Determine whether candidate A—one TypeScript semantic package on Hermes and an isolated Node runner reached through a BEAM Port—satisfies the approved envelope. A passing A ends the comparison. Only a documented failure justifies B, then C. No language or native binding is preselected.

Do not implement the full chapter, production compiler, commerce, Realm/PostgreSQL authority, generic Builder, Foundry integration, LokaScript or an additional proof-language toolchain. Prepared definitions are permitted. The 57-room/10-quest/two-ending release and the later four-place R6P remain separate obligations. The Python models are specification examples, not production foundations.

## Work order and acceptance

| Ticket | Dependencies | Work and required evidence |
|---|---|---|
| PREP-01 | Amendment review | Reconcile governing contracts; review exact initial operation/order/budget semantics, existing Tiny known answers and both Lantern intent traces. Resolve counterexamples before candidate semantics, without claiming self-review independent. |
| PREP-02 | PREP-01, R0 acceptance | Copy the setup template; record real device/OS/toolchain/lock metadata, accepted specification commit, retained input hashes and independent oracle/setup review receipts. All preparation checks must pass before R1-A1; templates fail closed. |
| PREP-03 | PREP-01, parallel with R1 | Review exact downloaded payload and pre-shipped API surface; retain policy notes, sample package and risk disposition. Resolve investment risk before scaling production content, then repeat exact-app/current-policy review before public store launch. |
| R1-A1 | PREP-02 | Stateless state-in/proposal-out TypeScript kernel; same semantics as frozen Tiny + numeric + admitted composition/scene cases. Runtime cannot rewrite expectations. |
| R1-A2 | R1-A1 | Actual Hermes release builds on physical iOS/Android; Node/BEAM Port adapter; real SQLite transactions; source-mapped/symbolicated injected faults and repeatable builds. |
| R1-A3 | R1-A2 | Tiny/Medium/Stress generator+seed and raw samples; per-step hidden-state/result bytes; all fault points, UI latency, restore, memory, runner death and 100-instance server load. Demonstrate mismatch detection. |
| R1-A4 | R1-A3 | Independent evidence review and exact ADR-004/005 selection with failed/unmeasured rows retained. B/C only when preceding candidate fails; no post hoc threshold tuning. |
| R1-A5 | R1-A4, R0, PREP-03 investment disposition | R2 fresh repository/spec cutover. Carry reviewed fixtures/evidence and deliberately reimplemented code, not accidental spike structure. Then production contracts/compiler/local save slices → R6P. |

PREP-01 model work and inventory gathering may happen now. PREP-02 records actual facts; no inferred purchase/availability or placeholder hash may masquerade as an accepted setup. Approval of the recommendation is not approval of an unseen device manifest.

## Preparation commands

From the repository root:

```sh
python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py' -v
python3 docs/rewrite-v3/checks/release_scope.py --check
python3 docs/rewrite-v3/checks/packet_navigation.py --check
python3 docs/rewrite-v3/checks/readiness.py --check-template
# Expected to FAIL until a real, reviewed setup bundle exists:
python3 docs/rewrite-v3/checks/readiness.py --require-ready \
  docs/rewrite-v3/conformance/r1-run-manifest.template.json \
  --evidence-root docs/rewrite-v3
```

The ready check verifies completeness, local retained hashes and cross-links in review records. It cannot authenticate reviewers or prove hardware use, and never emits an R1 result. Its tests use explicitly synthetic temporary setups. Do not commit those as evidence. Use a separate result manifest after builds exist; build hashes and per-run thermal/battery/load records are not fictitious pre-build requirements.

## Evidence bundle and review boundary

Retain `setup.json`, the approved envelope/profile/fixture bytes, stable toolchain+lock manifest, exact device inventory and review receipts in a versioned bundle. Review receipts bind the accepted specification commit and covered input hashes. Freeze before R1-A1. Preparation status is not candidate acceptance. Actual result bundles additionally pin candidate commit, all build/package hashes, runtime pool/boundary variant, exact run conditions and raw results.

The host fixture format is defined in [conformance/README.md](conformance/README.md). Compare every step's decision/delta/events/effects/RNG/state/continuation, not only final hash or transcript. Expected answers have independent review; matching two identically wrong hosts is not correctness. Separate admitted successes, failed checks, rejections, replays and faults. Record raw counts and percentiles; missing rare-event sample sizes do not justify a confident p99.

Start stateless. Add revision-tagged reconstructible caches or touched-state slices only when measured need justifies them and the variant is recorded before tuning. BEAM remains serialized authority; a runner is never a second durable owner. After unknown COMMIT, reconcile rather than rerun. A smooth native animation is not proof the JS thread can handle input.

## Completion criteria and deferred decisions

R1 finishes only after actual release-build physical iOS/Android evidence and all common host/fault/load gates pass under reviewed setup. Database evidence here is SQLite; PostgreSQL and production Realm remain later. This amendment records no physical-device availability or measurements. Store review, human R6P comprehension and production release are separate gates.

After R1, use R2 to enforce boundaries and import one accepted spec. P1–P6 in [the playable proof](pre-release-proof.md) are the next narrow product path. Implement run-lifetime foundations at R6 and bookmark/export UX by R12. R12A mandatory completion sync stays separate from optional whole-save backup. Guest-first versus initial sign-in UX, exact recovery quotas, provider selection and future distribution changes remain scoped decisions; they must not reopen the authority model or delay unrelated portability evidence.

## Current-source notes

Rechecked 2026-09-22: [Expo SDK compatibility](https://docs.expo.dev/versions/latest/), [React Native performance](https://reactnative.dev/docs/performance), [Apple review rules](https://developer.apple.com/app-store/review/guidelines/). These sources constrain setup/release verification; they are not a pinned dependency set or approval of Loka. Documentation versions may move, so record exact stable versions at PREP-02 and recheck actual release obligations later.

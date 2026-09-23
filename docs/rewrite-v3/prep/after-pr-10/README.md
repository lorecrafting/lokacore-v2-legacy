# R0 / PREP-02 decision and setup — still blocked

Current observed main: `4a9f60c9040b3582fa79c39916307eab15c76e1b`
(PR #12 merge). Its tree matches reviewed PR #12 head
`367274e0c7ef942dd1c11e8b2eb79058cce24040`. The **proposed R0 contract stays
`9567117404f635c803373d9957050fd8ec50f334`** (PR #11 merge): the later
preparation/evidence records do not amend the normative contract. PRs #10–#12
are merged; no separate owner acceptance or independent approval was found in
the inspected records, recent PR discussions or R0 issue search. The owner's
merge confirmation is not the missing acceptance.

[Work order](../../r1-work-package.md) · [Focused review](../../reviews/2026-09-22-prep-followup.md)
· [Tooling coverage](../../spec_tools/README.md) · [Downloaded representation review](../downloaded-representation.md)

## One concrete R0 decision for the owner

The existing [R0 record](r0-acceptance.pending.json) now proposes that exact
commit, names all 19 normative files, preserves all 67 ADR statuses with their
qualifiers, identifies subordinate governing companions and leaves outstanding
gates/deferred questions explicit. The content pull list in `00`/`00a` is included
without reclassifying it as engine architecture. Informative documents and models
have not been promoted to normative authority.

**Proposed decision text, not a recorded approval:**

> I accept `9567117404f635c803373d9957050fd8ec50f334` as the R0 contract under
> the normative file set, qualified ADR dispositions, remaining gates,
> amendment authority and fresh-repository cutover rule proposed in
> `prep/after-pr-10/r0-acceptance.pending.json`. Provisional, deferred and
> rejected decisions keep those dispositions. This does not approve an R1
> result, qualification hardware, expected answers/setup, store submission or
> production implementation.

The owner should explicitly adopt or amend that decision, with an attributable
record. Until then `disposition` stays `pending`; `accepted_spec_commit`,
`reviewer_id` and `owner_decision_source` stay null. The proposed source commit
is stable even though this follow-up adds evidence records on a later commit:
**it changes no normative contract, fixture, threshold or checker.**

The cutover rule does not require creating or naming a production repository
now: the owner records its exact URL/import commit at R2, after reviewed R1
selection and the PREP-03 investment disposition. It then becomes the sole
implementation-era normative source; no legacy port or dual specification.

## Status

| Work | Established | Still required |
|---|---|---|
| R0 | Exact-commit decision proposal and explicit file/ADR/cutover scope. | Owner acceptance; proposing the record does not accept it. |
| PREP-01 | Bounded source/fixture review and corrections completed and merged in #11; current baseline reproduced. | Independent expected-answer approval remains part of PREP-02; no repeated broad review is requested. |
| PREP-02 | Seven retained input hashes, pending bindings, and a retained SDK-matched JavaScript dependency graph with two clean-install checks. Five exact toolchain fields have partial hosted evidence. | Nine remaining toolchain fields, complete native/configuration lock, actual devices/common host, attributable authors and independent oracle/setup approvals. |
| PREP-03 | Existing payload specimen, pre-shipped API boundary and policy-risk review. | Owner investment disposition before A5/R2; later exact-app/current-policy release review. |
| R1-A1 | **NOT AUTHORIZED TO START.** A-first/stateless order unchanged. | Truthful completion of PREP-02 and both readiness checks. |

## Factual compatibility check — not a candidate lock

Official documentation checked on 2026-09-23 UTC / 2026-09-22 Hawaii:

| Source | Documented fact | PREP-02 consequence |
|---|---|---|
| [Expo SDK reference](https://docs.expo.dev/versions/latest/) | SDK 57 targets React Native 0.86; minimum Node 22.13.x; iOS 16.4+, Android 7+, Xcode 26.4+, compile/target SDK 36. | This train's documented OS minima fit the approved iOS 16.4+/Android 10+ floors. This is not a device test or an exact version selection. Do not pair arbitrary latest Expo and React Native releases. |
| [SDK 57 release notes](https://expo.dev/changelog/sdk-57) | The regression notes identify fixes in expo 57.0.9 / RN 0.86.2 for Hermes V1 memory use with worklets, and expo 57.0.17 / RN 0.86.3 for development startup. | Review the actual resolved Hermes/RN patch pair; do not freeze an early patch blindly. These documented fixes are not a claim of the latest patch or a passing Loka benchmark. |
| [Expo SQLite reference](https://docs.expo.dev/versions/latest/sdk/sqlite/) | Documents iOS/Android support and recommended binding range `~57.0.3`. | A documentation range is not lock bytes and is not the embedded SQLite engine version. Retain and review both exact resolved versions. |

The same release notes require scene-based lifecycle support when building with
Xcode 27 / iOS 27 SDK; SDK 57 adds opt-in support in expo 57.0.23. The
preparer must review the actual Xcode/SDK/configuration combination, not treat
`26.4+` as a blanket build-success guarantee.

## Retained dependency-only resolution — partial PREP-02 evidence

[Captured package manifest](dependency-evidence/package.json) ·
[Exact package lock](dependency-evidence/package-lock.json) ·
[Command transcript](dependency-evidence/resolution.log) ·
[Checksums](dependency-evidence/SHA256SUMS) ·
[Packaged native metadata](dependency-evidence/dependency-observations.txt)

The bounded hosted capture used Node **24.21.0** and npm **11.19.0** on an
Ubuntu 24.04 x86_64 runner. This runner is **not** the approved common host or
qualification hardware. The retained graph is:

| Package / executed resolver runtime | Exact value | Evidence |
|---|---|---|
| Expo | 57.0.24 | Lock and SDK-bundled recommendation file |
| React Native | 0.86.3 | Lock; recommended by the captured Expo SDK |
| React | 19.2.3 | Lock; recommended by the captured Expo SDK |
| expo-sqlite binding | 57.0.3 | Lock; not the SQLite engine identity |
| TypeScript | 6.0.3 | Lock, SDK 57 template range and executed `tsc --version` |
| React type definitions | 19.2.18 | Lock and SDK 57 template range |
| Node / npm | 24.21.0 / 11.19.0 | Captured version output; package `engines` / `packageManager` |

The capture resolved SDK recommendations from the retained
[Expo bundled modules file](dependency-evidence/expo-bundledNativeModules.json)
and [SDK 57 template manifest](dependency-evidence/expo-template-package.json),
not independently chosen latest packages. It then ran `npm install
--package-lock-only`, two `npm ci` installs in separate clean directories,
`npm ls --all` and Expo's dependency check on both installations. The lock bytes
stayed identical; each install reported 468 packages. Package lifecycle scripts
were disabled. The graph retains npm's `uuid@7.0.3` deprecation warning;
`--no-audit` means **no vulnerability audit was performed**. Successful resolution
and replay establish neither native compatibility nor supply-chain approval.

The exact capture source is retained as inert
[`capture-workflow.yml.txt`](dependency-evidence/capture-workflow.yml.txt), not
an installed repository workflow. Run identifiers, checksums, the corrected
publication failure and authorship limits are in
[the validation record](tooling-validation.md#post-pr-12-dependency-evidence).
The resolver had read-only repository permissions; a separate job validated the
fixed artifact file set and pushed only the temporary capture branch. No
candidate code or package lifecycle script ran in that write-capable job. The
final follow-up imports data blobs onto current main, not the temporary branch's
workflow or commit ancestry. Continuing specification tooling remains Elixir.

Only `toolchain.expo`, `react_native`, `typescript`, `node` and `sqlite_binding`
are populated in [the existing pending setup](setup.pending.json). They identify
this partial resolved proposal, **not a reviewed or native-qualified setup**.
`toolchain_lock.path/sha256` remain null: pointing the complete-lock field at a
JavaScript-only lock would conceal missing native dependencies/configuration.
Use the retained bytes for subsequent native preparation instead of resolving
new versions without a reason; recheck the exact values on the approved host.

The other nine fields remain unverified. In particular, packaged React Native
metadata contains both `HERMES_VERSION_NAME=0.17.0` and
`HERMES_V1_VERSION_NAME=250829098.0.17`; it does not establish which engine the
actual build uses. The binding contains default SQLite **3.50.3** and SQLCipher
SQLite **3.49.1** headers. Neither header is an executed SQLite version query or
an approved native configuration. The recorded Android Gradle Plugin **8.12.0**
is not the Gradle distribution version. No Hermes, SQLite, Gradle, JDK, Xcode,
iOS/Android SDK or BEAM candidate runtime was executed by this capture.
Tooling-only Elixir/OTP pins are not copied into candidate fields.

To replay the *retained* graph, first verify `SHA256SUMS` in the evidence
folder, then copy only `package.json` and `package-lock.json` to a new disposable
directory outside the packet. With the recorded Node/npm versions:

```sh
npm_config_engine_strict=true npm ci --ignore-scripts --no-audit --no-fund
npm ls --all
CI=1 EXPO_NO_TELEMETRY=1 node node_modules/expo/bin/cli install --check
node node_modules/typescript/bin/tsc --version
```

Compare the resulting lock bytes to the retained original. This replay is
network-dependent dependency preparation, not permission to create an app or
start A1. The historical capture's range-resolution step should not be rerun
merely to produce a newer lock. Native preparation still needs its own actual
configuration, package/native locks, hashes and version outputs; Xcode 27's
scene-lifecycle requirements above are not resolved by installing Expo alone.

## Consolidated external actions

| Who supplies it | Exact artifact / fields | Evidence needed |
|---|---|---|
| Owner | `r0-acceptance.pending.json`: decision, `accepted_spec_commit`, `reviewer_id`, `owner_decision_source`; then the setup's accepted commit/reference | Explicit adoption or amendment of the decision above. Verify that its qualifications and later gates remain intact. |
| Device/setup preparer, with owner approval of the common host | `setup.pending.json`: `devices.ios.*`, `devices.android.*`, `server.*`, `candidate_author_ids`, nine remaining `toolchain` entries plus confirmation of the five resolved values, `toolchain_lock.path/sha256` | Available physical iPhone SE 2 (3 GB) and Galaxy A14 (4 GB), exact SKU/SoC/physical RAM/OS/build/arm64 and availability records; approved M1+ common host with at least 16 GB and exact configuration. Reuse the retained JS lock; supply actual native configuration/locks and exact Hermes, Elixir, full OTP, SQLite engine, Xcode, iOS SDK, Android SDK, Gradle and JDK evidence. Confirm the five recorded JS/runtime values on the approved host. Bind the complete evidence bundle only after these facts exist. Dependency-only preparation must not implement candidate gameplay. |
| Expected-answer reviewer, independent of candidate AND expected-answer authors | `oracle-review.pending.json`: accepted commit, reviewer, `subject_author_ids`, both separation declarations, disposition, exact seven inputs | Inspect state/result bytes, adverse cases, numeric outputs AND next states, order/conflicts/invariants/budgets/receipts/rollback/unknown commit, both Lantern outcomes and early possession. Preserve the due-job cancellation/rescheduling and save-fork/restore model limitations. |
| Setup reviewer, independent of candidate AND setup authors | `setup-review.pending.json`: accepted commit, reviewer, `subject_author_ids`, both separation declarations, disposition, exact `setup_digest` | Review the actual retained inventory/configuration/lock bundle, not the blank fields or a synthetic stand-in. An owner-approved identity/provenance check is required outside the structural checker. |

A newer phone, simulator, Linux editing container or CI runner is not an
unannounced substitute for qualification hardware. Escalate any proposed
substitution for an explicit disposition under the envelope before using it;
do not relabel it to satisfy the checker. No owner device ownership is inferred.
A new session, model, role label or second implementation is not automatically
an independent reviewer. Do not assign an identity or sign an approval on behalf
of anyone else.

`host-observation.json` remains a dated observation of the prior editing
container, **not** owner inventory or the approved R1 host. Current tooling
execution is recorded in [tooling-validation.md](tooling-validation.md).
Pre-build inventory and locks must not be confused with later application build
hashes, per-run thermal/battery/load records, or performance/persistence evidence.

## Binding and readiness sequence

After actual owner acceptance and factual preparation, retain the review records
with attributable approvals. Refresh `r0_acceptance` and `oracle_review` file
hashes in the setup before the setup reviewer signs the resulting setup digest.
`setup_digest` excludes the `status` and `setup_review` fields to avoid a cycle.
Then retain the setup-review file hash, set `status` to `setup_reviewed` only
when warranted, and run both checkers. Changed underlying inputs invalidate old
approvals; recomputing a hash alone does not renew one.

This dependency follow-up leaves the R0 proposal and oracle record byte-identical.
Five newly evidenced setup values change the setup digest, so its **pending**
setup-review digest and reference hash are refreshed. No approval, reviewer
identity or hardware measurement is added. All seven setup inputs, eleven
preserved inputs and the permanent blank template remain byte-identical.

From `docs/rewrite-v3/spec_tools` (both must currently fail with exit 1):

```sh
mix loka.readiness --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root ..
python3 ../checks/readiness.py --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root ..
```

Only truthful approval-backed success unlocks the separate disposable stateless
TypeScript R1-A1 workspace and Elixir BEAM harness. Follow A1 through A5;
passing A ends comparison, and B/C require documented preceding failures.
R6P remains a later four-place playable proof. The public chapter stays
57 rooms, ten quests and two endings.

## Separate PREP-03 decision — not an A1 blocker

Reuse [the payload specimen](../downloaded-payload.sample.json) and
[its representation review](../downloaded-representation.md). The owner can
record an investment disposition there in parallel: continue bounded R1
investment with the proposed pre-shipped API/data surface while accepting that
store classification is unresolved, or revise/stop that investment.
This is not a store approval. The disposition is required at A5/R2, not as a
new prerequisite for A1, and does not authorize production content scaling now.

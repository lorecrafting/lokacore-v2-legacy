# R0 / PREP-02 decision and setup — still blocked

Current observed main and **proposed R0 contract**:
`9567117404f635c803373d9957050fd8ec50f334` (PR #11 merge).
PR #11's reviewed head `c06034b4643a6c259f385084d996ebabd1d151b9` has the same
Git tree. PRs #10 and #11 are merged; neither merge is an exact R0 acceptance,
an independent approval, evidence of device availability or permission to build
production. No subsequent PR or owner acceptance was found in this follow-up's
repository/PR checks.

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
| PREP-02 | Seven retained input hashes, linked pending records, observed editing-host limits, and documented native OS-floor compatibility. | Actual devices/common host, complete exact candidate lock, attributable authors and independent oracle/setup approvals. |
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

No dependency graph or native project was resolved/built in this editing
container. Local GitHub access failed DNS resolution; Elixir/OTP/Mix and Xcode
are unavailable. The successful hosted specification checks do not
supply the candidate dependency lock. All fourteen `toolchain` values remain
null rather than being copied from documentation or the tooling-only pins.

## Consolidated external actions

| Who supplies it | Exact artifact / fields | Evidence needed |
|---|---|---|
| Owner | `r0-acceptance.pending.json`: decision, `accepted_spec_commit`, `reviewer_id`, `owner_decision_source`; then the setup's accepted commit/reference | Explicit adoption or amendment of the decision above. Verify that its qualifications and later gates remain intact. |
| Device/setup preparer, with owner approval of the common host | `setup.pending.json`: `devices.ios.*`, `devices.android.*`, `server.*`, `candidate_author_ids`, all 14 `toolchain` entries, `toolchain_lock.path/sha256` | Available physical iPhone SE 2 (3 GB) and Galaxy A14 (4 GB), exact SKU/SoC/physical RAM/OS/build/arm64 and availability records; approved M1+ common host with at least 16 GB and exact configuration. Retain resolved package/native lock bytes and version output for Expo, RN, Hermes, TypeScript, Node, Elixir, full OTP, SQLite, binding, Xcode, iOS SDK, Android SDK, Gradle and JDK. Dependency-only preparation must not implement candidate gameplay. |
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

This follow-up changes only the R0 proposal and its **pending** bindings:
the new R0 hash changes the setup digest, so the pending setup-review digest and
its file hash are refreshed too. No reviewer, approval or measured evidence is
added. The seven inputs and the permanent blank template remain byte-identical.

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

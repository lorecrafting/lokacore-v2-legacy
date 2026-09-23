# Focused preparation after PR #10

## Baseline and provenance

Baseline: `864ed383de7657107914502a919491dd8ff9f705` (current main when work began;
PR #10 merge). Reviewed source: `d3659ca172bcbabba6133b9452e67c793f8c3daf`.
GitHub comparison reports identical files. No later PR was present. New branch:
`prep/v3-elixir-handoff`; the merged branch is not reused.

The local runtime could not resolve GitHub for cloning. The retained PR #10
artifact was downloaded through the authorized GitHub connector, its archive
SHA-256 verified, and its reconstructed `docs/rewrite-v3` Git tree matched current
main exactly: `92a3f344fc79758e95ce21db4807ae29c298629e`. The local materialization
commit is not an upstream baseline or acceptance receipt.

Before changes: **94 unittest methods passed**, release-scope and packet-navigation
checks passed, template integrity passed, and `--require-ready` returned exit 1
for the incomplete template. This is newly reproduced specification evidence,
not a repeated historical assertion or physical/persistence evidence.

Review provenance: one assistant performed source review, corrections and an
adversarial self-review. No independent person or separate independent reviewer
approved this work. The owner has approved direction/thresholds, not an exact
R0 contract or actual experiment setup.

## Semantic/checker corrections (separate from language migration)

| ID | Concrete counterexample | Correction and regression |
|---|---|---|
| PF-01 | Replacing template `schema_version: 1` with `true` compares equal under Python structural equality. The old template-integrity command passes. | Compare canonical typed JSON bytes; `PrepFollowup.test_template_equality_preserves_json_types`. Original template bytes unchanged. |
| PF-02 | An expected-answer author who is not a candidate author can approve their own oracle under the old checker, even with correctly bound hashes. The same gap exists for setup preparation. | Require nonempty `subject_author_ids`, explicit subject-author separation and reviewer exclusion for both receipts. Rehashed self-approval, empty/typed/duplicate author lists and integer-as-boolean declarations fail. This is a gate amendment, not migration parity disguised as a refactor. |
| PF-03 | `rng_next(None)` raises an incidental TypeError; malformed states can bypass validation at a zero draw budget. Boolean/negative budgets are not explicitly rejected. | Typed state/budget validation with controlled diagnostics, preserving every valid numeric vector and next state. |
| PF-04 | Model tuples `(run="a:b", milestone="c", revision=1)` and `(run="a", milestone="b:c", revision=1)` both hash the text `a:b:c:1`. | Hash canonical array encoding instead of delimiter joining. This is an abstract local-report ID example correction, not a change to real player data or an established production ID format. Restore preserves existing queued IDs; production R6/R12A must independently specify/verify their encoding. |

No existing JSON fixture, numeric profile/vector, capability lock, expected
Lantern result, target threshold or candidate order is changed by these fixes.

## Contract challenge matrix

The reviewed governing boundaries remain one decision/commit owner, closed
versioned operations, root sequencing then FIFO reactions, and no alternate
write path. Specific challenges and remaining evidence are recorded in the
follow-up handoff; model success is not proof of actual transactions or a
complete portable implementation.

| Boundary challenged | Concrete ordering/counterexample checked | Disposition / executable coverage |
|---|---|---|
| Root and FIFO | Emit E1, emit E2; E1's reaction emits E3. E2 precedes E3. A root write following E1 is visible to E1's later overlay guard. | Existing `fifo-not-depth-first`, `root-before-reactions`, registry-reorder cases retained. |
| Eligibility versus guards | Emit while a subscription is inactive, then activate it: no retroactive delivery. Activate before emission: delivery. Event payload remains 1 while overlay becomes 2. | Existing emission/activation/payload cases and typed guard negative control retained. |
| Writer ownership | Two independent reactions setting even the same value conflict; two root operations within an explicitly ordered sequence may overwrite. Two custody transfers cannot duplicate the same item. | Existing identical-conflict/sequence/custody cases retained; no implicit last-writer-wins introduced. |
| Aggregate invariants | Distinct items both transferred to a bag with capacity 1 have disjoint entity write targets but violate aggregate capacity; a bag inside itself violates containment. | Existing all-or-nothing capacity and cycle cases retained, including rollback mutant. |
| Shared budgets | Self-emitting reaction cannot obtain a fresh operation/query/event/depth/delivery budget. A job due at 8 created while advancing to 19 is illegal, even if the visited time is 7. | Existing child-budget, output, selector, job-cap and future-target regressions retained. |
| Due cancellation | Candidate list contains A@7/g1 and B@8/g1. A cancels B; B must not run. If A reschedules B to 20/g2, the old B@8/g1 still must not run. | Protocol 04 §5.4 is explicit. Reviewed concrete trace, NOT executed by the simple job-scheduling model; R1 must produce actual scheduler traces. |
| Due reaction order | A@7 emits a reaction that cancels B@8. Drain A's FIFO reactions before checking B, rather than executing all roots first. Two independent job roots writing one singleton without a declared fold conflict; queue order is not authorization. | Protocol 04 §5.4 resolves both cases. Whole-advance fault rolls back time/jobs/events together. No claim of scheduler execution or database atomicity. |
| Rejection / failed attempt | Take from the wrong room rejects without a draw; an admitted failed check commits its next RNG state and receipt. Reading changes neither RNG nor time. | Tiny and Lantern negative cases retained; four original numeric methods also mapped into ExUnit. |
| Retry / current targets | Resolve a choice, move Bram, then retry the same intent with stale view: replay receipt. A NEW stale/consumed choice rejects; same ID with another ending conflicts. | Existing Lantern retry/presence/changed-intent and Tiny receipt-before-validation mutants retained. |
| Rollback / unknown commit | Definitive pre-commit failure discards outcome, narration and milestone. Unknown commit fences new work until reconciliation; confirmed commit replays, confirmed rollback permits one new attempt. | Both Lantern settlement outcomes and Tiny fault tests retained. These are abstract simulated fault outcomes, not actual SQLite fault injection. |
| Both Lantern outcomes / early possession | Carry keeps custody with hero and selects `player_led`; leave transfers to Bram and selects `party_led`. Each creates one narration/milestone at revision 10. Finding first, accepting later uses current possession, not historical-event replay. | Read both full 10-step fixture traces and their expected states; original exact-byte assertions and early-acquisition regression retained. |
| Save fork / account provenance | Fork F from run R's snapshot with pending report P: P still belongs to R/account lifecycle, not F. A new post-fork milestone uses F. Restore after accepted P replays; deletion/withdrawal cannot be undone by an old queue. | 23 §11 and mobile save contract are consistent. Existing backup/requeue/account-binding/withdrawal/deletion tests retained. No semantic-fork serializer is implemented by `LocalJournal`; R6/R12A must demonstrate that distinction. PF-04 fixes a concrete model ID collision, not the entire save subsystem. |

PREP-01's bounded source review/corrections are complete for this follow-up.
Independent expected-answer approval is still PREP-02 work. Explicitly unexecuted
scheduler/fork obligations must not be relabeled as passing model cases.

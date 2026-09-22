# V3 audit follow-through — 2026-09-22

## Scope and provenance

Original audit: `1f5f32c8472a2378b881e93cf16dcd80d73ae6f3`. Follow-up base after PR #8: `c4674f5b5c6c59e08dec39cc52a1ed71b83eeed4` (same specification tree as PR #8 head `bda0fe3`). PR #8 merged the planning note and CI scaffold, NOT the substantive audit fixes. This follow-up supplies those fixes. Local editing used the exact-head Actions source archive; it was not a full engine clone or a run of legacy engine tests.

The owner reaffirmed the from-scratch engine rebuild and the full first chapter: **57 rooms, ten quests, two endings**, with powerful LLM-assisted world creation/reasoning. R6P is a smaller earlier proof of the fresh engine, not a reduced release or an online-only pivot. No legacy engine code is changed or imported.

## Changes delivered

- Receipt access authentication and intent recognition before current action/freshness validation; separate invocation/command digests and versioned normalization; original outcome replay without old-view rollback.
- Accepted failed attempts persist their rule-defined RNG/outcome; definite rollback differs from unknown COMMIT. Uncertain transactions fence further decisions until authoritative reconciliation.
- Corrected tiny activation order, explicit event/state-credit controls, consumed-choice and schedule examples. Q2 now uses knowledge established by Q1 instead of requiring its earlier event again.
- Corrected index summaries for proposed events, facts/events/consequences, general connections, time-derived state and supported save compatibility.
- R1 v0.2 separates Tiny semantics and synthetic scaling, common load, decision/commit/checkpoint/restore timing, responsiveness and fault classes. Its numbers and numeric profile are still proposals, not accepted measurements.
- Release applicability is explicit and generated: immediate commerce/ferry safety is required now; ServiceJob escrow, spatial InstancePlan and later mechanics do not silently become first-chapter prerequisites.
- R6P work package and dependencies precede the full chapter. Offline Story/Builder/factory work no longer depends on production Realm. Free experience proof is distinct from paid-purchase validation. Later reuse includes a small unrelated cartridge.
- Small Python specification model, fixed JSON cases/numeric vectors, checked index links, generated matrix and read-only CI. These are NOT a production kernel, compiler, real database fault suite or mobile proof.

## Self-review, corrections

1. **Latent input/fault bug in the new model:** malformed move direction could raise, and an unknown test-fault label was detected after mutation. Validate both before unsafe work; negative cases now test no mutation.
2. **Scope omission:** positions were already in the full chapter design but absent from its manifest. Add `position@1` and the missing rule-IR/hello capability declarations without adding a new player feature. Correct the full-map summary count and chapter-one minimum z-level; no rooms removed.
3. **Activation reuse:** the same event-credit mistake affected Q2 as well as Tiny. Replace Q2's repeated event requirement with the existing arrival/knowledge fact. Keep a negative control preventing global retroactive event credit.
4. **Gate drift:** R7/R8/R9 and R3 freeze wording still pulled future features despite the chapter ladder. Scope their obligations by actual feature use, while retaining immediate transaction and always-applicable authority tests.

## Adversarial self-review, corrections

This pass was performed by the implementing assistant. It is **not independent review**, a separate principal, or R0 approval.

1. **Retry after consumed target/offer:** test changed intent and semantic continuation versus transport-only changes; replay the historical outcome without rolling back current state. Unauthorized actors cannot disclose receipts.
2. **Late COMMIT after a missing receipt:** model both eventual outcomes, block rerun while unresolved, and require real-store tests at R6/R14. An initially absent receipt is not treated as rollback proof.
3. **Failed RNG retention:** use a fixed known failing draw/next state and a mutant that restores RNG on failure. Matching retry cannot draw twice; a genuinely new attempt advances.
4. **Precommit publication:** inject an evaluator that publishes proposed events, then force rollback; the assertion catches the leak.
5. **Candidate-friendly planning:** reject missing/duplicate capabilities, removed mandatory gates, unknown feature gates, later deferral of first-chapter features, changed product counts and false accepted-status markers. Production certification still derives applicability from the engine registry and frozen artifact, not this plan.
6. **Stale companion contracts:** reconcile document 07's obsolete envelope section number, mandatory multi-binding comparison, three-strategy requirement and premature PostgreSQL gate with the bounded R1 procedure. Align paid/free shipping language and the index's phase table.
7. **Evidence inflation:** JSON/model checks do not parse the whole YAML grammar; the consumed-offer example is explicitly a separate contract fixture. Numeric cross-check is a standalone rendition of the attributed upstream transition, not independent reviewer approval or host parity.

## Validation performed locally

- `python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py' -v`: **26 tests passed**, including parameterized negative controls and four named behavioral mutation-sensitivity tests.
- `python3 docs/rewrite-v3/checks/release_scope.py --check`: passed; 37 declared chapter-one capabilities match its manifest, selected summary links resolve, generated checklist is current.
- `git diff --check`: passed.
- First five xoshiro128** 1.1 outputs AND states from explicit `[1,2,3,4]` cross-checked against a standalone C transition; exact values retained in `numeric-vectors.json`. No cryptographic use is authorized.

Exact remote-head Actions results belong in the PR handoff. The CI job remains read-only and preserves exact-head inputs and logs. Source publishing may use a temporary branch-only patch application job because the editing environment cannot access GitHub directly; that job/payload must be removed from the final candidate and must never update main.

## Remaining evidence and next implementation work

R0 acceptance/cutover, R1 numeric/performance envelope confirmation, actual candidate implementation, physical iOS/Android builds, real SQLite/PostgreSQL crash behavior, R6P playability/human feedback and App Review classification are NOT completed by this PR. `pre-release-proof.md` provides the fresh-repository work packages. Merge of this follow-up does not retroactively mark any of those gates passed.

The original Fable report was not authenticated; document 18 §32 remains the located outside-review summary. Independent/adversarial review by another principal is still required by the project's acceptance process. No auto-merge.

# Human/LLM packet housekeeping — 2026-09-22

## Scope and provenance

The user is preparing a comprehensive human review and requested every R milestone explained, plus a full-packet readability/organization pass. Starting candidate: PR #9 at `3e0aff993c0d4c76937544708f662a4624a08bfb`; main was `c4674f5b5c6c59e08dec39cc52a1ed71b83eeed4`. PR #9 was still open, so this is an additional reviewable commit there, not a competing specification packet. Files were read from the exact-head CI archive after GitHub metadata verification.

## Housekeeping delivered

`REVIEW-GUIDE.md` supplies the complete thematic human reading route, document-authority distinctions, the different ID families, a plain-language vocabulary, an LLM reading protocol, and a review-note method. `R-MILESTONES.md` covers all 25 top-level R labels and both R3 subphases, with links to document 14.

All 24 numbered documents, plus five overview/implementation companions, receive checked reader context, backlinks and collapsible section menus. No numbered files or existing sections are renamed. The navigation generator changes only marked blocks; existing acceptance IDs and contract-link fixtures remain in place.

The README's stale draft/date label, thematic index, missing Ink link and companion descriptions are reconciled. INDEX points to the live decision register instead of repeating a hand-maintained status count. Document 14's misleading branch layout is replaced with separate foundation, Story, authoring and Realm tracks without changing dependencies. Deferred scripting sections and historical review conclusions are explicitly labeled. Escort is aligned with its already-required chapter-one use.

## Self-review and corrections

- Generated contents must ignore headings inside YAML/code fences and retain stable heading targets. Added fence/slug/collision tests.
- New navigation must not change the authored document body or duplicate itself on regeneration. Added body-preservation and idempotence tests over every routed file.
- Milestone summaries must not omit R6P/R9C or confuse R3A/R3B with top-level releases. Added full coverage and deletion-negative-control checks.
- Reading context must not imply that a draft is accepted or a model test proves a build. Added explicit status/evidence distinctions and reference labels.
- A misleading full-campaign acceptance list and R11 scripting shorthand needed contextual clarification rather than feature removal.
- Whitespace checking caught two newly edited Markdown hard-break lines; converted them to ordinary paragraph separation.

## Adversarial self-review and corrections

This is an implementing-assistant review, not an independent principal or R0 approval.

The checking path rejects malformed/duplicate navigation markers, unclosed code fences, stale menus, missing milestones, broken local file links and missing local heading anchors. Negative tests deliberately introduce these errors. It checks links within this packet only; it does not verify external URLs, validate the entire game grammar, or prove the truth of prose summaries.

The guide cannot become an alternative contract. It points to the governing sections and explicitly retains the conflict rule. Historical research is labeled dated, not reverified. Broad catalogs are separated from release applicability, not deleted. The four-place proof does not replace the 57-room chapter or authorize a legacy-engine port.

## Unresolved content findings

- Document 00 section 5 lists Q1-Q5 and S1-S28, but its full-campaign count says 28 quests. Reconcile the intended total; chapter-one ten-quest scope is unchanged.
- Document 00a section 4 places Hale in the kitchen garden at 14:00, but section 11 requires both novices in the cloister at 14:00. Resolve the intended schedule or test scenario before certification.

These findings are marked at their source and in the review guide. This pass does not claim exhaustive semantic consistency or silently select new story behavior.

## Validation and maintenance

Run from the repository root:

```text
python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py' -v
python3 docs/rewrite-v3/checks/release_scope.py --check
python3 docs/rewrite-v3/checks/packet_navigation.py --check
```

Local result: **36 tests passed** (26 prior contract/planning tests and 10 navigation tests); release scope and navigation checks passed. Exact final-head remote CI belongs in the PR handoff. To regenerate menus after an authored heading change, run `python3 docs/rewrite-v3/checks/packet_navigation.py --write`; generated release scope still uses its existing generator. No legacy-engine tests, production engine, real database fault test, physical device, or new external research is claimed.

# V3 audit follow-through — 2026-09-22

## Scope and owner direction

Base: `1f5f32c8472a2378b881e93cf16dcd80d73ae6f3`.

The owner reaffirmed that v3 is an engine rebuild from scratch and that the full first-chapter scope is appropriate, including LLM-assisted world creation and review. Chapter one remains 57 rooms, 10 quests, and two endings. The smaller proof is an earlier engineering/player-feedback slice, NOT a smaller release or a requirement to rework the legacy engine.

This branch addresses the audit's recommended next work: correct the seed fixtures and admission/outcome contracts; reconcile the index; make R1 measurable without implementing all of chapter one; make release capability applicability explicit; and specify a clean-room playable proof before the full chapter. Executable specification checks are not a production engine, a completed mobile proof, or acceptance of R0/R1.

## Planned changes

- Correct activation-before-event credit, replay versus duplicate rejection, failed attempts versus rejected commands, and ambiguous commit recovery.
- Resolve retries before current-world action validation while authenticating access to the stored result; distinguish canonical invocation intent from resolved semantic command.
- Reconcile index summaries with in-decision proposed events, typed facts/events, general connections, and supported save compatibility.
- Revise the proposed R1 envelope: tiny semantic workload plus synthetic volume, common server load, component timing, UI responsiveness, fault classes, and evidence requirements. No threshold is deemed accepted or measured by this PR.
- Preserve chapter-one scope, generate its capability/applicability checklist, add an earlier playable proof, and decouple offline content/Builder work from Realm production.
- Add machine-readable small contract fixtures and standard-library validation tests; record exactly what those tests do and do not prove.
- Apply relevant Ink findings to concrete fixture/oracle requirements rather than adding another broad architecture layer.

## Workflow and evidence

Draft PR first, then implementation, self-review, corrections, adversarial self-review, corrections, exact-head validation, and a truthful handoff. No auto-merge. An adversarial pass by the implementing assistant is NOT independent review. Physical iOS/Android builds, R1 measurements, and player testing are separate evidence gates and must not be reported as completed here.

## Status

Planning commit. Implementation and validation pending.

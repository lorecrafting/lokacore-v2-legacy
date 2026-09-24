# Owner decision: quick R1-A3, then R2 — 2026-09-24

Relayed verbatim by the coordinating assistant (Claude Code, Claude Opus) from the
owner's chat messages. Not self-review; not an accepted contract amendment.

## Owner's words

> Do we really need to do all the measurements? will this inform how things are
> built? or is this just a check? What if i'm relatively confident it will handle
> loads and we can optimize later? So we can get the actual new clean repo going
> faster?

After the assistant recommended a quick A3 (below), the owner answered:

> yes lets go with the quick a3 then r2, the thing you recommend

## The recommendation the owner accepted (assistant's words, summarized)

1. **Quick A3.** Build the Medium/Stress synthetic state generator and time decision,
   SQLite commit and end to end on the Pixel 3a release build (the slower,
   floor device) and on the M1 common host, one run each. This targets the one
   risk that could change the plan: whole-state copy/encode per step on an old
   phone.
2. **If well under the envelope thresholds, the owner accepts candidate C.** The
   full A3 gates (three 10,000-input runs per device, iPhone timing, memory
   ceilings, UI responsiveness, 100-instance load, cold restore) move to R6P and
   R10 as recorded, owner-accepted risk. If close to or over a threshold, stop and
   report before R2.
3. **Correctness items carried from the R1-A2 review move into R2's production
   tests**: a failed COMMIT on the phone, stale-view duplicate delivery as a
   scheduled fault, and one defined outbox durability rule.
4. **PREP-03 owner disposition**, then R1-A5 / R2 fresh repository.

## Consequence for the envelope

Envelope §2 and §12 say unmeasured rows cannot pass. This decision therefore needs a
contract amendment (proposed as ADR-071, entering document 16 at the next contract
amendment together with ADR-070) that records the deferral and the accepted risk.
Nothing here changes a numeric threshold.

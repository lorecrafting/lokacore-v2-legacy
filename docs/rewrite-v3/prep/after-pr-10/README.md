# R0 / PREP-02 handoff — still blocked

This is an **incomplete real handoff**, not a synthetic passing experiment.
Source baseline: `864ed383de7657107914502a919491dd8ff9f705`. That is an observed
repository revision, NOT an accepted R0 hash. The owner must accept the exact
post-review contract; it must not be filled automatically with this PR's head.

[Work order](../../r1-work-package.md) · [Focused review](../../reviews/2026-09-22-prep-followup.md)
· [Tooling coverage](../../spec_tools/README.md) · [Downloaded representation review](../downloaded-representation.md)

## Status

| Work | Established | Still required |
|---|---|---|
| PREP-01 | Baseline reproduced; bounded source/fixture review and counterexample corrections completed. | Review/merge this follow-up; this assistant's self/adversarial review is not independent acceptance. |
| PREP-02 | Unchanged seven-input hashes retained; linked pending R0/oracle/setup records; actual editing-host/tool availability recorded. | Exact R0 acceptance/cutover, real qualifying hardware inventory, stable candidate toolchain/lock files, identified authors, independently reviewed expected answers and actual setup. |
| PREP-03 | Concrete representation specimen, shipped API boundary and current official policy risks retained. | Owner's investment disposition, later exact-app/current-policy release review. No store approval claimed. |
| R1-A1 | **NOT AUTHORIZED TO START.** Candidate A and stateless order unchanged. | All PREP-02 prerequisites, not merely green abstract tests. |

## What the records do and do not establish

`host-observation.json` records the Linux editing container, Git/Python/Node
versions and absent local Elixir/OTP executables. It is not the owner's M1+ server,
iPhone SE 2 or Galaxy A14, and is not used to populate those inventory fields.
Pinned CI separately verifies the tooling-only Elixir/OTP runtime; it is still
not qualifying R1 hardware, an R1 dependency lock or a benchmark.

`setup.pending.json` preserves manifest schema 1 and contains actual SHA-256
values for the existing seven reviewed input files. Its references point to
honestly pending records, not fabricated approvals. The `accepted_spec_commit`,
actual phones/server, candidate authors, candidate toolchain and lock remain
empty. The pending setup digest is computable but does not approve anything.
The original blank template remains unchanged and also fails the ready gate.

## Exact completion sequence

1. **Owner / R0:** accept an exact reviewed commit, confirm the normative file set,
   ADR accepted/provisional/deferred states, outstanding gates, amendment authority
   and the fresh-repository cutover destination/rule. Record the approval rather
   than inferring it from a merge. No new production repository is created here.
2. **Device/setup preparer:** establish availability, exact model/SKU/SoC/physical
   RAM/OS/build/architecture for both qualification phones and the common M1+
   server host. Recheck current native dependency compatibility against the
   approved floor. A newer phone or simulator needs an explicit disposition;
   it is not silently substituted. Retain stable candidate dependency/lock bytes
   for all 14 named toolchain entries; the tooling project's pins are not that lock.
3. **Independent oracle reviewer:** inspect expected values, failure cases and
   baseline hashes, including due-job/restore obligations noted in the review.
   Identify expected-answer authors and reviewer; bind the accepted contract and
   exact inputs. A second implementation agreeing with these answers is not
   independent approval. Use `subject_author_ids` and the two explicit separation
   declarations; the owner verifies identities and evidence outside the checker.
4. **Independent setup reviewer:** review actual devices, configuration and lock
   files. Identify setup preparers, bind the exact `setup_digest`, and record an
   approval. Recompute any affected hashes/digests after changes; do not reuse a
   receipt for a modified setup. Then set status to `setup_reviewed` and run the
   Mix gate plus the temporary Python comparison gate. Mechanical success still
   requires truthful/authenticated retained evidence.

Run from `docs/rewrite-v3/spec_tools` (both must currently fail):

```sh
mix loka.readiness --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root ..
python3 ../checks/readiness.py --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root ..
```

Only then create the separate disposable stateless TypeScript R1-A1 workspace,
with an Elixir BEAM harness. R1-A2 supplies actual mobile/SQLite evidence; A3
supplies measured load/latency/faults; A4 supplies independent selection. Passing
A ends comparison; B then C require documented preceding failures. R6P remains
later playable proof, and chapter one remains 57 rooms / 10 quests / two endings.

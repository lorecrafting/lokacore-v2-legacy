# Proposed ADR-071 and ADR-072 — 2026-09-24

**Status: proposed.** Written by the coordinating assistant (Claude Code, Claude
Opus), the candidate author's side. Like ADR-070 in
[a2-plan.md](after-pr-10/a2-plan.md), these enter document 16 only at the next
contract amendment; document 16 is not edited here. Evidence:
[r1-a3-quick-evidence/](../r1-a3-quick-evidence/README.md) and
[touched-1/](../r1-a3-quick-evidence/touched-1/README.md).

## Owner decisions these rest on (verbatim, relayed)

- Quick A3 then R2: "yes lets go with the quick a3 then r2, the thing you
  recommend" ([owner-decision-a3-2026-09-24.md](after-pr-10/owner-decision-a3-2026-09-24.md)).
- Rebuild the phone path before R2: "okay lets do option 1" (retained in
  [variant-touched-declaration.md](../r1-a3-quick-evidence/variant-touched-declaration.md)).
- Save design: "idk i leave it up to you" (the owner delegated the persistence
  shape to the assistant; ADR-072 is the assistant's decision under that delegation).
- Accept C with the checkpoint risk recorded: asked "Accept C with the checkpoint
  risk recorded, and proceed?", the owner answered "yes please go ahead".

## ADR-071 — Candidate C selected on a quick A3; remaining R1 gates deferred

**Decision.** Candidate C (Elixir on the server, TypeScript on Hermes) is selected
for R2 with the `touched-1` boundary variant. Candidates B and A are not built.
This selection rests on a quick A3, not the full envelope procedure, by owner
decision.

**Measured (one run, 1,000 warm-up + 2,000 measured per model, nearest rank):**

| Row | Threshold | Pixel 3a, touched-1 | M1 server | Status |
|---|---|---|---|---|
| Decision p99, Tiny / Medium / Stress | 10 / 30 / 80 ms | 0.49 / 0.71 / 0.89 | 0.011 / 0.018 / 0.030 | pass |
| Medium end to end p95 / p99 | 100 / 200 ms | 10.9 / 17.4 | 5.4 / 5.9 | pass |
| Checkpoint round trip, Tiny / Medium / Stress | 10 / 50 / 200 ms | max 5.8 / 861 / 488 | 0.09 / 16.2 / 117.5 | **phone Medium and Stress fail**; others pass or close |

The stateless variant's failing results stay retained beside these. `touched-1`
was declared before tuning (envelope §6).

**Recorded failure, accepted as risk.** The phone checkpoint round trip (full
canonical save, read back, validate) fails at Medium and Stress. Under ADR-072 a
full checkpoint is an export or backup operation, not part of any player action,
but the §7 row is unchanged and stays failed. It must be re-measured at R6P on the
production save format, together with the 3 second cold restore ceiling.
Structural sharing cannot reduce it; faster canonical parse/encode or a different
export encoding may. A Rust candidate would still move the same bytes through
SQLite, so this failure alone is not a reason to evaluate B.

**Deferred to R6P and R10 (unmeasured, not passed):** iPhone timing, three runs of
10,000 inputs per device, memory and retention (§8), UI responsiveness (§5), cold
restore (§7), the 100-instance server load and scheduler impact (§6), reaction and
scene decision work, faults under load, and the R1-A2 review carry-overs (a failed
COMMIT on the phone, stale-view duplicate delivery as a scheduled fault, one
defined outbox durability rule), which become R2 production tests.

**Reopens if** an R6P or R10 measurement of a deferred row fails and the cause is
in the TypeScript-on-Hermes kernel rather than host I/O; then B is evaluated as
envelope §2 orders. No threshold changes.

## ADR-072 — Online and local persistence shape

**Decision.**
1. The world owner holds the world in memory; rules read only memory.
2. Rules are pure: `decide(state, command) → proposal` (changed values, receipt,
   events). They never write memory or storage.
3. The host commits the proposal in one transaction: only the changed rows, plus
   the receipt and outbox rows. Then it adopts the proposal into memory, then
   replies. Disk first, memory second, one action per transaction.
4. Kernels use structural sharing: a step allocates new values only along the
   paths it changes.
5. No periodic or rest-point snapshots. The rows are always the complete current
   state. A full canonical checkpoint exists only for export, backup and the §7
   round trip. In-fiction rest points (inns, campfires) carry no persistence role.
6. If sustained write load ever needs it, group commit (several actions in one
   transaction, each still durable before its reply) is the first remedy.

**Why.** Every accepted attempt must be durable before the player sees it (§7),
which prevents force-quit rerolls, gives exact replay, and protects later
commerce. Measured cost of per-action commits is small (Pixel 6 to 11 ms p99 for
about 190 bytes; M1 1 to 3 ms even for whole-state writes). The measured problem was
whole-state copying, which items 4 and 3 remove.

**Unchanged.** ADR-006 (PostgreSQL online, SQLite offline; the owner reconfirmed
PostgreSQL online on 2026-09-24) and ADR-007 (one owner per world domain).
Production code uses Ecto with Ecto-managed migrations on the server; the
per-row schema is an R2+ design task.

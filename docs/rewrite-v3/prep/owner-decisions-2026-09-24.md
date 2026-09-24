# Owner decisions without their own file — 2026-09-24

Relayed verbatim by the coordinating assistant (Claude Code, Claude Opus) from the
owner's chat messages, in order. The question each answers is summarized in the
assistant's words. No checker can verify these quotes against the chat.

1. **ADR-006 stays.** After a drafted SQLite-online amendment and its risks:
   > ok lets keep it postgres for online version

   The draft branch was deleted; ADR-006 is unchanged.
2. **Rebuild the phone path before R2** (touched-1 variant):
   > okay lets do option 1
3. **Persistence shape delegated** (periodic vs per-action saves, snapshots):
   > wait, is snapshots and rest points saving really needed of kernel always computes results and saves to disk? idk i leave it up to you

   The assistant decided ADR-072 under this delegation.
4. **Accept C with the checkpoint risk recorded, and proceed:**
   > yes please go ahead
5. **Repository after R2 starts.** Asked whether to rename the current repository:
   > no its not deployed on fly.io and nothing else depends on it, lokacore-v2-legacy would be nice for the old repo

   Plan: rename `lorecrafting/lokacore` to `lorecrafting/lokacore-v2-legacy` and
   archive it; create a new `lorecrafting/lokacore` for R2.

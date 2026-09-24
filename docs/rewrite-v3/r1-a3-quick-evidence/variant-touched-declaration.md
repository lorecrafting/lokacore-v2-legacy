# Boundary variant declaration: `touched-1` — 2026-09-24

Declared before any tuning or measurement of the variant, as envelope §2 and §6
require. The stateless variant's failing results in this folder stay retained
and unchanged; this variant does not revise expected semantics or thresholds.

Owner decision (relayed verbatim by the coordinating assistant): "okay lets do
option 1" — rebuild the phone path with structural sharing and changed-row
persistence, then rerun the quick A3 on the Pixel 3a before R2.

## What changes

1. **TypeScript kernel, structural sharing.** No whole-state deep copy per step.
   A step builds new objects only along the paths it changes; untouched
   sub-values keep their identity. The `delta` is computed from the touched
   top-level keys, not by encoding and comparing every key.
2. **Phone host, changed-row persistence.** Durable state is stored as rows
   keyed by top-level memory key (and by element where a key holds a large
   collection). A step's transaction writes only the rows it changed plus its
   receipt. Loading reads the rows back into the canonical state.
3. **Timing boundary.** Encoding the full `HOST` for the runner protocol or the
   differential is test output, not part of decision/commit/end to end, and is
   excluded from those timers. It is timed separately and reported.

## What does not change

- Semantics. Every fixture suite and the Elixir-vs-TypeScript differential must
  stay byte-identical, including the on-device differential of R1-A2.
- Thresholds, the synthetic state sizes and the percentile method.
- The Elixir kernel and server host (they passed).
- The checkpoint round trip stays a full canonical save, read back and validated.

## Also recorded before measuring

The `r1-scale-1` command mix was skewed (Lantern clock reached 23 during warm-up,
so every wait/activate/choose in the measured window was rejected). The rerun uses
`r1-scale-2`, which keeps the mix representative. Both versions are retained.

// Summarizes a quick R1-A3 run (the same code for the phone and the M1 server).
// Usage: node scripts/scale-summary.mjs <a3-samples.csv> <a3-run.json>  > summary.json
// Percentiles are nearest rank: the ceil(p/100 * n)-th smallest sample (1-based).
// Gate verdicts (owner decision 2026-09-24): pass when every gated percentile is below
// half its threshold, close when one is at or above half but none over, fail when one
// is over. Gates use the accepted class; the other classes are reported beside it.
import { readFileSync } from 'node:fs';

const [csv, runPath] = process.argv.slice(2);
const [header, ...lines] = readFileSync(csv, 'utf8').trim().split('\n');
const cols = header.split(',');
const rows = lines.map((l) => Object.fromEntries(l.split(',').map((v, i) => [cols[i], v])));
const run = JSON.parse(readFileSync(runPath, 'utf8'));

const DECISION = { tiny: [2, 5, 10], medium: [5, 15, 30], stress: [15, 40, 80] };
const E2E = { medium: [null, 100, 200] };
const CHECKPOINT = { tiny: 10, medium: 50, stress: 200 };
const METRICS = ['admission_ms', 'decision_ms', 'encode_ms', 'commit_ms', 'projection_ms', 'e2e_ms'];

const rank = (sorted, p) => sorted[Math.max(0, Math.ceil((p / 100) * sorted.length) - 1)];
function stats(values) {
  const s = values.slice().sort((a, b) => a - b);
  if (!s.length) return { n: 0 };
  return { n: s.length, p50: rank(s, 50), p95: rank(s, 95), p99: rank(s, 99), max: s[s.length - 1] };
}
function gate(st, limits) {
  const ps = ['p50', 'p95', 'p99'];
  let verdict = 'pass';
  ps.forEach((p, i) => {
    const t = limits[i];
    if (t == null) return;
    if (st[p] > t) verdict = 'fail';
    else if (st[p] >= t / 2 && verdict !== 'fail') verdict = 'close';
  });
  return { thresholds_ms: Object.fromEntries(ps.map((p, i) => [p, limits[i]])), verdict };
}

const classes = {
  all: () => true,
  accepted: (r) => r.outcome === 'accepted',
  accepted_state_write: (r) => r.outcome === 'accepted' && r.state_write === '1',
  rejected: (r) => r.outcome === 'rejected',
  replayed: (r) => r.outcome === 'replayed',
};

const models = run.models.map((m) => {
  const mine = rows.filter((r) => r.model === m.model);
  const by = {};
  for (const [c, pred] of Object.entries(classes)) {
    const sel = mine.filter(pred);
    by[c] = Object.fromEntries(METRICS.map((k) => [k, stats(sel.map((r) => Number(r[k])))]));
  }
  const counts = {};
  for (const r of mine) {
    const k = `${r.action}:${r.outcome}`;
    counts[k] = (counts[k] || 0) + 1;
  }
  const cp = stats(m.checkpoint_round_trip_us.map((us) => us / 1000));
  const acc = by.accepted;
  return {
    model: m.model,
    initial_state_bytes: m.initial_state_bytes,
    final_state_bytes: m.final_state_bytes,
    final_state_sha256: m.final_state_sha256,
    measured_steps: mine.length,
    outcome_counts: Object.fromEntries(Object.keys(classes).map((c) => [c, by[c].e2e_ms.n])),
    action_outcome_counts: Object.fromEntries(Object.entries(counts).sort()),
    stats_ms: by,
    checkpoint_round_trip_ms: { ...cp, samples_ms: m.checkpoint_round_trip_us.map((us) => us / 1000) },
    gates: {
      decision_accepted: gate(acc.decision_ms, DECISION[m.model]),
      ...(E2E[m.model] ? { e2e_accepted: gate(acc.e2e_ms, E2E[m.model]) } : {}),
      checkpoint_round_trip_max: {
        threshold_ms: CHECKPOINT[m.model],
        observed_max_ms: cp.max,
        verdict: cp.max > CHECKPOINT[m.model] ? 'fail' : cp.max >= CHECKPOINT[m.model] / 2 ? 'close' : 'pass',
      },
    },
    sqlite: m.sqlite,
    receipts: m.receipts,
  };
});

console.log(JSON.stringify({
  host: run.host,
  percentile_method: 'nearest rank: ceil(p/100*n)-th smallest, 1-based',
  verdict_rule: 'pass: every gated percentile < threshold/2; close: some >= threshold/2, none over; fail: some > threshold',
  wall_ms: run.wall_ms,
  runtime: run.runtime ?? null,
  models,
}, null, 2));

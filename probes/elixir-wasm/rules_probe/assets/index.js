import { Popcorn } from "@swmansion/popcorn";
import { decide } from "./rules.js";

const WARMUP = 1000;
const N = 10000;
const start = { hp: 100, x: 10, y: 10, rng: 2463534242, gold: 0 };
const actionFor = (i) => (i % 2 === 0 ? ["move", 1, -1] : ["attack", 12]);
const pct = (xs, p) => xs[Math.min(xs.length - 1, Math.floor((p / 100) * xs.length))];
const same = (a, b) => ["hp", "x", "y", "rng", "gold"].every((k) => a[k] === b[k]);

async function run() {
  const t0 = performance.now();
  const booted = await Popcorn.init({ onStdout: () => {} });
  if (!booted.ok) throw new Error("boot: " + JSON.stringify(booted.error));
  const vm = booted.data;
  const bootMs = performance.now() - t0;

  const call = async (req) => {
    const r = await vm.genserver.call("rules", req, { timeoutMs: 30000 });
    if (!r.ok) throw new Error("call: " + JSON.stringify(r.error));
    return r.data;
  };

  // Parity: every step of the Elixir rule must equal the JavaScript mirror.
  let ex = start, js = start, mismatches = 0;
  for (let i = 1; i <= WARMUP; i++) {
    ex = await call(["decide", ex, actionFor(i)]);
    js = decide(js, actionFor(i));
    if (!same(ex, js)) mismatches++;
  }

  // Round trip: page -> worker -> BEAM -> worker -> page, one decision each.
  const rt = [];
  let s = start;
  for (let i = 1; i <= N; i++) {
    const a = performance.now();
    s = await call(["decide", s, actionFor(i)]);
    rt.push(performance.now() - a);
  }
  rt.sort((a, b) => a - b);

  // Kernel only: the same N decisions inside the VM, timed by :timer.tc.
  const [vmUs, vmFinal] = await call(["loop", start, N]);

  // Baseline: the same N decisions in plain JavaScript on the page.
  const b0 = performance.now();
  let jb = start;
  for (let i = 1; i <= N; i++) jb = decide(jb, actionFor(i));
  const jsMs = performance.now() - b0;

  vm.deinit();
  return {
    userAgent: navigator.userAgent,
    crossOriginIsolated: self.crossOriginIsolated,
    bootMs,
    parity: { steps: WARMUP, mismatches, loopFinalMatchesJs: same(vmFinal, jb) },
    roundTripMs: { n: N, p50: pct(rt, 50), p95: pct(rt, 95), p99: pct(rt, 99), max: rt[rt.length - 1] },
    kernelInVmUsPerDecision: vmUs / N,
    plainJsUsPerDecision: (jsMs * 1000) / N,
  };
}

window.__results = run().catch((e) => ({ error: String(e && e.stack || e) }));

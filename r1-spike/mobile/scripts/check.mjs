// M1-side checks of what the phone wrote. Node 24 (imports the kernel's .ts directly).
//
//   node scripts/check.mjs diff <requests.jsonl> <elixir.jsonl> <device responses.jsonl>
//     Byte-for-byte line comparison, then the same comparison with one byte of one
//     device line altered, which must be reported as a mismatch. Exit 1 unless both hold.
//
//   node scripts/check.mjs faults <device faults.jsonl> <source map> <out faults.jsonl>
//     For every record: verdict pass, and its recovered HOST and next step record equal
//     to the Elixir runner's (the model, run independently here) for the commit
//     disposition SQLite showed. JS stacks are symbolicated through the release source
//     map with metro-symbolicate and added as `error.stack_symbolicated`. Exit 1 on any failure.
import { readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { canonical, parse } from '../../ts/src/kernel/codec.ts';

const here = (p) => fileURLToPath(new URL(p, import.meta.url));
const lines = (buf) => {
  const out = [];
  let s = 0;
  for (let i = 0; i < buf.length; i++) if (buf[i] === 0x0a) (out.push(buf.subarray(s, i)), (s = i + 1));
  if (s < buf.length) out.push(buf.subarray(s));
  return out;
};

function compare(a, b) {
  const n = Math.max(a.length, b.length);
  const mismatches = [];
  for (let i = 0; i < n; i++) if (!a[i] || !b[i] || Buffer.compare(a[i], b[i]) !== 0) mismatches.push(i + 1);
  return { lines_elixir: a.length, lines_device: b.length, identical: n - mismatches.length, mismatches };
}

function elixir(requestLines) {
  const r = spawnSync('mise', ['exec', 'elixir@1.20.4', 'erlang@28.4', '--', 'mix', 'r1.runner'], {
    cwd: here('../../elixir'), input: requestLines.map((l) => l + '\n').join(''), maxBuffer: 1 << 28,
  });
  if (r.status !== 0) throw new Error('mix r1.runner: ' + r.stderr);
  return r.stdout.toString('utf8').split('\n').slice(0, -1);
}

const [mode, ...args] = process.argv.slice(2);
if (mode === 'diff') {
  const [requests, ex, dev] = args.map((p) => readFileSync(p));
  const gen = readFileSync(here('../requests.gen.ts'), 'utf8').match(/'([A-Za-z0-9+/=]*)'/)[1];
  const embedded = Buffer.compare(Buffer.from(gen, 'base64'), requests) === 0;
  const e = lines(ex);
  const d = lines(dev);
  const real = compare(e, d);
  const k = Math.floor(d.length / 2);
  const altered = d.map((l, i) => (i === k ? Buffer.from(l).fill(l[l.length >> 1] ^ 1, l.length >> 1, (l.length >> 1) + 1) : l));
  const injected = compare(e, altered);
  const ok = embedded && real.mismatches.length === 0 && real.lines_device === lines(requests).length
    && injected.mismatches.length === 1 && injected.mismatches[0] === k + 1;
  console.log(JSON.stringify({ requests_embedded_in_app_equal_requests_jsonl: embedded, request_lines: lines(requests).length, real,
    injected: { altered_line: k + 1, change: 'middle byte of the device line XOR 0x01', ...injected }, result: ok ? 'pass' : 'fail' }, null, 2));
  process.exit(ok ? 0 : 1);
} else if (mode === 'faults') {
  const [src, map, out] = args;
  const recs = readFileSync(src, 'utf8').trim().split('\n').map((l) => parse(l));
  const reqs = recs.map((r) => {
    const n = r.fault.step;
    const cmds = [...r.commands.slice(0, r.sqlite_committed ? n + 1 : n), { op: 'recover' }, r.commands[n + 1]];
    return canonical({ fn: 'world.run', world: r.world, initial: r.initial, commands: cmds });
  });
  const got = elixir(reqs).map((l) => parse(l));
  let failures = 0;
  const outLines = recs.map((r, i) => {
    const m = got[i];
    const elixirAgrees = canonical(m[m.length - 2].state) === canonical(r.recovered) && canonical(m[m.length - 1]) === canonical(r.next);
    if (r.verdict !== 'pass' || !elixirAgrees) failures++;
    if (r.error?.stack) {
      const s = spawnSync(process.execPath, [here('../node_modules/metro-symbolicate/src/index.js'), map], { input: r.error.stack });
      r.error.stack_symbolicated = s.status === 0 ? s.stdout.toString('utf8') : 'metro-symbolicate failed: ' + s.stderr;
    }
    r.checks.elixir_runner_agrees = elixirAgrees;
    console.log([r.fault.point, r.fault.kind, r.world, 'committed=' + r.sqlite_committed, r.verdict, 'elixir_agrees=' + elixirAgrees].join(' '));
    return canonical(r);
  });
  writeFileSync(out, outLines.map((l) => l + '\n').join(''));
  console.log(`cases=${recs.length} failures=${failures}`);
  process.exit(failures === 0 && recs.length === 19 ? 0 : 1);
} else {
  console.error('usage: check.mjs diff|faults ...');
  process.exit(2);
}

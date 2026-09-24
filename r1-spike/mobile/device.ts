// R1-A2 on-device runs: the differential over the bundled requests and the
// injected-fault cases. Platform-free: App.tsx supplies SQLite, file output and
// process death; scripts/local-check.mjs runs the same code on node:sqlite.
import { canonical, canonicalBytes, clone, has, obj, parse, utf8 } from '../ts/src/kernel/codec.ts';
import type { Json, JsonObject } from '../ts/src/kernel/codec.ts';
import { handleLine } from '../ts/src/kernel/protocol.ts';
import { sha256Hex } from '../ts/src/kernel/sha256.ts';
import { WORLDS, hostJson, initialHost, step } from '../ts/src/kernel/world.ts';
import type { Host, World } from '../ts/src/kernel/world.ts';
import { CommitUnknown, DurableHost, POINTS, readBack, reset } from './host.ts';
import type { Db, Inject } from './host.ts';

export type Env = {
  host: string; // e.g. "phone-android"
  open(name: string): Db;
  kill(): void; // must not return
  write(name: string, text: string): void; // an evidence file the M1 pulls
};

const o = (pairs: { [k: string]: Json }): JsonObject => Object.assign(obj(), pairs);

/** UTF-8 decoding that fails on any invalid sequence, as the Node runner's fatal TextDecoder does. */
export function decodeUtf8(b: Uint8Array): string {
  let s = '';
  for (let i = 0; i < b.length; ) {
    const c = b[i];
    const n = c < 0x80 ? 0 : c >= 0xc2 && c <= 0xdf ? 1 : c >= 0xe0 && c <= 0xef ? 2 : c >= 0xf0 && c <= 0xf4 ? 3 : -1;
    if (n < 0) throw new Error('utf8');
    let cp = n === 0 ? c : c & (0x3f >> n);
    for (let k = 1; k <= n; k++) {
      const d = b[i + k];
      if (d === undefined || (d & 0xc0) !== 0x80) throw new Error('utf8');
      cp = (cp << 6) | (d & 0x3f);
    }
    if ((n === 2 && cp < 0x800) || (n === 3 && (cp < 0x10000 || cp > 0x10ffff)) || (cp >= 0xd800 && cp <= 0xdfff)) throw new Error('utf8');
    s += String.fromCodePoint(cp);
    i += n + 1;
  }
  return s;
}

function durableRun(db: Db, req: JsonObject): Json[] {
  const world = WORLDS[req.world as string]();
  reset(db, has(req, 'initial') ? (req.initial as JsonObject) : world.initial());
  const host = new DurableHost(world, db);
  return (req.commands as Json[]).map((c) => host.step(c));
}

/**
 * One response line per request line (split on 0x0a, as the Node runner does).
 * `world.run` requests the model accepts go through the durable host; the rest
 * through the kernel's line handler. `hostMismatches` counts lines where the
 * durable host's bytes differ from the in-memory model host's.
 */
export function differential(db: Db, input: Uint8Array): { lines: string[]; hostMismatches: number; worldRuns: number } {
  const lines: string[] = [];
  let hostMismatches = 0;
  let worldRuns = 0;
  let start = 0;
  for (let i = 0; i <= input.length; i++) {
    if (i < input.length && input[i] !== 0x0a) continue;
    if (i === input.length && start === i) break;
    let text: string | null;
    try {
      text = decodeUtf8(input.subarray(start, i));
    } catch {
      text = null;
    }
    start = i + 1;
    const model = handleLine(text ?? '');
    let line = model;
    if (text !== null && model.startsWith('[')) {
      worldRuns++;
      try {
        line = canonical(durableRun(db, parse(text) as JsonObject));
      } catch (e) {
        line = canonical(o({ error: 'host_exception', message: String(e) }));
      }
      if (line !== model) hostMismatches++;
    }
    lines.push(line);
  }
  return { lines, hostMismatches, worldRuns };
}

// ---------------------------------------------------------------- injected faults

export const KINDS = ['raise', 'io_error', 'commit_unknown', 'kill'];

type Case = { world: string; seed: number; initial: JsonObject; commands: JsonObject[]; fault: { step: number; point: string; kind: string } };

const invoke = (id: string, action: string, input?: JsonObject): JsonObject => {
  const request = o({ id, actor: 'hero', action });
  if (input) request.input = input;
  return o({ op: 'invoke', request });
};

// Each case: a legal prefix, the faulted attempt (an accepted, state-changing
// command), then the same command again (same identity: replay or retry).
const SCRIPTS: { [w: string]: JsonObject[] } = {
  'tiny-event': [invoke('a', 'activate'), invoke('m', 'move', o({ direction: 'north' })), invoke('t', 'take')],
  'tiny-state': [invoke('a', 'activate'), invoke('m', 'move', o({ direction: 'north' })), invoke('t', 'take')],
  lantern: [invoke('a', 'activate'), invoke('m1', 'move', o({ direction: 'north' })), invoke('m2', 'move', o({ direction: 'east' }))],
};

export const CASES: Case[] = POINTS.flatMap((point) => KINDS.filter((k) => k !== 'commit_unknown' || point === 'in_persistence').map((kind) => ({ point, kind })))
  .map(({ point, kind }, i) => {
    const world = ['tiny-event', 'tiny-state', 'lantern'][i % 3];
    const initial = WORLDS[world]().initial();
    initial.rng = [i + 1, i % 2 ? 0x9e3779b9 : 2, 3, 4]; // nonzero; the first roll is 20 (taken) or 75 (check_failed)
    const script = SCRIPTS[world];
    const n = script.length - 1;
    return { world, seed: i + 1, initial, commands: [...script, clone(script[n])], fault: { step: n, point, kind } };
  });

/** Committed or not, as SQLite must show it after this fault. */
function wantCommitted(point: string, kind: string): boolean {
  if (point === 'in_persistence') return kind === 'commit_unknown';
  return point !== 'pre_decision' && point !== 'post_decision_pre_commit';
}

function modelRun(world: World, initial: JsonObject, commands: JsonObject[]): { host: Host; records: JsonObject[] } {
  let host = initialHost(world, initial);
  const records = commands.map((c) => {
    const r = step(world, host, c);
    host = r.host;
    return r.record;
  });
  return { host, records };
}

function stackOf(e: unknown): Json {
  if (e === null) return null;
  const err = e as { name?: string; message?: string; stack?: string };
  return o({ name: String(err.name), message: String(err.message), stack: err.stack === undefined ? null : String(err.stack) });
}

/** Run case `c` up to and including the fault. Returns the caught error, or never returns (kill). */
function runToFault(env: Env, db: Db, c: Case, h: Db, index: number): { error: unknown; fenced: Json } {
  const world = WORLDS[c.world]();
  reset(db, c.initial);
  const host = new DurableHost(world, db);
  for (const cmd of c.commands.slice(0, c.fault.step)) host.step(cmd);
  const s = readBack(db);
  const diag = o({
    case: index, step: c.fault.step, point: c.fault.point, kind: c.fault.kind, command: c.commands[c.fault.step],
    durable_revision: s.durable.revision, receipts: Object.keys(s.receipts).length, launch: launches(h),
  });
  db.all('INSERT INTO diag(record) VALUES (?)', canonical(diag)); // durable before the fault
  if (c.fault.kind === 'kill') h.all('INSERT OR REPLACE INTO progress VALUES (?, ?)', 'armed', index);
  let fired = false;
  const at: Inject = (point) => {
    if (point !== c.fault.point || fired) return;
    fired = true;
    if (c.fault.kind === 'raise') throw new Error('injected raise at ' + point);
    if (c.fault.kind === 'io_error') diskFull(db);
    if (c.fault.kind === 'kill') env.kill();
    if (c.fault.kind === 'commit_unknown') return 'discard_commit';
  };
  let error: unknown = null;
  let fenced: Json = null;
  try {
    host.step(c.commands[c.fault.step], at);
  } catch (e) {
    error = e;
  }
  if (!fired) error = new Error('fault point not reached');
  if (error instanceof CommitUnknown) fenced = host.step(c.commands[c.fault.step + 1]); // refused while in doubt
  return { error, fenced };
}

/** A real SQLite write failure: cap the file at its current size, then write past it (SQLITE_FULL). */
function diskFull(db: Db): void {
  const one = (sql: string): number => Object.values(db.all(sql)[0])[0] as number;
  const pages = one('PRAGMA page_count');
  const bytes = (one('PRAGMA freelist_count') + 2) * one('PRAGMA page_size');
  one('PRAGMA max_page_count = ' + pages);
  try {
    db.all('INSERT INTO ballast VALUES (zeroblob(?))', bytes);
  } finally {
    one('PRAGMA max_page_count = 4294967294');
  }
  throw new Error('io_error: the capped write succeeded');
}

/** After the fault (same process or a relaunch): recover from SQLite only and judge against the model. */
function judge(env: Env, db: Db, c: Case, error: unknown, fenced: Json, kill: JsonObject | null): string {
  const world = WORLDS[c.world]();
  const n = c.fault.step;
  const host = new DurableHost(world, db); // recovery reads SQLite only
  const committed = has(host.host().receipts, (c.commands[n].request as JsonObject).id as string);
  const recovered = hostJson(host.host());
  const next = host.step(c.commands[n + 1]);
  const m = modelRun(world, c.initial, [...c.commands.slice(0, committed ? n + 1 : n), o({ op: 'recover' }), c.commands[n + 1]]);
  const want = o({ recovered: m.records[m.records.length - 2].state, next: m.records[m.records.length - 1] });
  const errorOk =
    c.fault.kind === 'raise' ? String((error as Error)?.message).startsWith('injected raise')
    : c.fault.kind === 'io_error' ? /full/i.test(String((error as Error)?.message))
    : c.fault.kind === 'commit_unknown' ? error instanceof CommitUnknown && ((fenced as JsonObject).result as JsonObject).code === 'commit_pending'
    : kill !== null && (kill.launch_after as number) > (kill.launch_before as number);
  const checks = o({
    fault_realized: errorOk,
    disposition_as_required: committed === wantCommitted(c.fault.point, c.fault.kind),
    recovered_equals_model: canonical(recovered) === canonical(want.recovered),
    next_equals_model: canonical(next) === canonical(want.next),
  });
  const pass = Object.values(checks).every((v) => v === true);
  const diag = db.all('SELECT record FROM diag ORDER BY seq').map((r) => parse(r.record as string));
  return canonical(o({
    host: env.host, world: c.world, seed: c.seed, initial_sha256: sha256Hex(canonicalBytes(c.initial)), initial: c.initial,
    commands: c.commands, fault: o(c.fault), diagnostic: diag[diag.length - 1] ?? null,
    error: c.fault.kind === 'kill' ? null : stackOf(error), fenced, kill,
    sqlite_committed: committed, recovered, next, expected: want, checks, verdict: pass ? 'pass' : 'fail',
  }));
}

function launches(h: Db): number {
  const r = h.all("SELECT v FROM progress WHERE k = 'launches'");
  return r.length ? (r[0].v as number) : 0;
}

/**
 * Resumable: progress lives in the harness database, so a `kill` case ends the
 * process and the next launch finishes it. Writes responses.jsonl once, then
 * faults.jsonl and summary.json when every case has a line. Returns the summary.
 */
export function runAll(env: Env, requests: Uint8Array, extra: JsonObject, onCase: (i: number) => void = () => {}): JsonObject {
  const h = env.open('harness.db');
  h.exec('CREATE TABLE IF NOT EXISTS progress(k TEXT PRIMARY KEY, v); CREATE TABLE IF NOT EXISTS evidence(i INTEGER PRIMARY KEY, line TEXT NOT NULL)');
  h.all('INSERT OR REPLACE INTO progress VALUES (?, ?)', 'launches', launches(h) + 1);
  if (!h.all("SELECT v FROM progress WHERE k = 'differential'").length) {
    const d = differential(env.open('diff.db'), requests);
    const text = d.lines.map((l) => l + '\n').join('');
    env.write('responses.jsonl', text);
    const summary = o({ lines: d.lines.length, world_runs: d.worldRuns, host_mismatches: d.hostMismatches, sha256: sha256Hex(utf8(text)) });
    h.all('INSERT INTO progress VALUES (?, ?)', 'differential', canonical(summary));
  }
  const db = env.open('host.db');
  for (;;) {
    const i = h.all('SELECT count(*) AS n FROM evidence')[0].n as number;
    if (i >= CASES.length) break;
    onCase(i);
    const c = CASES[i];
    const armed = h.all("SELECT v FROM progress WHERE k = 'armed'");
    let line: string;
    if (armed.length && armed[0].v === i) {
      const d = parse(db.all('SELECT record FROM diag ORDER BY seq DESC LIMIT 1')[0].record as string) as JsonObject;
      line = judge(env, db, c, null, null, o({ launch_before: d.launch, launch_after: launches(h) }));
    } else {
      const r = runToFault(env, db, c, h, i);
      line = judge(env, db, c, r.error, r.fenced, null);
    }
    h.exec('BEGIN IMMEDIATE');
    h.all('INSERT INTO evidence VALUES (?, ?)', i, line);
    h.exec("DELETE FROM progress WHERE k = 'armed'");
    h.exec('COMMIT');
  }
  const lines = h.all('SELECT line FROM evidence ORDER BY i').map((r) => r.line as string);
  env.write('faults.jsonl', lines.map((l) => l + '\n').join(''));
  const summary = o({
    host: env.host,
    differential: parse(h.all("SELECT v FROM progress WHERE k = 'differential'")[0].v as string),
    faults: o({ cases: lines.length, pass: lines.filter((l) => (parse(l) as JsonObject).verdict === 'pass').length }),
    launches: launches(h),
    ...extra,
  });
  env.write('summary.json', canonical(summary) + '\n'); // written last: its presence means done
  return summary;
}

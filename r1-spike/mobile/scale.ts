// Quick R1-A3 timing (owner decision 2026-09-24), boundary variant touched-1
// (docs/rewrite-v3/r1-a3-quick-evidence/variant-touched-declaration.md): the TypeScript
// kernel with structural sharing behind a durable SQLite host that writes changed rows,
// at Tiny/Medium/Stress state size. Platform-free: App.tsx supplies expo-sqlite,
// performance.now() and file output on the phone; scripts/scale-local.mjs runs the same
// code on node:sqlite (the M1 preview, not phone evidence).
//
// Per step (one fresh `invoke` command, no faults):
//   admission   the receipt row for this request id (SELECT by primary key), and the kernel HOST
//               value built from process memory: memory, that one receipt (if any), no pending,
//               empty published. Receipts are host storage, not world state, so only the
//               admission-relevant one crosses into the kernel.
//   decision    kernel `step` (world.ts): shallow HOST copy, envelope checks, decide (new objects
//               only along changed paths), delta from the replaced keys, record.
//               In-process on Hermes: there is no further boundary encode/decode.
//   encode      canonical encoding of the changed state rows (host.ts stateWrites: one row per
//               replaced top-level key, one per changed list element), the new receipt and events.
//   commit      BEGIN IMMEDIATE; the changed state rows; INSERT receipt; INSERT outbox events; COMMIT.
//   projection  adopt the new memory and encode the player response {result, events, delta}.
//   e2e         admission + decision + encode + commit + projection.
// Outside e2e: bytes_written (UTF-8 bytes of the text bound in the transaction) and
// host_encode_ms (canonical encoding of the step record's full HOST, which only the runner
// protocol and the differential need).
import { canonical, has, obj, parse } from '../ts/src/kernel/codec.ts';
import type { Json, JsonObject } from '../ts/src/kernel/codec.ts';
import { sha256Hex } from '../ts/src/kernel/sha256.ts';
import { utf8 } from '../ts/src/kernel/codec.ts';
import { WORLDS, step, validMemory } from '../ts/src/kernel/world.ts';
import type { Host } from '../ts/src/kernel/world.ts';
import { loadState, stateWrites } from './host.ts';
import type { Db, Write } from './host.ts';

export type ScaleEnv = {
  host: string;
  open(name: string): Db;
  now(): number; // monotonic milliseconds
  write(name: string, text: string): void;
  log(line: string): void;
};

export const CSV_HEADER = 'host,model,i,action,outcome,code,state_write,admission_ms,decision_ms,encode_ms,commit_ms,projection_ms,e2e_ms,bytes_written,host_encode_ms';
const CHECKPOINTS = 20;

const SCHEMA = `
CREATE TABLE IF NOT EXISTS mem(k TEXT PRIMARY KEY, v TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS mem_items(k TEXT NOT NULL, i INTEGER NOT NULL, v TEXT NOT NULL, PRIMARY KEY(k, i));
CREATE TABLE IF NOT EXISTS receipts(id TEXT PRIMARY KEY, receipt TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS outbox(seq INTEGER PRIMARY KEY, event TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS checkpoint(k TEXT PRIMARY KEY, v TEXT NOT NULL);`;

const f = (ms: number): string => ms.toFixed(4);
const bytes = (params: Array<string | number>): number => params.reduce<number>((n, p) => n + (typeof p === 'string' ? utf8(p).length : 0), 0);

/** Runs one model; returns its CSV rows (measured steps only) and summary facts. */
export function runModel(env: ScaleEnv, input: JsonObject): { rows: string[]; facts: JsonObject } {
  const model = input.model as string;
  const world = WORLDS[input.world as string]();
  const initial = input.initial as JsonObject;
  if (!validMemory(world, initial)) throw new Error(model + ': the kernel rejects the padded initial memory');
  const db = env.open('a3-' + model + '.db');
  db.exec(SCHEMA);
  db.exec('BEGIN IMMEDIATE');
  db.exec('DELETE FROM mem; DELETE FROM mem_items; DELETE FROM receipts; DELETE FROM outbox; DELETE FROM checkpoint');
  for (const [sql, ...params] of stateWrites(obj(), initial)) db.all(sql, ...params);
  db.exec('COMMIT');
  const pragmas = { ...db.all('PRAGMA journal_mode')[0], ...db.all('PRAGMA synchronous')[0] };

  let memory = loadState(db);
  const commands = input.commands as JsonObject[];
  const warmup = input.warmup as number;
  const rows: string[] = [];
  let outboxSeq = 0;
  for (let i = 0; i < commands.length; i++) {
    const command = commands[i];
    const request = command.request as JsonObject;
    const id = request.id as string;
    const t0 = env.now();
    const found = db.all('SELECT receipt FROM receipts WHERE id = ?', id);
    const receipts = obj();
    if (found.length) receipts[id] = parse(found[0].receipt as string);
    const host: Host = { memory, durable: memory, receipts, pending: null, in_doubt: false, published: [] };
    const t1 = env.now();
    const { record, host: after } = step(world, host, command);
    const t2 = env.now();
    const fresh = !found.length && has(after.receipts, id);
    const stateWrite = fresh && after.durable.revision !== memory.revision;
    const writes: Write[] = fresh ? stateWrites(memory, after.durable) : [];
    if (fresh) writes.push(['INSERT INTO receipts VALUES (?, ?)', id, canonical(after.receipts[id])]);
    for (const e of after.published) writes.push(['INSERT INTO outbox VALUES (?, ?)', ++outboxSeq, canonical(e)]);
    const t3 = env.now();
    if (fresh) {
      db.exec('BEGIN IMMEDIATE');
      for (const [sql, ...params] of writes) db.all(sql, ...params);
      db.exec('COMMIT');
    }
    const t4 = env.now();
    memory = after.memory;
    const response = canonical(Object.assign(obj(), { result: record.result, events: record.events, delta: record.delta }));
    const t5 = env.now();
    const result = record.result as JsonObject;
    if (i >= warmup) {
      // Outside every phase above: the full HOST encoding the runner protocol and the
      // differential need (test output, not part of the phone's step), timed on its own.
      const t6 = env.now();
      canonical(record.state);
      const t7 = env.now();
      const outcome = result.delivery === 'replay' ? 'replayed' : (result.kind as string);
      rows.push([env.host, model, i, request.action, outcome, result.code, stateWrite ? 1 : 0,
        f(t1 - t0), f(t2 - t1), f(t3 - t2), f(t4 - t3), f(t5 - t4), f(t5 - t0),
        fresh ? writes.reduce((n, [, ...p]) => n + bytes(p), 0) : 0, f(t7 - t6)].join(','));
    }
    if (response.length === 0) throw new Error('empty response');
    if ((i + 1) % 250 === 0) env.log(`LOKA_A3_PROGRESS ${model} ${i + 1}/${commands.length}`);
  }

  // Checkpoint round trip: write the canonical state, read it back, parse, re-encode, compare.
  const pre = canonical(memory);
  const checkpoints: number[] = [];
  for (let k = 0; k < CHECKPOINTS; k++) {
    const t0 = env.now();
    db.exec('BEGIN IMMEDIATE');
    db.all('INSERT OR REPLACE INTO checkpoint VALUES (?, ?)', 'state', pre);
    db.exec('COMMIT');
    const back = canonical(parse(db.all("SELECT v FROM checkpoint WHERE k = 'state'")[0].v as string));
    const t1 = env.now();
    if (back !== pre) throw new Error(model + ': checkpoint round trip changed the canonical state');
    checkpoints.push(Math.round((t1 - t0) * 1000));
  }
  if (canonical(loadState(db)) !== pre) throw new Error(model + ': durable rows differ from memory at the end');
  const facts = Object.assign(obj(), {
    model,
    version: input.version as Json,
    seed: input.seed as Json,
    steps: commands.length,
    warmup,
    initial_state_bytes: utf8(canonical(initial)).length,
    final_state_bytes: utf8(pre).length,
    final_state_sha256: sha256Hex(utf8(pre)),
    final_narration_entries: (memory.narration as Json[]).length,
    receipts: db.all('SELECT count(*) AS n FROM receipts')[0].n as number,
    state_rows: Object.assign(obj(), {
      mem: db.all('SELECT count(*) AS n FROM mem')[0].n as number,
      mem_items: db.all('SELECT count(*) AS n FROM mem_items')[0].n as number,
    }),
    sqlite: pragmas as JsonObject,
    checkpoint_round_trip_us: checkpoints,
  });
  return { rows, facts };
}

/** All models in order; writes a3-samples.csv then a3-run.json (its presence means done). */
export function runScale(env: ScaleEnv, inputLines: string[], extra: JsonObject): JsonObject {
  const rows: string[] = [CSV_HEADER];
  const models: Json[] = [];
  const start = env.now();
  for (const line of inputLines) {
    const r = runModel(env, parse(line) as JsonObject);
    rows.push(...r.rows);
    models.push(r.facts);
    env.log('LOKA_A3_MODEL ' + canonical(r.facts));
  }
  env.write('a3-samples.csv', rows.map((r) => r + '\n').join(''));
  const run = Object.assign(obj(), { host: env.host, wall_ms: Math.round(env.now() - start), models, ...extra });
  env.write('a3-run.json', canonical(run) + '\n');
  return run;
}

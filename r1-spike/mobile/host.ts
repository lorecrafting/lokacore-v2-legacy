// R1-A2 phone durable host (r1-spike/README.md, "R1-A2 durable-host contract").
// Host code, not kernel: the unchanged kernel decides; this file makes each
// accepted attempt durable in SQLite and reads durable/receipts/pending/published
// back from SQLite for every step record.
//
// Transactions are explicit `BEGIN IMMEDIATE` / `COMMIT` / `ROLLBACK` statements
// on one connection, so the host owns the COMMIT point: a fault can sit after the
// first write, after COMMIT returns, or discard COMMIT's result. expo-sqlite's
// `withTransactionSync` / `withExclusiveTransactionAsync` issue COMMIT themselves
// after the callback, so they cannot express `commit_unknown`.
import { canonical, clone, has, isObject, parse } from '../ts/src/kernel/codec.ts';
import type { Json, JsonObject } from '../ts/src/kernel/codec.ts';
import { obj } from '../ts/src/kernel/codec.ts';
import { step } from '../ts/src/kernel/world.ts';
import type { Host, World } from '../ts/src/kernel/world.ts';

/** The two calls the host needs; expo-sqlite on the phone, node:sqlite in local checks. */
export type Db = { exec(sql: string): void; all(sql: string, ...params: Array<string | number>): Array<{ [k: string]: unknown }> };

export const POINTS = [
  'pre_decision',
  'post_decision_pre_commit',
  'in_persistence',
  'post_commit_pre_adoption',
  'post_adoption_pre_response',
  'post_response_pre_presentation',
];

/** Called at each fault point. It may throw, end the process, or ask to discard COMMIT's result. */
export type Inject = (point: string) => void | 'discard_commit';

/** COMMIT was issued and its result discarded: the host does not know the disposition. */
export class CommitUnknown extends Error {}

const SCHEMA = `
CREATE TABLE IF NOT EXISTS kv(k TEXT PRIMARY KEY, v TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS receipts(id TEXT PRIMARY KEY, receipt TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS outbox(seq INTEGER PRIMARY KEY, event TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS diag(seq INTEGER PRIMARY KEY, record TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS ballast(b BLOB);`;

/** Empty the store and make `memory` the durable state (one world.run's starting point). */
export function reset(db: Db, memory: JsonObject): void {
  db.exec(SCHEMA);
  db.exec('BEGIN IMMEDIATE');
  db.exec('DELETE FROM kv; DELETE FROM receipts; DELETE FROM outbox; DELETE FROM diag; DELETE FROM ballast');
  db.all('INSERT INTO kv VALUES (?, ?), (?, ?)', 'durable', canonical(memory), 'pending', 'null');
  db.exec('COMMIT');
}

type Stored = Pick<Host, 'durable' | 'receipts' | 'pending' | 'published'>;

/** What SQLite holds now. */
export function readBack(db: Db): Stored {
  const kv = obj();
  for (const r of db.all('SELECT k, v FROM kv')) kv[r.k as string] = parse(r.v as string);
  const receipts = obj();
  for (const r of db.all('SELECT id, receipt FROM receipts')) receipts[r.id as string] = parse(r.receipt as string);
  const published = db.all('SELECT event FROM outbox ORDER BY seq').map((r) => parse(r.event as string));
  return { durable: kv.durable as JsonObject, receipts, pending: kv.pending as Host['pending'], published };
}

type Write = [string, ...Array<string | number>];

function writes(a: Stored, b: Stored): Write[] {
  const w: Write[] = [];
  if (canonical(a.durable) !== canonical(b.durable)) w.push(['UPDATE kv SET v = ? WHERE k = ?', canonical(b.durable), 'durable']);
  for (const id of Object.keys(b.receipts)) {
    const v = canonical(b.receipts[id]);
    if (!has(a.receipts, id) || canonical(a.receipts[id]) !== v) w.push(['INSERT OR REPLACE INTO receipts VALUES (?, ?)', id, v]);
  }
  for (const e of b.published.slice(a.published.length)) w.push(['INSERT INTO outbox(event) VALUES (?)', canonical(e)]);
  const pa = canonical(a.pending as Json);
  const pb = canonical(b.pending as Json);
  if (pa !== pb) w.push(['UPDATE kv SET v = ? WHERE k = ?', pb, 'pending']);
  return w;
}

function modelFault(command: Json): Json {
  if (!isObject(command) || !isObject(command.options)) return null;
  return has(command.options, 'fault') ? command.options.fault : null;
}

export class DurableHost {
  world: World;
  db: Db;
  memory: JsonObject;
  inDoubt: boolean;

  /** Start (or restart) from SQLite only: memory is the durable state; a pending row keeps the fence. */
  constructor(world: World, db: Db) {
    this.world = world;
    this.db = db;
    const s = readBack(db);
    this.memory = s.durable;
    this.inDoubt = s.pending !== null;
  }

  host(): Host {
    return { memory: this.memory, in_doubt: this.inDoubt, ...readBack(this.db) };
  }

  /** One runner command; the step record's durable/receipts/pending/published are read back from SQLite. */
  step(command: Json, inject: Inject = () => {}): JsonObject {
    const before = this.host();
    inject('pre_decision');
    const { record, host: after } = step(this.world, before, command);
    inject('post_decision_pre_commit');
    try {
      this.persist(before, after, command, inject);
    } catch (e) {
      if (e instanceof CommitUnknown) this.inDoubt = true; // fence: no new decisions until reconciled
      throw e;
    }
    inject('post_commit_pre_adoption');
    this.memory = after.memory;
    this.inDoubt = after.in_doubt;
    inject('post_adoption_pre_response');
    Object.assign(record.state as JsonObject, readBack(this.db));
    inject('post_response_pre_presentation');
    return record;
  }

  private persist(before: Host, after: Host, command: Json, inject: Inject): void {
    let w = writes(before, after);
    let rollback = false;
    if (w.length === 0 && modelFault(command) === 'before_commit') {
      // The model discards the proposal; realize it as the real writes, then ROLLBACK.
      const c = clone(command as JsonObject);
      delete (c.options as JsonObject).fault;
      w = writes(before, step(this.world, before, c).host);
      rollback = w.length > 0;
    }
    if (w.length === 0) return;
    this.db.exec('BEGIN IMMEDIATE');
    let discard = false;
    try {
      w.forEach(([sql, ...params], i) => {
        this.db.all(sql, ...params);
        if (i === 0 && inject('in_persistence') === 'discard_commit') discard = true;
      });
    } catch (e) {
      try {
        this.db.exec('ROLLBACK');
      } catch {
        // SQLite may already have rolled back after SQLITE_FULL.
      }
      throw e;
    }
    if (rollback) return this.db.exec('ROLLBACK');
    if (!discard) return this.db.exec('COMMIT');
    try {
      this.db.exec('COMMIT');
    } catch {
      // commit_unknown: the result is discarded either way.
    }
    throw new CommitUnknown('COMMIT issued, result discarded');
  }
}

// Composition evaluate (composition_model.py, 04 §5.2-5.4). Pure: no host APIs.
//
// The model runs on arbitrary JSON and maps Python's KeyError/TypeError to
// `invalid_plan`, so the helpers below reproduce Python's container semantics
// (dict/list/str indexing, `in`, iteration, ordering, bool-as-int arithmetic).
import { Fault, canonical, clone, has, isInt, isObject, obj, pyKeys, utf8 } from './codec.ts';
import type { Json, JsonObject } from './codec.ts';

export const PROFILE_LIMITS: { [k: string]: number } = {
  operations: 4096, query_steps: 32768, events: 4096, deliveries: 8192, reaction_depth: 32,
  selector_cardinality: 1024, created_jobs: 64, pending_jobs: 1024, due_jobs_per_advance: 1024,
  scene_auto_advances: 64, output_bytes: 1048576,
};

class RuleFault {
  code: string;
  constructor(code: string) {
    this.code = code;
  }
}

const rule = (code: string): never => {
  throw new RuleFault(code);
};
// Python KeyError/TypeError/AttributeError/IndexError.
const pyErr = (): never => {
  throw new Fault('invalid_plan');
};

const codePoints = (s: string): string[] => Array.from(s);

function numeric(v: Json): number | null {
  if (typeof v === 'boolean') return v ? 1 : 0;
  return typeof v === 'number' ? v : null;
}

function pyEq(a: Json, b: Json): boolean {
  const na = numeric(a);
  const nb = numeric(b);
  if (na !== null || nb !== null) return na === nb;
  if (a === null || typeof a === 'string') return a === b;
  if (Array.isArray(a)) return Array.isArray(b) && a.length === b.length && a.every((x, i) => pyEq(x, b[i]));
  if (!isObject(a) || !isObject(b)) return false;
  const ka = Object.keys(a);
  return ka.length === Object.keys(b).length && ka.every((k) => has(b, k) && pyEq(a[k], b[k]));
}

function pyLt(a: Json, b: Json): boolean {
  const na = numeric(a);
  const nb = numeric(b);
  if (na !== null && nb !== null) return na < nb;
  if (typeof a === 'string' && typeof b === 'string') {
    const x = codePoints(a);
    const y = codePoints(b);
    for (let i = 0; i < Math.min(x.length, y.length); i++) {
      if (x[i] !== y[i]) return x[i].codePointAt(0)! < y[i].codePointAt(0)!;
    }
    return x.length < y.length;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    for (let i = 0; i < Math.min(a.length, b.length); i++) if (!pyEq(a[i], b[i])) return pyLt(a[i], b[i]);
    return a.length < b.length;
  }
  return pyErr();
}

const gt = (a: Json, b: Json): boolean => pyLt(b, a);

const unhashable = (v: Json): boolean => Array.isArray(v) || isObject(v);

/** `x in {fixed string set}` */
function inSet(x: Json, set: string[]): boolean {
  if (unhashable(x)) pyErr();
  return typeof x === 'string' && set.indexOf(x) >= 0;
}

/** `x in container` */
function contains(c: Json, x: Json): boolean {
  if (isObject(c)) {
    if (unhashable(x)) pyErr();
    return typeof x === 'string' && has(c, x);
  }
  if (Array.isArray(c)) return c.some((v) => pyEq(v, x));
  if (typeof c === 'string') return typeof x === 'string' ? c.indexOf(x) >= 0 : pyErr();
  return pyErr();
}

/** `c[k]` */
function item(c: Json, k: Json): Json {
  if (isObject(c)) {
    if (unhashable(k)) pyErr();
    return typeof k === 'string' && has(c, k) ? c[k] : pyErr();
  }
  const seq: Json[] | null = Array.isArray(c) ? c : typeof c === 'string' ? codePoints(c) : null;
  const i = numeric(k);
  if (seq === null || i === null) return pyErr();
  const j = i < 0 ? seq.length + i : i;
  return j >= 0 && j < seq.length ? seq[j] : pyErr();
}

/** `c[k] = v` for a string key */
function setItem(c: Json, k: string, v: Json): void {
  if (!isObject(c)) pyErr();
  (c as JsonObject)[k] = v;
}

/** `iter(c)` */
function iter(c: Json): Json[] {
  if (isObject(c)) return pyKeys(c);
  if (Array.isArray(c)) return c;
  if (typeof c === 'string') return codePoints(c);
  return pyErr();
}

const pyLen = (c: Json): number => iter(c).length;

// ponytail: comparator order differs from CPython's timsort, which matters only for
// which incomparable pair raises first in a junk (non-dict) `locations` list.
const pySorted = (xs: Json[]): Json[] => xs.slice().sort((a, b) => (pyLt(a, b) ? -1 : pyLt(b, a) ? 1 : 0));

const FIELDS: { [k: string]: string[] } = {
  'fact.set': ['op', 'fact', 'value'],
  'fact.add': ['op', 'fact', 'amount'],
  'event.emit': ['op', 'event', 'payload'],
  'subscription.activate': ['op', 'rule'],
  'item.transfer': ['op', 'item', 'source', 'destination'],
  'job.schedule': ['op', 'id', 'due'],
};
const FACTS: { [k: string]: [number, number] } = { flag: [0, 2], seen: [0, 2], count: [-2147483648, 2147483647] };
const CUSTOM = ['proof.signal', 'proof.followup'];

function sameKeys(o: JsonObject, want: string[]): boolean {
  const keys = Object.keys(o);
  return keys.length === want.length && want.every((k) => has(o, k));
}

const nonEmptyStr = (v: Json): boolean => typeof v === 'string' && v !== '';

function checkOp(op: Json, ids: string[]): void {
  if (!isObject(op) || !inSet(has(op, 'op') ? op.op : null, Object.keys(FIELDS))) rule('unknown_operation');
  const o = op as JsonObject;
  const kind = o.op as string;
  if (!sameKeys(o, FIELDS[kind])) rule('invalid_operation');
  if (kind.startsWith('fact.')) {
    if (!inSet(o.fact, Object.keys(FACTS))) rule('unknown_fact');
    if (kind === 'fact.add' && o.fact !== 'count') rule('invalid_operation');
    if (!isInt(kind === 'fact.set' ? o.value : o.amount)) rule('invalid_value');
  } else if (kind === 'event.emit') {
    if (!inSet(o.event, CUSTOM)) rule('forbidden_event');
    if (!isObject(o.payload)) rule('invalid_event');
  } else if (kind === 'subscription.activate') {
    if (!inSet(o.rule, ids)) rule('unknown_subscription');
  } else if (kind === 'item.transfer') {
    if (!nonEmptyStr(o.item) || !nonEmptyStr(o.source) || !nonEmptyStr(o.destination)) rule('invalid_target');
  } else if (kind === 'job.schedule') {
    if (!nonEmptyStr(o.id) || !isInt(o.due)) rule('invalid_job');
  }
}

type Rule = { id: string; event: string; guard: Json; ops: JsonObject[] };
type Queued = { event: JsonObject; eligible: Rule[]; depth: number };

/**
 * Evaluate one isolated proposal; faults return the unchanged input state.
 * `advanceTarget` null means none (absent or JSON null, as Python's None).
 */
export function evaluate(limits: JsonObject, initial: Json, root: Json, rules: Json, advanceTarget: Json): JsonObject {
  const state = clone(initial);
  const events: JsonObject[] = [];
  const deliveries: string[] = [];
  const queue: Queued[] = [];
  const writers = new Map<string, string>();
  const used: { [k: string]: number } = { operations: 0, query_steps: 0, events: 0, deliveries: 0, created_jobs: 0 };
  let ordered: Rule[] = [];

  const limit = (key: string): Json => (has(limits, key) ? limits[key] : pyErr());
  const spend = (key: string, count = 1): void => {
    used[key] += count;
    if (gt(used[key], limit(key))) rule('budget_' + key);
  };
  const write = (target: string, group: string): void => {
    const prior = writers.get(target);
    if (prior !== undefined && prior !== group) rule('conflicting_write');
    writers.set(target, group);
  };
  const emit = (name: string, payload: JsonObject, depth: number): void => {
    spend('events');
    if (gt(depth, limit('reaction_depth'))) rule('budget_reaction_depth');
    const event = obj();
    Object.assign(event, { type: name, payload: clone(payload), position: events.length + 1, time: item(state, 'clock') });
    // Lifecycle eligibility is snapshotted at EMISSION, not delivery.
    const eligible = ordered.filter((r) => r.event === name && contains(item(state, 'active'), r.id));
    spend('query_steps', ordered.length);
    events.push(event);
    queue.push({ event, eligible, depth });
    if (gt(utf8(canonical(events)).length, limit('output_bytes'))) rule('budget_output_bytes');
  };
  const sequence = (ops: JsonObject[], group: string, depth: number): void => {
    for (const op of ops) {
      spend('operations');
      const kind = op.op as string;
      if (kind.startsWith('fact.')) {
        const name = op.fact as string;
        write('fact\0' + name, group);
        let value: number;
        if (kind === 'fact.set') value = op.value as number;
        else {
          const cur = numeric(item(item(state, 'facts'), name));
          if (cur === null) pyErr();
          value = (cur as number) + (op.amount as number);
        }
        const [low, high] = FACTS[name];
        if (!(low <= value && value <= high)) rule('resource_bounds');
        setItem(item(state, 'facts'), name, value);
      } else if (kind === 'event.emit') {
        emit(op.event as string, op.payload as JsonObject, depth);
      } else if (kind === 'subscription.activate') {
        const id = op.rule as string;
        write('subscription\0' + id, group);
        const active = item(state, 'active');
        if (!contains(active, id)) {
          if (!Array.isArray(active)) pyErr(); // no .append
          const list = active as Json[];
          list.push(id);
          list.sort((a, b) => (pyLt(a, b) ? -1 : pyLt(b, a) ? 1 : 0));
        }
      } else if (kind === 'item.transfer') {
        const it = op.item as string;
        write('item\0' + it, group);
        const locations = item(state, 'locations');
        if (!isObject(locations)) pyErr(); // no .get
        const loc = locations as JsonObject;
        if ((has(loc, it) ? loc[it] : null) !== op.source) rule('not_owned');
        const dest = op.destination as string;
        if (dest !== 'hero' && dest !== 'room' && !has(loc, dest)) rule('unknown_destination');
        loc[it] = dest;
        const payload = obj();
        Object.assign(payload, { item: it, from: op.source, to: dest });
        emit('engine.item_transferred', payload, depth);
      } else if (kind === 'job.schedule') {
        const id = op.id as string;
        write('job\0' + id, group);
        const clock = item(state, 'clock');
        // max(clock, target) keeps clock unless target is strictly greater.
        const barrier: Json = advanceTarget === null ? clock : gt(advanceTarget, clock) ? advanceTarget : clock;
        if (!gt(op.due as number, barrier)) rule('nonfuture_job');
        const jobs = item(state, 'jobs');
        if (contains(jobs, id)) rule('duplicate_job');
        spend('created_jobs');
        setItem(jobs, id, op.due as number);
        if (gt(pyLen(jobs), limit('pending_jobs'))) rule('budget_pending_jobs');
      }
    }
  };

  try {
    canonical(initial);
    if (advanceTarget !== null && (!isInt(advanceTarget) || pyLt(advanceTarget, item(state, 'clock')))) rule('invalid_time');
    if (!Array.isArray(root) || !Array.isArray(rules)) rule('invalid_plan');
    const ruleList = rules as Json[];
    const ids = ruleList.map((r) => item(r, 'id'));
    if (ids.some((i) => typeof i !== 'string' || !/^[a-z][a-z0-9_-]*$/.test(i)) || new Set(ids).size !== ids.length) rule('invalid_registry');
    const idList = ids as string[];
    ordered = (ruleList as Rule[]).slice().sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
    for (const r of ordered as unknown as JsonObject[]) {
      if (!sameKeys(r, ['id', 'event', 'guard', 'ops']) || !inSet(r.event, [...CUSTOM, 'engine.item_transferred'])) rule('invalid_rule');
      const guard = r.guard;
      if (guard !== null) {
        if (!isObject(guard) || !sameKeys(guard, ['source', 'key', 'equals']) || !inSet(guard.source, ['overlay', 'event'])
            || typeof guard.key !== 'string' || (guard.source === 'overlay' && !has(FACTS, guard.key))) rule('unknown_policy');
      }
      if (!Array.isArray(r.ops)) rule('invalid_plan');
      for (const op of r.ops as Json[]) checkOp(op, idList);
    }
    const active = iter(item(state, 'active'));
    if (active.some(unhashable)) pyErr(); // set() of it
    if (active.some((a) => typeof a !== 'string' || idList.indexOf(a) < 0)) rule('unknown_subscription');
    for (const op of root as Json[]) checkOp(op, idList);
    sequence(root as JsonObject[], 'root', 0);
    while (queue.length > 0) {
      const { event, eligible, depth } = queue.shift()!;
      for (const r of eligible) {
        spend('deliveries');
        const guard = r.guard;
        if (isObject(guard)) {
          spend('query_steps');
          const source = guard.source === 'overlay' ? item(state, 'facts') : event.payload;
          if (!contains(source, guard.key) || canonical(item(source, guard.key)) !== canonical(guard.equals)) continue;
        }
        deliveries.push(String(event.position) + ':' + r.id);
        sequence(r.ops, 'delivery:' + String(event.position) + ':' + r.id, depth + 1);
      }
    }
    const locations = item(state, 'locations');
    for (const start of pySorted(iter(locations))) {
      const visited: Json[] = [];
      let cursor = start;
      while (contains(locations, cursor)) {
        spend('query_steps');
        if (unhashable(cursor)) pyErr(); // `in visited` on a set
        if (visited.some((v) => pyEq(v, cursor))) rule('containment_cycle');
        visited.push(cursor);
        cursor = item(locations, cursor);
      }
    }
    const capacities = item(state, 'capacities');
    if (!isObject(capacities)) pyErr(); // no .items
    for (const container of pyKeys(capacities as JsonObject)) {
      spend('query_steps', pyLen(locations));
      if (!isObject(locations)) pyErr(); // no .values
      const loc = locations as JsonObject;
      const count = Object.keys(loc).filter((k) => loc[k] === container).length;
      if (gt(count, (capacities as JsonObject)[container])) rule('capacity_exceeded');
    }
    const result = obj();
    Object.assign(result, { kind: 'accepted', code: 'ok', state, events, deliveries });
    if (gt(utf8(canonical(result)).length, limit('output_bytes'))) rule('budget_output_bytes');
    return result;
  } catch (e) {
    const result = obj();
    Object.assign(result, { kind: 'fault', code: e instanceof RuleFault ? e.code : 'invalid_plan', state: clone(initial), events: [], deliveries: [] });
    return result;
  }
}

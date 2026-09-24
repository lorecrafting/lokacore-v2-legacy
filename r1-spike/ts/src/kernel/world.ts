// Tiny world (contract_model.py), Lantern world (lantern_model.py) and the
// stateless step over the runner's HOST value. Pure: no host APIs.
import { Fault, SAFE_INT, canonical, canonicalBytes, clone, has, isInt, isObject, obj } from './codec.ts';
import type { Json, JsonObject } from './codec.ts';
import { sha256Hex } from './sha256.ts';
import { uniform } from './numeric.ts';

export type Host = {
  memory: JsonObject;
  durable: JsonObject;
  receipts: JsonObject; // id -> {intent, result}
  pending: null | { id: string; proposed: JsonObject; receipt: JsonObject };
  in_doubt: boolean;
  published: Json[];
};

export type Decision = { state: JsonObject; code: string; events: string[]; accepted: boolean };

export type World = {
  initial: () => JsonObject;
  /** Field -> accepted value type; `initial` must have exactly these keys. */
  schema: { [key: string]: 'int' | 'str' | 'bool' | 'str?' | 'list' | 'any' };
  decide: (memory: JsonObject, request: JsonObject) => Decision;
};

export const FAULTS = ['before_commit', 'commit_pending', 'after_commit_before_memory', 'after_memory_before_response'];

const lookup = (table: { [k: string]: { [k: string]: string } }, room: Json, dir: string): string | undefined => {
  // Python: EXITS[room] raises KeyError for an unknown room; .get(dir) is None when absent.
  if (typeof room !== 'string' || !Object.prototype.hasOwnProperty.call(table, room)) throw new Fault('invalid_state');
  return Object.prototype.hasOwnProperty.call(table[room], dir) ? table[room][dir] : undefined;
};

function sameKeys(o: JsonObject, want: string[]): boolean {
  const keys = Object.keys(o);
  return keys.length === want.length && want.every((k) => has(o, k));
}

function bump(s: JsonObject): void {
  const r = (s.revision as number) + 1;
  if (r > SAFE_INT) throw new Fault('integer_out_of_range');
  s.revision = r;
}

const ACTION_FIELDS_TINY: { [a: string]: string[] } = {
  look: [], activate: [], move: ['direction'], take: [], drop: [], wait: ['until'], choose: ['choice_id', 'continuation_id'],
};

export function tinyWorld(credit: 'event' | 'state'): World {
  const exits = { landing: { north: 'green' }, green: { south: 'landing' } };
  return {
    initial: () => {
      const s = obj();
      Object.assign(s, {
        revision: 0, room: 'landing', lantern: 'green', quest: 'absent', arrived: false, clock: 6,
        bram_room: 'landing', job_pending: true, rng: [1, 2, 3, 4], choice: null, outcome: null,
      });
      return s;
    },
    schema: {
      revision: 'int', room: 'str', lantern: 'str', quest: 'str', arrived: 'any', clock: 'int',
      bram_room: 'str', job_pending: 'bool', rng: 'any', choice: 'str?', outcome: 'any',
    },
    decide(memory, request) {
      const state = clone(memory);
      const action = request.action as string;
      const payload = (has(request, 'input') ? request.input : obj()) as JsonObject;
      const no = (code: string): Decision => ({ state, code, events: [], accepted: false });
      if (!Object.prototype.hasOwnProperty.call(ACTION_FIELDS_TINY, action) || !sameKeys(payload, ACTION_FIELDS_TINY[action])) return no('invalid_input');
      const events: string[] = [];
      let code: string;
      if (action === 'look') return { state, code: 'observed', events: [], accepted: true };
      if (action === 'activate') {
        if (state.quest !== 'absent' || state.room !== state.bram_room) return no('not_eligible');
        state.quest = 'active';
        events.push('quest_activated');
        if (credit === 'state' && state.lantern === 'hero') {
          state.quest = 'resolved';
          state.arrived = true;
          state.choice = 'lantern-offer-1';
          events.push('quest_resolved', 'fact_changed');
        }
        code = 'activated';
      } else if (action === 'move') {
        if (typeof payload.direction !== 'string') return no('invalid_input');
        const dest = lookup(exits, state.room, payload.direction);
        if (!dest) return no('no_exit');
        state.room = dest;
        code = 'moved';
        events.push('entity_entered_room');
      } else if (action === 'take') {
        if (state.lantern !== state.room) return no('not_present');
        const [roll, rng] = uniform(state.rng, 100, 1024);
        state.rng = rng;
        if (roll < 50) {
          state.lantern = 'hero';
          code = 'taken';
          events.push('check_passed', 'item_acquired');
          if (state.quest === 'active') {
            state.quest = 'resolved';
            state.arrived = true;
            state.choice = 'lantern-offer-1';
            events.push('quest_resolved', 'fact_changed');
          }
        } else {
          code = 'check_failed';
          events.push('check_failed');
        }
      } else if (action === 'choose') {
        if (state.choice === null || payload.continuation_id !== state.choice || (payload.choice_id !== 'carry' && payload.choice_id !== 'leave')) return no('invalid_choice');
        state.choice = null;
        state.outcome = payload.choice_id;
        code = 'choice_completed';
        events.push('choice_completed');
      } else if (action === 'drop') {
        if (state.lantern !== 'hero') return no('not_owned');
        state.lantern = state.room;
        code = 'dropped';
        events.push('item_dropped');
      } else {
        const until = payload.until;
        if (!isInt(until) || !((state.clock as number) < until && until <= 48)) return no('invalid_time');
        state.clock = until;
        if (state.job_pending && until >= 19) {
          state.bram_room = 'green';
          state.job_pending = false;
          events.push('schedule_completed');
        }
        code = 'waited';
      }
      bump(state);
      return { state, code, events, accepted: true };
    },
  };
}

const ACTION_FIELDS_LANTERN: { [a: string]: string[] } = {
  ...ACTION_FIELDS_TINY, talk: [], close_choice: [],
};

export function lanternWorld(): World {
  const exits = {
    landing: { north: 'green' }, green: { south: 'landing', east: 'reed_bank' },
    reed_bank: { west: 'green', east: 'shelter' }, shelter: { west: 'reed_bank' },
  };
  return {
    initial: () => {
      const s = obj();
      Object.assign(s, {
        revision: 0, room: 'landing', lantern: 'shelter', quest: 'absent', choice: null, search_plan: 'undecided',
        clock: 6, bram_room: 'landing', rng: [1, 2, 3, 4], narration: [], milestone: null,
      });
      return s;
    },
    schema: {
      revision: 'int', room: 'str', lantern: 'str', quest: 'str', choice: 'str?', search_plan: 'any',
      clock: 'int', bram_room: 'str', rng: 'any', narration: 'list', milestone: 'any',
    },
    decide(memory, request) {
      const s = clone(memory);
      const action = request.action as string;
      const payload = (has(request, 'input') ? request.input : obj()) as JsonObject;
      const no = (code: string): Decision => ({ state: s, code, events: [], accepted: false });
      if (!Object.prototype.hasOwnProperty.call(ACTION_FIELDS_LANTERN, action) || !sameKeys(payload, ACTION_FIELDS_LANTERN[action])) return no('invalid_input');
      if (action === 'look') return { state: s, code: 'observed', events: [], accepted: true };
      let code: string;
      if (action === 'activate') {
        if (s.quest !== 'absent' || s.room !== s.bram_room) return no('not_eligible');
        s.quest = 'active';
        code = s.lantern === 'hero' ? 'activated_with_possession' : 'activated';
      } else if (action === 'move') {
        if (typeof payload.direction !== 'string') return no('invalid_input');
        const dest = lookup(exits, s.room, payload.direction);
        if (!dest) return no('exit_unavailable');
        s.room = dest;
        code = 'moved';
      } else if (action === 'take') {
        if (s.lantern !== s.room) return no('not_present');
        s.lantern = 'hero';
        code = 'taken';
      } else if (action === 'drop') {
        if (s.lantern !== 'hero') return no('not_owned');
        s.lantern = s.room;
        code = 'dropped';
      } else if (action === 'talk') {
        if (s.quest !== 'active' || s.room !== s.bram_room) return no('not_eligible');
        if (s.lantern !== 'hero') return no('not_owned');
        // Reopening a still-pending choice does not mint a new occurrence.
        s.choice = (s.choice as string | null) || 'proof-choice:' + (request.id as string);
        code = 'choice_opened';
      } else if (action === 'choose') {
        if (s.choice === null || payload.continuation_id !== s.choice || (payload.choice_id !== 'carry' && payload.choice_id !== 'leave')) return no('invalid_choice');
        if (s.lantern !== 'hero') return no('not_owned');
        if (s.room !== s.bram_room) return no('not_present');
        const choice = payload.choice_id;
        const occurrence = s.choice as string;
        s.quest = 'resolved';
        s.choice = null;
        s.search_plan = choice === 'carry' ? 'player_led' : 'party_led';
        if (choice === 'leave') s.lantern = 'bram';
        const bindings = obj();
        Object.assign(bindings, { actor: 'hero', bram: 'bram', lantern: 'lantern' });
        const line = obj();
        Object.assign(line, { id: occurrence + ':outcome', text_key: 'proof.' + choice, bindings });
        (s.narration as Json[]).push(line);
        const milestone = obj();
        Object.assign(milestone, { key: 'proof.terminal', occurrence, outcome: choice });
        s.milestone = milestone;
        code = 'resolved_' + choice;
      } else if (action === 'close_choice') {
        if (s.choice === null) return no('invalid_choice');
        s.choice = null;
        code = 'choice_closed';
      } else {
        const until = payload.until;
        if (!isInt(until) || !((s.clock as number) < until && until <= 23)) return no('invalid_time');
        s.clock = until;
        s.bram_room = until < 19 ? 'landing' : 'green';
        code = 'waited';
      }
      bump(s);
      return { state: s, code, events: [code], accepted: true };
    },
  };
}

export const WORLDS: { [name: string]: () => World } = {
  'tiny-event': () => tinyWorld('event'),
  'tiny-state': () => tinyWorld('state'),
  lantern: () => lanternWorld(),
};

/** Does `memory` have exactly the world's state keys with the types the model reads? */
export function validMemory(world: World, memory: Json): memory is JsonObject {
  if (!isObject(memory) || !sameKeys(memory, Object.keys(world.schema))) return false;
  for (const k of Object.keys(world.schema)) {
    const v = memory[k];
    const t = world.schema[k];
    if (t === 'int' && !isInt(v)) return false;
    if (t === 'str' && typeof v !== 'string') return false;
    if (t === 'bool' && typeof v !== 'boolean') return false;
    if (t === 'str?' && v !== null && typeof v !== 'string') return false;
    if (t === 'list' && !Array.isArray(v)) return false;
  }
  return true;
}

export function initialHost(world: World, memory?: JsonObject): Host {
  const m = memory ?? world.initial();
  return { memory: clone(m), durable: clone(m), receipts: obj(), pending: null, in_doubt: false, published: [] };
}

function response(kind: string, code: string, revision: Json, delivery = 'new'): JsonObject {
  const r = obj();
  Object.assign(r, { kind, code, revision, delivery });
  return r;
}

const ENVELOPE = ['id', 'actor', 'action', 'targets', 'input', 'view', 'session', 'route', 'seq'];

function intent(request: JsonObject): string | null {
  for (const k of Object.keys(request)) if (ENVELOPE.indexOf(k) < 0) return null;
  for (const k of ['id', 'actor', 'action']) {
    const v = request[k];
    if (!has(request, k) || typeof v !== 'string' || v === '') return null;
  }
  const targets = has(request, 'targets') ? request.targets : [];
  if (!Array.isArray(targets) || targets.some((t) => typeof t !== 'string')) return null;
  const input = has(request, 'input') ? request.input : obj();
  if (!isObject(input)) return null;
  const value = obj();
  Object.assign(value, { actor: request.actor, action: request.action, targets, input });
  return sha256Hex(canonicalBytes(value));
}

function invoke(world: World, h: Host, request: Json, authorized: boolean, fault: string | null): JsonObject {
  const rev = h.memory.revision;
  if (!isObject(request)) return response('rejected', 'invalid_envelope', rev);
  // 03 §14: validate the envelope, then authenticate/authorize.
  const digest = intent(request);
  if (digest === null) return response('rejected', 'invalid_envelope', rev);
  if (!authorized || request.actor !== 'hero') return response('rejected', 'unauthorized', rev);
  if (h.in_doubt) return response('retryable', 'commit_pending', rev);
  const id = request.id as string;
  if (has(h.receipts, id)) {
    const prior = h.receipts[id] as JsonObject;
    if (prior.intent !== digest) return response('rejected', 'integrity_conflict', rev);
    const result = clone(prior.result as JsonObject);
    result.delivery = 'replay';
    return result;
  }
  const receiptOf = (result: JsonObject): JsonObject => {
    const r = obj();
    Object.assign(r, { intent: digest, result });
    return r;
  };
  if (has(request, 'view') && request.view !== 'view:' + String(rev)) {
    const result = response('rejected', 'stale_view', rev);
    h.receipts[id] = receiptOf(result);
    return clone(result);
  }
  const d = world.decide(h.memory, request);
  const result = response(d.accepted ? 'accepted' : 'rejected', d.code, d.state.revision);
  const receipt = receiptOf(result);
  if (fault === 'before_commit') return response('retryable', 'rolled_back', rev);
  if (fault === 'commit_pending') {
    h.in_doubt = true;
    h.pending = { id, proposed: d.state, receipt };
    return response('retryable', 'commit_pending', rev);
  }
  h.durable = clone(d.state);
  h.receipts[id] = clone(receipt);
  if (fault === 'after_commit_before_memory') {
    h.in_doubt = true;
    return response('retryable', 'commit_unknown', rev);
  }
  h.memory = clone(d.state);
  h.published.push(...d.events);
  if (fault === 'after_memory_before_response') return response('retryable', 'response_lost', h.memory.revision);
  return clone(result);
}

function commandError(command: Json): string | null {
  if (!isObject(command)) return 'invalid_command';
  const keys = Object.keys(command).sort().join(',');
  const op = command.op;
  if (op === 'invoke') {
    if (keys !== 'op,request' && keys !== 'op,options,request') return 'invalid_command';
    if (!has(command, 'options')) return null;
    const o = command.options;
    if (!isObject(o) || Object.keys(o).some((k) => k !== 'fault' && k !== 'authorized')) return 'invalid_options';
    if (has(o, 'fault') && typeof o.fault !== 'string') return 'invalid_options';
    if (has(o, 'authorized') && typeof o.authorized !== 'boolean') return 'invalid_options';
    if (has(o, 'fault') && FAULTS.indexOf(o.fault as string) < 0) return 'unknown_fault';
    return null;
  }
  if (op === 'recover') return keys === 'op' ? null : 'invalid_command';
  if (op === 'settle') {
    if (keys !== 'committed,op') return 'invalid_command';
    if (typeof command.committed !== 'boolean') return 'invalid_commit_disposition';
    return null;
  }
  return 'invalid_command';
}

export function hostJson(h: Host): JsonObject {
  const o = obj();
  let pending: Json = null;
  if (h.pending) {
    pending = obj();
    Object.assign(pending, { id: h.pending.id, proposed: h.pending.proposed, receipt: h.pending.receipt });
  }
  Object.assign(o, { memory: h.memory, durable: h.durable, receipts: h.receipts, pending, in_doubt: h.in_doubt, published: h.published });
  return o;
}

function cloneHost(h: Host): Host {
  return clone(hostJson(h)) as unknown as Host;
}

/**
 * One command against the whole HOST value; returns the step record and a new HOST.
 * Throws Fault when the model would raise (bad RNG in state, unknown room, overflow).
 */
export function step(world: World, host: Host, command: Json): { record: JsonObject; host: Host } {
  const h = cloneHost(host);
  const record = obj();
  const error = commandError(command);
  const events: Json[] = [];
  const delta = obj();
  let result: Json = null;
  if (error === null) {
    const c = command as JsonObject;
    const before = h.memory;
    const published = h.published.length;
    if (c.op === 'invoke') {
      const o = (has(c, 'options') ? c.options : obj()) as JsonObject;
      result = invoke(world, h, c.request, has(o, 'authorized') ? (o.authorized as boolean) : true, has(o, 'fault') ? (o.fault as string) : null);
    } else if (c.op === 'recover') {
      if (h.pending !== null) result = response('retryable', 'commit_pending', h.memory.revision);
      else {
        h.memory = clone(h.durable);
        h.in_doubt = false;
        result = response('recovered', 'recovered', h.memory.revision);
      }
    } else if (h.pending === null) {
      Object.assign(record, { result: null, error: 'no_pending_transaction', events, delta, state: hostJson(host) });
      return { record, host };
    } else {
      if (c.committed === true) {
        h.durable = clone(h.pending.proposed);
        h.receipts[h.pending.id] = clone(h.pending.receipt);
      }
      h.pending = null;
    }
    events.push(...h.published.slice(published));
    for (const k of Object.keys(h.memory)) {
      if (!has(before, k) || canonical(before[k]) !== canonical(h.memory[k])) delta[k] = clone(h.memory[k]);
    }
    Object.assign(record, { result, error: null, events, delta, state: hostJson(h) });
    return { record, host: h };
  }
  Object.assign(record, { result: null, error, events, delta, state: hostJson(host) });
  return { record, host };
}

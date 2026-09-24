// Runner protocol dispatch (r1-spike/README.md). Pure: the Node runner only does I/O.
import { Fault, canonical, has, isObject, obj, parse } from './codec.ts';
import type { Json, JsonObject } from './codec.ts';
import { divide, rngNext, uniform } from './numeric.ts';
import { evaluate, PROFILE_LIMITS } from './composition.ts';
import { WORLDS, initialHost, step, validMemory } from './world.ts';

const PROTOCOL_ERROR = 'invalid_protocol';

function error(code: string): JsonObject {
  const o = obj();
  o.error = code;
  return o;
}

function fields(req: JsonObject, required: string[], optional: string[] = []): boolean {
  const keys = Object.keys(req);
  return required.every((k) => has(req, k)) && keys.every((k) => required.indexOf(k) >= 0 || optional.indexOf(k) >= 0);
}

function out(pairs: { [k: string]: Json }): JsonObject {
  const o = obj();
  Object.assign(o, pairs);
  return o;
}

function worldRun(req: JsonObject): Json {
  if (!fields(req, ['fn', 'world', 'commands'], ['initial'])) return error(PROTOCOL_ERROR);
  const name = req.world;
  if (typeof name !== 'string' || !Object.prototype.hasOwnProperty.call(WORLDS, name) || !Array.isArray(req.commands)) return error(PROTOCOL_ERROR);
  const world = WORLDS[name]();
  if (has(req, 'initial') && !validMemory(world, req.initial)) return error(PROTOCOL_ERROR);
  let host = initialHost(world, has(req, 'initial') ? (req.initial as JsonObject) : undefined);
  const records: Json[] = [];
  try {
    for (const command of req.commands) {
      const r = step(world, host, command);
      records.push(r.record);
      host = r.host;
    }
  } catch (e) {
    if (e instanceof Fault) return error(PROTOCOL_ERROR); // the model would raise here
    throw e;
  }
  return records;
}

/** One parsed request to one response value. */
export function handle(req: Json): Json {
  if (!isObject(req)) return error(PROTOCOL_ERROR);
  try {
    switch (req.fn) {
      case 'world.run':
        return worldRun(req);
      case 'composition.evaluate': {
        if (!fields(req, ['fn', 'limits', 'initial', 'root', 'rules'], ['advance_target']) || !isObject(req.limits)) return error(PROTOCOL_ERROR);
        const limits = obj();
        Object.assign(limits, PROFILE_LIMITS, req.limits);
        return evaluate(limits, req.initial, req.root, req.rules, has(req, 'advance_target') ? req.advance_target : null);
      }
      case 'rng.next': {
        if (!fields(req, ['fn', 'state'])) return error(PROTOCOL_ERROR);
        const [raw, state] = rngNext(req.state);
        return out({ raw, state });
      }
      case 'rng.uniform': {
        if (!fields(req, ['fn', 'state', 'bound', 'max_draws'])) return error(PROTOCOL_ERROR);
        const [value, state] = uniform(req.state, req.bound, req.max_draws);
        return out({ value, state });
      }
      case 'int.divide': {
        if (!fields(req, ['fn', 'a', 'b'])) return error(PROTOCOL_ERROR);
        const [q, r] = divide(req.a, req.b);
        return out({ q, r });
      }
      case 'json.canonical': {
        if (!fields(req, ['fn', 'text']) || typeof req.text !== 'string') return error(PROTOCOL_ERROR);
        let value: Json;
        try {
          value = parse(req.text);
        } catch {
          return error('invalid_json');
        }
        return out({ canonical: canonical(value) });
      }
      default:
        return error(PROTOCOL_ERROR);
    }
  } catch (e) {
    if (e instanceof Fault) return error(e.code);
    throw e;
  }
}

/** One request line to one canonical response line (without the newline). */
export function handleLine(line: string): string {
  let req: Json;
  try {
    req = parse(line);
  } catch {
    return canonical(error(PROTOCOL_ERROR));
  }
  try {
    return canonical(handle(req));
  } catch (e) {
    if (e instanceof Fault) return canonical(error(PROTOCOL_ERROR)); // e.g. a receipt id that is not an ASCII key
    throw e;
  }
}

// touched-1: `step` shares structure between HOST values, so it must never mutate its
// input. Every fixture sequence runs again with each input HOST and command deeply
// frozen (a write to a frozen value throws in module code), and must give the same
// step records as the runner.
import { test } from 'node:test';
import { canonical } from '../src/kernel/codec.ts';
import type { Json, JsonObject } from '../src/kernel/codec.ts';
import { WORLDS, initialHost, step } from '../src/kernel/world.ts';
import { command, fixture, runVia } from './helpers.ts';

function freeze<T>(v: T): T {
  if (typeof v === 'object' && v !== null && !Object.isFrozen(v)) {
    Object.freeze(v);
    for (const k of Object.keys(v)) freeze((v as { [k: string]: unknown })[k]);
  }
  return v;
}

function frozenRun(world: string, commands: JsonObject[]): string {
  const w = WORLDS[world]();
  let host = initialHost(w);
  const records: Json[] = [];
  for (const c of commands) {
    const r = step(w, freeze(host), freeze(c));
    records.push(r.record);
    host = r.host;
  }
  return canonical(records);
}

const sequences: Array<[string, string, JsonObject[]]> = [
  ...(fixture('cases.json').cases as JsonObject[]).map((c): [string, string, JsonObject[]] =>
    [c.id as string, 'tiny-' + (c.credit as string), (c.steps as JsonObject[]).map(command)]),
  ...(fixture('lantern-traces.json').traces as JsonObject[]).map((t): [string, string, JsonObject[]] =>
    [t.id as string, 'lantern', (t.steps as JsonObject[]).map(command)]),
];

test('step never mutates its input HOST or command (every fixture sequence, deeply frozen)', () => {
  for (const [id, world, commands] of sequences) {
    const want = canonical(runVia(world)(commands));
    if (frozenRun(world, commands) !== want) throw new Error(id + ': frozen run differs from the runner');
  }
});

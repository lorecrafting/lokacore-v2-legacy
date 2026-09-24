import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { JsonObject } from '../src/kernel/codec.ts';
import { assertSame, call, checkSteps, command, fixture, runVia } from './helpers.ts';
import type { Runner } from './helpers.ts';
import { initialHost, step, tinyWorld } from '../src/kernel/world.ts';
import type { Host, World } from '../src/kernel/world.ts';

const DATA = fixture('adverse-cases.json');
const TRACES = fixture('lantern-traces.json').traces as JsonObject[];

test('uniform: every row, value and next state or typed error', () => {
  for (const [i, row] of (DATA.uniform as JsonObject[]).entries()) {
    const r = call({ fn: 'rng.uniform', state: row.state, bound: row.bound, max_draws: row.max_draws });
    const want: JsonObject = row.error !== undefined ? { error: row.error } : { value: row.value, state: row.next_state };
    assertSame(r, want, `uniform row ${i}`);
  }
});

function tinyCase(c: JsonObject, run: Runner): void {
  const steps = c.steps as JsonObject[];
  checkSteps(run(steps.map(command), c.initial_state as JsonObject | undefined), steps, c.id as string);
}

for (const c of DATA.tiny as JsonObject[]) {
  test(`adverse tiny ${c.id as string}`, () => tinyCase(c, runVia('tiny-' + (c.credit as string))));
}

for (const c of DATA.composition as JsonObject[]) {
  test(`adverse composition ${c.id as string}`, () => {
    const req: JsonObject = { fn: 'composition.evaluate', limits: c.limits ?? {}, initial: c.initial, root: c.root, rules: c.rules };
    if (c.advance_target !== undefined) req.advance_target = c.advance_target;
    assertSame(call(req), c.expected, c.id as string);
  });
}

for (const c of DATA.lantern as JsonObject[]) {
  test(`adverse lantern ${c.id as string}`, () => {
    const p = c.prefix as JsonObject;
    const trace = TRACES.find((t) => t.id === p.trace)!;
    const prefix = (trace.steps as JsonObject[]).slice(p.from as number, p.to as number).map((s) => ({ op: 'invoke', request: s.request }) as JsonObject);
    const steps = c.steps as JsonObject[];
    const records = runVia('lantern')([...prefix, ...steps.map(command)]);
    const tail = records.slice(prefix.length);
    for (const r of records.slice(0, prefix.length)) assertSame(r.error, null, 'prefix');
    checkSteps(tail, steps, c.id as string);
  });
}

/** The same checks, driven through step() with a (possibly mutant) world. */
const runWorld = (world: World): Runner => (commands, initial) => {
  let host: Host = initialHost(world, initial);
  return commands.map((cmd) => {
    const r = step(world, host, cmd);
    host = r.host;
    return r.record;
  });
};

test('mutation sensitivity: restoring the RNG after a failed check fails the adverse fixtures', () => {
  const c = (DATA.tiny as JsonObject[]).find((x) => x.id === 'failed-check-commits-next-rng')!;
  const good = tinyWorld('event');
  tinyCase(c, runWorld(good)); // the unmutated kernel passes through the same path
  const mutant: World = {
    ...good,
    decide(memory, request) {
      const d = good.decide(memory, request);
      if (d.code === 'check_failed') d.state.rng = (memory.rng as number[]).slice();
      return d;
    },
  };
  assert.throws(() => tinyCase(c, runWorld(mutant)));
  // And across every adverse Tiny case, at least that one fails.
  const failures = (DATA.tiny as JsonObject[]).filter((x) => {
    try {
      tinyCase(x, runWorld({ ...tinyWorld(x.credit as 'event' | 'state'), decide: mutant.decide }));
      return false;
    } catch {
      return true;
    }
  });
  assert.ok(failures.some((x) => x.id === 'failed-check-commits-next-rng'));
});

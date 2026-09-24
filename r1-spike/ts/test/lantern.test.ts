import { test } from 'node:test';
import type { JsonObject } from '../src/kernel/codec.ts';
import { assertSame, checkSteps, command, fixture, runVia } from './helpers.ts';
import { lanternWorld } from '../src/kernel/world.ts';

const DATA = fixture('lantern-traces.json');

test('lantern initial_state is the kernel initial state', () => {
  assertSame(lanternWorld().initial(), DATA.initial_state, 'initial_state');
});

for (const t of DATA.traces as JsonObject[]) {
  test(`lantern-traces.json ${t.id as string}`, () => {
    const steps = t.steps as JsonObject[];
    checkSteps(runVia('lantern')(steps.map(command)), steps, t.id as string);
  });
}

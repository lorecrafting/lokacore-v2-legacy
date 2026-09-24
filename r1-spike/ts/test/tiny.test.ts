import { test } from 'node:test';
import type { JsonObject } from '../src/kernel/codec.ts';
import { checkSteps, command, fixture, runVia } from './helpers.ts';

const DATA = fixture('cases.json');

for (const c of DATA.cases as JsonObject[]) {
  test(`cases.json ${c.id as string} (credit ${c.credit as string})`, () => {
    const steps = c.steps as JsonObject[];
    checkSteps(runVia('tiny-' + (c.credit as string))(steps.map(command)), steps, c.id as string);
  });
}

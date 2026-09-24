import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { JsonObject } from '../src/kernel/codec.ts';
import { PROFILE_LIMITS } from '../src/kernel/composition.ts';
import { assertSame, call, fixture } from './helpers.ts';

const PROFILE = fixture('composition-profile.json');
const CASES = fixture('composition-cases.json').cases as JsonObject[];

test('kernel limits equal composition-profile.json limits', () => {
  assertSame(PROFILE_LIMITS, PROFILE.limits, 'limits');
});

for (const c of CASES) {
  test(`composition-cases.json ${c.id as string}`, () => {
    const r = call({ fn: 'composition.evaluate', limits: {}, initial: c.initial, root: c.root, rules: c.rules });
    assertSame(r, c.expected, c.id as string);
  });
}

test('file registry order is not semantic (canonical-registry-order reversed)', () => {
  const c = CASES.find((x) => x.id === 'canonical-registry-order')!;
  const rules = (c.rules as JsonObject[]).slice().reverse();
  assertSame(call({ fn: 'composition.evaluate', limits: {}, initial: c.initial, root: c.root, rules }), c.expected, 'reversed');
});

test('explicit sequence order is semantic (explicit-sequence reversed)', () => {
  const c = CASES.find((x) => x.id === 'explicit-sequence')!;
  const r = call({ fn: 'composition.evaluate', limits: {}, initial: c.initial, root: (c.root as JsonObject[]).slice().reverse(), rules: [] }) as JsonObject;
  assert.equal(((r.state as JsonObject).facts as JsonObject).flag, 1);
});

test('Python KeyError/TypeError shapes map to invalid_plan', () => {
  const initial = CASES[0].initial as JsonObject;
  const emit = { op: 'event.emit', event: 'proof.signal', payload: {} };
  const code = (req: JsonObject): string => ((call({ fn: 'composition.evaluate', limits: {}, root: [], rules: [], initial, ...req }) as JsonObject).code as string);
  assert.equal(code({ rules: [{ event: 'proof.signal' }] }), 'invalid_plan'); // r['id'] KeyError
  assert.equal(code({ rules: [['a']] }), 'invalid_plan'); // list['id'] TypeError
  assert.equal(code({ root: [{ op: ['fact.set'] }] }), 'invalid_plan'); // unhashable `in` dict
  assert.equal(code({ root: [{ op: 'fact.set', fact: {}, value: 1 }] }), 'invalid_plan');
  assert.equal(code({ initial: { ...initial, clock: 'x' }, root: [emit] }), 'ok'); // time is copied, not compared
  assert.equal(code({ initial: { ...initial, clock: 'x' }, advance_target: 7 }), 'invalid_plan');
  assert.equal(code({ initial: [], advance_target: 7 }), 'invalid_plan');
  assert.equal(code({ initial: { ...initial, clock: true }, advance_target: 1 }), 'ok'); // True == 1
  assert.equal(code({ initial: { ...initial, active: 5 } }), 'invalid_plan');
  assert.equal(code({ initial: { ...initial, active: [1] } }), 'unknown_subscription');
  assert.equal(code({ initial: { ...initial, active: [[1], 'zz'] } }), 'invalid_plan'); // set() fails before difference
  assert.equal(code({ initial: { ...initial, jobs: [] }, root: [{ op: 'job.schedule', id: 'j', due: 9 }] }), 'invalid_plan');
  assert.equal(code({ initial: { ...initial, facts: { ...(initial.facts as JsonObject), count: true } }, root: [{ op: 'fact.add', fact: 'count', amount: 1 }] }), 'ok');
  assert.equal(code({ initial: { ...initial, facts: { ...(initial.facts as JsonObject), count: 'x' } }, root: [{ op: 'fact.add', fact: 'count', amount: 1 }] }), 'invalid_plan');
  assert.equal(code({ initial: { ...initial, capacities: { bag: 'x' } } }), 'invalid_plan');
  assert.equal(code({ initial: { ...initial, locations: [1, 0], capacities: {} } }), 'containment_cycle'); // list indexing
  assert.equal(code({ limits: { operations: 'x' }, root: [emit] }), 'invalid_plan');
  assert.equal(code({ root: 'x' }), 'invalid_plan');
  assert.equal(code({ root: [{ op: 'job.schedule', id: '幻', due: 9 }] }), 'invalid_plan'); // non-ASCII key at output
});

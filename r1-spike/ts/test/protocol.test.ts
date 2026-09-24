import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { canonical, parse, utf8 } from '../src/kernel/codec.ts';
import type { Json, JsonObject } from '../src/kernel/codec.ts';
import { handleLine } from '../src/runner.ts';
import { assertSame, call } from './helpers.ts';

const PROTOCOL = '{"error":"invalid_protocol"}';
const req = (id: string, action: string, input?: JsonObject): JsonObject => ({ id, actor: 'hero', action, ...(input ? { input } : {}) });
const run = (commands: Json[], world = 'tiny-event'): JsonObject[] => call({ fn: 'world.run', world, commands }) as JsonObject[];

test('invalid_protocol: unparsable lines, unknown fn, malformed arguments', () => {
  const lines = [
    '', 'not json', '[]', '{"fn":1}', '{"fn":"nope"}', '{"fn":"rng.next"}', '{"fn":"rng.next","state":[1,2,3,4],"x":1}',
    '{"fn":"rng.next","state":[1,2,3,4],"fn":"rng.next"}', '{"fn":"rng.next","state":[1.0,2,3,4]}',
    '{"fn":"rng.uniform","state":[1,2,3,4],"bound":10}', '{"fn":"int.divide","a":1}', '{"fn":"int.divide","a":1,"b":9007199254740992}',
    '{"fn":"json.canonical","text":1}', '{"fn":"json.canonical","text":"\\ud800"}',
    '{"fn":"composition.evaluate","initial":{},"root":[],"rules":[]}', '{"fn":"composition.evaluate","limits":[],"initial":{},"root":[],"rules":[]}',
    '{"fn":"world.run","world":"tiny","commands":[]}', '{"fn":"world.run","world":"lantern","commands":{}}',
    '{"fn":"world.run","world":"lantern"}', '{"fn":"world.run","world":"lantern","commands":[],"initial":[]}',
    '{"fn":"world.run","world":"lantern","commands":[],"initial":{"revision":0}}',
    '{"fn":"composition.evaluate","limits":{"bogus":1},"initial":{},"root":[],"rules":[]}',
    '{"fn":"composition.evaluate","limits":{"events":0},"initial":{},"root":[],"rules":[]}',
    '{"fn":"composition.evaluate","limits":{"events":true},"initial":{},"root":[],"rules":[]}',
    '{"fn":"composition.evaluate","limits":{"events":"1"},"initial":{},"root":[],"rules":[]}',
    '\r', ' ',
  ];
  for (const line of lines) assert.equal(handleLine(line), PROTOCOL, line);
});

test('pure function error codes, checked in the README order', () => {
  assertSame(call({ fn: 'rng.next', state: [0, 0, 0, 0] }), { error: 'invalid_rng_state' }, 'zero state');
  assertSame(call({ fn: 'rng.next', state: [4294967296, 0, 0, 0] }), { error: 'invalid_rng_state' }, 'word > u32');
  assertSame(call({ fn: 'rng.uniform', state: 'x', bound: 0, max_draws: -1 }), { error: 'invalid_bound' }, 'bound first');
  assertSame(call({ fn: 'rng.uniform', state: 'x', bound: 1, max_draws: -1 }), { error: 'invalid_rng_budget' }, 'budget second');
  assertSame(call({ fn: 'rng.uniform', state: 'x', bound: 1, max_draws: true }), { error: 'invalid_rng_budget' }, 'bool budget');
  assertSame(call({ fn: 'rng.uniform', state: 'x', bound: 1, max_draws: 0 }), { error: 'invalid_rng_state' }, 'state third');
  assertSame(call({ fn: 'rng.uniform', state: [1, 2, 3, 4], bound: 1, max_draws: 0 }), { error: 'rng_budget_exhausted' }, 'budget 0');
  assertSame(call({ fn: 'rng.uniform', state: [1, 2, 3, 4], bound: 4294967296, max_draws: 1 }), { value: 11520, state: [7, 0, 1026, 12288] }, 'bound 2^32');
  assertSame(call({ fn: 'int.divide', a: 1, b: 0 }), { error: 'divide_by_zero' }, '1/0');
  assertSame(call({ fn: 'int.divide', a: true, b: 1 }), { error: 'integer_out_of_range' }, 'bool');
  assertSame(call({ fn: 'int.divide', a: 1, b: 'x' }), { error: 'integer_out_of_range' }, 'string');
  assertSame(call({ fn: 'int.divide', a: -9007199254740991, b: -1 }), { q: 9007199254740991, r: 0 }, 'edge');
  assertSame(call({ fn: 'int.divide', a: 0, b: -3 }), { q: 0, r: 0 }, 'no negative zero');
  assertSame(call({ fn: 'int.divide', a: 4503599627370495, b: 4503599627370496 }), { q: 0, r: 4503599627370495 }, 'near 1');
  assertSame(call({ fn: 'json.canonical', text: '{"a":1,"a":1}' }), { error: 'invalid_json' }, 'duplicate');
});

test('world.run step errors change nothing', () => {
  const activate = { op: 'invoke', request: req('a', 'activate') };
  const cases: [Json, string][] = [
    [{ op: 'invoke', request: req('x', 'look'), options: [] }, 'invalid_options'],
    [{ op: 'invoke', request: req('x', 'look'), options: { other: 1 } }, 'invalid_options'],
    [{ op: 'invoke', request: req('x', 'look'), options: { fault: null } }, 'invalid_options'],
    [{ op: 'invoke', request: req('x', 'look'), options: { authorized: 1 } }, 'invalid_options'],
    [{ op: 'invoke', request: req('x', 'look'), options: { fault: 'typo' } }, 'unknown_fault'],
    [{ op: 'settle', committed: 1 }, 'invalid_commit_disposition'],
    [{ op: 'settle', committed: true }, 'no_pending_transaction'],
    [{ op: 'jump' }, 'invalid_command'],
    [{ op: 'invoke' }, 'invalid_command'],
    [{ op: 'recover', x: 1 }, 'invalid_command'],
    [{ op: 'settle' }, 'invalid_command'],
    [{ request: req('x', 'look') }, 'invalid_command'],
    ['invoke', 'invalid_command'],
  ];
  for (const [cmd, code] of cases) {
    const [first, bad] = run([activate, cmd]);
    assertSame({ result: bad.result, error: bad.error, events: bad.events, delta: bad.delta }, { result: null, error: code, events: [], delta: {} }, canonical(cmd));
    assertSame(bad.state, first.state, canonical(cmd) + ' state');
  }
});

test('step record: delta, events, pending and settle', () => {
  const [a, n, pend, rec1, settle, rec2] = run([
    { op: 'invoke', request: req('a', 'activate') },
    { op: 'invoke', request: req('n', 'move', { direction: 'north' }) },
    { op: 'invoke', request: req('x', 'take'), options: { fault: 'commit_pending' } },
    { op: 'recover' },
    { op: 'settle', committed: true },
    { op: 'recover' },
  ]);
  assertSame(a.delta, { quest: 'active', revision: 1 }, 'activate delta');
  assertSame(n.events, ['entity_entered_room'], 'move events');
  const host = pend.state as JsonObject;
  assertSame(host.in_doubt, true, 'in doubt');
  assertSame(Object.keys(host.pending as JsonObject).sort(), ['id', 'proposed', 'receipt'], 'pending shape');
  assertSame(pend.delta, {}, 'no memory change');
  assertSame(rec1.result, { kind: 'retryable', code: 'commit_pending', revision: 2, delivery: 'new' }, 'recover while pending');
  assertSame(settle.result, null, 'settle result');
  assertSame((settle.state as JsonObject).pending, null, 'settled');
  assertSame(((settle.state as JsonObject).durable as JsonObject).lantern, 'hero', 'committed durable');
  assertSame(rec2.delta, { arrived: true, choice: 'lantern-offer-1', lantern: 'hero', quest: 'resolved', revision: 3, rng: [7, 0, 1026, 12288] }, 'recover delta');
  assertSame(rec2.events, [], 'recovery publishes nothing');
});

test('initial replaces memory and durable; a state the model would raise on is invalid_protocol', () => {
  const initial = { revision: 0, room: 'green', lantern: 'green', quest: 'absent', arrived: false, clock: 6, bram_room: 'landing', job_pending: true, rng: [0, 0, 0, 0], choice: null, outcome: null };
  const [look] = call({ fn: 'world.run', world: 'tiny-event', initial, commands: [{ op: 'invoke', request: req('l', 'look') }] }) as JsonObject[];
  assertSame((look.state as JsonObject).durable, initial, 'durable');
  assertSame(call({ fn: 'world.run', world: 'tiny-event', initial, commands: [{ op: 'invoke', request: req('t', 'take') }] }), { error: 'invalid_protocol' }, 'zero rng on take');
  assertSame(call({ fn: 'world.run', world: 'tiny-event', initial: { ...initial, revision: 9007199254740991, rng: [1, 2, 3, 4] }, commands: [{ op: 'invoke', request: req('t', 'take') }] }), { error: 'invalid_protocol' }, 'revision overflow');
  assertSame(call({ fn: 'world.run', world: 'tiny-event', initial: { ...initial, room: 'attic' }, commands: [{ op: 'invoke', request: req('m', 'move', { direction: 'north' }) }] }), { error: 'invalid_protocol' }, 'unknown room');
});

test('a receipt id that cannot be an ASCII HOST key is invalid_protocol; "__proto__" is ordinary data', () => {
  assert.equal(handleLine(canonical({ fn: 'world.run', world: 'lantern', commands: [{ op: 'invoke', request: req('幻', 'look') }] })), PROTOCOL);
  const [r] = run([{ op: 'invoke', request: req('__proto__', 'look') }], 'lantern');
  assertSame(Object.keys((r.state as JsonObject).receipts as JsonObject), ['__proto__'], 'receipt key');
});

test('runner process: one canonical UTF-8 line per request, including bad bytes and a final unterminated line', () => {
  const lines = [
    utf8('{"fn":"json.canonical","text":"{\\"z\\":-0,\\"a\\":\\"幻跡\\\\n\\"}"}\n'),
    Uint8Array.from([0x7b, 0xff, 0x7d, 0x0a]), // invalid UTF-8
    utf8('\n'),
    utf8('{"fn":"int.divide","a":-7,"b":3}'),
  ];
  const input = new Uint8Array(lines.reduce((n, l) => n + l.length, 0));
  let at = 0;
  for (const l of lines) {
    input.set(l, at);
    at += l.length;
  }
  const out = spawnSync(process.execPath, ['src/runner.ts'], { input, cwd: new URL('..', import.meta.url).pathname });
  assert.equal(out.status, 0);
  const expected = utf8('{"canonical":"{\\"a\\":\\"幻跡\\\\n\\",\\"z\\":0}"}\n' + PROTOCOL + '\n' + PROTOCOL + '\n{"q":-2,"r":-1}\n');
  assert.deepEqual(Array.from(out.stdout), Array.from(expected));
  assert.ok(parse(new TextDecoder().decode(out.stdout).split('\n')[0]));
});

test('lantern: look publishes nothing, other accepted actions publish their code', () => {
  const [look, act] = run([{ op: 'invoke', request: req('l', 'look') }, { op: 'invoke', request: req('a', 'activate') }], 'lantern');
  assertSame(look.events, [], 'look');
  assertSame(act.events, ['activated'], 'activate');
});

test('kernel sources use no host APIs (Hermes has no Node)', () => {
  for (const f of ['codec', 'sha256', 'numeric', 'world', 'composition', 'protocol']) {
    const src = readFileSync(new URL(`../src/kernel/${f}.ts`, import.meta.url), 'utf8');
    for (const banned of ['node:', 'process', 'Buffer', 'require(', 'TextEncoder', 'TextDecoder', 'BigInt', 'crypto', 'JSON.']) {
      assert.ok(!src.includes(banned), `${f}.ts uses ${banned}`);
    }
  }
});

test('world.run edge rules: empty commands, missing authorized, trailing \\r', () => {
  assert.equal(handleLine('{"fn":"world.run","world":"tiny-state","commands":[]}\r'), '[]');
  const [r] = run([{ op: 'invoke', request: req('a', 'activate'), options: { fault: 'after_memory_before_response' } }]);
  assertSame(r.result, { kind: 'retryable', code: 'response_lost', revision: 1, delivery: 'new' }, 'authorized by default');
});

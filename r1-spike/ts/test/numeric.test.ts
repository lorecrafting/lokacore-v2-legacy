import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { canonical, parse, utf8 } from '../src/kernel/codec.ts';
import type { Json, JsonObject } from '../src/kernel/codec.ts';
import { sha256Hex } from '../src/kernel/sha256.ts';
import { assertSame, call, fixture } from './helpers.ts';

const V = fixture('numeric-vectors.json');

test('rng_steps: raw output and next state, chained through rng.next', () => {
  let state: Json = V.initial_rng;
  for (const [i, row] of (V.rng_steps as JsonObject[]).entries()) {
    const r = call({ fn: 'rng.next', state }) as JsonObject;
    assertSame(r, { raw: row.raw, state: row.state }, `rng step ${i}`);
    state = r.state;
  }
});

test('division: signed truncating quotient and remainder', () => {
  for (const row of V.division as JsonObject[]) {
    assertSame(call({ fn: 'int.divide', a: row.a, b: row.b }), { q: row.q, r: row.r }, `${row.a}/${row.b}`);
  }
});

test('invalid_json: every row is rejected by json.canonical', () => {
  for (const text of V.invalid_json as string[]) {
    assertSame(call({ fn: 'json.canonical', text }), { error: 'invalid_json' }, text);
  }
});

test('canonical: every row re-encodes to the expected text and UTF-8 bytes', () => {
  for (const row of V.canonical as JsonObject[]) {
    assertSame(call({ fn: 'json.canonical', text: row.input }), { canonical: row.expected }, row.input as string);
    assert.deepEqual(Array.from(utf8(canonical(parse(row.input as string)))), Array.from(utf8(row.expected as string)));
  }
});

test('canonical escapes match Python json.dumps(ensure_ascii=False)', () => {
  assert.equal(canonical({ s: '\b\t\n\f\r\x01"\\' }), '{"s":"\\b\\t\\n\\f\\r\\u0001\\"\\\\"}');
  assert.equal(canonical('\x1f\x7f\u2028é😀'), '"\\u001f\x7f\u2028é😀"');
  assert.throws(() => canonical('\ud800'));
  assert.throws(() => canonical({ é: 1 }));
  assert.throws(() => canonical(1.5));
  assert.throws(() => canonical(9007199254740992));
});

test('strict parser: Python json.loads edges', () => {
  const bad = ['', ' ', '01', '1.', '.5', '-', '+1', '[1,]', '{"a":1,}', '"\\x"', '"\t"', '\ufeff1', '"\\ud800\\u0041"',
    '"\\udc00"', '{"é":1}', 'nul', '1 2', '-0.0', '"\\u12"', '[' ];
  for (const t of bad) assert.throws(() => parse(t), JSON.stringify(t));
  assert.equal(canonical(parse(' \t\r\n[-0 , true,null ,"\\ud83d\\ude00\\/"] ')), '[0,true,null,"😀/"]');
  assert.equal(canonical(parse('-9007199254740991')), '-9007199254740991');
  assert.equal(canonical(parse('{"__proto__":{"b":1,"a":2}}')), '{"__proto__":{"a":2,"b":1}}');
});

test('pure SHA-256 matches node:crypto', () => {
  const inputs = ['', 'abc', 'a'.repeat(55), 'a'.repeat(56), 'a'.repeat(64), '幻跡'.repeat(100)];
  for (const s of inputs) {
    const bytes = utf8(s);
    assert.equal(sha256Hex(bytes), createHash('sha256').update(bytes).digest('hex'), `length ${bytes.length}`);
  }
});

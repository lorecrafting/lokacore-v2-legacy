// Shared fixture access. Fixtures are read in place and hash-checked first; never written.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { canonical, parse } from '../src/kernel/codec.ts';
import type { Json, JsonObject } from '../src/kernel/codec.ts';
import { handleLine } from '../src/runner.ts';

const V3 = new URL('../../../docs/rewrite-v3/', import.meta.url);
const PRESERVED = JSON.parse(readFileSync(new URL('spec_tools/preserved-inputs.json', V3), 'utf8')) as { [k: string]: string };

/** Parse a conformance file with the kernel's strict parser after checking its retained SHA-256. */
export function fixture(name: string): JsonObject {
  const path = 'conformance/' + name;
  const bytes = readFileSync(new URL(path, V3));
  const digest = createHash('sha256').update(bytes).digest('hex');
  if (PRESERVED[path] !== digest) throw new Error(`${path}: sha256 ${digest} != preserved ${PRESERVED[path]}`);
  return parse(readFileSync(new URL(path, V3), 'utf8')) as JsonObject;
}

/** Send one request through the runner's line handler and parse the response line. */
export function call(request: Json): Json {
  return parse(handleLine(canonical(request)));
}

export const same = (a: Json, b: Json): boolean => canonical(a) === canonical(b);

export function assertSame(actual: Json, expected: Json, where: string): void {
  const a = canonical(actual);
  const e = canonical(expected);
  if (a !== e) throw new Error(`${where}\n  actual:   ${a}\n  expected: ${e}`);
}

/** A fixture step ({request, options?} or {op, ...}) as a runner command. */
export function command(step: JsonObject): JsonObject {
  const op = (step.op as string | undefined) ?? 'invoke';
  if (op === 'recover') return { op } as JsonObject;
  if (op === 'settle') return { op, committed: step.committed } as JsonObject;
  const c: JsonObject = { op, request: step.request };
  if (step.options !== undefined) c.options = step.options;
  return c;
}

export type Runner = (commands: JsonObject[], initial?: JsonObject) => JsonObject[];

export const runVia = (world: string): Runner => (commands, initial) => {
  const request: JsonObject = { fn: 'world.run', world, commands };
  if (initial !== undefined) request.initial = initial;
  const response = call(request);
  if (!Array.isArray(response)) throw new Error(`${world}: ${canonical(response)}`);
  return response as JsonObject[];
};

/**
 * Check step records against fixture steps: result, memory, durable (default: the
 * state) and published where fixed. Throws on the first difference.
 */
export function checkSteps(records: JsonObject[], steps: JsonObject[], where: string): void {
  if (records.length !== steps.length) throw new Error(`${where}: ${records.length} records for ${steps.length} steps`);
  let published: Json[] = [];
  steps.forEach((s, i) => {
    const r = records[i];
    const host = r.state as JsonObject;
    const at = `${where} step ${i}`;
    assertSame(r.error, null, at + ' error');
    const now = host.published as Json[];
    if (i > 0) assertSame(r.events, now.slice(published.length), at + ' events');
    published = now;
    assertSame(r.result, s.result, at + ' result');
    assertSame(host.memory, s.state, at + ' memory');
    assertSame(host.durable, s.durable !== undefined ? s.durable : s.state, at + ' durable');
    if (s.published !== undefined) assertSame(host.published, s.published, at + ' published');
  });
}

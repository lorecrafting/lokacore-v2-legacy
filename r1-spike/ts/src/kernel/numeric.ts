// Numeric profile v1: xoshiro128** 1.1 (Blackman/Vigna, public domain), uniform, divide.
import { Fault, SAFE_INT, isInt } from './codec.ts';
import type { Json } from './codec.ts';

const U32 = 0xffffffff;
const TWO32 = 0x100000000;

function checkWords(words: Json): number[] {
  if (!Array.isArray(words) || words.length !== 4) throw new Fault('invalid_rng_state');
  for (const v of words) if (!isInt(v) || v < 0 || v > U32) throw new Fault('invalid_rng_state');
  const w = words as number[];
  if (w.every((v) => v === 0)) throw new Fault('invalid_rng_state');
  return w;
}

const rotl = (v: number, k: number): number => ((v << k) | (v >>> (32 - k))) >>> 0;

function next(w: number[]): [number, number[]] {
  let [a, b, c, d] = w;
  const result = Math.imul(rotl(Math.imul(b, 5) >>> 0, 7), 9) >>> 0;
  const t = (b << 9) >>> 0;
  c = (c ^ a) >>> 0;
  d = (d ^ b) >>> 0;
  b = (b ^ c) >>> 0;
  a = (a ^ d) >>> 0;
  c = (c ^ t) >>> 0;
  d = rotl(d, 11);
  return [result, [a, b, c, d]];
}

export function rngNext(words: Json): [number, number[]] {
  return next(checkWords(words));
}

export function uniform(words: Json, bound: Json, maxDraws: Json): [number, number[]] {
  if (!isInt(bound) || bound < 1 || bound > TWO32) throw new Fault('invalid_bound');
  if (!isInt(maxDraws) || maxDraws < 0) throw new Fault('invalid_rng_budget');
  let w = checkWords(words);
  const limit = TWO32 - (TWO32 % bound);
  for (let i = 0; i < maxDraws; i++) {
    const [raw, nw] = next(w);
    w = nw;
    if (raw < limit) return [raw % bound, w];
  }
  throw new Fault('rng_budget_exhausted');
}

/** Truncating division; exact because % on doubles is exact and (a - r) / b divides evenly. */
export function divide(a: Json, b: Json): [number, number] {
  if (!isInt(a) || !isInt(b) || Math.abs(a) > SAFE_INT || Math.abs(b) > SAFE_INT) throw new Fault('integer_out_of_range');
  if (b === 0) throw new Fault('divide_by_zero');
  const r = a % b;
  const q = (a - r) / b;
  return [q + 0, r + 0];
}

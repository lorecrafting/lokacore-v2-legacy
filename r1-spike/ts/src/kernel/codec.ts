// Strict fixture codec (conformance/numeric-profile.md). Pure: no host APIs.
// Objects are null-prototype so keys such as "__proto__" stay ordinary data.

export type Json = null | boolean | number | string | Json[] | JsonObject;
export type JsonObject = { [key: string]: Json };

export const SAFE_INT = 9007199254740991;

export class Fault extends Error {
  code: string;
  constructor(code: string) {
    super(code);
    this.code = code;
  }
}

// Key order as written, kept only where it differs from JS enumeration order
// (integer-like keys). Python dicts iterate in insertion order; see pyItems.
export const KEY_ORDER: unique symbol = Symbol('keyOrder');

export function isObject(v: unknown): v is JsonObject {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

export function isInt(v: unknown): v is number {
  return typeof v === 'number' && Number.isInteger(v);
}

export function has(o: JsonObject, k: string): boolean {
  return Object.prototype.hasOwnProperty.call(o, k);
}

export function obj(): JsonObject {
  return Object.create(null) as JsonObject;
}

export function clone<T extends Json>(v: T): T {
  if (Array.isArray(v)) return v.map(clone) as T;
  if (isObject(v)) {
    const out = obj();
    for (const k of Object.keys(v)) out[k] = clone(v[k]);
    const order = (v as { [KEY_ORDER]?: string[] })[KEY_ORDER];
    if (order) (out as { [KEY_ORDER]?: string[] })[KEY_ORDER] = order.slice();
    return out as T;
  }
  return v;
}

/** Keys in insertion order, as a Python dict built from the same JSON would iterate. */
export function pyKeys(o: JsonObject): string[] {
  const order = (o as { [KEY_ORDER]?: string[] })[KEY_ORDER];
  return order ? order.filter((k) => has(o, k)) : Object.keys(o);
}

const INVALID = 'invalid_json';

/** Parse per Python json.loads plus the profile's strict checks. Throws Fault('invalid_json'). */
export function parse(text: string): Json {
  let i = 0;
  const n = text.length;
  const fail = (): never => {
    throw new Fault(INVALID);
  };
  const ws = (): void => {
    while (i < n) {
      const c = text.charCodeAt(i);
      if (c === 0x20 || c === 0x09 || c === 0x0a || c === 0x0d) i++;
      else break;
    }
  };
  const hex4 = (): number => {
    if (i + 4 > n) fail();
    let v = 0;
    for (let k = 0; k < 4; k++) {
      const c = text.charCodeAt(i++);
      const d = c >= 48 && c <= 57 ? c - 48 : c >= 65 && c <= 70 ? c - 55 : c >= 97 && c <= 102 ? c - 87 : -1;
      if (d < 0) fail();
      v = v * 16 + d;
    }
    return v;
  };
  const str = (): string => {
    i++; // opening quote
    let out = '';
    for (;;) {
      if (i >= n) fail();
      const c = text.charCodeAt(i);
      if (c === 0x22) {
        i++;
        return out;
      }
      if (c < 0x20) fail();
      if (c === 0x5c) {
        const e = text[i + 1];
        i += 2;
        if (e === '"' || e === '\\' || e === '/') out += e;
        else if (e === 'b') out += '\b';
        else if (e === 'f') out += '\f';
        else if (e === 'n') out += '\n';
        else if (e === 'r') out += '\r';
        else if (e === 't') out += '\t';
        else if (e === 'u') {
          const u = hex4();
          if (u >= 0xdc00 && u <= 0xdfff) fail();
          if (u >= 0xd800 && u <= 0xdbff) {
            // Python pairs only an escaped high surrogate with an escaped low one.
            if (text[i] !== '\\' || text[i + 1] !== 'u') fail();
            i += 2;
            const lo = hex4();
            if (lo < 0xdc00 || lo > 0xdfff) fail();
            out += String.fromCharCode(u, lo);
          } else out += String.fromCharCode(u);
        } else fail();
        continue;
      }
      if (c >= 0xd800 && c <= 0xdfff) {
        const lo = text.charCodeAt(i + 1);
        if (c > 0xdbff || !(lo >= 0xdc00 && lo <= 0xdfff)) fail();
        out += text[i] + text[i + 1];
        i += 2;
        continue;
      }
      out += text[i++];
    }
  };
  const num = (): number => {
    const start = i;
    if (text[i] === '-') i++;
    const d0 = i;
    if (text[i] === '0') i++;
    else if (text[i] >= '1' && text[i] <= '9') while (text[i] >= '0' && text[i] <= '9') i++;
    else fail();
    // A fraction or exponent makes a float, which the profile rejects.
    if (text[i] === '.' || text[i] === 'e' || text[i] === 'E') fail();
    if (i - d0 > 16) fail();
    const v = Number(text.slice(start, i));
    if (Math.abs(v) > SAFE_INT) fail();
    return v === 0 ? 0 : v; // -0 normalizes to 0
  };
  const value = (): Json => {
    ws();
    const c = text[i];
    if (c === '{') {
      i++;
      const o = obj();
      const keys: string[] = [];
      let ordered = true;
      ws();
      if (text[i] === '}') {
        i++;
        return o;
      }
      for (;;) {
        ws();
        if (text[i] !== '"') fail();
        const k = str();
        for (let j = 0; j < k.length; j++) if (k.charCodeAt(j) > 0x7f) fail();
        if (has(o, k)) fail();
        ws();
        if (text[i] !== ':') fail();
        i++;
        o[k] = value();
        keys.push(k);
        if (/^(0|[1-9][0-9]*)$/.test(k)) ordered = false;
        ws();
        if (text[i] === ',') i++;
        else if (text[i] === '}') {
          i++;
          break;
        } else fail();
      }
      if (!ordered) (o as { [KEY_ORDER]?: string[] })[KEY_ORDER] = keys;
      return o;
    }
    if (c === '[') {
      i++;
      const a: Json[] = [];
      ws();
      if (text[i] === ']') {
        i++;
        return a;
      }
      for (;;) {
        a.push(value());
        ws();
        if (text[i] === ',') i++;
        else if (text[i] === ']') {
          i++;
          return a;
        } else fail();
      }
    }
    if (c === '"') return str();
    if (text.startsWith('true', i)) {
      i += 4;
      return true;
    }
    if (text.startsWith('false', i)) {
      i += 5;
      return false;
    }
    if (text.startsWith('null', i)) {
      i += 4;
      return null;
    }
    return num();
  };
  try {
    const v = value();
    ws();
    if (i !== n) fail();
    return v;
  } catch (e) {
    if (e instanceof Fault) throw e;
    throw new Fault(INVALID); // e.g. stack exhaustion on absurd nesting
  }
}

function quote(s: string): string {
  let out = '"';
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c === 0x22) out += '\\"';
    else if (c === 0x5c) out += '\\\\';
    else if (c === 0x08) out += '\\b';
    else if (c === 0x09) out += '\\t';
    else if (c === 0x0a) out += '\\n';
    else if (c === 0x0c) out += '\\f';
    else if (c === 0x0d) out += '\\r';
    else if (c < 0x20) out += '\\u00' + (c < 16 ? '0' : '') + c.toString(16);
    else if (c >= 0xd800 && c <= 0xdfff) {
      const lo = s.charCodeAt(i + 1);
      if (c > 0xdbff || !(lo >= 0xdc00 && lo <= 0xdfff)) throw new Fault('invalid_canonical');
      out += s[i] + s[i + 1];
      i++;
    } else out += s[i];
  }
  return out + '"';
}

/** Canonical text (keys sorted by code point, no whitespace). Throws Fault('invalid_canonical'). */
export function canonical(v: Json): string {
  if (v === null) return 'null';
  if (v === true) return 'true';
  if (v === false) return 'false';
  if (typeof v === 'number') {
    if (!Number.isInteger(v) || Math.abs(v) > SAFE_INT) throw new Fault('invalid_canonical');
    return String(v === 0 ? 0 : v);
  }
  if (typeof v === 'string') return quote(v);
  if (Array.isArray(v)) return '[' + v.map(canonical).join(',') + ']';
  if (isObject(v)) {
    const keys = Object.keys(v);
    for (const k of keys) for (let j = 0; j < k.length; j++) if (k.charCodeAt(j) > 0x7f) throw new Fault('invalid_canonical');
    keys.sort(); // ASCII-only keys: UTF-16 order equals code-point order
    return '{' + keys.map((k) => quote(k) + ':' + canonical(v[k])).join(',') + '}';
  }
  throw new Fault('invalid_canonical');
}

/** UTF-8 bytes of a string of Unicode scalars (lone surrogates are rejected). */
export function utf8(s: string): Uint8Array {
  const out: number[] = [];
  for (let i = 0; i < s.length; i++) {
    let c = s.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdfff) {
      const lo = s.charCodeAt(i + 1);
      if (c > 0xdbff || !(lo >= 0xdc00 && lo <= 0xdfff)) throw new Fault('invalid_canonical');
      c = 0x10000 + ((c - 0xd800) << 10) + (lo - 0xdc00);
      i++;
    }
    if (c < 0x80) out.push(c);
    else if (c < 0x800) out.push(0xc0 | (c >> 6), 0x80 | (c & 63));
    else if (c < 0x10000) out.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
    else out.push(0xf0 | (c >> 18), 0x80 | ((c >> 12) & 63), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
  }
  return Uint8Array.from(out);
}

export function canonicalBytes(v: Json): Uint8Array {
  return utf8(canonical(v));
}

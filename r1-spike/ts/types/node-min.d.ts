// Minimal ambient declarations for the Node-only runner and tests. The kernel
// (src/kernel/) must not use any of these; lib is ES2020 only.
interface ImportMeta {
  main: boolean;
}
declare class TextDecoder {
  constructor(label?: string, options?: { fatal?: boolean; ignoreBOM?: boolean });
  decode(input: Uint8Array): string;
}
declare var process: {
  stdin: { on(event: 'data', cb: (chunk: Uint8Array) => void): void; on(event: 'end', cb: () => void): void };
  stdout: { write(data: Uint8Array): boolean };
  execPath: string;
};
declare module 'node:fs' {
  export function readFileSync(path: string | URL): Uint8Array;
  export function readFileSync(path: string | URL, encoding: 'utf8'): string;
}
declare module 'node:crypto' {
  export function createHash(alg: string): { update(data: Uint8Array | string): { digest(enc: 'hex'): string } };
}
declare module 'node:child_process' {
  export function spawnSync(cmd: string, args: string[], opts: { input: Uint8Array; cwd?: string }): { stdout: Uint8Array; status: number | null };
}
declare module 'node:test' {
  export function test(name: string, fn: () => void | Promise<void>): void;
}
declare module 'node:assert/strict' {
  const assert: {
    equal(actual: unknown, expected: unknown, message?: string): void;
    notEqual(actual: unknown, expected: unknown, message?: string): void;
    deepEqual(actual: unknown, expected: unknown, message?: string): void;
    ok(value: unknown, message?: string): void;
    throws(fn: () => unknown, message?: string): void;
  };
  export default assert;
}
declare class URL {
  constructor(url: string, base?: string | URL);
}

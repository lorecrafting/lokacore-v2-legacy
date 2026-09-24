// Runs scale.ts on Node + node:sqlite: a pre-phone check of the same code, not evidence.
// Usage: node scripts/scale-local.mjs <scale.jsonl> <out dir>
import { DatabaseSync } from 'node:sqlite';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { runScale } from '../scale.ts';

const [input, out] = process.argv.slice(2);
mkdirSync(out, { recursive: true });
const env = {
  host: 'node-local',
  open: (name) => {
    const d = new DatabaseSync(out + '/' + name);
    return { exec: (s) => d.exec(s), all: (s, ...p) => d.prepare(s).all(...p) };
  },
  now: () => performance.now(),
  write: (name, text) => writeFileSync(out + '/' + name, text),
  log: (l) => console.log(l),
};
runScale(env, readFileSync(input, 'utf8').trim().split('\n'), {});

// Runs device.ts on Node + node:sqlite: a pre-phone check of the same code, not evidence.
// Usage: node scripts/local-check.mjs <requests.jsonl> <out dir>
// `kill` ends the child with exit code 137 and this loop relaunches it, as the M1 does for the app.
import { DatabaseSync } from 'node:sqlite';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { runAll } from '../device.ts';

const [requests, out] = process.argv.slice(2);
mkdirSync(out, { recursive: true });

if (process.env.LOKA_CHILD) {
  const env = {
    host: 'node-local',
    open: (name) => {
      const d = new DatabaseSync(out + '/' + name);
      return { exec: (s) => d.exec(s), all: (s, ...p) => d.prepare(s).all(...p) };
    },
    kill: () => process.exit(137),
    write: (name, text) => writeFileSync(out + '/' + name, text),
  };
  runAll(env, readFileSync(requests), {});
} else {
  for (;;) {
    const r = spawnSync(process.execPath, [...process.execArgv, process.argv[1], requests, out], { env: { ...process.env, LOKA_CHILD: '1' }, stdio: 'inherit' });
    if (r.status === 0) break;
    if (r.status !== 137) throw new Error('child exit ' + r.status);
  }
  console.log(readFileSync(out + '/summary.json', 'utf8'));
  for (const l of readFileSync(out + '/faults.jsonl', 'utf8').trim().split('\n')) {
    const x = JSON.parse(l);
    if (x.verdict !== 'pass') console.log('FAIL', x.fault, x.checks, x.error?.message);
  }
}

// Phone host. R1-A2 ran the on-device differential and fault cases (device.ts, runAll); on this
// branch the app runs the quick R1-A3 timing instead (scale.ts): it reports the running JS engine,
// SQLite and OS-visible memory, then times Tiny/Medium/Stress and writes a3-samples.csv and
// a3-run.json for the M1 to pull.
import { requireNativeModule } from 'expo';
import { openDatabaseSync } from 'expo-sqlite';
import { useEffect, useState } from 'react';
import { Platform, Text, View } from 'react-native';
import { utf8 } from '../ts/src/kernel/codec.ts';
import type { JsonObject } from '../ts/src/kernel/codec.ts';
import type { Db } from './host.ts';
import { runScale } from './scale.ts';
import SCALE from './scale.gen.ts';

declare const HermesInternal: { getRuntimeProperties?: () => Record<string, unknown> } | undefined;

// Local module (modules/loka-memory): memory probe, evidence files, process death.
const native = requireNativeModule<{
  physicalMemory(): { api: string; bytes: string };
  writeFile(name: string, base64: string): void;
  kill(): void;
}>('LokaMemory');

// One handle per database for the life of the process. On Android, expo-sqlite 57.0.3 hands a second
// openDatabaseSync of the same path the same cached native database, and garbage collection of either
// JS handle closes it (NativeDatabase.sharedObjectDidRelease -> ref.close(), refCount ignored), so the
// other handle's next call fails with a NullPointerException (Pixel 3a, failed-attempt-1 evidence).
const handles: { [name: string]: Db } = {};
const open = (name: string): Db => {
  if (!handles[name]) {
    const d = openDatabaseSync(name);
    handles[name] = { exec: (s) => d.execSync(s), all: (s, ...p) => d.getAllSync(s, p) as Array<{ [k: string]: unknown }> };
  }
  return handles[name];
};

function base64(bytes: Uint8Array): string {
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

const hermes = typeof HermesInternal === 'object' ? HermesInternal?.getRuntimeProperties?.() ?? null : null;
const hostDb = open('host.db');
const probe = {
  ...hostDb.all('SELECT sqlite_version() AS version, sqlite_source_id() AS source_id')[0],
  ...hostDb.all('PRAGMA journal_mode')[0],
  ...hostDb.all('PRAGMA synchronous')[0],
};
const report = { hermes, sqlite: probe, memory: native.physicalMemory() };
console.log('LOKA_A3_PROBE ' + JSON.stringify(report));

function run(setStatus: (s: string) => void): void {
  const env = {
    host: 'phone-' + Platform.OS,
    open,
    now: () => performance.now(),
    write: (name: string, text: string) => native.writeFile(name, base64(utf8(text))),
    log: (line: string) => console.log(line),
  };
  const summary = runScale(env, SCALE, { runtime: JSON.parse(JSON.stringify(report)) as JsonObject });
  const line = JSON.stringify({ wall_ms: summary.wall_ms });
  console.log('LOKA_A3_DONE ' + line);
  setStatus(line);
}

export default function App() {
  const [status, setStatus] = useState('running');
  useEffect(() => {
    const t = setTimeout(() => {
      try {
        run(setStatus);
      } catch (e) {
        const err = e as Error;
        console.log('LOKA_A3_ERROR ' + String(err.message) + '\n' + String(err.stack));
        setStatus('error: ' + String(err.message));
      }
    }, 3000); // let startup settle before timing
    return () => clearTimeout(t);
  }, []);
  return (
    <View style={{ flex: 1, padding: 24, paddingTop: 64 }}>
      <Text selectable style={{ fontFamily: 'monospace' }}>{JSON.stringify(report, null, 2) + '\n\n' + status}</Text>
    </View>
  );
}

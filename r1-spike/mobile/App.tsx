// R1-A2 phone host: reports the running JS engine, SQLite and OS-visible memory,
// then runs the on-device differential and the injected-fault cases (device.ts)
// and writes responses.jsonl, faults.jsonl and summary.json for the M1 to pull.
import { requireNativeModule } from 'expo';
import { openDatabaseSync } from 'expo-sqlite';
import { useEffect, useState } from 'react';
import { Platform, Text, View } from 'react-native';
import { utf8 } from '../ts/src/kernel/codec.ts';
import type { JsonObject } from '../ts/src/kernel/codec.ts';
import { CASES, runAll } from './device.ts';
import type { Db } from './host.ts';
import REQUESTS from './requests.gen.ts';

declare const HermesInternal: { getRuntimeProperties?: () => Record<string, unknown> } | undefined;

// Local module (modules/loka-memory): memory probe, evidence files, process death.
const native = requireNativeModule<{
  physicalMemory(): { api: string; bytes: string };
  writeFile(name: string, base64: string): void;
  kill(): void;
}>('LokaMemory');

const open = (name: string): Db => {
  const d = openDatabaseSync(name);
  return { exec: (s) => d.execSync(s), all: (s, ...p) => d.getAllSync(s, p) as Array<{ [k: string]: unknown }> };
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
console.log('LOKA_A2_PROBE ' + JSON.stringify(report));

function run(setStatus: (s: string) => void): void {
  const env = {
    host: 'phone-' + Platform.OS,
    open,
    kill: () => native.kill(),
    write: (name: string, text: string) => native.writeFile(name, base64(utf8(text))),
  };
  const requests = Uint8Array.from(atob(REQUESTS), (c) => c.charCodeAt(0));
  const summary = runAll(env, requests, { runtime: JSON.parse(JSON.stringify(report)) as JsonObject }, (i) =>
    console.log(`LOKA_A2_CASE ${i + 1}/${CASES.length} ${CASES[i].fault.point} ${CASES[i].fault.kind}`),
  );
  const line = JSON.stringify(summary);
  console.log('LOKA_A2_DONE ' + line);
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
        console.log('LOKA_A2_ERROR ' + String(err.message) + '\n' + String(err.stack));
        setStatus('error: ' + String(err.message));
      }
    }, 100);
    return () => clearTimeout(t);
  }, []);
  return (
    <View style={{ flex: 1, padding: 24, paddingTop: 64 }}>
      <Text selectable style={{ fontFamily: 'monospace' }}>{JSON.stringify(report, null, 2) + '\n\n' + status}</Text>
    </View>
  );
}

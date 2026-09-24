// A2 native-evidence probe only: reports the running JS engine, SQLite and OS-visible memory, nothing else.
import { requireNativeModule } from 'expo';
import { openDatabaseSync } from 'expo-sqlite';
import { Text, View } from 'react-native';

declare const HermesInternal: { getRuntimeProperties?: () => Record<string, unknown> } | undefined;

const hermes = typeof HermesInternal === 'object' ? HermesInternal?.getRuntimeProperties?.() ?? null : null;
const sqlite = openDatabaseSync(':memory:').getFirstSync<{ v: string; s: string }>(
  'SELECT sqlite_version() AS v, sqlite_source_id() AS s',
);
// Local module (modules/loka-memory): { api, bytes } from the platform API named in `api`.
const memory = requireNativeModule<{ physicalMemory(): { api: string; bytes: string } }>('LokaMemory').physicalMemory();
const report = JSON.stringify({ hermes, sqlite, memory }, null, 2);
console.log('LOKA_A2_PROBE ' + report);

export default function App() {
  return (
    <View style={{ flex: 1, padding: 24, paddingTop: 64 }}>
      <Text selectable style={{ fontFamily: 'monospace' }}>{report}</Text>
    </View>
  );
}

// A2 native-evidence probe only: reports the running JS engine and SQLite, nothing else.
import { openDatabaseSync } from 'expo-sqlite';
import { Text, View } from 'react-native';

declare const HermesInternal: { getRuntimeProperties?: () => Record<string, unknown> } | undefined;

const hermes = typeof HermesInternal === 'object' ? HermesInternal?.getRuntimeProperties?.() ?? null : null;
const sqlite = openDatabaseSync(':memory:').getFirstSync<{ v: string; s: string }>(
  'SELECT sqlite_version() AS v, sqlite_source_id() AS s',
);
const report = JSON.stringify({ hermes, sqlite }, null, 2);
console.log('LOKA_A2_PROBE ' + report);

export default function App() {
  return (
    <View style={{ flex: 1, padding: 24, paddingTop: 64 }}>
      <Text selectable style={{ fontFamily: 'monospace' }}>{report}</Text>
    </View>
  );
}

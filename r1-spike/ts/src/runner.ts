// Node NDJSON runner: one canonical UTF-8 line per request line (r1-spike/README.md).
import { utf8 } from './kernel/codec.ts';
import { handleLine } from './kernel/protocol.ts';

export { handleLine };

const decoder = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });

function respond(bytes: Uint8Array): void {
  let line: string;
  try {
    line = handleLine(decoder.decode(bytes));
  } catch {
    line = handleLine(''); // invalid UTF-8 cannot parse: invalid_protocol
  }
  process.stdout.write(utf8(line + '\n'));
}

if (import.meta.main) {
  let pending = new Uint8Array(0);
  process.stdin.on('data', (chunk: Uint8Array) => {
    const buf = new Uint8Array(pending.length + chunk.length);
    buf.set(pending);
    buf.set(chunk, pending.length);
    let start = 0;
    for (let i = 0; i < buf.length; i++) {
      if (buf[i] === 0x0a) {
        respond(buf.subarray(start, i));
        start = i + 1;
      }
    }
    pending = buf.slice(start);
  });
  process.stdin.on('end', () => {
    if (pending.length > 0) respond(pending);
  });
}

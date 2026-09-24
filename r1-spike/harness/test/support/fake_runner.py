"""Fake runner for harness self-tests: echoes each request line byte for byte.

With `--corrupt-step N`, a world.run with more than N commands gets a changed
response, so the minimal failing input has exactly N + 1 commands. `--crlf` ends
every line with \\r\\n. Raw bytes both ways, so invalid UTF-8 and \\r-terminated
lines echo intact.
"""
import json
import sys

corrupt = int(sys.argv[2]) if sys.argv[1:2] == ["--corrupt-step"] else None
ending = b"\r\n" if sys.argv[1:2] == ["--crlf"] else b"\n"
out = sys.stdout.buffer
for raw in sys.stdin.buffer:
    line = raw[:-1] if raw.endswith(b"\n") else raw
    if corrupt is not None:
        try:
            req = json.loads(line)
            if req.get("fn") == "world.run" and len(req["commands"]) > corrupt:
                line = b"corrupt:" + line
        except Exception:
            pass
    out.write(line + ending)
    out.flush()

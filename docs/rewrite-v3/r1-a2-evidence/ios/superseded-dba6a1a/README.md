# R1-A2 iPhone 11 evidence

**App tested on the phone: iOS build 2, built from source commit `dba6a1a`**
(`dba6a1ab8ffdcc6d60f17dec6058740e64801af5`, recorded as `git rev-parse HEAD` in
`build-2.txt`). Hermes bytecode sha256 `bc417c6b…8a81`, executable sha256
`ca4d0335…ac1e`, Mach-O/dSYM UUID `717A4A7B-FD51-3705-B028-AB29DE4BF275`
(`build-2.txt`, `iphone-11-run.txt`, and `slice_uuid` in every crash report).
Later commits on the branch change only the capture script and evidence, not the
app. `git status --porcelain` at build time lists only the untracked evidence
directory.

All files come from `iphone-11.sh` (`build 1`, `build 2`, `compare`, `run`) and
pass through its `redact()`. `SHA256SUMS` indexes every other file here, and
`SHA256SUMS.verify.txt` is its `shasum -a 256 -c` output.

| File | What |
|---|---|
| `build-N.txt`, `build-N-*.log` | Build identities and hashes; raw pod/xcodebuild logs |
| `build-compare.txt` | Build 1 vs build 2 |
| `iphone-11-run.txt` | Install, launch loop (7 launches: 6 `kill` cases + the final one), pulls |
| `responses.jsonl`, `elixir-runner.jsonl`, `differential.txt` | On-device differential, the Elixir runner's lines, the comparison with one injected mismatch |
| `faults.device.jsonl` | Fault records as pulled (redacted: app-container UUIDs in stack paths) |
| `faults.jsonl`, `faults-check.txt` | The same plus `error.stack_symbolicated` and the Elixir-runner cross-check |
| `crash/`, `kill-stacks-symbolicated.txt` | The six `kill` crash reports (redacted) and their app frame via `atos` + dSYM |
| `summary.json` | The app's own summary (Hermes, SQLite, journal mode, counts) |

Symbolication commands: `node node_modules/metro-symbolicate/src/index.js <build-2 main.jsbundle.map> < stack`
(the composed Metro + hermesc map that `SOURCEMAP_FILE` makes the Release build emit) and
`xcrun atos -o LokaR1A2.app.dSYM/Contents/Resources/DWARF/LokaR1A2 -arch arm64 -l <image base> <return address - 1>`.
The source map and dSYM are not retained here (they contain build-machine paths); their hashes are in `build-2.txt`.

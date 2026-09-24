# R1-A2 iPhone 11 evidence

**App tested on the phone: iOS Release build 2 from source commit `e0930bb`**
(`e0930bbbb2ab520a567a6b3ae76029735549f9fb`). This is the same app source as the
Pixel 3a run: `e0930bb` changes nothing under `r1-spike/` after `e61c52a`.
`build-2.txt` records `git rev-parse HEAD` and `git status --porcelain`. The
status lists only staged moves of this directory's earlier files into
`superseded-dba6a1a/`. No app source was modified.
- Hermes bytecode sha256 `09dd5bb6…ea8a`.
- Executable sha256 `723e2e6c…05ef`.
- Mach-O/dSYM UUID `3AF1CFCF-AF02-3F33-B877-0CD995E54042` (also the `slice_uuid`
  in each crash report).

## Results

- **Differential** (`differential.txt`): all 139 lines are byte-identical to
  the Elixir runner. With one byte of line 70 altered, that line is reported as
  the only mismatch.
- **Faults** (`faults-check.txt`, `faults.jsonl`): 19 of 19 pass, and each is
  also cross-checked against the Elixir runner. The six `kill` cases each died
  by SIGABRT, and the app recovered on relaunch (7 launches,
  `iphone-11-run.txt`). JS stacks are symbolicated through the composed release
  source map. The app frame of each of the six crash reports is symbolicated
  with `atos` and the dSYM to `LokaMemoryModule.swift:17`
  (`kill-stacks-symbolicated.txt`, `crash/`).
- **Builds** (`build-compare.txt`): Metro bundle, Hermes bytecode and source map
  are identical across the two clean builds. The Mach-O files are identical once
  their signatures are removed; the dSYM differs in a few DWARF bytes and has the
  same UUID.

Symbolication commands:
- `node node_modules/metro-symbolicate/src/index.js <build-2 main.jsbundle.map> < stack`.
  The map is the composed Metro + hermesc map that `SOURCEMAP_FILE` makes the
  Release build emit.
- `xcrun atos -o LokaR1A2.app.dSYM/Contents/Resources/DWARF/LokaR1A2 -arch arm64 -l <image base> <return address - 1>`.

The source map and dSYM are not retained here, because they contain
build-machine paths. Their hashes are in `build-2.txt`.

`superseded-dba6a1a/` holds the earlier run on build 2 at `dba6a1a`. That
source predates the Android-only handle fix. The earlier run also passed
139/139 and 19/19; it is superseded only so that both phones tested the same
source.

All files come from `iphone-11.sh` (`build 1`, `build 2`, `compare`, `run`,
with bounded 120 s waits) and pass through its `redact()`. `SHA256SUMS` covers
every file here, and `SHA256SUMS.verify.txt` is its check output.

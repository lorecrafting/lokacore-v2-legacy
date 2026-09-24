# R1-A1 spike: candidate C (disposable)

Candidate C under [ADR-068](../docs/rewrite-v3/16-decision-register.md): a pure
Elixir implementation for the server and a TypeScript implementation for the
phone. Both are held to the eight frozen inputs and to each other through
randomized differential testing ([envelope §3](../docs/rewrite-v3/r1-acceptance-envelope.md)).

This is throwaway R1 code, not production. R2 starts a fresh repository and
reimplements deliberately. The A1 gate passed on 2026-09-23 (main `f9ac1b5`);
since the A2 setup approval (PR #30), `setup.pending.json` passes `--stage A2`
instead. Candidate author: the Claude Code
implementing assistant (Claude Opus). The reviewers of the frozen inputs and the
setup must not author code here.

| Directory | What |
|---|---|
| `elixir/` | Mix project `loka_r1`: kernel, runner, fixture tests. No dependencies. |
| `ts/` | TypeScript kernel (runs on Hermes later, so no Node APIs in `src/kernel/`), Node runner, fixture tests. Only dev dependency: `typescript` 6.0.3, locked with the retained integrity hash. |
| `harness/` | Mix project: seeded generator, differential runner, minimizer, CI entry point. `mix r1.requests` writes the on-device differential input. |
| `server/` | Mix project `loka_r1_server`: the A2 durable host (GenServer per world instance, SQLite through `exqlite` 0.40.0, raw SQL), `mix r1.durable_runner`, `mix r1.faults`, `mix r1.sqlite_identity`. |
| `mobile/` | Expo app (release builds on Hermes): the phone durable host (`host.ts`, expo-sqlite), the on-device differential and fault cases (`device.ts`), the local module `modules/loka-memory` (memory probe, evidence files, process death), and M1 checks in `scripts/`. It bundles the unchanged `ts/src/kernel` through Metro `watchFolders`. |

Toolchain: Elixir 1.20.4 / OTP 28.4, Node 24.21.0 (it runs `.ts` directly by
stripping types, so write only erasable TypeScript), TypeScript 6.0.3 for type
checking.

## Rules

1. **Expected answers are read-only.** Tests read `docs/rewrite-v3/conformance/*.json`
   in place, first checking each file's SHA-256 against
   `docs/rewrite-v3/spec_tools/preserved-inputs.json`, and never write them. A test
   must not be edited to match an implementation.
2. **The contracts govern.** The Python models in `docs/rewrite-v3/checks/` are the
   executable reading of them. Match the models' observable behavior, including
   error codes, except where a contract says otherwise. Record any deliberate
   difference in this README.
3. **Kernels are stateless.** Each call takes the whole state value and returns a new
   one. No process state, clock, global RNG, filesystem or network inside a kernel.
4. **Implementations stay independent.** Whoever writes one implementation does not
   read the other's source. Both are written from the contracts, fixtures and models.

## Semantics covered

- **Codec and numeric profile** (`conformance/numeric-profile.md`): strict JSON
  parsing (duplicate keys, floats, exponents, NaN/Infinity, integers beyond
  ±(2^53−1), lone surrogates and non-ASCII object keys all rejected), canonical
  encoding (keys sorted, no whitespace, literal UTF-8, short escapes
  `\b \t \n \f \r`, lower-case `\u00xx` for other controls), xoshiro128** 1.1,
  `uniform` with rejection sampling and a draw budget, and signed truncating
  division.
- **Tiny world** (`contract_model.py`, credit policy `event` or `state`),
  **Lantern world** (`lantern_model.py`) and **composition**
  (`composition_model.py`). Receipt digests are SHA-256 hex of the canonical
  `{actor, action, targets, input}`. The TypeScript kernel needs its own pure
  SHA-256, since Hermes has no Node crypto.

## Runner protocol (identical in both languages)

A runner reads newline-delimited JSON requests on stdin and writes exactly one line
per request to stdout: the canonical encoding of the response, then `\n`. Each
request line is parsed with the strict profile parser. A line that fails to parse,
or has an unknown `fn` or malformed arguments, gets `{"error":"invalid_protocol"}`.
The Elixir runner is `mix r1.runner` in `elixir/`; the TypeScript runner is
`node src/runner.ts` in `ts/`. The differential harness compares response lines
byte for byte.

### `world.run`

```json
{"fn":"world.run","world":"tiny-event|tiny-state|lantern","initial":{...}?,"commands":[...]}
```

`initial`, when present, replaces both `memory` and `durable` before the first
command, as in the adverse fixtures. Commands:

- `{"op":"invoke","request":<any JSON>,"options":{"fault"?:string,"authorized"?:boolean}}`.
  `options` may be omitted.
- `{"op":"recover"}`
- `{"op":"settle","committed":<any JSON>}`

The response is a JSON array with one step record per command:

```json
{"result":R,"error":E,"events":[...],"delta":{...},"state":HOST}
```

- `result`: the invoke or recover response object, or `null` for settle and for errors.
- `error`: `null`, or one of these, in which case the step changes nothing:
  - `invalid_options`: `options` isn't an object, has other keys, a non-string `fault` or a non-boolean `authorized`.
  - `unknown_fault`: `fault` isn't one of `before_commit`, `commit_pending`, `after_commit_before_memory` or `after_memory_before_response`.
  - `invalid_commit_disposition`: `committed` isn't a boolean.
  - `no_pending_transaction`: settle with nothing pending.
  - `invalid_command`: an unknown `op`, or missing or extra fields.
- `events`: entries appended to `published` during this step.
- `delta`: for each top-level `memory` key whose canonical value changed in this step, the new value. Otherwise `{}`.
- `HOST`: `{"memory":{..},"durable":{..},"receipts":{id:{"intent":hex,"result":{..}}},"pending":null|{"id":..,"proposed":{..},"receipt":{"intent":..,"result":..}},"in_doubt":bool,"published":[..]}`.

### Protocol edge rules (settled 2026-09-23)

- **Lines:** input is split on `\n`, and every input line gets exactly one output
  line. A blank line, invalid UTF-8 (decode fatally; never substitute U+FFFD), a
  parse failure, unknown or extra top-level keys, or a missing required argument
  gets `{"error":"invalid_protocol"}`. JSON whitespace (space, tab, `\r`, `\n`) around
  values is legal, so a trailing `\r` is harmless.
- **`world.run`:** `commands` must be an array of any length, including 0 (the
  response is then `[]`). A non-object command is a per-step `invalid_command`.
  `world` must be one of the three names, and `initial`, if present, must be an
  object; otherwise the response is `invalid_protocol`. `initial` is harness setup,
  not player input: behavior for a value that isn't a complete, in-range memory of
  that world (including a nonzero RNG) is unspecified, and the generator never
  sends one. Revision overflow past 2^53−1 is likewise unspecified; the generator
  keeps revisions at least 64 below the limit.
- **Options:** a missing `authorized` means authorized, as in the model.
- **`composition.evaluate`:** `limits` must be an object whose keys are profile
  limit names and whose values are positive integers; anything else is
  `invalid_protocol`. `advance_target: null` means the same as leaving it out.
  All other argument shapes follow the model, so a wrong type or a missing key in
  `initial`, `root` or `rules` is `{"kind":"fault","code":"invalid_plan",...}`.
- `int.divide`'s `integer_out_of_range` can't be reached through the protocol,
  because the strict parser rejects such integers first.

### Pure functions

| Request | Response |
|---|---|
| `{"fn":"composition.evaluate","limits":{..},"initial":{..},"root":[..],"rules":[..],"advance_target"?:<any>}` | The model's result object. `limits` overrides keys of `composition-profile.json`'s limits. An absent `advance_target` means none. |
| `{"fn":"rng.next","state":<any>}` | `{"raw":n,"state":[..]}` or `{"error":"invalid_rng_state"}` |
| `{"fn":"rng.uniform","state":<any>,"bound":<any>,"max_draws":<any>}` | `{"value":n,"state":[..]}` or `{"error":code}`, with codes `invalid_bound`, `invalid_rng_budget`, `invalid_rng_state` and `rng_budget_exhausted`, checked in that order |
| `{"fn":"int.divide","a":<any>,"b":<any>}` | `{"q":n,"r":n}` or `{"error":"integer_out_of_range"|"divide_by_zero"}` |
| `{"fn":"json.canonical","text":string}` | `{"canonical":string}` or `{"error":"invalid_json"}` |

The `json.canonical` response holds the canonical text as a string. Its line
bytes are therefore that text's canonical re-encoding, which is deterministic.

## Differential testing (MUST for C)

`harness/` generates seeded sequences of 1 to 64 commands over all three worlds.
They include rejected and failed attempts, replays, altered intents, stale views,
faults, recovery, settle, boundary values and random nonzero RNG states. The
harness also generates composition plans and pure-function inputs. Every sequence
runs on both runners, and the first differing response fails the run. The harness
then prints the seed and the minimized failing input. A fast CI run executes the
fixed regression seeds plus at least 10,000 fresh sequences. It records the
generator version, seeds, sequence count and length distribution. Agreement
between the two is not correctness: the fixture suites stay authoritative.

## R1-A2 durable-host contract (both hosts; set 2026-09-24)

A2 puts each kernel behind a real durable host: the Elixir server adapter
(`server/`, BEAM + SQLite through `exqlite`, raw `BEGIN`/`COMMIT`, no Ecto) and the
phone app (`mobile/`, Hermes release build + `expo-sqlite`). The kernels are
unchanged. The authors of the two hosts do not read each other's host code
(rule 4). Physical schemas may differ (ADR-006); behavior may not.

**Oracle.** The in-memory model host (`LokaR1.World` / `ts/src/kernel/world.ts`)
is the expected behavior. With no real fault injected, a durable host's step
records for a `world.run` request are byte-identical to the model host's. The
`HOST` object's `durable`, `receipts` and `pending` are read back from SQLite,
not from process memory. The four model `fault` options stay accepted and mean
the same thing, now realized as real events (for example `before_commit` issues a
real `ROLLBACK` after the writes).

**Real injected faults.** A durable host additionally accepts a fault schedule
`{"step":n,"point":P,"kind":K}` outside the runner protocol (test/app input, never
player input).

| `point` | Where |
|---|---|
| `pre_decision` | after admission, before the kernel call |
| `post_decision_pre_commit` | proposal in memory, no SQL issued |
| `in_persistence` | inside the transaction, after at least one write |
| `post_commit_pre_adoption` | COMMIT returned, memory not yet updated |
| `post_adoption_pre_response` | memory updated, response not yet returned |
| `post_response_pre_presentation` | response built, not yet shown or sent |

| `kind` | Meaning |
|---|---|
| `raise` | a caught exception in the host at that point |
| `io_error` | the SQLite write fails (disk full / I/O error), transaction rolls back |
| `commit_unknown` | COMMIT is issued but its result is discarded (only `in_persistence`) |
| `kill` | the whole process dies (BEAM VM halt; app process killed), then restarts |

Required behavior is envelope §9. After every fault the host recovers from
SQLite only, and the recovered `HOST` must equal the model host's state for the
commit disposition that SQLite actually shows (committed iff the receipt row
exists). An unknown COMMIT fences new decisions until reconciled from storage; it
is never re-run. A definite rollback leaves no RNG advance. The next command after
recovery must produce a coherent continuation (same identity replays or retries).

**Fault evidence record** (one JSONL line per injected run): `host`, `world`,
`seed`, initial-state SHA-256, ordered `commands`, `fault`, the pre-fault durable
diagnostic record, recovered `HOST`, the next step record, `expected` (model),
and `verdict` (`pass`/`fail`). JS faults also retain the raw stack and the stack
symbolicated through the release source map (and dSYM on iOS).

**On-device differential.** The phone app runs a bundled JSONL of runner requests
(regression seeds and fixture rows, produced by `harness/`) through the kernel on
Hermes in the release build and writes one response line per request to a file.
The file is pulled to the M1 and compared byte for byte with the Elixir runner's
lines. One deliberately altered response line must be reported as a mismatch.

**Hygiene.** Never print or commit adb serials, UDID, ECID, team ID, certificate
identifiers, home or scratchpad paths, or app-container/LaunchServices UUIDs;
every capture script's `redact()` covers them. iOS build scripts record
`git rev-parse HEAD` and `git status --porcelain`.

**Server notes (readings taken by the server host, 2026-09-24; not contract text).**
(1) `step` is the 0-based index into the `world.run` commands, and a fault fires
only if that command reaches the point; the fault runs use a fresh identity so it
always does. (2) `io_error` applies only at `in_persistence`, the one point with a
write in flight. The hook pins `PRAGMA max_page_count` to the current page count
and inserts a 1 MiB blob in the open transaction, so SQLite returns SQLITE_FULL
and the host rolls back; the failing statement is the hook's, not the receipt
insert. (3) After any real fault, raised or killed, the host rebuilds from SQLite
alone: `memory` is the durable state, `in_doubt` is whether a pending row exists,
and `published` is empty, because the outbox isn't durable. The expected HOST is
the model host at the disposition SQLite shows, after the model's `recover`, with
`published` empty. (4) A caught fault answers `retryable` with `rolled_back`, or
with `response_lost` if the receipt row exists. `commit_unknown` answers
`retryable commit_unknown` with `in_doubt: true`, and the host reconciles before
it takes the next command. (5) The per-attempt diagnostic line is written only
when a diagnostic path is set (fault runs), not in the differential runs.

**Phone notes (readings by the `mobile/` author, 2026-09-24; the contract above is unchanged).**

- *Transactions.* The phone host issues `BEGIN IMMEDIATE` / `COMMIT` / `ROLLBACK`
  itself with `execSync` on one connection per database. expo-sqlite's
  `withTransactionSync` and `withExclusiveTransactionAsync` issue COMMIT inside
  the helper, so the host could not own the COMMIT point or discard its result.
- *What is durable.* Each step persists the difference between the kernel's
  `HOST` before and after the step in one transaction: durable state, new
  receipts, `pending`, and newly published events. Events go to an outbox table,
  so `published` is also read back from SQLite. The kernel publishes only on
  adoption, so the outbox always equals the model's `published`. `memory` and
  `in_doubt` stay in process memory. A restart sets `memory = durable` and
  `in_doubt = (pending row exists)`.
- *`before_commit`.* The model discards the proposal. The host writes the
  no-fault proposal and then issues a real `ROLLBACK`. This happens only when
  the faulted step would otherwise write nothing: a stale-view receipt is still
  committed, as in the model.
- *Expected state after a fault.* The model host runs the prefix, then the
  faulted command without a fault if SQLite shows its receipt, then `recover`,
  then the next command (the same request again). "Recovered `HOST`" is the
  state after that `recover`.
- *`io_error`.* At the point, the host clamps `PRAGMA max_page_count` to the
  current `page_count` and then issues a write that must grow the file. SQLite
  returns a real `SQLITE_FULL` ("database or disk is full") on the host's
  connection. In `in_persistence` that write is inside the host's open
  transaction, so the host's `ROLLBACK` discards its earlier writes. Clamping
  alone would fail only whichever write next needs a page, which is not
  deterministic.
- *`commit_unknown`.* COMMIT really succeeds and its result is discarded. So
  SQLite always shows "committed", and the not-committed branch of an unknown
  COMMIT is not exercised. The fenced attempt is retained as `fenced`.
- *`kill`.* Android: `Process.killProcess` (SIGKILL). iOS: `abort()` (SIGABRT),
  which leaves a crash report for dSYM symbolication. The M1 script relaunches
  the app. The recovery record carries `launch_before` < `launch_after`.
- *Fault cases.* 19 cases: 6 points × `raise` / `io_error` / `kill`, plus
  `commit_unknown` in `in_persistence`. The worlds rotate. The faulted command
  is an accepted, state-changing `take` (with an RNG draw, both outcomes) or a
  Lantern `move`. The cases do not cover duplicate delivery with stale views.

## A2 phone evidence (2026-09-24)

Bundles: `docs/rewrite-v3/r1-a2-evidence/android/` and `…/ios/`. Each has a
`SHA256SUMS` with its verify output beside it.

- **iPhone 11** (iOS 26.6.2). The app was Release build 2 at `e0930bb` (same app
  source as the Pixel run; the earlier `dba6a1a` run is kept in
  `ios/superseded-dba6a1a/`), signed
  by the free personal team. On-device differential: 139 request lines (22
  regression seeds' sequences and 95 fixture rows), all byte-identical to the
  Elixir runner. One altered line was reported as the only mismatch. Faults:
  19/19 pass, each also cross-checked against the Elixir runner. Six real
  process deaths, recovered on relaunch. JS stacks are symbolicated through the
  composed release source map. The crash reports' app frame is symbolicated
  with `atos` and the dSYM to `LokaMemoryModule.swift:17`.
- **Pixel 3a** (Android 11). The app was the APK from Actions run 36024373520
  at `e61c52a`. Differential: 139/139 byte-identical, and the injected mismatch
  was caught. Faults: 19/19 pass, Elixir cross-check included. Six SIGKILL
  deaths were logged by ActivityManager and recovered on relaunch. JS stacks are
  symbolicated through the Hermes composed source map.
  `android/failed-attempt-1/` keeps the first attempt. It failed before any
  fault case with a real host bug: two JS handles shared one expo-sqlite
  database, and garbage collection closed it. Fixed by opening each database
  once.
- **Builds.**
  - Android: two Actions builds per source commit. The Metro bundle, Hermes
    bytecode and source map are identical across builds.
  - Before `-PreactNativeDevServerIp=localhost`, `resources.arsc` embedded the
    runner's IP address.
  - After it, every zip entry, the v2 signature and the central directory are
    identical. Only AGP's dependency-info block (`0x504b4453`, stored encrypted
    with fresh randomness per build) differs.
  - AGP 8.12.0 (root `buildEnvironment`).
  - iOS: two clean builds. The Metro bundle, Hermes bytecode and source map are
    identical. The Mach-O files are identical once their code signatures are
    removed. The dSYM differs in 2 DWARF bytes, and the UUID is the same.
- **Not here:** latency, memory ceilings, load (R1-A3).

## Known gaps (A1 scope)

- Selector cardinality is only a model helper, and no operation reaches it.
- The durable outbox isn't modelled, so publication after recovery isn't compared
  beyond the in-memory `published` list.
- There is no Hermes, native Elixir adapter, SQLite, timing or device evidence here.
  All of that is A2 and later.

## Evidence so far (2026-09-23)

- **Fixture suites:** the Elixir suite has 32 tests and the TypeScript suite 89. Each covers every row of the six frozen fixture files, after checking their hashes.
- **Differential runs:** generator `r1-gen-3`, five local runs of the 22 regression seeds plus 10,000 fresh sequences each, base seeds 2–6. There were zero mismatches, and each run took about 45 s. The CI run (`r1-spike.yml`) uses a fresh seed every time and uploads its summary.
- **Coverage:** in 2,000 generated composition plans, the Python model reaches every one of its 30 fault codes, and about 70% of plans pass validation. The harness self-test enforces this.
- **Sensitivity:** CI alters one output byte of the real TypeScript runner and requires a mismatch. Locally, that divergence was caught within 23 sequences and minimized to two commands.
- **Limits:** agreement between the two is not correctness; the fixtures stay authoritative. None of this is Hermes, device, SQLite, timing or load evidence.

### A2 server evidence (2026-09-24)

Bundle: [`docs/rewrite-v3/r1-a2-evidence/server/`](../docs/rewrite-v3/r1-a2-evidence/server/),
produced at `2fc0fb3` on an M1 MacBook Air (MacBookAir10,1, macOS 26.6.2), with
`SHA256SUMS` and its check output.

- **Engine:** SQLite 3.53.4 (source id `2026-07-24 19:02:57 bf7c7f30…`), from the
  amalgamation bundled with `exqlite` 0.40.0 and built from source by Apple clang 21
  (`force_build`). `sqlite-identity.json` lists the compile options.
- **Oracle differential:** `mix r1.diff` with the durable runner in place of the
  TypeScript one. Generator `r1-gen-3`, base seed 20260924, the 22 regression seeds
  plus 10,000 fresh sequences (10,194 `world.run` requests), zero mismatches, 116 s.
- **Sensitivity:** a SQLite trigger that rewrites stored failed-roll receipts
  (`test/support/mutated_durable_runner.sh`). It only changes what the host reads back
  from SQLite, and it was caught at sequence 23 and minimized to two commands.
- **Real faults:** `mix r1.faults --seeds 6` gives 252 records: 14 point × kind pairs
  × 3 worlds × 6 seeds. All 252 pass, 18 per pair. That covers `raise` and `kill` at
  all six points, and `io_error` and `commit_unknown` at `in_persistence`. Each
  `kill` halted a child VM with status 137, and a fresh VM recovered from the file.
- **Not measured here:** timings, memory and load (R1-A3). Kills are VM halts, not
  power loss, so fsync durability isn't exercised.

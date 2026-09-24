# R1-A1 spike: candidate C (disposable)

Candidate C under [ADR-068](../docs/rewrite-v3/16-decision-register.md): a pure
Elixir implementation for the server and a TypeScript implementation for the
phone. Both are held to the eight frozen inputs and to each other through
randomized differential testing ([envelope §3](../docs/rewrite-v3/r1-acceptance-envelope.md)).

This is throwaway R1 code, not production. R2 starts a fresh repository and
reimplements deliberately. The A1 gate passed on 2026-09-23 (main `f9ac1b5`;
`setup.pending.json` passes `--stage A1`). Candidate author: the Claude Code
implementing assistant (Claude Opus). The reviewers of the frozen inputs and the
setup must not author code here.

| Directory | What |
|---|---|
| `elixir/` | Mix project `loka_r1`: kernel, runner, fixture tests. No dependencies. |
| `ts/` | TypeScript kernel (runs on Hermes later, so no Node APIs in `src/kernel/`), Node runner, fixture tests. Only dev dependency: `typescript` 6.0.3, locked with the retained integrity hash. |
| `harness/` | Mix project: seeded generator, differential runner, minimizer, CI entry point. |

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

## Known gaps (A1 scope)

- Selector cardinality is only a model helper, and no operation reaches it.
- The durable outbox isn't modelled, so publication after recovery isn't compared
  beyond the in-memory `published` list.
- There is no Hermes, native Elixir adapter, SQLite, timing or device evidence here.
  All of that is A2 and later.

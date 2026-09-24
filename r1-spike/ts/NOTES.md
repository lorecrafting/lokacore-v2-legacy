# TypeScript candidate notes

Run from `r1-spike/ts/` with Node 24.21.0:

```sh
npm ci --ignore-scripts --no-audit --no-fund
node node_modules/typescript/bin/tsc -p .
node --test 'test/*.test.ts'
node src/runner.ts            # NDJSON on stdin/stdout
```

`node --test test/` does not work on Node 24.21: a directory argument is loaded as a
module and fails. Use the quoted glob above, or plain `node --test`, which also runs
`test/helpers.ts` as an empty test file.

`src/kernel/` is pure and uses only ES2020 (`lib: ["ES2020"]`, no `@types/node`). A
test checks that it does not reference Node APIs. `types/node-min.d.ts` declares the
few Node APIs that the runner and tests use, because `package.json` must not gain
`@types/node`.

## Readings where the contract is silent

Each follows the Python model unless it says otherwise.

1. **The model raising inside `world.run`.** Examples are an invalid RNG in `initial`
   on `take`, an unknown room on `move`, and revision overflow. The model raises here,
   and the README defines no step code for it, so the whole request returns
   `{"error":"invalid_protocol"}`. The README edge rules now call these inputs
   unspecified.
2. **`initial` checks.** `initial` must have exactly the world's memory keys, and each
   field the model reads must have the type the model expects: ints for `revision`
   and `clock`, strings for rooms, `lantern` and `quest`, a string or null for
   `choice`, a bool for Tiny's `job_pending` and a list for Lantern's `narration`.
   Anything else is `invalid_protocol`. The edge rules leave this unspecified. This
   check avoids copying Python's behavior on odd types, such as `True + 1` or an
   f-string repr in `view:{revision}`.
3. **Receipt ids that can't be HOST keys.** A request `id` with non-ASCII characters
   becomes a key in `receipts`, and the canonical profile forbids non-ASCII keys, so
   the response can't be encoded. It returns `invalid_protocol`. The keys
   `"__proto__"` and `"constructor"` are ordinary data, because every object is
   null-prototype.
4. **Order of step-error checks.** Checks run in this order: `invalid_command` (op and
   field set), `invalid_options`, then `unknown_fault`. For settle,
   `invalid_commit_disposition` comes before `no_pending_transaction`. `options.fault:
   null` is `invalid_options`, as the README says ("non-string fault"), even though
   Python would treat `fault=None` as no fault.
5. **Composition cases that crash the model.** Python only catches
   `KeyError`/`TypeError`/`ValueError`/`UnicodeError`. Some shapes raise
   `AttributeError` or `IndexError` in the model, which crashes it. Examples are
   `active` as a dict or string that reaches `.append`, `locations` as a non-dict that
   reaches `.get` or `.values`, `capacities` as a non-dict, and an out-of-range list
   index. These return `invalid_plan`.
6. **Python container semantics in composition.** For arbitrary JSON the evaluator
   copies Python's behavior. A `list`/`dict` used with `in` on a dict or set, or as a
   set element, raises `TypeError`. `in` on a string checks for a substring, and `in`
   on a list uses `==`, where `True == 1`. Iterating a dict gives its keys in the
   order they were written, and iterating a string gives its code points. Lists can be
   indexed with ints and bools, including negative ones. Bools compare and add as
   0/1. Strings order by code point. The parser keeps the written key order for
   objects with integer-like keys, because JS would otherwise enumerate those keys
   first. `capacities.items()` iterates in that order.
7. **Sorting a `locations` list (a known gap).** CPython's timsort and the JS
   comparator can raise on different pairs, so when a non-dict `locations` list mixes
   types that can't be compared, the error can differ. This only affects junk
   `locations` lists, and it is marked `ponytail:` in `composition.ts`.
8. **Deep nesting.** CPython's recursion limit (about 1000 levels) makes `json.loads`
   raise on very deep nesting, while this parser accepts nesting up to the JS stack
   limit. The two diverge only on absurd inputs.
9. **The final line.** A final segment without a newline, if it isn't empty, is
   treated as a line and gets a response. The empty string after the last `\n` is not
   a line.
10. **`step` signature.** It is `step(world, host, command)`, not `step(host,
    command)`. The HOST shape has no world field, and passing the `World` value (which
    holds `decide`) is how the restored-RNG mutation test substitutes a mutant.
11. **`delta` comparison.** A key counts as changed when its canonical bytes differ.
    Memory never gains or loses keys, because every state is derived from the
    validated `initial`.

## Defect found by self-review, not by fixtures

For a Lantern `look`, the model publishes nothing (`return s, 'observed', [], True`).
The first draft published `["observed"]`, and no fixture pins that. A protocol test
now covers it.

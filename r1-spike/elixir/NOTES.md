# Elixir candidate notes

Where `r1-spike/README.md` leaves a choice, this implementation matches the Python
models in `docs/rewrite-v3/checks/`. The README's "Protocol edge rules" section
(dfd11d3) settled most of the open questions. These points are still readings of
the contract, not settled text.

## Interpretations

1. **World: where the Python model raises.** Some `initial` memories make the model
   raise, for example an unknown `room` on `move` (KeyError), a non-numeric `clock`
   on `wait` (TypeError), an invalid `rng` on `take` (ValueError from `uniform`), or
   a non-list `narration`. Then the whole `world.run` answer is
   `{"error":"invalid_protocol"}`, since there is no step error code for it. The
   README leaves this unspecified and says the generator never sends such memory.
   Everything short of a raise follows Python: `True == 1` in the model's equality
   checks, truthiness for `job_pending` and Lantern's `choice or ...`, and `bool`
   counting as an int in `revision += 1` and the `clock` comparison.
2. **World: `view` against a list or dict `revision`.** Python compares the view with
   `f"view:{revision}"`, so it needs `str()` of the revision. This implementation
   models `str()` for null, booleans, integers and strings. A list or dict revision
   matches no view, so the request gets `stale_view`. Python differs only when the
   view string is exactly that value's Python repr. This is unspecified input anyway.
3. **World: revision overflow.** The canonical encoder writes any integer, so a
   revision of 2^53 is written as `9007199254740992`, not rejected. The README
   leaves this unspecified.
4. **Composition: model exceptions.** KeyError and TypeError are `invalid_plan`, as in
   the model. The model's uncaught AttributeError is `invalid_plan` too: calling
   `.get` or `.items` on a non-dict `locations` or `capacities`, or `.append` on a
   non-list `active`. This follows the edge rule that a wrong type in `initial` is
   `invalid_plan`. Other quirks are modelled as Python behaves: `set(active)` over a
   list, dict or string, `in` on a dict, list or string for `active`, `jobs` and an
   overlay guard's `facts`, unhashable values in `in {...}` tests (TypeError, so
   `invalid_plan`, not the specific code), and booleans in comparisons with limits,
   `clock` and capacities.
5. **Composition: approximations.** (a) If `locations` is a list or string by the
   final containment walk, the answer is `invalid_plan`. Python sorts it and indexes
   it, which sometimes succeeds and sometimes raises IndexError. (b) `capacities` is
   iterated in key order. Python uses the request's key order, and that only differs
   when both a capacity fault and a query budget fault are possible and the request
   keys aren't sorted. The harness sends canonical JSON, whose keys are sorted.
6. **Command validation order.** An unknown op or wrong field set is
   `invalid_command`. Then, for `invoke`, `options` is checked as a whole
   (`invalid_options`) before the fault name (`unknown_fault`), so
   `{"fault":"typo","authorized":1}` is `invalid_options`. `settle` checks
   `invalid_commit_disposition` before `no_pending_transaction`, as the model does.
7. **World API.** The kernel entry point is `LokaR1.World.step(decide, host, command)`,
   not `step(host, command)`. The README's HOST has no world field, so the world's
   decide function (`World.world/1`) is passed in. That same parameter is how the
   mutation test injects a restored-RNG mutant.

## Evidence

- `mix test`: 32 tests. `test/fixtures_test.exs` reads all six fixture files in
  place after checking their SHA-256 against
  `docs/rewrite-v3/spec_tools/preserved-inputs.json`, and runs every row through the
  runner line protocol. `test/protocol_test.exs` covers the error codes, the edge
  rules, codec edges and a real `mix r1.runner` subprocess, including that each
  response is flushed before stdin closes.
- A scratch differential run is not retained here: 60,000 random requests,
  checked byte for byte against a Python reference runner built on the models.
  About half were world sequences of up to 40 commands and half were composition
  plans. There were no differences in the final run. An earlier run found
  differences only for a string or dict `active`, which is now modelled (point 4).
  It is not the harness, and it is not evidence for R1.

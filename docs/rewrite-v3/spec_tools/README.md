# Isolated Elixir specification tools

This is a small Mix/ExUnit project, **not the legacy server, a production engine,
or candidate C**. It starts no Phoenix, Ecto, database or gameplay authority.
Candidate A remains one TypeScript semantic package on Hermes/isolated Node,
with an Elixir BEAM-side harness; passing A ends the comparison. Tooling language
does not select a portable runtime or waive any prerequisite.

## Run

Use the scoped `.tool-versions`: Elixir **1.20.4 / OTP 28.4**. These are pinned
stable tooling versions, not fabricated locally installed versions or an R1
candidate dependency set. There are no Hex dependencies; `mix.lock` is empty by
design. Official verification: [Elixir release](https://github.com/elixir-lang/elixir/releases/tag/v1.20.4),
[Elixir installation compatibility](https://elixir-lang.org/install/),
[OTP 28.4 release](https://www.erlang.org/patches/OTP-28.4), checked 2026-09-22.
CI uses commit-pinned `erlef/setup-beam`; tests verify the actual full OTP version.

From this directory:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix loka.readiness --check-template
# Both MUST fail until their real stage-specific records/approvals exist:
mix loka.readiness --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root .. --stage A1
mix loka.readiness --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root .. --stage A2
# Temporary comparison ratchet, additionally requires Python 3:
mix test --include comparison
```

`mix test` itself does not require Python. The comparison tag is deliberately
excluded by default and included in migration CI. Both paths remain checked;
a language port is not independent oracle review. The JSON parser uses OTP's
`:json` with duplicate-key/number callbacks; the profile encoder explicitly
sorts ASCII keys, retains scalar Unicode, rejects floats and bounds integers.
This is the existing fixture codec, not general JSON canonicalization or a
production hostile-cartridge decoder. The uniform sampler's callback seam exists
only for controlled rejection/budget tests; ordinary calls use the fixed PRNG.

## Staged preparation

`--stage A1` permits deferred native/physical fields, never missing R0,
independent oracle/A1 setup review, execution-host details, exact
Node/TypeScript/Elixir/full-OTP identities or retained replayable locks.
`--stage A2` (also the default) requires full native/physical qualification setup.
A1 is semantic-only and cannot produce A2/R1/production authorization.

`setup_digest(data, "A1")` prefixes canonical setup bytes with
`loka-r1-a1-setup-v1` plus a NUL byte. The default/`"A2"` digest remains unchanged.
Both exclude `status` and `setup_review`; all other supplied fields stay bound.
Existing JSON schemas/records are reused. A changed stage requires a new genuine
setup review, not status editing or rehashing. See [the corpus guide](../conformance/README.md).
The authorized envelope amendment changes one of eleven preservation hashes;
the other ten, including all gameplay/numeric/profile/template inputs, stay fixed.

## Bounded inventory and retirement map

Inventory scope is `docs/rewrite-v3`, not an assertion about legacy tooling.
No production Python gameplay runtime is introduced or planned.

| Existing Python usage | Category | This PR / retirement boundary |
|---|---|---|
| `checks/readiness.py` | Durable setup/receipt checker | Continuing interface is `mix loka.readiness`. Python is retained as a temporary comparison oracle until this amendment's review/parity acceptance; no deletion before that acceptance. |
| `contract_model.py`: codec, division, RNG, sampling helpers | Durable fixture/numeric helpers inside an abstract model | ExUnit independently runs every original numeric vector/failure obligation. Python helpers remain because the retained models import them; remove only with those callers, not by breaking the models. |
| `contract_model.py`: serial owner; `composition_model.py`; `lantern_model.py`; `account_progress_model.py` | Small abstract behavioral models | Retained with all tests and reviewed JSON. Do not grow them into an engine. Move further continuing model work to focused ExUnit tests when required, with obligation mapping, before retiring each old model. A wholesale port is NOT an R1 prerequisite. |
| `release_scope.py` and planning tests | Durable scope/lock checker plus generated planning summary | Temporarily retained; its coupled registry/link/gate/summary checks require their own bounded parity change before retirement. Original 37-capability lock and release scope remain protected. |
| `packet_navigation.py` and navigation tests | Incidental reader generation plus link hygiene checks | Retained. No gameplay semantics. Its replacement is not a candidate feasibility dependency. |
| Existing `test_*.py`, new focused regression file | Comparison/behavioral obligations | All 98 methods continue in CI (94 baseline plus four defect regressions). Exact count is not the contract; no original obligation has been removed. |

## Coverage map

All new test names below are in `test/spec_tools_test.exs`. None changes the
checked-in expected answers. `preserved-inputs.json` independently records the
baseline hashes, including the chapter capability-lock source and all existing
JSON files. It is a preservation ratchet, not freshly generated expected gameplay.

| Old obligation | ExUnit coverage |
|---|---|
| `NumericCases.test_known_rng_output_and_next_state` | `frozen RNG outputs AND every next state` |
| `NumericCases.test_signed_division_known_answers` | `frozen signed division, remainder and numeric bounds`, plus exhaustive small signed quotient/remainder identities |
| `NumericCases.test_strict_numeric_and_encoding_cases` | `frozen strict JSON and canonical vectors`, `typed equality...`, `malformed JSON...` |
| `NumericCases.test_rng_bounds_and_rejection_sampling` | `RNG state, bound and budget diagnostics...`, `controlled rejected draw...`; rejected raw value consumes one draw and advances the proposed state, not modulo clamp |
| `PreparationCases.test_checked_in_template_is_honestly_incomplete` | `template is exact typed JSON and stays NOT READY`, `CLI preserves a controlled negative gate` |
| `PreparationCases.test_complete_synthetic_records_validate_structure_only` | `complete synthetic records test structure only` |
| `PreparationCases.test_malformed_evidence_entries_fail_with_typed_diagnostic` | `malformed evidence and normative set fail without crashes` |
| `PreparationCases.test_missing_or_changed_records_fail` | `every prior preparation mutation remains rejected`; transitional cross-check runs the shared valid/negative manifest families through both CLIs |
| `PreparationCases.test_hash_tampering_and_review_rebinding_fail` | `hash tamper, missing file, empty lock and setup rebinding fail` |
| `PreparationCases.test_oracle_must_cover_exact_inputs_even_when_receipt_rehashed` | `rehashed receipts cannot change...oracle inputs` |
| `PreparationCases.test_no_self_referential_setup_digest` | `setup digest has no self-reference and does bind configuration` |
| PF-01, PF-02, PF-03 corrections | Typed template, subject-author/boolean/rehash rejection and malformed RNG tests; PF-04 remains covered by the retained account regression |

The original four controlled composition mutants and Tiny mutation tests still
run in Python. New fixed canonical ordering/type bytes and rejected-draw/budget
assertions detect their corresponding mistakes. This is not exhaustive mutation
analysis, formal proof, database atomicity, device timing or independent approval.

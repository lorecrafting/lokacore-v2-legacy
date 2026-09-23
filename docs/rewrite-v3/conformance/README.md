# Small contract corpus and evidence boundary

**Status:** executable specification examples, pending normal packet acceptance. Not a production v3 engine, R1 candidate, full cartridge compiler, mobile build, or release certificate.

Run from the repository root:

```sh
python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py' -v
python3 docs/rewrite-v3/checks/release_scope.py --check
```

The checked-in JSON cases contain explicit inputs and expected projected state/results. `checks/contract_model.py` is a deliberately small standard-library Python model of receipt admission, one offered quest, a check, and a transaction boundary. It does not implement the entire YAML cartridge grammar. It models failure injection; it does not prove SQLite, PostgreSQL, BEAM, Hermes or a native FFI. Known-bad mutations in the tests establish sensitivity only to the listed defects. Passing examples are not a proof over all possible game traces.

No code or fixtures here are ported from legacy Lokacore. The only named external algorithm adapted is the explicitly attributed gameplay PRNG; that does not import an engine. They are specification inputs for the from-scratch rebuild. Do not adopt this Python model as the production implementation or let an implementation rewrite expected answers during CI.

## Small checked cases

`cases.json` fixes activation-before-credit, the no-retroactive-credit negative control, explicit state credit, matching retries, consumed choices and scheduled time. `checks/test_contracts.py` adds failed checks, changed intent, stale views, rollback and uncertain commit acknowledgement. The consumed-offer model is a separate narrow contract example, not a claim that the two-room YAML has been compiled or extended. Canonical projected states include revision, RNG state, quest/fact, and containment so visible success cannot hide divergence.

`numeric-vectors.json` fixes RNG output **and next state**, signed division/remainder, and numeric edges under the proposed numeric profile. The algorithm is specified independently in `numeric-profile.md`; candidate implementations must match the frozen values, not merely each other.

## R1 adapters must supply the missing evidence

For each accepted host, consume one versioned fixture directory containing:

```text
metadata.json                 # schema/capability/RNG/codec versions and fixture ID
source/ or prepared-defs.json  # prepared data is allowed before R4
expected-artifact.json        # exact compiled bytes/hash when a compiler is tested
initial-snapshot.json
commands.ndjson               # ordered semantic and admitted invocation inputs
fault-schedule.json
expected-results.ndjson       # per-step decision/StateDelta/events/effects/RNG
expected-states.ndjson        # per-step canonical mutable states
expected-projections.ndjson   # semantic views/continuations, not pixel output
```

Metadata must say which fields are real host evidence versus preparation. No pretend compiled artifact or blank expected file counts as a pass. Hashes are derived from retained canonical bytes and supplement a readable first-difference report. Operational timestamps, tracing IDs, addresses and transport sequence numbers stay outside portable semantic hashes; semantic event IDs/RNG/time stay inside.

Separate portable-rule parity, persistence/authority faults, and player-facing continuity. A shared kernel can be consistently wrong on every host; retain independently reviewed known-answer cases and registered invariants. R1 additionally injects a host-specific mismatch and demonstrates the adapter checker catches it.

## Specification checks

`release-scope.json` is reviewed planning/applicability input, not a candidate-controlled certificate. The checker enforces its chapter-one lock and generates `release-scope.md`. Real certification derives used features and transitive dependencies from the compiled artifact and engine registry, fails conservative on unknowns, and cannot trust a content author to omit a costly gate.

`contract-links.json` binds selected index summaries to governing document sections and acceptance IDs. The checker catches specific drift and missing links, not the semantic correctness of every paragraph. Review of the actual contracts remains necessary.

## Adoption from the Ink study

Use small implementation-neutral fixtures, separate immutable definitions from mutable saves, compare hidden state as well as transcript, and version numeric/save/artifact semantics separately. Do not embed Ink or copy its runtime architecture. See `../22-ink-runtime-lessons.md` for the pinned prior-art study and its limitations.


## Account/progress model scope

`checks/account_progress_model.py` and `test_account_progress.py` exercise document 23's local queue, authenticated-principal boundary, run/release binding, report replay/conflicts, evidence policy, multi-device membership, deletion and current admission rules. Principals and transaction fault outcomes are supplied by the test harness. In-memory assignment is not actual SQLite/PostgreSQL atomicity, token verification, or a mobile background uploader. ACCOUNT-01–12 require those real integrations at R12A/R14; these tests cannot mark them complete.

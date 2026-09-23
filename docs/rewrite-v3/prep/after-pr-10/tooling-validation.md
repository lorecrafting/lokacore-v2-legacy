# Tooling validation — not R0 acceptance or R1 evidence

## Exact revisions and execution provenance

Baseline: `864ed383de7657107914502a919491dd8ff9f705`.
Semantic/checker corrections: `e1c41438e486c5f166390da892e5df50636a64b8`.
Validated Elixir/preparation source: `d49f89c8f6d4ce39c11114f639cb25acfcc375e8`.
The permanent CI wiring and this record are a subsequent documentation/CI commit;
its exact-head result must be checked on the PR, not inferred from this run.

[Validation run 35833017655](https://github.com/lorecrafting/lokacore/actions/runs/35833017655)
completed successfully on 2026-09-23 UTC (2026-09-22 Hawaii).
It checked out actual main, reproduced the baseline, applied separately retained
correction/migration patches in a clean worktree, formatted/compiled/tested the
isolated project, and published the two clean commits above. The transport branch
and its workflow/payload are not in those commits or their ancestry. Main and the
new follow-up branch were checked for unexpected advancement before publication.

The hosted runner reported Ubuntu 24.04, x86-64 BEAM, Elixir **1.20.4** compiled
for OTP 28, and exact **OTP 28.4 / ERTS 16.3**. The full `OTP_VERSION` file and
ExUnit's runtime-pin assertions verified the patch version, not only OTP major.
`mix.lock` is empty because there are no external dependencies; no Phoenix,
Ecto, legacy application or database was started. These are tooling-host facts,
not the pending M1+/physical-phone experiment configuration.

## Commands and observed results

Commands below are from repository root unless the working directory is shown.

| Command | Observed result |
|---|---|
| `python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py' -v` before changes | 94 methods passed |
| Same command after corrections | 98 methods passed; no original method removed |
| `python3 docs/rewrite-v3/checks/release_scope.py --check` | Passed scope, capability lock, generated checklist and selected summary links |
| `python3 docs/rewrite-v3/checks/packet_navigation.py --check` | Passed 30 reader menus, local links and R milestone coverage |
| `python3 docs/rewrite-v3/checks/readiness.py --check-template` | Passed template integrity; explicitly NOT ready |
| In `docs/rewrite-v3/spec_tools`: `mix format --check-formatted` | Passed after formatting |
| Same directory: `mix compile --warnings-as-errors` | Passed; two `.ex` files, no compile warnings |
| Same directory: `mix test --include comparison` | **19 passed**, including transitional Python/Elixir readiness comparisons |
| Same directory: `mix loka.readiness --check-template` | Passed typed template integrity; explicitly NOT ready |
| Same directory: `mix loka.readiness --require-ready ../conformance/r1-run-manifest.template.json --evidence-root ..` | Expected exit **1**, `NOT READY: preparation pending...` |
| Same directory: `mix loka.readiness --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root ..` | Expected exit **1**, same pending diagnostic |

The permanent workflow additionally runs default `mix test` without the Python
comparison tag, followed by the full comparison run. See the exact PR-head CI
result for that added invocation. Default tests themselves do not invoke Python.
The [coverage map](../../spec_tools/README.md#coverage-map) maps four original
numeric and seven preparation methods. All behavioral/model, scope/navigation
and mutation checks remain available in the Python suite. Eleven original input
files are byte-hash locked in `spec_tools/preserved-inputs.json`; no reviewed
fixture, numeric vector, capability lock, threshold or expected ending changed.

## Corrections during validation / review provenance

One assistant performed implementation review, corrections, adversarial
self-review and subsequent fixes; this is **not independent approval**.

First disposable CI run `35832484709` reproduced 94/98 passing Python methods,
but stopped before ExUnit on a non-idempotent formatting layout. The setup action
also resolved requested OTP `28.4` to `28.4.3` under its default loose matching.
The call layout was simplified, and setup now uses `version-type: strict` with
Hex/Rebar installation disabled. No skipped check was called a pass.

Second run `35832698298` compiled cleanly on exact OTP 28.4, then passed 13/19
ExUnit tests. Six failures exposed a root-path handling error that rejected even
valid retained evidence. Resolving from the absolute path anchor fixed the bug;
positive bundles, malformed bundles, symlink containment/cycles, allocation bounds
and both-language comparison all pass in the successful third run. No fixture or
gate was weakened to obtain that result.

The successful run's artifact `10738011958` has archive SHA-256
`35d5bac8ac8c7c3c16a11f712a9cadeb5d57803eebd680a7b9909a70d285af33`.
Its source/log archive was downloaded and hash-verified; hosted artifacts have
seven-day retention, so this checked-in record preserves the result and the
source commits remain durable. A different language and CI run do not create
independent oracle review, authenticated acceptance, physical-device performance,
actual persistence-fault evidence or store approval.

**PREP-01 source review/corrections complete; PREP-02 remains blocked;
PREP-03 representation/policy analysis prepared with owner disposition pending.
R1-A1 has NOT started and is NOT authorized by this validation.**

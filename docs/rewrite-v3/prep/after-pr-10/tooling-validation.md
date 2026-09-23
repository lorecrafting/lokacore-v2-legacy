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

## Post-PR-11 continuation — exact main reproduced before edits

Observed and proposed R0 source: `9567117404f635c803373d9957050fd8ec50f334`.
PR #11 is merged; its reviewed head
`c06034b4643a6c259f385084d996ebabd1d151b9` and current main both have tree
`1af0a5df20aebef25444dbd593dcff1339bca9f0`. No later PR or explicit R0
approval was found in repository records or the #10/#11 discussions; #11 has
no inline review threads. Earlier paragraphs are historical execution records,
not current "awaiting merge" status or a substitute for this reproduction.

The retained PR #11 source archive was downloaded and verified against SHA-256
`62dfbc3e7cdad78cd122898b9a16b6941263cf1c278e1e64aa534c66da674268`.
Its head marker matches the reviewed source; upstream Git trees establish byte
identity with the current main baseline. Local Python reran all **98 tests**
before edits. Scope/navigation/template checks passed; both blank and pending
real manifests returned controlled readiness exit **1**.

Because this editing container has no `mix`, `elixir` or `erl`, the existing
read-only specification job was rerun, not replaced with a synthetic result:
[main run 35835903786, attempt 2](https://github.com/lorecrafting/lokacore/actions/runs/35835903786/attempts/2),
job `107104301783`, completed successfully on 2026-09-23 at 08:30 UTC
(2026-09-22 Hawaii). Its checkout is the exact main SHA above. Decoded job logs
show **98 Python tests**, **18 default ExUnit tests with one comparison excluded**,
and **19 ExUnit tests with comparison**. Formatting, warnings-as-errors
compilation, scope/navigation and both template checks passed. Both Mix negative
checks returned exit 1 with the expected pending diagnostic. Installed Elixir
was **1.20.4**, full `OTP_VERSION` was **28.4**, and ERTS was **16.3**.
The job retained artifact `10739447868`, reported archive digest
`139e44db41c9936ea3dc713467b49dfb97d14ddf125600b582d019baaf3a4641`;
this continuation inspected the decoded logs, not the bytes of that new archive.

The commands are the existing table's Python/scope/navigation/template and Mix
commands, plus separate `mix test` and the local Python `--require-ready` checks
on both manifests with `--evidence-root docs/rewrite-v3`. After the proposal and
pending-binding edits, the same local Python suite again passed **98 tests**;
scope/navigation/template checks passed and both negative checks returned the
same controlled exit 1. The follow-up PR's exact-head CI is checked separately
and reported in its review comment; this main run is baseline evidence only.

### Focused self-review and corrections

One implementing assistant performed review and adversarial self-review;
**neither is independent expected-answer or setup approval**. Review retained
the content-versus-architecture authority distinction and every qualifier in
all 67 ADR statuses, and kept `accepted_spec_commit`, identities, devices and
candidate locks empty. It corrected a broad tooling-availability statement:
Java exists locally, but Elixir/OTP/Mix, Xcode, adb/sdkmanager and Gradle do not.
The compatibility note was qualified for SDK 57's Xcode 27/iOS 27 scene-support
requirement; documentation minima are not actual native-build evidence.

Programmatic local review verified all **11 preserved input hashes**, the exact
seven input entries/order, all three retained evidence-reference hashes, the
recomputed setup digest, 19 existing normative paths and all 67 source ADR
status strings without promotion or omission. An in-memory status-only relabel
of the real pending setup was rejected for missing accepted specification
commit; tampering with each retained review/reference hash was also rejected.
Those challenges used copies, not fabricated approvals in the real records.

Only the existing handoff README, R0 proposal, pending setup/setup-review bindings
and this validation record change. Checkers, tests, tooling pins, workflow,
fixtures, envelope, public chapter and legacy/production code do not change.
Publication uses GitHub tree/commit/ref APIs because local GitHub DNS resolution
failed; this is not a claim of a local `git push`. The new branch starts from the
main SHA above; no merged branch is resumed and no production repository is made.
**R0/PREP-02 stay pending; R1-A1 has not started.**

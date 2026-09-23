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
(2026-09-23: historical. The R0 proposal was later retargeted, finally to
`74832d8e0f82162e79290d1b92fa6a4131df381e`; see `r0-acceptance.pending.json`.)
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

## Post-PR-12 dependency evidence

Starting main: `4a9f60c9040b3582fa79c39916307eab15c76e1b`; reviewed #12 head:
`367274e0c7ef942dd1c11e8b2eb79058cce24040`. GitHub comparison reports identical
files/trees. The proposed R0 contract stays
`9567117404f635c803373d9957050fd8ec50f334`; its proposal bytes and the oracle
record are unchanged. No later PR, separate R0 acceptance or actual device/setup
approval was found in the inspected records/discussions. The explicit owner
merge confirmation is not an acceptance record.

### Baseline execution versus inspected historical CI

The #12 source artifact `10740930231` was downloaded and checked against archive
SHA-256 `a7a97b3a4c1106520492db0ec1b864e7f78d8f0304ffb62f5b51f859897bcbfc`.
Its exact head marker and the no-file-change comparison establish the editing
baseline. Local Python reproduced **98 passing tests before edits**; scope,
navigation and blank-template integrity checks passed. Both the blank and real
pending manifests returned controlled readiness exit **1** separately.

The already completed [#12 run 35838639056](https://github.com/lorecrafting/lokacore/actions/runs/35838639056),
job `107108111450`, was inspected, not rerun or described as a new local result.
Its retained logs show 98 Python tests, 18 default ExUnit tests with one
comparison excluded, and 19 with comparison enabled; formatting, compilation,
template checks and the two expected Mix rejections passed on tooling-only
Elixir 1.20.4 / full OTP 28.4 / ERTS 16.3.

This editing environment was reassessed: Python 3.13.5, Node 22.16.0, npm 10.9.2
and Java are available; Mix/Elixir/OTP, Xcode, adb/sdkmanager and Gradle are not.
Direct GitHub/npm DNS resolution fails locally. Local native, Mix and online
npm commands are **unavailable**, not passing. Hosted resolution below uses a
different, explicitly recorded Node version. No local qualification is claimed.

### Actual hosted dependency resolution and retained bytes

[Capture run 35840888616](https://github.com/lorecrafting/lokacore/actions/runs/35840888616)
completed successfully: resolver job `107115388625` and retention job
`107115659050`. Capture source commit:
`b16ab5508248bec53ae98765f950e4ad8178bd37`. The retention job performed a real
`git push` to its bounded temporary branch, yielding evidence commit
`00971d3ebb7b9688d894b690292e0443251de2c9`. Neither temporary commit is a parent
of the focused follow-up; only the verified evidence blobs are imported.

Artifact `10741271537` was downloaded, verified against archive SHA-256
`0896d8544eaa146fb615a51f9605116d736a9c1ab8116968187de58a2bf5d429`, and its
nine file hashes checked. The ten retained files include those nine inputs plus
`SHA256SUMS`. Package manifest SHA-256:
`fb8f8395be872f7ff0fbfc76a6bb9e644c552daa9bfa9770c8272a839098d9d3`.
Package lock SHA-256:
`18ac7c91f854dcd55480dea15b57c52afa0d674863ce4d620221926b99644359`.
Both files are byte-identical to the first capture, before the excerpt fix below.

The full [resolution transcript](dependency-evidence/resolution.log),
[executed capture source](dependency-evidence/capture-workflow.yml.txt),
[upstream template](dependency-evidence/expo-template-package.json),
[SDK recommendations](dependency-evidence/expo-bundledNativeModules.json),
[runtime output](dependency-evidence/runtime.txt) and
[installed top-level graph](dependency-evidence/npm-ls.json) are retained, not
reconstructed from remembered versions. The lock is format 3 with 479 package
entries including the root; the Linux installs each reported 468 packages.

| Executed hosted command / check | Result |
|---|---|
| SDK 57 template and Expo package metadata capture; range-to-exact `npm view` resolution | Pass; direct dependencies match captured SDK recommendations and template ranges |
| `npm install --package-lock-only --ignore-scripts --no-audit --no-fund` | Pass; actual lock generated with Node 24.21.0 / npm 11.19.0 |
| `npm ci --ignore-scripts --no-audit --no-fund` in each of two clean directories | Both pass; no package lifecycle scripts run |
| `npm ls --all` and `node node_modules/expo/bin/cli install --check` in each directory | Both pass; full graph command exits 0; full tree stdout discarded, top-level JSON retained |
| `node node_modules/typescript/bin/tsc --version` | 6.0.3 |
| Lock SHA-256 check after first install; `cmp` after clean replay | Identical bytes |
| Fixed file-set, regular-file/size checks and `sha256sum -c SHA256SUMS` before retention | Pass |
| Hosted `git diff --cached --check` and temporary-branch push | Pass after the excerpt-format correction |

No app was generated and no gameplay/BEAM adapter, native project, native
lockfile, release build, database transaction or physical measurement was run.
The default SQLite and SQLCipher header versions, Hermes variant labels and
Android Gradle Plugin metadata are only source observations, not executed engine
or toolchain identities. `uuid@7.0.3`'s deprecation warning is preserved; no
vulnerability audit was run. No dependency override hides the warning.

### Failure retained rather than counted as success

The first [capture run 35840456743](https://github.com/lorecrafting/lokacore/actions/runs/35840456743)
had a successful resolver job `107114001453`, but retention job `107114260140`
failed `git diff --cached --check` (exit 2): numbered blank source lines ended
with a space. No commit/push occurred in that job. The excerpt printer now trims
trailing whitespace from the displayed numbered lines. SHA-256 values still
identify the original source bytes, and the package manifest/lock did not change.
The second run above repeated resolution, both installs and publication
successfully. The first run as a whole is **not** reported as a pass.

### Post-edit checks, binding update and review limits

Local post-edit commands: the same 98-test Python suite, scope/navigation and
`readiness.py --check-template` pass; each `--require-ready` probe on the blank
and real pending setup separately returns exit 1 with the pending diagnostic.
`git diff --check` includes the newly added evidence files. The follow-up's
exact-head hosted specification CI is separate from the historical #12 run and
is reported on the PR; it is not replaced by the dependency capture.

Programmatic self-review verifies all 11 preserved hashes, the exact seven
setup inputs/order, three evidence-reference hashes and the setup digest.
The five populated fields exactly match the retained package/lock/runtime
outputs; the other nine and the complete-lock reference remain null. New digest:
`3ac484c71e4ae2a9606dd2bc74cac39ca391a13023f46ffd5cd8601e77a07ab5`.
The pending setup-review reference hash is
`8f20cd0cdbae98430bbf5f8ac83b107f8fd55e7a624bb08d48097b5a4a549b2d`.
This rebinding does not create or renew an approval.

Adversarial self-review checks a status-only relabel of the actual pending setup
(still rejected for missing accepted commit), wrong retained-reference hashes
(rejected), a changed populated version (changes the setup digest), and mutated
lock bytes (fail the retained checksum). These use copies or in-memory values;
no synthetic acceptance, hardware or approval is written into the real records.
Direct package versions have no ranges; lock entries use registry HTTPS tarball
URLs with integrity fields. The package has no app entrypoint or lifecycle
scripts. No native/plugin configuration was inferred from this absence.

The implementing ChatGPT assistant authored the capture and evidence integration
and performed self-review, corrections and adversarial self-review. The hosted
bot executed/published the capture; GitHub account attribution does not identify
an independent reviewer or prove owner consent. Existing author/reviewer identity
fields remain incomplete pending attributable records. A new session, language,
role or successful second installation is not an independent oracle/setup review.

Only the evidence bundle, existing preparation README, setup/setup-review pending
bindings and this validation record change. The R0 proposal, expected-answer
record, 11 locked inputs, 7 setup inputs, checkers, tests, tooling pins and
permanent workflow are unchanged. Production/legacy code and real data are
untouched. Remote integration uses a clean tree/commit/ref update on the fresh
follow-up branch from actual main; local Git is only a validation snapshot and
is not presented as a pushed main-ancestry checkout. No auto-merge.

**PREP-02 now has a replayed JavaScript lock, not a complete native setup.
R0 and independent reviews remain pending. R1-A1 has not started.**

# R0 / PREP-02: staged preparation after PR #13

Starting main: `037e6513f882b25512928aab5883f8545b58fc84` (merged PR #13).
The R0 proposal now targets `74832d8e0f82162e79290d1b92fa6a4131df381e`,
retargeted at the owner's request (via `e1e0177`) from the unaccepted historical base
`9567117404f635c803373d9957050fd8ec50f334`; its record is not acceptance.
Unlike PR #13's dependency-only evidence, this follow-up deliberately amends
normative sequencing and the initial iOS qualification target. An eventual R0
acceptance for the new A1 path must explicitly cover the amended revision; do
not silently interpret adoption of an older base as adoption of new semantics.

[Work order](../../r1-work-package.md) · [Owner instruction](owner-instruction-2026-09-23.md)
· [Stage amendment/review record](../../reviews/2026-09-23-staged-preparation.md)
· [Fable review prompt](fable-review-prompt.md)
· [Tooling coverage](../../spec_tools/README.md)

## What the owner authorized

The owner accepted separating A1 semantic preparation from A2 native/physical
preparation, requested Expo previews, reported available hardware and delegated
minimum-target recommendations. The retained owner instruction is not a blanket
R0 approval or independent signoff. No A1 implementation is included here.

| Stage | Must be ready first | What a pass does not establish |
|---|---|---|
| A1 | Accepted amended contract, all seven exact inputs, identified candidate/subject authors, genuinely independent expected-answer review, actual execution host and Node/TypeScript/Elixir/full-OTP versions, retained replayable locks/commands, independent A1 setup review | Hermes/BEAM Port/SQLite integration, physical-device qualification, A2 readiness, runtime selection or production |
| A2 | A1 plus complete native configuration/package/native locks, all fourteen tool identities, actual qualification phones, approved common host and new stage-bound setup review | Performance/persistence/fault results not yet executed |
| R1 acceptance | All applicable original numerical/correctness/persistence/fault/load gates and independently reviewed retained results | R0, R2 production cutover, store approval or chapter release |

PREP-01 is complete. PREP-02 has a partial dependency bundle and new owner-reported
availability evidence, but neither stage is complete. PREP-03's existing specimen
and policy work remain parallel; its investment disposition is due at A5/R2,
not an extra A1 gate. Production remains clean-room at R2; the public chapter is
57 rooms, ten quests and two endings, with the four-place R6P still later.

## R0 decision remains separate

The [R0 proposal](r0-acceptance.pending.json) names the 19 normative files and
preserves all 67 qualified ADR dispositions, unchanged from the historical base.
Its decision, quoted below, has not been adopted in the inspected evidence:

> I accept `74832d8e0f82162e79290d1b92fa6a4131df381e` as the R0 contract under
> the normative file set, qualified ADR dispositions, remaining gates,
> amendment authority and fresh-repository cutover rule proposed in
> `prep/after-pr-10/r0-acceptance.pending.json`. Provisional, deferred and
> rejected decisions keep those dispositions. This does not approve an R1
> result, qualification hardware, expected answers/setup, store submission or
> production implementation.

The proposed commit includes the staged A1/A2 amendment, envelope v0.5 and
ADR-068's candidate order C, B, A with envelope v0.6's differential testing.
Retain explicit owner acceptance of that exact commit when given. Until then its `disposition`,
`accepted_spec_commit`, `reviewer_id` and `owner_decision_source` stay pending/null.
Do not retarget the old proposal merely because evidence or a PR was merged.
The exact fresh production URL/import commit is an R2 record, not needed now.

## Hardware and preview workflow

| Device | Evidence currently available | Intended role / missing facts |
|---|---|---|
| MacBook Air M1, 16 GB | Owner statement only; model/RAM populated, OS/cores still null | Preferred development and common server-test host. Need actual OS/build, execution architecture, cores, runtime evidence and approved test configuration |
| Physical iPhone 11 | Owner statement only; model/availability source populated | Selected initial iOS qualification class, replacing SE 2/3 GB before measurements. Verify SKU, RAM, OS/build and native tooling; no claim of 3 GB iPhone support |
| Old Google Pixel | Owner statement only, model unknown | Identify exact model/SoC/physical RAM/OS/architecture before any Android qualification substitution; A14/4 GB target remains |
| BOOX Palma 2 | Owner statement only | Supplementary e-paper readability/touch exploration, not Android minimum-phone performance evidence |
| iOS Simulator / Android Emulator on Mac | Proposed development tools, not claimed installed | Iteration and compatibility coverage, never physical latency/memory qualification |

Use Expo development builds as the ordinary mobile preview path once mobile
work is authorized. Expo Go may supply an early compatible preview with its
fixed native-library/SDK constraints; it cannot prove this app's native runtime,
configuration, SQLite engine, persistence or release behavior. Live JS updates
usually do not require rebuilding a development client, but native dependencies
or configuration changes do. A1 itself stays headless and stateless; this preview
direction does not add an app/UI milestone or change the retained lock now.

Official references checked 2026-09-23:
[Expo development builds](https://docs.expo.dev/develop/development-builds/introduction/),
[preview workflow](https://docs.expo.dev/develop/development-builds/use-development-builds/),
[Expo Go limitations](https://docs.expo.dev/develop/development-builds/faq/),
[local debug/release builds](https://docs.expo.dev/guides/local-app-overview/),
[Apple iPhone 11 specifications](https://support.apple.com/en-us/111865),
[BOOX Palma 2 specifications](https://shop.boox.com/products/palma2).
Apple identifies iPhone 11's A13 chip; the planned 4 GB class still requires
actual RAM evidence. BOOX lists e-paper, 6 GB and Android 13; those product
specifications do not establish the owner's installed firmware or app support.
Do not buy replacement hardware before identifying the Pixel.

## Cloud-first follow-up direction (not a silent host amendment)

The owner wants headless work on free GitHub-hosted runners and pays for no EAS
tier; app iteration and iPhone installs stay local on the M1 Air. See
[development host strategy](cloud-first-development.md) for the zero-cost plan,
rejected options and security boundaries. This correction preserves
the reviewed envelope byte-for-byte. The current envelope's M1+/16 GB host row
has **not** been changed to a hosted runner, and no actual setup observation or
approval is replaced by this preference. CI specification checks can run now;
R1-A1 still needs the accepted, explicitly amended/reviewed host setup.

## Hosted A1 execution evidence (proposed envelope v0.5)

Envelope v0.5 proposes one A1-only row: an identified GitHub-hosted Linux runner
may be the A1 execution host. It carries no timing, load or A2 weight, and the M1
row still governs common server tests. The amendment needs review; the refreshed
envelope hash in `setup.pending.json`, `oracle-review.pending.json` and
`spec_tools/preserved-inputs.json` renews nobody's consent.

[Bundle](a1-host-evidence/) came from `.github/workflows/v3-a1-host.yml`, run
35901131399 attempt 1 at source `e9a7bd626a7bf963776ba1fbb04cc2fca9d9aff0`,
image ubuntu24/20260920.314.1, x86_64, 4 cores, MemTotal 16372436 KiB, recorded
as `ram_gb: 16`. It observed Node 24.21.0, npm 11.19.0, TypeScript 6.0.3,
Elixir 1.20.4 and OTP 28.4. Replay commands all exited 0 and the lock bytes were
unchanged. `toolchain_lock` points at its `SHA256SUMS`, and
`SHA256SUMS.verify.txt` sits outside that index. `server` now describes this
runner. A2 must restore the actual common host under its own review. Rerun the
workflow for fresh evidence; a later image version is a new observation.

## Retained dependency evidence: reuse, do not resolve again

[Manifest](dependency-evidence/package.json) · [JavaScript lock](dependency-evidence/package-lock.json)
· [Transcript](dependency-evidence/resolution.log) · [Checksums](dependency-evidence/SHA256SUMS)
· [Packaged observations](dependency-evidence/dependency-observations.txt)

PR #13 retained Expo 57.0.24, React Native 0.86.3, React 19.2.3, expo-sqlite
57.0.3, TypeScript 6.0.3 and @types/react 19.2.18, resolved using Node 24.21.0 /
npm 11.19.0. Its two clean-directory installs, full npm graph checks and Expo
checks are historical hosted evidence, not a current Mac replay. Package scripts
were disabled; uuid@7.0.3's warning remains; no vulnerability audit was performed.

Lock SHA-256:
`18ac7c91f854dcd55480dea15b57c52afa0d674863ce4d620221926b99644359`.
Verify SHA256SUMS, then copy only the package manifest/lock into a disposable
directory outside the packet. With those exact recorded Node/npm versions:

```sh
npm_config_engine_strict=true npm ci --ignore-scripts --no-audit --no-fund
npm ls --all
CI=1 EXPO_NO_TELEMETRY=1 node node_modules/expo/bin/cli install --check
node node_modules/typescript/bin/tsc --version
```

Retain replay commands/runtime identities and byte comparisons. Do not rerun the
old range-resolution step without a specific compatibility reason/change record.
For A1, `toolchain_lock` must reference the complete retained A1 execution bundle
(JS lock plus actual Node/npm/TypeScript/Elixir/full-OTP tooling and host evidence),
not merely a filename with missing environment records. A2 needs complete native
configuration/locks as well. It remains null in the actual pending record.

For Fable F4, use **one retained checksum/index manifest** as the eventual
`toolchain_lock.path`, with its hash in `toolchain_lock.sha256`. List the actual
lock bytes, package manifest, execution-host record, Node/npm/TypeScript/Elixir
and full OTP output, replay commands/results and the resulting byte comparisons.
The manifest uses paths relative to a documented bundle root; keep its entries
inside that root, with no missing members, unsafe paths or unreviewed symlinks.
Run `sha256sum -c SHA256SUMS` from that root (or `shasum -a 256 -c SHA256SUMS`),
retain the successful verification output separately, and have the setup reviewer
inspect both coverage and **every referenced byte**. An index hash proves only
that the index is unchanged; the readiness checker does not recursively verify
members or authenticate runtime output. Avoid a self-containing checksum cycle.
A checksum pass over an incomplete or fabricated bundle is still not approval.
Do not point the pending field at the JS-only lock or at this instruction file.

Nine candidate fields remain unverified: Hermes, Elixir, full OTP, SQLite engine,
Xcode, iOS SDK, Android SDK, Gradle and JDK. Elixir/full OTP are required already
at A1 for its reproducible tooling; other native identities wait until A2.
Confirm the recorded five values on the actual chosen execution/native host as
applicable. Tooling-only Elixir 1.20.4 / OTP 28.4 pins are not observed candidate
identities. Hermes 0.17.0 versus V1 250829098.0.17 and default SQLite 3.50.3 versus
SQLCipher 3.49.1 are packaged metadata, not executed identities. AGP 8.12.0 is
not the Gradle distribution. Recheck actual Xcode/SDK compatibility, including
SDK 57's scene-lifecycle configuration when using Xcode 27/iOS 27 SDK.

The old `capture-workflow.yml.txt` is inert historical evidence; do not reinstall
it. Full prior execution/provenance is in
[tooling-validation.md](tooling-validation.md#post-pr-12-dependency-evidence).

## One artifact/field/evidence action list

| Contributor | Existing artifact / fields | Evidence needed |
|---|---|---|
| Owner | `r0-acceptance.pending.json`, accepted commit and source; setup's R0 binding | Explicit acceptance of the reviewed amended contract, keeping provisional/deferred/rejected ADRs and later gates. The sequencing instruction alone does not provide this |
| Setup preparer | `setup.pending.json`: host, authors, stage-required toolchain and `toolchain_lock`; later complete devices/native fields | Actual A1 environment/replayed locks first; native configuration and physical qualification inventory before A2. Preserve unknowns, owner-report provenance and explicit substitution decisions |
| Independent expected-answer reviewer | `oracle-review.pending.json`: author separation, disposition, accepted revision and exact seven inputs | State/result bytes and adverse cases; numeric outputs AND next states; ordering/conflicts/invariants/budgets/receipts/rollback/unknown commit; both Lantern outcomes/early possession; documented scheduler and save-fork/restore limitations. Fable is nominated, not pre-approved |
| Independent setup reviewer | `setup-review.pending.json`: author separation, disposition and stage-specific digest | Actual stage-complete evidence and identity/provenance review. Reviewing A1 does not approve A2; preparing setup does not authorize self-review |

## Binding sequence and stage checks

Refresh R0/oracle references in the setup after genuine approvals. Compute the
stage-specific setup digest, obtain genuine review of those bytes/stage, then
retain the setup-review file hash. `status: setup_reviewed` is warranted only by
that approval and is never itself a stage authorization.

A2 uses the original digest: SHA-256 of canonical setup excluding `status` and
`setup_review`. A1 uses the same bytes prefixed with UTF-8
`loka-r1-a1-setup-v1` and one NUL byte. Every other field remains bound, including
supplied deferred observations. A1 and A2 approvals cannot cross-bind even with
complete data. A changed stage or input needs real renewed review, not rehashing.

From `docs/rewrite-v3/spec_tools`, run both languages and both stages separately
against the blank template and actual pending setup, recording exit codes:

```sh
for stage in A1 A2; do
  mix loka.readiness --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root .. --stage "$stage"
  python3 ../checks/readiness.py --require-ready ../prep/after-pr-10/setup.pending.json --evidence-root .. --stage "$stage"
done
```

All four real-pending probes must currently reject; so must the four blank-template
probes. Omitting `--stage` remains strict A2. No weak default or synthetic receipt
is introduced. Only truthful A1 approval-backed readiness unlocks semantic work;
only full reviewed A2 preparation unlocks actual-host integration. A1 success is
not a documented C failure and cannot authorize B/A or production.

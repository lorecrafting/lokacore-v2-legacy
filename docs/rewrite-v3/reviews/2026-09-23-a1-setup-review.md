# Independent A1 setup review — 2026-09-23

**Disposition for the A1 execution setup: APPROVE WITH NOTES.**
The retained bundle is the bundle GitHub produced, every byte checks, every
A1-required field is what the logs show, deferred fields are null or typed as
owner reports, and both readiness implementations compute the same A1 digest.
The notes are small and none changes a reviewed byte.

This review does **not** approve A2. It does not fill
`setup-review.pending.json`; the implementer fills that receipt from this
report. It approves no R1 result, candidate, runtime selection, native
qualification or production step.

## 1. What was reviewed

| Item | Value |
|---|---|
| Reviewed commit | `main` at `88edd925165a06ae5c52237cd28638824e1cb80d` (merge of PR #26), checked out fresh as worktree branch `review/v3-a1-setup` |
| Accepted R0 contract | `f5bef28a3094083fed67712c771504954d65d2de`, per `prep/after-pr-10/r0-acceptance.pending.json` (`disposition: accepted`, owner decision quoted) |
| Subject manifest | `prep/after-pr-10/setup.pending.json`, stage A1 |
| Subject bundle | `prep/after-pr-10/a1-host-evidence/` — all eight files, every byte read |
| Producer | `.github/workflows/v3-a1-host.yml`, run 35901131399 attempt 1, source `e9a7bd626a7bf963776ba1fbb04cc2fca9d9aff0` |
| Oracle review | Already approved (`oracle-review.pending.json`); not redone |

Paths below are relative to `docs/rewrite-v3` unless they start with `.github`.

## 2. Provenance and authorship

| Artifact | Author of record | Git identity | Notes |
|---|---|---|---|
| `.github/workflows/v3-a1-host.yml` | Claude Code implementing assistant (Claude Opus 5.5 co-author trailer) | `Raymond Luong <raymond.n.luong@gmail.com>` (owner account `lorecrafting`) | Commit `e9a7bd6`, 2026-09-23 18:14:47Z; unchanged between `e9a7bd6` and `88edd92` |
| `a1-host-evidence/` bundle | GitHub-hosted runner executing that workflow | retained by commit `48f9c4b` (same assistant, same trailer), merged as PR #16 | Bytes match the run's uploaded artifact (section 3) |
| `setup.pending.json` fields | Same assistant lineage across `b0eb3d6`, `63732da`, `48f9c4b`, `8d20500`, `f6c69ab`, `c571a71` | same | 16 commits touch the file; no Fable co-author trailer on any reviewed file |
| `candidate_author_ids` | Declares "Claude Code implementing assistant, Claude Opus (R1-A1 candidate author)" | — | The candidate does not exist yet; this is a pre-declaration. The setup preparer and the declared candidate author are the same lineage. That is permitted; it means the setup reviewer must be independent of that lineage |
| This review | A fresh Claude Fable 5.1 agent on Claude Code, launched by the implementing assistant under the owner's account | — | I wrote no file under review. `git log` shows no Fable co-authorship of the manifest, bundle or workflow. I cannot authenticate my own identity beyond that statement; the launching session's attribution is not an attestation |

The GitHub account name on a commit is not an authorship or approval
attestation. The owner's R0 acceptance and the Fable oracle approval are
recorded by the implementing assistant; the owner may correct either.

## 3. Per-file findings

| File | Bytes | Checked | Result |
|---|---|---|---|
| `a1-host-evidence/SHA256SUMS` | 472 | Six entries, relative names, no `..`, no absolute path, no symlink in the directory, does not list itself or the verify file (no cycle). SHA-256 `6f237db6…3f4cd9` equals `toolchain_lock.sha256` | OK |
| `a1-host-evidence/SHA256SUMS.verify.txt` | 100 | Six `: OK` lines; sits outside the index as the README requires; equals the run log's verify step | OK |
| `a1-host-evidence/package-lock.json` | 227 690 | `cmp` identical to `dependency-evidence/package-lock.json`; SHA-256 `18ac7c91f854dcd55480dea15b57c52afa0d674863ce4d620221926b99644359` | OK |
| `a1-host-evidence/package.json` | 486 | `cmp` identical to `dependency-evidence/package.json`; pins expo 57.0.24, react 19.2.3, react-native 0.86.3, expo-sqlite 57.0.3, typescript 6.0.3, @types/react 19.2.18; engines node 24.21.0, packageManager npm 11.19.0 | OK (note N5) |
| `a1-host-evidence/host.txt` | 1 126 | `source_commit=e9a7bd6…`, `run_id=35901131399`, `run_attempt=1`, `ImageOS=ubuntu24`, `ImageVersion=20260920.314.1`, `RUNNER_ARCH=X64`, kernel `6.17.0-1022-azure`, `nproc=4`, `cpu_model=INTEL(R) XEON(R) PLATINUM 8573C`, `mem_total_kib=16372436`, `PRETTY_NAME="Ubuntu 24.04.5 LTS"`; every line equals the run log | OK (notes N2) |
| `a1-host-evidence/tools.txt` | 103 | `node=v24.21.0`, `npm=11.19.0`, `elixir=Elixir 1.20.4 (compiled with Erlang/OTP 28)`, `otp=28.4`, `typescript=6.0.3`; every line equals the run log | OK (note N3) |
| `a1-host-evidence/replay.log` | 49 245 | Four commands, each `exit=0`: `npm ci` (468 packages, one uuid@7.0.3 deprecation warning), `npm ls --all` (no `invalid`/`extraneous`/`missing`; only `UNMET OPTIONAL DEPENDENCY` lines), `expo install --check` ("Dependencies are up to date"), `tsc --version` ("Version 6.0.3"). Commands match the README's four replay commands (`env` prefix is the same thing) | OK |
| `a1-host-evidence/comparison.txt` | 240 | Retained and post-install lock SHA-256 both `18ac7c91…9644359`; `lock_unchanged_by_replay=true`; `manifest_unchanged_by_replay=true` | OK |
| `.github/workflows/v3-a1-host.yml` | — | `permissions: contents: read`; four actions pinned to full SHAs that resolve to real tags (checkout v4.4.0, setup-node v7.0.0, setup-beam v1.24.1, upload-artifact v4.6.2); `persist-credentials: false`; strict version types; verifies the dependency SHA256SUMS before replay; fails the job if any replay command or byte comparison fails; indexes and self-verifies the bundle | OK (notes N3, N4) |
| `setup.pending.json` | — | See section 4 | OK (note N1 about the receipt) |

Independent confirmation of the bundle's origin: `gh run download 35901131399
-n a1-host-evidence` fetched the artifact GitHub stored for that run; all eight
files are byte-identical to the retained copies (`cmp` on each). `gh run view
35901131399 --log` returned the full log (1 362 lines, not expired); the
identity lines quoted above appear there verbatim. Run metadata: event `push`,
branch `prep/v3-hosted-a1`, head `e9a7bd6`, created 2026-09-23T18:14:53Z,
conclusion `success`.

## 4. The manifest, field by field

Required at A1 (checker `A1_TOOLS` plus server, lock, inputs and records):

| Field | Value | Source | Verdict |
|---|---|---|---|
| `accepted_spec_commit` | `f5bef28…` | equals R0 record and oracle record | real |
| `server.model` | "GitHub-hosted runner ubuntu-24.04, image ubuntu24/20260920.314.1, Intel Xeon Platinum 8573C, x86_64" | host.txt (normalised capitalisation) | real |
| `server.os_build` | "Ubuntu 24.04.5 LTS, kernel 6.17.0-1022-azure" | host.txt | real |
| `server.cores` | 4 | `nproc=4` | real, but vCPUs (N2) |
| `server.ram_gb` | 16 | `mem_total_kib=16372436` = 15.61 GiB | rounded, disclosed in README (N2) |
| `toolchain.node` | 24.21.0 | tools.txt | real |
| `toolchain.typescript` | 6.0.3 | tools.txt, replay.log | real |
| `toolchain.elixir` | 1.20.4 | tools.txt | real |
| `toolchain.otp` | 28.4 | tools.txt (`OTP_VERSION` file) | real (N3) |
| `toolchain_lock` | `a1-host-evidence/SHA256SUMS`, `6f237db6…` | recomputed | real |
| `inputs[8]` | eight paths and hashes | all recomputed from the working tree | all match; identical to the oracle record's eight |
| `r0_acceptance`, `oracle_review`, `setup_review` | paths and hashes | recomputed | all match |

Deferred at A1 and correctly left alone:

- `toolchain.hermes`, `sqlite`, `xcode`, `ios_sdk`, `android_sdk`, `gradle`,
  `jdk`: null. Nothing invented.
- `toolchain.expo` 57.0.24, `react_native` 0.86.3, `sqlite_binding` 57.0.3:
  supplied from the replayed lock. These are resolved package versions, not
  executed runtime identities, and the README says so. They are bound in the
  digest because they are supplied, which is the intended rule.
- `devices.ios`: `qualification_class: iphone-11`, `model: iPhone 11`, all
  inspected fields null, `availability_record` typed as an owner report citing
  `owner-instruction-2026-09-23.md` (which does say "iphone 11 physical"). No
  RAM, SKU, OS or build claimed.
- `devices.android`: entirely null. The Pixel is not inventoried and is not
  pretended to be.
- `status: preparation_pending`, as it must be before a receipt exists.

## 5. The A1 digest

Both implementations, run against the manifest at `88edd92`:

| Implementation | Stage | Digest |
|---|---|---|
| `checks/readiness.py` `setup_digest(manifest, 'A1')` | A1 | `95d454b76a8ec138420f81a4e1ff40000c1d1f9ec56f831fefc9e0678fb530ae` |
| `spec_tools` `LokaSpec.Readiness.setup_digest(data, "A1")` (Elixir 1.20.4 / OTP 28.4) | A1 | `95d454b76a8ec138420f81a4e1ff40000c1d1f9ec56f831fefc9e0678fb530ae` |
| both | A2 (for the record, not approved) | `a60314fc24419df2ff5dbf1e0db6e2a8f0a9739148e94bf47f65fdffffb60270` |

**The A1 digest this review approves is
`95d454b76a8ec138420f81a4e1ff40000c1d1f9ec56f831fefc9e0678fb530ae`.**
It is SHA-256 of `loka-r1-a1-setup-v1` + NUL + the canonical manifest without
`status` and `setup_review`. Any change to any other field, including the
deferred device fields, produces a new digest and needs a new review.

## 6. Findings

None blocks. Severity: low = should be fixed when the receipt is filled;
info = recorded so nobody has to rediscover it.

**N1 — low.** `prep/after-pr-10/setup-review.pending.json:9` holds
`setup_digest: bd2b9e2f…7e67c6`. That value was written at `b0eb3d6`, before
the hosted bundle existed, and matches no A1 or A2 digest of any manifest
revision from `48f9c4b` onward. It is harmless today because the receipt is
pending and the field is excluded from the manifest digest, but both checkers
reject a filled receipt whose digest differs ("setup review does not bind exact
configuration"). Smallest correction: when filling the receipt, set
`setup_digest` to `95d454b7…530ae`, `accepted_spec_commit` to `f5bef28…`,
`subject_author_ids` to the setup preparer (the Claude Code implementing
assistant, Claude Opus 5.5 co-authored commits `63732da`, `48f9c4b`, `8d20500`,
`f6c69ab`, `c571a71` under the owner's account), `reviewer_id` to this fresh
Fable agent, then rehash the file into `setup.pending.json` `setup_review.sha256`.
Do not change any other manifest field, or the digest above no longer applies.

**N2 — info.** `setup.pending.json:36-37`: `cores: 4` is `nproc` on an Azure
VM (vCPUs, not physical cores) and `ram_gb: 16` rounds 16 372 436 KiB
(15.61 GiB). The exact numbers are in `host.txt` and the README discloses the
rounding. At A1 the checker requires only `>= 1`; no timing or memory claim
rests on these. No correction needed at A1. A2 restores the M1 host under its
own review.

**N3 — info.** `.github/workflows/v3-a1-host.yml:62-63`: `tools.txt` keeps only
the last line of `elixir --version` and reads OTP from the `OTP_VERSION` file.
The emulator/erts identity (`Erlang/OTP 28 [erts-16.3] … [jit:ns]`,
`erl -version` → 16.3, `otp_release` → 28) exists only in the GitHub run log,
which expires. `OTP_VERSION` is the documented full-identity source, so the
recorded `28.4` is correct. Smallest improvement for the next rerun, not for
this bundle: drop `tail -n 1` and also record `erl -noshell -eval
'io:format("~s~n",[erlang:system_info(otp_release)]), halt().'`.

**N4 — info.** `.github/workflows/v3-a1-host.yml:6-9`: the push trigger names
`prep/v3-hosted-a1`, now merged. Fresh evidence must come from
`workflow_dispatch` on `main`, which exists. Also `npm install -g npm@11.19.0`
fetches from the registry without a pinned integrity hash; the version is
asserted afterwards, and the replay's own packages are integrity-checked by the
lock. Node 24.21.0 came from the runner image's toolcache
(`Found in cache @ /opt/hostedtoolcache/node/24.21.0/x64`), not a download the
job checksummed.

**N5 — info.** `a1-host-evidence/package.json:2`: the package name is
`loka-r1-a-dependency-evidence`, from before the C-first amendment. Cosmetic.
Its bytes are frozen by hash; do not edit it.

## 7. Commands and exit codes

All run locally in the review worktree at `88edd92` on macOS (Darwin 25.6.0),
Python 3, Elixir 1.20.4 / OTP 28.4 via `mise exec`. Every readiness probe was
run as its own command.

| Command | Result | Exit |
|---|---|---|
| `shasum -a 256 -c SHA256SUMS` (bundle root) | 6 × OK | 0 |
| `cmp` bundle lock vs `dependency-evidence/package-lock.json` | identical | 0 |
| `cmp` bundle manifest vs `dependency-evidence/package.json` | identical | 0 |
| `gh run download 35901131399 -n a1-host-evidence` + `cmp` × 8 | all identical | 0 |
| `gh run view 35901131399 --log` | 1 362 lines, available | 0 |
| `git diff --quiet e9a7bd6 HEAD -- .github/workflows/v3-a1-host.yml` | identical | 0 |
| `git diff --quiet e9a7bd6 HEAD -- …/dependency-evidence` | identical | 0 |
| `python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py'` | 118 tests OK | 0 |
| `python3 docs/rewrite-v3/checks/release_scope.py --check` | PASS | 0 |
| `python3 docs/rewrite-v3/checks/packet_navigation.py --check` | PASS | 0 |
| `python3 docs/rewrite-v3/checks/readiness.py --check-template` | PASS | 0 |
| `git diff --check` | clean | 0 |
| `mix format --check-formatted` | clean | 0 |
| `mix compile --warnings-as-errors` | clean | 0 |
| `mix test` | 25 passed, 3 excluded | 0 |
| `mix test --include comparison` | 28 passed | 0 |
| `mix loka.readiness --check-template` | PASS | 0 |
| `mix loka.readiness --require-ready setup.pending.json --stage A1` | NOT READY: preparation pending | 1 |
| `mix loka.readiness --require-ready setup.pending.json --stage A2` | NOT READY: preparation pending | 1 |
| `mix loka.readiness --require-ready template --stage A1` | NOT READY: preparation pending | 1 |
| `mix loka.readiness --require-ready template --stage A2` | NOT READY: preparation pending | 1 |
| `readiness.py --require-ready setup.pending.json --stage A1` | NOT READY: preparation pending | 1 |
| `readiness.py --require-ready setup.pending.json --stage A2` | NOT READY: preparation pending | 1 |
| `readiness.py --require-ready template --stage A1` | NOT READY: preparation pending | 1 |
| `readiness.py --require-ready template --stage A2` | NOT READY: preparation pending | 1 |

All eight probes reject, as they must while `status` is `preparation_pending`
and the receipt is unfilled. The first rejection reason is the status field, so
these runs do not yet exercise the digest comparison; section 5 covers that
directly.

## 8. What this review cannot prove

- That the runner's hardware is what `/proc` reports. It is a virtual machine;
  CPU model, core count and memory are the hypervisor's story. Nothing at A1
  depends on them being exact.
- That GitHub's log and artifact store were not altered. The review trusts
  GitHub as the executor of a workflow whose text is in `main`'s history.
- That the Node binary in the toolcache and the OTP/Elixir builds from the
  hex.pm mirror are authentic upstream builds. The job recorded their reported
  versions, not their checksums.
- Anything about timing, load, memory footprint, Hermes, SQLite, phones or
  native toolchains. The envelope's A1 row excludes all of it and so does this
  review.
- That the R1-A1 candidate, once written, will actually run on this host and
  lock. That is an R1 result manifest's job.
- My own independence beyond what git history shows. The owner confirmed on
  2026-09-23 that a fresh Fable agent counts as independent; I am one, and I
  did not author or edit any reviewed file.

## 9. Disposition

| Subject | Disposition |
|---|---|
| A1 execution setup at `88edd92`, digest `95d454b7…530ae` | **APPROVE WITH NOTES** (N1–N5) |
| A2 setup | **Not reviewed, not approved.** Needs the M1 common host, all fourteen tool identities, native locks, inspected phones and a new stage-bound review |
| Actual A1 authorization | Not granted by this review. It follows only from a truthful filled receipt, `status: setup_reviewed`, and both `--stage A1` probes passing on those bytes |

Smallest remaining list: (1) fill `setup-review.pending.json` per N1 and rehash
it into the manifest; (2) rerun both `--stage A1` probes and retain the two
exit codes; (3) nothing else before R1-A1 semantic work begins.

# A2 setup recheck of PR #30 — 2026-09-23

**Disposition for the A2 native/physical setup at `6b73803`: APPROVE WITH NOTES.**
Every required change from the first A2 review is applied as its ruling
worded it; every hash in the three indexes and in the manifest recomputes;
the Android bundle is byte for byte the one GitHub run 35966206296 produced
and the APK it retained; both phones' raw captures carry the Hermes, SQLite
and OS-visible memory identities with their capture scripts beside them; the
history rewrite removed every serial-bearing object from the branch; the A1
record and every protected file are byte-identical to `main`. The notes
below change no byte that the A2 digest binds. The only thing between
`setup.a2-proposed.json` and passing `--stage A2` in both checkers is the
review receipt, which this report specifies exactly and which is filled after
this approval, not by it.

This recheck fills no receipt, changes no file except this report, and
approves no R1 result, candidate, runtime selection or production step.

## 1. What was reviewed

| Item | Value |
|---|---|
| Subject | PR #30, branch `prep/a2-freeze`, head `6b738030f7fe4d52da4709bcfc7d672acc419a04` (confirmed with `gh pr view 30` at start; 16 commits), base `main` `40ab191e8293cc9e742755bfce5a84199e6c56e3` |
| Worktree | `~/dev/lokacore-a2-recheck`, branch `review/v3-a2-recheck` at the head above; `~/dev/lokacore-a2` not used |
| Prior review | `reviews/2026-09-23-a2-setup-review.md` at reviewed head `8e56566` (CHANGES REQUIRED, F1–F17, Rulings 1–5, OD1–OD4); retained unchanged on the branch by `392c0d1` |
| Accepted R0 contract | `f5bef28a3094083fed67712c771504954d65d2de` (`r0-acceptance.pending.json`, `disposition: accepted`) |
| Proposed manifest | `prep/after-pr-10/setup.a2-proposed.json`, status `a2_proposed_not_reviewed`; digests from both implementations: A1 `9345d52bf91948e5cdd9d9f4f97a971be24f3e56e74e901a0f6d9497c5efcecd`, A2 `fef848f945da4608997dd4c3c81c470721dbdae98db3d338259be8bf7d742d1a` |
| Owner decisions | `prep/after-pr-10/owner-decision-a2-2026-09-23.md`, SHA-256 `40b33035646008135795c4e8d10f487397fb138e55df88397aa15b6246b68f2a` |
| Combined index | `prep/after-pr-10/a2-toolchain-lock.SHA256SUMS`, SHA-256 `8a755fac33140e6179ffe5408929acc8145b34d7f5ef7c0d957bf1ba54cecd5b`, 44 members; verify output `a2-toolchain-lock.verify.txt` outside it |
| Device bundle | `a2-device-evidence/`: 25 files, 23 indexed (index and verify file outside); every file read or grepped |
| Android bundle | `a2-android-evidence/`: 14 files, 12 indexed; producer `.github/workflows/r1-android-native.yml`, run 35966206296 attempt 1, source `c4d2059ad29fe38990bc78a5a3cc5bb5834cf1f0`, image ubuntu24/20260920.314.1 |
| Probe app | `r1-spike/mobile/` (`App.tsx`, `app.json`, `.gitignore`, `modules/loka-memory/**`, `package.json`, `package-lock.json`); identical between `c4d2059` and the head |
| Checkers | `checks/readiness.py`, `spec_tools/lib/readiness.ex`: byte-identical to `main` |
| A1 record | `setup.pending.json` byte-identical to `main`; A1 digest `95d454b76a8ec138420f81a4e1ff40000c1d1f9ec56f831fefc9e0678fb530ae` unchanged in both implementations |

Paths are relative to `docs/rewrite-v3` unless they start with `.github`,
`r1-spike` or `.gitattributes`. Governing texts: README §8, REVIEW-GUIDE,
`prep/after-pr-10/README.md` ("Binding sequence and stage checks"),
`r1-work-package.md` §"Evidence bundle and review boundary", 14 §PREP-02 /
R1-A2 rows, the prior A2 review, and the A1 review and oracle recheck as
style models.

## 2. Provenance and independence

| Artifact | Author of record | Notes |
|---|---|---|
| All 16 commits `0b06abe`…`6b73803` | `Raymond Luong` (owner account), each with `Co-Authored-By: Claude Opus 5.5` | Same implementing lineage as the A1 setup preparer and the declared candidate author |
| Run 35966206296 bundle and APK | GitHub-hosted runner, event `pull_request`, checkout of the PR head `c4d2059` (`ref: github.event.pull_request.head.sha`) | Two artifacts only (`a2-android-evidence`, `app-release-apk`), created 06:54Z; independently downloaded twice into fresh directories (section 3.2) |
| Device bundle | The implementing assistant on the owner's M1, owner handling the phones (relayed owner reports at a2-plan.md:279-285) | Every cited file now has its capture script retained and indexed (F7) |
| Owner decisions OD1–OD4 | Owner's words relayed by the coordinating assistant, transcribed by the implementing assistant | Labeled as a retained conversation source, not an identity attestation (owner-decision file lines 3–11) |
| This recheck | A fresh Claude Fable 5.1 agent on Claude Code under the owner's account, launched by a coordinator. Not a fork of the author's session and not the first reviewer's session | I authored none of the reviewed files; `git log` shows no Fable trailer on any of them |

Disclosure: the scratchpad directory this session was given is the
coordinating session's, and the implementing agent used the same directory
(`a2-device-evidence/pixel-3a-probe.txt:12` shows its path, and the author's
working files, including redaction inputs, are present there). I did not open
any of those files; my APK and bundle comparisons used two fresh
`gh run download` directories of my own; the temporary file in which I held
the two old serial values for counting was deleted before this report was
written. Sharing a temp directory is not sharing a conversation or an
authorship; the reviewed bytes are in git, not in that directory. The owner
has previously accepted that a fresh Fable agent counts as independent.

## 3. Independent verification

### 3.1 Hashes

| Check | Result |
|---|---|
| `shasum -a 256 -c SHA256SUMS` in `a2-device-evidence/` | 23 × OK; `SHA256SUMS.verify.txt` reproduced exactly; index does not list itself or the verify file; no `..`, absolute path or symlink |
| `shasum -a 256 -c SHA256SUMS` in `a2-android-evidence/` | 12 × OK; verify file reproduced; same structural checks |
| `shasum -a 256 -c a2-toolchain-lock.SHA256SUMS` from `prep/after-pr-10/` | 44 × OK; `a2-toolchain-lock.verify.txt` reproduced; neither the index nor the verify file is listed; no `..` or absolute path |
| SHA-256 of the combined index | `8a755fac…cd5b` = `setup.a2-proposed.json:57` |
| Eight inputs, `r0_acceptance`, `oracle_review` in the proposed manifest | all recompute |
| Five file hashes cited inside the two `availability_record` strings (`iphone-11-ideviceinfo.txt`, `iphone-11-probe.txt`, `pixel-3a-adb.txt`, `pixel-3a-probe.txt`, `owner-decision-a2-2026-09-23.md`) | all recompute |
| Twelve hashes cited by `setup.pending.json` (A1) | all recompute |

Combined-index membership against Ruling 5: the six `a1-host-evidence`
files (`package.json`, `package-lock.json`, `host.txt`, `tools.txt`,
`replay.log`, `comparison.txt`); all 14 files of `a2-android-evidence/`
including its index and verify file; all 24 files of `a2-device-evidence/`
except `boox-palma-adb.txt`, including its index and verify file. The
documented root is `prep/after-pr-10/` (a2-plan.md:166-177). The BOOX file
is in the device bundle's own index but not in the combined one, exactly as
the plan says (line 39–41); it is not cited by the manifest.

### 3.2 Android bundle against GitHub run 35966206296

- `gh api …/runs/35966206296/artifacts`: exactly two artifacts,
  `a2-android-evidence` (20 709 bytes, expires 2026-12-23) and
  `app-release-apk` (15 194 059 bytes, expires 2026-10-24). One job,
  `android`, success, 06:47:33Z–06:54:10Z; event `pull_request`, head
  `c4d2059`, attempt 1.
- `gh run download 35966206296` into a fresh directory (done twice): all
  14 bundle files `cmp`-identical to the retained ones; APK SHA-256
  `c0d65fbaae69e8d79f6969225b6d2dd61108496223cb2bdf36aad4f0feea72a7`,
  27 734 061 bytes, equal to `apk-facts.txt:1` and `pixel-3a-probe.txt:8`.
- `gh run view --log`: 1 158 lines, available; the identity lines
  (`source_commit=c4d2059…`, `apk=app-release.apk sha256=c0d65fba…`,
  `A2 compileSdk=android-36`, `hermes-android:250829098.0.17`,
  `sqlite_version_string: 3.50.3`, `mem_total_kib=16373440`) are present.
- `host.txt:2` `source_commit=c4d2059…` is on the branch
  (`git merge-base --is-ancestor c4d2059 HEAD`), and
  `git diff --quiet c4d2059 HEAD -- r1-spike/mobile .github/workflows/r1-android-native.yml`
  is empty, so the built tree is the head's for the built paths.
- `gradle-build.log:88,104-184` shows the local `loka-memory` module
  autolinked and built; `build-environment.txt:101` is "No dependencies"
  (the plan's F11 disclosure at lines 143–149 is accurate).

### 3.3 History rewrite (OD3)

- The old head `8e56566` and the four old serial-bearing commits
  (`25d0052`, `a2dbdf4`, `420f919`, `478af0d`) are still fetchable by SHA
  from GitHub (`git fetch origin 8e5656…` succeeds; the plan says so at
  line 64–66).
- `git diff 8e56566 b337467` is empty: the rewritten head tree equals the
  old reviewed tree. For every old→new pair the plan lists (line 61–64),
  author, committer, dates and message are identical, and the tree diff
  touches only `pixel-3a-adb.txt`, `boox-palma-adb.txt`, the device
  `SHA256SUMS` and (for `478af0d`→`394915b`) `setup.a2-proposed.json`, i.e.
  exactly the serial-bearing bytes and the hashes that pointed at them.
  `af699df`→`c97c0d5` is tree-identical (already redacted at that commit).
- Two distinct `adb` serial values (8 and 10 characters) were taken from the
  old `25d0052` blobs and used only as grep patterns, never printed. Counts:
  old history `origin/main..8e56566` `git log -p`: 4 hits (control);
  new history `origin/main..HEAD` `git log -p`: 0; commit messages: 0;
  every object reachable from HEAD (`git rev-list --objects HEAD | git cat-file --batch`):
  0; working tree: 0.
- Identifier sweep of the head tree: no UDID-shaped (`00008030-…`/8-16 hex)
  token, no 40-hex certificate SHA-1, no `DEVELOPMENT_TEAM` value, no
  provisioning-profile UUID, no `Apple Development: <name> (<team>)`
  identity in any device file; every such field reads `[redacted]`
  (`iphone-11-xcodebuild.log` 59 redactions, `devicectl` 7, `ideviceinfo` 7,
  syslog 2). `CODE_SIGN_IDENTITY=Apple Development` / `iPhone Developer`
  are identity *types*, not identifiers.

### 3.4 Probe claims

| Claim | Evidence | Result |
|---|---|---|
| Same app source revision on both phones | Android: run 35966206296 built `c4d2059`; `pixel-3a-probe.txt:8,12-14` installs that APK by hash. iOS: `iphone-11-xcodebuild.log:6209` timestamps the build at 2026-09-23 20:53:18 local (06:53:18Z), after `c4d2059` (06:47:15Z) and before `17f2a10` (07:04:30Z); `r1-spike/mobile` is identical from `c4d2059` to the head; the Podfile.lock lists `LokaMemory (0.0.0)` from `../modules/loka-memory/ios`; the syslog probe line carries the field names the module at that revision emits. The iOS build script does **not** record `git rev-parse HEAD` or a clean-tree check | Inspected for Android; **inferred** (consistent, not proven) for iOS — note N1 |
| Hermes and SQLite in raw captures | `pixel-3a-logcat.txt:3-24` (raw `adb logcat -d`, `OSS Release Version 250829098.0.17`, `Build Release`, SQLite `3.50.3` with source id `2025-07-17 … 3ce993b8…`); `iphone-11-syslog.txt:776-796` (raw `idevicesyslog`, same values) | OK, in raw files, not only excerpts |
| Physical-memory bytes and source API in raw captures | `pixel-3a-logcat.txt:19-22` `ActivityManager.MemoryInfo.totalMem` `3766829056`; `iphone-11-syslog.txt:793-796` `ProcessInfo.processInfo.physicalMemory` `4039901184`; API names match `LokaMemoryModule.kt:16` and `LokaMemoryModule.swift:8` | OK |
| Consistency with the 4 GB class | Pixel: 3 766 829 056 B = 3 678 544 kB = `MemTotal` (`pixel-3a-adb.txt:50`, `pixel-3a-probe.txt:53-55`), 3.51 GiB. iPhone: 4 039 901 184 B = 3.76 GiB. Both above 3 GB and below 6 GB classes | OK (class figure, not available memory, as labeled) |
| Capture scripts retained | `m1-air-host.sh`, `m1-tools.sh`, `m1-xcode.sh`, `iphone-11-ideviceinfo.sh`, `iphone-11-build.sh`, `iphone-11-probe.sh`, `pixel-3a-adb.sh`, `pixel-3a-probe.sh`; each writes the file named beside it, prints `$ cmd` and `exit=` per command, and defines its `redact()` | OK; all in both indexes |
| Raw vs excerpt labeling | a2-plan.md:26-44 lists which files are verbatim-under-composed-layout, which are script-composed excerpts (`iphone-11-pods.txt`, `iphone-11-probe.txt`) and which are raw logs; the file headers say the same (`iphone-11-pods.txt:2`, `pixel-3a-probe.sh:4-5`, `iphone-11-probe.sh:2-5`) | Accurate |
| Hermes release tarball and `lipo` (F16) | `iphone-11-pod-install.log:94-96` verifies and caches the release tarball; `iphone-11-xcodebuild.log:997,1546-1547` shows the replacement phase; `lipo -archs: arm64` at `iphone-11-pods.txt:42` and `iphone-11-probe.txt:12` | OK |
| Timestamps | Device captures 06:45:02Z–07:04:17Z; iOS build observed 06:54:11Z; Pixel probe 06:59:31Z; iPhone probe 07:03:44Z; `ideviceinfo` 07:04:17Z; manifest `availability_record` timestamps equal the files' first lines | Consistent |

### 3.5 Setup encodings against Rulings 1–5

| Field | Head value | Ruling text | Result |
|---|---|---|---|
| `ios.architecture` (line 18) / `android.architecture` (line 29) | `"arm64"` both | Ruling 1 | OK |
| Raw names appended | line 19 `; CPUArchitecture arm64e (ideviceinfo), recorded as class arm64`; line 30 `; ro.product.cpu.abi arm64-v8a (adb), APK native-code arm64-v8a, recorded as class arm64` | Ruling 1 verbatim | OK |
| `android.qualification_class` (line 22) | `"galaxy-a14-4gb"`; line 30 `; substitutes for the galaxy-a14-4gb class per prep/after-pr-10/owner-decision-a2-2026-09-23.md sha256 40b33035… (ADR-070 proposed)` | Ruling 2 / OD1 | OK; hash recomputes |
| ADR-070 text, four additions (F9) | a2-plan.md:217-248: RAM labeled as Google's published figure with the inspected kernel figure; `sdm710` labeled inspected, Snapdragon 670 labeled reviewer catalogue knowledge and unverified; setup encoding stated; decision-maker and retained source named; the "do not update its OS" sentence attributed as an instruction whose first giver is not retained | Ruling 2 items 1–4, F9 | OK |
| `installed_ram_gb` (lines 15, 26) | `4` both; line 19 `installed RAM 4 GB is the class figure (not published by Apple; not inspected); physicalMemory 4039901184 bytes read on device (…)`; line 30 `installed RAM 4 GB is the class figure (Google product specification, not inspected); kernel MemTotal 3678544 kB; totalMem 3766829056 bytes read on device (…)` | Ruling 3 | OK; both cite the probe file by path and hash |
| `ios.soc` (line 14) | `"A13 Bionic (Apple product page for iPhone12,1, cited in prep/after-pr-10/README.md; not tool-inspected)"`; README.md:84 carries the Apple citation | F4 verbatim | OK |
| `server` (lines 33-38) | `MacBookAir10,1, Apple M1, arm64`, `macOS 26.6.2 (25G83)`, 8 cores, 16 GB; owner confirmation OD4 recorded at a2-plan.md:191 and in the decision file | Ruling 4 / OD4 | OK |
| `toolchain_lock` (lines 55-58) | combined index, root `prep/after-pr-10/`, members as required, hash recomputes | Ruling 5 / F5 | OK |
| Fact classes kept separate | Inspected (device/tool lines with hashes), owner-reported (OD1–OD4, Personal Team, phone connection; a2-plan.md:279-285), catalogue (A13, 4 GB), reviewer catalogue (Snapdragon 670) are each labeled | — | OK, except the iOS "same tree" statement (N1) |

### 3.6 Protected files versus `main`

`git diff --stat 40ab191 HEAD --` over `setup.pending.json`,
`r0-acceptance.pending.json`, `oracle-review.pending.json`,
`setup-review.pending.json`, `a1-host-evidence/`, `dependency-evidence/`,
`prep/after-pr-10/README.md`, `16-decision-register.md`,
`r1-acceptance-envelope.md`, `conformance/`, `checks/`, `spec_tools/`:
empty. The eight frozen inputs recompute to the hashes both manifests cite.
`git diff --name-only 40ab191 HEAD` contains nothing outside
`prep/after-pr-10/{a2-*,owner-decision-a2-*,setup.a2-proposed.json}`,
`reviews/2026-09-23-a2-setup-review.md`, `r1-spike/mobile/`,
`.github/workflows/r1-android-native.yml` and `.gitattributes`. No scope
creep.

## 4. Prior findings and owner decisions

| ID | Required change (prior wording) | Status | Evidence at `6b73803` |
|---|---|---|---|
| F1 | `arm64` on lines 18/29; raw names appended to 19/30 | resolved | §3.5 rows 1–2 |
| F2 / OD1 | `galaxy-a14-4gb`; owner decision retained and cited by path + hash; four ADR-070 additions | resolved | owner-decision file §OD1 "Yes, prep decision file"; manifest line 22 and 30; a2-plan.md:217-248 |
| F3 / OD2 | `4` on both with labeled sources, only after an OS-visible iPhone reading; both probes from one app revision (A) or the plan says otherwise (B) | resolved (owner chose A) | manifest lines 15, 19, 26, 30; `iphone-11-syslog.txt:793-796`; `pixel-3a-logcat.txt:19-22`; see N1 on how the iOS revision is established |
| F4 | `ios/soc` as the labeled catalogue string | resolved | manifest line 14, verbatim |
| F5 | `toolchain_lock` filled per Ruling 5 after F3 and F7 | resolved | §3.1; 44 members verified |
| F6 / OD3 | Rewrite so no serial-bearing blob reaches `main`; plan sentence about `a2dbdf4` | resolved (owner chose (b)) | §3.3: 0 hits in all objects reachable from HEAD; a2-plan.md:53-68 records the rewrite and that run 35951344446 is superseded by 35966206296 whose source is on the branch |
| F7 | Reword plan lines 9–10; retain capture commands per composed file; retain raw xcodebuild, pod install and devicectl output; do it before the index is built | resolved | a2-plan.md:26-44; eight scripts; `iphone-11-xcodebuild.log` (31 313 lines), `iphone-11-pod-install.log` (243), `iphone-11-devicectl.txt` (108), `iphone-11-syslog.txt` (965), `pixel-3a-logcat.txt` (24); all in the combined index. `boox-palma-adb.txt` remains a composed excerpt without a script and is labeled so and excluded from the manifest and combined index |
| F8 | `.gitattributes` exemption for the device bundle; one disclosing line in the plan | resolved | `.gitattributes:6`; a2-plan.md:70-75 |
| F9 | Four ADR additions; attribute the OS instruction | resolved | a2-plan.md:217-248 (attribution honestly recorded as "not retained") |
| F10 | info: Maven recorded, not locked | carried, recorded | a2-plan.md:138-142 |
| F11 | info: record AGP on next rerun | carried, disclosed | `build-environment.txt` added but is the wrong project ("No dependencies"); a2-plan.md:143-149 says so and defers the root `buildEnvironment` to the next needed rerun. Not a setup field |
| F12 | info: one sentence that `toolchain.sqlite` is the phone engine | resolved | a2-plan.md:108-111 |
| F13 | info: say `DEVELOPER_DIR` is required on the M1 | resolved | all three Xcode scripts set it; a2-plan.md:155-158, 261-262; `m1-tools.sh:4` home path kept and disclosed |
| F14 | info: stale PR-description line | resolved | PR body now describes the rewrite; no "serial numbers" line |
| F15 | info: dates consistent | carried | a2-plan.md:265-266; re-checked (§3.4) |
| F16 | info: retain release-tarball fetch and `lipo -archs` | resolved | §3.4 |
| F17 | info: `minSdk=24` is not a setup conflict | carried | a2-plan.md:269-271 |
| OD4 | Confirm the M1 Air as common host | resolved | owner-decision file §OD4 "Confirm M1 Air"; a2-plan.md:191 |

Resolved: F1–F9, F12–F14, F16, OD1–OD4 (17). Carried as informational with
accurate disclosure: F10, F11, F15, F17 (4). Unresolved: none.

## 5. New findings

Severity as in the prior review. None is blocking; none changes a byte the
A2 digest binds.

**N1 — low.** a2-plan.md:200-202 ("Both readings come from one app revision
(source `c4d2059`: the Android APK from run 35966206296 … and the iOS
Release build from the same tree)") and :281-283 state the iOS source
revision as a fact. For Android it is inspected (`host.txt:2`). For iOS it
is inferred: `iphone-11-build.sh` records neither `git rev-parse HEAD` nor
`git status --porcelain -- r1-spike/mobile`, so an uncommitted local edit at
build time cannot be excluded. The inference is strong (build timestamp
between `c4d2059` and `17f2a10`; `r1-spike/mobile` unchanged since
`c4d2059`; Podfile.lock and probe field names match the revision) but it is
an inference. Required, in the same commit that fills the receipt (the plan
is not digest-bound): change the two sentences to say the iOS build's source
revision is inferred from the build timestamp and the unchanged tree, not
recorded. For the next iOS build, add to `iphone-11-build.sh` the
`git rev-parse HEAD`, `git status --porcelain -- r1-spike/mobile` and
SHA-256 of `App.tsx` and `modules/loka-memory/**` lines to
`iphone-11-pods.txt`.

**N2 — info.** Residual non-sensitive identifiers in bound files, outside the
owner's exclusion list: `pixel-3a-probe.txt:12` contains the author's
absolute scratchpad path including a Claude Code session id;
`iphone-11-probe.txt:27,29` contain the per-install app-container UUID and
the device's LaunchServices `databaseUUID`. None is a serial, UDID, ECID,
team ID or certificate identifier. Changing these bytes now would re-index
and re-review for no security gain; leave them, and add `$TMPDIR`-style
path redaction and the `databaseUUID`/`installationURL` lines to the
scripts' `redact()` on the next capture.

**N3 — process, must be handled when the receipt is filled.**
`prep/after-pr-10/README.md:184-198` prescribes one `setup.pending.json` and
one `setup-review.pending.json` that are updated as stages complete, and
says A1 and A2 approvals cannot cross-bind. Consequences the author must
carry out together, in one commit, whichever file layout is chosen
(section 7): (a) a receipt bound to the A2 digest cannot also satisfy
`--stage A1` on the same manifest, so once the A2 record is in place
`--stage A1` on it fails with "setup review does not bind exact
configuration" by design; (b) if the A2 receipt overwrites
`setup-review.pending.json`, `setup.pending.json` (A1) must be superseded
or re-pointed in the same commit or it fails on "retained hash mismatch";
(c) README lines 211–213 ("the actual setup passes `--stage A1` … and must
still reject A2 and the default") become false and must be rewritten to the
A2 state. The A1 approval remains recorded by
`reviews/2026-09-23-a1-setup-review.md` and digest `95d454b7…530ae`. This
is a sequencing instruction, not a defect in the reviewed bytes.

**N4 — info.** AGP version is still unrecorded (F11). The plan's reason for
not rerunning (a workflow edit rebuilds the APK and supersedes the Pixel
probe) is correct: the workflow's `paths` filter includes the workflow file.

**N5 — info.** `m1-tools.txt` (03:23Z, `xcodebuild` exit 1 under Command
Line Tools) predates the Xcode capture (`m1-xcode.txt`, 06:45Z). Both are
retained and the plan explains the order (F13). Not a conflict.

## 6. Commands and exit codes

All run in the recheck worktree at `6b73803` on macOS (Darwin 25.6.0),
Python 3, and Elixir 1.20.4 / OTP 28.4 / Node 24.21.0 via
`mise exec elixir@1.20.4 erlang@28.4 node@24.21.0 --`; no sudo; no Xcode
tool was needed. Each readiness probe was its own process.

| Command | Result | Exit |
|---|---|---|
| `gh pr view 30` head check | `6b73803…` (unchanged) | 0 |
| `shasum -a 256 -c` device / android / combined index | 23 / 12 / 44 × OK; all three verify files reproduced | 0 |
| recompute 8 inputs + r0 + oracle + lock + 5 availability-cited hashes (proposed); 12 hashes (pending) | all match | 0 |
| `gh run download 35966206296` (fresh dir, twice) + `cmp` × 14 | identical | 0 |
| `shasum -a 256` downloaded APK | `c0d65fba…ea72a7`, 27 734 061 bytes | 0 |
| `gh api …/artifacts`, `gh run view --json jobs`, `gh run view --log` | 2 artifacts, 1 job success, 1 158 log lines with identity lines | 0 |
| `git fetch origin 8e56566…`; `git diff --quiet 8e56566 b337467` | fetchable; trees identical | 0 |
| serial grep over `git log -p origin/main..HEAD`, messages, all reachable objects, working tree | 0 / 0 / 0 / 0 (control on old history: 4) | 0 |
| `git diff --quiet c4d2059 HEAD -- r1-spike/mobile .github/workflows/r1-android-native.yml` | identical | 0 |
| `git diff --stat 40ab191 HEAD -- <protected files>` | empty | 0 |
| `git diff --check 40ab191 HEAD` | clean | 0 |
| `python3 -m unittest discover -s checks -p 'test_*.py'` | 118 tests OK | 0 |
| `checks/readiness.py --check-template`; `mix loka.readiness --check-template` | PASS / PASS | 0 / 0 |
| `mix format --check-formatted`; `mix compile --warnings-as-errors --force` | clean / clean | 0 / 0 |
| `mix test`; `mix test --include comparison` | 25 passed, 3 excluded / 28 passed | 0 / 0 |
| `readiness.py --require-ready setup.pending.json --stage A1` | PASS; A1 ONLY | 0 |
| `readiness.py --require-ready setup.pending.json --stage A2` | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `readiness.py --require-ready setup.pending.json` (default) | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `readiness.py --require-ready setup.a2-proposed.json --stage A1` | NOT READY: preparation pending or unsupported candidate work package | 1 |
| `readiness.py --require-ready setup.a2-proposed.json --stage A2` | NOT READY: preparation pending … | 1 |
| `readiness.py --require-ready setup.a2-proposed.json` (default) | NOT READY: preparation pending … | 1 |
| `mix loka.readiness --require-ready setup.pending.json --stage A1` | PASS; A1 ONLY | 0 |
| `mix loka.readiness --require-ready setup.pending.json --stage A2` | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `mix loka.readiness --require-ready setup.pending.json` (default) | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `mix loka.readiness --require-ready setup.a2-proposed.json --stage A1` | NOT READY: preparation pending … | 1 |
| `mix loka.readiness --require-ready setup.a2-proposed.json --stage A2` | NOT READY: preparation pending … | 1 |
| `mix loka.readiness --require-ready setup.a2-proposed.json` (default) | NOT READY: preparation pending … | 1 |
| `setup_digest` of `setup.pending.json`, Python and Elixir | A1 `95d454b7…530ae` (unchanged from the A1 review), A2 `a60314fc…0270`; equal in both | 0 |
| `setup_digest` of `setup.a2-proposed.json`, Python and Elixir | A1 `9345d52b…cecd`, A2 `fef848f9…2d1a`; equal in both; equal to the PR description's values | 0 |

Scratch dry run (a copy of `docs/rewrite-v3` outside the repo, never written
back; both checkers with `--evidence-root` at the copy):

| Variant | Python | Elixir |
|---|---|---|
| A: `status: setup_reviewed`, receipt still null, `--stage A2` | NOT READY: missing retained path/hash (1) | same (1) |
| B: A plus a receipt as in section 7 at a new path, `--stage A2` | PASS: R1-A2 preparation records complete (0) | PASS (0) |
| B, default stage | PASS (0) | PASS (0) |
| B, `--stage A1` | NOT READY: setup review does not bind exact configuration (1) | same (1) |
| C: `setup.pending.json` re-pointed at an A2-bound receipt, `--stage A1` | NOT READY: setup review does not bind exact configuration (1) | same (1) |

So at the head the sole remaining rejection after the status flip is the
null receipt, and a receipt bound to `fef848f9…2d1a` makes both checkers
pass at A2 and default on these exact bytes.

## 7. Exact receipt contents and status value

For `setup.a2-proposed.json` at `6b73803`, unchanged in every field other
than the two below (any other change alters the A2 digest and voids this
approval):

- `"status": "setup_reviewed"`.
- `"setup_review": {"path": "prep/after-pr-10/<receipt file>", "sha256": "<SHA-256 of the receipt file's bytes>"}`; the path must be relative, inside `docs/rewrite-v3`, no `..`, a regular file of at most 8 MiB.

The receipt file must be strict JSON with at least these members (extra
members such as `note` are allowed):

| Member | Required value |
|---|---|
| `accepted_spec_commit` | `"f5bef28a3094083fed67712c771504954d65d2de"` (equal to the manifest's) |
| `disposition` | `"approved"` |
| `reviewer_id` | non-empty string identifying this recheck's reviewer (a fresh Claude Fable 5.1 agent, launched 2026-09-23 under the owner account, not a fork of the author or the first reviewer's session), citing this report's path; it must differ from every string in `candidate_author_ids` and `subject_author_ids` |
| `independent_of_candidate_authorship` | JSON `true` |
| `subject_author_ids` | non-empty list of unique non-empty strings naming the subject's authors: the Claude Code implementing assistant, Claude Opus (prepared `setup.a2-proposed.json`, the plan, the probe app, the workflow, both bundles' capture scripts and the owner-decision transcription) and GitHub Actions run 35966206296 attempt 1 (produced `a2-android-evidence` and the APK at `c4d2059`) |
| `independent_of_subject_authorship` | JSON `true` |
| `setup_digest` | `"fef848f945da4608997dd4c3c81c470721dbdae98db3d338259be8bf7d742d1a"` (the A2 digest, no prefix, of the manifest at `6b73803` excluding `status` and `setup_review`) |

The receipt's `note` should state that this is stage A2 only, cite this
report, list N1–N5, and repeat that the A1 approval (digest
`95d454b7…530ae`, `reviews/2026-09-23-a1-setup-review.md`) stands and that
the reviewed bytes cannot prove the items in section 8.

File layout: the prep README's model is to fill `setup-review.pending.json`
with this receipt and make `setup.pending.json` the A2 record (its content
becoming the `setup.a2-proposed.json` bytes plus the two fields above);
in that layout `setup.a2-proposed.json` is retired or kept as a copy, and
README lines 211–213 are rewritten (N3). Keeping separate A1 and A2 files
instead is equally checkable (variant B above) but departs from the README.
Either way, both checkers must be rerun at A1, A2 and default on the final
bytes and the exit codes retained; approval is of the bytes reviewed here,
so the manifest's digest-bound fields must remain byte-identical.

## 8. What this review cannot prove

- That the iOS app on the iPhone was built from a clean checkout of
  `c4d2059` (N1); the build is consistent with it in every retained detail.
- That the phones are what their firmware reports, or that the M1's
  `sysctl` values are exact; nothing at A2 setup depends on more than the
  class they establish.
- That GitHub's log and artifact store were not altered; the review trusts
  GitHub as the executor of the workflow whose text is in the PR.
- That the composed excerpts are complete; every value in them was found in
  the retained raw file it cites.
- That the Hermes and SQLite builds inside the APK and the Pods are
  authentic upstream artifacts: versions and the pods' SHA-1 verification
  lines were read; Maven remains unlocked (F10).
- Installed RAM on either phone: a catalogue class figure everywhere, now
  labeled so, with OS-visible readings beside it (Ruling 3).
- That the old serial-bearing objects are unreachable from GitHub by SHA:
  they are still served (plan line 64–66); only the branch and anything
  merged from it are clean (OD3 chose (b), not (c)).
- Anything about timing, memory footprint, persistence, faults or load:
  R1-A2/A3 results, not setup.
- My own independence beyond what git history and section 2 show.

## 9. Disposition

| Subject | Disposition |
|---|---|
| A2 native/physical setup at `6b73803`, proposed A2 digest `fef848f9…2d1a` | **APPROVE WITH NOTES** (N1 wording fix and N3 sequencing in the receipt commit; N2, N4, N5 recorded) |
| A1 execution setup | Unchanged; approval of digest `95d454b7…530ae` stands |
| Android native evidence bundle (run 35966206296) | Genuine, byte-identical to the run's artifacts, complete for what it claims |
| Device and M1 evidence | Genuine, scripted, raw logs retained, redaction verified |
| History rewrite (OD3) | Done as decided: no serial-bearing object reachable from the head |
| Actual A2 authorization | Follows only from the receipt in section 7 bound to these exact bytes, `status: setup_reviewed`, and both `--stage A2` probes passing on the committed files. Readiness is not R1 acceptance. |

No owner decision is needed to close this recheck. OWNER DECISION NEEDED
only if the author wants to depart from the prep README's single-file layout
(N3, section 7); that is a process choice the owner may delegate to the
coordinator.

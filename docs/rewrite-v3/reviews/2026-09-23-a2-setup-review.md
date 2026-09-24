# Independent A2 setup review — 2026-09-23

**Disposition for the A2 native/physical setup: CHANGES REQUIRED.**
The evidence that exists is genuine: both bundles verify byte for byte, the
Android bundle is the one GitHub produced, the on-device Hermes and SQLite
identities agree across the APK, the Pods lock and both phones, and the
proposed manifest invents nothing. But the proposed record cannot become an
A2 record as written. Six fields still block both checkers (architecture on
both devices, Android class, RAM on both devices, iPhone SoC, `toolchain_lock`),
two of them need an owner decision, and one required device fact (an
OS-visible memory reading on the iPhone) has not been captured yet. Rulings
1–5 below say exactly what each field must become; a follow-up review of
the corrected bytes is required before `status: setup_reviewed`.

This review does **not** approve A2, does not fill
`setup-review.pending.json`, and does not disturb the approved A1 record:
`setup.pending.json` is byte-identical to `main` at `40ab191` and its A1
digest `95d454b7…530ae` still binds. It approves no R1 result, candidate,
runtime selection or production step.

## 1. What was reviewed

| Item | Value |
|---|---|
| Subject | PR #30, branch `prep/a2-freeze`, head `8e5656698582e697b7d0a1f8317054a42b1461b9` (confirmed with `gh pr view 30` at review start), base `main` `40ab191e8293cc9e742755bfce5a84199e6c56e3` |
| Worktree | `~/dev/lokacore-a2-review`, branch `review/v3-a2-setup` at the head above; the author's `~/dev/lokacore-a2` was not used |
| Accepted R0 contract | `f5bef28a3094083fed67712c771504954d65d2de` (`r0-acceptance.pending.json`, `disposition: accepted`) |
| Proposed manifest | `prep/after-pr-10/setup.a2-proposed.json`, status `a2_proposed_not_reviewed` |
| Plan | `prep/after-pr-10/a2-plan.md` |
| Device bundle | `prep/after-pr-10/a2-device-evidence/` — 13 files, every byte read, 11 indexed |
| Android bundle | `prep/after-pr-10/a2-android-evidence/` — 13 files, every byte read, 11 indexed; producer `.github/workflows/r1-android-native.yml`, run 35951344446 attempt 1, source `a2dbdf4f035c9743b6c120dc245d3261ec43885c`, image ubuntu24/20260920.314.1 |
| Probe app | `r1-spike/mobile/` (`App.tsx`, `app.json`, `package.json`, `package-lock.json`, `tsconfig.json`, `.gitignore`) |
| Checkers | `checks/readiness.py` and `spec_tools/lib/readiness.ex`, unchanged from `main` |
| Digests of the proposed manifest (for the record only, not approved) | A1 `1bc523140a461713373eacfa80811b22dd55d1e570945413a15c3cb9bafde796`, A2 `2703059604222f260d36bc353b1dd62279cff08ea2bc4a66754d386524214c20`; identical from both implementations |

Paths are relative to `docs/rewrite-v3` unless they start with `.github` or
`r1-spike`. Governing texts used: README §8 and §11, REVIEW-GUIDE,
`prep/after-pr-10/README.md`, 14 §PREP-02/R1-A2 rows, 15 READY-01/02,
`r1-work-package.md` §"Evidence bundle and review boundary",
`r1-acceptance-envelope.md` §4 rows 83–86 and lines 90–106, ADR-064,
`owner-instruction-2026-09-23.md`, and the A1 review as the model.

## 2. Provenance and authorship

| Artifact | Author of record | Notes |
|---|---|---|
| All 11 commits `0b06abe`…`8e56566` | `Raymond Luong` (owner account), every commit carrying `Co-Authored-By: Claude Opus 5.5` | Same lineage as the A1 setup preparer and the declared candidate author; permitted, and it means this review must be independent of that lineage |
| `a2-android-evidence/` | GitHub-hosted runner executing the workflow at `a2dbdf4` (event `pull_request`, checkout of the PR head, not the merge ref) | Retained by `420f919`. Independently confirmed: `gh run download 35951344446 -n a2-android-evidence` returns 13 files byte-identical to the retained ones; `-n app-release-apk` returns an APK with SHA-256 `f15267fc…6c1b`, 27 733 981 bytes, equal to `apk-facts.txt:1` and `pixel-3a-probe.txt:3`. The run log (1 103 lines, not expired) contains the identity lines verbatim |
| `a2-device-evidence/` | The implementing assistant on the owner's M1, with the owner physically handling the phones (owner report: Personal Team selection, cable/USB) | Only `m1-tools.txt` has its capture script retained (`m1-tools.sh`). The other files are assistant-composed excerpts of tool output (finding F7) |
| `a2-plan.md`, `setup.a2-proposed.json` | Implementing assistant | Self-described as "proposal by the candidate author … not a review" |
| Owner-reported facts | `owner-instruction-2026-09-23.md`; a2-plan.md:149 (Personal Team chosen in Xcode) | Nothing else in the record is attributed to the owner |
| This review | A fresh Claude Fable 5.1 agent on Claude Code, launched under the owner's account by a coordinator; not a fork of the author's session | I authored none of the reviewed files; `git log` shows no Fable trailer on any of them. I cannot authenticate my own identity beyond that statement |

The GitHub account name on a commit is not an authorship or approval
attestation. AGENTS.md's "push before ending" rule was set aside on the
coordinator's instruction: this report is the only file written, uncommitted.

## 3. Per-file findings

### 3.1 Device bundle (`a2-device-evidence/`)

| File | Bytes | Checked | Result |
|---|---|---|---|
| `SHA256SUMS` | 923 | 11 entries, relative names, no `..`, no absolute path, no symlink in the directory, does not list itself or the verify file | OK |
| `SHA256SUMS.verify.txt` | 241 | 11 × `: OK`; outside the index; my own `shasum -a 256 -c` reproduces it | OK |
| `m1-air-host.txt` | 245 | `hw.model MacBookAir10,1`, `Apple M1`, `hw.ncpu 8`, `perflevel0/1.physicalcpu 4/4`, `hw.memsize 17179869184` (exactly 16 GiB), macOS 26.6.2 (25G83), `arm64`. No capture command retained | OK (F7) |
| `m1-tools.sh` / `m1-tools.txt` | 806 / 849 | Script retained beside output, each command with its exit code: node v24.21.0, npm 11.19.0, `Erlang/OTP 28 [erts-16.3] … [jit]`, Elixir 1.20.4, `otp_release 28`, `OTP_VERSION=28.4`, tsc 6.0.3. `xcodebuild -version` exit 1 at 03:23Z (Command Line Tools active); `xcode-select -p` = CLT. This is the model the other device files should follow. Line 4 contains the owner's home path (F13) | OK |
| `m1-xcode.txt` | 888 | Composed: header lines, `xcodebuild -version` and `-showsdks` output, then a hand-written line 36 `iphoneos sdk: 27.0 build 24A430`. Taken at 05:42Z after Xcode was installed; `DEVELOPER_DIR` override recorded | OK as value, composed (F7) |
| `iphone-11-ideviceinfo.txt` | 205 | Nine selected keys: ProductType iPhone12,1, ModelNumber MH8Y3, RegionInfo LL/A, HardwareModel N104AP, CPUArchitecture arm64e, ProductVersion 26.6.2, BuildVersion 23G90. No UDID, ECID or serial. SHA-256 equals the manifest's `availability_record` | OK |
| `pixel-3a-adb.txt` | 623 | `adb devices -l` line with serial `[redacted]`, twelve `ro.*` properties, `MemTotal 3678544 kB`, `aarch64`. SHA-256 equals the manifest's `availability_record`. Property lines are `key: value`, not raw `getprop` format, so this is composed (F7) | OK |
| `pixel-3a-probe.txt` | 1 819 | APK SHA-256 equals the run's artifact; device fingerprint equals `pixel-3a-adb.txt:15`; `logcat` lines verbatim: Hermes `OSS Release Version 250829098.0.17`, `Build Release`, SQLite 3.50.3 with source id `2025-07-17 … 3ce993b8…`; `dumpsys meminfo Total RAM 3,678,544K` = MemTotal | OK |
| `boox-palma-adb.txt` | 799 | Supplementary only; serial `[redacted]`; not referenced by the manifest | OK |
| `iphone-11-Podfile.lock` | 69 255 | 2 258 lines; `hermes-engine (250829098.0.17)` with `:tag: hermes-v250829098.0.17`, `ExpoSQLite (57.0.3)`, `React-Core-prebuilt (0.86.3)`, `ReactNativeDependencies (0.86.3)`, `PODFILE CHECKSUM 78dd5900…`, `COCOAPODS: 1.17.0`; no absolute paths, no identifiers. SHA-256 equals `iphone-11-pods.txt:10` | OK |
| `iphone-11-pods.txt` | 2 122 | Composed summary: CocoaPods 1.17.0, Ruby 4.0.7, template tarball hash equal to the workflow's `TEMPLATE_SHA256`, lock `cmp`-equal claim (not independently replayable: no pod/npm log retained), `sqlite3.h` 3.50.3 with the same source id. Line 23 shows pod install fetched the **debug** Hermes tarball (F16). Trailing whitespace stripped after capture in `8e56566` (F8) | OK (F7, F8, F16) |
| `iphone-11-probe.txt` | 2 363 | Composed: build/install/launch commands with the UDID and Team ID as `[redacted]` in every committed revision (checked `5498797` and `8e56566`), executable and `main.jsbundle` SHA-256, `DTSDKBuild 24A430`, `DTXcodeBuild 27A266a`, `MinimumOSVersion 16.4`, `devicectl` excerpt (6 cores, arm64e, iPhone12,1, 26.6.2/23G90, Developer Mode on), then `idevicesyslog` lines verbatim with the same Hermes and SQLite identities as the Pixel. No raw xcodebuild, devicectl or syslog capture retained. Trailing whitespace stripped after capture in `8e56566` (F8) | OK (F7, F8) |

### 3.2 Android bundle (`a2-android-evidence/`)

| File | Bytes | Checked | Result |
|---|---|---|---|
| `SHA256SUMS` / `SHA256SUMS.verify.txt` | 918 / 236 | 11 entries, safe names, no cycle; verify output outside the index; reproduced locally | OK |
| `host.txt` | 560 | `source_commit=a2dbdf4…`, `event=pull_request`, `workflow_ref=…@refs/pull/30/merge`, run 35951344446 attempt 1, image ubuntu24/20260920.314.1, X64, kernel 6.17.0-1022-azure, `nproc=4`, `mem_total_kib=16373444`. All equal to the run log. The checkout was the PR head (`ref: github.event.pull_request.head.sha`), so `source_commit` is the built tree even though the workflow file came from the merge ref; the two are identical for the built paths (`git diff --stat a2dbdf4 HEAD -- r1-spike/mobile .github/workflows/r1-android-native.yml` is empty) | OK |
| `tools.txt` | 561 | node v24.21.0, npm 11.19.0, Temurin 17.0.20+8, build-tools 36.0.0, platforms/android-36 `Pkg.Revision=2`, NDK 27.1.12297006, Gradle distribution SHA pinned `b266d5ff…`. No `gradle_distribution_zip=` line: the zip was not on disk, so the pin was enforced by the wrapper, not re-hashed (as the plan says at line 63–66) | OK |
| `gradle-version.txt` | 1 048 | Gradle 9.3.1, revision `44f4e8d3…`, Launcher JVM 17.0.20+8, Kotlin 2.2.21 | OK |
| `gradle-wrapper.properties` | 339 | `distributionUrl` gradle-9.3.1-bin.zip, `distributionSha256Sum=b266d5ff…`; hash equals the `prebuild-tree.sha256` entry for the same path | OK |
| `native-config.txt` | 95 | `compileSdk=android-36`, `buildToolsVersion=36.0.0`, `ndkVersion=27.1.12297006`, `minSdk=24`, `targetSdk=36`; the five `A2 ` lines appear at `gradle-build.log:95-99` | OK (F17) |
| `prebuild-tree.sha256` | 4 093 | 36 generated files; `debug.keystore` hash `221e0a31…` equals `apk-facts.txt:3`; `gradle-wrapper.jar` hash `b3a875dd…` equals the workflow pin | OK |
| `prebuild.log` | 4 383 | `npm ci` 468 packages (uuid@7.0.3 warning, as in A1), template tarball `expo-template-bare-minimum@57.0.26` verified `OK` against `6b19d423…`, prebuild finished with `Updated package.json | no changes` | OK |
| `comparison.txt` | 61 | `package_json_and_lock_unchanged_by_install_and_prebuild=true`; I also `cmp`'d `r1-spike/mobile/package{,-lock}.json` against `dependency-evidence/` (identical; lock SHA-256 `18ac7c91…9644359`) | OK |
| `gradle-build.log` | 27 716 | `BUILD SUCCESSFUL in 5m 23s`; deprecation warnings only; no AGP version line anywhere in the bundle (F11) | OK |
| `release-runtime-classpath.txt` | 45 562 | `com.facebook.react:react-android -> 0.86.3`, `com.facebook.react:hermes-android -> com.facebook.hermes:hermes-android:250829098.0.17`, `expo-sqlite (57.0.3)`, `expo-modules-core (57.0.18)`. A record of resolution, not a lock (F10) | OK |
| `apk-facts.txt` | 3 561 | APK SHA-256 and size equal the downloaded artifact; `aapt2` package `com.lorecrafting.lokar1a2`, compileSdk 36, targetSdk 36, `native-code: 'arm64-v8a'`; apksigner shows the public debug certificate `fac61745…`; 15 `.so` hashes; SQLite 3.50.3 string and source id in `libexpo-sqlite.so` (I reproduced the version string from the downloaded APK) | OK |

### 3.3 Workflow, probe app, plan, manifest

| File | Checked | Result |
|---|---|---|
| `.github/workflows/r1-android-native.yml` | `permissions: contents: read`; four actions pinned to full SHAs; `persist-credentials: false`; exact Node/JDK versions; verifies `dependency-evidence/SHA256SUMS` and `cmp`s both lock files before and after prebuild; template tarball hash checked before use; Gradle distribution and wrapper jar pinned by hash; `sort -u`'d config lines from an init script; bundle indexed and self-verified; APK retained 30 days, bundle 90 | OK |
| `r1-spike/mobile/App.tsx` | Reads `HermesInternal.getRuntimeProperties()` and `SELECT sqlite_version(), sqlite_source_id()` from an in-memory DB, logs one `LOKA_A2_PROBE` line; nothing else | OK |
| `r1-spike/mobile/app.json` | Bundle id `com.lorecrafting.lokar1a2` both platforms | OK |
| `r1-spike/mobile/package.json` | Byte-identical to `dependency-evidence/package.json` (name still `loka-r1-a-dependency-evidence`, A1 note N5) | OK |
| `.gitattributes` | `-whitespace` for `a2-android-evidence/**` only; the device bundle is not exempt, which is why `8e56566` edited two evidence files (F8) | note |
| `a2-plan.md` | Claims checked line by line against the bundles; every value in the fourteen-field table (lines 27–42) is present in the cited file. Line 9–10 overstates "copied verbatim" (F7). Line 17–19 admits serials remain in earlier commits (F6). Line 19 says "The serials remain in this branch's earlier commits": true for four commits, and the repository is public | see findings |
| `setup.a2-proposed.json` | All eight input hashes, both record hashes and both `availability_record` file hashes recomputed from the working tree: all match. Every non-null toolchain string passes `exact_tool_version`. Server record complete. Nothing supplied is fabricated: every non-null device field traces to an inspected line | see rulings |

Redaction sweep: no UDID, ECID, serial or Team ID in any file at the head
commit; the iPhone files were redacted in every committed revision; the two
`adb` files were not (F6).

## 4. Rulings

### Ruling 1 — Architecture normalization: record `arm64`, keep the raw names in the bound record

**Ruling: option 1 of a2-plan.md:107-113 is correct. Record `"architecture": "arm64"` for both devices and leave both checkers unchanged.**

Reasoning. `arm64` in the checker (`readiness.py:105-106`, `readiness.ex:209`) and in the envelope (line 102, "Android arm64 initially") is the instruction-set class, AArch64. The raw values are finer names of the same class: `arm64e` (`iphone-11-ideviceinfo.txt:7`) is Apple's name for the CPU's ARMv8.3 subtype with pointer authentication; `arm64-v8a` (`pixel-3a-adb.txt:11`, `apk-facts.txt:6`) is Android's ABI name for AArch64. Neither is a different architecture, and the Android APK's only native slice is literally named `arm64-v8a`. Amending two checkers to accept per-platform spellings would be a reviewed tooling change that adds nothing the retained evidence does not already say.

Required retention, so that the digest binds the raw values and nobody later reads `arm64` as an inspected string:

- `setup.a2-proposed.json:18` → `"arm64"`, and append to the iOS `availability_record` (line 19): `; CPUArchitecture arm64e (ideviceinfo), recorded as class arm64`.
- `setup.a2-proposed.json:29` → `"arm64"`, and append to the Android `availability_record` (line 30): `; ro.product.cpu.abi arm64-v8a (adb), APK native-code arm64-v8a, recorded as class arm64`.
- Keep the raw values where they already are (both evidence files, a2-plan.md:93).

Info, not required: the iOS app's own slice architecture was not inspected (no `lipo -archs` retained). Retain it on the next iOS build.

### Ruling 2 — Pixel 3a for `galaxy-a14-4gb`: acceptable for R1-A2 as a labeled substitution, but only the owner can make it, and the ADR text needs four additions

**Ruling: the substitution is acceptable for the disposable R1 experiment, provided the owner decides it explicitly and the record labels it. It is not a reviewer's decision (OWNER DECISION OD1).**

Why it can be acceptable. The owner delegated minimum-hardware choice ("we will go with whatever minimum hardware you think is best", owner-instruction line 8) and the applied scope anticipated exactly this path: "Android remains an exactly identified A14/4 GB-class ordinary phone until the old Pixel is inventoried and any substitution explicitly documented" (owner-instruction lines 28–29; ADR-064 text at 16-decision-register.md:824; envelope line 95). The Pixel is now inventoried (SKU G020G, platform sdm710, Android 11 RQ2A.210505.002, MemTotal 3 678 544 kB). Its OS (11) meets the checker floor (10.0) and the planning matrix (Android 10+). The envelope's numerical rows are untouched.

Why the reviewer cannot decide it. The class label `galaxy-a14-4gb` is the only Android value both checkers accept (`readiness.py:103-104`, `readiness.ex:211-213`), and the envelope row 86 names a Galaxy A14. Recording a Pixel 3a under that label is a documented owner choice about what R1's Android minimum device is, not a normalization.

Setup encoding once the owner decides yes: `setup.a2-proposed.json:22` → `"galaxy-a14-4gb"`, and the Android `availability_record` must cite the retained owner decision (file path plus SHA-256, same style as the ideviceinfo citation), for example `; substitutes for the galaxy-a14-4gb class per <decision file> sha256 <hash> (ADR-070 proposed)`.

ADR-070 text (a2-plan.md:118-134): adequate in scope and limits, with four required additions:

1. Label the RAM: "installed RAM 4 GB is Google's published figure for the Pixel 3a, not tool-inspected; the inspected kernel-visible figure is 3 678 544 kB."
2. Label the SoC: `sdm710` is the inspected `ro.board.platform`; any marketed name (the reviewer's catalogue knowledge says Snapdragon 670, unverified here) must be marked catalogue or omitted.
3. State the setup encoding: class `galaxy-a14-4gb`, model/SKU/platform as inspected, `availability_record` citing the decision.
4. Name the decision-maker and the retained source of the decision (the owner's words, transcribed, as `owner-instruction-2026-09-23.md` does).

Where the ADR lives (OWNER DECISION OD1b). Document 16 is a normative file at the accepted commit `f5bef28`. Adding ADR-070 there is a contract amendment under the R0 record's `amendment_authority` ("reviewed changes that identify the prior accepted commit, affected decisions/fixtures and gates"), which is how ADR-069 was handled: a new accepted commit, then `r0_acceptance`, `oracle_review` and `setup_review` rebound to it (both checkers require every receipt's `accepted_spec_commit` to equal the manifest's). The alternative is to retain the owner's decision now as a prep file cited from the setup, with ADR-070 entering the register at the next contract amendment. Both are honest; the second is cheaper and is what ADR-064 already anticipates. The reviewer does not choose.

### Ruling 3 — RAM: `installed_ram_gb: 4` can only be a labeled catalogue figure; Android has its consistency evidence, iOS does not yet

**Ruling: what is retained is sufficient for the Pixel 3a and insufficient for the iPhone 11. Both fields may be recorded as `4` only with source labels, and only after an OS-visible memory reading exists for the iPhone.**

The facts, kept separate:

| Device | Tool-inspected | Owner-reported | Catalogue | In the record |
|---|---|---|---|---|
| Pixel 3a | `MemTotal 3678544 kB` (3.51 GiB) from `adb shell` (`pixel-3a-adb.txt:18`) and `dumpsys meminfo Total RAM 3,678,544K` (`pixel-3a-probe.txt:27`) | nothing | 4 GB (Google's product specification; not retained in the repo) | null |
| iPhone 11 | nothing: `ideviceinfo` and `devicectl device info details` report no memory (`iphone-11-probe.txt:22`) | "iphone 11 physical" (owner-instruction line 8) | 4 GB (third-party teardowns; Apple publishes no RAM figure; the README's Apple reference confirms only the A13 chip) | null |

Neither tool reports installed RAM, and neither ever will: an OS reports the memory it can see, which is always below the installed size. So `installed_ram_gb` is, for any phone, a class figure whose source is a catalogue. The checker's `== 4` (`readiness.py:101-102`, `readiness.ex:208`) is a class check, and the envelope's iPhone 11 row says "planned 4 GB class" and "actual RAM … still need verification before A2" (line 85). Verification therefore means: an inspected OS-visible figure that is consistent with the 4 GB class and inconsistent with the neighbouring classes (3 GB SE 2, 6 GB). For the Pixel, 3.51 GiB does that. For the iPhone there is no reading at all, and the envelope explicitly separates the iPhone 11 substitution from measurement (REVIEW-GUIDE last paragraph).

Required:

- iPhone: retain an OS-visible memory reading from the device itself. The plan's route (a2-plan.md:96-103, a local Expo module returning `ProcessInfo.processInfo.physicalMemory`, printed on the `LOKA_A2_PROBE` line, captured by `idevicesyslog`) is the smallest thing that works, because no retained tool reports it and no JS API exposes it; `expo-device` would change the frozen lock and is not an option. Any other retained raw reading is equally acceptable. Note the consequence: the app changes, so the iOS executable and bundle hashes in `iphone-11-probe.txt` are superseded by the new run's, and the CI workflow will rebuild Android (its `paths` filter includes `r1-spike/mobile/**`), producing a new APK whose bytes differ from `f15267fc…`. Either re-sideload and re-probe the Pixel on the new APK, or keep the Android evidence at `a2dbdf4` and state in the plan that the Android probe ran the pre-module app (OWNER DECISION OD2).
- Both: record `"installed_ram_gb": 4` and append to each `availability_record` the source and the inspected figure, for example `; installed RAM 4 GB is the class figure (Google product specification, not inspected); kernel MemTotal 3678544 kB` and, for iOS, `; installed RAM 4 GB is the class figure (not published by Apple; not inspected); physicalMemory <bytes> read on device`.
- Nothing in any later measurement may treat 4 GB as available memory.

### Ruling 4 — The M1 MacBook Air is acceptable as the A2 common host

**Ruling: acceptable, with the notes below.**

Envelope row 83 requires "Apple Silicon M1-or-later, 16 GB; exact model, OS, runtime, cores and load recorded; common server tests use the same host". Inspected: `MacBookAir10,1`, `Apple M1`, 8 cores (4P+4E), `hw.memsize` exactly 16 GiB, macOS 26.6.2 (25G83), `arm64` (`m1-air-host.txt`); Node 24.21.0, npm 11.19.0, Elixir 1.20.4 on OTP 28.4 (`erts-16.3`, `[jit]`), tsc 6.0.3 with the invoking script and exit codes (`m1-tools.sh`, `m1-tools.txt`); Xcode 27.0 (27A266a) with iOS SDK 27.0 (24A430) (`m1-xcode.txt`). The manifest's `server` block (`setup.a2-proposed.json:33-38`) states exactly those values and passes the A2 RAM floor. The M1's Elixir/OTP identities equal the A1 runner's, which is what the A1 review's note N3 asked to be recorded properly. "Load" is a per-run condition that belongs in result manifests, not in setup.

Notes (not blocking): `m1-air-host.txt` has no retained capture script (F7); the system developer directory is still Command Line Tools (`m1-tools.txt:24-25`), so every M1 replay must set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (F13); no server-side SQLite engine is recorded and the setup schema has no field for one (F12). Confirmation of the host is listed as the owner's item 5 (a2-plan.md:158-159); the reviewer finds the evidence adequate (OD4).

### Ruling 5 — `toolchain_lock`: it may point at one combined A2 index once the bundle is complete; it must stay null in this PR as submitted

**Ruling: yes, a combined index is the right target, and it is what the README asks for ("one retained checksum/index manifest"). It cannot be filled yet because the bundle is not complete (iPhone memory reading, F3) and the index does not exist.**

What the combined index must be:

- One file, for example `prep/after-pr-10/a2-toolchain-lock.SHA256SUMS`, whose documented root is `prep/after-pr-10/`. Every entry is a path relative to that root, inside it, no `..`, no absolute path, no symlink; the index does not list itself; its verification output (`shasum -a 256 -c` from the root) is retained beside it in a file the index does not list. Both readiness implementations only check that the index file's own hash matches `toolchain_lock.sha256` (`readiness.py:82-95`); member coverage and bytes are the reviewer's job, which is why this list is explicit.
- Members, by bundle, all already retained except where marked:
  - `a1-host-evidence/`: `package.json`, `package-lock.json`, `host.txt`, `tools.txt`, `replay.log`, `comparison.txt` (the JS lock, its replay and the A1 host; the A1 record keeps pointing at that bundle's own `SHA256SUMS`, which is unaffected).
  - `a2-android-evidence/`: all eleven indexed files (native configuration, Gradle wrapper pin, prebuild tree, resolved classpath, build log, APK facts, host and tools).
  - `a2-device-evidence/`: `m1-air-host.txt`, `m1-tools.sh`, `m1-tools.txt`, `m1-xcode.txt`, `iphone-11-ideviceinfo.txt`, `iphone-11-Podfile.lock`, `iphone-11-pods.txt`, `iphone-11-probe.txt`, `pixel-3a-adb.txt`, `pixel-3a-probe.txt`; **plus, not yet existing:** the iPhone memory reading (Ruling 3) and, if the app is rebuilt, the superseding probe files; and the capture scripts or raw logs required by F7. `boox-palma-adb.txt` may be included or left out; it is supplementary either way.
  - Existing per-bundle `SHA256SUMS` and `SHA256SUMS.verify.txt` files may be listed as ordinary members (no cycle arises, since the combined index lists them and not itself), or left out; listing them is simpler.
- Hashing: `toolchain_lock.sha256` = SHA-256 of the combined index file's bytes; every member hash inside the index is SHA-256 of that member's bytes; regenerate the index whenever a member changes and re-verify. A changed member is a changed setup and needs renewed review.

What the index does not have to contain: the Maven artifact bytes (F10; the resolved classpath is the record), the Hermes release tarball (F16; the executed identity is in both probes), or the APK itself (its hash is in `apk-facts.txt` and the artifact is retained by GitHub for 30 days; the reviewer downloaded it).

## 5. Findings

Severity: **blocking** = the A2 record cannot be approved without it;
**medium** = must change in this PR; **low** = fix when the record is filled;
**info** = recorded so nobody rediscovers it.

**F1 — blocking.** `setup.a2-proposed.json:18` (`"arm64e"`) and `:29` (`"arm64-v8a"`). Change both to `"arm64"` and append the raw names to lines 19 and 30 as in Ruling 1.

**F2 — blocking, OWNER DECISION OD1.** `setup.a2-proposed.json:22` (`null`). Must be `"galaxy-a14-4gb"` with the owner's substitution decision retained and cited from line 30, as in Ruling 2. a2-plan.md:118-134 (ADR-070 text) needs the four additions in Ruling 2.

**F3 — blocking, OWNER DECISION OD2.** `setup.a2-proposed.json:15` and `:26` (`null`). Record `4` on both only with labeled sources, and only after an OS-visible memory reading is retained for the iPhone 11, as in Ruling 3. The Pixel's reading is already retained (`pixel-3a-adb.txt:18`, `pixel-3a-probe.txt:27-28`).

**F4 — blocking.** `setup.a2-proposed.json:14` (`"soc": null`). Not listed among the plan's open decisions, but both checkers require a non-empty string for every A2 device field (`readiness.py:99-113` falls through to `nonempty`; the dry run in §7 fails here first even after F1–F3). `ideviceinfo` cannot report it. Record a labeled catalogue fact tied to the inspected ProductType: `"A13 Bionic (Apple product page for iPhone12,1, cited in prep/after-pr-10/README.md; not tool-inspected)"`. The `devicectl` excerpt's 6 cores (`iphone-11-probe.txt:14`) is consistent with, not proof of, that chip.

**F5 — blocking.** `setup.a2-proposed.json:55-58` (`toolchain_lock` null). Fill per Ruling 5 once F3 and F7 are done; until then it must stay null and the record stays unreviewable.

**F6 — medium, OWNER DECISION OD3.** Unredacted `adb` serial numbers for the Pixel 3a and the BOOX are in four commits of this public repository: `25d0052`, `a2dbdf4`, `420f919`, `478af0d` (`a2-device-evidence/pixel-3a-adb.txt:4`, `boox-palma-adb.txt:4`, redacted from `af699df` on). a2-plan.md:17-19 discloses this. The owner instruction (line 37) excludes serials from public evidence; the head commit complies, the branch history does not, and merging as-is carries the blobs into `main`. The iPhone UDID and Team ID were never committed unredacted (verified at `5498797` and `8e56566`). Options for the owner: (a) accept the exposure as already public via the PR refs and merge; (b) rewrite the branch so no serial-bearing blob reaches `main` (the Android evidence cites `a2dbdf4` in `host.txt:2`; that commit stays reachable through `refs/pull/30/head` and its built tree equals the head's for the built paths, so the citation stays true, but the plan must then say so); (c) additionally ask GitHub support to purge the unreachable objects. The reviewer recommends (b) plus a sentence in the plan; it does not decide.

**F7 — medium.** a2-plan.md:9-10 says the device bundle is "raw `sysctl`/`sw_vers`, `ideviceinfo`, `adb` output copied verbatim". Only `m1-tools.txt` has its script beside it. `m1-air-host.txt`, `m1-xcode.txt` (line 36 is hand-written), `pixel-3a-adb.txt` and `boox-palma-adb.txt` (property lines reformatted from `getprop`), `iphone-11-pods.txt` and `iphone-11-probe.txt` (excerpts of build, pod, devicectl and syslog output, with hand-written summary lines) are assistant-composed. The values are not in doubt (each traces to a tool and, for iOS, to the retained `Podfile.lock` and syslog lines), but provenance must be labeled truthfully. Required: (1) reword a2-plan.md:9-10 to say which files are verbatim tool output and which are composed excerpts; (2) for each composed file retain the commands that produced its lines, in the style of `m1-tools.sh` (a `capture.sh` per file is enough), and for the iOS build retain the redacted raw `xcodebuild … build` log, the `pod install` log and the `devicectl` output alongside the excerpt. (3) Do this before the combined index is built (Ruling 5), so the index covers them.

**F8 — low.** Commit `8e56566` edited two retained evidence files after capture (`iphone-11-pods.txt:3`, `iphone-11-probe.txt:3`, trailing whitespace) and re-indexed them; only the commit message says so, the plan's "nothing else in those files changed" (line 18) refers to the adb files. Extend `.gitattributes` to `docs/rewrite-v3/prep/after-pr-10/a2-device-evidence/** -whitespace` so retained bytes are never corrected again, and add one line to a2-plan.md disclosing the edit.

**F9 — low.** a2-plan.md:118-134 (ADR-070). The four additions in Ruling 2. Also the plan's sentence "the owner was told not to update its OS" (line 129) is an instruction, not an observation; keep it but say who gave it.

**F10 — info.** a2-plan.md:71-75. Maven artifacts (AGP, React Native, Expo Gradle plugins) are resolved at build time and only recorded, not locked. For A2 setup the retained resolved classpath is an adequate record, on the same standard the A1 review applied to the un-checksummed toolcache (A1 note N4); result manifests re-record build hashes. Gradle dependency verification (`verification-metadata.xml`) is a worthwhile follow-up, not an A2 requirement.

**F11 — info.** No file in the Android bundle records the Android Gradle Plugin version (the runtime classpath does not include buildscript dependencies; the plan's "AGP 8.12.0" at prep README is PR #13 packaged metadata). On the next rerun add `./gradlew :app:buildEnvironment` output to the bundle. Not a setup field.

**F12 — info.** `toolchain.sqlite` (`setup.a2-proposed.json:47`) is the phone engine (APK library strings, iOS `sqlite3.h`, both on-device probes). The Elixir server side's SQLite engine does not exist yet and the schema has no field for it; a2-plan.md should say so in one sentence so 3.50.3 is not read as a server fact. It is an R1-A2 result item.

**F13 — info.** `m1-tools.sh:4` contains the owner's home path (same name as the git identity; not a secret). `m1-tools.txt:21-25`: `xcodebuild` failed at 03:23Z because Command Line Tools were active; `m1-xcode.txt` at 05:42Z used `DEVELOPER_DIR`. `xcode-select -p` still points at CLT, so every M1 replay must set `DEVELOPER_DIR`; say so in the plan's iOS section.

**F14 — info.** The PR description's line "Note: the adb files include device serial numbers" is stale since `af699df`; the iOS paragraph is current.

**F15 — info.** Dates: evidence timestamps and a2-plan.md's title are UTC (2026-09-24); commits are `-10:00` (2026-09-23 evening). The Pixel `logcat` (`09-23 19:56`) and APK `lastUpdateTime` are device-local and agree with the 05:56Z probe. Nothing is inconsistent.

**F16 — info.** `iphone-11-pods.txt:23`: `pod install` fetched `hermes-ios-…-debug.tar.gz`; React Native swaps in the release artifact at build time, and the executed identity on the phone says `Build: Release` (`iphone-11-probe.txt:31`). The release tarball fetch is not retained. On the next build retain that build-phase log line and `lipo -archs` of the app executable.

**F17 — info.** `native-config.txt:3` `minSdk=24` is the Expo template default; the planning matrix says Android 10+ and the checker enforces the device OS floor (Android 11 here), so there is no setup conflict. The store-facing minimum is a release decision, not A2.

## 6. Owner decisions needed

- **OD1 — Android substitution.** OWNER DECISION NEEDED: does the Pixel 3a (G020G, sdm710, Android 11 RQ2A.210505.002, kernel-visible 3.51 GiB) stand in for the `galaxy-a14-4gb` class for the disposable R1 experiment only, under the limits in ADR-070's text? Options: yes (record per Ruling 2) / no (obtain an identified A14-class 4 GB device before A2). **OD1b:** where the decision lives: (A) an owner decision file in `prep/after-pr-10/` cited from the setup now, with ADR-070 entering document 16 at the next contract amendment; or (B) amend document 16 now, accept a new R0 commit, and rebind the R0, oracle and setup-review receipts to it.
- **OD2 — iPhone memory reading.** OWNER DECISION NEEDED: add the local memory module and re-run the probe on the iPhone (required by Ruling 3), and then either (A) also re-sideload and re-probe the Pixel on the rebuilt APK so both probes come from one app revision, or (B) keep the Android evidence at `a2dbdf4` and state in the plan that the Android probe ran the pre-module app. The reviewer prefers (A) for one app hash, but (B) is honest.
- **OD3 — Serial numbers in public history.** OWNER DECISION NEEDED: (a) merge as is, (b) rewrite the branch before merge, (c) rewrite and request a purge from GitHub support. See F6.
- **OD4 — Common host.** OWNER DECISION NEEDED: confirm the M1 MacBook Air (`MacBookAir10,1`, 16 GiB, macOS 26.6.2) as the A2 common host. The reviewer finds the evidence adequate (Ruling 4).

No decision is needed for Ruling 1 (architecture) or F4 (iPhone SoC); those are reviewer rulings with exact text.

## 7. Commands and exit codes

All run locally in the review worktree at `8e56566` on macOS (Darwin 25.6.0),
Python 3, Elixir 1.20.4 / OTP 28.4 / Node 24.21.0 via
`mise exec elixir@1.20.4 erlang@28.4 node@24.21.0 --`. Each readiness probe
was its own process.

| Command | Result | Exit |
|---|---|---|
| `gh pr view 30` head check | `8e56566…` (unchanged) | 0 |
| `shasum -a 256 -c SHA256SUMS` in `a2-device-evidence/` | 11 × OK | 0 |
| `shasum -a 256 -c SHA256SUMS` in `a2-android-evidence/` | 11 × OK | 0 |
| `gh run download 35951344446 -n a2-android-evidence` + `cmp` × 13 | all identical | 0 |
| `gh run download 35951344446 -n app-release-apk`; `shasum` | `f15267fc…6c1b`, 27 733 981 bytes | 0 |
| `gh run view 35951344446 --log` | 1 103 lines, available; identity lines present | 0 |
| `gh run view 35951344446 --json …` | `pull_request`, head `a2dbdf4`, attempt 1, `success`, created 2026-09-24T03:24:55Z | 0 |
| `git merge-base --is-ancestor a2dbdf4 HEAD` | yes | 0 |
| `git diff --quiet a2dbdf4 HEAD -- r1-spike/mobile .github/workflows/r1-android-native.yml` | identical | 0 |
| `git diff --quiet 40ab191 HEAD -- setup.pending.json a1-host-evidence setup-review.pending.json oracle-review.pending.json r0-acceptance.pending.json conformance r1-acceptance-envelope.md checks spec_tools 16-decision-register.md` | identical | 0 |
| `cmp` probe `package.json` / `package-lock.json` vs `dependency-evidence/` | identical | 0 |
| recompute 8 inputs + r0 + oracle + 2 `availability_record` hashes (proposed); 8 + r0 + oracle + setup-review + lock (pending) | all match | 0 |
| `python3 -m unittest discover -s checks -p 'test_*.py'` | OK | 0 |
| `checks/release_scope.py --check`, `checks/packet_navigation.py --check`, `checks/readiness.py --check-template` | PASS | 0 |
| `git diff --check 40ab191 HEAD` | clean | 0 |
| `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix loka.readiness --check-template` | clean / clean / PASS | 0 |
| `mix test` / `mix test --include comparison` | 25 passed, 3 excluded / 28 passed | 0 |
| `readiness.py --require-ready setup.a2-proposed.json --stage A1` | NOT READY: preparation pending or unsupported candidate work package | 1 |
| `readiness.py --require-ready setup.a2-proposed.json --stage A2` | NOT READY: preparation pending … | 1 |
| `readiness.py --require-ready setup.a2-proposed.json` (default) | NOT READY: preparation pending … | 1 |
| `readiness.py --require-ready setup.pending.json --stage A1` | A1 ONLY: no native/physical qualification, A2 authorization or runtime selection | 0 |
| `readiness.py --require-ready setup.pending.json --stage A2` | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `readiness.py --require-ready setup.pending.json` (default) | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `readiness.py --require-ready template --stage A1` / `--stage A2` | NOT READY: preparation pending … | 1 / 1 |
| `mix loka.readiness --require-ready setup.a2-proposed.json --stage A1` | NOT READY: preparation pending … | 1 |
| `mix loka.readiness --require-ready setup.a2-proposed.json --stage A2` | NOT READY: preparation pending … | 1 |
| `mix loka.readiness --require-ready setup.a2-proposed.json` (default) | NOT READY: preparation pending … | 1 |
| `mix loka.readiness --require-ready setup.pending.json --stage A1` | A1 ONLY: … | 0 |
| `mix loka.readiness --require-ready setup.pending.json --stage A2` | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `mix loka.readiness --require-ready setup.pending.json` (default) | NOT READY: missing/invalid device detail: ios/sku | 1 |
| `mix loka.readiness --require-ready template --stage A1` / `--stage A2` | NOT READY: preparation pending … | 1 / 1 |
| `setup_digest` of the proposed manifest, Python and Elixir | A1 `1bc52314…de796`, A2 `27030596…14c20`, equal in both | 0 |

These match the PR description's table. The proposed record is rejected on
its `status` before any field is examined, so the probes do not yet
exercise the device rules. A scratchpad dry run (a copy with
`status: setup_reviewed`, never written to the repo) exercised them: the
first rejection is `ios/soc` (F4); with F1–F4 applied the next is the null
`toolchain_lock` (F5); after that the null `setup_review` receipt. Every
non-null toolchain string passes `exact_tool_version` in isolation.

## 8. What this review cannot prove

- That the phones are what their firmware reports, or that the M1's
  `sysctl` values are exact. Nothing at A2 setup depends on more than the
  class they establish.
- That GitHub's log and artifact store were not altered. The review trusts
  GitHub as the executor of a workflow whose text is in the PR.
- That the composed iOS excerpts are complete transcriptions. The values
  they carry are corroborated by the retained `Podfile.lock` and the
  verbatim syslog lines, but the raw logs are not retained (F7).
- That the Hermes and SQLite builds inside the APK and the Pods are
  authentic upstream artifacts. Their versions were read; their download
  checksums were not (Maven is unlocked, F10).
- Installed RAM on either phone. It is a catalogue figure everywhere
  (Ruling 3).
- Anything about timing, memory footprint, persistence, faults or load.
  Those are R1-A2/A3 results, not setup.
- My own independence beyond what git history shows. I did not author or
  edit any reviewed file; the owner has previously confirmed that a fresh
  Fable agent counts as independent.

## 9. Disposition

| Subject | Disposition |
|---|---|
| A2 native/physical setup at `8e56566`, proposed digest `27030596…14c20` | **CHANGES REQUIRED** (F1–F7; OD1–OD4) |
| A1 execution setup | Unchanged; approval of digest `95d454b7…530ae` stands |
| Android native evidence bundle (run 35951344446) | Genuine, complete for what it claims, reusable as is unless OD2(A) rebuilds the app |
| Device and M1 evidence | Genuine values; provenance labeling and capture records required (F7, F8) |
| Actual A2 authorization | Not granted. It follows only from a corrected manifest, a follow-up independent review of those exact bytes, a truthful filled receipt bound to the new A2 digest (no prefix), `status: setup_reviewed`, and both `--stage A2` probes passing on those bytes |

Smallest remaining list, in order: (1) owner answers OD1–OD4; (2) capture
the iPhone memory reading and the F7 capture records/raw logs;
(3) apply F1–F4 and F8–F9 to `setup.a2-proposed.json` and `a2-plan.md`;
(4) build the combined index and fill `toolchain_lock` (F5); (5) rerun both
checkers at A1, A2 and default and retain the exit codes; (6) request the
follow-up review of the corrected bytes, which may be bounded to the changed
fields, the new evidence files and the combined index; (7) only then fill
`setup-review.pending.json` from that follow-up report.

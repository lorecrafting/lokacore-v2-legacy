# PREP-02 A2 preparation plan — 2026-09-24

**Status: A2 setup approved with notes** by an independent recheck
([reviews/2026-09-23-a2-setup-recheck.md](../../reviews/2026-09-23-a2-setup-recheck.md),
head `6b73803`, A2 digest `fef848f9…2d1a`). The proposal text below is by the
candidate author (Claude Code implementing assistant, Claude Opus). The
reviewed `setup.a2-proposed.json` bytes, plus `status: setup_reviewed` and the
receipt pointer, are now [setup.pending.json](setup.pending.json), and the A2
receipt is [setup-review.pending.json](setup-review.pending.json) (recheck N3).
Both checkers pass `--stage A2` and the default and reject A1 by design. The A1
approval (digest `95d454b7…530ae`) stands as a record at main `40ab191`.
Mentions of `setup.a2-proposed.json` below refer to those reviewed bytes.

This revision applies the independent A2 setup review
([reviews/2026-09-23-a2-setup-review.md](../../reviews/2026-09-23-a2-setup-review.md),
CHANGES REQUIRED at reviewed head `8e56566`) and the owner's answers to its
OD1–OD4, retained in
[owner-decision-a2-2026-09-23.md](owner-decision-a2-2026-09-23.md) (relayed by
the coordinating assistant). A follow-up independent review of these bytes is
still required.

Evidence: [device and M1 host](a2-device-evidence/) and
[Android native build](a2-android-evidence/) from
`.github/workflows/r1-android-native.yml`, run 35966206296 attempt 1, source
`c4d2059ad29fe38990bc78a5a3cc5bb5834cf1f0`, image ubuntu24/20260920.314.1.
Each bundle has a `SHA256SUMS` index with its verify output beside it, outside
the index. The combined A2 index
[a2-toolchain-lock.SHA256SUMS](a2-toolchain-lock.SHA256SUMS) covers them (see
`toolchain_lock` below).

**Which device files are raw and which are composed (review F7).** Every device
file except `boox-palma-adb.txt` is written by the capture script beside it,
which is retained and indexed. The `*.txt` files named after a script print
each command (`$ …`) beside its output and exit code, so each value is
verbatim tool output under a composed layout. These are `m1-air-host`,
`m1-tools`, `m1-xcode`, `iphone-11-ideviceinfo`, `pixel-3a-adb` and the
command sections of `pixel-3a-probe`. Two files are **excerpts composed by
their script**: `iphone-11-pods.txt` (from `iphone-11-build.sh`) and
`iphone-11-probe.txt` (from `iphone-11-probe.sh`), which select lines from the
raw files. The **raw tool output** is `iphone-11-pod-install.log`,
`iphone-11-xcodebuild.log`, `iphone-11-devicectl.txt`,
`iphone-11-syslog.txt`, `pixel-3a-logcat.txt` and `iphone-11-Podfile.lock`
(a copy of the generated lock). It is redacted as listed below and otherwise
unchanged. `boox-palma-adb.txt` is a composed excerpt from 2026-09-24T03:15Z whose
commands were not retained. It is supplementary only: not a qualification device,
not in the setup record and not in the combined index. The previous versions of
the other files, captured 03:08–06:13Z without scripts (except `m1-tools`), were
replaced by the scripted re-captures of 06:45–07:04Z. The values are unchanged
except the app hashes and the new memory readings.

**Redaction.** Retained files replace these with `[redacted]`: `adb` serials,
iPhone UDID, ECID, serial number, device name, CoreDevice identifier, CoreDevice
tunnel IP, personal team ID, signing identity name, certificate SHA-1 and
provisioning profile UUID. The home directory is shown as `~`. Each script's
`redact()` shows exactly what it replaces. `m1-tools.sh:4` still contains the home
path (review F13; not a secret).

**History rewrite (owner decision OD3).** The `adb` serials of the Pixel 3a and
the BOOX were in four earlier commits of this branch. `prep/a2-freeze` was
rewritten with `git filter-repo --replace-text` over `40ab191..prep/a2-freeze`
and force-pushed. Every version of `pixel-3a-adb.txt` and `boox-palma-adb.txt`
now carries `[redacted]`. The two whole-file hashes of the serial-bearing
versions in the older `SHA256SUMS` and setup record were mapped to the redacted
files' hashes, so each rewritten commit's index still verifies. The head tree
was unchanged (`git diff` empty). Messages, authors and dates are identical. Old
to new: `8e56566`→`b337467`, `5498797`→`fa58bef`, `9d052a9`→`d5b392e`,
`e794b91`→`d1cd2bb`, `3583bd3`→`cd4b30b`, `af699df`→`c97c0d5`,
`478af0d`→`394915b`, `420f919`→`b488dff`, `a2dbdf4`→`056ca03`,
`25d0052`→`2641113`, `0b06abe` unchanged. The original commits are no longer on
any branch. GitHub may still serve them by hash (the review's option (c), a
purge request, was not chosen). Run 35951344446's `host.txt` cited
`a2dbdf4`. That bundle is superseded by run 35966206296, whose source commit
is on the branch.

**Whitespace edit disclosure (review F8).** Commit `8e56566` (now `b337467`)
stripped trailing whitespace from line 3 of `iphone-11-pods.txt` and
`iphone-11-probe.txt` after capture and re-indexed them. Both files have since
been replaced by scripted re-captures. `.gitattributes` now exempts
`a2-device-evidence/**` from whitespace correction as well as
`a2-android-evidence/**`, so retained bytes are never corrected again.

## Fourteen toolchain fields

Provenance: **inspected** = raw command output retained; **lock** = the
retained dependency-evidence manifest/lock bytes (installed unchanged, not
re-resolved); **null** = not observed.

| Field | Value | Provenance | Observed by | Host | Status |
|---|---|---|---|---|---|
| expo | 57.0.24 | lock; installed in A1 run 35901131399 and Android run 35966206296 | `npm ci` of the retained lock; `npm ls --all` (A1 `replay.log`) | Actions | proposed |
| react_native | 0.86.3 | lock, as above | as above | Actions | proposed |
| hermes | 250829098.0.17 | inspected (Android) | `./gradlew :app:dependencies --configuration releaseRuntimeClasspath` → `com.facebook.hermes:hermes-android:250829098.0.17` (`apk-facts.txt`) | Actions; M1 (iOS) | proposed; iOS pod `hermes-engine (250829098.0.17)` (`iphone-11-pods.txt`); on-device 250829098.0.17 Release on both phones (`pixel-3a-probe.txt`, `iphone-11-probe.txt`) |
| typescript | 6.0.3 | inspected | `node node_modules/typescript/bin/tsc --version` | Actions (A1) and M1 (`m1-tools.txt`) | proposed |
| node | 24.21.0 | inspected | `node -v` | Actions and M1 | proposed |
| elixir | 1.20.4 | inspected | `elixir --version` | Actions (A1) and M1 via mise | proposed |
| otp | 28.4 | inspected | `OTP_VERSION` file (Actions); `erl -eval` reading it (M1) | Actions and M1 | proposed |
| sqlite | 3.50.3 | inspected (Android APK) | `strings` on `lib/arm64-v8a/libexpo-sqlite.so`: version string and source id `2025-07-17 13:25:10 3ce993b8…` | Actions; M1 (iOS) | proposed; on-device `sqlite_version()` 3.50.3, same source id, on the Pixel 3a and iPhone 11; iOS Pods `sqlite3.h` 3.50.3 (`iphone-11-pods.txt`) |
| sqlite_binding | 57.0.3 | lock | as expo | Actions | proposed |
| xcode | 27.0+27A266a | inspected | `xcodebuild -version` with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (`m1-xcode.sh` / `.txt`) | M1 | observed 2026-09-24 |
| ios_sdk | 27.0+24A430 | inspected | `xcodebuild -showsdks`; `xcrun --sdk iphoneos --show-sdk-version` / `--show-sdk-build-version` (`m1-xcode.txt`) | M1 | observed 2026-09-24 |
| android_sdk | 36 | inspected | Gradle init report `compileSdk=android-36`, `targetSdk=36`; platform `Pkg.Revision=2`; `aapt2 dump badging` | Actions | proposed |
| gradle | 9.3.1 | inspected | `./gradlew --version` | Actions | proposed |
| jdk | 17.0.20+8 | inspected | `java -version` (Temurin, pinned by `actions/setup-java`) | Actions | proposed |

Also recorded, not setup fields: minSdk 24, build-tools 36.0.0, NDK
27.1.12297006 (`source.properties`), ABI `arm64-v8a` only.

The Hermes value is the Hermes V1 artifact actually resolved for the release
build, not the `0.17.0` in `sdks/.hermesversion`; that packaged-metadata
ambiguity from PR #13 is resolved for Android. The retained SQLite value is
the default `vendor/sqlite3` build, not SQLCipher 3.49.1.

`toolchain.sqlite` is the **phone** engine: the APK library strings, iOS
`sqlite3.h` and both on-device probes. The Elixir server's SQLite engine does not
exist yet, and the setup schema has no field for it. It is an R1-A2 result item,
not a server fact (review F12).

## Native configuration and lock plan

- **App config.** `r1-spike/mobile/` holds `app.json`, a one-screen probe
  (`App.tsx`: Hermes runtime properties, `SELECT sqlite_version()` and the
  OS-visible memory reading), the local Expo module
  `modules/loka-memory/` (autolinked from the default `modules/` directory,
  no npm dependency; iOS `ProcessInfo.processInfo.physicalMemory`, Android
  `ActivityManager.MemoryInfo.totalMem`, returned in bytes with the API name),
  and `package.json`/`package-lock.json` byte-identical to
  `dependency-evidence/`. CI `cmp`s both before install and after prebuild. The
  `.gitignore` prebuild patterns are anchored to the app root (`/ios/`,
  `/android/`) so the module's own native sources are tracked.
- **Prebuild output.** Continuous native generation: `android/` and `ios/` are
  gitignored and regenerated. The template is pinned to the tarball
  `expo-template-bare-minimum@57.0.26` (sha256 `6b19d423…`), checked before use.
  The generated tree's hashes are retained (`prebuild-tree.sha256`). A changed
  template, app config or plugin is a native configuration change.
- **Gradle wrapper.** Gradle 9.3.1. CI appends `distributionSha256Sum=b266d5ff…`
  (the services.gradle.org published checksum), so Gradle refuses a different
  distribution, and checks `gradle-wrapper.jar` against `b3a875dd…`. The zip is
  not kept on disk after extraction, so the checksum is enforced, not re-hashed.
- **JDK.** Temurin 17.0.20+8 via `actions/setup-java` at a pinned commit.
- **Signing.** The release variant is signed with the template's public
  `debug.keystore` (certificate SHA-256 `fac61745…`). This is not store signing;
  no signing secret exists.
- **Maven artifacts are recorded, not locked (review F10).** Gradle resolves AGP,
  React Native and Expo artifacts at build time. The retained resolved release
  classpath is the record, which the review accepts for A2 setup. Gradle
  dependency verification (`verification-metadata.xml`) is a follow-up, not an A2
  requirement.
- **AGP version (review F11): still not recorded.** Run 35966206296 added
  `./gradlew :app:buildEnvironment` (`build-environment.txt`). Its classpath is
  "No dependencies", because AGP sits on the root project's buildscript
  classpath. The correct command is the root `./gradlew buildEnvironment`. It was
  not changed in this revision because a workflow edit reruns the build and
  produces a new APK, which would supersede the Pixel probe. This is not a setup
  field. Fix it on the next rerun that is needed anyway.
- **iOS on the M1.** `iphone-11-build.sh` runs `npm ci` from the retained lock,
  `expo prebuild --platform ios` from the same pinned template, `pod install`
  (CocoaPods 1.17.0 installed with Homebrew; Ruby 4.0.7 per `pod env`) and a Release `xcodebuild` for
  `generic/platform=iOS`, signed automatically by the owner's free personal team
  (development signing; no IPA). `iphone-11-probe.sh` installs and launches it
  with `devicectl` and captures `idevicesyslog`. `xcode-select -p` on the M1
  still points at the Command Line Tools (`m1-xcode.txt`). Every Xcode command
  therefore sets `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`,
  as all three scripts do (review F13).
- **Hermes on iOS (review F16).** `pod install` fetches the debug tarball first.
  It also verifies (SHA1) and caches the release tarball
  `hermes-ios-250829098.0.17-release.tar.gz` (`iphone-11-pod-install.log`), and
  the Release build's "Replace Hermes for the right configuration" phase
  extracts the tarball for the configuration (`iphone-11-xcodebuild.log`,
  excerpted in `iphone-11-pods.txt`). The executed identity on the phone is
  `Build: Release`. `lipo -archs` of the app executable is `arm64`.
- **`toolchain_lock`.** One combined index, `a2-toolchain-lock.SHA256SUMS`, whose
  documented root is `prep/after-pr-10/`, built per review Ruling 5. Entries are
  relative to that root, stay inside it, contain no `..`, absolute path or
  symlink, and the index does not list itself. Its `shasum -a 256 -c` output from
  that root is retained in `a2-toolchain-lock.verify.txt`, which the index does
  not list. Members: from `a1-host-evidence/`, `package.json`,
  `package-lock.json`, `host.txt`, `tools.txt`, `replay.log` and
  `comparison.txt`; every file of `a2-android-evidence/`, including its
  `SHA256SUMS` and verify output; and every file of `a2-device-evidence/` except
  `boox-palma-adb.txt`, including its `SHA256SUMS` and verify output. The A1
  record keeps pointing at the A1 bundle's own `SHA256SUMS`. A changed member is
  a changed setup and needs renewed review.

## Device mapping

| Setup field | iOS: iPhone 11 | Android: Pixel 3a | Source |
|---|---|---|---|
| qualification_class | `iphone-11` | `galaxy-a14-4gb`, owner decision OD1 (substitution; see ADR-070 text) | owner-decision-a2-2026-09-23.md |
| model | iPhone 11 (iPhone12,1, N104AP) | Google Pixel 3a (sargo) | ProductType, HardwareModel / ro.product.* |
| sku | MH8Y3LL/A | G020G | ModelNumber + RegionInfo / ro.boot.hardware.sku |
| soc | "A13 Bionic": **catalogue**, Apple's product page for iPhone12,1 (cited in README.md), not tool-inspected; `devicectl` reports 6 cores, consistent with it but not proof (review F4) | `sdm710`: **inspected** `ro.board.platform`, a platform name, not a marketed SoC name | README.md / `pixel-3a-adb.txt` |
| installed_ram_gb | 4: **catalogue class figure** (Apple publishes none; not inspected) | 4: **catalogue class figure** (Google product specification; not inspected) | see below |
| OS-visible memory (inspected) | `ProcessInfo.processInfo.physicalMemory` 4 039 901 184 bytes (3.76 GiB) | `ActivityManager.MemoryInfo.totalMem` 3 766 829 056 bytes (= kernel MemTotal 3 678 544 kB, 3.51 GiB) | `iphone-11-probe.txt`, `iphone-11-syslog.txt` / `pixel-3a-probe.txt`, `pixel-3a-logcat.txt`, `pixel-3a-adb.txt` |
| os_version / os_build | 26.6.2 / 23G90 | 11 / RQ2A.210505.002 (patch 2021-05-05) | ProductVersion, BuildVersion / ro.build.* |
| architecture | `arm64` (class); raw `arm64e` (CPUArchitecture) | `arm64` (class); raw `arm64-v8a` (ro.product.cpu.abi, APK native-code) | review Ruling 1 |
| server (common host) | MacBookAir10,1, Apple M1, 8 cores (4P+4E), 16 GiB, macOS 26.6.2 (25G83), arm64. **Confirmed by the owner as the A2 common host (OD4)** | | `m1-air-host.txt` |

**Reading RAM (review Ruling 3).** Neither `ideviceinfo`, `devicectl` nor `adb`
reports installed RAM, and an OS reports only the memory it can see. So
`installed_ram_gb: 4` is a class figure from a catalogue on both phones. It is
recorded with that label in each `availability_record`, beside the inspected
OS-visible reading from the phone itself. Both readings are consistent with the
4 GB class and inconsistent with the neighbouring 3 GB and 6 GB classes. They are
not available memory. Nothing in any later measurement may treat 4 GB as
available memory. Both readings are intended to come from one app revision,
per owner decision OD2: the Android APK from run 35966206296 (sha256
`c0d65fba…ea72a7`) records source `c4d2059`; the iOS Release build's source
revision is inferred, not recorded (build time after `c4d2059`, `r1-spike/mobile`
unchanged since), because `iphone-11-build.sh` logged no `git rev-parse` or
`git status` (A2 recheck N1; record both in the next iOS build).

## Reviewer rulings applied (were open decisions)

**(a) Architecture: Ruling 1 applied.** `"architecture": "arm64"` on both
devices. The raw values stay in the evidence and in each `availability_record`.
The checkers are unchanged.

**(b) Pixel 3a for `galaxy-a14-4gb`: owner decision OD1 ("Yes, prep decision
file").** The decision is retained in
[owner-decision-a2-2026-09-23.md](owner-decision-a2-2026-09-23.md). The Android
`availability_record` cites it by path and SHA-256. The register text below is
still a proposal. It enters document 16 only at the next contract amendment,
and document 16 is not edited here.

> **ADR-070 — Pixel 3a substitutes for the Galaxy A14 4 GB Android class (proposed)**
>
> **Status:** Proposed 2026-09-24. Owner decision taken 2026-09-23 (OD1, "Yes,
> prep decision file"); entry into the register awaits the next contract
> amendment.
>
> **Decision-maker and source.** The owner decided. The decision is retained,
> transcribed as relayed by the coordinating assistant, in
> `prep/after-pr-10/owner-decision-a2-2026-09-23.md`, in the same way that
> `owner-instruction-2026-09-23.md` retains the owner's earlier words.
>
> The owner has a Google Pixel 3a (sargo, SKU G020G, platform `sdm710` as
> inspected from `ro.board.platform`, arm64-v8a, Android 11 RQ2A.210505.002,
> kernel MemTotal 3678544 kB) and no Galaxy A14. Any marketed SoC name is
> catalogue knowledge, not inspected. The review's catalogue knowledge says
> Snapdragon 670, unverified here. Installed RAM 4 GB is Google's published
> figure for the Pixel 3a, not tool-inspected. The inspected kernel-visible
> figure is 3 678 544 kB (`ActivityManager.MemoryInfo.totalMem` 3 766 829 056
> bytes).
> R1-A2 Android qualification uses it as the `galaxy-a14-4gb` class. **Setup
> encoding:** `qualification_class: "galaxy-a14-4gb"`. Model, SKU and platform
> are recorded as inspected. The `availability_record` cites the owner decision
> file by path and SHA-256. Limits: it is an older SoC generation than the
> class. Android 11 is older than the A14 class ships with. Its security patch
> (2021-05-05) is stale, so it must not hold secrets or real accounts. The
> build must stay fixed across measurements, so its OS must not be updated.
> That is an instruction to the owner, not an observation. The earlier plan
> text by the implementing assistant is its only retained source, and who
> first gave it is not retained.
> A pass on it is evidence for this device only; it is not store-release device
> coverage. A result that depends on OS behavior newer than Android 11 needs a
> device on that OS. The envelope's numbers do not change.

**RAM mapping: Ruling 3 applied**, as above. **iPhone SoC: F4 applied**, as a
labeled catalogue fact.

## Review findings F10–F17 (informational)

- F10: Maven artifacts are recorded by the resolved classpath, not locked. The
  follow-up is `verification-metadata.xml`. This is not an A2 requirement.
- F11: AGP is still unrecorded. `:app:buildEnvironment` was the wrong project,
  and the root `buildEnvironment` is due on the next needed rerun (see above).
- F12: `toolchain.sqlite` is the phone engine; the server engine is an R1-A2
  result item (see above).
- F13: `DEVELOPER_DIR` is set by every Xcode script. `m1-tools.sh:4` keeps the
  home path, which is not a secret.
- F14: The PR description's stale "adb files include device serial numbers" line
  is replaced. Serials are redacted in every retained revision (OD3).
- F15: Evidence timestamps are UTC (2026-09-24). Commits and phone-local log
  times are `-10:00` (2026-09-23). Nothing is inconsistent.
- F16: The release tarball verification and the replacement phase are now
  retained, as is `lipo -archs` (see above).
- F17: `minSdk=24` is the Expo template default. The device OS floor (Android
  10+; Android 11 here) is enforced by the checker, and the store-facing minimum
  is a release decision, not A2.

## What the owner still must do

1. ~~Install Xcode~~ Done 2026-09-24: Xcode 27.0 (27A266a), iOS SDK 27.0 (24A430).
2. ~~Sideload the APK on the Pixel 3a~~ Done again 2026-09-24 on the rebuilt APK
   (run 35966206296, sha256 `c0d65fba…ea72a7`): Hermes "OSS Release Version"
   250829098.0.17, Build "Release", SQLite 3.50.3, `totalMem` 3 766 829 056 bytes
   (`pixel-3a-probe.txt`, `pixel-3a-logcat.txt`). The owner connected the phone
   (owner report, relayed).
3. ~~Build and run the iOS probe on the iPhone 11~~ Done again 2026-09-24 on the
   rebuilt app: the same Hermes and SQLite identities, `physicalMemory`
   4 039 901 184 bytes (`iphone-11-probe.txt`, `iphone-11-syslog.txt`). The
   Personal Team selection in Xcode is the owner's earlier report, and the owner
   connected the phone (owner report, relayed). An iOS 27 device is untested.
4. ~~Run the RAM probe on both phones~~ Done (OD2).
5. ~~Decide (a), (b) and the RAM mapping; confirm the M1 Air~~ Rulings 1 and 3
   were applied. OD1 and OD4 were answered by the owner.
6. Request the follow-up independent A2 setup review of these bytes. Nobody who
   authored candidate code or this preparation may review it. Only then may
   `setup-review.pending.json` be filled and `status` change.

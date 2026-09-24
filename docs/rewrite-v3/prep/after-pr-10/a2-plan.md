# PREP-02 A2 preparation plan — 2026-09-24

**Status: proposal by the candidate author (Claude Code implementing assistant,
Claude Opus). Not a review, not an approval, not A2 readiness.** The A1 record
`setup.pending.json` is unchanged; its approved A1 digest binds every field.
Proposed A2 values live in [setup.a2-proposed.json](setup.a2-proposed.json),
whose status `a2_proposed_not_reviewed` both readiness checkers reject.

Evidence: [device and M1 host](a2-device-evidence/) (raw `sysctl`/`sw_vers`,
`ideviceinfo`, `adb` output copied verbatim, plus M1 tool identities) and
[Android native build](a2-android-evidence/) from
`.github/workflows/r1-android-native.yml`, run 35951344446 attempt 1, source
`a2dbdf4f035c9743b6c120dc245d3261ec43885c`, image ubuntu24/20260920.314.1.
Each bundle has a `SHA256SUMS` index with its verify output beside it, outside
the index. The BOOX Palma2 output is supplementary only: not a qualification
device and not in the setup record.

## Fourteen toolchain fields

Provenance: **inspected** = raw command output retained; **lock** = the
retained dependency-evidence manifest/lock bytes (installed unchanged, not
re-resolved); **null** = not observed.

| Field | Value | Provenance | Observed by | Host | Status |
|---|---|---|---|---|---|
| expo | 57.0.24 | lock; installed in A1 run 35901131399 and Android run 35951344446 | `npm ci` of the retained lock; `npm ls --all` (A1 `replay.log`) | Actions | proposed |
| react_native | 0.86.3 | lock, as above | as above | Actions | proposed |
| hermes | 250829098.0.17 | inspected (Android) | `./gradlew :app:dependencies --configuration releaseRuntimeClasspath` → `com.facebook.hermes:hermes-android:250829098.0.17` (`apk-facts.txt`) | Actions | proposed; iOS pod version pending Podfile.lock |
| typescript | 6.0.3 | inspected | `node node_modules/typescript/bin/tsc --version` | Actions (A1) and M1 (`m1-tools.txt`) | proposed |
| node | 24.21.0 | inspected | `node -v` | Actions and M1 | proposed |
| elixir | 1.20.4 | inspected | `elixir --version` | Actions (A1) and M1 via mise | proposed |
| otp | 28.4 | inspected | `OTP_VERSION` file (Actions); `erl -eval` reading it (M1) | Actions and M1 | proposed |
| sqlite | 3.50.3 | inspected (Android APK) | `strings` on `lib/arm64-v8a/libexpo-sqlite.so`: version string and source id `2025-07-17 13:25:10 3ce993b8…` | Actions | proposed; on-device `sqlite_version()` and iOS pending |
| sqlite_binding | 57.0.3 | lock | as expo | Actions | proposed |
| xcode | null | — | `xcodebuild -version` (today: Command Line Tools only, exit 1) | M1 | **pending owner Xcode install** |
| ios_sdk | null | — | `xcodebuild -showsdks`; `xcrun --sdk iphoneos --show-sdk-version` | M1 | **pending owner Xcode install** |
| android_sdk | 36 | inspected | Gradle init report `compileSdk=android-36`, `targetSdk=36`; platform `Pkg.Revision=2`; `aapt2 dump badging` | Actions | proposed |
| gradle | 9.3.1 | inspected | `./gradlew --version` | Actions | proposed |
| jdk | 17.0.20+8 | inspected | `java -version` (Temurin, pinned by `actions/setup-java`) | Actions | proposed |

Also recorded, not setup fields: minSdk 24, build-tools 36.0.0, NDK
27.1.12297006 (`source.properties`), ABI `arm64-v8a` only.

The Hermes value is the Hermes V1 artifact actually resolved for the release
build, not the `0.17.0` in `sdks/.hermesversion`; that packaged-metadata
ambiguity from PR #13 is resolved for Android. The retained SQLite value is
the default `vendor/sqlite3` build, not SQLCipher 3.49.1.

## Native configuration and lock plan

- **App config.** `r1-spike/mobile/` holds `app.json`, a one-screen probe
  (`App.tsx`: Hermes runtime properties and `SELECT sqlite_version()`), and
  `package.json`/`package-lock.json` byte-identical to `dependency-evidence/`.
  CI `cmp`s both before install and after prebuild.
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
- **Known gap: Maven artifacts are not locked.** Gradle resolves AGP, React
  Native and Expo artifacts from Google/Maven Central/JitPack at build time. The
  resolved release classpath is retained, but a rerun could resolve differently.
  If the reviewer requires it, add Gradle dependency verification
  (`verification-metadata.xml`) as a follow-up.
- **iOS, later, on the M1.** After Xcode is installed: `expo prebuild --platform
  ios` from the same template, `pod install`, retain `Podfile.lock` (Hermes pod
  version), CocoaPods version, `xcodebuild -version`, `-showsdks`, and a Release
  build signed with the owner's free personal team.
- **`toolchain_lock`.** Stays null until the iOS bundle exists. Then one A2
  `SHA256SUMS` index covers the A1, device, Android and iOS bundles.

## Device mapping

| Setup field | iOS: iPhone 11 | Android: Pixel 3a | Source line |
|---|---|---|---|
| qualification_class | `iphone-11` | null; see decision (b) | — |
| model | iPhone 11 (iPhone12,1, N104AP) | Google Pixel 3a (sargo) | ProductType, HardwareModel / ro.product.* |
| sku | MH8Y3LL/A | G020G | ModelNumber + RegionInfo / ro.boot.hardware.sku |
| soc | null (not inspectable by ideviceinfo) | `sdm710` (ro.board.platform, a platform name, not a marketed SoC name) | — / ro.board.platform |
| installed_ram_gb | null | null (MemTotal 3678544 kB is kernel-visible memory) | see below |
| os_version / os_build | 26.6.2 / 23G90 | 11 / RQ2A.210505.002 (patch 2021-05-05) | ProductVersion, BuildVersion / ro.build.* |
| architecture | raw `arm64e` | raw `arm64-v8a` | see decision (a) |
| server (common host) | MacBookAir10,1, Apple M1, 8 cores (4P+4E), 16 GiB, macOS 26.6.2 (25G83), arm64 | | `m1-air-host.txt` |

**Reading RAM.** Neither tool reports installed RAM. Add a local Expo module
under `r1-spike/mobile/modules/` (autolinked, no new npm dependency) returning
`ProcessInfo.processInfo.physicalMemory` on iOS and
`ActivityManager.MemoryInfo.totalMem` on Android, and have the probe print it
on the `LOKA_A2_PROBE` log line. The owner runs it on each phone (Xcode console;
`adb logcat -d`) and the raw log is retained. Both values are OS-visible bytes,
below the installed size, so mapping them to `installed_ram_gb: 4` (the checker
accepts only 4) is a reviewer decision, like (a).

## Open decisions for the A2 reviewer (proposals, not decided)

**(a) Architecture normalization.** The checker accepts only `arm64`. The raw
values are `arm64e` (Apple's arm64 with pointer authentication) and `arm64-v8a`
(Android's ABI name for AArch64). Options: (1) record `arm64` in the setup
field and keep the raw value in the retained evidence and this plan, leaving the
checker unchanged; (2) amend both checkers to accept the raw per-platform names,
which is a reviewed tooling change. The proposed record keeps the raw values,
so it fails here until the reviewer chooses. Proposal: option 1.

**(b) Pixel 3a for `galaxy-a14-4gb`.** Proposed register text (ADR-070 would
follow ADR-069; the register is not edited here):

> **ADR-070 — Pixel 3a substitutes for the Galaxy A14 4 GB Android class (proposed)**
>
> **Status:** Proposed 2026-09-24 for the A2 setup review; owner and reviewer
> decision pending.
>
> The owner has a Google Pixel 3a (sargo, SKU G020G, platform sdm710,
> arm64-v8a, Android 11 RQ2A.210505.002, kernel MemTotal 3678544 kB) and no
> Galaxy A14. R1-A2 Android qualification uses it as the `galaxy-a14-4gb`
> class, recorded with this ADR in the device's `availability_record`. Limits:
> it is an older SoC generation than the class; Android 11 is older than the
> A14 class ships with; its security patch (2021-05-05) is stale, so it must
> not hold secrets or real accounts; the owner was told not to update its OS,
> so the build stays fixed across measurements. A pass on it is evidence for
> this device only; it is not store-release device coverage. A result that
> depends on OS behavior newer than Android 11 needs a device on that OS. If
> the substitution is rejected, obtain an identified A14-class device before
> A2; the envelope's numbers do not change either way.

## What the owner still must do

1. Install Xcode on the M1 Air, then run `xcodebuild -version` and
   `xcodebuild -showsdks` and keep the output.
2. Sideload the `app-release-apk` artifact of run 35951344446 onto the Pixel 3a
   (`adb install app-release.apk`), open it, and keep
   `adb logcat -d | grep LOKA_A2_PROBE` (on-device Hermes and SQLite). Keep
   the Pixel's OS un-updated.
3. After Xcode: build and run the iOS probe on the iPhone 11 with a free
   personal team; keep the console `LOKA_A2_PROBE` line and `Podfile.lock`.
4. Run the RAM probe on both phones once the module above is added.
5. Decide, with the independent A2 setup reviewer, (a), (b) and the RAM
   mapping; confirm the M1 Air as the A2 common host.
6. Nominate the independent A2 setup reviewer; nobody who authored candidate
   code or this preparation may review it.

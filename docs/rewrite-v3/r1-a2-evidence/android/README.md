# R1-A2 Pixel 3a evidence

**App tested on the phone:** the release APK from Actions run **36024373520**
(`r1-android-native.yml`, source commit `e61c52a`), sha256 `f5d512b8…659c`.
Its Hermes composed source map has sha256 `c5f086df…1234`
(`actions-run-36024373520/index.android.bundle.map`). Gradle flags:
`-PreactNativeArchitectures=arm64-v8a -PreactNativeDevServerIp=localhost`
(`build-flags.txt`). AGP is 8.12.0 (`agp-version.txt`, from the root
`./gradlew buildEnvironment`). Phone: Pixel 3a, Android 11
(RQ2A.210505.002). The app data was cleared before the run (`pm clear`).

## Results

- **Differential** (`differential.txt`): all 139 request lines are
  byte-identical to the Elixir runner (`elixir-runner.jsonl`). When one byte of
  device line 70 is altered, that line is reported as the only mismatch.
- **Faults** (`faults-check.txt`, `faults.jsonl`): 19 of 19 pass. Each case is
  also cross-checked against the Elixir runner. Seven launches were needed: the
  six `kill` cases each SIGKILLed the process, and ActivityManager logged six
  "has died" lines (`pixel-3a-run.txt`). JS stacks for `raise` and `io_error`
  are symbolicated with
  `node node_modules/metro-symbolicate/src/index.js index.android.bundle.map < stack`.
- **Runtime** (`summary.json`): Hermes 250829098.0.17 Release, SQLite 3.50.3,
  `journal_mode=delete`, `synchronous=2` (FULL).

## Build-flag change and repeatability

The first two builds (runs 36019566499 and 36019591785 at `314a129`; bundles
kept, compared in `build-compare-before-flag.txt`) differed only in
`resources.arsc`. It held the string `react_native_dev_server_ip` = the Actions
runner's private IPv4. The RN Gradle plugin (`AgpConfiguratorUtils.configureDevServerLocation`)
writes the build host's first non-loopback IPv4 into `defaultConfig`, which
covers every variant, release included, unless `reactNativeDevServerIp` is set.
This leaked build-host information into a release artifact. Since `3525fdc`
the workflow passes `-PreactNativeDevServerIp=localhost`. That is a build flag
only; no version or template changed.

With the flag set, compare runs 36024373520 and 36024393410 at `e61c52a`
(`build-compare.txt`), and likewise runs 36022268988 and 36022290115 at
`3525fdc`:
- The Metro bundle, the Hermes bytecode, both source maps, every zip entry, the
  v2 signature and the central directory are byte-identical.
- The APK files still differ, but only in signing-block pair `0x504b4453`, AGP's
  dependency-info block. AGP stores it encrypted, with fresh randomness per
  build. It lies outside the v2-signed content.
- Disabling it (`dependenciesInfo { includeInApk = false }`) would be an app
  build-configuration change. It is not made here.

## Failed attempt kept

`failed-attempt-1/` holds the first Pixel run, with the APK from run
36022268988. It failed before case 1 with an Android-only expo-sqlite handle
bug in the app, now fixed. See its README.

All files except the `actions-run-*` bundles come from `pixel-3a.sh` or
`actions-compare.sh` and pass through `redact()`. The `actions-run-*` bundles
are Actions artifacts, unchanged, each with its own `SHA256SUMS`. This
directory's `SHA256SUMS` covers every file here, and `SHA256SUMS.verify.txt`
is its check output.

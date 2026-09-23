# Development host strategy: GitHub for headless work, local for the app — 2026-09-23

**Status: informative owner direction, not an accepted host amendment or
execution approval.** The owner first asked to develop without the local M1 Air,
because the web assistant can reach GitHub but not that machine. After checking
costs, the owner decided on 2026-09-23 that the project pays for **no** Expo
Application Services (EAS) tier and accepts local development where cloud
options cost money. This records that conversation, not an approval receipt. It
does not replace the earlier [owner instruction](owner-instruction-2026-09-23.md).

## Zero-cost working loop

GitHub branches and pull requests stay the handoff surface, so the web assistant
can push work and CI can check it. Headless work runs on free GitHub-hosted
runners. App iteration and iPhone installs run on the owner's M1 Air. No paid
subscription, signing credential, preview app or candidate gameplay is created
by this note.

| Need | Path | Cost | Evidence limit |
|---|---|---|---|
| Headless A1 semantics and lock replay | GitHub Actions, per the proposed envelope v0.5 A1 row and `.github/workflows/v3-a1-host.yml` | Free for this public repository | A green job is not setup approval |
| UI iteration | Metro on the M1 Air with hot reload on a physical phone | Free | Development builds are not release or performance evidence |
| Android app | Our own Actions workflow on a Linux runner: `expo prebuild`, then Gradle, APK uploaded as a run artifact and sideloaded | Free, no Expo account or token | Debug or unsigned builds are not A2 release evidence |
| iOS app on the owner's iPhone | Xcode on the M1 Air, signed with a free Apple ID personal team | Free; installs expire after 7 days | Needs the Mac; TestFlight or cloud-built device installs need the paid Apple Developer Program |
| Browser preview | `expo export` for web, published to GitHub Pages | Free | Browser behavior is not Hermes/native performance |
| Automated UI checks | Emulator or simulator jobs on free runners, retaining screenshots and logs | Free | Compatibility evidence, not physical qualification |
| A2 qualification | Release builds on identified physical phones, measured by the owner | Free apart from hardware already owned | Retain thermal/battery/build/device evidence and the separately approved common host |

The owner's assistant pushes branches, CI checks them, and the owner pulls and
runs anything visual on the Air. Prefer the physical phones over emulators when
the Air's 16 GB is contended by Xcode and Metro together. Actions is a batch
executor, not a live preview server. Development location does not change
offline-authoritative Story gameplay.

## Rejected or deferred options

- **EAS Build, Update and Hosting.** The free tier exists, but the owner declined
  any dependency on a paid tier. Do not add EAS configuration or tokens.
- **Visual Studio App Center.** Retired by Microsoft on 2025-03-31.
- **Third-party workflow generators such as ExpoBuilder.app.** Android only, and
  they still require an `EXPO_TOKEN`. Write and pin our own workflow instead.
- **Codespaces.** Optional for live editing; not required, and its free quota is
  separate from Actions.
- **Device farms.** Would need verified inventory of the exact phone models, a
  reviewed qualification amendment and a paid service. Not needed before A2.

## Facts checked on 2026-09-23

Recheck before relying on them.

- Standard GitHub-hosted runners, including macOS, are free for public
  repositories. Larger runners and Codespaces are billed separately.
- An OS label such as `ubuntu-24.04` is not an immutable image. Pin the tools
  and dependencies we control and record the observed image version, source
  SHA, run and attempt, CPU, architecture, RAM and OS. Hosted timing is not a
  substitute for controlled common-host p99 qualification.
- Expo Go only includes its bundled native modules. Use a development build for
  custom native dependencies. JS-only changes reuse an installed build; native
  dependency or configuration changes need a rebuild.
- EAS free plan at the time of checking: 15 Android and 15 iOS builds a month,
  low-priority queue; Starter $19/month and Production $199/month plus usage.
  Recorded only to explain the decision.

References: [GitHub runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners),
[runner image lifecycle](https://github.com/actions/runner-images),
[Expo development builds](https://docs.expo.dev/develop/development-builds/introduction/),
[Expo local builds](https://docs.expo.dev/guides/local-app-overview/),
[Expo pricing](https://expo.dev/pricing),
[App Center retirement](https://learn.microsoft.com/en-us/appcenter/retirement).

## Security

Keep CI checks read-only and pinned to exact action commits. Never expose
signing or deployment secrets to untrusted pull-request code. Keep forwarded
ports private; a public tunnel is a public endpoint. Workflow-file changes are
pushed by a human or an authorized connector, not by a job token. Build outputs
are artifacts, never automatic approvals or source commits.

## Stage boundaries

Envelope v0.5 proposes the hosted runner as the A1 execution host only. It
still needs review, and refreshing input hashes renews nobody's consent. R0
acceptance, attributable oracle approval, independently reviewed A1 setup and
both readiness checks remain prerequisites to candidate A1 work. A1 needs no UI,
native build or preview infrastructure. A2 keeps the M1 common host and the
physical phones. A-first/B-after-failure/C-after-B-failure sequencing, R2
clean-room cutover and the 57-room chapter are unchanged.

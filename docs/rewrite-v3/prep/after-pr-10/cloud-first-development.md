# Cloud-first development direction — 2026-09-23

**Status: informative owner preference and proposed next step, not an accepted
host amendment or execution approval.** The owner asked to consider developing
without their local M1 Air because the web assistant can access GitHub but not
that machine, using CI for builds/tests and browser-accessible Expo previews.
This records the current conversation, not an invented approval receipt. It does
not replace the earlier [owner instruction](owner-instruction-2026-09-23.md).

## Recommended working loop

Use GitHub branches and pull requests as the handoff surface. Run bounded,
repeatable checks in Actions and retain exact-source results. When the UI phase
is authorized, publish a web preview with a commit-labelled URL; add cloud-built
native development clients for checking the actual phone UI. A Codespace is an
optional interactive editor/Metro host, not a mandatory always-on service.
No preview app, candidate gameplay, paid subscription or signing credential is
created by this preparation change.

| Need | Proposed path | Evidence limit |
|---|---|---|
| Headless A1 semantics and lock replay | GitHub Actions, following an explicit hosted-A1 amendment and real setup review | A green specification job is not candidate setup approval |
| Browser visual review | Export/deploy the Expo web target; for example a static preview host or EAS Hosting, chosen when needed | Browser behavior is not Hermes/native performance |
| Live editing | Optional Codespaces with forwarded web port; Metro tunnel for a phone development client | A session must remain running; URLs/tunnels require access control |
| Native builds | EAS Build, or bounded Actions jobs using suitable macOS/Linux toolchains | iOS device provisioning/signing still applies |
| JS-only native preview updates | EAS Update/PR preview linked to an already-installed compatible native runtime | Native dependency changes require a new compatible binary |
| Automated UI checks | Emulator/simulator jobs with retained screenshots and logs | Compatibility/visual evidence, not physical qualification |
| A2 qualification | Cloud-built release binary installed on identified physical phones | Retain thermal/battery/build/device evidence and the separately approved common host |

Actions is a batch executor, not the persistent public web server for the app.
Uploading a ZIP alone does not provide a deployed interactive preview URL. Keep
preview hosting and interactive development separate from CI execution. Cloud
*development* also does not change offline-authoritative Story gameplay.

## Corrections and qualifications to the supplied cloud advice

Official documentation was checked on 2026-09-23; service access, prices and
inventory must be checked again before provisioning.

- Standard GitHub-hosted runners for public repositories are free, including
  standard macOS runners. Do not apply a blanket macOS billing multiplier to
  this public-repository case. Larger runners, Codespaces and Expo services
  have separate billing/allowances; this note authorizes no spending.
- An OS label such as `ubuntu-24.04` is not an immutable runner image. Pin actual
  tool/dependency versions and, where appropriate, container image digests;
  record the observed runner image version, source SHA, run/attempt, CPU,
  architecture, RAM and OS. A recorded image identity is not a guarantee that
  GitHub will let us request exactly that image later. Hosted variance is not a
  sound substitute for a controlled common-host p99 qualification decision.
- Expo Go is limited to the native modules it includes. Use a development build
  for custom native dependencies. EAS Build avoids a local native toolchain,
  but physical iOS installation still needs the applicable Apple provisioning;
  simulator builds are different from physical-device builds.
- Expo's current CLI also documents experimental `eas sim` remote simulator
  sessions with browser previews. This is a promising optional browser-native
  preview path, not a stable dependency selected here. Account eligibility,
  availability and costs have not been verified for the owner.
- Do not promise that a named device farm currently offers both required exact
  phone models, or that its thermal/battery controls satisfy the envelope.
  Device-farm substitution would require verified inventory and a reviewed
  qualification amendment. It is not necessary to decide this before A1.

Primary references: [GitHub runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners),
[runner image lifecycle](https://github.com/actions/runner-images),
[Codespaces port forwarding](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace),
[Codespaces billing](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-codespaces/about-billing-for-github-codespaces),
[Expo development builds](https://docs.expo.dev/develop/development-builds/introduction/),
[Expo PR previews](https://docs.expo.dev/tutorial/cicd/preview-builds/), and
[EAS CLI / experimental remote simulator](https://docs.expo.dev/eas/cli/).

## Security and the smallest next amendment

Keep CI checks read-only, use explicit source commits, and do not expose signing
or deployment secrets to untrusted pull-request code. Keep forwarded ports
private where possible; a public tunnel is a public endpoint, not an access
control mechanism. Use an authorized connector or human workflow-file change
with the necessary permission instead of teaching a job token to rewrite CI.
Retain build outputs as outputs, not as automatic approvals or source commits.

The correction PR preserves the seven reviewed inputs, including envelope v0.4.
The next focused proposal should explicitly permit an identified hosted **A1**
execution environment, specify retained runtime/lock replay evidence and its
stage-bound review, and keep A2 physical-device/common-host timing requirements
unchanged. Refresh only the affected input bindings after that amendment is
reviewed; a new digest does not renew anyone's consent. A1 does not need a UI,
Expo preview infrastructure, native integration or a device-farm purchase first.
The historical R0 proposal is not acceptance of this future host amendment.

Keep R0 acceptance, attributable oracle approval, independently reviewed A1
setup and both readiness checks as actual prerequisites to candidate A1 work.
A2 remains later. Existing A-first/B-after-failure/C-after-B-failure sequencing,
R2 clean-room cutover and the 57-room chapter remain unchanged.

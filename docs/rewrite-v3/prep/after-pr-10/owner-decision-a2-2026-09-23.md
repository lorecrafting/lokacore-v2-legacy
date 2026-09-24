# Owner decisions: A2 setup review OD1–OD4

Source: the owner's answers to the four owner decisions (OD1–OD4) in the
independent A2 setup review
([reviews/2026-09-23-a2-setup-review.md](../../reviews/2026-09-23-a2-setup-review.md)
§6), given 2026-09-23 in the coordinating Claude Code session and **relayed by
the coordinating assistant** to the implementing assistant, who transcribed them
here. This file is a retained conversation source. It is not an independent
identity attestation, a device inspection or a reviewer approval. No public
conversation URL or exact message timestamp is asserted. The owner's answers are
quoted as relayed. The options are the reviewer's, summarized from §6 and F6.

## OD1: Android substitution

**Question.** Does the Google Pixel 3a (SKU G020G, platform sdm710, Android 11
RQ2A.210505.002, kernel-visible memory 3 678 544 kB) stand in for the
`galaxy-a14-4gb` class for the disposable R1 experiment only, under the limits
in ADR-070's text? And where does that decision live (OD1b)?

**Options offered.** Yes, recording the substitution per Ruling 2; or no,
obtaining an identified A14-class 4 GB device before A2. OD1b: (A) an owner
decision file in `prep/after-pr-10/`, cited from the setup now, with ADR-070
entering document 16 at the next contract amendment; or (B) amend document 16
now, accept a new R0 commit and rebind the R0, oracle and setup-review receipts.

**Owner's answer:** "Yes, prep decision file".

**Applied scope.** The Pixel 3a stands in for the `galaxy-a14-4gb` class for the
disposable R1 experiment only. This file is the retained decision. The A2 setup
record cites it by path and SHA-256. ADR-070 (proposed text in
[a2-plan.md](a2-plan.md)) enters document 16 only at the next contract
amendment. Document 16 and the accepted contract commit are not changed here.

## OD2: Memory reading and re-probe

**Question.** Add the local memory module and re-run the probe on the iPhone 11,
and then either (A) also re-sideload and re-probe the Pixel 3a on the rebuilt
APK so that both probes come from one app revision, or (B) keep the Android
evidence at the pre-module app and say so.

**Owner's answer:** "Re-probe both phones".

**Applied scope.** Option (A). The memory reading is added to the probe app. The
iPhone 11 and the Pixel 3a are both re-probed on the rebuilt app, so both probes
come from one app revision.

## OD3: Serial numbers in public history

**Question.** The `adb` serial numbers of the Pixel 3a and the BOOX Palma 2 were
in four earlier commits of `prep/a2-freeze`. Options: (a) merge as is; (b)
rewrite the branch before merge; (c) rewrite and also ask GitHub support to
purge the unreachable objects.

**Owner's answer:** "Rewrite branch".

**Applied scope.** Option (b). `prep/a2-freeze` is rewritten so that no blob
containing an `adb` serial reaches `main`, and the branch is force-pushed. The
plan records the rewrite. No GitHub purge request is part of this decision.

## OD4: Common host

**Question.** Confirm the M1 MacBook Air (`MacBookAir10,1`, 16 GiB, macOS 26.6.2)
as the A2 common host.

**Owner's answer:** "Confirm M1 Air".

**Applied scope.** The M1 MacBook Air is the A2 common host. Its inspected
identity is retained in `a2-device-evidence/m1-air-host.txt`.

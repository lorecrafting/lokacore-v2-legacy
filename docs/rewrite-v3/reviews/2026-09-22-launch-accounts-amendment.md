# Launch accounts and prologue progress amendment — 2026-09-22

## Owner direction and base

The owner requested accounts from the outset so offline prologue completion can be tracked per player and used as a prerequisite for later online-world entry, then approved the proposed amendment. Starting review head: PR #9 at `f985ebe8cb5c61109325ee38e912b5f8f3600f39`. This is a further amendment to that open packet, not a new specification authority or a legacy-engine implementation.

The full chapter-one scope stays 57 rooms, 10 quests and two endings. Both intended endings qualify by default. Account support and durable progress sync are required at the first public Story release. Guest-first versus initial-registration UX remains an explicit product choice; installed offline play cannot depend on an active login. Full-save backup is still optional and distinct.

## Changes

Document 23 is the single governing account/progress/admission contract, with ADR-063 recording accepted product direction. Existing state, capability, narrative, mobile, security, Lab and roadmap documents link to it and remove outdated optional/late-account wording. README, INDEX, the human review guide and R milestone guide route readers to the same contract.

R12A is a subdivision of R12, so all 25 existing top-level milestone IDs remain stable. It brings real platform identity, recovery/deletion, PostgreSQL/API and milestone acceptance/readback before free public launch. R13 extends it with purchases; R14/R15 enforce server-side onboarding admission. R6 captures local milestones/pending reports atomically; R6P exercises a fake adapter without waiting for production identity.

The planning schema moves to version 2 to add a distinct platform-gate map. ACCOUNT applies to public chapter releases and Realm, not as a live-service dependency for the proof or pure cartridge certification. The 37-capability chapter-one lock is unchanged. ACCOUNT-01–12 define implementation evidence. The new Python model and tests exercise a deliberately much smaller contract.

## Self-review corrections

- Account progress was at risk of becoming another gameplay scope or an authentication dependency inside deterministic rules. Kept association/queue/acceptance metadata in the host/platform, outside portable inputs and hashes.
- An early wording treated a milestone as a generic fact/event. Clarified a typed DomainEvent plus durable marker and atomic host-side report capture.
- The first draft moved account work in the prose but left old roadmap/sizing and MODE-10 shorthand. Reconciled the launch gate, diagram, estimates, historical-heading explanation, pruning hints and generated checklist.
- Adding a required planning field without a version change was misleading. Bumped the planning schema and validator together to version 2.

## Adversarial self-review corrections

This pass is by the implementing assistant, not an independent reviewer or R0 approval.

- A run was bound to an account but could submit another cartridge release. Pin both account and exact release, reject silent repinning, and add a negative test.
- Replaying an accepted report after withdrawal must replay history without reinstating eligibility. Admission reads current effective records; tested same-ID and new-ID retries after withdrawal.
- New account creation with the same email must not inherit a deleted identity or its queued reports. Identity is non-reused; server commit rechecks lifecycle, and local deleted-account disposition does not silently guest-claim.
- Client-selected account/evidence/unlock/currency fields must not become authority. Strict report fields, trusted harness principals, known milestone/outcome maps and onboarding-only policy are checked separately.
- Admission must not rely on a stale progress or policy version. Both version-change cases have explicit tests; real session/DB race evidence remains required.
- The generated checklist must distinguish public-app platform work from pure cartridge gates. It now labels the additional ACCOUNT gate separately.

## Validation and evidence limits

Run from the repository root:

```text
python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py' -v
python3 docs/rewrite-v3/checks/release_scope.py --check
python3 docs/rewrite-v3/checks/packet_navigation.py --check
python3 -m compileall -q docs/rewrite-v3/checks
git diff --check
```

Local result: **58 tests passed** (36 existing plus 22 account/progress tests). Scope generation, 30 reader menus/local links/milestone coverage, syntax compilation and whitespace checks passed. Exact remote-head evidence is recorded in the PR after publication; a local pass is not a remote CI result.

The model uses harness-supplied principals and in-memory transaction/fault outcomes. It does not implement authentication, real SQLite/PostgreSQL concurrency, secure credential storage, live admission, account recovery, privacy operations or device background sync. These are R12A/R14 implementation gates. No production account is created and no user data is accessed or changed. No R0/R1 or player/device gate is marked complete. Existing full-campaign quest-count and novice-schedule questions remain flagged; this amendment does not silently resolve story intent.

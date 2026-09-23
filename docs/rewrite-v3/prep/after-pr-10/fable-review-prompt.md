# Fable / Claude Code: bounded independent review

You are reviewing Loka v3 in https://github.com/lorecrafting/lokacore. Perform a
bounded expected-answer and staged-readiness review, NOT another architecture
redesign and NOT candidate implementation. Produce attributable findings and one
review report. Do not fix the material you are independently reviewing and then
approve your own corrected version.

## Establish the exact subject first

Follow AGENTS.md and applicable nested instructions. Preserve unrelated work.
Read `docs/rewrite-v3/README.md` section 8 and `REVIEW-GUIDE.md` for authority.
The prior main was `037e6513f882b25512928aab5883f8545b58fc84` (merged PR #13).
The staged-preparation amendment is on `prep/v3-staged-readiness`; inspect its PR
status and record its exact source head, current main and your checkout. The
owner-provided handoff may pin a specific PR/head: review that exact head, not an
unmerged branch silently represented as main or a later moving target. Do not
execute temporary transport workflows or treat their commits as the subject.

Start with:
- `docs/rewrite-v3/prep/after-pr-10/README.md`
- `owner-instruction-2026-09-23.md`, `r0-acceptance.pending.json`,
  `setup.pending.json`, `oracle-review.pending.json`, `setup-review.pending.json`
  in that same directory
- `docs/rewrite-v3/reviews/2026-09-23-staged-preparation.md`
- `docs/rewrite-v3/r1-work-package.md`, `r1-acceptance-envelope.md`,
  `conformance/README.md`, `spec_tools/README.md`, `spec_tools/preserved-inputs.json`
- relevant R0/R1/R2 portions of document 14, READY-01/02 in document 15,
  ADR-064/067 in document 16, and document 04's composition/commit contracts.

The owner approved moving complete native/physical preparation to A2, prefers
Expo previews, reported M1 MacBook Air/16 GB and physical iPhone 11, old unknown
Pixel and Palma 2, and delegated hardware recommendations. The amendment selects
iPhone 11/4 GB as the initial iOS planning class instead of SE 2/3 GB; Android
A14/4 GB remains until a concrete substitution is reviewed. These are not actual
OS/native/runtime measurements. No entire-contract R0 acceptance is inferred
from the owner's sequencing instruction or any merge.

## 1. Establish review provenance; do not self-certify independence

Record the actual reviewing agent/tool/session and responsible operator as
known, without inventing a model build, identity, signature or attestation.
Inspect attribution/history for candidate authors and the authors/material
revisers of each reviewed subject, including the envelope and setup. A prior
Fable review is not necessarily authorship, but it must be disclosed and checked.
Different model/session/language/account labels alone do not prove independence.
Do not put the owner or another person in `reviewer_id` merely because the tool
runs under their GitHub account. Document evidence of separation or say it is
unresolved. Lack of accepted R0/attribution does not prevent useful technical
findings, but it prevents an unconditional gate approval.

Review expected answers and gate logic as separate subjects. If you create or
repair setup configuration, you become an author of that setup and must not
independently approve it. Do not fill an approval receipt for missing evidence.

## 2. Independently inspect the exact seven inputs

Read every byte/expected value in:
1. `r1-acceptance-envelope.md`
2. `conformance/numeric-profile.md`
3. `conformance/numeric-vectors.json`
4. `conformance/cases.json`
5. `conformance/composition-profile.json`
6. `conformance/composition-cases.json`
7. `conformance/lantern-traces.json`

Recompute hashes and verify ordering/bindings. Only the authorized envelope
changed from the previous eleven-input preservation baseline; all six semantic
inputs and the other preserved inputs must remain unchanged. Inspect the old
and new envelope; challenge the narrower iOS support claim explicitly.

Derive expected behavior from governing contracts before using model output as
confirmation. Check numeric results AND every next RNG state, negative signed
division/remainder, bounds/overflow, invalid JSON/booleans, rejection sampling
and budgets. Check admission/retry/altered intent, failed checks versus rejection,
root sequence/FIFO dispatch, emission-time eligibility versus overlay guards,
writer groups/conflicts, aggregate invariants, shared fuel and rollback.

Check receipts, definite rollback, unknown COMMIT fencing/reconciliation,
post-commit recovery/narration, both Lantern outcomes, early possession, drops,
moved Bram, stale/consumed choices and continuation. Inspect the small Python
models and scoped tests as implementations of examples, not authorities that
may regenerate their own expected answers. Preserve stated limitations:
scheduler cancellation/rescheduling and save-fork/restore traces are not an
actual general scheduler, native persistence engine or proven save system.

For each material finding give file/line, exact input and expected/observed
behavior, a minimal counterexample, affected gate, severity and smallest proposed
correction. Do not introduce a new architecture, benchmark or gameplay scope.

## 3. Challenge the A1/A2 gate separation in both implementations

Read `checks/readiness.py`, `checks/test_staged_readiness.py`, related existing
preparation tests, `spec_tools/lib/readiness.ex` and its ExUnit tests.

Prove with bounded temporary SYNTHETIC test records:
- blank and actual pending manifests reject both stages; default stays full A2;
- A1 permits null native/phone fields but still requires real execution-host
  details, exact Node/TypeScript/Elixir/full OTP, retained replayable locks,
  accepted amended contract, exact seven inputs, identities and independent
  oracle/stage-specific setup approvals;
- A2 still requires complete native/physical evidence and common-host floor;
- a full A1-approved record cannot authorize A2 merely by switching the flag,
  status, copying review hashes or supplying more fields;
- A1 digest is SHA-256 of UTF-8 `loka-r1-a1-setup-v1` plus one NUL byte plus the
  canonical manifest excluding `status` and `setup_review`; A2 preserves the
  unprefixed digest. All other supplied fields stay bound;
- malformed deferred records, version ranges, missing/altered hashes,
  unsupported stages, changed inputs and candidate/subject self-review fail;
- both implementations agree; no weak implicit fallback or forged ready record.

Fixtures used to test acceptance structure must stay temporary and synthetic.
A structural pass cannot authenticate a person, establish device use, select a
runtime, prove performance or authorize production.

## 4. Review actual setup only to the extent real evidence exists

Check retained dependency SHA256SUMS and package/native evidence. Existing JS
lock SHA-256 is
`18ac7c91f854dcd55480dea15b57c52afa0d674863ce4d620221926b99644359`.
Do not resolve a new graph or call packaged metadata an executed runtime.
Separate owner-reported Mac/iPhone availability from inspected OS/SKU/RAM and
runtime/configuration evidence. At A1, no phone purchase/native qualification
is required. A2 must not use an emulator, Expo Go or Palma 2 as ordinary-phone
qualification. Expo development builds are previews; release builds and actual
physical measurements remain later gates.

Keep missing A1 setup evidence as missing. Do not create a setup, install/upgrade
the owner's tools, alter device settings or collect private identifiers merely
to approve it. Read-only verification of existing evidence is permitted; retain
necessary commands/output with serials, UDIDs, tokens and account details omitted.
Recheck official documentation when making compatibility claims.

## 5. Run scoped checks and distinguish execution from inspection

From repo root:
```sh
python3 -m unittest discover -s docs/rewrite-v3/checks -p 'test_*.py' -v
python3 docs/rewrite-v3/checks/release_scope.py --check
python3 docs/rewrite-v3/checks/packet_navigation.py --check
python3 docs/rewrite-v3/checks/readiness.py --check-template
git diff --check
```
From `docs/rewrite-v3/spec_tools`:
```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix test --include comparison
mix loka.readiness --check-template
```
Separately run both implementations' `--require-ready` with `--stage A1` and
`--stage A2` against BOTH the permanent blank template and actual setup; retain
all eight exit codes. Use `--evidence-root docs/rewrite-v3` from root or `..`
from spec_tools. The blank template must always reject; incomplete actual setup
must reject. Report unavailable commands, local execution, inspected hosted logs
and manual derivations separately. Never edit answers/checks to obtain a pass.
Do not run the legacy server/whole-project suite, a mutation sweep, native builds
or candidate gameplay as part of this review.

## 6. Deliverable

Produce one review report with exact reviewed commit, provenance/authorship
matrix, seven input hashes, findings/counterexamples, command results, coverage
limitations and separate dispositions for expected answers, stage-gate logic,
A1 setup, A2 setup and actual A1 authorization. A clean technical review can
coexist with NOT READY due to missing R0/setup/authenticated independence.

Only populate an existing approval receipt when real exact-revision acceptance,
authorship independence and subject evidence actually support it. Otherwise
leave receipts pending and record useful findings in the report. Do not rebind
old approval to new bytes without a genuine renewed review. Do not implement
corrections in the reviewed subjects; hand findings back to the implementer.

Retain completed review evidence on a fresh focused review branch/report PR
following repository instructions, or return the complete report when publication
is unavailable. Do not auto-merge. End with the smallest remaining actionable
list, not a new broad review plan. No A1/A2/R1/production pass is fabricated.

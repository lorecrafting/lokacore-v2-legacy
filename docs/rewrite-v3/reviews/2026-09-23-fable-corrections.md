# PR #14 — focused Fable corrections and transport cleanup

**Subject:** corrections after [Fable's complete review](https://github.com/lorecrafting/lokacore/pull/14#issuecomment-5799272066)
of source `b0eb3d6e66dfcdb02c3ce3db8c98bb6d2973a528`, tree
`cf95c26a744abef8976c47b45253dfc65363ca63`. That original review remains tied to
those bytes. This record is implementing-assistant self-review, not an
independent approval of corrected bytes. Final publication SHA and exact-head
CI disposition belong in the PR's validation comment; this file does not claim
a future run already passed.

## Reconciliation and cleanup

Observed main was `94c745dd03f2a5d3ca9c015069294725f7110a51`, which merged PR #15.
Comparison from shared base `037e6513f882b25512928aab5883f8545b58fc84` found only
the four temporary transport paths. Merge commit
`bfcfb7b1186437ba7a892e98e645d281ec1ec376` reconciles that main as a second parent.
Dedicated cleanup `cee26e586db36d29425487625d77895174d30120` then restores the
reviewed PR tree exactly, removing `.github/workflows/v3-stage-transport.yml`
and `.v3-stage-transport/part1.b64`, `part2.b64`, `part3.b64`.

The transport commits remain in history. No reset, force-push or transport
workflow execution is used. The permanent specification workflow and legitimate
dependency evidence remain. The live PR branch is advanced only to a cleaned
correction tip. Main's files change only when the owner merges this PR; deleting
a temporary branch cannot remove files already merged into main.

## Finding-to-fix disposition

| Finding | Correction | Regression evidence |
|---|---|---|
| F1: deferred supplied device values lack semantics | Both checkers validate each supplied field against platform class, RAM, architecture and numeric OS/floor rules; each unknown field may independently remain null at A1 | Python staged partial/contradictory tests; ExUnit re-bound matrix; Python/Elixir comparison matrix |
| F2: partial runtime identities look exact | Node/TypeScript/Elixir require complete stable three-part versions, with valid optional build metadata; OTP permits full numeric two-to-four-part identities such as 28.4; core runtime fields reject bare hashes | Valid retained versions, partial/range/prerelease/malformed/Unicode/hash values, both stages, with renewed synthetic digest |
| F3: unsupported stage CLI divergence | Python checks an explicit stage inside the controlled error boundary, like Mix; A3/a1 exit 1 with NOT READY; unrelated Python syntax remains argparse exit 2 | Both CLI modes in tests; actual blank/pending manifests at explicit/default/invalid stages in CI |
| F4: single lock path versus complete bundle | Existing preparation README specifies one checksum/index manifest covering actual A1 runtime, host, lock and replay bytes, plus verification of every member | Documentation/preparation obligation, not a claimed new recursive checker or real bundle |

The F2 format rules follow [SemVer](https://semver.org/),
[Elixir Version](https://hexdocs.pm/elixir/Version.html) and
[OTP full version reporting](https://www.erlang.org/doc/system/versions.html).
OTP's major-only runtime value is not the full OTP_VERSION file. A syntactically
valid identity is not proof of installation. Existing non-core build-ID support
is retained, not promoted into evidence for the four A1 runtimes.

## Validation and provenance

The editing container has Python but no Mix/Elixir/OTP and cannot resolve GitHub
for a local clone/push. The prior reviewed-source artifact was downloaded via
the GitHub connector; its ZIP SHA-256 is
`3b28d83eca3eb8f8148fb45117b72778279340e1236d6abc36602b83357e8f9e`.
It is a scoped source snapshot, not a full local repository history. Publication
uses GitHub tree/commit/ref APIs and must be verified on the remote branch; no
successful local git push is asserted.

New local Python baseline: **107 tests passed**. Corrected suite: **112 tests
passed**. Tests use temporary synthetic approvals only. The added cross-language
matrix rebinds the synthetic setup digest after each mutation, so rejection
cannot be credited merely to a stale review hash. Actual records remain pending.
Local scope/navigation/template/whitespace, preserved hashes, reference bindings
and negative probes are checked again before publication.

Permanent CI checks the exact source head, prospective merged-tree cleanup,
retained dependency checksums, Python tests, formatting, warnings-as-errors Mix
compilation, default ExUnit, comparison tests and both actual CLI negative gates.
It retains source, head, runner-image metadata and logs. A failure-only formatter
diff is diagnostic, not a passing validation or an automatic source write.
Any failed first attempt and the final corrected run must be reported separately.
Old successful run 35890946869 is not validation of these corrections.

## Preservation and separate decisions

All eleven preserved-input entries, the seven ordered setup inputs, original
stage-domain separation and real pending receipt bytes are preserved. Envelope
SHA-256 remains `c7748647761bcc9b6f1de4c965e50d6135b9e0a14aba4a95f30a75c728742df5`;
JS lock remains `18ac7c91f854dcd55480dea15b57c52afa0d674863ce4d620221926b99644359`;
pending A1 setup digest remains
`bd2b9e2f476885cf401fec30213cc34d0472f52cba71c7a045a1bb2f617e67c6`.
No expected answer, acceptance threshold or approval receipt is regenerated.

Fable reported no incorrect frozen answers and no disagreements in 62 probes;
those are Fable's reported runs, not executions by this assistant. Preserve its
four frozen-coverage limitations: rejected-draw vector, budget-exhaustion case,
successful item.transfer ordering and root-versus-reaction same-target conflict.
Some adverse paths are only model tests. Scheduler and save-fork/restore
limitations also remain. Fable's tooling installation on the Mac is not candidate
setup evidence. Reviewer attribution remains for the existing owner-approved
process; no new account/signature requirement or self-issued approval is added.

Merge readiness is a separate technical decision based on the corrected exact
head. R0 acceptance, attributable oracle approval and independently reviewed A1
execution setup remain pending; A1 implementation is not authorized. A2 physical
qualification remains later, not a reason to withhold correct checker fixes.
A narrow Fable recheck can cover this correction diff without redoing unchanged
semantic inputs, and must not be claimed to have happened before it does.

The owner's additional cloud-first preference is retained in
[the development direction note](../prep/after-pr-10/cloud-first-development.md).
It proposes the next explicit hosted-A1 amendment without changing the preserved
envelope here. It does not create another UI/platform/infrastructure prerequisite.

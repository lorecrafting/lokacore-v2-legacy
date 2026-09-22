# Fresh-engine playable proof (R6P)

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Proposed R6P work package.

Four-place proof on the fresh engine before the full chapter; not a reduced release or completed build.

<details>
<summary>Sections in this document</summary>

- [Scope stays intact](#scope-stays-intact)
- [Location and prerequisites](#location-and-prerequisites)
- [Concrete proof: The Ferryman's Lantern](#concrete-proof-the-ferrymans-lantern)
- [Implementation tickets and dependency graph](#implementation-tickets-and-dependency-graph)
- [Evidence required to finish R6P](#evidence-required-to-finish-r6p)
- [What follows the proof](#what-follows-the-proof)

</details>
<!-- packet-navigation:end -->

**Status:** proposed implementation work package; not a completed build or R0/R1 acceptance.

## Scope stays intact

The owner confirmed on 2026-09-22 that the first release remains **57 rooms, 10 quests, and two endings**. LLMs may create substantial world content, reason about interactions, propose tests and assist review. This proof is an earlier check of the fresh engine and player interaction, NOT a smaller chapter, a replacement game, an online-only pivot, or a migration of legacy Lokacore code.

There are three distinct artifacts:

| Artifact | Purpose | Not evidence of |
|---|---|---|
| Two-room R1/conformance fixture | Semantic and host-boundary feasibility | A pleasant product or a full game engine |
| R6P playable proof | A small coherent experience on the from-scratch engine | A release certificate for chapter one |
| Full chapter one (R10/R12) | The intended first player release | Paid-purchase validation until R13 is exercised |

## Location and prerequisites

R1 lives in a disposable workspace. After explicit R0 acceptance, R1 selection and R2 cutover, production implementation lives in the **new repository**. Do not patch or import legacy engine modules, compatibility shims, server actions, or UI stores to make the proof work. Lokacore remains specification/provenance; the checks committed here are a small specification model, not the production engine.

R6P needs the constitutional contracts, the minimal compiler/local authority/SQLite path, and only the selected early R7/R8 narrative/schedule slices in `release-scope.json`. It does not wait for every feature in R7/R8, Builder generalization, purchases, Foundry, or production Realm authority. Subsequent capability work must keep the proof green.

## Concrete proof: The Ferryman's Lantern

Use a separate pre-release cartridge ID and save lineage, with four connected places (landing, green, reed bank, lantern shelter), Bram, one lantern, one offered quest, one schedule, and one consequential choice. This is a proof fixture, not a revision to Ashmere's chapter-one map or canon.

The player talks to Bram, accepts before the acquisition objective, retrieves the lantern, and chooses whether to carry it along the bank or leave it with Bram's search party. Both outcomes visibly alter a typed fact, a description, and available dialogue. Bram's schedule provides one time-dependent interaction without a population/commerce framework. A simple barrier can exercise an unavailable action. The proof uses real, short, readable prose and touch actions, not only a debug command prompt.

Illustrative opening text (replace through ordinary content review):

> Bram steadies the ferry with his boot. Across the water, a lantern swings once between the reeds and goes dark. "Mine is up at the shelter," he says. "Bring it down. Then tell me whether you are coming with us."

No new general scripting, dream-space runtime, combat, economy, or party system is required for this proof. Those chapter-one features still arrive before their full-release gate. Reuse is earned through typed capabilities, not a special `FerrymanEngine`.

## Implementation tickets and dependency graph

| Ticket | Depends on | Deliverable and acceptance |
|---|---|---|
| P1 Identity/outcome adapter | R0/R1/R2 + constitutional contracts | Stable intent/command identity; failure/rejection distinction; exact fixture results on selected host paths |
| P2 Atomic local authority | P1 | SQLite attempt + receipt + RNG commit; definite rollback and uncertain-COMMIT recovery; serialized admission |
| P3 Compiled proof content | Minimal R4 + P1 | Four-place immutable artifact; validated references, choices, quest activation, schedule and capability lock |
| P4 Narrative/world interaction | P2/P3 + selected early R7/R8 slices | Quest/fact/reaction in one proposal; one durable choice and schedule; no pre-commit effects |
| P5 Touch-first mobile path | P4 + R1/R2 mobile integration | GameView render, ActionInvocation input, clear unavailable-action feedback, readable current state |
| P6 Adversarial/device proof | P5 | Per-boundary crash/retry tests, airplane-mode resume, numeric/state parity and actual human device feedback |

P1/P2 do not authorize the legacy repository to grow a production engine. The dependency graph is imported with the accepted packet into the fresh implementation repository.

## Evidence required to finish R6P

A non-developer can complete each choice path using touch, explain its consequence, quit at a choice, and resume in airplane mode without developer instructions. Record confusing interactions and authoring effort; do not equate an LLM playthrough with human readability.

On each supported physical device, record exact build/cartridge hash, OS, device and conformance profile, both path transcripts, save/restore results, and latency/input-responsiveness measurements. Inject failures before and after commit and at narrative presentation boundaries. Lost-response retries must replay the original outcome even when the old target/choice no longer exists. RNG/check failures must not reroll on duplicate delivery.

Run the small implementation-independent known-answer corpus against the actual candidate adapters, not just the Python specification model. A pass in `checks/` only validates the packet/model tests. Per-step mismatch diagnostics must include canonical state/result bytes, not just differing final hashes.

## What follows the proof

Continue directly to the **full chapter-one capability and content set**. LLM-assisted generation may scale once the compiler/validation boundary exists; generated tests remain supplemental to engine invariants and exact-artifact certification. Re-estimate work using observed authoring, correction and review throughput, not old calendar guesses or room count alone.

Story content and Builder work do not require R14/R15 Realm production. A small unrelated cartridge using already-shipped mechanics is the additional R16 reuse test; Ashmere chapters two and three still prove campaign continuity and capability growth.

The free chapter's playable/store release is distinct from the first paid purchase/restore milestone. R13 remains mandatory for paid commerce; it does not block this proof. The downloaded-rule review posture and published save-compatibility policy must be resolved before their applicable release, not assumed from a green proof.

# Fresh-engine playable proof (R6P)

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** R6P work package; readiness direction approved.

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

**Status:** owner-approved readiness direction (2026-09-22), pending amendment review/merge; not a completed build or R0/R1 acceptance.

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

The player talks to Bram, accepts a current-possession objective, retrieves the lantern (or already has it), returns to talk, and chooses whether to carry it along the bank or leave it with Bram's search party. The quest remains active until that choice resolves it. Both choices require current lantern custody and Bram's presence; carrying is a declared terminal commitment, not proof of a later unmodeled journey. Both outcomes visibly alter a typed fact, a description, and available dialogue. Bram's schedule provides one time-dependent interaction without a population/commerce framework. A simple barrier can exercise an unavailable action. The proof uses real, short, readable prose and touch actions, not only a debug command prompt.

Illustrative opening text (replace through ordinary content review):

> Bram steadies the ferry with his boot. Across the water, a lantern swings once between the reeds and goes dark. "Mine is up at the shelter," he says. "Bring it down. Then tell me whether you are coming with us."

No new general scripting, dream-space runtime, combat, economy, or party system is required for this proof. Those chapter-one features still arrive before their full-release gate. Reuse is earned through typed capabilities, not a special `FerrymanEngine`.

### Fixed content intent and expected traces

[Lantern traces](conformance/lantern-traces.json) define prepared four-place examples and full per-step projected semantic state/outcome expectations. These are retained explicit expected values reviewed during the amendment, not a candidate-generated oracle or compiled production cartridge. This assistant authored and self-reviewed them; genuinely independent oracle approval remains PREP-02. The separate two-room Tiny case retains its strict acquisition event and failed-roll semantics.

Ordinary proof actions cost zero logical time; explicit `wait` advances it. Bram is at landing from 06:00 to 19:00 and at green otherwise. This bounded fixture starts at 06:00 and admits waits only through 23:00; it does not claim full multi-day scheduler support. Landing connects north to green, green east to reed bank, reed bank east to lantern shelter, with reciprocal routes. The lantern starts at the shelter. A deliberately blocked west exit at landing advertises unavailable feedback without another room.

Both paths: accept → travel to shelter → take → return → talk → choose. `carry` retains custody and sets `search_plan=player_led`; `leave` transfers to Bram and sets `search_plan=party_led`. Each atomically resolves the quest/choice and stores stable required narration plus a **proof-only** terminal milestone. This is not an account-authorized production onboarding grant.

Adverse paths: acquire before acceptance (state credit); drop after opening choice (custody rejection); wait until Bram moves (presence rejection with close/return path); retry consumed choice after a stale view (receipt replay); alter choice under same ID (integrity conflict); conflict/budget fault (no partial proposal); rollback/unknown COMMIT/after-commit display interruption (durable reconciliation). Local account/report binding is tested with the fake adapter, never with invented authentication evidence.

P4 must integrate the shared operation/reaction evaluator: the deliberately small Python Lantern model is only a specification example and cannot be copied as a special FerrymanEngine. P6 compares actual adapter bytes, narrative continuity and human comprehension against the frozen examples.

## Implementation tickets and dependency graph

| Ticket | Depends on | Deliverable and acceptance |
|---|---|---|
| P1 Identity/outcome adapter | R0/R1/R2 + constitutional contracts | Stable intent/command identity; failure/rejection distinction; exact fixture results on selected host paths |
| P2 Atomic local authority | P1 | SQLite attempt + receipt + RNG commit; definite rollback and uncertain-COMMIT recovery; serialized admission |
| P3 Compiled proof content | Minimal R4 + P1 | Four-place immutable artifact; validated references, choices, quest activation, schedule and capability lock |
| P4 Narrative/world interaction | P2/P3 + selected early R7/R8 slices | Quest/fact/reaction in one proposal; one durable choice and schedule; no pre-commit effects |
| P5 Touch-first mobile path | P4 + R1/R2 mobile integration | GameView render, ActionInvocation input, clear unavailable-action feedback, readable current state |
| P6 Adversarial/device proof | P5 | Per-boundary crash/retry tests, airplane-mode resume, numeric/state parity and actual human device feedback |

P2/P6 also exercise atomic milestone capture, offline completion and delayed authenticated synchronization through a fake progress adapter, including duplicate delivery and account switching. Production authentication/PostgreSQL/API work belongs to R12A before the public release; it does not block R6P.

P1/P2 do not authorize the legacy repository to grow a production engine. The dependency graph is imported with the accepted packet into the fresh implementation repository.

## Evidence required to finish R6P

A non-developer can complete each choice path using touch, explain its consequence, quit at a choice, and resume in airplane mode without developer instructions. Record confusing interactions and authoring effort; do not equate an LLM playthrough with human readability.

On each supported physical device, record exact build/cartridge hash, OS, device and conformance profile, both path transcripts, save/restore results, and latency/input-responsiveness measurements. Inject failures before and after commit and at narrative presentation boundaries. Lost-response retries must replay the original outcome even when the old target/choice no longer exists. RNG/check failures must not reroll on duplicate delivery.

Run the small implementation-independent known-answer corpus against the actual candidate adapters, not just the Python specification model. A pass in `checks/` only validates the packet/model tests. Per-step mismatch diagnostics must include canonical state/result bytes, not just differing final hashes.

## What follows the proof

Continue directly to the **full chapter-one capability and content set**. LLM-assisted generation may scale once the compiler/validation boundary exists; generated tests remain supplemental to engine invariants and exact-artifact certification. Re-estimate work using observed authoring, correction and review throughput, not old calendar guesses or room count alone.

Story content and Builder work do not require R14/R15 Realm production. A small unrelated cartridge using already-shipped mechanics is the additional R16 reuse test; Ashmere chapters two and three still prove campaign continuity and capability growth.

The free chapter's playable/store release is distinct from the first paid purchase/restore milestone. R12A accounts/progress is mandatory for the first free public release. R13 remains mandatory for paid commerce; neither production service blocks this proof. The downloaded-rule review posture and published save-compatibility policy must be resolved before their applicable release, not assumed from a green proof.

# Loka v3 — Implementation Index

The R0 compact architecture and invariant index (README §12). This is a routing summary, not a replacement contract. Governing sections and executable schemas/fixtures retain detail; a summary that contradicts them is a defect, not an alternative implementation choice. Scope: what an implementer of **chapter one** (`00a-chapter-one-content.md`) must know. Limits: under 10k tokens, 39 navigation concepts (not a count of all implementation complexity; capability and scenario IDs are indexed separately).

## 1. Provenance

| Item | Value |
|---|---|
| Packet state | Draft 0.5 with audit corrections; R0 acceptance pending; baseline `1f5f32c` |
| Normative architecture | docs 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 19, 21; accepted ADRs in doc 16 (README §8) |
| Normative content pull list | doc 00 (§11 ladder), doc 00a (chapter one) |
| Normative gates | doc 14 (phases), doc 15 (scenarios) |
| Informative/reference | docs 12, 13, 17, 18, 20, 22; index summaries do not override governing contracts |
| ADR state | 51 accepted (incl. "accepted direction"), 4 provisional (004, 005, 023, 035), 3 deferred (018, 024, 025), 4 rejected (011, 020, 021, 030) |
| Open evidence gates | §7 below |
| Known spec defects | doc 18 §33.1, §33.2 (resolved 2026-09-21; see §33 for the amendments) |
| Cutover rule | after R2 imports this packet, the fresh repository is the only normative authority (ADR-062, ARCH-13) |

## 2. Pipeline

Every authoritative gameplay mutation converges on this spine (README §2). Adapters MAY collapse steps; they MUST NOT collapse semantic boundaries.

```text
touch/text/player-agent/test-bot
  -> ActionInvocation
  -> authorize + recognize receipt (matching retry returns prior outcome)
  -> NEW attempt: authority re-resolves + revalidates
  -> typed semantic Command
                         \
scheduler / durable job  \
BehaviorIntent arbitration -> typed internal Command
Population reconciliation  /
world-event/system trigger /
                         /
  -> DecisionCoordinator / portable decision layer
  -> StateDelta + DomainEvents + Effects
  -> authoritative commit + receipt/outbox
  -> committed state
  -> GameView projection
  -> client presentation
```

## 3. Vocabulary

| # | Concept | One line | Where |
|---|---|---|---|
| 1 | **ActionInvocation** | host-neutral intent from UI/text/bot naming an advertised action; not yet a Command | 04 §1 |
| 2 | **Command** | authority-side typed request; origin is invocation-derived or authority-internal (job, Behavior, population, world event) | 04 §1 |
| 3 | **StateDelta** | typed non-committed proposal of same-authority state change; registered ops, canonical targets | 04 §1, §5.1 |
| 4 | **DomainEvent** | typed fact produced by a decision; committed-observable only after commit | 04 §1, §8 |
| 5 | **Effect** | post-decision instruction (notify, enqueue, cross-authority request); never a state-write path | 04 §1, §10 |
| 6 | **GameView** | semantic projection of committed state for one viewer; carries available actions | 04 §14–16 |
| 7 | **mutation owner** | the one serialized owner of a mutable state domain; Story: `LocalInstanceAuthority`; SQLite/PostgreSQL record commits but decide nothing | README §2; 01 A1 |
| 8 | **GameSession adapter** | UI-facing session; `LocalStorySession` delegates to local authority; `RemoteRealmSession` is transport only (deferred) | README §2; 07 §2 |
| 9 | **authority revision** | monotonic version of committed authoritative state | 03 §19 |
| 10 | **command receipt** | durable `(idempotency_scope, command_id)` record with digest and stable response; scope outlives session and owner | 03 §14 |
| 11 | **view token** | client freshness token on one projected stream; not the authority revision | 04 §16 |
| 12 | **state scope** | who owns a fact/progression: player, party, instance, realm; independent of audience, capacity, placement | 01 C4; 03 §6 |
| 13 | **decision environment** | inputs to `decide`: definitions, committed state, logical clock, RNG state, IdSource, budget | 04 §4; 07 §5 |
| 14 | **Snapshot** | versioned capture sufficient to recreate an instance: revision, release hash, clock, RNG, entities, scoped state, jobs | 03 §18 |
| 15 | **effect outbox** | durable at-least-once queue for effects that cannot run inside the commit transaction | 03 §16 |
| 16 | **cartridge** | immutable, content-addressed, certified content release with an exact capability lock | 05 §1, §20 |
| 17 | **capability** | versioned engine semantic (`movement@1`); `portable` or `server_only`; registry is closed, composition is open | 05 §6; 21 §1 |
| 18 | **ActivationGroup** | manifest-selected set of rooms/exits; chapters differ only by active groups | 00a §3; 06 §12 |
| 19 | **campaign continuity** | declared export/import keys and a character schema; the only state that crosses cartridges | 07 §15; 00a §1 |
| 20 | **Definition / RuntimeEntity** | immutable compiled content vs mutable instance holding a DefinitionRef; never the same row | 03 §2–3; 05 §15 |
| 21 | **containment** | one `container_id` relation per entity; inventory is a query; equipment is a slot assignment | 03 §23 |
| 22 | **Fact** | typed, scoped, defaulted durable narrative truth; events and typed consequences also coordinate systems | 03 §7; 06 §11 |
| 23 | **Quest** | pure reducer over canonical events, including in-decision proposed events; results become authoritative only with commit | 06 §1–5, §10 |
| 24 | **Dialogue** | node graph with conditional choices; a choice is an ActionInvocation validated against the current node | 06 §17–18 |
| 25 | **SceneSequence** | durable, checkpointed narrative orchestration; beats are narration, choice, consequence | 06 §33–38 |
| 26 | **InstancePlan** | scoped temporary spatial simulation (dream, overlay) with explicit export policy | 19 §9; 06 §36 |
| 27 | **ActionSet** | the actions available to an actor now, computed by the authority from base set plus Policy operators | 06 §19 |
| 28 | **ActionRecipe** | builder-composed verb: target spec, checks, costs, consequences; no engine code | 21 §7 |
| 29 | **Policy** | versioned condition tree over facts, state, scope; fails closed on unknown nodes | 06 §21 |
| 30 | **TargetResolution** | deterministic search returning `none`, `unique`, or `ambiguous` with candidates | 04 §18; 21 §7 |
| 31 | **ReactionRule** | typed event-pattern rule over the proposal overlay; registered consequences join the bounded atomic decision | 06 §14; 21 §11 |
| 32 | **Behavior** | NPC state machine emitting BehaviorIntents; deterministic arbitration produces internal Commands | 21 §10; 06 §13 |
| 33 | **durable job** | persisted scheduled Command with explicit time basis; one of three temporal strategies (derived, durable, ephemeral) | 02 §11 |
| 34 | **PopulationPlan** | bounded, scoped spawn policy with SpawnBundles, respawn, provenance-safe cleanup | 21 §12 |
| 35 | **Connection / Barrier** | directed/undirected traversable relation; bidirectional faces share Barrier state; Ashmere uses six-direction reciprocal exits | 21 §5; 05 §17 |
| 36 | **InspectableDetail** | described feature of a room or entity without its own RuntimeEntity; variants select by Policy | 21 §6 |
| 37 | **execution profile** | how a deployment is hosted: `offline_private` (chapter one), `online_private`, `party`, `shared_area` | README §2; 07 §3 |
| 38 | **Builder target** | authoring constraint set: `story` (chapter one), `realm`, `promote` | 08 §2 |
| 39 | **certificate** | Lab evidence bound to one frozen artifact hash for one profile; chapter one's gates are 09 §1a | 09 §21, §25 |

## 4. Invariants

One line each. Columns: governing section, ADR, acceptance scenarios that test it.

### Authority

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| A1 | One mutation owner per state domain; the durable store never decides | 01 A1; 03 §1 | 007 | ARCH-06, ARCH-07, MODE-03 |
| A2 | Every authoritative mutation follows §2; steps may collapse, boundaries may not | README §2; 04 §1 | 009 | ACT-07, ARCH-06 |
| A3 | UI/text/bots emit ActionInvocation; authorize receipt access first; matching retries replay; NEW attempts re-resolve current legality/freshness | 04 §1–2 | 009 | ACT-09, ACT-10, MODE-04 |
| A4 | Authority-internal Commands are registered variants with stable causation/idempotency on the same decide/commit path | 04 §1 | 052 | BEHAVIOR-01, POP-01, SERVICE-03 |
| A5 | Decision output is provisional; rejection/definite rollback discards it; failed attempts commit; uncertain commits reconcile before reevaluation | 04 §5.1; 07 §6 | 059 | ARCH-09, DET-09, DET-10 |
| A6 | StateDelta ops are registered, canonically targeted, registry-ordered; two writes to one target need a composition rule or the decision fails; no last-writer-wins | 04 §5.1 | 059 | ARCH-10 |
| A7 | Effects cross a post-decision boundary; same-domain change is StateDelta, never an Effect | 04 §1, §10 | 009 | ARCH-06 |
| A8 | Domain rules import no Ecto/Repo/Phoenix/PubSub/filesystem/HTTP/wall clock/global RNG; PubSub is fan-out, not authority | 01 A3, A4, B4; 07 §5 | 002 | ARCH-01, ARCH-02, ARCH-03 |
| A9 | Story Mode runs `LocalStorySession` → `LocalInstanceAuthority` with no online dependency; Realm code never touches Story saves | 07 §2; 10 §1 | 037 | MODE-01, MODE-06, MODE-07 |
| A10 | Unknown capability, Policy node, Effect kind, reference, or protocol variant fails validation | 01 A7 | 013 | DET-05, ACT-06, CAR-02, CERT-17 |

### Determinism

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| D1 | Determinism includes representation: canonical map order and serialization, fixed RNG algorithm, IdSource-derived ids, integer/fixed-point rule math, stable tie-breaks | 01 A8; 09 §2–4 | 004 | DET-01, DET-02, DET-06, DET-07, DET-08 |
| D2 | Logical clock and RNG state enter through the decision environment; wall clock and host entropy never do | 01 A6; 07 §5 | 031 | DET-03, DET-04, WORLD-07 |
| D3 | Real-elapsed Story time enters as one idempotent authority input, capped per resume | 07 §10 | 049 | OFF-08, OFF-09, OFF-13 |
| D4 | The same cartridge trace hash on every host; a portable capability with a single-host implementation is rejected | 07 §13–14; 09 §5 | 060 | DET-02, ARCH-12 |
| D5 | Fault handling follows the host/fault class in the R1 envelope; no partial commit; fatal-process recovery and diagnostic limits are explicit | 11 §7; 09 §2 | 033 | DET-11, OFF-03, OFF-07 |

### Persistence

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| P1 | Every state-changing Command has a receipt identity that outlives session, process, and owner; same digest replays the stored response; different digest is an integrity conflict | 03 §14 | 010, 058 | OFF-05, INV-03, ACT-11, ACT-13, RECEIPT-01, RECEIPT-02, RECEIPT-03 |
| P2 | Commit is one transaction: receipt lookup, revision check, apply, receipt + trace + outbox insert; memory adopts state only after COMMIT | 03 §15 | 010 | OFF-03, OFF-04, INV-02, QST-07 |
| P3 | Authority revision is monotonic; view token is a separate freshness token | 03 §19; 04 §16 | 047 | PROTO-03, PROTO-04, ACT-10 |
| P4 | Current durable state is authoritative; trace is diagnostics, not event sourcing; a Snapshot boots an instance | 03 §17–18 | 011 (rejected) | OFF-07, CERT-08 |
| P5 | One containment relation per entity; no dual truth for location and inventory | 03 §23 | 029 | INV-01, INV-04, INV-06, INV-07 |
| P6 | Outbox delivery is at-least-once; receivers dedupe by idempotency key; a failed required effect is never dropped | 03 §16 | 010 | ONL-04, QST-26 |
| P7 | Offline saves carry lineage; divergent branches are never auto-merged; offline state never imports into Realm authority | 03 §25; 07 §22 | 027 | OFF-10, MMO-03, ENTITLEMENT-01 |
| P8 | App/kernel updates preserve installed-save access under the published compatibility policy; required local migrations are rollback-safe | 10 §22, §28 | 022 | COMPAT-01, COMPAT-02, COMPAT-03, COMPAT-07, MODE-09, OFF-11 |

### Content and cartridge

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| C1 | Definition and RuntimeEntity are distinct; canonical definition identity includes cartridge id and version | 03 §2–3; 05 §4, §15 | 008 | CAR-01, CAR-09 |
| C2 | Templates flatten at compile time; runtime never chases inheritance | 05 §9 | 030 (rejected) | CAR-03 |
| C3 | Same source compiles to the same artifact hash; the artifact is immutable; certificate and signature do not change semantic identity | 05 §12, §20 | 022 | CAR-04, CAR-05, CAR-10, COMP-04 |
| C4 | The capability lock is exact; `story` target and `offline_private` reject any `server_only` capability; chapter one's lock is 00a §1 | 05 §6; 07 §12; 08 §2 | 013, 038 | BUILDTARGET-01, SCR-09, CAR-07 |
| C5 | Content gains expressivity only by composition; no hidden persistence, host callbacks, second mutation authority, `Code.eval_string`, or arbitrary downloaded native/JavaScript modules; bounded rule IR remains store-review gated | 01 P2a; 21 §1; 10 §14 | 050, 018 | ARCH-04, ARCH-08, ACTIONRECIPE-01 |
| C6 | ActivationGroups select the active map; reachability, reciprocity, and barrier coherence are checked over the active set | 00a §3; 06 §12 | 034 | QST-19, QST-27, BARRIER-01 |
| C7 | No cross-cartridge runtime dependency; continuity crosses only through declared exports/imports with defaults | 05 §13; 07 §15 | 015 | COMP-01, COMP-04, MMO-04 |
| C8 | Every scoped truth declares a state scope; scope is ownership, independent of audience, capacity, and placement | 01 C4; 03 §6 | 012, 046 | SCOPE-01, QST-20, ARCH-11 |
| C9 | Localization keys, asset hashes, references, and unknown fields are checked statically; a missing locale fails | 05 §11, §18; 09 §8 | 013 | CAR-06, CAR-02 |

### Narrative

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| N1 | Quest reducers may consume proposed in-decision events; only commit makes results authoritative; no implicit pre-activation credit; delivery is idempotent | 06 §1, §5 | 017 | QST-05, QST-06, QST-30 |
| N2 | Rewards and consequences apply exactly once, keyed by quest instance, completion revision, and reward key | 06 §6, §10 | 040 | QST-07, QST-23, SCENE-02 |
| N3 | Quests change the world only through typed consequences and Facts; consequence scope never widens implicitly | 06 §10–11, §15 | 040, 041, 055 | QST-21, QST-24, QST-25, QUESTSCENE-02 |
| N4 | A Dialogue choice is validated against the current node and committed state; stale or knowledge-leaking choices reject; state survives restore | 06 §17–18 | 016 | DIA-01, DIA-02, DIA-04, DIA-06 |
| N5 | A SceneSequence is durable and checkpointed; each choice or consequence beat applies once across crash and restore; skip preserves consequences | 06 §33–38 | 054 | SCENE-01, SCENE-02, SCENE-03, SCENE-04, QUESTSCENE-01 |
| N6 | An InstancePlan (dream) isolates its state and exports only through its declared contract | 19 §9; 06 §36 | 057 | DREAM-01, DREAM-02, INSTANCEPLAN-06 |
| N7 | The authority computes the ActionSet from base set plus Policy operators; touch and text resolve to the same invocation | 06 §19–20; 01 P4 | 016 | ACT-01, ACT-02, ACT-03, ACT-04, ACT-05, ACT-07, TARGET-02 |
| N8 | TargetResolution is deterministic and returns `none`, `unique`, or `ambiguous`; ambiguity is data | 04 §18; 21 §7 | 051 | ACT-08, TARGET-01 |
| N9 | Facts are typed/scoped/defaulted durable truth; canonical events and registered consequences are also explicit coordination channels | 03 §7; 06 §11 | 041 | QST-21, QST-22 |

### Living world

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| W1 | Connections may be directed/undirected; bidirectional Barrier faces share state. Six-direction reciprocal exits are Ashmere content policy, not a universal engine limit | 21 §5; 05 §17; 00 §4.1 | 051 | BARRIER-01, WORLD-02 |
| W2 | Side-effect-free temporal views derive from persisted baseline and logical time; side-effecting deadlines use durable jobs; ephemeral timers are recreated | 02 §11; 21 §28 | 031 | WORLD-06, WORLD-07, QST-09 |
| W3 | Behaviors emit intents; arbitration is deterministic; nothing wanders implicitly; schedules move NPCs through internal Commands | 21 §10; 06 §13 | 052 | BEHAVIOR-01, BEHAVIOR-02, WORLD-01, WORLD-03 |
| W4 | PopulationPlan counts never exceed cap per scope; cleanup is provenance-safe; SpawnBundles nest explicitly | 21 §12 | 052 | POP-01, POP-02, POP-03, WORLD-05 |
| W5 | ReactionRule chains are typed and bounded; a reaction is a registered rule, not special-case code | 06 §14; 21 §11 | 042 | REACT-01, REACT-02 |
| W6 | InspectableDetail is content, not an entity; description variants select by Policy | 21 §6 | 051 | DETAIL-01 |
| W7 | Commerce is one atomic typed transaction with conservation; stock never goes negative | 21 §13 | 053 | COMMERCE-01, COMMERCE-02 |
| W8 | Learn-by-doing increments only inside a committed successful check, bounded per world day; sense cues, poses, topics, collections are projection or player-scoped Facts, never hidden authority | 21 §28 | 050 | NARRATE-01 |

### Mobile and release

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| M1 | One React Native app; exactly one active gameplay authority; Story Mode works with no network from launch | 10 §1, §4; 07 §2 | 037 | OFF-01, OFF-02, MODE-01, MODE-02, MODE-03, MODE-05 |
| M2 | Durably commit each authoritative attempt; restart recovers the last commit and matching receipts; full snapshot export is not required on every action | 00 §1; 07 §9 | 003 | OFF-03, OFF-04, OFF-05, OFF-06, OFF-07, INV-02 |
| M3 | Downloaded content is declarative data over shipped capabilities; the kernel ships in the reviewed binary; package integrity and signature are verified before load | 10 §14–15; 07 §27; 11 §8–9 | 035 | PAY-04, CAR-08, COMPAT-04, COMPAT-05, COMPAT-06 |
| M4 | Entitlement is account/platform state, never a character field; offline play continues under the declared policy | 10 §9, §11 | 027, 039 | SES-04, PAY-01, PAY-02, PAY-03, PLATFORM-01 |

### Specification

| # | Invariant | Doc § | ADR | Scenarios |
|---|---|---|---|---|
| S1 | Two normative documents disagreeing is a defect; stop at the boundary and record in doc 18; never pick a side | README §8 | 062 | ARCH-13 |
| S2 | R3A machine-readable schemas are the executable truth for their contracts; prose is checked against them; no handwritten duplicate catalogs | 01 A5; 14 R3 | 062 | PROTO-01, ARCH-12 |
| S3 | Deterministic gates decide correctness; a model opinion cannot waive a failed invariant; cartridge-authored tests supplement, never replace, gates | 01 AI2; 09 §33, §37 | 061 | CERT-06, CERT-13, CERT-15 |

## 5. Chapter ladder

Source: 00 §11. Each chapter is a complete cartridge with its own `offline_private` certificate and store entry; shared source under `cartridges/ashmere/`, per-chapter manifests select ActivationGroups.

| Chapter | Areas | Rooms | Levels | Mechanic tier adds | Quests | Sizing |
|---|---|---|---|---|---|---|
| 1 — The Missing Child (R10, free) | Ashmere, the Fen, Priory public rooms | 57 | z−2 to z+3 | six exits, doors/keys, tides, light, water rooms, details, variants, sense cues; day/night, shop hours, cooldowns, inn rest; 4 ancestries, 6 stats, levels 1–5, 6 skills learn-by-doing; 14 slots, stacking, liquids, readables, corpses; melee rounds, flee, wimpy, bleed/poison, death + shrine respawn; one shop, inn, ferry; schedules, patrol, wander, guard, scavenge, topics, rumors, one faction axis, 4 populations, reactive world; all quest operators, scenes, dream, riddles, continuity export; full touch UI | Q1–Q3, S1–S4, S9, S10, S27 | 9 to 14 months from R1 |
| 2 — The Barrow King (R16, paid) | + crypt, ossuary, priory gate, Barrow Downs | 77 | z−3 to z+3 | hidden exits, traps, climbing, moon portal, scan; moon, weather, `real_elapsed`, Wight Night; guilds, levels to 10, spell words, stances, collection, ironman; durability, affects, cursed, identify; ghost/resurrection, specials, dual wield, hireling, boss phases, hunt, sanctuary, pets; second shop, healer, trainers; 3 faction tracks, drives, NPC memory, permanent death | Q4, S7, S8, S12, S13, S20, S21, S25, S26, S28 | 4 to 7 months after ch. 1 |
| 3 — The King's Road (R16, paid) | + King's Road, Harrowgate, mine | 109 | z−3 to z+3 | mounts, cart, terrain, toll; seasons, events, Lantern Night; two more guilds, levels to 15, remaining skills; repair, forging, quality, tools; ranged, backstab, disarm; full economy, bank, haggle, stables, smithy, housing, mail; crime, witnesses, wanted, arrest, trial, jail, fence, disguise | Q5, S5, S6, S11, S14–S19, S22–S24 | 5 to 8 months after ch. 2 |

Ladder rules: full chapter-one scope stays intact; R6P is a separate early proof. Use `release-scope.md` for capability/gate applicability. Save support follows document 10 §28. Three chapter artifacts remain separate. R16 adds an unrelated reuse fixture; R9C is conformance, not diversity evidence.

## 6. Phase gates

Source: 14. Sizing values are historical estimates, not promises or acceptance criteria; re-estimate from R1/R6P and measured LLM-assisted authoring/review throughput.

| Phase | Gate (what must be true) | Sizing |
|---|---|---|
| R0 Spec acceptance | no unresolved contradiction on the Gate R0 list; commit hash, normative file set, ADR states, evidence gates, this index, cutover rule recorded | — |
| R1 Kernel spike | ADR selects the portable execution strategy against `r1-acceptance-envelope.md`; A first, B and C only if A fails | 3 to 5 days (A); 3 to 6 weeks (B) |
| R2 Fresh repo | empty-system CI green on Elixir, TypeScript, the R1 choice, and its mobile path; packet imported; cutover effective | R2–R6: 8 to 12 weeks |
| R3 Contracts | R3A constitutional registries generate Elixir and TypeScript types, fixtures, and the residency matrix; delta conflict and proposed-event containment proved; R3B envelopes reserved, not frozen | (in R2–R6) |
| R4 Compiler v1 | same source → identical hash; broken refs, cycles, unknown capabilities fail deterministically; 00a §12 compiles | (in R2–R6) |
| R5 Portable world rules | golden vectors pass through the R1 implementation on every host path; v1 ActionRecipe/Detail/Connection/Barrier frozen | (in R2–R6) |
| R6 Offline authority + save | airplane mode: start tiny cartridge, play, kill during actions, resume, finish, no corruption | (in R2–R6) |
| R6P Early fresh-engine proof | four-place touch-first proof, choice/schedule, local commit/retry/recovery, actual device/human evidence; NOT the full release | evidence-gated |
| R7 Quest, dialogue, scenes | Lokacore quest-bug regression cannot reproduce; a quest drives a durable scene with choice, crash checkpoint, and exactly-once consequences; chapter-one dream proves overlay; InstancePlan only when pulled; no LokaScript | 4 to 6 weeks |
| R8 Living world (ch. 1 tier) | 30 simulated days: bounded jobs, populations, reaction chains; deterministic arbitration and replay; NPCs reach schedules | 4 to 6 weeks |
| R9 Lab v1 (09 §1a minimum) | every injected failure yields a one-command repro; a broken mini-cartridge is caught; coverage and evidence bundle export | R9 + R9C: 4 to 6 weeks |
| R9C Conformance cartridge | synthetic cartridge passes `offline_private` conformance, crash/retry, coverage; becomes the standing regression corpus | (with R9) |
| R10 Chapter one | full `offline_private` certificate per 09 §1a and 00a §11, plus developer-harness device smoke; authoring pain recorded for R11 | 6 to 10 weeks |
| R12 Production Story Mode | a non-developer installs, plays in airplane mode, finishes, resumes after restart, uses save UX | 6 to 10 weeks |
| R13 Commerce | store sandbox on both platforms: purchase, download, airplane, reinstall/restore, second device, refund | 3 to 5 weeks |
| **Full free chapter one in the store** | R10 + R12 + applicable release gates; R13 before paid commerce | historical estimate; recalibrate after R6P |
| R11 Builder v1 | an agent recreates R10 content through Builder tools only | 4 to 8 weeks |
| R16 Factory/reuse | R11 plus Story authoring/certification; chapters two/three and unrelated reuse fixture; no Realm dependency | measured authoring evidence |
| R14–R22 Realm (excluding R16) | online authority, deployments, party, social shell, instanced regions, shards, promotion, MMO | separate dependency track |

## 7. Open evidence gates

Implementation MUST NOT treat these as settled.

- **R1 / ADR-004 / ADR-005** — portable kernel strategy and mobile binding; decided by the spike against the frozen envelope.
- **ADR-035** — App Store treatment of downloadable rule content; a store-review position is required before first submission. Chapter one is declarative data only (ADR-018 deferred).
- **R20 / ADR-025 / ADR-048 / ADR-058** — ownership placement, fencing, handoff, and migration-stable receipt routing for partitioned Realm play; not needed before chapter one ships.

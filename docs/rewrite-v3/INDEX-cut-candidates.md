# INDEX cut candidates

Sections of the normative packet that INDEX.md could not state. Listing is not deletion; each entry needs review. Missing an index summary does not make an invariant optional. In particular, error/numeric/receipt/causation/activation semantics cannot be cut as mere implementation detail; follow the corrected governing contracts and release matrix. Built from INDEX.md at the same commit.

## 01 — Core principles

| Section | Title | Reason | Note |
|---|---|---|---|
| §6 | Non-goals for v3 foundation | rationale | Scope framing; nothing an implementer can check. |

## 02 — BEAM runtime architecture

| Section | Title | Reason | Note |
|---|---|---|---|
| §1 | Proposed repository shape | implementation choice | Directory layout; the R2 gate only requires green CI. |
| §2 | Supervision topology | implementation choice | OTP tree shape for the online host. |
| §3 | Offline versus online authority | duplicate | Restates A9 and 07 §2. |
| §4 | Session, account, character, instance | later phase | R14; Story has one local character, no account. |
| §5 | Online private/party world owner | later phase | R14 and R17. |
| §6 | Why not one GenServer per entity by default | rationale | Argument against a design v3 does not adopt. |
| §7 | Shared MUD evolution | later phase | R18 through R22. |
| §8 | BEAM distribution | later phase | R20 shards. |
| §9 | Gateway/runtime separation | later phase | R14 online gateway. |
| §10 | Restart behavior | duplicate | P2 commit rule and M2 resume already state it. |
| §12 | Backpressure and overload | later phase | R14; one local authority has no gateway queue. |
| §13 | BEAM-specific review questions | rationale | Checklist for proposing a process. |

## 03 — Domain state and persistence

| Section | Title | Reason | Note |
|---|---|---|---|
| §4 | Component state | schema detail | Component contract fields; R3A registries own them. |
| §5 | Persistent vs ephemeral state | rationale | Classification guidance for authors, not a rule. |
| §8 | Persistence by authority host | implementation choice | PostgreSQL versus SQLite per host. |
| §9 | Proposed online durable schema families | schema detail | Logical online tables; migrations own the shape. |
| §10 | World instance row | schema detail | Field list; R3A and migrations own it. |
| §11 | Runtime entity rows | schema detail | Field list; R3A and migrations own it. |
| §12 | Quest instance rows | schema detail | Field list; R3A and migrations own it. |
| §13 | Scoped facts and durable ServiceJobs | schema detail | Field list; R3A and migrations own it. |
| §20 | Persistence adapters | implementation choice | Port and protocol shapes chosen at R6. |
| §21 | Migration rules | implementation choice | Deploy-time database procedure. |
| §22 | Deletion semantics | duplicate | C3 immutability and P5 containment cover both halves. |
| §24 | Definition cache | implementation choice | Caching hash-keyed definitions; no semantic effect. |

## 04 — Command, event, effect protocol

| Section | Title | Reason | Note |
|---|---|---|---|
| §3 | Canonical command representation | schema detail | Command struct fields; R3A generates them. |
| §6 | Online hybrid decision coordination | later phase | R14; Story locks out every server_only capability. |
| §7 | Game error taxonomy | schema detail | Error code registry; R3A owns it. |
| §9 | Event processing model | duplicate | Bounded reaction chains are W5. |
| §11 | Causation and correlation | schema detail | Correlation and causation id fields; R3A owns them. |
| §12 | Protocol source of truth for online transport | duplicate | S2 already makes schemas the executable truth. |
| §13 | Version negotiation | later phase | R14 online join; 10 §7 holds the client half. |
| §17 | Text commands | duplicate | N7 states text and touch share one invocation. |
| §19 | Action availability | duplicate | Restates 06 §19, indexed as N7. |
| §20 | Protocol tests | duplicate | S2 and the R3 gate already require these fixtures. |
| §21 | Offline command conformance | duplicate | D4 trace hash and the R5 golden vectors. |

## 05 — Cartridges, content, capabilities

| Section | Title | Reason | Note |
|---|---|---|---|
| §2 | Source layout | implementation choice | Recommended source directory form. |
| §3 | Manifest | schema detail | Manifest fields; 00a §1 is the chapter-one instance. |
| §5 | Content envelope | schema detail | Envelope fields; R3A generates them. |
| §7 | Capability discovery API | later phase | R11 Builder tooling. |
| §8 | Compile stages | implementation choice | Pipeline order; the R4 gate states the outcome. |
| §10 | Controlled compiler functions | implementation choice | Optional authoring conveniences at compile time. |
| §14 | Capability packs | implementation choice | Grouping only; individual capability ids stay authoritative. |
| §16 | Spawn model | duplicate | PopulationPlan and SpawnBundles, indexed as W4. |
| §19 | Content migrations | later phase | Needed at a second content release, not chapter one. |
| §21 | Promotion states | later phase | R11 workspace lifecycle. |
| §22 | Cartridge/deployment split | later phase | Deployment overlays first matter at R14. |
| §23 | Cartridge ports and extension points | later phase | Campaign composition; C7 covers chapter one. |
| §24 | Realm-native cartridges and portable Story reuse | later phase | R14 onward. |
| §25 | Composable world-primitive contract | duplicate | Pointer to doc 21; C5 states the rule. |

## 06 — Quests, dialogue, actions, scripting

| Section | Title | Reason | Note |
|---|---|---|---|
| §7 | Quest subscriptions/indexing | implementation choice | Index strategy for scale; performance only. |
| §8 | Quest invariants | duplicate | N1 through N3 and the 09 §1a quest gate. |
| §9 | Quest/world contract | duplicate | N3 typed consequences and N9 Facts. |
| §16 | Branches should leave durable world consequences | rationale | Advice on branch quality, not a checkable rule. |
| §22 | Text command parser | duplicate | 04 §17 and N7. |
| §23 | Scripting goals | deferred | ADR-018; chapter one ships no scripts. |
| §24 | LokaScript allowed model | deferred | ADR-018. |
| §25 | Portable script binding registry | deferred | ADR-018. |
| §26 | Script budgets | deferred | ADR-018. |
| §27 | Deterministic scripts | deferred | ADR-018. |
| §28 | Trusted compiled Elixir extensions | implementation choice | Engine-side capability work, not cartridge content. |
| §29 | Script lifecycle | deferred | ADR-018. |
| §30 | Cartridge custom domain events | later phase | R11 script-surface generalization. |
| §31 | State machine use outside quests | implementation choice | Reuse of a shape; no invariant attached. |
| §32 | Quest as the narrative spine | rationale | Explains why quests coordinate rather than own. |
| §39 | Scripted world events and WorldEventPlan | chapter 2/3 | 00 §11 puts world events in chapters two and three. |
| §40 | Multiplayer scene semantics | later phase | R17 party scenes. |
| §41 | Journal, reveal, hints, and story readability | schema detail | Projection metadata; R3B envelopes own the fields. |
| §42 | Narrative robustness and certification | duplicate | 09 §1a quest gate and doc 15 group Y. |

## 07 — Offline storypacks to MMO

| Section | Title | Reason | Note |
|---|---|---|---|
| §1 | Requirement | duplicate | M1 and A9 state offline-first play. |
| §7 | Server execution | later phase | R14 online host. |
| §8 | Offline execution | duplicate | A9 and 07 §2 state the local path. |
| §11 | Offline scripts | deferred | ADR-018. |
| §16 | Cartridge versus deployment | duplicate | Same split as 05 §22. |
| §17 | Three ways a single-player cartridge enters the MMO | later phase | R19 through R21. |
| §18 | Quest design for future reuse | later phase | Realm reuse guidance; C8 covers scope today. |
| §19 | Shared NPC versus personal narrative | later phase | R18 shared world. |
| §20 | Death and permanence | chapter 2/3 | Permanent death and ironman are chapter two. |
| §21 | Economy boundary | later phase | Realm economy trust; P7 states the offline rule. |
| §23 | Online-authoritative cartridge mode | later phase | R15 online_private. |
| §24 | Cloud save for offline storypacks | later phase | Optional convenience after R12; also 10 §17. |
| §25 | Offline entitlement | duplicate | M4 and 10 §11. |
| §26 | Cartridge update while offline | later phase | Second content release; pairs with 05 §19. |
| §28 | Local privacy | later phase | No upload path exists before R12. |
| §29 | Why this still uses BEAM's strengths | rationale | Defends the two-host split. |
| §30 | Product progression | rationale | Roadmap narrative; doc 14 owns phases. |

## 08 — Builder API and AI factory

| Section | Title | Reason | Note |
|---|---|---|---|
| §1 | Core decision | later phase | R11; chapter one is hand-authored. |
| §3 | Workspace-first authoring | later phase | R11. |
| §4 | Builder operation envelope | schema detail | Envelope fields; the R11 schema source generates them. |
| §5 | Operation families | schema detail | Per-family operation shapes; generated at R11. |
| §6 | Structured diagnostics | schema detail | Diagnostic code shapes; generated at R11. |
| §7 | Batch plans | later phase | R11. |
| §8 | Dry run | later phase | R11. |
| §9 | Rename/move must be semantic | later phase | R11. |
| §10 | Terminal adapter | later phase | R11 adapter. |
| §11 | MCP adapter | later phase | R11 adapter. |
| §12 | AI model independence | later phase | R11. |
| §13 | AI authoring workflow | later phase | R11. |
| §14 | Context minimization | later phase | R11. |
| §15 | Primitive proposal workflow | later phase | R11; 21 §24 governs graduation. |
| §16 | AI semantic review contract | later phase | R11; S3 already fixes gate authority. |
| §17 | Audit trail | later phase | R11. |
| §18 | Visual tools | later phase | R11. |
| §19 | Git relationship | implementation choice | Workspace backing store picked at R11. |
| §20 | Factory and runtime separation | later phase | R16. |
| §21 | Builder API schema source | duplicate | S2 already makes schemas the executable truth. |
| §22 | Agent permissions | later phase | R11. |
| §23 | Foundry integration | later phase | R16. |
| §24 | Builder expressive power | duplicate | C5 and 21 §1, closed semantics and open composition. |
| §25 | Foundry/Astra orchestration | later phase | R16. |
| §26 | Capability escalation contract | later phase | R16. |
| §27 | Context routing follows role and escalation | later phase | R16. |
| §28 | Agents-as-tools versus authority handoff | later phase | R16. |
| §29 | Foundry is optional infrastructure | rationale | States the factory is optional; no invariant. |

## 09 — Cartridge Lab and certification

| Section | Title | Reason | Note |
|---|---|---|---|
| §1 | Objective | rationale | Why the Lab exists. |
| §6 | Snapshot and rewind | duplicate | Concept 14 Snapshot, governed by 03 §18. |
| §7 | Trace viewer | implementation choice | A developer tool over the trace P4 defines. |
| §9 | Quest/dialogue model gate | duplicate | §1a states the chapter-one form of this gate. |
| §10 | Property-based tests | implementation choice | A method for reaching the gates, not a gate. |
| §11 | Autonomous world simulation | duplicate | §1a fixes the chapter-one run at 30 logical days. |
| §12 | Bot personas | duplicate | §1a fixes the three chapter-one bots. |
| §13 | Multiplayer race testing | later phase | R17 party interleavings. |
| §14 | Crash/chaos testing | duplicate | §1a scopes it to OFF-03 through OFF-07. |
| §15 | Offline lifecycle testing | duplicate | §1a crash and recovery row; P2 and M2. |
| §16 | Script fuzzing | deferred | ADR-018. |
| §17 | Performance certification | later phase | R12 production shell; §1a excludes load. |
| §18 | Semantic review | duplicate | S3 and 09 §33 state the evidence layer. |
| §19 | Human smoke | duplicate | §1a and the R10/R12 gates already name the smokes. |
| §20 | Certification profiles and Builder targets | duplicate | §1a applies the class; 08 §2 holds the targets. |
| §22 | Regression corpus | duplicate | The R9C gate states the standing corpus. |
| §23 | Shared-area promotion certification | later phase | R21. |
| §24 | Certification pyramid | later phase | §1a says everything from §24 on is later growth. |
| §26 | Coverage manifest | later phase | §1a excludes it beyond bot coverage. |
| §27 | Static graph and model analysis | later phase | Beyond the §1a static and topology gates. |
| §28 | Bounded state exploration and path search | later phase | §1a excludes it. |
| §29 | Invariant registry | duplicate | §1a invariants row; index §4 is the same list. |
| §30 | Mutation-sensitivity testing | later phase | §1a excludes it. |
| §31 | Differential and metamorphic testing | later phase | §1a excludes metamorphic tests. |
| §32 | Adversarial gameplay generation | later phase | Beyond the §1a bot set. |
| §34 | Jev/System-One-style fast semantic triage | later phase | §1a excludes Jev triage. |
| §35 | Release blocker classes | duplicate | S3 already fixes who may waive a failed gate. |
| §36 | Release evidence bundle | duplicate | The R9 gate states evidence bundle export. |
| §38 | Regression ratchet | duplicate | R9C corpus and §22. |
| §39 | Area-level assurance | later phase | §1a excludes area-mounted closure. |
| §40 | Change-impact analysis | later phase | An accelerator over gates chapter one does not run. |
| §41 | Release-candidate soak | later phase | §1a caps chapter one at 30 days. |

## 10 — Mobile, commerce, release

| Section | Title | Reason | Note |
|---|---|---|---|
| §2 | Mobile structure | implementation choice | App module layout. |
| §3 | Online connection lifecycle | later phase | R14 Realm session. |
| §5 | Local state | schema detail | On-device storage fields; the R6 save format owns them. |
| §6 | One app, many cartridges, later Realm Mode | duplicate | M1 states one app, one active authority. |
| §7 | Client/kernel feature negotiation | schema detail | Manifest client_features shape; 00a §1 instantiates it. |
| §8 | Catalog | later phase | R13 store catalog. |
| §10 | Purchase lifecycle | later phase | R13. |
| §12 | Restore/refunds/revocation | later phase | R13. |
| §13 | Initial monetization | rationale | Pricing hypothesis, not an engine rule. |
| §16 | Local package management | later phase | R13 multi-release installs. |
| §17 | Cloud backup | later phase | Optional convenience after R12. |
| §18 | Offline versus online characters | later phase | R14; P7 already states the no-import rule. |
| §19 | Narrative continuity | later phase | Account-level memory sync after R14. |
| §20 | Release environments | implementation choice | Channel setup for dev, stage, production. |
| §21 | Cartridge rollout | later phase | R13 staged rollout. |
| §23 | Mobile CI | implementation choice | Job selection; the R2 gate states green CI. |
| §24 | Deep links | later phase | The text itself marks this later. |
| §25 | Privacy/data minimization | duplicate | 07 §28; no upload path in chapter one. |
| §26 | Current technology feasibility note | rationale | Dated research note; doc 17 holds the baseline. |
| §27 | Store-review gate for downloadable rule content | duplicate | Index §7 records ADR-035 as an open gate. |
| §29 | Account, entitlement, and mode boundary | later phase | R14 accounts; M4 covers entitlement now. |

## 11 — Security, observability, operations

| Section | Title | Reason | Note |
|---|---|---|---|
| §1 | Trust zones | later phase | R14; offline has one local zone. |
| §2 | Online authority checks | later phase | R14 gateway authentication. |
| §3 | Offline trust boundary | duplicate | P7 states offline state never enters Realm authority. |
| §4 | Builder authorization | later phase | R11. |
| §5 | Fail closed | duplicate | A10 states unknown input fails validation. |
| §6 | LokaScript security | deferred | ADR-018. |
| §10 | Secrets | later phase | R14; no server before then. |
| §11 | Observability identity | later phase | R14 online correlation. |
| §12 | Structured logs | implementation choice | Log shape chosen at build time. |
| §13 | Telemetry | implementation choice | Metric selection at build time. |
| §14 | Tracing | later phase | R14 distributed spans. |
| §15 | Game trace store | duplicate | P4 states trace is diagnostics; 09 §7 is the viewer. |
| §16 | Health/readiness | later phase | R14 server endpoints. |
| §17 | Deployment | later phase | R14 topology. |
| §18 | Rolling deploys | later phase | R14. |
| §19 | Backups | later phase | R14 server backups. |
| §20 | Admin operations | later phase | R14 and R18 live operations. |
| §21 | Rate limits and abuse | later phase | R14 gateway. |
| §22 | Crash reporting | implementation choice | Report contents; D5 owns the repro record. |
| §23 | Supply chain | implementation choice | Dependency pinning set at R2. |
| §24 | SLO candidates | later phase | R14 online service targets. |
| §25 | Incident principle | rationale | Operating stance, not an invariant. |

## 14 — Implementation plan

| Section | Title | Reason | Note |
|---|---|---|---|
| R14 | BEAM online authority + Realm Mode skeleton | later phase | R14; starts after chapter one ships. |
| R15 | Online-private deployment | later phase | R15. |
| R16 | Repeatable AI factory | later phase | R16. |
| R17 | Party/co-op instances | later phase | R17. |
| R18 | Realm Mode persistent social shell | later phase | R18. |
| R19 | Instanced story regions in world geography | later phase | R19. |
| R20 | Shared zone/shard architecture | later phase | R20; index §7 keeps its open gates. |
| R21 | Shared-area promotion | later phase | R21. |
| R22 | Persistent text MMORPG expansion | later phase | R22 capability packs. |
| — | Dependency graph | duplicate | Index §6 already orders R0 through R22. |
| — | Issue sizing rule | implementation choice | Ticket granularity convention. |
| — | Agent workflow | implementation choice | Per-ticket process, not an engine rule. |
| — | Shipping rule | rationale | Restates why chapter one ships before the engine. |

## 15 — Acceptance scenarios

| Section | Title | Reason | Note |
|---|---|---|---|
| B | Offline lifecycle | later phase | OFF-12: artifact garbage collection, R13 package management. |
| C | Containment and inventory | later phase | INV-05: two concurrent players, R14. |
| D | Quest correctness | duplicate | QST-01–04, 08, 10, 11, 15, 18, 28, 29: N1–N3 cited by other ids. |
| D | Quest correctness | later phase | QST-12, 13, 14, 16, 17: party, realm, multiplayer credit. |
| E | Dialogue | duplicate | DIA-03, 05: N4 restore and the 09 §1a reachability gate. |
| F | Actions and policy | later phase | ACT-12, 14: Realm forgery and authority handoff. |
| G | Scripting | deferred | SCR-01–08, 10: ADR-018; only SCR-09 is cited. |
| H | Living world and time | duplicate | WORLD-04: derived growth is W2. |
| J | Builder/AI | later phase | BLD-01–09: R11 Builder v1. |
| K | Mobile protocol | later phase | PROTO-02, 05: online version negotiation, R14. |
| L | Online transaction and recovery | later phase | ONL-01, 02, 03, 05, 06: R14. |
| M | Session/account/character | later phase | SES-01, 02, 03: R14 accounts. |
| N | Offline-to-MMO reconciliation | later phase | MMO-01, 02, 05–09: R19 through R21. |
| O | Commerce | later phase | PAY-05: server SKU mapping, R13 backend. |
| P | Operations | later phase | OPS-01–05: R14 server operations. |
| Q | Architecture tests | later phase | ARCH-05: Builder adapter bypass, R11. |
| R | Definition of a regression | rationale | No scenarios; states how the suite should grow. |
| S | Cartridge composition | later phase | COMP-02, 03, 05: campaign ports and MMO mount. |
| U | Receipt and platform boundaries | duplicate | PLATFORM-02: M4 offline entitlement policy. |
| V | Client mode and builder target separation | later phase | MODE-08, 10, BUILDTARGET-02–05: Realm and promote targets. |
| W | Quest sharing, phasing, scarce services | later phase | SCOPE-02–05, PHASE-01–05, INSTANCE-01–03, SERVICE-01–11, MIXED-01–02. |
| X | Composable world primitives | duplicate | ACTIONRECIPE-02, AREA-01, COMMERCE-03: concept 28, C8, W7. |
| Y | Quest scenes, dreams, world events | duplicate | INSTANCEPLAN-01–05, SCENE-05, 06, QUESTSCENE-03, NARRATIVE-TRACE-01: N5, N6, P4. |
| Y | Quest scenes, dreams, world events | chapter 2/3 | WORLDEVENT-01, 02: world events are chapters two and three. |
| Y | Quest scenes, dreams, world events | later phase | SCENE-MP-01: shared scene across shards, R20. |
| Z | Release assurance | later phase | CERT-01–05, 07, 09–12, 14, 16, 18: Lab gates beyond 09 §1a. |
| Z | Release assurance | later phase | FOUNDRY-01–05: R16 factory role boundaries. |

## 19 — Quest sharing, instancing, capacity

| Section | Title | Reason | Note |
|---|---|---|---|
| §1 | Five independent dimensions | duplicate | C8 states scope is independent of audience and placement. |
| §2 | Story Mode tracking | duplicate | A9 and M1; Story has one local player. |
| §3 | Realm Mode progress scopes | later phase | R14 onward. |
| §4 | Objective credit is separate from quest ownership | later phase | R17 shared credit; chapter one has one actor. |
| §5 | Shared world is the default | later phase | R18 shared world. |
| §6 | Scoped overlays and phasing | later phase | R19 phasing. |
| §7 | GameView layering | later phase | R18 composed Realm views. |
| §8 | When to create a private instance | later phase | R17 and R19 selection guidance. |
| §10 | Scarce services are compositions of reusable primitives | later phase | R18 contention; 09 §1a excludes ServiceJobs. |
| §11 | Durable ServiceJobs | later phase | Chapter one's lock has no ServiceJob. |
| §12 | Worked example: the one-sword-per-day smithy | worked example | Illustrates §10 and §11. |
| §13 | Shared service fairness and contention | later phase | R18. |
| §14 | Story Mode service behavior | later phase | Depends on §10 services chapter one does not pull. |
| §15 | Phased quest drops and actors | later phase | R19 phasing. |
| §16 | Personal access versus shared geometry | later phase | R18 shared geometry. |
| §17 | Party resources and rewards | later phase | R17 party. |
| §18 | Builder guidance | later phase | R11 Builder questioning. |
| §19 | Certification requirements | later phase | Gates for sharing models chapter one has none of. |
| §20 | Selection table | later phase | Chooses among R17 to R21 sharing models. |
| §21 | Commerce and services compose but are not the same mechanism | rationale | Distinguishes two composites; W7 states the commerce rule. |

## 21 — Composable world primitives

| Section | Title | Reason | Note |
|---|---|---|---|
| §2 | Where builder expressive power lives | rationale | Explains the layering behind C5. |
| §3 | Expression mechanisms available to builders | duplicate | The mechanisms are concepts 27 to 36 and 05 §6. |
| §4 | Foundation world primitives | duplicate | Candidate list; the locked set is 00a §1. |
| §8 | Item, inventory, equipment, and material primitives | duplicate | P5 containment and concept 21. |
| §9 | Character and embodiment primitives | schema detail | Candidate attribute and resource vocabulary; R3B freezes it. |
| §14 | Service primitives | later phase | Chapter one's lock has no ServiceJob; see 19 §11. |
| §15 | Crafting, gathering, and production primitives | chapter 2/3 | 00 §11 puts forging, repair, and tools in chapter three. |
| §16 | Social-world primitives | schema detail | Relationship and faction field shapes; R3B freezes them. |
| §17 | Environmental and ecological primitives | chapter 2/3 | Weather, seasons, and ecology are chapters two and three. |
| §18 | Narrative primitives | duplicate | Concepts 22 to 25 already name them. |
| §19 | Spatial instance and scene primitives | duplicate | Concept 26 InstancePlan and N6. |
| §20 | Scene and sequence primitives | duplicate | Concept 25 SceneSequence and N5. |
| §21 | WorldEventPlan composite | chapter 2/3 | World events start in chapter two. |
| §22 | Examples of emergent domain composites | worked example | Shows composites built from the primitives. |
| §23 | Builder semantic operations | later phase | R11 intent-level Builder operations. |
| §24 | Primitive graduation rule | rationale | Governs how this document grows, not the engine. |
| §25 | Builder expression test | worked example | Acceptance examples for the primitive layer. |
| §26 | Choosing the right composition shape | rationale | Authoring guidance toward the smallest shape. |
| §27 | Additional immersive-world capability candidates | later phase | Explicitly candidates; §28 holds the ones pulled. |

### 21 §28 rows chapter one does not pull

| Section | Title | Reason | Note |
|---|---|---|---|
| §28 | `mount@1` | chapter 2/3 | 00 §11: mounts are chapter three. |
| §28 | `spell_words@1` | chapter 2/3 | 00 §11: spell words are chapter two. |
| §28 | `stance@1` | chapter 2/3 | 00 §11: stances are chapter two. |
| §28 | `pet@1` | chapter 2/3 | 00 §11: pets are chapter two. |
| §28 | `hunt@1` | chapter 2/3 | 00 §11: mob memory and hunt are chapter two. |
| §28 | `death@1` ghost policy | chapter 2/3 | Ghost, resurrection, ironman are chapter two; ch.1 has corpse and shrine. |
| §28 | `equipment@1` cursed | chapter 2/3 | 00 §11: cursed items and identify are chapter two. |
| §28 | `identity_knowledge@1` | chapter 2/3 | 00 §11: identify is chapter two. |
| §28 | TargetSpec adjacent-room scope | chapter 2/3 | 00 §11: adjacent targeting is chapter two. |
| §28 | `drives@1` | chapter 2/3 | 00 §11: drives are chapter two. |
| §28 | `performance@1` | chapter 2/3 | 00 §11: performance is chapter two. |
| §28 | `quest@1` protect / race | chapter 2/3 | Chapter one pulls survive only; protect and race are chapter two. |
| §28 | `commerce@1` barter | chapter 2/3 | Chapter three per doc 00 §11 (owner decision 2026-09-21); chapter one has no barter mechanic. |
| §28 | `property@1` | chapter 2/3 | 00 §11: housing is chapter three. |
| §28 | `steal@1` | chapter 2/3 | 00 §11: crime is chapter three. |
| §28 | `law@1` | chapter 2/3 | 00 §11: wanted, arrest, trial, jail are chapter three. |
| §28 | `mail@1` | chapter 2/3 | 00 §11: mail is chapter three. |
| §28 | `recognition@1` | chapter 2/3 | 00 §11: recognition and disguise are chapter three. |
| §28 | NPC-to-NPC `commerce@1` job | chapter 2/3 | 00 §11: NPC commerce is chapter three. |
| §28 | `track@1` | chapter 2/3 | 00 §11: track is chapter three. |

## Summary

This list holds 288 rows. By reason class: later phase 130; duplicate 56; chapter 2/3 26; implementation choice 25; rationale 19; schema detail 19; deferred 10; worked example 3. Doc 21 §28 contributes 20 of the chapter 2/3 rows, and doc 15 is counted as 27 group rows rather than individual scenario ids.

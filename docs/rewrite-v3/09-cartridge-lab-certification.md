# 09 — Cartridge Lab and Certification

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: applicable assurance.

Start with section 1a for chapter one. The wider catalog does not require every gate for every profile.

<details>
<summary>Sections in this document</summary>

- [1. Objective](#1-objective)
- [1a. R9 minimum: what chapter one actually requires](#1a-r9-minimum-what-chapter-one-actually-requires)
- [2. Determinism contract](#2-determinism-contract)
- [3. Virtual clock](#3-virtual-clock)
- [4. Deterministic RNG](#4-deterministic-rng)
- [5. Boot modes](#5-boot-modes)
- [6. Snapshot and rewind](#6-snapshot-and-rewind)
- [7. Trace viewer](#7-trace-viewer)
- [8. Static certification gate](#8-static-certification-gate)
- [9. Quest/dialogue model gate](#9-questdialogue-model-gate)
- [10. Property-based tests](#10-property-based-tests)
- [11. Autonomous world simulation](#11-autonomous-world-simulation)
- [12. Bot personas](#12-bot-personas)
- [13. Multiplayer race testing](#13-multiplayer-race-testing)
- [14. Crash/chaos testing](#14-crashchaos-testing)
- [15. Offline lifecycle testing](#15-offline-lifecycle-testing)
- [16. Script fuzzing](#16-script-fuzzing)
- [17. Performance certification](#17-performance-certification)
- [18. Semantic review](#18-semantic-review)
- [19. Human smoke](#19-human-smoke)
- [20. Certification profiles and Builder targets](#20-certification-profiles-and-builder-targets)
- [21. Release certificate](#21-release-certificate)
- [22. Regression corpus](#22-regression-corpus)
- [23. Shared-area promotion certification](#23-shared-area-promotion-certification)
- [24. Certification pyramid: fast preflight to exact-hash release](#24-certification-pyramid-fast-preflight-to-exact-hash-release)
- [25. Freeze first, certify the exact candidate](#25-freeze-first-certify-the-exact-candidate)
- [26. Coverage manifest](#26-coverage-manifest)
- [27. Static graph and model analysis](#27-static-graph-and-model-analysis)
- [28. Bounded state exploration and path search](#28-bounded-state-exploration-and-path-search)
- [29. Invariant registry](#29-invariant-registry)
- [30. Mutation-sensitivity testing](#30-mutation-sensitivity-testing)
- [31. Differential and metamorphic testing](#31-differential-and-metamorphic-testing)
- [32. Adversarial gameplay generation](#32-adversarial-gameplay-generation)
- [33. LLM semantic review as a separate evidence layer](#33-llm-semantic-review-as-a-separate-evidence-layer)
- [34. Jev/System-One-style fast semantic triage](#34-jevsystem-one-style-fast-semantic-triage)
- [35. Release blocker classes](#35-release-blocker-classes)
- [36. Release evidence bundle](#36-release-evidence-bundle)
- [37. Cartridge-authored tests are supplemental, not certification authority](#37-cartridge-authored-tests-are-supplemental-not-certification-authority)
- [38. Regression ratchet](#38-regression-ratchet)
- [39. Area-level assurance: isolate, then mount](#39-area-level-assurance-isolate-then-mount)
- [40. Change-impact analysis accelerates feedback but cannot shrink release truth](#40-change-impact-analysis-accelerates-feedback-but-cannot-shrink-release-truth)
- [41. Release-candidate soak and long-horizon simulation](#41-release-candidate-soak-and-long-horizon-simulation)
- [42. Readiness evidence is not host evidence](#42-readiness-evidence-is-not-host-evidence)

</details>
<!-- packet-navigation:end -->

## 1. Objective

The Cartridge Lab is an executable test environment for a compiled cartridge or candidate shared area.

It uses the same portable semantic contract and R1-selected implementation strategy as production and, where relevant, the same BEAM runtime contracts, with controllable infrastructure adapters.

The Lab is a product feature for developers/agents, not merely an ExUnit helper.

## 1a. R9 minimum: what chapter one actually requires

The rest of this document is the certification design for every profile and level. Chapter one of `00-first-cartridge-design.md` is an `offline_private` cartridge whose capability lock contains no scripts, no ServiceJobs/escrow, no InstancePlan, no party scope, and no cross-authority effects. It DOES include immediate shop/inn/ferry transactions, a scoped-overlay dream, and durable schedule jobs. A broad capability ID alone cannot decide whether all its later feature gates apply. The reviewed planning matrix is `release-scope.json`; production applicability must derive from compiled features and transitive engine-registry dependencies, failing conservative on unknown use. Under the applicability classes in §20, its certificate requires only:

| Gate | What it is for chapter one |
|---|---|
| Static | schema, references, unknown fields, template cycles, capability lock, portability check, localization keys, asset hashes |
| Topology | all 57 rooms reachable under declared scenarios through exits AND transport (the ferry); validate admission/payment/schedule constraints separately from structural connectivity; Ashmere exits reciprocal; barrier faces coherent; no required quest target unreachable |
| Quest/dialogue model | lifecycle transitions, activation/resolution validity, prerequisite cycles, terminal-outcome reachability for both endings, duplicate-event idempotency, reward-once, consequence scope |
| Determinism | DET-01 through DET-10 on the R1-selected hosts; canonical ordering; RNG replay |
| Crash/recovery | OFF-03 through OFF-07 at every commit boundary of every chapter-one command type |
| Bot playthroughs | deterministic paths to both endings plus completionist and duplicate-tapper behaviors; record actual quest outcome/dialogue choice/scene beat coverage and explicit dispositions for uncovered surfaces |
| Autonomous simulation | 30 logical days: schedules reach destinations, populations bounded, no reaction loops, tides and light replay identically |
| Invariants | containment unique, no cycles, one Barrier state, revision monotonic, matching retries replay before freshness checks, accepted failed rolls advance RNG only once, immediate shop/inn/ferry payments and goods conserve under retry/crash |
| Human smoke | developer-harness device smoke at R10; production-shell smoke at R12 |

Not required for chapter one: CoverageManifest beyond the bot coverage above, mutation sensitivity, bounded state exploration, metamorphic tests, area-mounted closure, soak beyond 30 days, multiplayer interleavings, shard handoff, load, independent-reviewer lineage, Jev triage. Those gates attach when a later chapter's lock or profile triggers them.

Building the Lab in this order, minimum first, is R9. The later mechanisms grow as capabilities require them; current mandatory safety obligations cannot be disabled by candidate-authored exclusions. R6P uses its own smaller applicable corpus and never claims chapter-one certification.

Chapter-one terminal milestones and atomic local report capture are tested with narrative/recovery gates now. The first public app release also requires the R12A account/progress gate from [document 23](23-accounts-progress-admission.md), including real authenticated synchronization. It is an app/platform gate, not permission to require a live account server in pure Lab simulations or R6P. A cartridge certificate alone cannot satisfy it.

## 2. Determinism contract

A deterministic repro identifies:

```text
engine/kernel revision
protocol/schema versions
cartridge ID/version/hash
deployment hash
initial snapshot hash
logical clock
RNG algorithm/state/seed
ordered command stream
fault schedule
expected invariant
observed invariant
```

Running the repro on any conformant host should produce the same portable domain result.

## 3. Virtual clock

Lab provides:

```text
clock.now
clock.pause
clock.step(duration)
clock.advance_to(timestamp)
clock.run_until_idle
```

All game systems use logical time adapters.

No test needs real `sleep` for game time.

## 4. Deterministic RNG

Use explicit RNG state.

A decision consumes RNG and returns new RNG state.

Lab can:

- set seed;
- inspect draw trace;
- replay;
- search multiple seeds.

Randomness source/version is recorded in snapshot/certificate.

## 5. Boot modes

### Pure portable model

Fast kernel/reducer tests without full OTP or mobile shell.

### BEAM runtime instance

Starts actual `WorldInstance` under test supervision.

### Offline host

Runs local authority + SQLite semantics against the R1-selected Story portable-rules implementation.

### Integration

Uses PostgreSQL and real store transaction/outbox behavior.

### Protocol/mobile

Exercises Phoenix channel contract and generated fixtures.

### Cross-host conformance

Runs the same golden scenario through every host implementation/adapter selected by the accepted portable-execution ADR and compares canonical trace hashes. If R1 selects one shared native kernel, this includes its direct host plus BEAM/iOS/Android bindings; if R1 selects the dual implementation, it compares the accepted Elixir/mobile implementations instead.

Certification uses all modes relevant to the deployment profile.

## 6. Snapshot and rewind

Lab commands:

```text
snapshot save <name>
snapshot list
snapshot restore <name>
fork <name>
```

A fork creates an isolated branch of simulation from same state/seed.

Useful for exploring alternate dialogue/quest decisions.

## 7. Trace viewer

Trace groups by correlation:

```text
command move north
  decision accepted revision 18→19
  event entity_left_room
  event entity_entered_room
    quest missing_child objective find_dock progressed
  projection room_view
```

Trace includes state diffs by component, not giant whole-state dumps.

## 8. Static certification gate

Checks:

- syntax/schema;
- manifest;
- capability compatibility;
- portability classification;
- broken references;
- template/mixin cycles;
- graph reachability;
- localization;
- asset hashes;
- scripts;
- typed FactSpecs and allowed transitions/scopes;
- consequence operators and targets;
- reactive-rule references/cycles;
- policies/actions;
- unknown fields;
- state-scope declarations;
- cartridge namespace;
- client feature requirements;
- deployment profile constraints.

## 9. Quest/dialogue model gate

For each quest/dialogue:

- lifecycle transition validity;
- activation/resolution mode validity;
- prerequisite cycles;
- branch reachability;
- terminal outcome reachability;
- duplicate event idempotency;
- reward exactly once;
- turn-in reachability;
- required-NPC survivability or alternate path;
- timeout behavior;
- abandon/retry behavior;
- scope correctness;
- multiplayer credit/participation rules;
- unrelated players cannot receive progress unless policy allows it;
- every consequence operator/target/scope is valid;
- broader-scope consequences are explicit;
- consequence idempotency;
- fact transition legality;
- reactive-rule cycles/event-chain budgets;
- consequence dependencies do not silently destroy required future quest paths unless intentional.

### World-consequence branch testing

For each meaningful quest outcome, the Lab SHOULD fork from the last common snapshot and compare:

- changed facts;
- runtime entity/component state;
- accessible/revealed topology;
- NPC behavior/schedule profiles;
- dialogue/action availability;
- spawned/despawned entities;
- follow-up quest availability;
- relationship/personal memory state;
- environment/ambient variants.

Then advance logical time after each branch to catch delayed problems:

- NPC cannot reach a new schedule destination;
- a newly opened path becomes inaccessible at night;
- a quest-critical NPC despawns;
- reaction rules loop;
- a “rescued” NPC continues emitting mourning ambience;
- a branch accidentally exposes content intended for another outcome.

The comparison output becomes semantic-review evidence.

Bounded state exploration SHOULD exhaust small graphs.

For larger graphs, use targeted search + property testing.

## 10. Property-based tests

Use StreamData on Elixir host and equivalent portable-kernel property tests to generate:

- valid/invalid command sequences;
- duplicate commands;
- arbitrary logout/reconnect points;
- inventory moves;
- quest event permutations;
- timer advances;
- player interleavings.

Important properties:

```text
currency >= allowed minimum
item has one container
no duplicate unique reward
quest transition legal
no cross-scope state leak
revision monotonic
same command_id executes at most once
snapshot roundtrip equivalent
same portable input -> same canonical output on all hosts
```

## 11. Autonomous world simulation

Run without player:

- hours;
- days;
- weeks of logical time.

Check:

- schedules;
- shops;
- patrol reachability;
- spawn boundedness;
- ecology if enabled;
- time-window accessibility;
- durable jobs;
- ambient event rate;
- memory/state growth.

Prefer derived/on-demand systems where simulation reveals meaningless tick load.

## 12. Bot personas

Gameplay bots SHOULD use the same ActionInvocation → GameSession → authority path as real touch/text clients so they exercise action availability and stale-input rules. Lower-level reducer/property tests may construct semantic Commands directly when the layer under test is intentionally below that boundary.

Profiles:

- main-path player;
- completionist;
- impatient/rushing;
- combat-avoidant;
- aggressive;
- thief/hostile;
- random explorer;
- low-resource;
- disconnect-prone;
- malicious duplicate-tapper.

Agent-driven exploratory bots MAY supplement deterministic strategies, but deterministic bots are required for repeatable certification.

## 13. Multiplayer race testing

For party/shared content:

- same item picked simultaneously;
- same mob killed by two parties;
- shared door changed concurrently;
- same shop stock bought simultaneously;
- quest with different intended scopes;
- player crosses shard during event;
- party membership changes mid-quest;
- disconnect while trade/loot transfer occurs.

Use controlled interleaving schedules.

## 14. Crash/chaos testing

Inject crashes at boundaries:

```text
before decision
after decision before transaction
during transaction
after commit before in-memory adoption
after commit before client reply
before effect dispatch
during effect dispatch
after effect but before acknowledgement
```

Expected:

- durable state is either old or committed, never partial;
- command retry dedupes;
- outbox retries idempotently;
- instance restarts/reloads;
- client can resync.

Offline host gets analogous tests around local SQLite commit and app termination.

## 15. Offline lifecycle testing

Test:

- airplane mode launch after prior download;
- app killed during command;
- app killed during save migration;
- low-storage write failure;
- corrupted asset/package;
- device clock moves backward/forward;
- long absence with many due jobs;
- old cartridge release retained for pinned save;
- two device save branches diverge;
- reconnect/cloud-backup conflict.

No internet-dependent assumption may accidentally enter an `offline_private` certificate.

## 16. Script fuzzing

Generate script inputs/state for each binding.

Check:

- interpreter cannot escape allowed portable AST;
- step budget;
- query/effect budgets;
- deterministic result;
- unknown binding failure;
- effect schema validation;
- event-chain depth protection;
- host conformance.

Security tests include known AST escape attempts.

## 17. Performance certification

Cartridge manifest may declare expected envelope.

Measure:

- compile time;
- mobile boot time;
- memory per offline instance;
- BEAM memory per online instance;
- command p50/p95/p99;
- world owner mailbox;
- kernel decision latency;
- FFI boundary latency;
- DB transaction time;
- snapshot size/time;
- simulation throughput;
- effect backlog.

Performance warnings do not always block, but hard resource ceilings may.

## 18. Semantic review

Semantic review runs **after deterministic/mechanical gates** and produces auditable review evidence. It is intentionally not treated as a deterministic game-rule oracle.

Reviewer inspects:

- contradictions;
- nonsensical schedules;
- knowledge leaks;
- dead-feeling spaces;
- impossible narrative causality;
- repeated prose;
- consequences not reflected across world systems;
- NPC/world reactions that contradict typed facts or quest outcomes;
- branches whose world-state differences are too weak for the intended narrative consequence;
- misleading choice labels;
- inaccessible endings;
- multiplayer narrative mismatches;
- private-to-shared deployment mismatches.

Every semantic finding cites definitions/traces.

The review record stores enough identity to audit what was judged, for example:

- reviewer kind/provider/model and version when applicable;
- rubric/prompt/policy revision;
- input evidence bundle/hash;
- output/findings hash;
- blocker/warning disposition;
- explicit waiver/resolution records.

Re-running a stochastic model later is not expected to reproduce identical prose or findings. Release reproducibility comes from retaining the exact review evidence and disposition used by the certificate. Mechanical invariants remain enforced by deterministic/model/property tests rather than delegated to the reviewer.

A certification policy MAY require “no unresolved semantic blockers,” but a model response by itself cannot silently publish, waive, or mutate content.

For a commercially published first-party cartridge/deployment, semantic review MUST be
performed by a review assignment/principal that does not own mutation authority over the
frozen candidate and satisfies the configured independence predicate from the authoring
assignment/candidate lineage. Relaunching the author under a new role/model/session label
does not satisfy this requirement.

## 19. Human smoke

Required for commercial release:

- physical iOS/Android device;
- onboarding;
- purchase/restore sandbox;
- cartridge download;
- offline launch;
- airplane-mode completion sample;
- start/resume;
- touch targets;
- accessibility basics;
- dialogue readability;
- save/reconnect/cloud backup if offered;
- completion/end state.

## 20. Certification profiles and Builder targets

```text
offline_private
online_private
party
shared_area
portable_capability_pack
server_capability_pack
mobile_app_release
```

The gameplay profile names (`offline_private`, `online_private`, `party`, `shared_area`) intentionally reuse the canonical execution-profile vocabulary from the packet; certification does not invent a second parallel set of Story/Realm profile names. Capability-pack and app-release profiles are separate certification-only targets.

Each profile selects mandatory gates.

### `story` target

Minimum required evidence:

- frozen exact-candidate identity;
- static/schema/reference validation;
- topology/quest/scene/reaction model analysis;
- CoverageManifest with required surfaces accounted for;
- portable capability check;
- deterministic kernel + registered invariant tests;
- quest/dialogue/scene model checks;
- bounded branch/path/seed exploration appropriate to the content;
- autonomous/long-horizon simulation where applicable;
- script fuzzing where scripts exist;
- mutation-sensitivity obligations selected by the certification profile;
- offline lifecycle/app-kill/storage/clock tests;
- save and app/kernel compatibility;
- semantic review with explicit blocker disposition; commercial publication requires the
  independent frozen-candidate reviewer rule from §18;
- CertificationEvidenceBundle bound to the candidate hash;
- physical-device Story Mode smoke for release-level/product Story certification; an internal synthetic conformance artifact may use the profile's non-release gate level when the certification registry marks device smoke inapplicable.

Network availability MUST NOT be a prerequisite for certified ordinary play after acquisition/download.

### `realm` target

Select `online_private`, `party`, or `shared_area`.

Minimum evidence adds as relevant:

- mounted dependency-closure validation for Areas used by the deployment;
- protocol/version negotiation;
- command receipt/idempotency;
- PostgreSQL transactional recovery;
- reconnect/resync;
- concurrent-player interleavings;
- authorization/abuse checks;
- mailbox/backpressure/load envelope;
- shard/handoff testing for shared areas;
- long-horizon shared population/economy/service soak where applicable;
- CertificationEvidenceBundle bound to cartridge + deployment hashes;
- Realm Mode physical-device smoke.

Realm certification does not require offline portability unless the content is explicitly a portable Story cartridge being reused online.

### `promote` target

Promotion MUST:

1. verify the immutable source Story artifact/certificate;
2. record explicit decisions for scope, NPC multiplicity, death/respawn, loot/resource contention, economy, and mount/instance policy;
3. produce a new deployment/adaptation hash;
4. run the selected Realm certification profile.

A prior Story certificate is evidence, not a substitute for multiplayer certification.

### `mobile_app_release` profile

Every production mobile binary runs the Story Mode regression suite, including supported save/kernel/rule-IR compatibility.

After Realm Mode exists, the same app release MUST also run:

- Realm protocol compatibility fixtures;
- authentication/reconnect/resync smoke;
- remote-authority boundary tests;
- representative Realm physical-device smoke.

Online release cadence is never allowed to silently drop supported offline Story saves.

### Gate applicability classes

Certification rigor MUST scale by declared semantics without allowing content to opt out of relevant correctness obligations.

Every gate/check in the certification registry SHOULD declare an applicability class:

- **always mandatory** — foundational schema/reference/determinism/integrity/authority checks required for every candidate in the profile;
- **capability-triggered** — required when the frozen artifact/deployment uses the relevant capability or semantic surface, such as scripts, ServiceJobs, commerce, InstancePlan, party scope, or cross-authority effects;
- **risk/profile-triggered** — selected by execution profile, certification level, or detected architecture risk, such as physical-device host smoke, multiplayer interleavings, load/backpressure, shard handoff, long-horizon economy/population soak, or hostile-package checks;
- **commercial-release-only** — store/package/signing/entitlement/release-policy/human commercial evidence that is unnecessary for an edit-time or internal semantic candidate but mandatory for the corresponding commercial release.

The registry, not the cartridge author/model, determines which gates apply from the frozen candidate, capability lock, deployment, and release profile. Unknown applicability fails conservative: it widens the required evidence set or requires explicit certification-policy disposition rather than silently skipping work.

This classification exists to prevent two failures at once:

1. a tiny offline story paying the implementation/runtime cost of unrelated shared-Realm checks during every author edit;
2. a candidate avoiding a hard gate merely because nobody manually selected it.

Fast preflight may run a strict subset for feedback, but the frozen-candidate certificate still includes every applicable mandatory gate.

## 21. Release certificate

Machine-readable example:

```json
{
  "cartridge_hash": "...",
  "deployment_hash": "...",
  "portable_rules_revision": "...",
  "portable_strategy": "...",
  "engine_revision": "...",
  "capability_lock_hash": "...",
  "profile": "offline_private",
  "gates": {
    "static": "pass",
    "model_analysis": "pass",
    "coverage": "pass",
    "host_conformance": "pass",
    "quest_scene_model": "pass",
    "invariants": "pass",
    "simulation_exploration": "pass",
    "mutation_sensitivity": "pass",
    "crash_recovery": "pass",
    "offline_lifecycle": "pass",
    "semantic": "pass",
    "human_mobile": "pass"
  },
  "evidence_bundle_hash": "...",
  "semantic_review_evidence_hash": "...",
  "coverage_manifest_hash": "...",
  "exploration_bounds": {...},
  "seeds": [...],
  "warnings": [...]
}
```

Only the exact artifact/deployment hash with all profile-mandatory gate receipts bound to its CertificationEvidenceBundle is promotable. A summary certificate without resolvable required evidence is invalid.

## 22. Regression corpus

Every production bug SHOULD become:

- minimal snapshot;
- command/event sequence;
- seed;
- invariant assertion.

The corpus runs forever in certification.

This makes the product progressively harder to break.

## 23. Shared-area promotion certification

A storypack being promoted from private adventure to shared area gets a new deployment certification, not a waiver based on its private certificate.

Additional checks:

- player-vs-player concurrency;
- spawn/respawn;
- resource competition;
- shared NPC death/liveness;
- griefability;
- economic faucets/sinks;
- unique item semantics;
- world rollback;
- shard handoff;
- realm event interactions;
- load.

The private cartridge certificate remains evidence for underlying story logic.


## 24. Certification pyramid: fast preflight to exact-hash release

Certification should be usable continuously during authoring without confusing partial
evidence with release approval.

### Level 0 — edit-time validation

Fast, deterministic checks after a small change:

- schema/type/reference;
- local graph integrity;
- policy/action shape;
- changed quest/scene/reaction checks;
- changed-unit focused tests.

### Level 1 — component/area preflight

Run broader checks for one quest, AreaDefinition, storyline, capability composition, or
other selected slice.

Useful for builder feedback, but **not promotable release certification** because external
dependencies and cross-area interactions may still be untested.

### Level 2 — cartridge candidate certification

Freeze one exact compiled cartridge hash and run every gate required by the selected
Story/online-private/party profile.

### Level 3 — deployment/shared-area certification

Freeze exact cartridge + deployment hashes and run multiplayer/economy/abuse/load/
authority-placement gates required by that deployment.

### Level 4 — commercial release evidence

Bind the exact certified semantic hash to:

- package/signature verification;
- supported app/runtime versions;
- physical-device smoke;
- commerce/entitlement evidence where relevant;
- release-policy/human disposition;
- immutable certification evidence manifest.

A lower-level preflight must never be rendered or interpreted as Level-4 acceptance.

## 25. Freeze first, certify the exact candidate

Full certification starts by freezing/importing the exact normalized artifact and
governing compatibility locks.

Every gate receipt records:

- semantic cartridge hash;
- deployment hash when applicable;
- engine/portable-rules revisions;
- capability lock;
- certification profile/policy revision;
- test/check implementation revision;
- environment/host identity where relevant.

A content edit after freeze creates a new candidate hash and invalidates downstream
candidate-specific evidence unless the gate's contract explicitly proves it is
content-independent.

There is no "tests were green before the final edit" release path.

## 26. Coverage manifest

Certification tooling SHOULD produce a machine-readable **CoverageManifest** from the
frozen compiled artifact plus observed/proved gate receipts, describing which authored
semantic surfaces were exercised and which remain intentionally unreachable/dormant.

The cartridge/author/model does not self-report coverage. Any author-declared exclusions
or intentionally unreachable branches are inputs requiring schema/policy validation and,
where release-relevant, explicit certification disposition.

Coverage dimensions should include, where present:

- rooms/AreaDefinitions/connections/barriers;
- InspectableDetails;
- Actions/ActionRecipes and result bands;
- policies and important true/false branches;
- facts and state-machine transitions;
- quest activation modes, objectives, milestones, branches and outcomes;
- dialogue nodes/choices;
- SceneSequence beats, choices, waits, outcomes and SceneSpaces;
- InstancePlan entry/reconnect/reset/teardown/export paths;
- ReactionRule triggers/conditions/consequences;
- Behavior arbitration combinations;
- SpawnBundle/PopulationPlan lifecycle;
- commerce buy/sell/admission/stock/restock/price paths;
- ServiceJob queue/cancel/complete/failure paths;
- world-event phases/outcomes;
- scripts/bindings;
- save/migration paths;
- multiplayer scopes/interleavings where applicable.

Coverage is evidence of exercised structure, **not proof of semantic correctness**.

An uncovered required branch is a release blocker unless the definition/certification
policy marks it intentionally unreachable, content-only presentation, or otherwise
outside the profile with an explicit reason.

## 27. Static graph and model analysis

Before simulation, compile semantic graphs and detect mechanically provable defects.

Examples:

### Topology

- unreachable required locations;
- one-way link mistakes where reciprocity was declared;
- contradictory Barrier faces;
- path loss under required schedule/time states;
- orphan exported ports;
- InstancePlan entry with no valid exit/teardown path where one is required.

### Quest/story

- prerequisite cycles;
- impossible conjunctions;
- dead objectives;
- branches with no terminal outcome;
- required outcome with no reachable path;
- turn-in/scene target impossible under branch state;
- quest branch destroys all future required progress;
- storyline arc references incompatible outcome prerequisites.

### Scene

- unreachable beats;
- nonterminal branch with no wait/end;
- endless immediate beat loop;
- choice with no legal option under reachable state;
- modal scene with no escape/continuation;
- InstancePlan scene whose required export references temporary-only state.

### Reaction/event

- statically visible reaction cycles;
- event chains that necessarily exceed budget;
- trigger references impossible event/target;
- scope escalation without explicit operator.

### Population/economy/services

- impossible min/max or stock constraints;
- population plan whose placement selector is empty;
- negative/nonconserving transfer paths;
- service output with no ownership/delivery policy;
- restock/capacity windows with missing time basis.

Static proof should eliminate cheap defects before expensive simulation/model review.

## 28. Bounded state exploration and path search

For small quest/scene/world graphs, certification SHOULD exhaust all reachable logical
states within the declared finite model.

For larger worlds, use bounded search guided by coverage gaps and risk:

- breadth/depth path exploration;
- branch/outcome enumeration;
- pairwise/combinatorial policy variation;
- state-machine transition exploration;
- seed search;
- temporal boundary search;
- multiplayer interleaving search.

The candidate records exploration bounds. "No failure found in 10,000 paths" is not
reported as exhaustive proof unless the state space was actually exhausted.

The Lab should support goals such as:

~~~text
find path to every quest outcome
find path that strands the player
find state where required NPC is unavailable
find sequence that duplicates a unique reward
find schedule/time state where route disappears
find interleaving that violates stock/capacity
find scene state with no legal continuation
~~~

A found counterexample becomes a deterministic repro fixture.

## 29. Invariant registry

Capabilities SHOULD register reusable invariants so a new cartridge automatically gains
the appropriate checks.

Examples:

### Core/world

- entity location/containment is unique;
- no containment cycles;
- one logical Barrier has one authoritative state;
- state scope/audience/placement constraints hold;
- no unknown runtime definition ref.

### Quest/narrative

- legal lifecycle transition;
- reward/consequence once;
- scene choice once;
- no hidden pre-activation credit unless declared;
- temporary InstancePlan state cannot leak except through allowed exports.

### Population/economy

- population stays within policy bounds;
- provenance-safe cleanup;
- currency/item conservation except registered source/sink;
- finite stock never becomes negative;
- escrow/custody unique;
- ServiceJob output once.

### Runtime

- command/idempotency identity never changes on retry/reconnect;
- authority revision monotonic;
- stale owner cannot write;
- event/reaction/script chain stays bounded.

The Lab runs applicable invariants continuously during simulation, not only at the end.

## 30. Mutation-sensitivity testing

A certification suite should prove that important gates can actually detect representative
defects.

For selected high-risk content/capability contracts, create disposable candidate
mutations such as:

- remove a quest prerequisite;
- swap a target ref;
- broaden player scope to realm;
- break a reverse connection/barrier binding;
- duplicate a reward key;
- remove a SceneSequence terminal;
- alter an idempotency key;
- change PopulationPlan provenance;
- make merchant stock non-conserving;
- disable a required reaction;
- weaken an access policy;
- reorder conflicting Behavior priority.

The expected gate must fail.

Mutation testing is evidence about **test sensitivity**, not production content. Mutants
never become publishable candidates.

## 31. Differential and metamorphic testing

In addition to exact cross-host replay, test transformations that should preserve or
predictably alter semantics.

Examples:

- serialization/deserialize round trip;
- save/reload at arbitrary command boundaries;
- irrelevant insertion-order changes;
- reconnect under a new session ID;
- equivalent text versus touch ActionInvocation;
- same scenario with presentation-only locale change;
- duplicate delivery of idempotent event/command;
- advancing time in one step versus permitted equivalent substeps;
- party player-order permutation where policy is symmetric.

A semantic difference where equivalence is expected is a blocker.

## 32. Adversarial gameplay generation

Deterministic bots remain the release baseline, but high-reasoning models may propose
new adversarial play plans.

Useful model-generated challenges include:

- "How could I sequence these legal actions to strand the quest?";
- "Which NPC death/timing combinations threaten completion?";
- "What does a malicious player spam or retry?";
- "Which branch combinations produce contradictory facts?";
- "Which shared-resource races are missing?";
- "What player behavior would reveal an implausible schedule/economy?";
- "What scene interruption/reconnect point is least tested?".

The model's text is not test evidence.

Foundry/Builder tooling converts an accepted proposed scenario into:

- typed initial state;
- ActionInvocation/Command sequence;
- clock/RNG/fault schedule;
- candidate expected property.

The deterministic Lab executes it. A model-proposed expected property becomes a release
blocker only when it maps to an existing registered invariant/certification predicate or
is separately reviewed/admitted into the test profile. Otherwise the execution is
exploratory evidence requiring disposition.

Failures against governing invariants become permanent regression fixtures.

## 33. LLM semantic review as a separate evidence layer

A high-reasoning semantic reviewer is useful for defects that static/model checks cannot
define completely.

Reviewer inputs SHOULD be compact, exact evidence views such as:

- frozen artifact/hash and relevant definitions;
- topology and quest/storyline graphs;
- SceneSequence/InstancePlan graphs;
- branch world-state comparisons;
- NPC schedule timelines;
- population/commerce/service summaries;
- coverage gaps;
- invariant/simulation findings;
- representative transcripts/traces;
- declared narrative intent/rubric.

Review questions can include:

- Does the story causality make sense?
- Are player choices honestly reflected in outcomes?
- Does NPC knowledge precede any plausible source?
- Does a rescued/dead NPC still behave inconsistently?
- Are areas dead, repetitive, or incoherent?
- Are there soft-locks that mechanical reachability missed because the path is
  narratively nonsensical?
- Do dream/vision exports contradict ordinary-world state?
- Does shared Realm adaptation undermine private-story assumptions?
- Are prices/schedules/populations believable enough for the cartridge's design goals?

The reviewer should be independent of the authoring assignment where policy requires it.

The model may emit blockers/warnings/questions with cited evidence. It cannot:

- alter the candidate;
- waive a deterministic failed gate;
- mark its own authored candidate accepted;
- publish;
- convert uncertainty into pass.

Resolved findings and human/operator waivers are explicit evidence bound to the exact
candidate.

## 34. Jev/System-One-style fast semantic triage

A fast typed probabilistic decision model such as Jev MAY sit in front of expensive
semantic review **after held-out evaluation proves value**.

Appropriate advisory questions are narrow and typed:

- which evidence bundle deserves deeper review;
- which rubric category a trace threatens;
- whether two findings are likely duplicates;
- which quest/scene/area is highest semantic risk;
- whether a simulation anomaly looks likely narrative, mechanical, or infrastructure;
- which already-authorized reviewer/test profile should inspect next.

Possible outputs are Choice/Score/probability-style signals plus confidence.

Deterministic policy owns:

- minimum confidence;
- maximum autonomous triage effect;
- fallback to full review;
- mandatory evidence that triage may never suppress.

Jev is **not** an acceptance oracle. It cannot certify correctness, waive coverage,
replace invariants, establish reviewer independence, or turn an untested area green.

Pin provider/model/question-schema/threshold identity in the review evidence. If the
provider is unavailable, malformed, low-confidence or stale, fall back to deterministic
baseline/full review rather than weakening certification.

## 35. Release blocker classes

Certification SHOULD classify findings instead of flattening everything into pass/fail
logs.

### Mechanical blocker

Examples:

- schema/ref/invariant failure;
- deterministic repro failure;
- required branch unreachable;
- cross-host divergence;
- duplicate reward/stock/custody;
- crash/recovery inconsistency.

Cannot be waived by an LLM or by an ordinary content/release waiver. Changing what
counts as a mechanical blocker requires an explicit reviewed certification/engine-policy
revision and renewed evidence for affected candidates.

### Security/authority blocker

Examples:

- script escape;
- scope leak;
- unauthorized action;
- stale-owner write;
- package traversal;
- cross-player data leak.

Requires code/content correction or an explicit architecture/security process—not an
ordinary content-editor, reviewer, release-agent, or model waiver.

### Semantic blocker

Examples:

- contradiction with declared narrative intent;
- inaccessible intended ending not mechanically encoded as required;
- severe knowledge leak;
- branch consequence contradicts story canon.

Requires explicit reviewer/operator disposition and normally correction before release.

### Warning / accepted design tradeoff

Non-blocking concern retained in certificate evidence with reason.

Unknown evidence is not pass.

## 36. Release evidence bundle

Every release candidate should produce a content-addressed **CertificationEvidenceBundle**
containing or referencing:

- candidate/deployment hashes and compatibility locks;
- static diagnostics;
- CoverageManifest;
- graph/model-analysis report;
- deterministic/property/fuzz results;
- explored path/seed/interleaving summary;
- invariant results;
- mutation-sensitivity report where required;
- cross-host differential receipts;
- crash/chaos recovery receipts;
- performance/load report;
- semantic reviewer evidence;
- Jev/fast-assessor evidence if used;
- human/device smoke evidence;
- unresolved warnings/waivers;
- regression fixtures added from findings.

The final certificate is a small signed/attested summary over this exact bundle and
candidate hash.

Agents and humans should be able to inspect *why* a release passed, not merely see a
green badge.

## 37. Cartridge-authored tests are supplemental, not certification authority

Cartridges MAY ship author-authored scenario/property tests to express design intent and
speed development.

Those tests:

- run against the same frozen artifact;
- may add stronger cartridge-specific invariants;
- are included in evidence with exact source/revision;
- cannot replace, disable, weaken or mark passed any engine/profile-mandatory gate;
- cannot redefine a failed engine invariant as success;
- are treated as candidate-controlled input when deciding release authority.

A malicious or mistaken cartridge test suite that asserts only happy paths must not make
the candidate easier to publish.

## 38. Regression ratchet

Every escaped production defect, certification-discovered blocker, or important
adversarial counterexample SHOULD be reduced to the smallest durable regression artifact
that still reproduces the failure.

Classify it into the relevant permanent suite:

- static compiler;
- capability invariant;
- quest/scene model;
- deterministic scenario;
- property/fuzz;
- multiplayer interleaving;
- crash/recovery;
- security;
- semantic reviewer fixture.

Certification should become harder to fool over time without making the whole suite
depend on ever-growing LLM prompts.


## 39. Area-level assurance: isolate, then mount

An AreaDefinition SHOULD be testable as a coherent authored module before whole-cartridge
release, but area isolation is not enough.

A Level-1 **AreaAssuranceProfile** may declare:

- area identity and exact source/artifact revision;
- entry/exit/exported ports;
- imported facts/capabilities/assumptions;
- contained quests/scenes/dialogues;
- PopulationPlans/merchants/services;
- required neighboring definitions;
- intended player-level/resource assumptions;
- required reachable outcomes;
- area-local performance envelope.

Run the area in two modes:

### Isolated harness

Supply explicit fixtures for declared imports and test the area's own invariants:

- every required room/detail/connection reachable under intended states;
- local quests/scenes can reach all intended outcomes;
- required NPCs/services exist when needed;
- schedules remain navigable;
- population/economy bounded;
- no local reaction/event loop;
- instance/scene teardown clean;
- no undeclared external reference.

### Mounted dependency closure

Mount the area into its real cartridge/deployment dependency closure and retest:

- imported facts/policies resolve as expected;
- neighboring topology/ports bind correctly;
- cross-area quests/rumors/services/reactions remain coherent;
- schedule/pathfinding across area boundaries works;
- global stock/economy/population policies remain bounded;
- no name/target ambiguity introduced by neighboring content;
- shared Realm scope/audience assumptions remain valid.

An area passing isolated tests but failing mounted-closure tests is not releasable.

Whole-cartridge/deployment certification remains mandatory because two individually
healthy areas can interact badly.

## 40. Change-impact analysis accelerates feedback but cannot shrink release truth

Builder/Lab should compute a typed **ImpactSet** from the reference/dependency graph after
a content edit.

Potential affected surfaces include:

- direct definition refs;
- quests/scenes/dialogues consuming changed facts/events;
- paths/topology reachable through changed Connection/Barrier;
- NPC schedules/Behaviors;
- ReactionRules;
- PopulationPlans;
- merchants/services/economy;
- InstancePlans;
- exported cartridge ports;
- localization/presentation;
- tests/regression fixtures.

Use ImpactSet to choose fast Level-0/1 checks during authoring.

Impact analysis is fail-conservative. If the compiler cannot prove a dependency boundary
because of dynamic selectors, LokaScript/query behavior, custom event subscriptions,
deployment imports, or another opaque capability edge, the ImpactSet widens to the
enclosing capability/area/cartridge scope required by policy. Unknown dependency is not
treated as "unaffected."

For Level-2+ release certification, protected profile policy—not the author/model—decides
which previously valid receipts may be reused and which gates rerun. High-risk semantic
changes may force wider/full recertification even when static references look local.

Examples:

- prose typo -> localization/presentation checks may suffice for authoring feedback;
- quest outcome FactSpec change -> all consumers + branch simulations rerun;
- connection topology change -> path/schedule/quest reachability rerun;
- capability-version change -> all dependent semantics/conformance rerun;
- scope change player -> realm -> multiplayer/shared-area recertification.

Impact analysis is an optimization, never authority to declare an exact candidate safe.

## 41. Release-candidate soak and long-horizon simulation

For living-world cartridges, final certification SHOULD include profile-appropriate
long-horizon simulation from the frozen candidate, not only unit scenarios.

Examples:

- 30/90/365 logical-day runs where practical;
- repeated day/night/shop/service cycles;
- population death/replenishment;
- resource regeneration/decay;
- merchant restock and currency/item conservation;
- quest deadline expiration;
- WorldEvent recurrence/cleanup;
- NPC schedule/path stability;
- save/snapshot growth;
- bounded retained history/memory/job state.

Search multiple deterministic seeds and starting states.

The goal is to expose slow leaks and contradictions that a short playthrough misses:
population inflation, currency creation, orphan jobs, accumulating scene state, NPCs
drifting permanently out of schedule, or events that never clean up.

Soak success is still bounded evidence. The certificate records duration/seeds/state
coverage rather than claiming proof over infinite time.

## 42. Readiness evidence is not host evidence

The added composition and Lantern fixtures extend `conformance/`, using independent explicit expected values rather than candidate-generated baselines. Preserve the existing Tiny strict-event and state-credit cases; Lantern is a separate content-intent fixture, not a replacement oracle. Run known-bad variants for queue ordering, activation snapshots, conflicting writes and restored narration alongside ordinary examples. Any expected-value amendment is separately reviewed against the governing contract, not regenerated to make a candidate green.

R1 preparation validation checks a reviewed manifest and retained artifact hashes. It does not establish that devices were used, measurements are genuine or a store will accept the app. R1 acceptance additionally requires actual per-step adapters, release builds, physical iOS/Android, SQLite faults, Node/BEAM load and mismatch sensitivity under the accepted envelope. R6P adds human comprehension and both durable choice paths. Keep these evidence classes distinct in reports and certificates.

Run-lifetime gates (10 §31–33) add released-save fixtures, package-retention references, interrupted migration, explicit fork lineage and bounded untrusted import tests at R6/R12. Optional backup tests become applicable only when the backup feature is delivered. Local specification-model passes cannot mark those integrations complete.

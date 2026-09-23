# 08 — Builder API and AI Factory

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: authoring plane.

Tools and agent permissions are separate from gameplay authority. General Builder/factory work follows demonstrated authoring needs.

<details>
<summary>Sections in this document</summary>

- [1. Core decision](#1-core-decision)
- [2. Builder targets: story, realm, promote](#2-builder-targets-story-realm-promote)
- [3. Workspace-first authoring](#3-workspace-first-authoring)
- [4. Builder operation envelope](#4-builder-operation-envelope)
- [5. Operation families](#5-operation-families)
- [6. Structured diagnostics](#6-structured-diagnostics)
- [7. Batch plans](#7-batch-plans)
- [8. Dry run](#8-dry-run)
- [9. Rename/move must be semantic](#9-renamemove-must-be-semantic)
- [10. Terminal adapter](#10-terminal-adapter)
- [11. MCP adapter](#11-mcp-adapter)
- [12. AI model independence](#12-ai-model-independence)
- [13. AI authoring workflow](#13-ai-authoring-workflow)
- [14. Context minimization](#14-context-minimization)
- [15. Primitive proposal workflow](#15-primitive-proposal-workflow)
- [16. AI semantic review contract](#16-ai-semantic-review-contract)
- [17. Audit trail](#17-audit-trail)
- [18. Visual tools](#18-visual-tools)
- [19. Git relationship](#19-git-relationship)
- [20. Factory and runtime separation](#20-factory-and-runtime-separation)
- [21. Builder API schema source](#21-builder-api-schema-source)
- [22. Agent permissions](#22-agent-permissions)
- [23. Foundry integration](#23-foundry-integration)
- [24. Builder expressive power: semantic composition, not arbitrary authority](#24-builder-expressive-power-semantic-composition-not-arbitrary-authority)
- [25. Foundry/Astra orchestration: project roles map onto Loka layers](#25-foundryastra-orchestration-project-roles-map-onto-loka-layers)
- [26. Capability escalation contract](#26-capability-escalation-contract)
- [27. Context routing follows role and escalation](#27-context-routing-follows-role-and-escalation)
- [28. Agents-as-tools versus authority handoff](#28-agents-as-tools-versus-authority-handoff)
- [29. Foundry is optional infrastructure](#29-foundry-is-optional-infrastructure)
- [30. Small initial authoring surface](#30-small-initial-authoring-surface)

</details>
<!-- packet-navigation:end -->

## 1. Core decision

The canonical authoring surface is a **typed Builder API**.

MCP, terminal, CLI, CI, admin visualizations, Astra, Foundry, and other models are clients of that API.

No adapter owns separate mutation semantics.

```text
                       Builder API
             /             |             \
          MCP           Terminal          CLI/CI
       AI agents          human          automation
```

## 2. Builder targets: story, realm, promote

The Builder API has explicit build targets. An author/model does not work in an ambiguous “generic Loka world” mode.

### `story`

For Story Mode.

Constraints:

- cartridge must compile against portable capabilities only;
- offline save/campaign semantics required;
- no realm/global service assumptions;
- default runtime quest scope is player; campaign continuity is handled through explicit continuity exports/imports rather than a fifth runtime scope;
- certification profile is offline-first;
- economy/power remains local to the story/campaign lineage.

Typical command:

```text
workspace.create target=story cartridge=fox_spirit_of_yunmeng
```

### `realm`

For Realm Mode native multiplayer content.

Allows:

- server-only capabilities;
- party/instance/realm scopes;
- persistent online economy;
- social/presence/guild dependencies;
- zone/shard deployment metadata;
- concurrency/abuse/load requirements.

Realm mode is not required to remain offline-portable.

### `promote`

For adapting an existing portable Story cartridge into Realm deployment.

The workflow starts from an immutable certified cartridge and creates a new online deployment/adaptation workspace.

It must explicitly resolve:

- player/party/realm state scopes;
- shared NPC multiplicity;
- death/respawn;
- loot/resource contention;
- economy integration;
- personal versus shared quest state;
- instance versus shared-area hosting;
- entry/exit mount ports;
- concurrency and griefing concerns.

Promotion does not mutate the original Stories cartridge.

This mode may produce:

- a private/party online deployment with little or no narrative change;
- an embedded instanced region;
- a genuinely shared-area adaptation.

### One API, target-specific capability surface

All targets use the same Builder API/diagnostic model. Capability discovery is filtered by target:

```text
capability.search(target=story, "shop")
capability.search(target=realm, "shop")
```

A story author cannot accidentally select server-only mechanics; a realm author is not constrained by offline portability where it provides no product value.

Builder target is an authoring/runtime contract, **not a mobile-app target**. Story and Realm content are both consumed by the same Loka mobile app under different session authority modes.

### Target determines certification

The workspace target MUST select a default certification policy:

- `story` → `offline_private` plus portable/offline/save-compatibility gates;
- `realm` → an online profile such as `online_private`, `party`, or `shared_area`, including concurrency/security/load gates appropriate to scope;
- `promote` → validates the source Story certificate, requires explicit multiplayer adaptation decisions, then runs the selected Realm certification profile.

The builder may add stricter gates, but content cannot weaken target-mandated certification.

## 3. Workspace-first authoring

Normal authoring happens inside a workspace:

```elixir
%Workspace{
  id: uuid,
  cartridge_id: "fox_spirit_of_yunmeng",
  base_release: optional,
  source_revision: git_sha_or_workspace_rev,
  status: :draft,
  revision: 42
}
```

Every mutation command specifies workspace and expected revision.

No generic builder operation edits published cartridge content in place.

## 4. Builder operation envelope

```json
{
  "operation_id": "uuid",
  "workspace_id": "uuid",
  "expected_revision": 42,
  "operation": "npc.create",
  "input": {
    "key": "old_ferryman",
    "components": {}
  }
}
```

Response:

```json
{
  "ok": true,
  "workspace_revision": 43,
  "result": {...},
  "warnings": [],
  "changed_paths": ["npcs/old_ferryman.yaml"],
  "diagnostics": []
}
```

### Builder mutation idempotency

Builder writes are network/agent operations and MUST be safe to retry after an unknown response outcome.

For each mutating `operation_id`, the workspace mutation layer records enough receipt data to compare an input/operation digest and return the prior committed result/revision.

- same `operation_id` + same semantic operation digest → return the original committed result;
- same `operation_id` + different digest → reject with a stable idempotency/integrity conflict;
- a retry after commit MUST NOT fail merely because its original `expected_revision` is now stale.

The receipt/audit retention policy may be bounded, but it must cover supported retry/recovery workflows. High-impact publish/promotion operations require durable idempotency appropriate to release history.

Errors use stable codes and field paths.

## 5. Operation families

### Workspace

```text
workspace.create
workspace.clone
workspace.status
workspace.diff
workspace.revert
workspace.commit
workspace.snapshot
```

### Capability discovery

```text
capability.search
capability.describe
capability.examples
capability.compatibility
capability.portability
```

### Content CRUD

```text
room.create/update/delete/get/list
npc.create/update/delete/get/list
item.*
quest.*
dialogue.*
fact.*
reaction.*
script.*
zone.*
system.*
deployment.*
```

### Graph/query

```text
content.search
references.incoming
references.outgoing
world.path
world.component
quest.graph
quest.consequence_graph
quest.world_impact
dialogue.graph
fact.references
reaction.graph
dependency.graph
schedule.timeline
```

### Compile/validate

```text
cartridge.compile
cartridge.validate
content.validate
script.validate
protocol.compatibility
deployment.validate
offline.portability_check
```

### Lab

```text
lab.boot
lab.snapshot
lab.restore
lab.command
lab.advance_time
lab.run_bot
lab.run_scenario
lab.fork_branch
lab.compare_branches
lab.trace
lab.invariants
lab.compare_hosts
```

### Certification/publish

```text
certification.start
certification.status
certification.report
publish.stage
publish.promote
publish.rollback
```

Policy controls protect promotion operations.

### Quest/world authoring workflow

The Builder should help an author design quests as part of the world rather than as isolated objective lists.

Recommended workflow:

```text
narrative intent
   ↓
identify world facts and scopes
   ↓
identify observable DomainEvents/objectives
   ↓
define named quest outcomes
   ↓
attach typed consequences
   ↓
inspect consequence/reference graph
   ↓
fork/simulate each branch
   ↓
inspect NPC schedules / access / dialogue / world state
   ↓
certify
```

Useful operations:

```text
quest.preview_outcome
quest.consequence_graph
quest.world_impact
fact.references
world.explain_access
world.explain_behavior
lab.fork_branch
lab.compare_branches
```

`quest.world_impact` should report all statically knowable downstream dependencies affected by facts/consequences:

- exits/access policies;
- room description variants;
- NPC behavior/schedule profiles;
- dialogue nodes/choices;
- shops/services;
- spawn rules;
- follow-up quests;
- map visibility;
- reactions.

This is especially useful for Astra: before changing an outcome it can ask, “what else in the world depends on this fact?”

### Builder should suggest facts before scripts

If an author asks for:

> After the child is rescued, the mother returns home, the ferryman thanks you, villagers gossip about it, and the northern road opens.

The Builder SHOULD first propose a shared fact/outcome model such as:

```text
village.child_status = rescued
```

plus direct mechanical consequences only where needed.

It SHOULD NOT immediately generate separate scripts for every NPC/room.

## 6. Structured diagnostics

Diagnostics are first-class:

```json
{
  "severity": "error",
  "code": "QUEST_TARGET_UNREACHABLE",
  "path": "quests/missing_child.objectives[2].target",
  "message_key": "diagnostics.quest_target_unreachable",
  "data": {
    "target": "rooms/abandoned_shrine",
    "entry_room": "rooms/ferry_dock"
  },
  "suggested_capabilities": []
}
```

AI repair loops consume codes/data, not prose scraping.

## 7. Batch plans

Agents often need multi-step edits.

Support a batch plan:

```json
{
  "plan_id": "uuid",
  "operations": [
    {...},
    {...}
  ],
  "mode": "atomic"
}
```

Builder API may:

- validate the entire plan before write;
- apply it to a temporary revision;
- return the diff;
- reject if expected references break;
- commit atomic workspace mutations as one workspace revision;
- make an atomic plan retry-safe under its stable `plan_id` and semantic plan digest.

If a future batch includes operations that cannot be atomic, that must be an explicit different mode with per-operation receipts/recovery semantics. Do not make `atomic_if_possible` silently weaken atomicity.

For file-backed first-party source, implementation may use a staging tree and atomic Git/workspace commit.

## 8. Dry run

All destructive/high-impact operations SHOULD support dry-run:

- delete entity;
- rename definition key;
- change capability version;
- migrate quest;
- change deployment scope;
- publish.

Dry-run reports incoming refs, generated migrations, validation impact, and affected tests.

## 9. Rename/move must be semantic

Never make AI perform blind text replacement for definition IDs.

`content.rename`:

1. resolves exact definition;
2. enumerates typed references;
3. updates references;
4. validates;
5. returns diff.

## 10. Terminal adapter

Human terminal commands remain ergonomic:

```text
use fox_spirit
create npc old_ferryman
show npc old_ferryman
test quest missing_child
simulate --days 14
trace last
check offline
```

Parser converts commands to Builder API calls.

Terminal output can be pretty text, but underlying operation result stays structured.

## 11. MCP adapter

MCP exposes Builder API operations as tools.

Tool definitions SHOULD be generated from Builder operation schemas.

MCP adapter responsibilities:

- auth;
- schema conversion;
- request/response formatting;
- streaming long certification progress where supported.

MCP does not directly call low-level managers bypassing Builder API.

## 12. AI model independence

Lokacore currently contains model-provider-specific conversation plumbing.

V3 SHOULD NOT make the engine depend on one provider.

Possible clients:

- Astra;
- Foundry orchestration;
- Claude;
- OpenAI;
- local models.

Model selection is external orchestration configuration.

## 13. AI authoring workflow

Recommended responsibility pipeline (one model/process may perform multiple stages when
policy permits; these are not mandatory permanent agent classes):

```text
brief
  ↓
architect
  ↓
content plan
  ↓
capability lookup
  ↓
world builder
  ↓
quest/dialogue builder
  ↓
compile
  ↓
deterministic validation
  ↓
Lab simulations/bots
  ↓
semantic reviewer
  ↓
repair loop
  ↓
human editorial/mobile smoke
  ↓
certificate
```

Not every step requires a separate model process, but responsibilities should be separable.

## 14. Context minimization

An authoring agent SHOULD retrieve only:

- relevant schemas;
- capability docs/examples;
- local cartridge neighborhood;
- incoming/outgoing refs;
- failing traces;
- deployment profile being targeted.

Do not feed the entire engine documentation on every turn.

## 15. Primitive proposal workflow

If the builder cannot represent requested behavior:

```json
{
  "ok": false,
  "code": "MISSING_CAPABILITY",
  "requested_semantics": "...",
  "nearest_capabilities": [...]
}
```

Agent may produce a capability proposal containing:

- semantic contract;
- definition/runtime schema;
- portability classification;
- commands/events/effects;
- determinism requirements;
- tests;
- migration/version impact;
- example usage.

That proposal enters normal engine-development review. It does not auto-install into production.

## 16. AI semantic review contract

Semantic reviewer receives compact artifacts:

- world graph;
- quest/dialogue graphs;
- NPC schedule timelines;
- relevant definition summaries;
- simulation traces;
- coverage gaps;
- deterministic warnings;
- offline/shared deployment differences.

Reviewer returns structured findings:

```text
finding ID
severity
entities/definitions involved
evidence trace
semantic explanation
suggested correction
confidence
```

No “looks good” approval substitutes for mechanical gates.

## 17. Audit trail

Every Builder API write records:

- actor/model/session;
- operation ID;
- workspace/revision;
- input digest;
- output/diff digest;
- timestamp;
- policy result;
- linked certification/PR where applicable.

Secrets/prompts with sensitive data should not be retained blindly.

## 18. Visual tools

Visual UI is primarily read/debug oriented:

- map;
- dependency graph;
- quest graph;
- dialogue graph;
- timeline;
- event trace;
- certification dashboard;
- offline-vs-online conformance view;
- shared-deployment scope view.

Visual editing may be added later only when it demonstrably improves a specific workflow.

## 19. Git relationship

For first-party cartridges, Git SHOULD remain the durable collaborative source history.

The Builder API may manipulate a workspace abstraction backed by:

- checkout/worktree;
- database staging store;
- generated patch set.

Publication records exact source commit + compiled content hash.

AI should not need raw Git operations for normal content work.

## 20. Factory and runtime separation

The factory may be completely offline and gameplay must continue.

No released world may require:

- Astra;
- Foundry;
- MCP server;
- Builder API write services

to run ordinary game mechanics.

## 21. Builder API schema source

Builder operations SHOULD be declared from a machine-readable registry containing:

- operation name/version;
- input schema;
- output schema;
- error codes;
- required policy;
- workspace mutation classification;
- dry-run support;
- examples.

Generate MCP tool declarations, terminal help, API docs, and contract tests from the same registry.

## 22. Agent permissions

When an orchestrator uses named roles, those names are Loka project/workflow vocabulary,
not runtime authority and not a fixed Foundry taxonomy.

Agent assignments SHOULD be capability-limited.

Examples:

- narrative author: content write, no publish;
- systems author: capabilities/content write, no engine merge;
- reviewer: read/simulate/comment, no mutation;
- release agent: stage exact certified hash only;
- engine developer: code change through Git workflow.

The Builder API must not expose “shell” or arbitrary filesystem execution as a normal authoring tool.

## 23. Foundry integration

Foundry MAY eventually orchestrate:

```text
objective
  → plan
  → specialized author agents
  → deterministic evidence
  → independent semantic review
  → correction
  → accepted artifact
```

But the Builder API and certification artifacts must remain independently useful without Foundry.

A future portability proof could use the Loka v3 repository as a materially different second project once Foundry's own repair gates are complete.


## 24. Builder expressive power: semantic composition, not arbitrary authority

The Builder's expressive-power contract is defined in [21 — Composable World Primitives and Builder Expressivity](21-composable-world-primitives.md).

The key rule is:

> **closed semantics, open composition**

Builders/agents should be able to create highly unusual mechanics and story situations by composing registered capabilities, without needing engine-code changes for every piece of content.

Normal builder expression includes:

- custom typed facts and namespaced DomainEvents;
- Policy/condition trees;
- bounded deterministic target selectors;
- Actions and ActionRecipes;
- ReactionRules;
- state machines;
- Behaviors and profiles;
- SpawnBundles;
- PopulationPlans;
- commerce definitions;
- Service compositions;
- Dialogue graphs;
- SceneSequences;
- quest graphs/outcomes/consequences;
- WorldEventPlans;
- templates/mixins/archetypes/recipes;
- bounded LokaScript;
- Lab tests/scenarios.

This is intentionally broad. What builders cannot do is introduce:

- arbitrary persistence writes;
- arbitrary BEAM/host code;
- hidden network/filesystem calls;
- new mutation authorities;
- unregistered effect types;
- untyped cross-system state mutation.

### Progressive disclosure and intent-first composition

The composition grammar is intentionally rich, but ordinary authors/agents SHOULD NOT need to choose among every low-level primitive before stating what they want.

The Builder SHOULD accept intent-oriented requests/operations and resolve them toward the **smallest typed composition shape** that preserves the mechanic's invariants. It may recommend or expand into ActionRecipe, ReactionRule, Behavior, StateMachine, SceneSequence, ServiceJob, PopulationPlan, Quest, WorldEventPlan, or another registered construct, but the user/model should not need to memorize the entire primitive taxonomy merely to create ordinary content.

Representative explain/assist operations may include:

~~~text
composition.suggest
composition.explain_choice
composition.alternatives
capability.explain_gap
~~~

For example, "a monk rings the bell at sunset" should normally lead the Builder through schedule/Behavior + Action/Reaction/Narration semantics, not force the author to select an abstraction from a long menu first.

Progressive disclosure has two rules:

- higher-level intent helpers MUST expand to the same canonical Builder operations and schemas; they are not a second mutation API;
- if several composition shapes are materially different in persistence, authority, multiplayer scope, or retry semantics, the Builder surfaces the decision instead of guessing.

R10 authoring telemetry/notes SHOULD record places where skilled humans or agents repeatedly choose the wrong construct. R11 uses that evidence to improve intent-level operations, documentation, and composition guidance; theoretical elegance is not enough if the primitive boundary is consistently hard to use correctly.

### Semantic Builder verbs

In addition to precise content CRUD, Builder v1 SHOULD grow intent-level operations from demonstrated R10 authoring pain.

Candidate operation families include:

~~~text
topology.connect
topology.make_barrier
detail.add
policy.attach
action.add
action_recipe.create
reaction.add
behavior.add
spawn_bundle.create
population.add
encounter.create
merchant.configure
service.configure
recipe.create
relationship.define
faction.define
rumor.define
scene.create
scene.add_beat
quest.attach_scene
world_event.create
world_event.add_phase
~~~

These are not a second storage API. They expand into ordinary workspace edits through the same revision/idempotency/audit layer.

### Explainability operations

Rich composition also requires rich explanation.

Builder/Lab should be able to answer:

~~~text
world.explain_target_resolution
world.explain_presence
world.explain_description
world.explain_behavior
world.explain_population
world.explain_price
world.explain_connection
world.explain_reaction
quest.explain_progress
scene.explain_state
world_event.explain_phase
~~~

The result should identify the facts/policies/capabilities/provenance that contributed to the current result.

### Capability-gap discipline

If the requested behavior cannot be expressed safely from registered semantics, return MISSING_CAPABILITY rather than encouraging an agent to hide a new subsystem inside LokaScript.

Conversely, do not promote every one-off pattern into engine code. Prefer, in order:

1. ordinary declarative configuration;
2. composition recipe/template;
3. ReactionRule/state machine/SceneSequence;
4. bounded LokaScript;
5. new versioned engine capability only when repeated semantics/invariants justify it.


## 25. Foundry/Astra orchestration: project roles map onto Loka layers

Loka's Builder API and certification contracts should be usable by Foundry, Astra, a
human operator, or another orchestrator without making any orchestrator part of gameplay
authority.

When Foundry is used, Loka SHOULD expose enough machine-readable policy for a
project/workflow profile to grant **different tool surfaces by role**.

Representative roles:

### World builder

Normal semantic scope: **L3–L6** from document 21.

May receive:

- Builder API workspace operations;
- capability discovery/docs/examples;
- content CRUD/semantic authoring operations;
- Cartridge Lab simulation;
- preflight validation;
- read-only certification evidence.

Should normally receive **no engine-source write surface and no arbitrary shell**.

### Quest/story builder

A narrower world-builder role focused on:

- quests;
- dialogues;
- scenes;
- storylines;
- facts;
- reactions;
- related world content explicitly in assignment scope.

A quest needing a missing mechanic does not authorize engine editing.

### Engine capability developer

May receive an isolated source checkout and approved build/test tools for explicit L2
capability work.

L0/L1 authority/transaction architecture changes require separately admitted
higher-risk scope.

### Semantic reviewer

Read/simulate only.

Receives the frozen candidate, exact relevant definitions, graphs, traces, CoverageManifest,
branch comparisons and rubric. It cannot mutate the candidate or publish.

### Certification/release role

May run/inspect mandatory certification and, where protected policy allows, stage only
the exact already-certified artifact/hash.

It cannot waive a failed gate or silently edit content to make a gate pass.

These are **project workflow roles**, not Loka runtime concepts and not mandatory model
identities.

## 26. Capability escalation contract

If a builder cannot express requested semantics from registered primitives:

~~~text
Builder API
 -> MISSING_CAPABILITY
 -> CapabilityProposal
~~~

A CapabilityProposal SHOULD include:

- requested behavior in domain terms;
- motivating content examples;
- nearest existing primitives and why composition is insufficient;
- proposed semantic invariants;
- portability need: portable / Realm-only / presentation-only;
- commands/events/deltas/effects/policies/bindings likely required;
- compatibility/migration implications;
- proposed deterministic/property/adversarial tests.

The originating builder cannot self-upgrade its authority.

An orchestrator may propose a separate engine-capability assignment, but protected
project/operator policy decides whether it is admitted and what source/tool scope it
receives.

After a new capability is implemented/released, the content workspace must explicitly
adopt the new capability version and rerun affected certification. Engine work does not
silently mutate the frozen cartridge candidate.

## 27. Context routing follows role and escalation

Astra/Foundry should not preload the whole engine into every authoring session.

### World/quest builder context

Prefer:

- permitted Builder operations;
- capability schemas/docs/examples;
- local cartridge neighborhood;
- incoming/outgoing references;
- relevant world/quest graph;
- failing Lab/certification evidence;
- L3–L6 composition guidance.

Normally omit:

- engine internals;
- unrelated platform/commerce code;
- protected release credentials;
- other projects.

### Engine developer context

Add only when escalation is admitted:

- exact CapabilityProposal;
- L0–L2 governing contracts;
- affected capability registry/schema;
- engine modules/callers/tests;
- compatibility locks/migration consequences;
- related regression/adversarial fixtures.

### Reviewer context

Supply:

- exact frozen candidate/hash;
- assignment/rubric;
- mandatory check receipts;
- coverage gaps;
- raw traces/evidence needed to challenge claims;
- relevant semantic intent.

A fast assessor may rank optional context, but mandatory policy/spec/evidence context is
chosen deterministically and cannot be removed for token savings.

## 28. Agents-as-tools versus authority handoff

A builder may use a bounded subagent/model as a **tool** for brainstorming, prose,
classification or candidate test generation while retaining the parent assignment's
authority and responsibility.

A real workflow **handoff** creates a new durable assignment/principal/grant.

Examples:

- world builder asks an LLM to suggest ambient descriptions -> tool/subtask, no new authority;
- world builder hits MISSING_CAPABILITY -> capability proposal -> possible protected
  handoff to engine-capability developer;
- content candidate freezes -> handoff to independent semantic reviewer.

A different model/session/role label alone does not establish reviewer independence.
Independence belongs to the orchestrator's durable principal/candidate-ownership policy.

## 29. Foundry is optional infrastructure

Loka MUST remain fully authorable/testable/releasable through its own Builder/Lab/
certification interfaces without Foundry.

Foundry integration is valuable because it can automate role scoping, evidence routing,
review/correction and escalation, but Loka remains the source of truth for:

- content semantics;
- Builder operation schemas;
- capability boundaries;
- Lab test semantics;
- certification profile/gate definitions;
- exact artifact identity.

The orchestrator cannot redefine what a passing Loka certificate means.

## 30. Small initial authoring surface

Before generalizing Builder, support the proof through named typed recipes and the same evaluator used for play. Authors need four explanations: why an action is present/absent; what a recipe reads/writes and may trigger; where validation failed; and what unsupported capability blocks the intended mechanic. `explain`, `preview`, `validate`, `trace` and `why_not` are interface responsibilities, not frozen API spellings.

Preview uses a disposable snapshot with isolated RNG and no publication handles. Source maps connect expanded operations to original input (05 §28). An LLM cannot fix a content conflict by broadening grants, changing expected baselines or editing the engine. Use the existing CapabilityProposal escalation. Human-readable proof traces and observed authoring/correction effort inform R11; generalized scripting, extra primitive catalogs and new proof-language toolchains are not R1 prerequisites.

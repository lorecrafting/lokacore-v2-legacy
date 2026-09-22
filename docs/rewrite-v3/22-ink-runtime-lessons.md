# 22 - Ink Runtime Lessons for Loka v3

**Study baseline:** Loka v3 at `c2303ca90115e7940d2b29ccb389da46b2f950c0`; inkle/ink at `35c63e52f1d36060930dc7ed3cfba38ea224b528` (v1.2.1); y-lohse/inkjs at `6b1153410ab1c4bcfd9ef04eb2f0107f36be7778` (v2.4.0); chromy/ink-proof at `eb6dbd33de8697b8d19c465549bbaa4d0fdc11a5`.

The requested local checkout was not mounted in the execution environment, so the same repository files were read through GitHub at the pinned commits above. Measurements below are against those exact trees. This is informative prior-art analysis, not a proposal to embed Ink or replace Loka's architecture.

## 1. Compiled artifact

### What Ink does

A compiled Ink story is a compact JSON instruction tree. The top level carries an `inkVersion`, a `root` runtime container, and optional list definitions. The runtime accepts format 18 through 21, rejects files newer than 21 or older than 18, and warns on a compatible mismatch (ink-engine-runtime/Story.cs:19-36, 208-236). Serialization writes the current format number, root container, and list definitions (Story.cs:263-281).

This is not merely passive object data. The runtime-format specification defines control instructions such as evaluation-stack operations, function/tunnel calls, thread creation, sequence shuffle, and termination, plus native operators, diverts, and external-function call instructions (Documentation/ink_JSON_runtime_format.md:74-114). Containers are arrays whose final object can hold named child containers and flags (Documentation/ink_JSON_runtime_format.md:20-24). It is therefore executable narrative IR interpreted by code already in the app, although it is not arbitrary C# or JavaScript source.

Repository-size measurement reinforces that compilation is not compression. Across 172 source/compiled fixture pairs in inkjs, 31,360 source bytes become 127,393 compiled bytes, 4.06x in aggregate and 4.88x at the median. The largest source fixture, src/tests/inkfiles/original/inkjs/tests.ink, is 11,811 bytes and its compiled JSON is 42,252 bytes, 3.58x. Tiny fixtures exaggerate ratios because every artifact pays structural overhead.

### Loka currently specifies

README sections 2 and 6, doc 07 sections 5 and 14, doc 09 sections 2-5, and doc 10 section 14 describe YAML/JSON-like authored content compiled into an immutable, hashed cartridge interpreted through capabilities shipped with the client. INDEX C3/C5 and M3 require identical artifact hashes, no hidden host callbacks, and downloaded content that remains declarative over shipped capabilities. ADR-035 remains the policy gate for downloaded rule treatment.

### Verdict: ADAPT

Ink validates a versioned, portable, interpreted artifact, but it also shows why "it is JSON" is not a sufficient App Store argument. JSON can encode an instruction machine. Loka should describe the cartridge as a bounded, validated rule IR whose opcode/capability vocabulary ships in the reviewed binary, with no arbitrary downloaded JavaScript/native modules or unregistered host calls. Keep explicit current/minimum-compatible artifact versions and fail closed on unsupported versions. Do not copy Ink's broad narrative VM instruction set merely because it is data-shaped.

### Loka change if adopted

Doc 07 section 5 and doc 10 section 14 should explicitly distinguish "serialized data" from "interpretable rule IR", state that policy posture rests on a bounded shipped capability vocabulary and certification, and define artifact current/minimum-compatible version fields. ADR-035 should use the same distinction.

## 2. Save state

### What Ink does

Ink separately versions saves. Current `inkSaveVersion` is 10 and minimum loadable is 8; comments identify v9 as multi-flow and v10 as dynamic tags (ink-engine-runtime/StoryState.cs:22-26). A current save contains flows and current flow name, global variables, evaluation stack, optional divert target, visit counts, turn indices, current turn index, story seed, previous random value, save version, and story-format version (StoryState.cs:654-700). Each flow serializes its call stack, output stream, current choices, and any choice-owned threads no longer present on the live call stack (Flow.cs:31-76). Call-stack threads serialize their frames and thread counter (CallStack.cs:116-166, 246-278).

Older v8 single-flow saves are loaded structurally when the `flows` object is absent: the loader reads legacy `callstackThreads`, `outputStream`, `currentChoices`, and choice threads, then loads the common variable/count/RNG state (StoryState.cs:704-794). There is no general migration framework here. Compatibility is mostly field-shape branching plus tolerant defaults. Notably, C# accepts a missing `previousRandom` because older inkjs saves accidentally omitted it (StoryState.cs:787-793).

Ink avoids embedding the immutable story tree in the save. It also omits globals equal to their defaults by default to make saves "potentially much smaller" (VariablesState.cs:159-169). The repository does not publish a large-story save-size benchmark. It does acknowledge that saving a large story to JSON can take long enough to affect frame rate and provides a background-save copy/patch path (Story.cs:828-835).

### Loka currently specifies

Doc 03 section 18 defines Snapshot as revision, cartridge hash, logical clock, RNG state, runtime entities, quest/scoped state, and durable scheduler reference. Doc 03 sections 14-15 make transaction commit and receipt persistence authoritative. Doc 10 section 28 requires old supported saves to remain openable offline through backward compatibility, deterministic migration, or bundled older interpreters. OFF-03 through OFF-13 test crash and upgrade behavior.

### Verdict: ADAPT

Copy the separation between immutable artifact and mutable save, independent save/artifact version numbers, explicit minimum compatibility, and default-value elision. Do not copy the assumption that interpreter internals such as output streams and evaluation stacks are automatically durable game state. Loka saves on every action, so its normal persisted form should stay as small and domain-canonical as possible. Any SceneSequence/dialogue continuation that truly must survive restart should be represented explicitly rather than by an opaque VM stack.

Ink also shows that compatibility needs real fixture coverage, not only a version integer. Loka's doc 10 rule is stronger because it treats offline upgrade continuity as a product guarantee rather than a best-effort loader.

### Loka change if adopted

Doc 03 section 18 should define separate snapshot-schema and cartridge/rule-IR compatibility versions, plus canonical omission rules for default/derived fields. Doc 10 section 28 should require compatibility fixtures for every supported snapshot version and state whether newer unsupported snapshot versions fail closed.

## 3. Determinism and RNG

### What Ink does

Within one runtime, Ink makes random continuation saveable by storing `storySeed` and `previousRandom`. RANDOM derives a new generator from their sum, records the generated integer as `previousRandom`, and SEED_RANDOM resets the seed and previous value (ink-engine-runtime/Story.cs:1495-1527). Shuffled sequences derive a seed from the sequence path hash, loop index, and story seed (Story.cs:2794-2813). Both values are serialized (StoryState.cs:691-698).

However, Ink is not evidence of cross-language RNG parity. The C# runtime uses System.Random. inkjs uses a Park-Miller generator with multiplier 48271 and modulus 2147483647 (src/engine/PRNG.ts:1-16), and its RANDOM path uses that generator (src/engine/Story.ts:1420-1444). inkjs issue #31 remains open specifically to align its PRNG with C# so randomness is the same on all platforms. ink-proof hides its seeded sequence fixture I106 with `"hide": "Uses randomness"` (ink/I106/metadata.json:1-7), and hidden fixtures are removed from runs (proof.py:667-671).

Numeric semantics expose another portability trap. C# integer division is native integer `x / y` (ink-engine-runtime/NativeFunctionCall.cs:330-357), which truncates toward zero. inkjs currently implements integer division as `Math.floor(x / y)` (src/engine/NativeFunctionCall.ts:377-403), which differs for negative results. inkjs has explicit machinery to retain int/float distinctions that JavaScript normally erases (src/engine/Value.ts:19-58), while C# formats float-to-string with invariant culture (ink-engine-runtime/Value.cs:170-197). Both runtimes use exact string equality and substring containment rather than locale ordering for Ink string operators (NativeFunctionCall.cs:387-392; inkjs src/engine/NativeFunctionCall.ts:433-438).

Ink also seeds a new unseeded story from wall-clock time: C# uses DateTime.UtcNow.Millisecond and inkjs uses Date.getTime() (StoryState.cs around 477-485; inkjs src/engine/StoryState.ts:440-445). That is acceptable for a narrative runtime that does not promise Loka-style replay, but not for Loka's deterministic kernel boundary.

### Loka currently specifies

DET-01 through DET-08 require canonical results, cross-host hash equality, replayable RNG, no wall-clock dependence, deterministic capability handling/order/IDs, and no numeric divergence. Doc 09 sections 3-4 already inject logical time and explicit RNG state. The R1 Tiny model includes an RNG check, and the envelope says candidate A uses integer or fixed-point rule-critical math.

### Verdict: ADAPT

Loka should be stricter than Ink. Specify the RNG algorithm, state representation, seed normalization, draw operation, modulo/range semantics, and RNG-version identifier as protocol, not implementation detail. Add vectors that assert both results and post-draw RNG state. Specify signed integer division/modulo behavior and numeric overflow/range behavior. Keep rule-critical floating point out of the portable kernel unless a future numeric profile defines exact cross-host semantics.

The Ink/inkjs split is especially relevant to candidate C: "same seed" is not enough. Candidate A also needs Node-versus-Hermes vectors because sharing TypeScript source does not by itself prove host numeric/serialization identity.

### Loka change if adopted

Doc 09 section 4 and r1-acceptance-envelope.md should name a concrete RNG algorithm/version and exact vectors. DET-03 and DET-08 should gain negative division/modulo, range-edge, and post-RNG-state cases.

## 4. Cross-implementation parity

### What Ink does

inkjs keeps a large mirrored fixture corpus under src/tests/inkfiles/original and src/tests/inkfiles/compiled. Its compile utility can regenerate compiled baselines with reference `inklecate` or the inkjs compiler, and comments explicitly frame failing-source fixtures as bytecode-diff tests for identical compiler output (src/tests/compile.js:6-10, 30-33, 77-99). At the pinned tree there are 198 source .ink fixtures, 176 compiled JSON fixtures, and 172 direct source/compiled path pairs. They are grouped by semantics such as choices, variables, diverts, builtins, evaluation, lists, sequences, threads, and multiflow.

Runtime version drift is caught first by the shared story-format contract: both current runtimes advertise format 21 and minimum compatible 18 (ink-engine-runtime/Story.cs:19-36; inkjs src/engine/Story.ts:52-55, 194-206). inkjs also publishes a compatibility table mapping ink/inklecate, inkjs, and JSON versions (README.md:208-230).

ink-proof adds implementation-neutral fixtures. Each case has story source or bytecode, input.txt, transcript.txt, and metadata.json; runtime drivers receive bytecode and choice input on stdin and emit stdout (README.md:23-25, 38-64). At the pinned commit there are 135 Ink cases and 7 hand-written bytecode cases. The harness compares stdout to the expected transcript using diff.py (proof.py:507-508, 705-723). It does not compare serialized runtime state. It detects incompatible bytecode as a distinct result (proof.py:20-24, 106-110) and permits metadata to hide unsupported/nonportable cases (proof.py:289-301, 667-671).

### Loka currently specifies

Doc 07 section 13 requires canonical, byte-for-byte domain results across hosts. Section 14 requires the Tiny fixture on BEAM, iOS, and Android with identical trace hashes and save/reload. Doc 09 section 5 defines cross-host conformance boot modes. R5 and R9C in INDEX require golden vectors and a conformance cartridge.

### Verdict: ADAPT

Adopt ink-proof's small, portable fixture-directory convention and inkjs's habit of keeping source plus compiled artifacts. Expand the oracle substantially. Transcript-only parity is too weak for Loka because two hosts can print the same text while diverging in hidden RNG, quest state, timers, IDs, or ordering.

Loka should compare both trace hashes and canonical state JSON. The trace hash gives a compact per-step behavioral identity and is ideal for CI summaries. Canonical state bytes catch hidden-state drift and make a hash mismatch debuggable. For the Tiny suite, also compare canonical Decision/StateDelta/DomainEvent/Effect bytes at every step. Hashes should be derived from those canonical bytes, not treated as the only oracle.

A concrete vector directory should contain: source YAML, expected compiled artifact bytes/hash, initial canonical Snapshot, commands.ndjson, expected per-step result.ndjson, expected per-step trace hash, expected checkpoint/final Snapshot JSON and hash, and metadata declaring required capability/RNG/schema versions. Every host adapter consumes exactly those files.

### Loka change if adopted

Doc 07 section 13 and doc 09 section 5 should define this fixture contract and require both canonical state bytes and trace hashes. R1 should gate on per-step parity for Tiny, not final trace hash alone.

## 5. Choices as validated input

### What Ink does

`ChooseChoiceIndex` reads the current visible choice list, bounds-checks the supplied index, restores the call-stack thread captured when that choice was generated, and diverts to its target (ink-engine-runtime/Story.cs:1789-1809). An invalid index reaches Ink's internal Assert, which throws a general exception (Story.cs:2860-2871).

A Choice carries display text, target path, source path, its generated list index, the thread snapshot at generation, an invisible-default flag, and tags (Choice.cs:4-49). The public selection API nevertheless uses the ephemeral list index, not a stable semantic choice ID or state revision. If a client submits an old numeric index after the visible choice set has changed, Ink can only validate it against whatever choices are current now. It has no invocation freshness token.

"Once only" is enforced earlier during choice generation: a once-only ChoicePoint is suppressed when the target container's visit count is already nonzero (Story.cs around 1076-1082). This is durable narrative-state validation, but still tied to Ink's path/count model.

### Loka currently specifies

DIA-01 validates choice conditions; DIA-02 revalidates stale choices and rejects them; DIA-06 guards semantic knowledge leaks. Doc 04 section 1 requires every ActionInvocation to be resolved and revalidated against current authoritative state. Doc 06 sections 17-18 give dialogue choices stable content identity and consequential durable state.

### Verdict: ADAPT

Copy the principle that only currently generated choices are selectable and that one-shot choices are enforced from durable state. Do not copy numeric list index as identity. Loka's stable ChoiceId plus dialogue/node identity, current revision/state revalidation, visibility/knowledge checks, and ordinary GameError rejection are stronger. A stale request that happens to reuse an index must never silently select a different choice.

The captured continuation concept is useful: a displayed choice can bind to the exact narrative continuation that produced it. In Loka that should be explicit data, not an opaque call-stack thread.

### Loka change if adopted

Doc 06 section 17 can state that a choice offer binds stable ChoiceId, dialogue/node identity, and any required continuation/version token. Doc 04 section 1 can make "numeric presentation index is never semantic identity" explicit.

## 6. Mutation model

### What Ink does

Normal Ink evaluation mutates StoryState in place. For lookahead and background saving, it has a targeted speculative mechanism. `CopyAndStartPatching` clones the current call stack, output stream, evaluation stack, current-flow control state, and sometimes choices; it shares immutable runtime objects and non-current named flows, then installs a StatePatch overlay for globals, visit counts, and turn indices (StoryState.cs:543-620). StatePatch itself is four small collections: patched globals, changed variable names, visit counts, and turn indices (StatePatch.cs:5-24, 27-59).

Lookahead stores the old state, evaluates against the patched copy, then either restores the snapshot or applies the patch (Story.cs:783-825). The same machinery lets a frozen state be serialized on another thread while play continues; completion later applies the diff (Story.cs:828-868).

This is not a general transactional StateDelta. Control-flow state, output, choices, evaluation stack, RNG state, and current turn are copied/mutated on the speculative StoryState object rather than represented as typed operations. Patch application also lacks Loka-style canonical target ordering and conflict detection.

Cost is therefore approximately "clone current interpreter continuation plus copy touched overlay entries", not "clone the whole story". That is a useful performance shape, but output/evaluation/call-stack size can still make copies nontrivial.

### Loka currently specifies

Doc 04 section 5 and doc 07 section 6 require decide-then-commit. StateDelta, events, effects, RNG advance, and logical-time changes remain proposals until authority commit succeeds; rejection or persistence failure discards them. StateDelta composition is a typed proposal overlay with canonical ordering/conflict rules.

### Verdict: ADAPT

Borrow the copy-on-write overlay idea as an implementation technique for candidate kernels, not Ink's StatePatch representation. Loka's public decision result should remain explicit and complete. Internally, an efficient materializer may layer reads over committed state and record touched fields with structural sharing, then lower those changes into canonical StateDelta/RNG/time outputs. That preserves "no hidden advancement before commit" while avoiding full-world copies.

Do not let a retained kernel handle behave like Ink's mutable current StoryState unless R1 proves that every failed commit can restore every hidden cursor, RNG value, queue, and cache exactly.

### Loka change if adopted

Doc 07 section 6 should mention copy-on-write/structural-sharing overlays as an allowed internal strategy only when all externally relevant mutations are surfaced in the proposal. The normative StateDelta model in doc 04 section 5 should not change.

## 7. External functions, observers, and bindings

### What Ink does

Ink can bind an EXTERNAL instruction to an arbitrary host delegate. On first Continue it walks the story and validates external bindings; missing bindings become a runtime error unless fallback functions are allowed and a same-named Ink function exists (Story.cs:2384-2447). At invocation time, fallback diverts into that Ink function; with fallbacks disabled a missing binding asserts (Story.cs:1943-2001).

Host functions are not capability-sandboxed. They can perform any C# side effect the host permits. Ink explicitly warns that lookahead may call a bound function earlier or twice, and says side-effecting functions are normally not `lookaheadSafe` (Story.cs:2043-2053). Unsafe calls can force snapshot rewind behavior (Story.cs:1978-1983).

Variable observers are host callbacks. Multiple changes during one evaluation are batched and the observer is called once at the end; external writes to VariablesState can also trigger observers (Story.cs:2450-2481). Continue reports variable observations only after evaluation has finished (Story.cs:584-586).

### Loka currently specifies

Doc 06 section 25 defines a script binding registry with typed schemas, cost/portability metadata, and portable-only offline bindings. Mutation bindings return typed delta/events/effects rather than writing databases. ReactionRules are deterministic rule-domain reactions. Doc 07 section 5 forbids network, filesystem, database, wall-clock, and global RNG access in the portable boundary.

### Verdict: ADAPT

The registry/fallback-validation shape is useful; the unrestricted callback semantics are not. Loka should validate every binding name and version before certification/activation, fail closed when a required capability is absent, and permit a fallback only when it is itself compiled/certified portable content. During decide, bindings should be pure with explicit inputs/outputs. External effects should remain post-commit Effects.

Ink observers are best compared to Loka post-commit projections or diagnostics, not ReactionRules. ReactionRules affect authoritative decisions and therefore belong inside deterministic evaluation, while observers are notification hooks.

### Loka change if adopted

Doc 06 section 25 should require preflight validation of every referenced binding/capability and define fallback eligibility. It should explicitly prohibit host callbacks with irreversible side effects during portable decision evaluation.

## 8. Error handling

### What Ink does

StoryException is documented as a runtime story/authoring error, usually a bug in Ink rather than the runtime (ink-engine-runtime/StoryException.cs:3-8). Continue catches StoryException from stepping, records it as a runtime error, and stops the flow (Story.cs:466-470). Errors and warnings are later delivered to `onError`; without a handler, Ink throws a StoryException summarizing them (Story.cs:533-580). Warning and Error add source/path context to the state error list (Story.cs:2824-2853).

Internal API contract violations use ordinary assertions/exceptions. Invalid choice index is one example (Story.cs:1794-1798, 2860-2871). Missing external bindings likewise become runtime errors/assertions depending on when detected.

### Loka currently specifies

Doc 04 section 5 says, "Expected gameplay failure is data, not exception control flow." Rejections return GameError and carry no committed mutation, event, effect, RNG, time, or hint advancement. DET-11 covers portable faults separately from ordinary rejected actions.

### Verdict: REJECT

Do not copy Ink's exception path for expected player failures. Loka's distinction is better for replay, telemetry, clients, and authority commit. Borrow only the separate category for authoring/runtime faults and warnings. A malformed cartridge, impossible invariant, missing required capability, or kernel defect can be a fault; "door locked", "choice stale", and "already taken" remain data.

### Loka change if adopted

No change to doc 04 section 5. Doc 09 certification could add a standard portable-fault record containing artifact/path/source metadata analogous to Ink's enriched runtime errors.

## 9. Multiple flows and threads

### What Ink does

A Flow is a named bundle of call stack, output stream, and current choices (Flow.cs:5-16). StoryState can hold multiple named flows and switch which is current while variables and counts remain story-global (StoryState.cs:658-677 and the flow-loading logic at 714-750).

Ink "threads" are interpreter continuations, not OS threads. A thread is a call-stack frame list plus thread index and previous pointer; PushThread/ForkThread clone the current continuation (CallStack.cs:43-54, 272-285). Choices retain the thread that existed when generated, so choosing can restore the correct leading edge (Story.cs:1799-1808). Thread state is serializable.

### Loka currently specifies

INDEX row 25 describes SceneSequence as durable/checkpointed narrative sequencing. Row 26 describes InstancePlan as scoped temporary spatial simulation with an explicit export policy. Doc 06 and doc 07 keep these as domain mechanisms rather than hidden interpreter concurrency.

### Verdict: ADAPT

Borrow explicit, serializable continuation identity where Loka needs to resume a multi-step narrative after save/reconnect. In particular, a choice offer may point to a durable SceneSequence continuation token. Do not import Ink's multi-flow/thread VM abstraction into InstancePlan or actor ownership. Ink threads solve branching interpreter control flow; InstancePlan solves scoped world simulation and has different authority/lifetime concerns.

### Loka change if adopted

Doc 06's SceneSequence section should define a small serializable continuation/checkpoint shape if it does not already. INDEX row 26 and InstancePlan architecture need no change.

## 10. Runtime size and performance

### What Ink does

Measured at the pinned commits, ink-engine-runtime contains 34 C# files, 10,673 physical lines and 8,795 nonblank lines. inkjs src/engine contains 40 TypeScript files, 9,655 physical lines and 8,160 nonblank lines. These are repository measurements, not upstream claims.

The repositories publish no repeatable Continue latency, large-story parse-time, or save-size benchmark that can validate Loka's millisecond/byte thresholds. They do expose two operational signals. First, C# Ink has ContinueAsync with a millisecond budget specifically to spread long evaluation over frames (Story.cs:395-421). Second, it has background-state saving because large-story JSON serialization may be too slow for a frame (Story.cs:828-835). VariablesState also optimizes save size by omitting unchanged defaults (VariablesState.cs:159-169).

### Loka currently specifies

The R1 envelope has Tiny/Medium/Stress command latency targets, BEAM boundary budgets, snapshot byte/time budgets, memory targets, crash containment, and an unchanged-on-Hermes dependency gate. The app saves on every action.

### Verdict: ADAPT

Nothing in Ink's public evidence makes the current Loka thresholds obviously unrealistic, but Ink does not supply numbers strong enough to justify loosening them either. Keep the present thresholds as spike gates and measure. The important Ink lesson is to separate warm command cost from cold artifact parse/init cost and to measure serialization independently from durable write cost. Save-on-every-action makes dirty-state size and incremental persistence more important to Loka than to a typical Ink host.

The approximately 10k-line engine size is encouraging for R1 candidate A or B: a portable semantic kernel can remain reviewable. It is not evidence that Loka's broader world rules will fit the same size.

### Loka change if adopted

r1-acceptance-envelope.md should add cold artifact parse/init timing and separately record snapshot serialization time, serialized bytes, and database/fsync time. Do not loosen existing command or save thresholds based on Ink.

## 11. TypeScript port viability

### What Ink does

inkjs is concrete evidence that the Ink runtime can be maintained as a roughly 10k-line TypeScript engine. Its package declares no production dependencies, and README calls it zero-dependency and browser/Node compatible (package.json:1-18, 61-90; README.md:7-10). The package exposes engine and compiler modules plus bundled dist entry points (package.json:19-41).

The engine heavily uses ES2015 Map/Set. VariablesState optionally wraps itself in Proxy for ergonomic property access, but catches lack of Proxy and leaves the explicit accessor path available (src/engine/VariablesState.ts:140-181). No uses of Intl or BigInt were found in src/engine at the pinned commit. Proxy is used. The repository does not document React Native or Hermes execution, and repository issue search found no React Native/Hermes validation to cite, so that part remains unverified.

The biggest viability warning is semantic, not dependency weight. JavaScript has one Number type, so inkjs carries explicit int/float tagging and parse workarounds (src/engine/Value.ts:19-58; src/engine/SimpleJson.ts:32-44). Its integer division currently uses Math.floor while C# uses integer division, and its PRNG is intentionally not C# System.Random. SimpleJson ultimately serializes a JavaScript object with JSON.stringify (src/engine/SimpleJson.ts:329-335). VariablesState and multi-flow serialization iterate Maps in insertion order rather than sorting keys (src/engine/VariablesState.ts:220-233; src/engine/StoryState.ts:612-625). That is acceptable for semantic save compatibility, but it is not a design for Loka's cross-language canonical byte identity.

The built dist files are not committed at this snapshot, so no trustworthy bundle-size number can be derived from the repository. Package metadata shows Rollup-based bundling (package.json:43-53). R1 should measure release-build Hermes bundle contribution directly rather than import an npm dashboard number.

### Loka currently specifies

Candidate A is one TypeScript kernel used natively by React Native and through an Erlang Port on BEAM. The envelope says the kernel package "MUST run unchanged on Hermes with no polyfills", contain no native modules, and use integer or fixed-point rule-critical math.

### Verdict: ADAPT

inkjs makes candidate A credible enough to spike: a substantial narrative runtime can be zero-dependency TypeScript and run in browser/Node environments. It does not prove Node/Hermes byte-identical behavior. In fact, its long-running PRNG and numeric-portability issues are a warning to make Loka's numeric, RNG, canonical-serialization, and iteration-order contract explicit before implementation.

For candidate A, avoid reliance on Proxy in kernel semantics, sort every map/set-derived serialization path explicitly, keep rule-critical integers inside a documented safe range, use a specified fixed-point representation when fractions are needed, and use an in-kernel PRNG with golden vectors. The BEAM Port and Hermes hosts should treat the same package as a protocol appliance, not reimplement semantics.

### Loka change if adopted

r1-acceptance-envelope.md dependency-risk section should add direct checks for deterministic Map/object canonicalization, no semantic dependence on Proxy, and exact Node-versus-Hermes numeric/RNG/serialization vectors. Doc 07 section 13 should state that shared source is not an exemption from cross-host conformance.

## Recommended changes to r1-acceptance-envelope.md

| Change | Recommendation | Evidence |
|---|---|---|
| RNG profile | Add a named RNG algorithm/version, seed normalization, range/modulo rules, and at least 100 fixed expected draws plus expected post-draw state on every host. Include save/reload mid-sequence. | Ink saves seed/state, but C# uses System.Random while inkjs uses a different PRNG (Story.cs:1495-1527; inkjs PRNG.ts:1-16), and ink-proof hides randomness (I106 metadata:1-7). |
| Numeric edge gate | Add vectors for negative integer division/modulo, zero divisor fault behavior, safe-integer boundaries, fixed-point multiply/divide/rounding, and integer serialization. | C# integer division and inkjs Math.floor differ for negatives (NativeFunctionCall.cs:330-357; inkjs NativeFunctionCall.ts:377-403). |
| Canonical state gate | For every Tiny action, compare canonical Decision bytes, trace hash, and canonical Snapshot bytes/hash on all hosts. Keep final/checkpoint state comparisons for Medium/Stress. | ink-proof compares only transcripts (README.md:23-25; proof.py:507-508), which cannot catch hidden-state drift. |
| Artifact gate | Compile the same Tiny source at least twice and require identical artifact bytes and hash, then reject unsupported artifact version before evaluation. | Ink has explicit current/minimum-compatible story versions (Story.cs:19-36). Loka's hello fixture already expects repeated compile-hash identity. |
| Cold-start budget | Add cartridge parse/validation/init p50/p95/p99 separately from warm command latency, for Tiny/Medium/Stress. | Ink's runtime architecture separates parse/construction from Continue, but publishes no parse benchmark. |
| Save decomposition | Keep current total save budgets, but record serialization bytes/time separately from SQLite write/fsync and reload/hash validation. Add a "many defaults, few mutations" and "many dirty fields" profile. | Ink omits unchanged globals and provides background save because JSON serialization can hurt frame time (VariablesState.cs:159-169; Story.cs:828-835). |
| Candidate A engine parity | Run the exact production bundle on Hermes and the BEAM-side JS host with vectors for Map ordering, object serialization, Proxy absence, Unicode strings, integer edges, and RNG. No polyfill fallback in the scored path. | inkjs is zero-dependency but uses Map, optional Proxy, JS Number, and JSON.stringify (package.json:1-18; VariablesState.ts:140-181; SimpleJson.ts:329-335). |
| Stale-choice adversary | Add a vector where a previously displayed numeric position is reused after the choice set changes. It must reject unless the submitted stable ChoiceId still names an eligible current choice. | Ink validates only current index bounds (Story.cs:1789-1809), so index reuse is not a freshness guarantee. |
| Binding preflight | Add activation-time failure for unknown/missing portable capability bindings before the first player command. | Ink validates all externals on first Continue (Story.cs:2384-2447); Loka can move this earlier into cartridge certification/activation. |

No existing latency, save-size, or BEAM-boundary threshold should be loosened from Ink evidence. The study suggests adding observability and semantic gates, not relaxing performance gates.

## Open questions for Raymond

1. **ADR-035 expressiveness boundary.** Ink proves that JSON can encode a real instruction machine. For Loka's store posture, do you want the portable rule IR intentionally restricted to finite capability composition with bounded control constructs, or may it eventually contain general loops/functions so long as the interpreter and capabilities ship in the app? The code study cannot settle the policy/product boundary.

2. **Canonical snapshot scope.** Should conformance snapshots include only durable authoritative domain state, RNG/logical time, scheduler state, and narrative continuation tokens, while presentation/output buffers live only in trace/view fixtures? I recommend that split, but the exact boundary is a product decision if offline UI restoration requires pending presentation state.

3. **Compatibility horizon.** Doc 10 section 28 leaves the support window configurable. Ink gives a minimum compatible save version but no lesson for how many years/releases Loka should guarantee. That horizon should be chosen explicitly before release engineering locks migration/bundled-interpreter policy.

4. **Hermes evidence.** I found no repository evidence that current inkjs has been validated on React Native/Hermes. This does not argue against candidate A, but it means R1's real-device Hermes run remains primary evidence rather than something this prior-art study can settle.

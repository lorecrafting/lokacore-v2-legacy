# Continuation prompt: v3 R1 preparation

Paste everything below this line into a fresh session.

---

You are continuing work on the Loka v3 clean-room rebuild specification in `docs/rewrite-v3/`. Read this whole prompt, then the files listed under "Read first," then do the two tasks. Do not re-read the entire packet; it is about 99k tokens and the index you are writing exists so nobody has to.

## Where things stand (2026-09-21, main at 6974e0a)

- The packet is Draft 0.5, awaiting R0 acceptance. An independent review found the authority architecture sound and the plan too large; the response was a named first product and a release ladder, not a trim.
- `00-first-cartridge-design.md` names the first game, The Fox of Ashmere: Western low-fantasy, classic-MUD mechanic density, touch-first UI, six exits with a real z-axis. §11 is a three-chapter release ladder; chapter one is the R10 cartridge and the free showcase.
- `00a-chapter-one-content.md` is the exact chapter-one content: 57 rooms, 16 NPCs, 10 quests in packet grammar, and a hello-world fixture in §12 that is the R4 compiler fixture and the R1 spike model.
- Doc 14 R1 now compares three candidates: (A) one TypeScript kernel, native in React Native, reached from BEAM through a Port; (B) one Rust kernel; (C) dual Elixir/TypeScript. None is selected. The chapter-one workload is almost all derived state and pure reducers, which favors A.
- LokaScript is deferred (ADR-018). Doc 09 §1a lists the R9 minimum gates. Doc 14 has a sizing table. Doc 18 §32 records all of this.
- Decisions already made by Raymond; do not re-open them: density over trimming, the chapter ladder, Western setting, no bank loans, no gambling, touch-first, TypeScript kernel as candidate A.

## Read first

1. `docs/rewrite-v3/README.md` §2 (axes, pipeline, vocabulary) and §8 (authority map)
2. `docs/rewrite-v3/00-first-cartridge-design.md` §1 and §11
3. `docs/rewrite-v3/00a-chapter-one-content.md` §1 and §12
4. `docs/rewrite-v3/14-implementation-plan.md` R0, R1, R3, R10 and the Sizing section
5. `docs/rewrite-v3/16-decision-register.md` ADR-004, ADR-018, ADR-059
6. `docs/rewrite-v3/09-cartridge-lab-certification.md` §1a
7. `docs/rewrite-v3/18-review-record.md` §32

## Task 1: draft the R1 acceptance envelope

Create `docs/rewrite-v3/r1-acceptance-envelope.md`. Doc 14 R1 requires it to be committed before any spike code exists. One to two pages. It must fix, with numbers where a number is meaningful:

- the tiny model: use `00a` §12 as-is; a medium model of chapter one's full 57 rooms and 16 NPCs; a stress model of the full 109-room design with 10 populations at cap;
- command mix: look, move, take, talk/choose, wait, plus one reaction chain and one scene beat, per 1,000 commands;
- target devices: one development machine class, one minimum iOS device, one minimum Android device (propose specific models; Raymond decides);
- per-decision latency ceilings p50/p95/p99 on the minimum devices for each model size;
- serialization budget: bytes crossed per decision under state-in/state-out versus retained handle versus touched-slice strategies;
- BEAM boundary: for A, Port round trip ceiling; for B, normal-NIF scheduler occupancy ceiling;
- save round trip size and time for each model;
- memory growth over 10,000 commands;
- crash containment: what a kernel fault must never do (commit partial state, duplicate a command);
- build and debug criteria: Expo/EAS build passes on both platforms, a kernel stack trace is readable on device, one upgrade of the kernel package does not require a native rebuild for A;
- dependency risk: any third-party binding generator marked early-development is disqualifying for B;
- the comparison procedure: A is built first; B and C are built only if A fails its envelope; the same hello-world trace hash must match on every host for whichever candidate is kept.

Mark every number as "proposed, Raymond to confirm." Do not tune thresholds to favor any candidate.

## Task 2: write the compact specification index

Create `docs/rewrite-v3/INDEX.md`. This is the R0 deliverable the packet promises: the implementation-facing architecture and invariant index. Hard limits: under 10,000 tokens, under 40 distinct named concepts. Rules:

- one line per invariant, each linking to the governing document and section, the ADR, and the acceptance scenario IDs that test it;
- the canonical pipeline diagram from README §2 once;
- the vocabulary table, reduced to the concepts an implementer of chapter one must know;
- the chapter ladder in one table;
- the R-phase gate list in one table with the sizing ranges;
- the deliberately open evidence gates (R1, ADR-035, R20) in one short list;
- nothing explanatory; rationale lives in the numbered docs.

Anything in the normative packet that cannot be stated in this index is a candidate for deletion. Produce a second file, `docs/rewrite-v3/INDEX-cut-candidates.md`, listing each such section with one line on why it did not fit. Do not delete anything from the packet yourself.

## Constraints

- Follow the packet's own conventions: MUST/SHOULD/MAY, six exits only, no `Code.eval_string`, no `server_only` capability in chapter one.
- Do not add scope. If a task reveals a contradiction between two normative docs, record it in doc 18 as a new subsection and stop at that boundary rather than picking a side.
- Commit each task separately with a `docs(v3):` message, end the message with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`, and push to `main`.

## Raymond's own tasks, not yours

- Put one online-private story from Lokacore on TestFlight to test the offline-first belief cheaply.
- Read Ink's runtime source (inkle) for a few hours before signing the envelope; it has solved cross-host narrative-state parity already.
- Confirm the envelope's device classes and latency numbers.

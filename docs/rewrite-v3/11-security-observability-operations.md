# 11 — Security, Observability, and Operations

<!-- packet-navigation:start -->
[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)

**Reader context:** Design contract: safety and operations.

Distinguish always-needed integrity/recovery from later online operations. LokaScript security is retained deferred design.

<details>
<summary>Sections in this document</summary>

- [1. Trust zones](#1-trust-zones)
- [2. Online authority checks](#2-online-authority-checks)
- [3. Offline trust boundary](#3-offline-trust-boundary)
- [4. Builder authorization](#4-builder-authorization)
- [5. Fail closed](#5-fail-closed)
- [6. LokaScript security](#6-lokascript-security)
- [7. Portable-kernel implementation safety](#7-portable-kernel-implementation-safety)
- [8. Content integrity](#8-content-integrity)
- [9. Artifact signing trust and key rotation](#9-artifact-signing-trust-and-key-rotation)
- [10. Secrets](#10-secrets)
- [11. Observability identity](#11-observability-identity)
- [12. Structured logs](#12-structured-logs)
- [13. Telemetry](#13-telemetry)
- [14. Tracing](#14-tracing)
- [15. Game trace store](#15-game-trace-store)
- [16. Health/readiness](#16-healthreadiness)
- [17. Deployment](#17-deployment)
- [18. Rolling deploys](#18-rolling-deploys)
- [19. Backups](#19-backups)
- [20. Admin operations](#20-admin-operations)
- [21. Rate limits and abuse](#21-rate-limits-and-abuse)
- [22. Crash reporting](#22-crash-reporting)
- [23. Supply chain](#23-supply-chain)
- [24. SLO candidates](#24-slo-candidates)
- [25. Incident principle](#25-incident-principle)
- [26. Account progress is low-trust input, durable product state](#26-account-progress-is-low-trust-input-durable-product-state)

</details>
<!-- packet-navigation:end -->

## 1. Trust zones

### Untrusted

- mobile requests;
- text command input;
- offline save files from a security perspective;
- future public creator input;
- external webhook payloads.

### Authenticated but bounded

- normal online player commands;
- purchased cartridge access;
- account API.

### Privileged

- builder operations;
- admin;
- publication;
- engine capability development.

### First-party trusted source with runtime restrictions

- certified cartridge definitions;
- certified portable LokaScript.

Trusted provenance does not mean bypassing determinism/budgets.

## 2. Online authority checks

Gateway authenticates account/session.

Runtime verifies:

- character controlled by account/session;
- character allowed in instance;
- action/policy;
- entitlement where relevant;
- command scope/target presence;
- expected revision where required.

Do not rely solely on hidden mobile buttons.

## 3. Offline trust boundary

The local device owns offline gameplay experience but is not trusted as an MMO economy authority.

Offline saves may be modified by users or tools.

Therefore:

- local play remains functional;
- local save integrity checks detect accidental corruption, not “prove honesty”;
- valuable online state is never derived from offline inventory/currency/stat values;
- optional narrative-memory imports are explicitly non-competitive.

## 4. Builder authorization

Builder API operation metadata declares required policy.

Examples:

```text
read workspace
edit workspace
run lab
certify
stage
publish
rollback
engine capability admin
```

Publication is more privileged than editing.

## 5. Fail closed

Unknown:

- operation;
- policy operator;
- capability;
- script binding;
- protocol schema;
- effect;
- content kind

is rejected.

## 6. LokaScript security

> **Deferred design:** ADR-018 defers LokaScript until a demonstrated composition gap is admitted. This retained design is not a chapter-one build requirement; it constrains that feature if admitted.

Portable custom interpreter is the primary semantic boundary.

Defense in depth:

- source length;
- parsed AST/bytecode whitelist;
- no module dispatch;
- no BEAM process primitives;
- no filesystem/network;
- deterministic bindings;
- step counter;
- effect/query quotas;
- memory/collection limits;
- non-semantic host wall-time kill switch as an outer safety guard;
- result size;
- telemetry;
- certification fuzz suite.

Deterministic step/query/memory/effect budgets define normal script failure semantics. The host wall-time guard exists only to protect a device/process from implementation failure or pathological behavior and MUST NOT become a cartridge-visible cross-host timing rule. If it fires during certified supported input, treat that as a runtime/conformance fault.

If public scripting arrives, conduct a dedicated security review and consider additional OS-process isolation even with the custom interpreter.

## 7. Portable-kernel implementation safety

The portable rules implementation becomes high-trust code regardless of language.

Common requirements:

- fuzz parsers/deserializers;
- canonical input size limits;
- cartridge-driven allocation/work quotas;
- versioned serialization;
- hostile package corpus tests;
- well-defined failure/panic/exception handling at host boundaries.

If R1 accepts a Rust/native kernel, additionally require:

- safe Rust by default;
- unsafe code denied/linted unless explicitly justified/reviewed;
- panic handling at the FFI boundary;
- no cartridge-driven native allocation without quotas.

If R1 chooses a non-native implementation, apply equivalent sandbox/resource/error-boundary requirements for that implementation.

On BEAM, any native long/heavy kernel operations must not block normal schedulers.

## 8. Content integrity

Compiled cartridge/deployment has a canonical **semantic content/deployment hash** plus a separate release/signature/attestation envelope.

Published release stores:

- source revision;
- compiler version;
- kernel/schema versions;
- semantic cartridge/content hash;
- deployment/adaptation hash where applicable;
- certificate hash;
- signing/attestation metadata;
- optional package/transport hash for exact downloadable bytes;
- build identity.

Certificate/signature/reference material is not part of the semantic hash domain it attests; otherwise certification/signing would create a self-referential hash cycle.

Runtime/local client refuses artifact/hash mismatch.

Package ingestion is hostile-input handling even for first-party distribution. Download/install code MUST enforce declared and actual size limits, bounded decompression, path normalization/no archive traversal, duplicate-path rules, media/type validation where relevant, and atomic staging-before-activation. A signed package is not allowed to bypass parser/resource limits.

## 9. Artifact signing trust and key rotation

Signed cartridge/catalog artifacts MUST include:

- signing key ID;
- signature algorithm/version;
- semantic artifact/content hash;
- signed metadata version.

The mobile app ships or securely obtains a trusted public-key set.

Key rotation rules:

- new signing keys may be introduced before old keys are retired;
- old public keys remain available long enough to verify still-supported installed cartridges;
- compromised keys can be revoked on reconnect, but true offline operation means already-downloaded content cannot always be remotely revoked immediately;
- private signing keys never ship to clients;
- build/certification records identify which key signed each release.

Signature verification proves publisher/artifact integrity. It does not make offline save state authoritative for the MMO.

## 10. Secrets

Use runtime secret management/env/provider appropriate to deployment.

Secrets never enter:

- cartridge source;
- Builder API outputs;
- traces exported to models;
- mobile bundle except public keys/config intended public.

## 11. Observability identity

Every online command records/correlates:

```text
request_id
command_id
correlation_id
session_id
account/character IDs as privacy policy allows
instance_id
cartridge/deployment hash
instance revision before/after
kernel version
```

Offline debug traces use local save/instance IDs and should not be uploaded by default.

## 12. Structured logs

Logs are structured events, not prose-only strings.

Examples:

```text
runtime.command.accepted
runtime.command.rejected
runtime.commit.failed
runtime.instance.restarted
effect.retry
builder.operation
certification.gate
kernel.conformance_mismatch
protocol.validation_failed
```

PII fields are minimized/redacted.

## 13. Telemetry

Metrics:

### Runtime

- active sessions;
- active instances/shards;
- command rate/latency;
- kernel decision latency;
- mailbox length;
- DB commit latency/conflicts;
- restarts;
- snapshot load/save;
- scheduler jobs.

### Effects

- outbox pending;
- retry count;
- oldest pending age;
- permanent failures.

### Builder/certification

- compile duration;
- validation errors;
- simulation throughput;
- semantic-review findings;
- content-only ratio;
- certification escape defects.

### Commerce

- verification success/failure;
- entitlement reconciliation;
- restore failures;
- cartridge download/hash failures.

## 14. Tracing

OpenTelemetry-style span/correlation model SHOULD allow:

```text
channel command
  -> WorldInstance call
  -> kernel decision
  -> DB transaction
  -> domain event chain
  -> effect
  -> client projection
```

Do not trace giant state payloads by default.

## 15. Game trace store

Separate debug/game trace from generic application logs.

Trace captures compact:

- command;
- event chain;
- state delta digest;
- RNG draws if configured;
- effect IDs;
- revision.

Retention can vary by environment/profile.

Certification retains reproducible traces longer than ordinary production.

## 16. Health/readiness

Liveness: BEAM process responds.

Readiness checks:

- PostgreSQL connectivity;
- required cartridge registry loaded;
- kernel loaded/version compatible;
- migrations current;
- critical scheduler/effect services alive.

Do not fail readiness because an optional AI/provider is unavailable.

## 17. Deployment

Recommended initial online topology:

```text
one Phoenix/BEAM application cluster size 1
+
managed PostgreSQL
+
object storage/CDN for cartridge assets
```

Scale vertically/replica read services before introducing distributed-world complexity unless measurements demand it.

## 18. Rolling deploys

Online release process:

1. database backward-compatible migration when possible;
2. deploy new application;
3. old/new protocol compatibility window;
4. instances either continue if kernel/content compatible or checkpoint/restart gracefully;
5. remove old compatibility in later release.

Exact hot-code-upgrade support is not a foundation requirement.

## 19. Backups

Back up:

- PostgreSQL;
- published cartridge artifacts/source refs;
- entitlement/catalog state;
- certificate metadata;
- critical object storage.

Regularly test restore, not only backup creation.

Offline saves use device/platform backup/cloud-save mechanisms separately.

## 20. Admin operations

Admin actions go through typed audited APIs.

Examples:

- inspect instance;
- kick session;
- pause instance;
- force snapshot;
- grant/revoke entitlement with reason;
- stage/rollback cartridge;
- inspect outbox;
- replay repro bundle in staging.

No production admin shell should be the normal operational interface.

## 21. Rate limits and abuse

Rate limits by:

- IP/account/session;
- command class;
- chat/social;
- expensive pathfinding/search;
- builder operations.

Runtime command queues bounded.

Shared MUD later adds:

- chat moderation;
- economy abuse;
- automation/bot policy;
- spam/flood controls.

## 22. Crash reporting

BEAM crashes should include correlation/instance IDs but not dump secrets or enormous state.

Mobile native-kernel crashes require symbolicated iOS/Android reporting.

A crash should ideally point to a deterministic repro seed/snapshot if privacy and storage policy allow.

## 23. Supply chain

Pin/check:

- Hex deps;
- Cargo deps;
- npm deps;
- GitHub Actions;
- build tool versions.

CI runs dependency/security audits.

Native kernel release artifacts must be reproducibly associated with source commit and build pipeline.

## 24. SLO candidates

Before launch define measurable targets, for example:

- online command p95;
- crash-free sessions;
- offline save corruption rate;
- purchase restore success;
- cartridge download integrity success;
- world-instance restart recovery;
- outbox max age.

Numbers come from vertical-slice benchmarks, not guessed here.

## 25. Incident principle

Correctness over availability for authoritative mutations.

If runtime cannot prove a command committed safely, return/recover/retry rather than inventing success.

Ambient presentation may degrade; money/items/quest progression must not.

## 26. Account progress is low-trust input, durable product state

[Document 23](23-accounts-progress-admission.md) defines first-release account progress and onboarding-only acceptance. Authenticate the principal, enforce immutable run binding and input budgets, and assign evidence class only at the trusted ingestion boundary. A signed cartridge, a device claim, or an LLM opinion is not proof of human completion. Replay and server-authoritative evidence may be introduced later through separate trusted workflows.

Progress acceptance and admission use durable platform records, not sampled analytics. Account deletion must serialize against ingestion, revoke credentials and prevent old queues from recreating deleted state. Minimize private data and implement per-account access control, secure credential storage and abuse limits before public launch. Account outage never converts Realm to local authority and never blocks installed offline Story play.

# Proposed portable numeric profile v1

Status: proposed R1 input, not an accepted production ABI. Review/freeze before candidate performance results. This profile is deliberately small and is separate from runtime selection.

## Integers and representation

Rule-critical integers are exact signed integers in `[-9007199254740991, 9007199254740991]`. Overflow is a typed error, never wraparound or silent floating-point rounding. Division truncates toward zero; remainder is `a - trunc(a/b)*b`; zero divisors fail. Intermediates must be checked or evaluated with sufficient precision before range checking. Booleans are not integers. Fixed-point capabilities must separately name scale and rounding; this profile does not silently define them.

The fixture encoding is UTF-8 canonical JSON with ASCII object keys in ordinal order, no whitespace, exact integer decimal notation, JSON booleans/null, arrays in semantic order, and scalar-Unicode strings without normalization. Escape quote/backslash and controls per JSON; use short escapes for backspace/tab/newline/formfeed/carriage return, lower-case `\u00xx` for other controls, and literal UTF-8 for other scalars. Reject duplicate keys, non-finite numbers, floats/exponents, out-of-range integers and isolated surrogate code points. Numeric input `-0` normalizes to integer zero; there is no separate semantic negative zero. This is a fixture profile, NOT an unqualified claim of RFC 8785 support or a ban on non-ASCII player prose.

## RNG

Use the proposed `xoshiro128ss-1.1` transition: four explicit unsigned 32-bit words, not all zero. Arithmetic in the RNG transition alone wraps modulo 2^32. The output is `rotl32(s1*5, 7)*9`; then apply the published xoshiro128** 1.1 state transition. Snapshot the algorithm ID and all four words. R1 starts from explicit words; no host-specific seed expansion is allowed. Initial save seeding belongs to the host, which supplies and persists the explicit state. This PRNG is for gameplay, not keys, tokens, signatures or other security randomness.

For a uniform integer in `[0,bound)`, require `1 <= bound <= 2^32`; draw raw uint32 values until `raw < 2^32 - (2^32 mod bound)`, then return `raw mod bound`. Rejected draws advance the proposed RNG. A deterministic draw budget (fixture default 1024) bounds work; budget exhaustion aborts the decision and discards all proposed draws. A 50% check uses `uniform(100) < 50`.

A valid failed check commits the new RNG with the failed-attempt receipt. A duplicate delivery does not draw again. Gameplay rejection and definitive rollback do not advance RNG. Uncertain COMMIT must reconcile before another draw.

## Known answers and provenance

`numeric-vectors.json` contains manually retained output and next-state vectors for explicit `[1,2,3,4]`, plus signed division and range edges. These values were cross-checked against a standalone C rendition of the upstream transition, not generated from the Python candidate during CI. This is a cross-language numeric check, not independent review or full host conformance.

Primary algorithm source: [Blackman/Vigna xoshiro128** 1.1](https://prng.di.unimi.it/xoshiro128starstar.c), retrieved 2026-09-22. The upstream code is dedicated to the public domain; preserve attribution when adapting it. Its current extra jump APIs are not part of this proposed profile.

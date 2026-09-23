# Probe: Elixir rules on the phone through Popcorn — 2026-09-23

Feasibility probe for an Elixir-only backend, where one Elixir rules kernel
would also run on the phone. It is not R1 evidence and selects nothing.

Workflow `.github/workflows/probe-elixir-wasm.yml`, run 35907356254 attempt 1,
source `cdd26cfbfd4b99ee77b803249ab5a563248ba4c6`. Raw outputs are in `results/`.

## Hermes cannot run Popcorn

Hermes built from tag `hermes-v250829098.0.17`, the `hermes-compiler` version
in the retained SDK 57 lock, reports:

| Global | Present |
|---|---|
| WebAssembly | no |
| SharedArrayBuffer | no |
| Atomics | no |
| Worker | no |

Instantiating a minimal WebAssembly module fails with a ReferenceError. The
`static_h` branch head on 2026-09-18 also has no WebAssembly implementation.
Popcorn 0.4 needs WebAssembly and a Worker, so on the phone it could only run in
a hidden WebView, with a message bridge to React Native.

## Popcorn in headless Chromium works

Popcorn 0.4.0-next.0, OTP 29.0.5, Elixir 1.20.4, GitHub runner with 4 cores.
The rule is a Tiny-sized integer decision with a deterministic RNG, mirrored in
JavaScript.

| Measure | 1x CPU | 4x throttle |
|---|---|---|
| Elixir vs JS mismatches, 1,000 steps | 0 | 0 |
| Boot | 632 ms | 675 ms |
| Page to Elixir round trip p50 | 0.29 ms | 0.90 ms |
| Round trip p99 | 0.41 ms | 2.21 ms |
| Rule inside the Erlang VM, per decision | 1.47 µs | 1.63 µs |
| Same rule in plain JS, per decision | 0.065 µs | 0.42 µs |

The throttle does not appear to reach the Worker, so treat the 4x kernel figure
as unthrottled. Bundle: 10.7 MB uncompressed, 6.4 MB gzip, of which `beam.wasm`
is 2.4 MB.

## Not measured, each potentially disqualifying

- The React Native to WebView bridge hop on a real iPhone 11 and Android phone.
- Whether a React Native WKWebView can be cross-origin isolated, which
  SharedArrayBuffer and so Popcorn 0.4 require.
- Memory on a 4 GB phone, and App Store review of BEAM bytecode interpreted in a
  WebView under ADR-035.
- Popcorn 0.4 is a prerelease; its maintainers call Popcorn unsuitable for
  production.

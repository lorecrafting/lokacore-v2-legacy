# Fable recheck of the PR #14 corrections — 2026-09-23

Scope: correction diff `b0eb3d6..28a3672` only. Reviewer: a fresh Fable 5.1
agent on Claude Code, nominated by the owner, not an attributable approval.

**Verdict: merge-ready.** `cee26e5` deletes only the four temporary transport paths.

| Finding | Status | Evidence |
|---|---|---|
| F1 supplied device semantics at A1 | Fixed | Same per-field rules at both stages in both checkers; reverting fails 23 Python and 1 ExUnit test |
| F2 major-only runtime versions | Fixed | Full SemVer for Node/TS/Elixir, 2–4 part OTP; reverting fails 66 Python and 1 ExUnit test |
| F3 unsupported `--stage` exit | Fixed | Both CLIs exit 1 with the same message; 20/20 probes agree |
| F4 single lock path vs bundle | Fixed as documented obligation | Docs state the checker does not verify bundle members |

New findings:

- **N1 (low).** The non-A1 tool pattern used Python `\d`, which accepts Unicode
  digits that Elixir rejects. Fixed on `prep/v3-hosted-a1` with a test that
  fails without the fix.
- **N2 (info).** ExUnit folds the F1/F2 cases into one test, so a regression
  reports only its first bad case. Left as is.

Observed at `28a3672` on macOS arm64 with Elixir 1.20.4 / OTP 28.4: Python 112
tests OK, `mix test` 25 passed with 3 excluded, `mix test --include comparison`
28 passed, all 20 negative readiness probes exit 1 with the expected message.

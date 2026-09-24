# Failed Pixel 3a attempt 1 (2026-09-24T15:52Z), kept on purpose

**APK:** Actions run 36022268988 at `3525fdc`, sha256 `7e248aab…acadf`.
**Result: failed before the first fault case. No fault records were produced.**
The differential finished; its output was not pulled because the run was stopped.

The app stopped at `LOKA_A2_CASE 1/19` with
`Call to function 'NativeDatabase.execSync' has been rejected. → Caused by: java.lang.NullPointerException`
(`pixel-3a-logcat.txt`). It stayed on that error screen. The capture script then
waited with no bound until the coordinator killed it (`pixel-3a-run.partial.txt`).

**Cause (host bug, not an injected fault).** `App.tsx` opened `host.db` twice:
once at module scope for the SQLite probe, and once in `runAll`. On Android,
expo-sqlite 57.0.3's `NativeDatabase` constructor gives a second open of the same
path the same cached native object and increments its refCount
(`SQLiteModule.kt`, `findCachedDatabase … addRef()`). But
`NativeDatabase.sharedObjectDidRelease()` calls `ref.close()` →
`mHybridData.resetNative()` whenever one JS handle is garbage-collected, and it
ignores the refCount. After Hermes collected the unused probe handle, the next
`execSync` on the other handle hit a null native pointer. The iPhone 11 run did
not show this failure.

**Fix** (`r1-spike/mobile/App.tsx`): open each database once per process and
keep the handle. No version, template or kernel change. The capture scripts now
also bound every wait: at most 120 s per launch. The run stops as a failure on
`LOKA_A2_ERROR` or when the process is alive but has made no progress.

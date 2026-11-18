# Phase 17 — Self-review #1

Every finding is applied (with a test proven to fail without the fix) or
marked invalid.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| S1 | Medium | Practice with a kept checkpoint but the camera since revoked showed the game; "Scan QR" then let `mobile_scanner` raise the OS camera prompt itself, with no reason shown. | **Applied.** Practice reads camera access (on open and resume) and routes through setup until it is `ready`; the setup's prompt comes first. Test: `a kept checkpoint without the camera asks first`. |
| S2 | Medium | The pool sheet waited on `qrHuntReadyProvider.future`, which Riverpod 3 pauses when nothing listens — the sheet never opened from the chooser. | **Applied** (found by its test). The sheet reads the checkpoint and camera access directly. |
| S3 | Low | A camera grant changed in device Settings never refreshed readiness. | **Applied.** The provider re-reads on app resume (a binding observer — `AppLifecycleListener` drops a paused → resumed jump, measured). Test. |
| S4 | Low | At 375 × 667 the card reached 38 pt higher than Catch the Capy (the clock guard's cap): the instruction and the wrong-code line wrapped. | **Applied.** Shorter strings in all ten locales, field 136 → 118 pt; the small-phone guard passes. |
| S5 | Low | "Every playable game is screen-reader solvable" cannot hold for a camera game. | **Applied as a stated exception:** the catalogue test now asserts solvable ⇔ not a camera game; a QR-only pool already triggers the visual-only warning, and the escape is always there. |
| S6 | Low | `mobile_scanner` itself asks the OS for permission when its widget starts. | **Invalid as a defect** after S1: the widget is built only after "Scan QR", which a ring offers only once access is `ready`, and practice only once ready. |

## Mutation checks

13 of 13 guards fail without their code: no camera before a tap, camera off on
pause, `_canRing` readiness, camera failure is a struggle, digest never the
code, wrong-code dedupe, win closes the camera, readiness needs the camera,
resume refresh, no sheet when ready, setup camera off on pause, scanner
failure reported once, practice asks before the plugin can (S1). Two were
first on trust: the H4 mutation did not leak the code (fixed the mutation), and
"reported once" was never rebuilt (fixed the test).

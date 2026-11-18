# Phase 17 — Full-project review

The whole app, read for what QR Treasure Hunt changed outside its own files.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| P1 | Medium | Riverpod 3 pauses an unlistened provider: any `read(x.future)` outside a widget that watches it waits forever. QR readiness is kept live only by `RingingHost` (always mounted at the app root, `app.dart:49`). | **Applied/recorded.** The pool sheet no longer depends on it (S2); the readiness tests listen; memory note added for later phases. |
| P2 | Medium | `StepAccess` became `DeviceAccess` + `DevicePermission`; every Phase 16 caller and test was renamed, the prompt takes its copy (`DeviceAccessCopy.steps/camera`). | **Applied.** Step Quest tests unchanged in substance and green; no `StepAccess` left in `lib/` or `test/`. |
| P3 | Low | `GameBlockedReason` removed with the last blocked game; `GameAvailability.blocked` and its sheet copy stay for a future game, tested with a synthetic entry. | **Applied.** |
| P4 | Low | `mobile_scanner` bundles ML Kit for every ABI (`libbarhopper_v3.so`: 4.9 MB arm64, 5.9 MB x86_64, 3.2 MB armv7, + 0.9 MB models). A Play App Bundle ships one ABI; a universal APK ships all. | **Recorded** for the owner and Phase 19 (`OPEN_QUESTIONS.md`). |
| P5 | Low | The ring's held slot is a new state on `RingingScreen`; it must not animate (ringing chrome rule) and must keep the escape. | **Applied** — a plain sized box; the host test asserts the escape is visible. |

Checked, no finding: no `Phase N` in `lib/` doc comments (0); comment baseline
113 (+0); RTL; every game fits 320 pt and the 424 pt budget; both clock guards
include QR; `NSCameraUsageDescription` in all ten languages; the Android APK
lists `CAMERA` from the plugin's manifest.

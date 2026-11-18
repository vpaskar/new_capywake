# Phase 16 — Self-review #1

Reviewed after the first green validation (2,293 tests). Every finding is
applied (with a test proven to fail without the fix) or marked invalid.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| S1 | Medium | A screen-reader user tapping "Take a step" heard nothing for steps 1–4: the count pill sat inside the field's `ExcludeSemantics`, and only the five-step milestone pips spoke. | **Applied.** The meadow and Capy are excluded; the count is a live region. Test: `each step is spoken`. |
| S2 | Medium | The iOS Motion & Fitness prompt is the first app-authored string an OS dialog shows, and the app declared no localizations, so all ten locales would see it in English. | **Applied.** `CFBundleLocalizations` (10) in `Info.plist`, `<code>.lproj/InfoPlist.strings` for each, registered in the Xcode project. Test reads all three. |
| S3 | Low | `_readAccess` guarded re-entry with a bool; a sensor swapped while its access was being read was never read. | **Applied.** After the await, a swapped sensor is read again. Test with a slow fake. |
| S4 | Low | Swapping the step sensor left the tally on `sensor` with no stream, so accelerometer steps were held back until demotion. | **Applied.** A swap starts a fresh tally and resumes the accelerometer. Test. |
| S5 | Low | Android below 10 has no runtime permission. | **Invalid** — read from `permission_handler_android` 13.0.1: `determinePermissionStatus` returns `GRANTED` when no names apply (pre-Q), so `access()` is `ready` with no prompt. |
| S6 | Low | iOS can lag before its first pedometer update; 16 unseen accelerometer steps could demote a working pedometer. | **Invalid as a defect** — demotion keeps every step and still counts (from motion); a lagging sensor is never trusted over a counting one. Logged as an owner question with the constant. |

## Mutation checks (each guard removed, its test must fail)

13 of 13 failed as required: sensor-swap race, swap reset, live region, H1
(never listen unless ready), M5 (never prompt on a ring), H2 (stream error
demotes), M1 (accelerometer released on first delivery), resume re-reads,
demotion at 16 not 15, rhythm gate, jolt rejection, sheet only on → off,
`restricted` → unavailable.

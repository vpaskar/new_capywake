# Phase 15 — Full-project review

Scope: the whole app as it stands after Phase 15, not just the phase's files.
1 High (carried, already owned), 3 Medium, 1 Low; all applied or recorded as
the owner's, none invalid.

## FP-M1 — Result lines moved Snooze at 2× text in four older games

Found from Phase 15's own fix (SR2-L2), but the defect was cross-app: Capy
Rocket, Rhythm Rescue, Morning Sort and Find the Impostor reserved two body
lines for results that wrap to three or four at 2× text. **Applied:** all four
pass their results to `GameOutcomeLine(reserveFor:)`. Their existing tests
(card height, clock guards at 1×) still pass; the 2× case is covered by the
widget test.

## FP-M2 — The plugin fence was a convention, not a check

`package:alarm` is fenced by review; `package:health` by
`sleep_boundary_test`. `sensors_plus` had neither. **Applied:** a test fails
if any file but `lib/data/motion/platform_motion_sensor.dart` imports it, and
`CLAUDE.md`'s architecture section says so.

## FP-M3 — No game had been checked on a 320 pt phone

iOS 15 is the deployment target, and the 1st-gen iPhone SE (320 pt) runs it.
**Applied:** a registry test builds every registered game at 320 × 568 in the
ringing slot. All eight fit (Tilt Maze's arrows needed SR2-L5).

## FP-H1 (carried, owner) — Settings' motion-check switch still governs nothing

`memory/capywake-owed-across-phases.md` already records it. Phase 15 makes it
cheaper — the accelerometer is now wired, faked in tests, and the post-dismiss
`MotionCheckService` is ported and tested — but building the check is a new
alarm-flow feature, not this phase's. Not deferred by this review: it stays on
the owed list and in `docs/sessions/next.md`, now with "the sensor exists".

## FP-L1 — Home's game rail: Shake DJ lost its "Soon" badge

Expected (it is playable). `tool/compare.dart home 01_HOME` after the capture:
worst delta 2.7 pt, game rail tiles −1.4 / labels +1.1 — the same five blocks
"absent" as before (tool blind spots, `memory/capywake-compare-tool-blind-spots.md`).
No Tier A change. Recorded in `docs/visual/home/README.md`.

## Checked and found sound

- Nothing else enumerates the catalogue in a way the flip could break: the
  alarm form's summary and the chooser iterate `GameCatalogue`; mappers store
  ids; Stats does not list games.
- No `Phase N` in `lib/` doc comments (`grep` returns 0).
- The new `NSMotionUsageDescription` is the only `Info.plist` change; the
  plugin adds no Android permission (`AndroidManifest.xml` is empty) and its
  privacy manifest declares no collected data.
- Comment budget: baseline unchanged at 113; every new file meets the budget.

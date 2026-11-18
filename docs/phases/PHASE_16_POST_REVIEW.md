# Phase 16 — Post-review: Capy Step Quest

**Done 2026-11-18.** Unblocked by the owner this session: *"the most accurate
one … work for as much phones as possible, maybe multiple depending on phone."*

## What shipped

- **Three counters, best first.** The phone's step sensor (Android
  `TYPE_STEP_DETECTOR`, else `TYPE_STEP_COUNTER`, unbatched; iOS `CMPedometer`
  counted from the moment the game listens) → CapyWake's own accelerometer step
  detector (`StepDetector`: four steps in rhythm before any count, a jolt over
  10 m/s² is a shake) → the "Take a step" button, always on screen.
  `StepTally` merges them: the sensor wins once ready; until it delivers, a
  failure or 16 unseen accelerometer steps demote it for good, keeping the steps.
- **Our own platform channel** (`capywake/steps`), not the `pedometer` package,
  which throws Android's per-step events away and counts iOS from reboot. No
  new dependency; `permission_handler` asks Android's `ACTIVITY_RECOGNITION`.
- **Just-in-time access, never on a ring.** A card in practice, a sheet when
  Step Quest is switched on in a wake pool (after the switch is saved). A ring
  uses what is already allowed — a test proves no request and no listen.
- **The iOS purpose string in all ten languages** (`InfoPlist.strings`,
  `CFBundleLocalizations`) — the Motion & Fitness prompt is the first OS dialog
  showing the app's own text.
- **Android builds for the first time** (desugaring).

## Reviews

Pre-review 4H/7M/7L (L2 invalid). Self-review #1: 6 (4 applied, 2 invalid).
Self-review #2 (unanchored subagent): 6 applied — the Medium was a second
`receiveBroadcastStream` silently killing a ringing game's step sensor.
Full-project: 6 (4 applied, 2 invalid). **18 guards mutation-checked**, all
fail without their code.

## Evidence

- `docs/visual/ringing_step_quest/`, `win_step_quest/`, `home/` — captured on
  the iPhone 14 Pro simulator via `tool/capture.sh`, verified 1179×2556.
- `integration_test/step_channel_test.dart` on the same simulator: the Swift
  channel is registered and answers `unavailable` (no pedometer in a simulator).
- `flutter build apk --debug` succeeds (Kotlin compiles). **Never run.**

## Tier A / Tier B

Tier A binds nothing (the poster is a storyboard). Tier B: **G41** — no walk
cycle for the backpack Capy; `collection_02` stands in, reported in session.

## Not verified

No phone was walked with: the step sensor, the pedometer and the
accelerometer thresholds are untested on hardware. Android never ran.

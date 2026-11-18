# Current phase

**Phase 16 — Capy Step Quest: done, 2026-11-18 (owner unblocked it this
session). `Current phase: 17` — QR Treasure Hunt, which is BLOCKED on an owner
decision (a camera dependency + camera permission). Do not start it without the
owner's answer; Phase 18 needs the owner to re-point the tracker.**

**2,302 tests**, analyze clean including infos, lib 98.64% / `lib/core` 99.73%
/ `lib/core/games`, `lib/core/motion`, `lib/features/games`, `lib/data/motion`
**100%** / `lib/data` 90.16%, **568 ARB keys × 10 locales**. Comment baseline
113 (+0). Motion check (owner) built and committed after Phase 15 (`005bf3f`),
with the fix for alarms going silent 35 ms in.

Nine games are playable; only QR Treasure Hunt is `blocked`.

## What Phase 16 adds to the recipe

- **Step counting:** `GameLaunch.steps` (a `StepSensor`), hosts read
  `stepSensorProvider` (an unavailable `FakeStepSensor` by default,
  `platformStepOverride()` in production). Listen to `steps` **only after
  `access()` is `ready`**; `StepTally` picks sensor → accelerometer; the button
  always works. Re-read access on resume, on `accessChanges`, or a new sensor —
  never on every rebuild.
- **Never ask for a permission on a ring.** `StepAccessPrompt` lives in
  practice and the pool sheet only.
- **A platform event channel has one handler:** cache the stream
  (`late final`), never `receiveBroadcastStream()` per read — a second listener
  silently kills the first. Fakes cannot show this.
- **The iOS app now declares ten localizations**; any new Info.plist purpose
  string needs all ten `InfoPlist.strings`.


## What Phase 15 adds to the recipe

- **Motion input:** `GameLaunch.motion` (a `MotionSensor`); hosts read
  `motionSensorProvider` (a silent `FakeMotionSensor` by default,
  `platformMotionOverride()` in production). Subscribe once, cancel on win and
  dispose, resubscribe in `didUpdateWidget` when the sensor changes, ignore
  stream errors.
- **The fallback is always live**, never gated behind a mode or a timer.
- **`ShakeDetector`** (8 m/s² from gravity, re-arm under 4) and **`TiltReader`**
  (angles from the first grip, full-turn pitch, 18° engage / 9° release,
  `suppressUntilLevel()` after a press or escape). Never re-baseline on a
  tilted grip — letting go reads as the reverse.
- **`GameOutcomeLine(reserveFor:)`**: pass every result the game can show.
- **A game control is never a `CapyButton`** — Snooze is one, right below.
- **Mutation-check every guard**, and pump timers one beat at a time: a long
  `pump` coalesces several timers into one frame.

## Carried from Phases 12–13 (unchanged)

Games live inside `DismissMethod.puzzle`; a new game = flip its catalogue entry
**and** add one `GameRegistry.builders` line (pinned equal). Motion stops under
`disableAnimations` **or** `accessibleNavigation`, re-read every build. Results
in `GameOutcomeLine`; card ≤ 424 pt (clock guard). Size art from the decoded
file. Mount new games in the real `RingingScreen` in host tests.

## What Phase 14 adds to the recipe

- **`DriftingGrid`** for a grid that moves: `swap` or `carousel`. Choose the
  motion that does not reveal the answer. No beat while a finger is on the
  grid; a tap mid-slide goes to the card aimed at; still snaps home.
- **`GameOutcomeLine(serial:)`**: pass a count of answers so a repeated result
  is announced again.
- **Tests that read state after a timer must pump rest + slide per beat**, and
  prove they fail without the guard (Phase 14 found two that did not).
- **Authored banks** (these two games only): enum + one ARB key per entry in
  all ten locales; pose labels are the screen-reader answer key.

## Owner questions open (`docs/sessions/OPEN_QUESTIONS.md`)

Blue/orange win-pose caps; Capy Rocket cue vs any-swipe; Rhythm Rescue timing;
short-phone clock overlap; Morning Sort bank (pizza); Find the Impostor
adaptation; word-only item cards.

## Owed by nobody (carried)

Sleep boundary / `package:health` (unbuilt 07–15). (Settings' motion-check
switch: built 2026-11-18, see the motion-check follow-up.); `CapyNavBar` 98.7 vs 79.9;
Alarms 3 / Add-Edit 9 Tier A failures; `ringNow` uncalled; art G35–G38. Android
untested, no emulator.

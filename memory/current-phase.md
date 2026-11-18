# Current phase

**Phase 15 — Motion games: done, 2026-11-18 (unattended). `Current phase: 16`
— Capy Step Quest, which is BLOCKED on an owner decision (a step-count
permission: ACTIVITY_RECOGNITION on Android 10+, Motion & Fitness on iOS).
Phase 17 (QR Treasure Hunt, camera) is blocked the same way. Do not start
either without the owner's answer.**

**Motion check built after Phase 15 (owner); a core ring defect fixed with it
— every real alarm went silent 35 ms in.** **2,133 tests** (before the
follow-up), analyze clean including infos, lib 98.55% / `lib/core` 99.72% /
`lib/core/games` **100%** / `lib/features/games` **100%** / `lib/core/motion`
**100%** / `lib/data` 89.31% / `lib/features/ringing` 98.71%, **557 ARB keys ×
10 locales**. Comment baseline 113 (+0).

Eight games are playable: Catch the Capy, Memory Hideout, Rhythm Rescue, Capy
Rocket, Morning Sort, Find the Impostor, **Shake DJ, Tilt Maze**. Only Step
Quest and QR Treasure Hunt remain, both `blocked`; no catalogue entry is
`comingSoon` any more (the sheet is tested with a synthetic entry).

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

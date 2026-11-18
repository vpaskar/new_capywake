# Current phase

**Phase 13 — Touch games II: done, 2026-11-18 (unattended). `Current phase: 14`.**

**1,888 tests**, analyze clean including infos, lib 98.34% / `lib/core` 99.69% /
`lib/core/games` **100%** / `lib/features/games` **100%** / `lib/data` 89.17% /
`lib/features/ringing` 98.71%, **498 ARB keys × 10 locales**. Comment baseline
113 (+0).

Four games are playable: Catch the Capy, Memory Hideout, Rhythm Rescue, Capy
Rocket — on a ringing alarm (wake pool) and in practice (chooser "Try it"; Home
tiles only for the mockup's four).

## Carried from Phase 12 (unchanged)

Games live inside `DismissMethod.puzzle`; a new game = flip its catalogue entry
**and** add one `GameRegistry.builders` line (pinned equal). Games are dynamic;
motion stops under `disableAnimations` **or** `accessibleNavigation`. Never draw
art in code. Mount new games in the real `RingingScreen` in tests.

## What Phase 13 adds to the recipe

- **Re-read still mode every build** (`didChangeDependencies`), not once: a
  screen reader turned on mid-game must stop motion and reveal what was hidden.
- **`GameOutcomeLine`** for a game's result: a live region that reserves two
  *measured* lines, so a result appearing never moves Snooze. A changing
  status or cue must not change height either — `IndexedStack` the variants,
  or put the cue on a fixed-height field.
- **`GameHeader` progress is a live region**: a repeated identical outcome is
  not re-announced, progress is.
- **The clock guard** (`ringing_host_game_test`): at 393×852 with a 47 pt inset
  every game card clears the clock; at 375×667 none may reach higher than Catch
  the Capy (424 pt card). A new game's card must stay ≤ 424 pt.
- **Size art from the decoded file**, never a constant read off a sheet: the
  win poses are 205–246 px, so a pose is sharp only up to ~72 pt.
- `pumpAndSettle` returns between `Timer` beats; drive playback with explicit
  `pump(beat)`. Live-binding captures wait in real time — watch the game the
  way a user would (`_watchRhythm` in `capture_test.dart`).

## Owner questions open (`docs/sessions/OPEN_QUESTIONS.md`)

Blue/orange win-pose caps; Capy Rocket cue vs any-swipe; Rhythm Rescue timing
not judged; short-phone clock overlap (keep / shrink fields / smaller clock).

## Owed by nobody (carried)

Sleep boundary / `package:health` (unbuilt 07–13); `CapyNavBar` 98.7 vs 79.9;
Alarms 3 / Add-Edit 9 Tier A failures; `ringNow` uncalled. Android untested, no
emulator.

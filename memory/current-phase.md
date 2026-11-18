# Current phase

**Phase 14 — Authored games: done, 2026-11-18 (unattended). `Current phase: 15`
— Motion games (Shake DJ, Tilt Maze).**

**1,987 tests**, analyze clean including infos, lib 98.46% / `lib/core` 99.70% /
`lib/core/games` **100%** / `lib/features/games` **100%** / `lib/data` 89.17% /
`lib/features/ringing` 98.71%, **544 ARB keys × 10 locales**. Comment baseline
113 (+0).

Six games are playable: Catch the Capy, Memory Hideout, Rhythm Rescue, Capy
Rocket, Morning Sort, Find the Impostor — on a ringing alarm (wake pool) and in
practice (chooser "Try it"; Home tiles only for the mockup's four).

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

Sleep boundary / `package:health` (unbuilt 07–14); `CapyNavBar` 98.7 vs 79.9;
Alarms 3 / Add-Edit 9 Tier A failures; `ringNow` uncalled; art G35–G38. Android
untested, no emulator.

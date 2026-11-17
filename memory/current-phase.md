# Current phase

**Phase 12 — Touch games I: done, 2026-11-17. `Current phase: 13`.**

**1,767 tests**, analyze clean including infos, lib 98.20% / `lib/core` 99.67% /
`lib/core/games` **100%** / `lib/features/games` **100%** / `lib/data` 89.17% /
`lib/features/ringing` 98.62%, **466 ARB keys × 10 locales**. Comment baseline 113
(+0).

## The owner decisions this phase carries forward

1. **Selection model.** Games live inside `DismissMethod.puzzle`. The pool is
   "puzzles" + enabled games (`PuzzleSettings.enabledGames`/`includePuzzles`, also
   on `AlarmPuzzleOverride`, all in the existing JSON — no schema bump).
   `WakeChallengeSelector` picks one per ring, seeded, uniform, falling back to
   puzzles. A new game = flip its catalogue entry **and** add one line to
   `GameRegistry.builders`; a test pins the two equal.
2. **Games are dynamic.** Catch the Capy runs non-stop (speed by difficulty),
   faces its direction, bolts from missed taps; Memory Hideout shuffles. Motion
   stops under `disableAnimations` **or** `accessibleNavigation`, and each game
   stays finishable there. `CLAUDE.md` now limits "no animation" to the ringing
   **chrome**. **Phases 13–17 design motion in from the start.**
3. **Never draw art in code.** G32 asked for frames; the owner supplied them the
   same day (`reference/02_ASSETS/game_art/`). Sprite sheets go through
   `_FrameSheet` in `tool/import_art.dart`: grid cut, one canvas, right+bottom
   aligned. Expect supplied art to need validation — this batch had a framed
   tile and a flat-based bush.

## Findings that matter later

- **A green view test is not a rendered surface.** SR1 H1: both games would have
  drawn dark text straight onto the scrimmed ringing hero; every view test passed
  in a cream `Scaffold`. Mount new games in the real `RingingScreen`.
- **A widget's layout box is not its paint.** Settings' title overflowed *paint*
  over its value for five phases; a rect-overlap test cannot see that — measure
  glyph boxes (`getBoxesForSelection`).
- **Vocabulary collides when a product grows.** es/fr/it/ar called puzzles
  "games" — harmless until games existed. `test/l10n/puzzle_game_vocabulary_test.dart`
  guards it; a new games phase must keep puzzle and game words apart.
- **Continuous animation and `pumpAndSettle`.** The running capybara keeps a
  150 ms footfall so `pumpAndSettle` can settle; drive single runs with explicit
  `pump(duration)` — and remember a tap's animation starts on the *next* frame.
- **Practice waits for settings**, or it plays the wrong difficulty.

## Owed by nobody (carried)

Sleep boundary / `package:health` (unbuilt 07–12); `CapyNavBar` 98.7 vs 79.9;
G18/G19; Alarms 3 / Add-Edit 8 Tier A failures; `ringNow` uncalled. Android
untested, no emulator.

# Phase 20 — Pre-review (adversarial, before code)

Against `PHASE_20_PLAN.md` as first written. Every finding is applied or
marked invalid; the plan was revised afterwards.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| H1 | High | The pool floor ("never empty") now spans two screens: the last game's switch on Games and the Puzzles switch on Puzzle types can each be locked by the other screen's state. A disabled switch with no reason reads as broken to someone half-asleep. | Applied: a locked switch shows the reason under it (`challengePoolFloorReason`, new) and announces it as its semantics hint. Tests lock each side from the other. |
| H2 | High | `PuzzleChooserScreen` is referenced by `text_contrast_test.dart`, `capture_test.dart`, `tool/capture.sh` (`DARK_ONLY`), `docs/visual/dark_mode.md` and two feature tests. Deleting it silently drops the dark-mode legibility check for the puzzle surface. | Applied: the contrast route list gains the four new routes; capture targets renamed; tests migrated assertion by assertion, not deleted. |
| H3 | High | `test/l10n/puzzle_game_vocabulary_test.dart` forbids "game" in any `puzzle*` / `settingsPuzzle*` key. The plan's `settingsPuzzleEntrySummary` ("Games, puzzle types, difficulty") and `puzzleGamesTitle` would fail it in ten locales. | Applied: keys that name games use the `challenge` prefix (`challengeEntrySummary`, `challengeGamesTitle`, `challengeGamesHelp`, `challengeSelectedCount`). |
| M1 | Med | "N of 10 selected" for Puzzle types is a lie while `includePuzzles` is false — the types are configured but never drawn. | Applied: the card reads "Off" then; the count returns when puzzles are back in the pool. Test pins both. |
| M2 | Med | `{selected} of {total} selected` is not plural-safe (Russian, Arabic agree the participle with the number). | Applied: ICU plural on `selected` in every locale. |
| M3 | Med | Dropping the notification manage hint ("you can turn these off in your phone's settings") removes Phase 07's honesty note that replaced the mockup's switch. | Applied: when granted, the row keeps a chevron (as `01` draws it) that opens the OS settings, and the hint becomes its semantics hint. |
| M4 | Med | Motion check is a switch with no destination; without its description "Motion check after dismiss" is unexplained. | Applied: it keeps its one-line description (named Tier A deviation); the two chevron rows drop theirs — their screens explain themselves. |
| M5 | Med | Side-by-side Games / Puzzle types cards cannot hold German labels or 2× text at 393 pt. | Applied: the pair stacks when either label would wrap past two lines (LayoutBuilder on available width and the text scaler). Tested at 2× in all ten locales. |
| M6 | Med | `01` rows pitch at ~35 pt — under the 44 pt tap floor `CLAUDE.md` requires. | Applied: rows stay ≥ 44 pt; Settings scrolls instead of fitting one viewport. Recorded as the main Tier A deviation. |
| M7 | Med | Settings' Tier A blocks were measured against `04_SETTINGS.png`. Comparing the new screen to the old blocks would report the redesign as regression. | Applied: `01_SETTINGS_REFINED.png` replaces it as Settings' reference; blocks re-measured with the method named per row (`CLAUDE.md`, "say which method produced the number"). |
| M8 | Med | Green selected segments with white text: `success`/`grass` already fail AA as UI components in light mode (memory). | Applied: selected fill uses the deepest green token that passes 4.5:1 for its label in both themes; the contrast test covers the Advanced route. |
| M9 | Med | Enabling a game must still run `offerGameSetup` (QR checkpoint, step access) — easy to lose when moving the list. | Applied: Games keeps the call; a test enables QR Treasure Hunt and expects the offer. |
| M10 | Med | Long localized game names next to "Try it" and a switch. | Applied: name wraps to two lines; "Try it" stays a text button ≥ 44 pt. |
| L1 | Low | Header glyphs (gamepad, grid, mascot) are decorative. | Applied: `ExcludeSemantics`; the title is the header node. |
| L2 | Low | Route constants. | Applied: `Routes.settingsPuzzleGames/Types/Advanced`. |
| L3 | Low | Comment budget for new files. | Applied: new files meet 2 lines / 300 chars; no baseline entries. |
| L4 | Low | `docs/visual/puzzle_chooser/` would go stale. | Applied: replaced by `puzzle_overview/`, `puzzle_games/`, `puzzle_types/`, `puzzle_advanced/`; `dark_mode.md` updated. |
| L5 | Low | The overview's tolerance value must read `tolerated + 1`, same as the stepper. | Applied: both call `puzzleSettingsToleranceValue(tolerated + 1)`; one test asserts the two match. |
| X1 | — | "Add the Save changes button so the user knows it saved." | **Invalid:** settings autosave today; a Save button would introduce a second persistence model the spec forbids. |
| X2 | — | "Build the master Wake challenges switch from `02`." | **Invalid:** no domain field backs it; whether an alarm uses a challenge is per-alarm `dismissMethod`. Inventing a global off would change alarm behaviour. |

# Phase 20 — Settings and Wake puzzle redesign

Owner request, 2026-11-18: implement the five-screen package
`~/Downloads/CapyWake_Settings_WakePuzzle_Redesign/` (`CLAUDE_CODE_PROMPT.md`,
`docs/IMPLEMENTATION_SPEC.md`). Information architecture, not new features:
every existing setting stays, persistence semantics do not change.

Owner decisions (asked, 2026-11-18):

- **Overview rows → Advanced.** The Wake puzzle overview shows four compact
  value rows; tapping one opens the Advanced page (`05`). `02`'s inline
  segmented controls are not built — they do not survive German or large text
  at 393 pt.
- **Code after the "Home stats removal" session commits.** It is editing
  Settings in this checkout; this plan and its pre-review are written first.

## 1. References and what binds

| # | File | Size | Binding |
|---|---|---|---|
| 01 | `01_SETTINGS_REFINED.png` | 852×1846 = 393×852 pt | **Tier A** |
| 02 | `02_WAKE_PUZZLE_REFINED.png` | 1024×1536, not a phone aspect | structural only |
| 03 | `03_GAMES_SELECTION.png` | 502×1024 crop | structural only |
| 04 | `04_PUZZLE_TYPES_SELECTION.png` | 301×633 crop | structural only |
| 05 | `05_WAKE_PUZZLE_ADVANCED.png` | 305×633 crop | structural only |

Only `01` is a native 393×852 frame, so only `01` is held to ±4 pt. The other
four are compared for order, grouping, control shapes and states; their
deltas are named, not measured against a tolerance they cannot carry.
References are copied into `reference/01_REFERENCES/screens/settings_redesign/`.

## 2. Route tree

```
/settings                         Settings overview          (01)
/settings/reliability             unchanged
/settings/walkthrough             unchanged
/settings/puzzle                  Wake puzzle overview       (02)
/settings/puzzle/games            Games selection            (03)  new
/settings/puzzle/types            Puzzle types selection     (04)  new
/settings/puzzle/advanced         Advanced wake controls     (05)  new
```

All on the root navigator, each popping to its parent. Every setting is at most
two pushes from Settings.

## 3. Where every setting lives

| Setting (persisted field) | Before | After |
|---|---|---|
| `defaultSoundId` | Settings › Alarms | unchanged |
| `defaultSnoozeMinutes` | Settings › Alarms | unchanged |
| `themeMode` | Settings › Appearance | unchanged |
| `timeFormat` | Settings › Appearance | unchanged |
| Notification permission | Settings › Notifications | unchanged; one line, badge only when not granted |
| Reliability checklist | Settings › Alarms that ring | unchanged (subtitle dropped) |
| Setup walkthrough | Settings › Alarms that ring | unchanged (subtitle dropped) |
| `motionConfirmationEnabled` | Settings › Alarms that ring | unchanged |
| About | Settings › About | unchanged |
| Developer (debug only, other session) | Settings bottom | unchanged |
| `includePuzzles` | Puzzle chooser pool list | **Puzzle types** — top switch "Puzzles" |
| `enabledGames` + Try it + setup offer | Puzzle chooser pool list | **Games** |
| `enabledTypes` + visual-only notice + floor note | Puzzle chooser | **Puzzle types** |
| `difficulty` | Puzzle chooser | **Advanced** |
| `taskCount` + "puzzles only" caption | Puzzle chooser | **Advanced** |
| `escapeStrictness` + explanation | Puzzle chooser | **Advanced** |
| `toleratedWrongAnswers` + explanation | Puzzle chooser | **Advanced** |
| Per-alarm override pool | Add/Edit › Dismiss | unchanged (`ChallengePoolPicker` kept) |

One source of truth: `puzzleSettingsStreamProvider` read by all four puzzle
screens, `PuzzleSettingsController` the only writer. Autosave, as today: no
Save or Done button.

## 4. Screens

### 01 Settings
- Groups as today, compacted: Alarms, Appearance, **Wake puzzle card**
  (standalone, no "Preferences" heading), Notifications, Alarms that ring,
  About. Rows keep ≥ 44 pt (the mockup's ~35 pt pitch is below the tap floor —
  named deviation).
- Wake puzzle card: puzzle glyph, title, one-line summary, up to three tiles of
  the **enabled** games in catalogue order (none shown if no game is enabled).
- Notifications: title + status line; "Allow" chip only when not granted;
  "Open settings" when permanently denied; when granted, a chevron opens the
  OS settings and the manage hint is its semantics hint (pre-review M3).
- Alarms that ring: the two chevron rows drop their subtitles; Motion check
  keeps its one-line description (M4).
- Settings' Tier A reference becomes `01_SETTINGS_REFINED.png`; blocks
  re-measured, method named per row (M7).

### 02 Wake puzzle overview
Short hero (`scene.settings`), description, then:
- Two navigation cards side by side, stacked when a label would pass two
  lines (M5): **Games**
  `N of M selected` (M = `GameCatalogue.playable.length`) and **Puzzle types**
  `N of 10 selected`, or "Off" when `includePuzzles` is false.
- "How it works" card with four value rows → Advanced: Difficulty, Puzzles to
  solve, Stopping without the puzzle, When Stop without solving stands out.
- `challengePoolHelp` under the cards: one challenge is drawn per alarm.
- Meadow footer.

### 03 Games
Compact header (gamepad glyph + title, no hero), helper line, one card listing
every playable game in catalogue order: 48 pt tile, name, switch, "Try it".
The last pool member's switch is disabled with the reason shown and announced
(H1). Enabling a game still runs `offerGameSetup` (M9); names wrap (M10).

### 04 Puzzle types
Compact header, helper, "Puzzles" switch, visual-only notice when it applies,
the existing grouped two-column grid restyled to `04` (orange border +
check when selected), floor note.

### 05 Advanced
Compact header (mascot + "Wake puzzle"), four labelled groups: Difficulty
(3 segments), Puzzles to solve (1–5) + caption, Stopping without the puzzle (2
segments) + explanation, tolerance stepper + explanation callout. Selected
segment green with white text.

## 5. Assets — reuse only, nothing imported

| Mockup element | Production asset | Match |
|---|---|---|
| Settings / Wake puzzle hero | `scene.settings` | 01 exact composition; 02's nightcap absent → Tier B |
| Header mascot | `mascot.sleeping` | match |
| Theme tiles | `theme.system/light/dark` | match |
| Game tiles | `tile.<game>` ×10 | match by catalogue |
| Puzzle icons | `icon.puzzle.*` ×10 | match |
| Meadow, cloud scallop | `decor/meadow_footer`, `cloud_edge` | match |
| Row glyphs, gamepad, grid | Material icons tinted with tokens | per spec |

The package's PNGs are not imported: every element already has a production
asset. Gap logged: 02's nightcap hero (same as G-Home nightcap).

## 6. l10n (10 locales)

New (H3: keys that say "game" carry the `challenge` prefix the vocabulary
gate allows): `challengeEntrySummary` ("Games, puzzle types, difficulty"),
`challengeGamesTitle` ("Games"), `challengeGamesHelp`,
`challengeSelectedCount` (ICU plural on `selected`, M2),
`challengePoolFloorReason`, `puzzleTypesHelp`, `puzzleOff` ("Off"),
`puzzleHowItWorks`, `puzzleAdvancedTitle`. Existing keys
reused for every control label and caption.

## 7. Code

- `lib/features/puzzle/`: `wake_puzzle_overview_screen.dart` (replaces
  `puzzle_chooser_screen.dart`), `games_selection_screen.dart`,
  `puzzle_types_screen.dart`, `wake_puzzle_advanced_screen.dart`, controls
  split out of `puzzle_settings_fields.dart` into `puzzle_controls.dart`.
- `lib/design/`: `CompactHeader` (SettingsHeader with an optional glyph and no
  hero), `CapySegmented` (green-selected segmented control, ≥ 44 pt).
- `lib/features/settings/`: `wake_puzzle_card.dart`, compacted rows.
- `lib/app/router.dart`: three child routes; `Routes.*` constants.
- `integration_test/capture_test.dart` + `tool/capture.sh`: screens
  `puzzle_overview`, `puzzle_games`, `puzzle_types`, `puzzle_advanced`
  (`puzzle_chooser` retired), dark captures for all five.

## 8. Tests and acceptance

- Each screen: renders every catalogue game / every type; counts match a seeded
  `PuzzleSettings`; toggles write through the controller; last-member switch
  disabled; reachable within two pushes (router test).
- Selection survives restart: write via screen, rebuild app on the same DB,
  read counts on the overview.
- Advanced: each control writes its field; tolerance shows `tolerated + 1`;
  there is no "off" for strictness.
- 10 locales × 2× text scale: no overflow on all five screens (golden-free
  layout test).
- Dark mode contrast gate passes for the four puzzle routes (H2, M8).
- Pool floor locked from each side, reason shown (H1); "Off" vs count (M1).
- Captures: 5 screens light + dark on the 14 Pro, side-by-sides,
  `docs/visual/<screen>/README.md` with deviations. Tier A deltas for 01 via
  `tool/compare.dart`.
- Full validation list from `CLAUDE.md`; coverage gates unchanged.

## 9. Exclusions

Master "Wake challenges" switch (no domain field — inventing one would change
alarm behaviour), Save changes / Done buttons (autosave), the games bottom-sheet
variant, any change to `lib/core/` or `lib/data/`.

## 10. Risks / rollback

Risk: the pool floor now spans two screens. Risk: removing the chooser breaks
deep links and the Home "See all". Rollback: revert the phase commit; no schema
or data change.

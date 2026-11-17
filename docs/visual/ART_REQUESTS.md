# CapyWake — open art requests

One list of everything the app still needs drawn, in priority order. Details,
measurements and history for each are in `asset_gaps.md` under the G-number.

**Rules for every file:** transparent PNG unless it says "scene" or "tile";
no text baked in (the app is in 10 languages); no frame, rounded border or black
corners; the capybara drawn in the same style as `game_art/` and the sticker
sheets; frames of one animation on one shared canvas with the feet on the same
line. Put files in `reference/02_ASSETS/` and run
`dart run tool/import_art.dart`.

**Character rule:** in the games, Capy wears the **orange nightcap** (white brim,
white bobble), as in `game_art/run_cycle_sprite_sheet.png`.

## Games

| # | Request | Size | Base / style reference | Gap |
|---|---|---|---|---|
| 1 | **Win celebration** — Capy in the nightcap cheering, arms up, a little jump, with confetti. **No trophy, medal or stars** (no scores in this app). 6–8 frames, one canvas, facing the viewer. | ≥ 360 × 360 each | `animations/05_celebration/` for the motion (it holds a trophy and has no hat); `game_art/run_cycle_sprite_sheet.png` for the character | G34 |
| 2 | **Catch the Capy tile** with the nightcap — same as now, only the hat added | 1254 × 1254, full-bleed | `game_tiles/catch_the_capy.png` | G33 |
| 3 | **Five game tiles**: Tilt Maze, Morning Sort, Rhythm Rescue, Capy Rocket, QR Treasure Hunt | 1254 × 1254 each, full-bleed | `game_tiles/*.png` for format; `01_REFERENCES/games/posters/07`–`10` and `02` for each game's content | G24–G28 |

## Every screen

| # | Request | Size | Base / style reference | Gap |
|---|---|---|---|---|
| 4 | **Meadow footer band** — rolling grass crowns with two daisies, the strip above the tab bar | ≥ 1179 × 196 | `01_HOME.png`, bottom band | G13, G19 |
| 5 | **Cloud edge for the cream sheet** — the scalloped cloud top the cream card has in every mockup, cream `#FEF4E8` | ≥ 1179 × 200 | `05_STATS.png` and `01_HOME.png`, where the cream meets the hero art | G18 |

## Alarms

| # | Request | Size | Base / style reference | Gap |
|---|---|---|---|---|
| 6 | **Four alarm-row thumbnails**, each Capy on its own painted background: sleeping under a blue blanket; headband with dumbbells on grass; backpack walking under sky; **blue** headphones with notes | ≥ 372 × 264 each | `02_ALARMS.png` rows | G14, G15 |
| 7 | *(optional)* **Alarms hero** (Capy hugging an alarm clock) and **Add/Edit hero** scenes | 1536 × 1024 each | `header_scenes/*_integrated.png` | G17 |

## Settings and onboarding

| # | Request | Size | Base / style reference | Gap |
|---|---|---|---|---|
| 8 | **Three theme tiles**: Light (sunrise over hills), System (split sun / moon — *not* a sunset), Dark (night sky, crescent moon, stars) | ≥ 171 × 135 each | `04_SETTINGS.png`, Appearance row | G12 |
| 9 | **Ten puzzle-type icons**: Arithmetic, Number sequences, Missing sign, Compare numbers, Odd one out, Remember digits, Digits backwards, Grid patterns, Spot the change, Rotated shapes | ≥ 132 × 132 each | `asset_library/icons/` (`math`, `numbers`, `memory_cards`, `shapes`…) for style | G21 |
| 10 | **Onboarding welcome scene** — Capy asleep in bed, sunrise window | 1536 × 1024 | `screens/alternative/onboarding_illustrated.png` | G20 |
| 11 | **Puzzle hero scene** — Capy holding a puzzle piece (chooser and onboarding) | 1536 × 1024 | `CapyWake_Puzzle_Chooser_Onboarding_Handoff` boards | G22 |

Items 1–3 change what a player sees in the games right now; 4–5 are on every
tab; the rest are polish. Nothing here blocks the app from working.

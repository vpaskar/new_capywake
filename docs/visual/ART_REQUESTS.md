# CapyWake — open art requests

One list of everything the app still needs drawn, in priority order. Details,
measurements and history for each are in `asset_gaps.md` under the G-number.

**Rules for every file:** transparent PNG unless it says "scene" or "tile";
no text baked in (the app is in 10 languages); no frame, rounded border, white
or black corners; drawn natively at the size given, not enlarged from a sheet;
the capybara in the same style as `game_art/`; frames of one animation on one
shared canvas with the feet on the same line. Put files in
`reference/02_ASSETS/` and run `dart run tool/import_art.dart`.

**Character rule:** in the games, Capy wears the **orange nightcap** (white brim,
white bobble), as in `game_art/run_cycle_sprite_sheet.png`.

## Answered on 2026-11-18 (`CapyWake_Open_Art_Requests`)

All eleven earlier items arrived and are in the app: the win celebration, six
game tiles, the meadow footer, the cloud edge, four alarm thumbnails, the System
theme tile (with Light and Dark from the patch), ten puzzle icons, the
onboarding bedroom and the puzzle hero. What came back short is below; the
per-file findings are in `asset_gaps.md`, "Owner art package".

## Still pending from the owner

| # | Request | Size | Gap |
|---|---|---|---|
| 1 | **Ten per-game win poses with the orange nightcap.** The supplied set (2026-11-18) wears **blue** caps; it is in the app meanwhile. | 512 × 308 each, transparent | G34 |
| 1a | **Step Quest win pose, uncut.** `09_capy_step_quest.png` is cut flat through the top of the cap, in the sheet too; not imported. | 512 × 308 | G34 |
| 1b | *(optional)* **Morning Sort win pose** showing cards or sorting; the supplied one shows a backpack. | 512 × 308 | G34 |

## Replacements for files that arrived short

| # | Request | Size | What was wrong | Gap |
|---|---|---|---|---|
| 2 | **Four alarm-row thumbnails**, same drawings, native | ≥ 372 × 264 each, full-bleed | Upscaled crops with white rounded corners; 332 px after cutting them off | G15 |
| 3 | **Ten puzzle-type icons** as transparent glyphs, each centred with a margin | ≥ 96 × 96 each | Cream tile backing, white corners, soft; two crops cut the glyph | G21 |
| 4 | **Puzzle hero as a painted scene**, the Capy's head and the piece in the middle 40 % of the height | 1536 × 1024 | A cutout on white, upscaled; a 109 pt band would cut the face | G22 |
| 5 | **System theme tile**, same drawing, native | ≥ 171 × 135, full-bleed | Board crop, soft, white margins; 145 px after the cut | G12 |
| 6 | **Win celebration**, same eight frames with a clean matte edge | ≥ 360 × 360 each | A light halo along every outline, visible on dark | G34 |
| 7 | *(optional)* **Alarms and Add/Edit heroes** showing the mockups' Capy hugging an alarm clock | 1536 × 1024 each | The two supplied are the existing Alarms and Settings scenes, unchanged | G17 |

Items 2–6 are polish: every one is in the app now and works. Nothing here
blocks the app.

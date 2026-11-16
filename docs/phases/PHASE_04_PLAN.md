# Phase 04 — Alarms list and Add/Edit alarm

**Mockups:** `reference/01_REFERENCES/screens/primary/02_ALARMS.png`,
`03_ADD_EDIT_ALARM.png` (851×1847 px = 393×853 pt).

**Baseline entering this phase:** 1,116 tests; `lib` 97.38%, `lib/core`
99.41%, `lib/data` 86.40%; 395 ARB keys × 10 locales; HEAD `7e137d4`.

## Objective

The second and third screens with a body, and the **first screen that
writes**. Home reads the repository; Alarms and Add/Edit create, edit, enable,
disable and delete alarms. The ported `AlarmDraft` already owns every
validation rule, so this phase builds a view over a finished domain rather
than inventing one.

## What already exists and is not rebuilt

Measured, not assumed — `lib/core/` was ported whole in Phase 02.

| Need | Already in `lib/core/` |
|---|---|
| Form state, validation, `toAlarm()` | `alarm_draft.dart` (462 lines) |
| Repeat summary copy | `alarm_repeat.dart` — `AlarmRepeatSummary.format` |
| Time/weekday formatting | `alarm_format.dart` |
| Hour/minute stepping with wrap | `time_stepper.dart` |
| Sound catalogue | `alarm_sound.dart` |
| Persistence | `CapyWakeRepository.upsertAlarm` / `deleteAlarm` |

**The ARB is nearly complete for this phase.** All 395 keys were ported in
Phase 02, including `alarmTimeStepperHourUp`, `alarmSoundPreviewPlay`,
`alarmSnoozeDurationValue`, `alarmDeleteConfirmTitle` and
`alarmRepeat{Never,EveryDay,Weekdays,Weekends}`.

**Expected new ARB keys: ≥3 × 10 locales** (pre-review M1). The plan's first
draft said 0, drawn from a prefix search rather than from the screens. Missing:
the alarm-list **empty state**, the **"Add Alarm" pill's visible label**
(`addAlarmTooltip` is a tooltip, not a button label), and the edit screen's
**title in its two states**. The real count is measured and restated below.

### Three gaps in the ported domain (pre-review H1, H2, H3)

The plan's first draft assumed `lib/core/` could drive both screens as-is.
Reading the ported APIs showed it cannot:

- **`AlarmFormat.time` returns one string** (`'7:00 AM'`). Both screens need
  the parts separately — the list styles "AM" smaller than "7:00"; the form
  needs three controls. Splitting the string in a widget is locale-fragile
  (`ja` → `午前7:00`, `de` → no period, `ar` → Arabic-Indic digits). **A
  `ClockTimeParts` + `AlarmFormat.timeParts` is added to `lib/core/`**, built
  from `intl` skeletons, tested across ten locales.
- **`narrowWeekday`'s dartdoc says it is "used for the seven repeat-day
  toggles"** — describing the *legacy's* square toggles. This mockup's chips
  read "Mon Tue Wed", so the chips use `shortWeekday` and the stale dartdoc is
  corrected in place.
- **`watchAlarms()` sorts by `createdAt`**; the mockup is ordered by time. The
  screen sorts by `(targetTimeMinutes, createdAt)` — total, so equal times do
  not swap between rebuilds. The repository is not changed.

## Measurements

Every number below states the method that produced it, per `CLAUDE.md`
"Measuring a block". `L` is row-mean luminance; "hairline" means the dark
1-px card border read at a **text-free column**, which is the method Phase 03
lacked.

### `02_ALARMS.png`

| Block | pt | Method |
|---|---|---|
| Header band lower edge | 103.9 | Inherited from Home — same `CapyHeader` |
| Hero art lower edge | **252.5** | Full-width green-pixel count collapses 67→58; flat art → flat cream, so the detector is valid here |
| Screen title "Alarms" glyph band | 279.4–302.0 | Dark-glyph colour scan, x 21.7–122.8. **Glyph extent, not a block** |
| Add Alarm pill | **272.5–309.4** | Orange colour anchor, x 232.8–377.3 |
| Alarm card 1 | **329.7–419.3** | Hairline minima, x=360 pt (right of chevron, no text) |
| Alarm card 2 | **431.8–518.6** | same |
| Alarm card 3 | **530.4–617.9** | same |
| Alarm card 4 | **630.4–716.7** | same |
| Meadow footer top | **728.3** | Green saturation run, ≥40 hits/row |
| Nav bar top | 774.5 | Inherited from Home |

Derived — stated as inference, not measurement:

| | pt | From |
|---|---|---|
| Card height | **89.6** | 419.3 − 329.7 |
| Card pitch | **101.6** | 431.8 − 330.2 |
| Card gap | **12.5** | 431.8 − 419.3 |
| Add Alarm pill height | **36.9** | 309.4 − 272.5 |

Horizontal, from a row profile at y=345 pt:

| | pt |
|---|---|
| Card left edge | 11.5 |
| Card right edge | 379.6 |
| Thumbnail panel | 11.5 → ~136 (art fades out; **no hard divider**) |
| Toggle track | 302.0 → 339.9, 30.5 pt tall (green colour anchor) |

The gutter is **~11.5 pt**, matching Home's 11.0 — `CapySpacing.gutter`
is reused unchanged.

### `03_ADD_EDIT_ALARM.png`

Card boundaries read as hairline minima at **x=19 pt**, the column between the
outer card edge (15.2) and the inner panel (23.1) — text-free by construction.
Cross-checked at x=372 pt, which agreed within 0.5 pt on both cards it covers.

| Block | pt | Method |
|---|---|---|
| Hero art lower edge | **216.0** | Full-width green collapse 63→56 |
| Time stepper card | **249.8–362.5** | Hairline, x=19 |
| AM/PM pill (AM selected) | **265.5–300.6** | Orange anchor, x 277.5–347.7 |
| Repeat card | **399.9–482.6** | Hairline, x=19 |
| Weekday chip row | **442.9–474.7** | Orange anchor, x 27.2–271.1, 31.8 pt tall |
| Label card | **511.7–577.7** | Hairline, x=19 |
| Sound card | **603.1–643.3** | Hairline, x=372 (cross-checked) |
| Snooze card | **660.4–703.8** | Hairline, x=372 |
| Snooze toggle | 667.3–695.0 | Green anchor, x 320.0–366.7 |
| Save Alarm CTA | **724.6–778.1** | Orange anchor, x 14.8–377.8 |
| Meadow footer top | **793.4** | Green saturation run, ≥40 hits/row (runs to 852.5) |

Derived:

| | pt | From |
|---|---|---|
| Save CTA size | **363.0 × 53.5** | the orange bounding box |
| Gutter | **14.8** | CTA left edge |
| Hour/minute well width | **~91** | row profile at y=285, x 54.5–145.9 and 171.3–262.8 |

**The Add/Edit gutter is 14.8 pt, not Home's 11.0.** Two screens, two gutters,
both measured. This is recorded rather than normalized — Tier A binds the
mockup, and `CLAUDE.md`'s palette ruling ("do as in the mockups") is the same
principle applied to colour.

Pre-review M2: a measured difference the implementation has no way to express
becomes a silent 3.8 pt error. **`CapySpacing.gutterWide = 15.0`** is added
beside `gutter`, named for the screen it was measured from. Shared components
keep their defaults; Add/Edit passes the wide token explicitly.

## Scope

### Alarms list (`lib/features/alarms/`)

1. `alarms_screen.dart` — `SceneHeader(scene: alarms, header: CapyHeader())`,
   title row with the Add Alarm pill, the list, `MeadowFooter`.
2. `alarm_list_tile.dart` — thumbnail, time + period, repeat summary,
   emoji + label, `CapyToggle`, chevron. Tapping pushes the edit route.
3. `alarms_empty_state.dart` — **the default**, built and tested first.

### Add/Edit (`lib/features/alarms/edit/`)

4. `alarm_edit_screen.dart` — back button + centred title (a **different
   header** from the three tabs; the gear is absent), the five cards, Save.
5. `time_stepper_field.dart` — hour/minute wells with chevrons, AM/PM pills,
   over `TimeStepper`.
6. `weekday_chip_row.dart` — seven chips over `AlarmDraft.toggleWeekday`.
7. `alarm_label_field.dart`, `alarm_sound_row.dart`, `alarm_snooze_row.dart`.
8. Delete, with the ported confirm copy. Not in the mockup, which shows the
   **Add** state; an edit screen with no way to remove the alarm would strand
   the user, and the ARB already carries the three keys.

### Routing

`/alarms/new` and `/alarms/:id` inside the alarms branch, so the tab bar stays
visible and popping returns to the list.

### Wiring

A `StateNotifier`-free `AlarmDraft` held in widget state; the repository is
reached through the existing providers. No new provider types.

## Exclusions

Sound **preview playback** (Phase 05 owns the engine), wake-mode and puzzle
configuration (Phases 06/07), reordering, search.

The sound row shows the current sound and opens the **same kind of "not built
yet" sheet Home uses for a `comingSoon` game**, reusing
`alarmSoundPreviewUnavailable` (pre-review L1). An inert row would be the dead
tap `CLAUDE.md` forbids; "follows Home's precedent" means the sheet, not the
absence of one.

## Tests

Mirrors `lib/`. Expected additions, registered here so measurement can
contradict them:

| File | ~Tests |
|---|---|
| `test/features/alarms/alarms_screen_test.dart` | 12 |
| `test/features/alarms/alarm_list_tile_test.dart` | 10 |
| `test/features/alarms/edit/alarm_edit_screen_test.dart` | 16 |
| `test/features/alarms/edit/time_stepper_field_test.dart` | 10 |
| `test/features/alarms/edit/weekday_chip_row_test.dart` | 8 |
| `test/features/alarms/edit/alarm_edit_fields_test.dart` | 8 |
| `test/core/alarm_format_parts_test.dart` (H1, ten locales) | 12 |

**Expected total ≈ 1,192** (1,116 + ~76). The real number is measured and
restated; Phase 02 estimated 66 and measured 83, and said so.

Empty state is tested **before** any populated case.

## Acceptance criteria

1. `tool/capture.sh alarms add_edit_alarm` writes verified PNGs.
2. `compare.dart` reports both screens' blocks; deviations named with deltas.
3. Full validation block green, all three coverage gates held.
4. No numeric literal in a user-facing position in `lib/features/alarms/`.
5. Every control reachable at ≥44 pt; no colour-only state (F1).
6. Ten locales, RTL-safe (`EdgeInsetsDirectional`, `start`/`end`).
7. Asset substitutions logged **by name** in `asset_gaps.md` and reported in
   the session.

## Risks

| Risk | Mitigation |
|---|---|
| Thumbnail art is a cutout, mockup shows a painted panel | Tier B substitution, logged. See gaps below |
| Add/Edit meadow band | **Measured 793.4 → 852.5 (~59 pt).** It is present; the screen gets a `MeadowFooter`. The plan's first draft said "starts ~780" — that was the *Alarms* band's end, carried across and never re-derived (pre-review M5) |
| Capture seed has 1 alarm; mockup has 4 | Extend `captureSeed` to four rows **including two disabled**, so both toggle states are captured. Keep the existing `capture-weekday` id so Home's recorded capture stays valid |
| A 5th card (wake mode) might be assumed | The mockup shows five cards; nothing is added |
| `compare.dart`'s 14 blocks are Home's | Nine cannot exist on a pushed route. **Per-screen blocks with a shared group** (pre-review M4), so anti-cherry-picking survives |

## Asset gaps found while planning (reported, not papered over)

- **G14 — alarm row thumbnails are cutouts, not painted panels.** The mockup
  gives each row a thumbnail with its own painted background bleeding into the
  card. The bundled cells are transparent cutouts. Nearest matches:
  `moments_01` (sleeping), `moments_03` (workout), `collection_02` (walk),
  `collection_06` (headphones). **Used as cutouts on a tinted panel.**
- **G15 — those cells are under-resolution for the thumbnail box.** The panel
  is ~124 × 88 pt, needing ~372 px at 3×; the cells carry 230–288 px
  (`moments_01` 288×190, `collection_02` 230×242). They will be upscaled.
- **G16 — 30 of 31 bundled mascot cells are unreferenced.** Only
  `mascot.sleeping` is in `CapyArt`. This phase adds four; the remaining 26
  are bundled bytes nothing draws.

Pre-review L2: the four cells are registered under a new
**`ArtUse.thumbnail(renderBoxPt: 124)`**, not `mascotSmall` (44 pt). Under
`mascotSmall` the audit would require 132 px and pass art that is visibly soft
— a gate that passes on bad input is worse than no gate. Under `thumbnail` it
requires ~372 px and **fails**, which is correct: that failure is G15, recorded
by name rather than silenced by lowering the requirement.

All three are appended to `docs/visual/asset_gaps.md` and reported in-session.

## Rollback

Every file is new except `alarms_screen.dart` (16 lines), `router.dart`,
`art.dart`, `capture_test.dart`, `compare.dart` and the two docs. Reverting
the commit restores Phase 03.

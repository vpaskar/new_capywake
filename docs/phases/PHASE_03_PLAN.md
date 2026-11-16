# Phase 03 — Home / Today

Reference: `reference/01_REFERENCES/screens/primary/01_HOME.png`.
Written 2026-11-16, **before any code**, per `CLAUDE.md`'s session checklist.

Revised after `PHASE_03_PRE_REVIEW.md`. Findings applied in place and marked ⟲.

## 1. Objective

Build the Home / Today screen against `01_HOME.png` to Tier A, on the domain
Phase 02 ported. Close the three Tier A body blocks `compare.dart` currently
fails because the screens have no bodies.

Home is the first screen in the app with real content, so this phase also
settles several decisions every later screen inherits: what a card looks like,
what the section header + "see all" pattern is, how a row that pushes a route
behaves, and how the meadow footer is drawn.

## 2. What the mockup contains

Read top to bottom from the reference:

| Band | Content |
|---|---|
| Header (59.9 pt) | Sleeping-capybara mascot, `CapyWake` wordmark, gear |
| Hero (188.4 pt) | `today_integrated.png` — capybara asleep in bed |
| Next-alarm card | `7:00 AM` + `Mon – Fri`, green toggle at the trailing end |
| Primary CTA | `Add Alarm` with a `+` badge |
| Section header | `Wake-Up Games` + `See All ›` |
| Game rail | Four tiles: Step Quest, Shake DJ, Catch the Capy, Find the Impostor |
| My Stats row | Bar-chart icon, `My Stats`, chevron |
| Meadow footer | A continuous painted grass band |
| Nav bar | Home · Alarms · Stats |

**Six capybaras**, per `CLAUDE.md`: the hero, the header mascot, and one in
each of the four game tiles.

## 3. Measured Tier A geometry

Measured this phase by luminance-edge detection (`|ΔL| > 6` on a row mean over
x ∈ [20, w−20]) at 2.1654 px/pt, the same detector `tier_a_blocks.md` used, so
the numbers stay comparable. Every block already recorded there reproduced
exactly; the rows marked **new** are this phase's additions.

| Block | Edge (pt) | Status |
|---|---|---|
| Hero scene lower edge | 292.3 | recorded |
| Card top (overlap) | 303.4 | recorded |
| Next-alarm card top | 320.0 | **new** |
| Toggle band | 325.1 – 359.3 | **new** |
| Next-alarm card bottom | 385.1 | **new** |
| Section label baseline | 383.3 | recorded |
| Primary CTA top | 400.4 | recorded |
| Primary CTA bottom | 455.8 | recorded |
| Next section top | 498.8 | recorded |
| Game rail top | 605.0 | recorded |
| Game rail label band | 621.1 | recorded |
| My Stats row top | 662.7 | **new** |
| My Stats row bottom | 709.3 | **new** |
| Meadow footer top | 709.3 | recorded |
| Nav bar top | 774.5 | recorded |

Control geometry, from colour bounding boxes:

| | pt |
|---|---|
| Primary CTA | 370.4 × 55.9 at x 11.1 – 381.0 |
| Toggle | 59.6 × 34.6 at x 303.4 – 362.5 |
| Card hairline, leading edge | 12.5 |
| Game tile, leading edge | 10.2 |

⟲ **Pre-review M2 — one gutter, and why the two edges differ.** The first draft
proposed `gutter = 11.0` on the grounds that 12.5 and 10.2 both "round to ~11",
which is a rounding, not a reason. The 2.3 pt difference has a cause: the card's
detected edge is its **hairline stroke**, drawn inside the card's box, so the
luminance edge sits ~1 pt inboard of the card's true edge. The tile has no
stroke and reads at its true edge.

So the constant is taken from the **tile** measurement — `CapySpacing.gutter =
11.0`, from 10.2 plus the detector's half-pixel bias — and the card uses the
same gutter with its stroke drawn inside. Both then land within 1.5 pt of the
reference, well inside ±4.

⟲ **Correction from the capture (full-project review P2).** The row above
originally read "tile ≈ 94", derived arithmetically from the edges at 605.0 and
621.1 rather than measured. Those two are the tile art's **bottom** and the
label band — not the rail's top. Measured directly, the tile art runs
**532.0 → 606.0 pt = 74.0 pt**, so the estimate was 27% too large and pushed
every block below the rail down. Every other row in this table came from the
detector; this one did not, and it was not labelled as inferred.

### Derived spacing

| | pt |
|---|---|
| Card height | 385.1 − 320.0 = **65.1** |
| Card → CTA gap | 400.4 − 385.1 = **15.3** |
| CTA → section header | 498.8 − 455.8 = **43.0** |
| ⟲ Rail tile art | **74.0** — measured 532.0 → 606.0 pt by saturation scan |
| My Stats row height | 709.3 − 662.7 = **46.6** |
| Meadow band height | 774.5 − 709.3 = **65.2** |

## 4. Asset-to-mockup mapping

Written before the screen is built, per the fidelity contract.

| Element | Asset | Tier | Note |
|---|---|---|---|
| Hero | `assets/art/scenes/today.webp` | A | Already imported; `SceneCrop.home`, top-aligned |
| Wordmark | `assets/art/wordmark.webp` | A | Already imported |
| Step Quest tile | `assets/art/tiles/step_quest.webp` | A | G2 patch closed this |
| Shake DJ tile | `assets/art/tiles/shake_dj.webp` | A | G2 |
| Catch the Capy tile | `assets/art/tiles/catch_the_capy.webp` | A | G2 |
| Find the Impostor tile | `assets/art/tiles/find_the_impostor.webp` | A | G2 |
| Header mascot | ⟲ `assets/art/mascots/collection_00.webp` | A | Bundled and audited; needed a catalogue id, not new art (G12 withdrawn) |
| Meadow footer | **no asset fits** | B | See G13 |
| Nav icons, chevrons, `+` badge, bar-chart icon | Material glyphs | A | G8: the mockup draws flat glyphs, not art |

### Two new asset gaps — reported in session, appended to `asset_gaps.md`

⟲ **G12 — withdrawn, not a gap (pre-review H3).** The first draft filed "the
header mascot is not bundled". Checked against the bundle rather than the
manifest, and it is there: `assets/art/mascots/collection_00.webp` (282×271)
and `moments_12.webp` are the mockup's header mascot almost exactly — sleeping
capybara, blue nightcap with white bobble, `Zz`, yellow duck. `pubspec.yaml`
declares `assets/art/mascots/`, and `art_manifest_test.dart` already
ghost-audits the directory by scan.

What was missing is one line in `CapyArt`. The draft's fallback — omit the
mascot — would have shipped **five** capybaras where `CLAUDE.md` requires six,
with the right asset sitting unused in the bundle. The mascot ships.

This did surface a real structural gap: the mascots are bundled and
ghost-audited but **not catalogued**, so `art_manifest_test.dart`'s
`requiredPixels` check never runs on them. A mascot too small for its box would
ship silently. Closed by §10.

**G13 — no asset matches the meadow band.** ⟲ Re-measured at full row
resolution (pre-review L3), not the sampled scan the first draft used. Green
dominance (G−R) over the footer:

```
709.3 pt  −23.3     band top (the card/footer boundary)
731.5 pt   −0.3     green crosses red
748.1 pt  +24.0
773.1 pt  +40.5     peak
775.8 pt   −3.8     nav bar
```

A smooth monotonic ramp across 42 pt with **no periodicity** — a single
continuous painted band 393 pt wide with two small daisies, not a tiled motif.
The supplied `asset_library/decor/` cutouts are 22×53 to 147×81 px:
`grass_tuft` 90×63, `bush_round` 107×71, `leafy_shrub` 147×81. Tiling a 90 px
tuft 4.4× across 393 pt to fake a painted band would read as a repeat, which is
worse than not having the art. **Using for now:** a drawn band in `grass` with
the mockup's silhouette, no raster. Logged Tier B. If the owner supplies a
painted band later it replaces the painter with no layout change.

## 5. Scope

### In

1. `lib/core/games/game_catalogue.dart` — typed catalogue with
   `GameAvailability { playable, comingSoon, blocked }`. Pure Dart, no Flutter.
2. `lib/design/capy_card.dart` — the rounded cream card with its hairline.
3. `lib/design/capy_toggle.dart` — the large switch from the mockup.
4. `lib/design/meadow_footer.dart` — the grass band.
5. `lib/design/section_header.dart` — label + optional trailing action.
6. `lib/features/home/` — the screen, the next-alarm card, the game rail, the
   coming-soon sheet, the My Stats row.
7. ARB keys for anything the 384 existing keys do not cover, × 10 locales.
8. Widget tests, a golden-free capture, and `docs/visual/home/`.
9. ⟲ **`tool/compare.dart` extended from 4 blocks to 11 (pre-review H1).** Not
   scope creep: `tier_a_blocks.md` already claims the tool reports every row,
   acceptance criterion 5 depends on it, and the nine unreported rows have
   never been compared on any screen. Home cannot be judged against a
   vocabulary the tool does not measure.
10. ⟲ `mascot.sleeping` added to `CapyArt`, and `art_manifest_test.dart`
    extended so a catalogued mascot is size-gated (H3).

### Out

- Any platform plugin. Nothing rings; `AlarmEngine` stays an interface + fake.
- The Alarms list and Add/Edit (phase 04). `Add Alarm` and `See All` route to
  the existing `/alarms` tab, which is a placeholder until phase 04.
- Stats content (phase 08). `My Stats` switches to the Stats tab.
- Any game (phases 11–17). Every catalogue entry is `comingSoon` or `blocked`.
- Retuning the palette. Constraint F1 is honoured, not changed (§7).
- Animation (phase 18).

## 6. Decisions this plan makes

| Question | Decision |
|---|---|
| Header mascot (G12) | ⟲ **Include it, and the asset exists.** `CapyArt` gains `mascot.sleeping` → `assets/art/mascots/collection_00.webp`, chosen against the mockup crop and recorded in `docs/visual/home/`. The draft's "omit if no sleeping pose exists" fallback is deleted — pre-review H3 found two matching cells already bundled |
| Meadow (G13) | ⟲ **Drawn, not raster — and the reasoning belongs in the record (pre-review M6).** The banned legacy rule was *"the capybara is vector `CustomPaint`, never a raster cutout"*: a rule about **how the mascot is drawn**, which is what made the painted look unreachable. The meadow is not a mascot — it is a background band of flat colour with a wavy top edge, and no supplied asset is the right shape (G13). Drawing it is the alternative to tiling a 90 px tuft 4.4× across 393 pt, which reads as a repeat. **Every capybara on this screen is a raster cutout**, which is the rule that matters. `MeadowFooter` is decor and carries `ExcludeSemantics` |
| Game rail source | `lib/core/games/game_catalogue.dart`, pure Dart, so it is testable headlessly and phases 11–17 flip availability without touching the view |
| Step Quest + QR | `blocked`, each carrying its reason, per the architecture plan §6. Step Quest is the **first tile on the mockup**, so the blocked state is visible on a primary screen — intended, logged |
| Tap on a non-playable tile | Opens a modal sheet naming the game and saying it is not built yet. Never a dead tap, never a broken route |
| Next-alarm card with no alarm | ⟲ **The empty state is the default, not a case (pre-review H4).** A fresh install has no alarm, so this is the state the app ships in. Copy read, not assumed (L1): `todayNoAlarmTitle` = "No alarm set", `todayNoAlarmBody` = "When you add an alarm, it will show up here so you can see at a glance what is next." Both fit Home and clear the safety rules — calm, neutral, no overpromising. No new key needed. The **first** test in `home_screen_test.dart` asserts Home against an **empty** repository, before any populated test exists; the capture is taken against a **seeded** repository and the record states that it was seeded and with what |
| Toggle semantics | Writes `enabled` through `CapyWakeRepository.upsertAlarm`. Real, not decorative |
| `See All` / `My Stats` | Tab switches, not pushes — both targets are tabs. Uses `go`, not `push` |

## 7. Palette constraint F1 — how this screen honours it

Binding, from `PHASE_02_POST_REVIEW.md`. In light mode `accent`, `accentDeep`,
`success` and `grass` measure 1.76–2.68:1 on the three light surfaces, under
the 3:1 UI-component minimum, and `error` is 3.93:1 on `surfaceAlt`.

| Element | Channel | Clears F1 because |
|---|---|---|
| `Add Alarm` CTA | `accent` **fill**, `cocoa`-dark text | Fill under dark text is the asserted-good pairing |
| Toggle ON | `success` fill **+ knob position + `Semantics(toggled:)`** | State is carried by position and semantics, not colour alone |
| Toggle OFF | `cocoaSoft` fill + knob position | — |
| Selected tile ring | **Not used.** The mockup rings Step Quest in green; that ring would be `success`-on-`cream` = 2.68:1 as the only channel | Omitted, logged as a Tier B deviation with this reason |
| Meadow band | `grass` | Decor, not a UI component — F1 scopes to controls |
| Nav active tab | `accent` icon **+ `w700` label + `Semantics(selected:)`** | Already built in Phase 01; weight and semantics are the redundant channels |

⟲ **Pre-review H3.** The mockup's green ring around Step Quest is a real Tier A
deviation, not a free omission. It reads as "selected/featured", and dropping it
loses a visual. But reproducing it would put a 2.68:1 boundary as a control's
only state channel, which F1 forbids — and Step Quest is `blocked`, so a ring
implying "available" would also be a content lie. **Replaced, not dropped:** the
tile keeps a ring, drawn in `cocoa` at 2 pt, which is the ring the mockup draws
on no tile but which carries the same "this one is distinct" reading at 11.8:1.
Recorded as a deliberate Tier A deviation in the post-review with both reasons.

No token is retuned. Retuning is a Tier A decision for the owner.

## 8. Countable terms — registered before implementation

Per the Phase 02 lesson: state the expected count, measure it, restate it if it
changes rather than quietly passing.

| Term | Expected | Basis |
|---|---|---|
| Existing tests | **1,051** | Phase 02's measured total |
| New ARB keys | ⟲ **11** | §9 — 7 screen keys + 4 game names, measured against the 384 existing |
| ARB keys after | ⟲ **395** | 384 + 11 |
| New `lib/core/` files | 1 | `games/game_catalogue.dart` |
| New `lib/design/` files | 4 | card, toggle, meadow, section header |
| New `lib/features/home/` files | 4 | screen, next-alarm card, game rail, coming-soon sheet |
| New test files | 5 | catalogue, card+toggle, home screen, game rail, meadow |
| Blocks reported by `compare.dart` | ⟲ **14** | Pre-review H1 — was 4. See the correction below |
| Viewport widths tested | ⟲ **3** | Pre-review M4 — was 0, project-wide |
| New tests | **N — measured, not estimated** | Restated in the post-review |

⟲ **The block count was restated twice, which is the discipline working.** The
pre-review said 11 — "13 documented rows minus 2 device insets". That is right
about the *drawn* rows and forgets that Phase 03 measured three more (the
next-alarm card's two edges and the My Stats row's top). 11 + 3 = **14**, and
`tool/compare.dart` reports 14. Stated here rather than quietly shipped,
exactly as Phase 02 restated N = 13 rather than 5.

## 8a. The comment budget — added mid-phase at the owner's request

The owner asked for `../protio`'s comment budget and `../gastrowerk`'s
enforcement to be brought into this project. Both are now in, and the numbers
below were **measured here**, not inherited:

| | |
|---|---|
| Budget | **2 lines / 300 chars** per comment block — Protio's exact numbers |
| Measured before | 1,302 runs across `lib/ test/ tool/`; median 2 lines / 126 chars; **523 over 2 lines**; max 45 lines / 2,380 chars |
| Baseline | **113 files**, 116,517 excess chars — may only shrink |
| Phase 03 files in the baseline | **0** — every new file meets the budget outright |

A blank `///` separator counts as a line, so "summary, blank, detail" is
already over; every Phase 03 doc comment is two real lines.

**Why a ratchet and not Protio's zero-offender gate.** The worst offenders are
ported `lib/core/` files whose prose Phase 02 read in full and judged justified
(DST semantics, a state-machine transition table) — and Phase 02 withdrew
`gastrowerk`'s 12-line rule here because its number came from `gastrowerk`'s
tree. Rewriting them is outside this phase and was not asked for. The owner
chose "Protio's 2/300, ratcheted" when asked.

Pieces: `tool/trim_comments.dart` (ported, `--fix` and `--update-baseline`),
`test/style/comment_budget_test.dart` (the gate, inside `flutter test`),
`test/style/comment_budget_baseline.json`.

**The gate was verified in three directions**, not assumed: it passes clean,
it fails with a useful message when four comment lines are added to a clean
file, and it passes again when they are removed. A guard that cannot fail is
the Phase 02 lesson about gates green for the wrong reason.

⟲ **Pre-review H4.** The first draft of this table estimated "~35 new tests".
Phase 02's pre-review made exactly that mistake and was 26% out. A count that
can only be known by writing the tests is **not** registered as a number; it is
registered as "measure and restate". The terms that *are* knowable in advance —
ARB keys, file counts, the existing total — are fixed above and the post-review
checks them.

## 9. ARB keys

Measured against `lib/l10n/app_en.arb` (384 keys). The 39 `today*` keys cover
most of the screen. Missing:

| Key | English | Why not covered |
|---|---|---|
| `homeGamesHeading` | Wake-Up Games | `todayWakePuzzlesHeading` is "Wake Puzzles" — a different feature |
| `homeGamesSeeAll` | See All | `todayWakePuzzlesSeeAll` is puzzle-scoped |
| `homeMyStats` | My Stats | No equivalent |
| `homeGameComingSoonTitle` | Not built yet | No equivalent |
| `homeGameComingSoonBody` | {game} is on the way. We'll add it in a future update. | Placeholder `{game}` |
| `homeGameBlockedBody` | {game} needs a permission CapyWake doesn't ask for yet. | Placeholder `{game}` |
| `homeGameUnavailableBadge` | Soon | Tile badge |

Plus the four game display names. They are product names and the mockup shows
them untranslated — but `CLAUDE.md` forbids hardcoded user-facing strings
outright, so they are ARB keys with identical values in the locales where the
name does not translate:

| Key | English |
|---|---|
| `gameStepQuest` | Step Quest |
| `gameShakeDj` | Shake DJ |
| `gameCatchTheCapy` | Catch the Capy |
| `gameFindTheImpostor` | Find the Impostor |

⟲ **Total: 11 new keys, 384 → 395** (pre-review M1 — the first draft reasoned
to 11 and then left 7/391 standing in §8 and the acceptance criteria; all three
now read 11/395).

The empty-state keys need no addition: `todayNoAlarmTitle` and
`todayNoAlarmBody` were read (L1) and fit Home as written.

## 10. Tests

| File | Asserts |
|---|---|
| `test/core/games/game_catalogue_test.dart` | Every entry has an id, name key, tile asset and availability; **zero `playable`** (the state it ships in); Step Quest and QR are `blocked` with a reason; ids unique; every tile asset is in `CapyArt` |
| `test/design/capy_card_test.dart` | Card renders, hairline present, radius from tokens; toggle on/off renders, `Semantics(toggled:)` set both ways, tap fires |
| `test/design/meadow_footer_test.dart` | Renders at the measured height; `ExcludeSemantics` |
| `test/features/home/home_screen_test.dart` | **Empty state first** — renders against an empty repository before any populated test exists; populated branch renders time + repeat summary; toggle writes through the repository; `Add Alarm` routes; `My Stats` routes; ⟲ renders at **320×568, 393×852, 430×932** with no overflow (M4); ⟲ no clock-shaped or weekday-shaped literal in `lib/features/home/` (L2) |
| `test/features/home/game_rail_test.dart` | Four tiles from the catalogue; a `comingSoon` tap opens the sheet; a `blocked` tap opens the sheet with its reason; no tile is a dead tap; tile labels come from l10n; ⟲ the four names render unclipped in `en`, `de`, `ru` (M5) |
| ⟲ `test/design/art_manifest_test.dart` (extended) | A catalogued mascot meets its render box; the directory scan and the catalogue do not disagree about a file that exists (H3) |

⟲ **Pre-review M3 — the widget test does not satisfy the capture.** A widget
test measures a tree under a synthetic viewport with test fonts and no device
insets; the fidelity contract accepts a capture of the real app on the
simulator, and `CLAUDE.md` says *"Do not claim a screen matches without a
recorded capture."* The widget-test block assertion is a **cheap regression
guard**; acceptance criterion 5 is satisfied **only** by `tool/capture.sh` +
`tool/compare.dart`, and the post-review reports the capture's numbers, not the
widget test's.

⟲ **Pre-review M5 — tile labels.** The label box is two lines at the body
scale with `TextOverflow.visible` in a fixed-height slot. `CLAUDE.md` and
`flutter:accessibility-as-code` forbid `TextOverflow.ellipsis` as a fitting
device, and clipping a product name is a content defect. If a name does not fit
in two lines at tile width in any of the ten locales, the post-review reports
the measured string rather than silently ellipsising it.

## 11. Acceptance criteria

1. Full validation block from `CLAUDE.md` passes, zero analyze issues
   including infos.
2. `dart run tool/check_arb.dart` — 10 locales × ⟲ **395** keys.
3. Coverage: project ≥ 85%, `lib/core` ≥ 95%, `lib/data` ≥ 85%.
4. `tool/capture.sh home` writes a verified PNG at 1179×2556.
5. ⟲ **Split in two (pre-review H2).**
   - **5a.** `tool/compare.dart` reports ⟲ **11 blocks** — the nine drawn rows
     of `tier_a_blocks.md` plus the two of §3's five new ones that are
     structural edges — and every one lands within ±4 pt. Binding.
   - **5b.** Where a block is outside tolerance, the post-review states whether
     the cause is that block's own geometry or **accumulated drift** from the
     blocks above it, with the measured per-block deltas, and fixes the
     originating box rather than padding the symptom.
6. ⟲ `compare.dart`'s `referenceBlocks` and `tier_a_blocks.md` agree, and that
   file records which rows the tool reports — so the document and the tool
   cannot drift apart again (H1).
7. `docs/visual/home/` holds the reference, the capture, the side-by-side and
   the deviation log. The capture record states it was taken against a
   **seeded** repository and with what (H4).
8. Every Tier B substitution named by file.
9. `asset_gaps.md` gains G13 and records **G12 as withdrawn** with its
   reasoning — appended, not restarted.
10. No fabricated data on Home: the empty state is the default, and
    `lib/features/home/` holds no clock-shaped or weekday-shaped literal.
11. ⟲ Home renders without overflow at 320, 393 and 430 pt (M4).
12. No new dependency.

## 12. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| The meadow band is drawn and reads as flat beside painted art | Medium | Match the mockup's silhouette; capture and judge against the reference, not against intent |
| Game rail at 320 pt overflows | Medium | Horizontally scrollable rail; tested at 320 / 393 / 430 |
| Step Quest `blocked` is the first thing a user sees | Medium | Intended and logged; the sheet explains honestly |
| The ring substitution (§7) is read as a miss rather than a decision | Low | Recorded in the post-review with both reasons |
| ⟲ Tile labels wrap differently in `de` / `ru` | Medium | Pre-review M5 — "Find the Impostor" is two lines in the mockup already; tile label box is fixed-height, two lines, tested in `de` |

## 13. Rollback

Single phase on `main`. Revert is the phase commit; nothing before it is
touched. No schema change, no dependency change, no generated-code change.

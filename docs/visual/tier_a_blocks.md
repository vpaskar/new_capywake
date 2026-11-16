# Tier A — the block vocabulary

Pre-review finding M5: CLAUDE.md makes Tier A binding at "±4 pt on major block
positions" and never names a block, which would let each screen pick the blocks
it already matches. This file names them.

Measured from `reference/01_REFERENCES/screens/primary/01_HOME.png` by
luminance-edge detection (|ΔL| > 18 on a row mean), at 2.1654 px/pt.

`tool/compare.dart` reports **every row below for every screen**. A screen's
phase may **add** blocks; it may never remove one.

## Normalization

| | |
|---|---|
| Mockup | 851×1847 px @ 2.1654 = 393×**853** pt |
| Device capture | 1179×2556 px @ 3 = 393×**852** pt |
| Width | exact |
| Height | 1 pt short |

The reference is scaled to the captured **height**. **±1 pt is rounding, not
signal**, and every report prints the normalization it used so a reader can tell
measurement from tolerance.

## Blocks — Home (`01_HOME.png`)

| Block | Edge (pt) | How it reads |
|---|---|---|
| Status bar lower edge | 44.0 | Device inset, not drawn by us |
| Header band lower edge | 103.9 | Cream header → hero art |
| Hero scene lower edge | 292.3 | Art → card surface |
| Card top (overlap) | 303.4 | The cream card overlapping the art |
| Section label baseline | 383.3 | — |
| **Primary CTA top** | **400.4** | Add Alarm |
| **Primary CTA bottom** | **455.8** | — |
| Next section top | 498.8 | — |
| Game rail top | 605.0 | — |
| Game rail label band | 621.1 | — |
| Meadow footer top | 709.3 | Grass band |
| **Nav bar top** | **774.5** | — |
| Home indicator | 839.1 | Device, not drawn by us |

## Control geometry — Home

Measured from the orange cluster bounding box:

| | pt |
|---|---|
| Primary CTA size | **370.4 × 55.4** |
| Side margin, left | 11.1 |
| Side margin, right | 11.5 |

So the screen gutter is **~11 pt** and the CTA is full-width within it. The
button's lower edge is a darker band (`accentDeep`), not a shadow.

## Derived

| | pt |
|---|---|
| Header band height | 103.9 − 44.0 = **59.9** |
| Hero band height | 292.3 − 103.9 = **188.4** |
| Card overlap onto art | 303.4 − 292.3 = **11.1** |
| Nav bar height | 839.1 − 774.5 = **64.6** |

The hero band is 188.4 pt tall under a 59.9 pt header — **two blocks, not one**.
G9's withdrawal note measured them together as a single 234 pt band, which is
why its crop figure (10.7%) is too small. Corrected against the art-only band:

```
hero band  393 × 188.4 pt = 2.086:1
3:2 source, cover at full width → 393 × 262.0 pt
crop = 73.6 pt of 262.0 = 28.1%
```

**G9 stays withdrawn, for a different reason than stated there.** The crop is
large, not small — but it is still benign: rendered all three alignment extremes
from `today_integrated.png` at 2.086:1 and the capybara's face sits clear of
both edges in every one, with 288 px of `Alignment.y` travel. `SceneHeader`
exists to absorb exactly this. The finding was right to withdraw and wrong about
the number; both are corrected in `asset_gaps.md`.

## Phase 03 corrections — the detector reports glyph edges as blocks

Phase 03 built Home against this table and the capture disagreed. Two of its
rows were wrong, and both were wrong the same way: **a row-mean luminance
detector cannot tell a block boundary from a line of text.**

| Row | Was | Is | What the old value actually was |
|---|---|---|---|
| Game rail top | 605.0 | **485.7** | The tile art's *bottom* |
| Game rail label band | 621.1 | **593.9** (labels end) | A glyph edge inside the labels |
| My stats row top | 662.7 | **617.0** | A glyph edge in the second label line |
| Meadow footer top | 709.3 | **672.4** | — |

The corrected values were read off a crop of `01_HOME.png` at 520–700 pt, and
cross-checked against a hard anchor the detector cannot confuse: the My Stats
row's **orange bar-chart icon**, which occupies 632–651 pt by colour sampling
and sits inside a card measuring 617.0–665.5.

The tile band was measured separately by **saturation scan** — the tiles are
the only strongly saturated art in that region — giving 74.0 pt, against the
"≈ 94" the plan had inferred arithmetically from the two wrong rows.

**Rule for later phases:** a block boundary between two flat areas may come
from the detector. A boundary adjacent to text, or between two textured
regions, must be read off a crop or anchored to something with a distinct
colour. State which method produced each number.

These four rows are measured **from the status bar**, like the capture, rather
than as absolute mockup offsets like the rows above them.

## Status

Home is measured. **Alarms, Add/Edit, Settings and Stats are measured by their
own phases** (04, 04, 07, 08) and appended here, using the same detector so the
numbers stay comparable — subject to the correction above.

## Blocks — Alarms (`02_ALARMS.png`), Phase 04

Measured with the method `CLAUDE.md` requires. **The method is named beside
every number**, because three of Phase 03's rows were glyph edges read by a
detector that cannot tell text from a layout boundary.

| Block | Edge (pt) | Method |
|---|---|---|
| Hero art lower edge | **252.5** | Full-width green-pixel count collapses 67→58. Flat art → flat cream, so the row-mean detector is valid here |
| Add Alarm pill | **272.5–309.4** | Orange colour anchor, x 232.8–377.3. 36.9 pt tall |
| Alarm card 1 | **329.7–419.3** | Hairline minima at x=360 pt, a column with no text in it |
| Alarm card 2 | **431.8–518.6** | same |
| Alarm card 3 | **530.4–617.9** | same |
| Alarm card 4 | **630.4–716.7** | same |
| Meadow footer | **728.3–780.5** | Green-saturation run, ≥40 hits per row |
| Nav bar top | 774.5 | Inherited from Home — same `CapyNavBar` |

Derived (inference, not measurement):

| | pt | From |
|---|---|---|
| Card height | 89.6 | 419.3 − 329.7 |
| Card pitch | 101.6 | 431.8 − 330.2 |
| Card gap | 12.5 | 431.8 − 419.3 |
| Hero band | **148.6** | 252.5 − 103.9 — **not Home's 188.4** |
| Meadow height | **52.2** | 780.5 − 728.3 — **not Home's 65.2** |

Horizontal, from a row profile at y=345 pt: card 11.5 → 379.6, thumbnail panel
11.5 → ~136 (the art fades out; there is no hard divider), toggle track
302.0 → 339.9 at 30.5 pt tall.

## Blocks — Add/Edit (`03_ADD_EDIT_ALARM.png`), Phase 04

Card boundaries are hairline minima at **x=19 pt**, the column between the
outer card edge (15.2) and the inner panel (23.1) — text-free by construction.
Cross-checked at x=372 pt, which agreed within 0.5 pt on both cards it covers.

| Block | Edge (pt) | Method |
|---|---|---|
| Hero art lower edge | **216.0** | Full-width green collapse 63→56 |
| Time stepper card | **249.8–362.5** | Hairline, x=19 |
| AM pill (selected) | **265.5–300.6** | Orange anchor, x 277.5–347.7 → 70.2 × 35.1 |
| Repeat card | **399.9–482.6** | Hairline, x=19 |
| Weekday chip row | **442.9–474.7** | Orange anchor, x 27.2–271.1, 31.8 pt tall |
| Label card | **511.7–577.7** | Hairline, x=19 |
| Sound card | **603.1–643.3** | Hairline, x=372 |
| Snooze card | **660.4–703.8** | Hairline, x=372 |
| Save CTA | **724.6–778.1** | Orange anchor, x 14.8–377.8 → 363.0 × 53.5 |
| Meadow footer | **793.4–852.5** | Green-saturation run |

Derived: gutter **14.8** (not Home's 11.0 — `CapySpacing.gutterWide`), hero
band **112.1**, hour/minute wells ~91 pt wide (x 54.5–145.9, 171.3–262.8).

**Each screen's hero band and meadow differ.** Home 188.4/65.2, Alarms
148.6/52.2, Add/Edit 112.1/59.1. Phase 04 took Home's defaults and read +39.8
pt on the first capture; `SceneHeader.bandHeight` is now a required parameter
so Phases 07 and 08 cannot repeat it.

## Phase 04 — the detector could not see a card border

`compare.dart`'s row-mean scan needs |ΔL| > 18. A 1-px card border moves a
393-pt row mean by **under one unit**, so every alarm card was reported
`absent` while all four were on screen and correctly placed. A second miss:
the first fix cut at L < 235 and still could not see the two **disabled**
rows, whose 55%-opacity borders land near 236.

`_hairlines` now reads local minima down the same text-free column the mockup
rows were measured at, at L < 244. **A boundary the tool cannot see is
reported as a layout failure it never measured.**

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

## Status

Home is measured. **Alarms, Add/Edit, Settings and Stats are measured by their
own phases** (04, 04, 07, 08) and appended here, using the same detector so the
numbers stay comparable.

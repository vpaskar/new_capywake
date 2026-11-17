# Settings capture

`actual.png` is a real capture from the iPhone 14 Pro simulator, written by
`tool/capture.sh` and verified by it: 1179×2556 px (393×852 pt), non-empty,
newer than the run, no debug banner. `inset.txt` records the device's 59.0 pt
top inset; the mockup draws a 44 pt status bar, so every offset is compared
from the inset rather than from the top of the screen.

Captured against the shared `captureSeed`, at **scroll offset 0**. The screen
scrolls, so blocks below the fold depend on scroll position and are not
compared.

## What is claimed, and what is not

`04_SETTINGS.png` draws an **Account** group holding Backup & Sync, Restore
Purchases and About, an **App Icon** row, and a **Daily Reminder** toggle.
`CLAUDE.md` drops the first two by name ("there is no backend and nothing to
restore"); the other two have nothing behind them either. The mockup's **Alarm
Notifications** switch is shipped as a status row, because a switch there
would stop every alarm from ringing from inside Settings (pre-review **H2**).

So the shipped row set differs from the mockup's by design, and every block
below Appearance's top sits at a different distance down the screen as a
*consequence of that decision*, not of layout error. Those blocks are **not
claimed**. `tool/compare.dart` reports only the four that the row cuts cannot
move, plus the shared header row.

| Block | Ref (pt) | Actual | Delta | |
|---|---|---|---|---|
| header band lower edge | 59.9 | 60.0 | **+0.1** | ✅ |
| hero scene lower edge | 168.9 | 169.0 | **+0.1** | ✅ |
| group 1 card top | 187.4 | 184.7 | **−2.7** | ✅ (see below) |
| group 1 card bottom | 297.8 | 302.3 | **+4.5** | ❌ |
| group 2 card top | 311.6 | 311.0 | **−0.6** | ✅ |

**Group 1's top reports `absent` in the tool, not −2.7.** The tool's column
scan cannot see that edge; −2.7 is measured here by the left-card-edge trace
described below, which is the same method the mockup was measured with. An
unseen block is reported as absent rather than matched to a distant edge —
see "The tool was wrong twice" below.

## The one block over tolerance, and why it cannot be fixed

Group 1 is **117.2 pt** tall against the mockup's **110.4**.

| | pt |
|---|---|
| group header band | 28.0 measured (mockup 28.2) |
| plain row | **44.0** measured |
| group 1 = band + 2 rows | **116.2 minimum** |
| mockup group 1 | **110.4** |

The mockup's row is **41.1 pt**. The tap-target floor is **44 pt**, and
`CLAUDE.md` makes it binding: *"Core alarm controls are large and reachable —
a half-asleep user, no precision tapping."* A row cannot be both 41.1 pt and
reachable, so **the floor wins and the deviation is declared.**

Every removable pt was removed to get here: the row's vertical padding is
`CapySpacing.xs`, titles and values are held to one line at the default text
scale, and the band is within 0.2 pt of the mockup. At 2× text scale titles
are allowed to wrap again — reachability outranks row pitch in both
directions.

## Tier B — substitutions, by name

**The theme tiles have no art.** `04_SETTINGS.png` draws three illustrated
tiles (a sunrise, a sunset, a night sky) at x 180.6–240.2 / 247.1–303.0 /
310.8–366.2, y 384.7–429.5. The asset package ships **no file for any of
them** — `assets/art/` holds `scenes/`, `tiles/`, `mascots/` and
`wordmark.webp`, and nothing matching a theme, icon, sun or moon. Each tile is
drawn from palette tokens instead: cream, a cream/dark split, and dark.
Reported in `asset_gaps.md` as **G12**.

**The middle tile is System, not Sunset.** `ThemeModePreference` is
system / light / dark. A sunset theme does not exist, and adding a fourth tile
for it would put a control on screen that changes nothing.

## The tool was wrong twice, and both are fixed

`tool/compare.dart`'s hairline scan read a **single column at x=360 pt**. That
column is text-free on Alarms — where Phase 04 chose it — and sits **under the
hero art** on Settings, where it returned dozens of art minima (L≈90–135) and
never saw the card edge at all. It now scans x=360, 22 and 8 and merges them,
and ignores anything below L=150 as paint rather than a hairline.

`_nearest` then searched **±40 pt** for an edge to match. With group 1's own
edge undetected, it claimed the **hero's** edge 18.7 pt away and reported
"group 1 card top −18.7 TIER A FAIL" for a block sitting 2.7 pt from its mark.
The search is now ±12 pt; past that the answer is `absent`, which still counts
as a failure — an unmeasured block is not a passing block.

Both changes were checked against the three already-captured screens before
being kept. Neither introduced a failure, and both reduced false deltas:

| Screen | Worst delta before | After |
|---|---|---|
| Home | 36.2 | **1.4** (6 absent) |
| Alarms | 21.6 | **10.0** (2 absent) |
| Add/Edit | 31.1 | **10.5** (4 absent) |
| Settings | 28.4 | **4.5** (1 absent) |

**This is a finding about earlier phases, not about this one.** Home and
Alarms were already failing their own block tables under their own tools and
their own committed captures — see `PHASE_07_POST_REVIEW.md`.

## Method

Every number in the block table above was produced by a method named beside
it in `docs/visual/tier_a_blocks.md`. The one worth repeating:

**The left-card-edge trace.** For each row, the first x in 0…30 pt with
L < 238. A row inside a card has a dark edge pixel at x = 9.7 pt; a row in the
gap between two cards has none anywhere in that span. This is what caught my
own first reading, which took each card's **bottom drop-shadow** for the next
card's **top** — an error that would have put every group ~15 pt high and
every gap at −1.4 pt. A negative gap should have been the tell, and nearly
wasn't.

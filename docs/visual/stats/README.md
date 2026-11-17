# Stats — `05_STATS.png`

Captured on the iPhone 14 Pro simulator at 393×852 pt, via `tool/capture.sh
stats`. Block table in `tool/compare.dart` under `'stats'`; methods and the
unclaimed measurements in `docs/visual/tier_a_blocks.md`.

## The mockup is a filled screen; the default is empty

`CLAUDE.md` makes the empty state **the default, not a fallback**, so a fresh
install renders none of what the mockup draws: `7 h 32 m`, `+18 min`, a
seven-bar chart labelled 7:20…7:34, `6 days` with `Best: 14 days`, an `8 h`
goal at `Avg. 94%`, `10:28 PM` / `7:00 AM`, `52 h 44 m`.

**Every one of those is fabricated.** The screen renders the em dash
(`statsNoValue`) in each value slot, spoken as "No data yet", with the four
card envelopes kept so the screen holds the shape the mockup draws.

## Tier A

```
block                          ref   actual    delta
header band lower edge        59.9     60.0      0.1
hero scene lower edge        171.4    171.3     -0.1
segment track top            202.1    200.7     -1.4   within tolerance
segment track bottom         237.2    240.7      3.5   within tolerance
meadow footer bottom         729.1       --   absent
```

**Four of five claimed blocks pass; one is `absent`, which counts as a
failure.** Named here rather than omitted — Phase 07's full-project review H1
found two phases recording only the blocks they passed.

### The `absent` one is shared shell geometry, not this screen's

The painted grass ends at **694.3** against an expected **729.1** — 34.8 pt,
far outside the tool's ±12 pt search. Measured on every capture:

| Screen | Grass ends | Nav bar |
|---|---|---|
| home, alarms, **stats** | **694.3** | present |
| settings | 793.0 | absent — pushed route |

`CapyNavBar` occupies 98.7 pt where the mockup allots 79.9. `meadowHeight` is
correctly Stats' own measurement (853 − 773.1 = **79.9**); the footer simply
sits above a taller nav bar. Alarms' `+10.0`, recorded by Phase 07, is the
same fact from its own reference value. See `asset_gaps.md`.

### The 3.5 pt on the track bottom

The switcher's row takes the **44 pt tap floor**, which `CLAUDE.md` binds over
the mockup, while the pill inside it renders **30.7** against the mockup's
30.9. The row's extra height pushes the track's lower border down. A declared
rule conflict in the same family as Settings' 41.1 pt row.

### The 1.4 pt on the track top, and why it cannot be zero

`05_STATS.png` places "Statistics" **6.7 pt above** the cream sheet's flat top,
inside one of the cloud's raised lobes. `SceneHeader` draws a flat-topped
sheet (`asset_gaps.md` G18), so the title must start below that edge.

Arithmetic, from the cream top at 171.4 (from inset):

```
budget to the mockup's track top    205.4 - 171.4 = 34.0
title line box (CapyType.title 24 x 1.2)          = 28.8
switcher centring ((44 - 30.9) / 2)               =  6.55
                                            left  = -1.35
```

**The budget is negative before any padding is added**, so `titleTopGap` and
`titleToSwitcherGap` are both `0.0` and the residual is the 1.4 pt above.

## Blocks deliberately not claimed

All four card bottoms, cards 2–4 tops, and 100% of the mockup's intra-card
geometry. The default state does not render them: an empty card is shorter
than a filled one, so every one of those positions is high by construction.

Their mockup values **are** measured and recorded in `tier_a_blocks.md` so the
phase that builds the filled state inherits them.

## Tier B — substitutions, by name

- **Hero.** `assets/art/scenes/history.webp` (`SceneCrop.stats`), the
  trophy-and-capybara scene. Matches the mockup's hero.
- **Sleep segment and empty states.** `thumb.sleeping` via `StatsNotice`,
  the same asset `AlarmsEmptyState` uses. The mockup's sleeping capybara on a
  pillow with `Zz` is a different cut that is not in the package.
- **No chart art.** The mockup's bar chart is not drawn: there is no data to
  chart, and no bar chart primitive was built for a surface that would render
  empty.

## What this screen will not say

- **No "Connect Health".** The existing `sleepHistoryEmpty` reads *"No sleep
  to show yet. Connect Health to see your nights here."* and there is **no
  Connect control anywhere in the app** — `package:health` has not landed.
  The Sleep segment uses `statsSleepUnavailableTitle` /
  `statsSleepUnavailableBody` instead, which state the fact and promise no
  control. `sleepHistoryEmpty` is kept, unused, for the phase that lands the
  gateway; a widget test asserts it is not rendered.
- **No score, streak, or personal best.** The Games segment states that game
  activity is not recorded. `CLAUDE.md` forbids those on the puzzle, and
  nothing records game results in any case.
- **"Last 14 days", not the mockup's "Last 7 Days".** The label renders the
  window actually queried (`HistoryService.defaultWindowDays`). 7 is offered
  as a choice, so the mockup's state is reachable — the user picks it, the app
  does not fake it.

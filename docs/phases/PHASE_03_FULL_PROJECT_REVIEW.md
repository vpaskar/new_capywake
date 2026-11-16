# Phase 03 — full-project review

One pass over the whole repository, not only Phase 03's diff. The question is
what this phase's work reveals about the project as a whole.

## Summary

| # | Severity | One line | Outcome |
|---|---|---|---|
| P1 | **High** | `SceneHeader` misread the mockup and shortened every hero band by 11.1 pt | Applied |
| P2 | **High** | The game rail was built 94 pt wide against a measured 74 pt | Applied |
| P3 | **High** | Phase 02's "85.08% is the honest figure" was itself wrong | Applied |
| P4 | Medium | `compare.dart` snaps each block to the nearest edge, which can mislead | Recorded |
| P5 | Low | `docs/visual/shell/` is now a stale directory | Applied |

---

## P1 — `SceneHeader` shortened the hero band on every screen

**High.** This is the finding that justifies the whole capture-and-compare
apparatus, and nothing short of a real capture would have found it.

`docs/visual/tier_a_blocks.md` records two edges near the bottom of the hero:

| Block | Edge |
|---|---|
| Hero scene lower edge | 292.3 pt |
| Card top (overlap) | 303.4 pt |

Phase 01 read the 11.1 pt between them as *"the card rides up over the art's
lower edge"* and implemented it as
`Positioned.fill(top: bandHeight - overlap)` — the cream card drawn **inside**
the art's `Stack`, 11.1 pt above its bottom.

It is not two positions. It is **one edge and the curve of a corner**: the card
begins flush with the art at 292.3, and its 28 pt radius means full-width cream
is only reached at 303.4. The detector sees both and records them as two rows,
which is correct; the interpretation was wrong.

The cost, measured on the first real capture of a screen with a body:

```
hero scene lower edge   ref 248.3   actual 237.3   -11.0  TIER A FAIL
```

— and because every block below sits on top of that, **13 of 14 blocks failed**,
with a worst delta of 38.7 pt against a 4 pt tolerance.

**This was latent in Phase 01 and invisible to it.** Phase 01 captured three
screens and compared four blocks, three of which it reported as failing
"because the screens have no bodies". The band error was inside one of those
three, attributed to an empty body rather than to a layout defect.

**Applied.** The card is no longer drawn inside the art's `Stack`; the band is
its own box at the measured 188.4 pt and the card follows it in the `Column`,
flush. `overlap` is kept as a documented no-op constant with the reasoning, so
the next reader does not re-derive the same mistake from the same table.

## P2 — the rail was 94 pt against a measured 74 pt

**High.** `GameRail.tileSize` was `94.0`, taken from the plan's estimate that
the tiles were "≈ 94 pt" — an inference from two edge rows, not a measurement.

Measured directly by saturation scan (the tiles are the only strongly
saturated art in that band):

```
tile art START at 532pt
tile art END   at 606pt     => 74.0 pt
```

27% too large, which pushed My Stats and the meadow down and contributed to
the cascade in P1.

**This is the plan's own §3 failing its own rule.** Every other row in that
table came from the luminance detector; `tile ≈ 94` was derived arithmetically
from "rail top 605.0" and "rail label band 621.1" — and 605.0 is in fact the
tile art's *bottom*, not the rail's top. The registered-terms discipline
applies to geometry too: a number that is inferred should be labelled as
inferred, and this one was not.

**Applied.** `tileSize = 74.0`, with the measurement and its method in the
constant's own doc comment.

## P3 — Phase 02's coverage claim was wrong, and it is worth saying so

**High**, and it changes a recorded conclusion rather than only code.

`PHASE_02_POST_REVIEW.md`, `memory/current-phase.md`, the tracker and
`docs/sessions/next.md` all state that `lib/data`'s 85.08% is the honest figure
— that 67 lines are structurally uncoverable Drift getters, that the
hand-written code is really 422/429 = 98.4%, and that the number should not be
"fixed".

The first two claims are true. **The conclusion was not.** Part of that 85.08%
was an accident: five providers (`proStatusStreamProvider`,
`puzzleSettingsStreamProvider`, `sleepNightStoreProvider`,
`sleepSyncStateStreamProvider`, `sleepNightsStreamProvider`) were **never read
by any test** and counted as covered only because something in the suite
constructed the graph far enough to execute their declarations.

Phase 03's Home tests override `appDatabaseProvider` with an in-memory
database. That removed the accident, and the figure fell to **82.76%** — which
is not a regression Home caused but **the first honest measurement of that
tree**. A typo in any of those five would have shipped.

**Applied.** `test/data/providers_test.dart` reads every provider against a
real in-memory database. `lib/data` is now **86.40%** — above the gate and
above Phase 02's figure — and the coverage is earned. The gate was not touched
and no `// coverage:ignore` was added.

The lesson generalises: *"this number is depressed for a structural reason"* is
a claim that needs its own evidence, because it is equally consistent with the
number being inflated somewhere else.

## P4 — `compare.dart` snaps to the nearest edge

**Medium**, recorded rather than changed, because the alternative is worse
without more design.

`_nearest(captureEdges, reference)` matches each reference block to whichever
detected edge is closest. When a layout is badly displaced, several reference
blocks match the **same** detected edge — in the failing run, three blocks all
matched 237.3 and three more all matched 378.0.

Those rows are not independent measurements, and reading them as six separate
defects overstates the damage. The real information was "the band is 11 pt
short and everything below inherits it", which took a manual edge dump to see.

**Not changed this phase**, for a stated reason: a matcher that refuses to
reuse an edge, or that matches in order, is a design decision affecting every
future screen's numbers, and making it while 13 blocks are red would be tuning
the instrument to the result. **Recorded here as a known property**, with the
suggestion that phase 04 — the next phase to add blocks — decides it on a
screen that passes.

## P5 — `docs/visual/shell/` is stale

**Low.** Phase 01 captured Home under the key `shell`. Phase 03 renamed it to
`home` (self-review #1, F4), so `docs/visual/shell/` now holds a Phase 01
capture of a screen that no longer exists under that name, plus the only
`side_by_side.png` and `README.md` in the tree.

**Applied.** The directory is removed; its `README.md` content — which
documents the capture harness's verification contract — moves to
`docs/visual/home/README.md`, where the live capture is.

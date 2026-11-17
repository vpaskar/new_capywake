# Phase 08 — self-review #2

Second pass, looking for what the first one did not. **4 findings: 1 High,
2 Medium, 1 Low. All applied.**

---

## High

### H1 — `compare.dart` compared a pill against a track, and the phase nearly "fixed" a layout that was right

The first comparison reported:

```
segment track bottom   236.3   240.7   +4.4  TIER A FAIL
card 1 top             251.6   243.7   -7.9  TIER A FAIL
```

Both numbers were wrong, and for the same reason. **The block table named the
`segment track`, but the values measured were the selected orange pill**
(249.4–280.3 in the mockup). The tool's `_hairlines` detector finds the
*track's* pale border — a different edge, 3 pt outside the pill — so it was
comparing the capture's track against the mockup's pill.

Measured directly from the capture, the rendered pill is **30.7 pt** against
the mockup's 30.9 — a **0.2 pt** difference, comfortably inside tolerance —
while the tool reported the block 4.4 pt out.

Re-measuring the mockup's **track** (246.1–281.2 at x=360) and putting those
values in the table gives:

```
segment track top      202.1   200.7   -1.4  within tolerance
segment track bottom   237.2   240.7   +3.5  within tolerance
```

**This is the Phase 05 rule for the fourth consecutive phase, and the third
time in this same tool.** Phase 04: a boundary the tool could not see,
reported as a layout failure. Phase 07: a block matched to a distant edge and
given a confident delta. **Phase 08: a block whose *name* and whose *value*
described two different edges, so the tool compared unlike things and was
right to report a difference.**

The important part is where the defect was: not in the tool, and not in the
widget. In **the phase's own block table** — a measurement error dressed as a
layout failure. Two more minutes of believing it and this phase would have
moved a pill that was already 0.2 pt from its mark.

**Applied.** The table measures the track at both edges, with the naming
hazard recorded in `tool/compare.dart` and in `docs/visual/tier_a_blocks.md`.
`card 1 top` was dropped: it is on the **Alarms** segment, and the capture
renders the **Sleep** segment, so the block never existed in the artifact
being measured — claiming it was a second instance of the same error.

---

## Medium

### M1 — `StatTile.caption` was dead surface, and the coverage gate was carrying it

`StatTile` took an optional `caption`, rendered it, and **no caller ever
passed one**. It was the slot for the mockup's "Best: 14 days" and "Avg."
captions, left behind when those became unclaimable with the empty default.

It was the single uncovered line in the feature (99.42%), which is how it
surfaced — the coverage figure was the evidence, not an inspection.

`CLAUDE.md` forbids TODO-only placeholders; an unused optional parameter that
exists for a future state is the same thing with a nicer name. The phase that
adds captions can add the parameter back, against a caller.

**Applied.** Removed. `lib/features/stats` is now **100.00% (171/171)**.

### M2 — The meadow fails, and it is not this screen's to fix

`meadow footer bottom` reports `absent`: expected 729.1, the painted grass
ends at **694.3**, 34.8 pt away — far outside the tool's ±12 pt search.

Checked across every captured screen before concluding anything:

| Screen | Grass ends | Nav bar |
|---|---|---|
| home | 694.3 | present |
| alarms | 694.3 | present |
| **stats** | **694.3** | present |
| settings | 793.0 | absent (pushed route) |

**Every tab ends at exactly 694.3 and the pushed route reaches 793.0.** The
nav bar occupies 98.7 pt where the mockup allots 79.9. Alarms' meadow was
already recorded by Phase 07 as failing **+10.0**, which is the same fact
seen from its own reference value.

`StatsScreen.meadowHeight` is correctly its own measurement (853 − 773.1 =
79.9); the footer simply sits above a nav bar taller than the mockup draws.

**Applied as a recorded finding, not a fix.** It is shell geometry shared by
three screens, Phase 07 recorded the Alarms half of it and deliberately did
not fix it, and changing `CapyNavBar` from inside the Stats phase would move
two screens this phase never measured. Carried in the post-review and
`next.md` with the numbers, and now identified as **one defect, not three**.

---

## Low

### L1 — The mockup paints 29.1 pt of grass; `MeadowFooter` paints 60.6

A second, independent meadow fact found while checking M2. The widget box is
the right height, but `_MeadowPainter` fills roughly twice the grass the
mockup draws (mockup: scalloped top 744.0–764.3 to a flat 773.1 bottom = 29.1
painted; capture: 633.7 → 694.3 = 60.6).

Not a Tier A block — no block measures painted extent — and shared by every
screen using `MeadowFooter`.

**Applied** as an entry in `docs/visual/asset_gaps.md`, where the other
cross-screen art observations live, rather than as a silent change to a
component three built screens depend on.

---

## Outcome

4 findings, all applied. **H1 is the one worth carrying forward**: the phase's
own block table named one edge and measured another, and the tool faithfully
reported the difference as a Tier A failure. The screen was right the whole
time.

Four consecutive phases have now been saved by the same discipline — *check
whether the tool, or what you told the tool, is wrong before believing it
about your code.* This time it was neither the tool nor the code. It was the
table in between.

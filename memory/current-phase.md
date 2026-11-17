# Current phase

**Phase 08 — Stats: done, 2026-11-17. `Current phase: 09`.**

**1,493 tests**, analyze clean including infos, lib 97.85% / `lib/core`
99.61% / `lib/data` 88.95% / **`lib/features/stats` 100.00%**, **437 ARB keys
× 10 locales** (+10).

## What this phase actually found

### 1. A gate that exists is not the same as a rule that holds

`tool/check_no_fake_stats.dart` — claimed by `CLAUDE.md` since Phase 00, found
absent by Phase 07 — is written, tested (16) and widened to all of
`lib/features/` (38 files, already clean).

**Three mutations, run separately. The third is the finding:**

| Mutation | Gate | Widget tests |
|---|---|---|
| Neuter the matcher | — | **4 of its own fail** |
| Plant `?? '7 h 32 m'` | **caught** | **2 fail** |
| Plant a numeric `?? 6` | **PASSED — blind** | **1 fails** |

The gate prints "No fabricated numbers in 7 files" while the screen renders a
fabricated `6` to every user with no data. **Writing the file Phase 07 found
missing would have left `CLAUDE.md` making a new false claim** — that the rule
is enforced. It is enforced against the easy shape and blind to the realistic
one, now stated beside the rule and asserted in the test.

### 2. The gate shipped with two defects of its own, caught by its own fixtures

Written **before** the screen, as the plan required:

- **It could not match a percentage.** `\b` after `%` can never hold — `%` and
  the closing quote are both non-word characters. One of the two figure shapes
  the mockup draws.
- **It flagged every localized call taking a number**, and
  `Text(context.pad1)`.

A gate written after the screen would have been "verified" by a screen that
happened not to contain a percentage.

### 3. The block table named the track and measured the pill

`compare.dart` printed **`segment track bottom +4.4 TIER A FAIL`**. The table
held **249.4 / 280.3** — the selected *pill*; the detector finds the *track's*
border, 3 pt outside it. Measured directly, the rendered pill is **30.7**
against the mockup's **30.9**.

**The tool was right, the widget was right, the table between them was wrong.**
Phase 05's rule for the fourth consecutive phase and the third time in this
same tool — but a new variant: not a boundary the tool could not see
(Phase 04), not a block matched to a distant edge (Phase 07), but a name and a
value describing two different edges.

Second instance in the same table: `card 1 top` claimed while the capture
renders the **Sleep** segment, which has no cards.

### 4. The three failing meadows are one fact

| Screen | Grass ends | Nav bar |
|---|---|---|
| home, alarms, stats | **694.3** | present |
| settings | 793.0 | absent — pushed route |

`CapyNavBar` takes **98.7 pt** where the mockup allots 79.9. Phase 07 recorded
Alarms' `+10.0` and Home's `absent` as separate screen-local defects owed by
their own phases. One nav bar pushes every tab's meadow up by the same amount.

### 5. The plan declared eight blocks its own default cannot render

Pre-review H4/M1 cut the claimed set **13 → 5**. The plan claimed all four
card bottoms while also specifying an empty default — and an empty card is
shorter than the mockup's filled one, so those positions are high **by
construction**. The eight keep their measured values in `tier_a_blocks.md` for
the phase that builds the filled state.

### 6. `sleepHistoryEmpty` tells the user to press a control that does not exist

*"No sleep to show yet. **Connect Health** to see your nights here."* — in 10
locales, with **no Connect control anywhere in the app**. Phase 07's
dead-control defect in new clothes, and `CLAUDE.md`'s overpromising rule. New
keys state the fact; the old one is kept unused for the gateway phase, and a
test asserts it is not rendered.

### 7. The green-collapse method does not work on every screen

Phases 04 and 07 located the hero edge by a per-row green count. Re-implemented
and **validated against both** (Settings 213.1 vs documented 212.9; Alarms
252.4 vs 252.5) — then it produced **nothing** on Stats: a monotonic decay
from 302 to 0, no knee. Stats' cream is a scalloped cloud, so the boundary is
not a line. *A method validated on two screens is validated for those two.*

## Tier A — four of five, and the failure is named

header **+0.1**, hero **−0.1**, track top **−1.4**, track bottom **+3.5**,
meadow **`absent` ❌**.

The meadow is finding 4 — shell geometry, not this screen. The +3.5 and −1.4
are declared rule conflicts: the 44 pt tap floor over a 30.9 pt pill, and a
title-spacing budget that is **negative by 1.35 pt** before any padding,
because the mockup's title sits inside a cloud lobe a flat-topped
`SceneHeader` cannot draw (`asset_gaps.md` G18).

## Predictions

Tests **+41** against a registered 70–100 ❌ — **restated**: a screen that
deliberately renders nothing has less to assert than Phase 07's four stateful
surfaces. Coverage is the better check and the feature is **100%**. ARB **+10**
against 10–18 ✅. `lib` **97.85%** against 97.3–97.9 ✅. `lib/core` **99.61%**,
unchanged as registered ✅.

## Next session — Phase 09, Onboarding

**Still owed:** the sleep-boundary restoration (health did not land in 07 or
08 — `sleep_boundary_test.dart` stays at `at most one`). **Not owed by any
phase:** the nav-bar/meadow fact, `MeadowFooter`'s 2× grass (G19),
`SceneHeader`'s flat top (G18), Alarms' 3 and Add/Edit's 8 Tier A failures.

# Phase 08 — post-review

Stats, the gate `CLAUDE.md` has claimed since Phase 00, and Stats' own hero
band. **Done.**

## Measured against what was registered

Registered in the plan, restated here where measurement disagreed — Phase 07's
precedent, rather than quietly passing.

| Quantity | Registered | Measured | |
|---|---|---|---|
| Tests | +70 … +100 | **+41** (1,452 → **1,493**) | ❌ **restated below** |
| ARB keys | +10 … +18 | **+10** (427 → **437**) × 10 locales | ✅ |
| `lib` coverage | 97.3 – 97.9% | **97.85%** | ✅ |
| `lib/core` | unchanged 99.61% | **99.61%** | ✅ |
| `lib/data` | unchanged / +0.3 | **88.95%** | ✅ |
| `lib/features/stats` | ≥ 95% | **100.00%** (171/171) | ✅ |
| Comment baseline | 113 files | **113** — zero new files baselined | ✅ |
| Stale `Phase N` in `lib/` | 1 → 0 | **0** | ✅ |

### The test count missed its range, and the estimate was wrong, not the work

**41 against a registered 70–100.** Breakdown: 17 screen widget tests, 8
provider tests, 16 gate tests.

The estimate was built from Phase 07's 80, but Phase 07 shipped five settings
groups, a reliability checklist, a walkthrough and a permission gate — four
surfaces with real state machines. **Stats' default state has almost no state
to test**: there is no chart, no filled layout, and the Sleep and Games
segments have exactly one reachable state each by design.

A screen that deliberately renders nothing has less to assert, and the
registration did not account for that. The coverage figure is the better
check, and it is **100%** of the feature.

## Tier A

```
header band lower edge        59.9     60.0      0.1
hero scene lower edge        171.4    171.3     -0.1
segment track top            202.1    200.7     -1.4   within tolerance
segment track bottom         237.2    240.7      3.5   within tolerance
meadow footer bottom         729.1       --   absent
```

**Four of five pass; one is `absent` and that counts as a failure.** Named,
not omitted.

- **The `absent` meadow is shared shell geometry.** Every tab's grass ends at
  **694.3**; the pushed Settings route reaches 793.0. `CapyNavBar` takes
  98.7 pt where the mockup allots 79.9. `meadowHeight` is correctly Stats' own
  **79.9**. Alarms' `+10.0` (Phase 07) is the same fact.
- **+3.5 and −1.4 are declared rule conflicts**, with the arithmetic in
  `docs/visual/stats/README.md`: the 44 pt tap floor over the mockup's 30.9 pt
  pill, and a title-spacing budget that is **negative by 1.35 pt** before any
  padding, because the mockup's title sits inside a cloud lobe a flat-topped
  `SceneHeader` cannot draw.

**Capture is fresh, and verified as such** (`PHASE_08_PRE_REVIEW.md` L1): the
committed `actual.png` was Phase 03's (`b3b0574`, 01:45, 1,197,140 bytes); the
one measured is 15:22, **974,443 bytes**. `compare.dart` reads whatever is on
disk without checking its age.

## The three things this phase owed

### 1. `tool/check_no_fake_stats.dart` — written, and its blind spots measured

Claimed by `CLAUDE.md` since Phase 00; found absent by Phase 07's
full-project review; the same defect Phase 02 found in `tool/audit_art.dart`.

**Written, tested (16), wired into both validation blocks, and widened to all
of `lib/features/` — 38 files, already clean.**

Three mutations, run separately because Phase 07 showed that one aggregate
"it failed" hides which rule did the work:

| Mutation | Gate | Widget tests |
|---|---|---|
| Neuter the matcher | — | **4 of its own fail** |
| Plant `?? '7 h 32 m'` in the screen | **caught** | **2 fail** |
| Plant a numeric `?? 6` fallback | **PASSED — blind** | **1 fails** |

**The third is the finding.** The gate prints "No fabricated numbers in 7
files" while the screen renders a fabricated `6` to every user with no data.
Only the widget test catches it. The blind spot was predicted in the
pre-review and is now asserted in `check_no_fake_stats_test.dart` and stated
in `CLAUDE.md` next to the rule — because a documented gate invites exactly
the belief Phase 07 warned about.

### 2. The sleep boundary — **not discharged, and said so explicitly**

**`package:health` and `live_sleep_gateway.dart` did not land in Phase 08.**
`pubspec.yaml` has no health dependency, `lib/data/providers.dart:80-85`
still records that `sleepGatewayProvider` does not exist, and nothing in
`lib/` imports a health plugin.

`test/core/sleep/sleep_boundary_test.dart` **stays at `at most one` importer**
with its conditional `NSHealthShareUsageDescription` / `READ_SLEEP`
assertions. `PHASE_02_SELF_REVIEW_1.md` F5 carries forward.

**Why not:** it means a platform permission flow, an iOS entitlement, an
Android manifest permission and a declarable store-policy category on both
stores — none of it this phase's subject, all of it needing its own
pre-review. Pulling it in to tick an owed item is the drive-by change this
process exists to prevent.

**What it cost the screen, and the defect that fell out:** the Sleep segment
renders its empty state permanently. The existing `sleepHistoryEmpty` says
*"Connect Health to see your nights here"* — **and no Connect control exists
anywhere in the app.** That is Phase 07's dead-control defect in new clothes
and `CLAUDE.md`'s overpromising rule. New keys state the fact instead;
`sleepHistoryEmpty` is kept unused for the phase that lands the gateway, and a
test asserts it is not rendered.

### 3. Stats' own hero band — measured, and the method that failed is recorded

**`heroBandHeight = 111.5`** (215.4 − 103.9), a **fifth** distinct value;
**`meadowHeight = 79.9`** (853 − 773.1), a **sixth**.

The green-collapse method Phase 04 and Phase 07 used **does not work on this
screen**. Re-implemented and validated against both — it reproduces Settings
at 213.1 (documented 212.9) and Alarms at 252.4 (documented 252.5) — then
produced **nothing** on Stats: a monotonic decay from 302 to 0 with no knee.
Stats' cream shape is a scalloped cloud, so the boundary is not a line.
Replaced by an arc asymptote cross-checked at both screen edges (214.3 /
216.6).

*A method validated on two screens is validated for those two screens.*

## Reviews

**15 findings across three passes, all applied, none invalid, none deferred.**

- **Pre-review** — 11 (4 H, 5 M, 2 L). Cut the claimed blocks from 13 to 5
  after finding the plan had declared eight it had already designed itself not
  to render; replaced the "no digit anywhere" assertion, which would have
  failed on the window label; changed the provider shape so a tile cannot be
  handed `HistorySummary.empty`'s zeros.
- **Self-review #1** — 6 (2 H, 3 M, 1 L). The gate shipped with two defects
  of its own, caught by its own fixtures: it **could not match a percentage**
  (a `\b` after `%` can never hold) and flagged every localized call taking a
  number. The pill rendered **33.7 against a constant of 30.9** until it was
  measured.
- **Self-review #2** — 4 (1 H, 2 M, 1 L). The block table named the *track*
  and measured the *pill*.
- **Full-project review** — 5 (2 H, 2 M, 1 L). The three failing meadows are
  **one** nav-bar fact; `MeadowFooter` paints twice the grass the mockups
  draw; `SceneHeader`'s flat top versus five cloud mockups.

## The rule this phase adds

Phase 03: a row-mean detector cannot tell text from a layout edge.
Phase 04: a method named beside a number is not enough if it ran against the
wrong artifact.
Phase 05: when a tool reports a failure, check whether the tool is wrong first.
Phase 06: a guard whose test cannot fail when the guard is removed is a guard
on trust.
Phase 07: a tool that cannot see a block will match it to one it can.

**Phase 08: a block's name and its value must describe the same edge.** The
tool was right, the widget was right, and the table between them was wrong —
`segment track bottom` held the pill's 280.3, and `compare.dart` faithfully
reported the 4.4 pt difference between two different edges. The pill was
**0.2 pt** from its mark.

And its corollary, from the gate: **a gate that exists is not the same as a
rule that holds.** Writing the file Phase 07 found missing would have left
`CLAUDE.md` making a new false claim. The only way to tell was to mutate it
and count.

## Known, recorded, not fixed here

- **Alarms fails 3 Tier A blocks, Add/Edit 8.** Phase 07's numbers, unchanged.
  Another phase's screens.
- **The nav bar is 98.7 pt against the mockup's 79.9**, pushing three meadows
  up. One fact, now recorded as one.
- **`MeadowFooter` paints ~2× the mockup's grass** — `asset_gaps.md` G19.
- **`SceneHeader` is flat-topped; five mockups draw clouds** — G18.
- **`AlarmEngine.ringNow` is still called by nothing in `lib/`.**
- **Android is untested. No emulator. Never mark it tested.**
- **No control was exercised by hand on a device.** The evidence is 1,493
  tests and a verified capture.

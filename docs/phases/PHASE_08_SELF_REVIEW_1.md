# Phase 08 — self-review #1

First pass over what this phase actually wrote. **6 findings: 2 High, 3
Medium, 1 Low. All applied.**

---

## High

### H1 — The gate shipped with two defects of its own, found by its own tests

The first `check_no_fake_stats.dart` failed two of its own fixtures:

1. **`'Avg. 94%'` was not caught.** `_figureInString` ended its unit
   alternation with `\b`. `%` is a non-word character and so is the closing
   quote, so **a word boundary can never exist between them** — the pattern
   could not match a percentage, which is one of the two figure shapes the
   mockup actually draws. `(?![a-z])` is the boundary that works.
2. **`Text(l10n.historyWindowLabel(14))` was flagged.** `_textLiteral` was
   `\bText\(\s*['"]?[^'")]*\d` — any digit anywhere after `Text(`. It
   flagged every localized call taking a number, and `Text(context.pad1)`.
   Narrowed to a bare number: `\bText\(\s*-?\d+(\.\d+)?\s*[,)]`.

Worth stating plainly: **a gate written to catch fabricated numbers could not
see a percentage, and would have cried wolf on the one legitimate digit this
screen renders.** Both were found because the fixtures were written before
the screen, as the plan required, rather than after it was already green.

**Applied.** Both regexes corrected, both fixtures now assert the behaviour.

### H2 — The mutation protocol found that the gate is blind to the shape that would ship

Three mutations, run separately as `PHASE_08_PRE_REVIEW.md` H3 required:

| Mutation | Gate | Widget tests |
|---|---|---|
| 1. Neuter the matcher | — | **4 of its own tests fail** |
| 2. Plant `?? '7 h 32 m'` in the real screen | **caught** | **2 fail** |
| 3. Plant a numeric `?? 6` fallback | **PASSED — blind** | **1 fails** |

**Mutation 3 is the finding.** The gate reports "No fabricated numbers in 7
files" while the screen renders a fabricated `6` to every user with no data.
Only the widget test catches it.

This is not a gate defect — the blind spot is declared in the pre-review and
asserted in `check_no_fake_stats_test.dart`. It is evidence that **the second
mechanism was necessary**, measured rather than assumed. A phase that had
written only the script would have shipped believing itself protected.

**Applied** as recorded evidence; all three numbers go in the post-review.

---

## Medium

### M1 — The first Sleep segment contained a branch that could not be true

`SleepSegment` was written twice before it was right, and both earlier
versions were dishonest:

- v1 took `hasData` and, when true, rendered two `StatTile`s whose values
  were **hardcoded null** — permanently em dashes, pretending to be a data
  surface.
- v2 took `hasData` and, when true, rendered `sleepHistoryEmpty` — the string
  that says *"Connect Health"*, i.e. the exact defect H1 of the pre-review
  exists to prevent, reachable through a branch that also contradicted itself
  ("has data" → "no sleep to show").

**Applied.** The segment takes no flag and has one state, because there is
one reachable state. `statsHasSleepDataProvider` was deleted with it: a
provider with one reachable value is a branch no test can cover, and the
coverage gate would have been carrying dead code.

### M2 — A `Row` with `crossAxisAlignment: stretch` inside a `ListView` threw

The two side-by-side cards crashed with *"BoxConstraints forces an infinite
height"* on first run. Unbounded height from the list, stretched by the row.
`IntrinsicHeight` is the fix, and it is what makes the two cards match
heights — which is what the mockup draws.

Caught by the widget tests on their first execution, not by analyze.

### M3 — The pill rendered 33.7 pt against a constant of 30.9

`StatsSegmentSwitcher` gave its selected pill `height: trackHeight` through a
`Container` with an `alignment`, and the measured render was **33.7** — the
text's line box plus padding won over the height.

`CLAUDE.md`'s rule applies verbatim: *measure what it renders
(`tester.getRect`) before trusting the constant you gave it.* Rebuilt as
`SizedBox(height:) > DecoratedBox > Center`, which renders **30.7** against
the mockup's 30.9.

**Applied, with a test that asserts the rendered height**, so the constant
cannot drift from the render again.

---

## Low

### L1 — `historyAverageSnoozeValue` is given a rounded double

`AlarmsSegment` passes `summary.averageSnoozeCount.round()` to an ARB plural.
Rounding 1.4 → 1 renders "About 1", which is defensible for a calm summary,
but it is a transformation of measured data and was not stated anywhere.

**Applied.** The tile is a count-shaped plural and the ARB's own `=0{None}`
case handles the zero; the rounding is what the key was written for
(`"About {count}"`), so the behaviour stands and is now recorded here rather
than being invisible.

---

## Outcome

6 findings, all applied. The two that matter:

**H1** — the gate could not see a percentage. Written after the screen, it
would have been "verified" by a screen that happened not to contain one.

**H2** — the gate is measurably blind to a numeric fallback, and only the
widget test catches it. The pre-review predicted this; the mutation proved it.

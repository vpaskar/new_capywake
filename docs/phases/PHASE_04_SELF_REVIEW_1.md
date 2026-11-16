# Phase 04 — self-review #1

Against the implemented code, after the first green validation run.

---

## F1 — `AlarmListTile` resolved a directional radius against hardcoded LTR

**High.** `alarm_list_tile.dart` clipped the art panel with

```dart
const BorderRadiusDirectional.horizontal(start: Radius.circular(lg))
    .resolve(TextDirection.ltr)
```

`BorderRadiusDirectional` exists to be resolved against the **ambient**
direction. Resolving it against a literal `ltr` is worse than using
`BorderRadius` directly, because it reads as RTL-aware and is not: in Arabic
the rounded corners would sit on the trailing edge and the art would be
clipped square against the leading one.

Found by grepping the new files for `TextDirection`, not by reading them —
the Arabic test passed because it only asserted no exception was thrown.

**Applied.** Resolved against `Directionality.of(context)`, and
`alarm_list_tile_test.dart` gained a test that pumps in `ar` and asserts the
radius lands on `topRight`. That test fails against the old code.

---

## F2 — Every screen has its own hero band height, and three widgets assumed Home's

**High.** `SceneHeader.bandHeight` defaults to **188.4 pt**, measured from
`01_HOME.png`. Both Phase 04 screens took the default. Measured:

| Screen | Band | Source |
|---|---|---|
| Home | 188.4 | 292.3 − 103.9 |
| Alarms | **148.6** | 252.5 − 103.9 |
| Add/Edit | **112.1** | 216.0 − 103.9 |

The first Alarms capture read **hero lower edge +39.8 pt**, and every block
below inherited it. The same class of error as Phase 03's `SceneHeader` bug —
a constant that is right for one screen taken as right for all — found the
same way, by capturing and measuring rather than by reading the code.

**Applied.** Both screens pass their own measurement. Alarms is now **−0.2**,
Add/Edit **0.0**.

The same was true of `MeadowFooter.height` (65.2, Home's): Alarms measures
52.2 and Add/Edit 59.1. The widget now takes a `height`, keeping Home's as the
default, and the too-tall band was why the fourth alarm card fell off the fold.

---

## F3 — `BoxFit.contain` let the thumbnail drive the row height

**High.** `AlarmListTile` wrapped its art in `IntrinsicHeight` with no height
bound, so a squarer cell stretched the row. Measured on the capture: rows with
`moments_01` (288×190) came out **88.6 pt**, rows with `collection_02`
(230×242) came out **129.4 pt** — a 40 pt difference between two rows that
Tier A says are the same height.

It looked like "disabled rows render taller", because the two disabled rows
happened to be the two squarer cells. **The visible correlation was with the
wrong variable** — opacity does not affect layout; aspect ratio does.

**Applied.** The art sits in a box bounded to the row height. All four cards
now land within 5.6 pt and the pitch is 102.3 against the mockup's 102.1.

---

## M1 — The chip row painted 44 pt against the mockup's 31.8

**Medium.** `WeekdayChipRow` grew the *paint* to reach the tap target instead
of growing only the hit area, a 12.2 pt Tier A error. Caught by a test that
measures what renders (`tester.getRect`) rather than trusting the constant —
the rule Phase 03 added to `CLAUDE.md` after its next-alarm card was built at
167 pt against a measured 65.

**Applied.** Paint stays at 31.8 (within 4 pt once the label's line box is set
to `height: 1`); the `InkWell` carries 44. Both are asserted.

---

## M2 — `IconButton` gave the stepper chevrons 48 pt against a 19.4 pt mockup

**Medium.** Material's `IconButton` has a 48 pt minimum, so the time card came
out **184.7 pt** against the mockup's 112.7 — the single largest block error
on the form.

This is a real conflict, not a mistake: 19.4 pt is well under the 44 pt a
half-asleep user needs, and `CLAUDE.md` makes large, reachable alarm controls
a safety rule.

**Applied**, the way `CapyToggle` already resolves it: the glyph keeps the
mockup's 19.4 pt, and the tap region is 44 via `OverflowBox`, overlapping the
well. Tier A and reachability both hold, and the time card is now within
measurement of the mockup.

---

## M3 — The screen title inflated the row the Add pill defines

**Medium.** `02_ALARMS.png` sets the title row by its pill (36.9 pt). The
30 pt title's default line box is taller, so the row grew and pushed the first
card **+7.3 pt**. Also `maxLines: 1` + `TextOverflow.ellipsis` on a real label
— the pattern the accessibility rules ban, since it hides an overflow bug
instead of showing it.

**Applied.** `height: 1` on the title, ellipsis removed. Card 1 top is now
**−0.0 pt**.

---

## L1 — The Add pill lost its 44 pt tap target while being given its paint height

**Low.** Fixing the pill's painted height to the measured 36.9 replaced the
`CapyToggle.minTapTarget` constraint instead of nesting inside it, so the
button was 36.9 pt tall — under the minimum, on the screen's primary action.

**Applied.** 44 pt hit area, 36.9 pt paint, same split as the toggle and the
chips.

---

## L2 — Two unused imports and a stale `height` constant

**Low.** `go_router` imported in two test files that no longer call it, and
`_AddPill.height` declared but never used — an unused measured constant is a
value that will drift from the mockup unnoticed.

**Applied.** Imports removed; the constant renamed `paintedHeight` and applied
to the widget.

---

## Rule compliance

- `main` only, no branch, no worktree, **no stash** (Phase 03's F5).
- `../capywake` untouched.
- No numeric literal in a user-facing position in `lib/features/alarms/`
  (grep clean).
- No hardcoded user-facing string (grep clean).
- No `withClampedTextScaling`, `textScaleFactor` or `FittedBox` anywhere in
  `lib/` (grep clean) — one `FittedBox` was written and removed during
  implementation.

## Summary

| ID | Severity | Outcome |
|---|---|---|
| F1 | High | Applied + regression test |
| F2 | High | Applied — per-screen band and meadow heights |
| F3 | High | Applied — bounded art box |
| M1 | Medium | Applied — paint/tap split |
| M2 | Medium | Applied — 19.4 pt glyph in a 44 pt region |
| M3 | Medium | Applied — title no longer inflates the row |
| L1 | Low | Applied |
| L2 | Low | Applied |

3 High, 3 Medium, 2 Low. All applied, none deferred, none invalid.

**Every High was found by capturing a screen and measuring it, or by grepping
for a pattern — none by re-reading the code.** The widget tests were green
throughout: they assert behaviour, and all three Highs were geometry.

# Phase 03 — self-review #2

Second pass, deliberately aimed at what #1 did not look at: accessibility,
localization, RTL, and whether the new tests assert anything a regression
would actually trip.

## Summary

| # | Severity | One line | Outcome |
|---|---|---|---|
| G1 | **High** | The toggle's tap target was 34.6 pt, under the 44 pt minimum | Applied |
| G2 | Medium | The comment-budget gate fired on its own author's files | Applied |
| G3 | Medium | Nothing asserted Home's semantic tree | Applied |
| G4 | Low | RTL and 10-locale safety were assumed, not checked | Verified |

4 findings: 1 High, 2 Medium, 1 Low. All applied or verified. None invalid.

---

## G1 — the alarm toggle was too small to hit

**High.** `CapyToggle` painted and hit-tested at the mockup's measured
**59.6 × 34.6 pt**. `CLAUDE.md`: *"Core alarm controls are large and reachable
— a half-asleep user, no precision tapping."* The platform minimum is 44 pt,
and `flutter:accessibility-as-code` names it for every tap target.

34.6 is 79% of the minimum, on the one control on Home that turns an alarm off.
A user reaching for it at 06:45 is the exact person the rule is written for.

**The tension is real**, which is why it is worth recording rather than just
fixing: Tier A binds the *painted* geometry to ±4 pt, and 44 is 9.4 pt taller
than the mockup draws. Both constraints cannot be met by one box.

**Applied** by separating them: the painted track stays **34.6 pt** (Tier A
intact), wrapped in a 44 pt-tall `SizedBox` with `HitTestBehavior.opaque`, so
only the hit area grows. The test now asserts **both** — the `DecoratedBox`
measures 59.6 × 34.6, and the widget's own height is ≥ 44.

First attempt used `BoxConstraints(minWidth:, minHeight:)`, which expanded to
fill the parent and measured **800 pt** wide. Caught by the existing size
assertion, which is what that assertion is for.

## G2 — the comment gate caught its own author

**Medium**, and worth recording because it is the gate behaving correctly on
the session that wrote it.

The full suite failed with **416 excess chars in
`test/data/providers_test.dart`** — the file written an hour earlier to fix
F1, carrying a five-line explanation of why five providers were uncovered and
a five-line note on why `.read(p.future)` hangs. Then, after the G1 fix, it
failed again on **68 excess chars in `lib/design/capy_toggle.dart`**.

Both are exactly the prose this phase's own rule says belongs in `docs/`. Both
were tightened to two lines, with the full reasoning kept here and in
`PHASE_03_SELF_REVIEW_1.md`.

**Applied.** Nothing was added to the baseline to silence it, which is the
failure mode the gate exists to prevent.

## G3 — nothing asserted Home's semantics

**Medium.** `home_screen_test.dart` asserted text, routing, repository writes,
three viewport widths and the absence of literals — and never once read the
semantic tree. The toggle's `Semantics(toggled:)` is the redundant channel that
palette constraint F1 **depends on**; if it regressed, the F1 argument would
become false and every test would still pass.

**Applied.** `home_components_test.dart` asserts `matchesSemantics(label:,
hasToggledState:, isToggled:)` in both states, and the rail test asserts an
unavailable tile announces its badge. The toggle's state is now checked in
three independent channels — colour, knob position, semantics — which is what
F1 claims and what nothing verified.

## G4 — RTL and the ten locales were assumed

**Low**, and it checked out, but the point is that it was *assumed*.

`CLAUDE.md`: *"Arabic is RTL — direction-aware widgets only
(`EdgeInsetsDirectional`, `start`/`end`), never hardcoded `left`/`right`."*

Measured, across every file this phase added:

```
grep -rn 'EdgeInsets\.only|Alignment\.centerLeft|Alignment\.centerRight|\bleft:|\bright:' \
  lib/features/home/ lib/design/capy_{card,toggle}.dart \
  lib/design/{section_header,meadow_footer}.dart | grep -v EdgeInsetsDirectional
→ (empty)
```

Every inset is `EdgeInsetsDirectional`; the toggle knob and the Soon badge both
use `PositionedDirectional` with `start`/`end`. The meadow is symmetrical.

Translations spot-checked in the three non-Latin scripts rather than trusting
the key count:

| | `homeGamesHeading` | `homeMyStats` | `gameStepQuest` |
|---|---|---|---|
| `ar` | ألعاب الاستيقاظ | إحصاءاتي | Step Quest |
| `ja` | 目覚ましゲーム | マイ統計 | Step Quest |
| `ru` | Игры для пробуждения | Моя статистика | Step Quest |

Product names stay Latin in all ten, which is what the stores and the mockup
show. The rail test renders the four names in `en`, `de` and `ru` and asserts
none is ellipsised — `CLAUDE.md` forbids `TextOverflow.ellipsis` as a fitting
device, and clipping a product name is a content defect.

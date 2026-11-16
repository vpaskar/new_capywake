# Phase 06 — self-review #1

Against the implementation, after the validation block passed: **1,352 tests**,
analyze clean including infos, `lib` 96.95% / `lib/core` 99.49% / `lib/data`
88.95% / `lib/features/ringing` 90.85%, 405 ARB keys × 10 locales.

Every finding is applied or marked invalid with a one-line reason.

---

## High

### F1 — `confirmAndHold` is the stricter escape and **no test exercises it**

`escape_sheet.dart:64-66` is uncovered. That is the
`PuzzleEscapeStrictness.confirmAndHold` arm — the branch a user picks when
they want the puzzle to be the path of least resistance.

Everything about this phase's safety claim rests on the escape working at
*both* strictness settings, and the harder one is the untested one. The screen
tests all run the default, `confirm`, because `PuzzleSettings.defaults()`
chooses it; nothing constructs an alarm whose override sets `confirmAndHold`.

The pre-review's test table listed "`confirm` → one confirmation;
`confirmAndHold` → confirmation + hold" and implementation wrote only the
first half.

**Applied.** A test builds an alarm with a `confirmAndHold` override, opens the
sheet, asserts a tap does **not** escape and a completed hold does.

### F2 — the escape-visibility promotion is wired but never proven end to end

`ringing_host.dart:107-112` — `_onRoundChanged` — is uncovered. This is the
path that reads `escapeVisibilityFor` after each wrong answer and raises the
escape to prominent.

The controller has a unit test for `raiseEscapeVisibility`, and the screen has
a test that prominent renders a filled button. **Nothing connects them.** The
promotion could be disconnected — a wrong comparison, a missing `ref.read` —
and the whole suite would stay green while a struggling user never sees the
escape get easier to find, which is the exact behaviour `PuzzleSettings`
documents as a safety affordance.

**Applied.** A host test answers wrong past `toleratedWrongAnswers` on a real
puzzle round and asserts the escape becomes prominent on the live surface.

---

## Medium

### F3 — the all-unrenderable fallback is asserted *about*, not *exercised*

`ringing_host.dart:101-102` is uncovered. The existing test
("a visual-only override leaves nothing drawable…") asserts that the
*intersection* is empty — it re-computes the condition in the test and checks
arithmetic. It never builds a widget, so `_renderableSettings`'s fallback
branch never runs.

That is a test of the fixture, not of the code. If the fallback returned an
empty set — which `PuzzleSettings` would throw on — the test would still pass
and a user with only visual puzzles enabled would get a crash instead of an
alarm they can stop.

**Applied.** Replaced with a widget test that rings a puzzle alarm whose
enabled types are all unrenderable and asserts a drawable puzzle appears.

### F4 — `RingingSession`'s equality and `copyWith` are dead weight at 20 uncovered lines

`ringing_session.dart:41-68` — the whole of `copyWith`, `==`, `hashCode` and
`toString` — is uncovered, which is 20 of the feature's 41 uncovered lines.

Two possibilities and they need different fixes: either the value semantics
matter (the session crosses a stream, and a `distinct()` or a rebuild check
would rely on `==`) and they must be tested, or nothing uses them and they are
code written on reflex.

Checked: `copyWith` **is** used, by `raiseEscapeVisibility`. `==`/`hashCode`
are not used by anything in `lib/`.

**Applied.** Tested rather than deleted: the session is emitted on a broadcast
stream that the UI watches, and a value type on a stream whose equality is
wrong is a bug waiting for the first `distinct()` anyone adds. Small, honest
tests over inventing a use.

### F5 — multi-task rounds are never rendered

`puzzle_view.dart:66-71` — the `showsProgress` branch, which draws "1 of 3" —
is uncovered. `PuzzleSettings.taskCount` goes to 5 and the progress line only
appears when `taskCount > 1`; every test uses the default of 1.

A user who configured three puzzles would be the first to see that code run.

**Applied.** A test renders a 3-task round and asserts the progress line.

### F6 — `_instruction`'s wildcard arm silently mislabels seven puzzle types

```dart
_ => l10n.puzzleInstructionArithmetic,
```

`RingingHost.renderableTypes` keeps the other seven out, so this is currently
unreachable — but it is unreachable by a *convention held in another file*,
and it fails in the worst direction: a `gridPatternRecall` puzzle would be
captioned "What is the result?" over a grid of squares.

A wildcard that cannot be right for any value it catches is worse than no
wildcard.

**Applied.** Replaced with explicit arms for the three renderable types and a
`throw` on the rest, so an unrenderable type reaching the view is a loud
failure in a test rather than a wrong caption at 03:00. The exhaustive switch
also means adding a renderer forces the instruction to be chosen.

---

## Low

### F7 — `ringing_screen.dart:184` is an unreachable null-period branch

The `parts.period == null` arm of the clock's semantics value. Reached only in
a 24-hour locale; every test runs `en`.

**Applied.** A test pumps the screen in `de` (24-hour) and asserts the clock
announces without a period.

### F8 — `puzzle_view.dart:124,141` are the unused `empty`/`unparseable` feedback paths

The view only renders feedback for `incorrect`. `PuzzleAnswerOutcome` also has
`empty` and `unparseable`, and `puzzleFeedbackEmpty` / `puzzleFeedbackUnparseable`
exist in ARB — a user who presses Check with an empty field currently gets
silence.

**Applied.** Both outcomes now render their existing ARB string, and a test
covers the empty case. No new keys.

### F9 — the `_operatorWord` divide arm is uncovered

Generated puzzles at the tested difficulty did not produce a division option.
The arm is correct by inspection but unproven.

**Applied.** Covered by a direct unit test over all four operators rather than
hoping a seed produces one.

---

## Summary

| Severity | Count | Applied | Invalid |
|---|---|---|---|
| High | 2 | 2 | 0 |
| Medium | 4 | 4 | 0 |
| Low | 3 | 3 | 0 |
| **Total** | **9** | **9** | **0** |

The two Highs are the same shape and the shape worth naming: **both halves of
a safety mechanism were tested and the wire between them was not.** The escape
exists, the promotion rule exists, the renderer exists — and the paths that
join them were the uncovered lines.

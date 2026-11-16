# Phase 06 — self-review #2

After self-review #1's 9 findings were applied: **1,360 tests**, analyze clean,
`lib` 97.26% / `lib/core` 99.49% / `lib/data` 88.95% /
`lib/features/ringing` 94.67%.

Self-review #1 read the diff for coverage gaps. This pass reads it for
**claims** — things the phase asserts that nothing checks, and places where
two layers agree in prose but not in code.

---

## High

### G1 — the dismiss-exactly-once guard is tested only where it is *not* under contention

The controller tests call `Future.wait([dismiss(), dismiss()])`. Both calls
enter `_terminate`, the first claims the latch, the second finds the id
present and returns. That proves the latch.

**It does not prove the thing the latch exists for.** The real race is a
second call arriving *while the first is awaiting* `_engine.cancel` or
`_repository.upsertOccurrence` — and with the in-memory fake engine and an
in-memory database, both of those complete in the same microtask turn, so the
window the guard defends is never actually open during the test.

The guard is correct by construction. But a future change that moved the
`_claim` below the first `await` would keep every test green, which makes this
a test that cannot fail for the reason it was written.

**Applied.** A test injects a slow engine whose `cancel` completes only when
the test releases it, so the second call provably arrives mid-flight. That is
the window, held open deliberately.

### G2 — "no animation on the ringing surface" is asserted on a surface with no puzzle

`ringing_screen_test.dart` asserts `transientCallbackCount == 0`, and
`puzzle_view_test.dart` asserts it for the puzzle in isolation. **Neither
asserts it for the composed surface** — screen plus puzzle, which is what a
puzzle-backed user actually sees, and the only configuration where a reveal
would be introduced.

The rule's whole risk surface is the puzzle types that show-then-hide. Testing
the two halves separately leaves the composition untested, which is exactly
the shape of defect self-review #1 found twice.

**Applied.** The host test asserts no running animation with the puzzle on
screen, and again after a wrong answer regenerates the puzzle.

---

## Medium

### G3 — `_withRoundVisibility` can raise the escape without the controller ever learning

`ringing_host.dart:135` is uncovered: the `copyWith` that returns a session
with the escape promoted from the *round*.

That path raises the visibility **for this frame only**. `_onRoundChanged`
separately calls `raiseEscapeVisibility`, which is what makes it stick across
a snooze. The two happen to agree today because both read the same predicate —
but if a future change made the round's own `escapeVisibility` fire on a
condition `_onRoundChanged` does not check, the escape would be prominent on
screen and demoted on the next ring, with nothing failing.

**Applied.** Documented as a deliberate two-path design (frame-local vs
persistent) and tested: a test asserts that a frame-local promotion is also
recorded on the controller, so the two cannot drift apart silently.

### G4 — the `UnsupportedError` arm added by F6 is unreachable *and* untested

`puzzle_view.dart:150-157`. Self-review #1 replaced a silently-wrong wildcard
with a loud throw. That is better, but the arm now shows as 8 uncovered lines
and nothing proves the throw actually fires — if the switch were wrong the
caption could still be silently incorrect.

**Applied.** A direct test constructs a round of an unrenderable type and
asserts the view throws rather than drawing a wrong instruction. The throw is
the contract between `PuzzleView` and `RingingHost.renderableTypes`, so it is
worth one test.

### G5 — the snooze note is written by the controller and read by nobody in this phase

`_withSnoozeNote` stores `'snoozed:N'` on the occurrence. Phase 08 (Stats)
will read it. Right now the format is asserted by exactly one controller test
and is otherwise a string literal in a feature file.

If Stats later parses a different shape, nothing here fails.

**Applied.** The expectation is now stated where it belongs — the test asserts
the stored shape explicitly and names Stats as the consumer — so the contract
is discoverable by the phase that will depend on it rather than inferred from
a literal.

### G6 — nothing asserts the ringing surface actually blocks the app beneath it

The host stacks `RingingScreen` over `widget.child` and the comment says a
stray tap must not reach what is underneath. The `Scaffold` is opaque, so it
does — but that is a property of the widget tree, not an assertion.

A ringing alarm that let a tap through to the Alarms list could have a user
deleting an alarm while trying to silence it.

**Applied — and the first attempt was the wrong test.** A `tester.tap` on the
nav icon "proved" the tap *did* get through: the ringing screen covers the
whole viewport, so the coordinate under the nav icon is inside the ringing
surface and the tap hit its Stop button instead. The code was right and the
test was measuring something else — the Phase 05 rule, one layer down.

Replaced with a hit-test assertion: hit-testing at the nav icon's centre must
not reach the nav bar's render subtree. That asserts the blocking directly
rather than inferring it from a side effect.

---

## Low

### G7 — `RingingSession.==` is tested, `toString` is not

13 lines still uncovered in `ringing_session.dart`, mostly `==`/`hashCode`
(now tested) and `toString`.

`toString` on a value type is a debugging affordance; untested, it can throw
on a null field and take down a bug report.

**Applied.** One test, since the other three members already have one.

### G8 — the 24-hour clock test asserts the locale, not the absence of a period

F7's test pumps `de` and asserts the clock renders. It does not assert that
**no** period marker is shown, which is the actual difference.

**Applied.** Tightened to assert the period is absent and the semantics value
is the bare time.

### G9 — `_operatorGlyph` uses U+2212 MINUS SIGN, and nothing says why

`'−'` is not the ASCII hyphen. It is correct typography and it matches the
board, but it is the kind of character a later edit silently "fixes" to `-`.

**Applied.** Covered by the operator test, which now asserts the exact glyph,
so a substitution fails rather than passing unnoticed.

---

## Summary

| Severity | Count | Applied | Invalid |
|---|---|---|---|
| High | 2 | 2 | 0 |
| Medium | 4 | 4 | 0 |
| Low | 3 | 3 | 0 |
| **Total** | **9** | **9** | **0** |

**G1 is the finding worth carrying forward.** The phase's headline property —
dismiss exactly once — had a test that passed for the wrong reason: with
in-memory fakes, the async window the guard defends never opens. A guard whose
test cannot fail when the guard is removed is a guard on trust.

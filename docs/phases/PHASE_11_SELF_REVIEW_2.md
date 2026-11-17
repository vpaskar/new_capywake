# Phase 11 — self-review #2

A second adversarial pass, from a different angle than #1: not "is a value
unbounded" but "can a later phase use this contract to do the wrong thing, and
would a test catch it". Run after #1's fixes validated green.

**2 findings: 1 Medium, 1 Low. Both applied. Plus one mutation check recorded.**

---

## The mutation check (Phase 06's rule, run before the findings)

Phase 06: a guard whose test cannot fail when the guard is removed is a guard on
trust. The `game_ringing_view_test` "dismisses the alarm when its goal is
reached" test was mutation-checked: the conformer's
`if (_challenge.isComplete) widget.onCompleted();` was replaced with a no-op and
the suite re-run. The dismiss test **failed** (`+3 -1`), proving it genuinely
verifies completion → dismiss, not merely that the widget mounts. Restored.

## Medium

### M1 — The escape policy source is implicit; a Phase 12 game could invent its own tolerance

`GameChallenge.escapeVisibilityFor` takes a raw `toleratedStruggles` int. Nothing
in the contract ties it to the user's one setting, `PuzzleSettings
.toleratedWrongAnswers`. A Phase 12 game could pass a hard-coded tolerance, or a
per-game one, and the escape would then fire on a schedule the user never chose —
the exact divergence pre-review H1 guarded against (the escape **policy** stays
the user's; only what a game **measures** is the game's).

The `core` layer cannot read settings (no Riverpod, the headless rule), so the
contract correctly takes the tolerance as a parameter. What was missing was a
guard that the game's mapping **equals the puzzle's** for the same inputs — so
"games and puzzles offer the escape the same way" is pinned, not assumed.

**Applied.** A test sweeps `struggleCount` 0–6 and asserts
`GameChallenge.escapeVisibilityFor(toleratedStruggles: settings
.toleratedWrongAnswers)` equals `PuzzleSettings.escapeVisibilityFor` over the
matching `PuzzleEasingState`. They agree at every count. A Phase 12 game that
reads anything other than `toleratedWrongAnswers`, or maps it differently, breaks
this test. The *source* (passing `settings.toleratedWrongAnswers` in) is Phase
12's wiring job — recorded in the post-review as the one thing a game must get
right, with the test standing guard.

## Low

### L1 — `motionFallback` nests, but only one level is meaningful

A motion game's `fallback` is a full `GameChallenge`, which itself has a
`motionFallback` field (always null now, since #1's assert forbids a motion
fallback). So `motion.motionFallback!.motionFallback` is always null — a dangling
degree of freedom that reads as if fallbacks could chain.

**Applied.** No code change — the assert from #1 (`!fallback.requiresMotion`)
already forces the fallback to be a `.touch`, whose `motionFallback` is null by
construction. The nesting is structurally one level deep and cannot be otherwise.
Recorded so a reader does not mistake the type for a recursive chain. (Collapsing
the type to a non-`GameChallenge` fallback would lose the shared `target`/
`completed`/`isComplete` surface the fallback also needs — the reuse is the
point.)

---

## Outcome

2 findings, both applied; one mutation check recorded. None invalid.

**M1** is the one that matters for the next six phases: the foundation now proves
that a game and a puzzle offer the escape identically against the user's single
tolerance setting. The contract cannot read that setting (it is headless), so the
guard is the equivalence test plus the post-review's instruction that Phase 12
passes `toleratedWrongAnswers` in — the escape policy stays the user's, which is
pre-review H1 closed on both ends.

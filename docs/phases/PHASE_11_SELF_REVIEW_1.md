# Phase 11 — self-review #1

Adversarial pass over this phase's own code after it validated green (1,568
tests, analyze clean incl. infos, every coverage gate met, 446 ARB keys).

**3 findings: 1 High, 1 Medium, 1 Low. All applied.**

---

## High

### H1 — A motion game's fallback could itself require motion, defeating the a11y guarantee

`GameChallenge.motion` required *a* `fallback`, but nothing required the fallback
to be playable without motion:

```dart
GameChallenge.motion(
  target: 5, completed: 0,
  fallback: GameChallenge.motion(target: 3, completed: 0, fallback: touch),
)  // compiled fine — a "fallback" that also needs motion
```

The whole point of the required fallback (pre-review H4) is the safety rule:
**a motion game must offer a non-motion way to play.** A fallback that itself
needs motion is no fallback at all, and this compiled. This is the Phase 10 SR1
shape one layer down — a constructor accepting a state it must not represent.

**Applied.** `GameChallenge.motion` now asserts `!fallback.requiresMotion`. A
test constructs a motion game with a motion fallback and asserts it throws.
Because the assert reads a field on the parameter, it cannot run in a `const`
context, so `.motion` is **no longer `const`** — stated in its doc and harmless
(a game rebuilds its challenge each frame via `setState`, never as a `const`).
`.touch` stays `const`.

## Medium

### M1 — No goal bounds: `target: 0` dismisses the alarm with zero play

`isComplete` is `completed >= target`. A `GameChallenge.touch(target: 0,
completed: 0)` is **immediately complete** — the alarm would stop before the user
did anything. Negative `completed` or `struggleCount` are likewise nonsensical
and would pass. The foundation is where the ten games inherit their invariants;
leaving the goal unbounded hands every game a footgun.

**Applied.** Both constructors assert `target > 0`, `completed >= 0`,
`struggleCount >= 0`. Tests cover each. A game can still *start* at `completed:
0` (not complete, since `0 >= 1` is false) — only a zero/negative target is
rejected.

## Low

### L1 — The escape-reachability test passes because `RingingScreen` owns the escape, not because of anything game-specific — and that is correct

The `game_ringing_view_test` "keeps the escape reachable" test passes because
`RingingScreen` draws the escape whenever `puzzleSlot != null`, and a game is a
non-null slot. A reader might think the test is vacuous. It is not: it is the
pre-review H2 guarantee made observable — a game **has no seam** to hide the
escape, so the test documents that the escape survives arbitrary game state. A
mutation that made `RingingScreen` draw the escape only for puzzle rounds (not
games) would fail it.

**Applied.** No code change — the structure is the feature (pre-review H2). The
test is kept and its intent recorded here so a later reader does not "simplify"
it away as trivial.

---

## Outcome

3 findings, all applied, none invalid.

The one that matters is **H1**: the a11y fallback guarantee had a hole — a
"fallback" that also needed motion compiled. The foundation is the one place to
close it, since Phase 15's two motion games (Shake DJ, Tilt Maze) inherit this
contract. Now a motion game without a *usable* non-motion path cannot be built.

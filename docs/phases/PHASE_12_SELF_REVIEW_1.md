# Phase 12 — Self-review #1

Read against the implementation diff, not the plan. **5 findings: 1 High,
2 Medium, 2 Low. 4 applied, 1 invalid with a reason.**

## H1 — The games drew straight onto the scrimmed hero art

`RingingScreen` overlaps `puzzleSlot` on the hero image under `artScrim`.
`PuzzleView` wraps itself in a `CapyCard`; both game views returned a bare
`Column`, so their cocoa header text would sit on dark, busy art — unreadable on
the one surface where reading matters most. Every view test passed, because a
bare `Scaffold` has a cream background.

**Applied:** both views wrap in `CapyCard` (also right for practice). Pinned by a
host test that finds the instruction under a `CapyCard` inside the real ringing
surface.

## M1 — "Try it" inherited the failing accent

`TextButton` takes `colorScheme.primary`, which is `CapyColors.accent` — the
orange recorded since Phase 02 as failing contrast on light surfaces. Body-size
text in it is well under 4.5:1.

**Applied:** foreground set to ink. A test reads the rendered colour; restoring
the default fails it.

## M2 — The types grid's caption called the puzzles "games"

`puzzleRotationHelp` ("Turn on the games you want in your rotation. Tap play to
try one.") sat above the **puzzle types** grid, which has no play action. Ported
copy, misleading before this phase and now actively wrong beside a real Games
section with a real "Try it".

**Applied:** caption removed; the key deleted from all ten ARBs rather than left
dead (**ARB 466 → 465**). The pool section's own help says how the rotation works.

## L1 — "Solve a puzzle" labels an alarm set to a game

**Invalid.** Owner decision #1: games live inside the Puzzle dismissal. The label
only appears as the segment the user just chose, directly above the summary that
names the game (pre-review H3) and the pool picker.

## L2 — Large text and dark mode were not exercised on the games

**Applied:** both views render at 1× and 2× text in light and dark, hardest
difficulty (four bushes), with no overflow.

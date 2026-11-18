# Phase 15 — Self-review #2

Two sources, applied together: an **unanchored subagent review** (given the
code and `CLAUDE.md`, not this phase's conclusions — as Phase 14 did, because a
reviewer handed the author's reasoning tends to confirm it) and a second pass
of my own. 0 High, 3 Medium, 5 Low; all applied, none invalid. Every new guard
was mutation-checked: removing it fails at least one test.

## Medium

### SR2-M1 — Pitch still saturated near upright (subagent)

SR1-H2's `atan2(y, √(x²+z²))` fixed face-down play but tops out at 90° and
reads the same either side of vertical. Probed: from an 80° grip, +20° and +30°
read nothing and **+40° read "up"**. Someone sitting up in bed could not roll
Capy down, and leaning further sent it the wrong way. **Applied:** pitch is a
full turn about the screen's left-right axis, `atan2(y, s·z)`, with `s` the
side the screen faced at the start (so face-down still works), and the
difference is wrapped to ±180°. Tests: grips of 60/75/80/88° leaning +20/30/40°
read down, −25° reads up, and an upright rolled grip still reads down. The
saturating formula fails them (checked).

### SR2-M2 — Letting go of a tilt read as the reverse (subagent)

After an arrow press, and at every escape, the reader adopted the **current**
grip as level — usually still tilted toward the flag. Levelling the phone then
read as a tilt the other way: at a new maze's top-left start, where up and
left are the rim, that is a bump the user never made ("A wall. Try another
way.", a struggle). Probed: tilt right, tap an arrow, level → one unrequested
move, bumps 1 → 2. The H1 tests never sent a level reading afterwards, so they
could not fail. **Applied:** `TiltReader.suppressUntilLevel()` replaces
`rebaseline()`: the first grip stays the level, the held direction is dropped,
and nothing reads until the phone is back within 9° of it. A button player in
an odd grip is still never fought (tilt stays set aside while they hold it).
Both tests now level the phone afterwards and fail on the old behaviour
(checked).

### SR2-M3 — `_moves` was frozen in Tilt Maze (mine)

`_moves` was cached in `didChangeDependencies`. Reduce Motion reaches the view
through the host's rebuild (`didUpdateWidget`), not a dependency change, so
turning it on mid-game would have left slides and wobbles running. Shake DJ
already used a getter. **Applied:** a getter; a test turns reduce-motion on
mid-game and fails on the frozen value (checked).

## Low

### SR2-L1 — The escape line outgrew its reserve (subagent)

SR1-H3's "Out! Next maze. 7 steps to the flag." measured 44 → 88 pt in German
and 44 → 66 in Russian, so Snooze jumped at every escape. **Applied:** the
escape line is "Out! Next maze." alone; the first step reads the new distance
(at the start, the arrows' labels already say which way is a wall). The
by-ear test solver takes that first step, and still finishes all three mazes.

### SR2-L2 — At 2× text, every game's result moved Snooze (subagent, widened)

The subagent measured it for Tilt Maze; it held for all five games with a
`GameOutcomeLine`: two reserved lines are not two lines of a sentence at 2×.
**Applied** in the shared widget: `GameOutcomeLine(reserveFor:)` lays out each
result the game can show at the current width and text scale and reserves the
tallest. All five games pass their results. Tests at 2× in en/de/ru for both
new games and a widget test fail without it (checked). Shake DJ's stall line
was shortened so it still fits two lines on a 375 pt phone ("Beat stopped.
Shake or tap.") — otherwise the card rose above Catch the Capy's and the
small-phone guard failed.

### SR2-L3 — The instruction said "tilt" to a screen-reader user (subagent)

Tilt is ignored under a screen reader (pre-review H3), but the instruction
still said "Tilt the phone…". **Applied:** `gameTiltMazeInstructionArrows`
("Use the arrows to guide Capy to the flag."), ten locales, shown when
`accessibleNavigation` is on; the 424 pt card test runs in both modes.

### SR2-L4 — The stall was re-announced every eight seconds (subagent)

`GameOutcomeLine` re-announces the same text when its serial changes; the
serial was the stall count, so VoiceOver heard "Beat stopped" every 8 s while
looking for the button. **Applied:** the serial is the beat count — the live
region speaks the first stall, a beat resets it. The test pumps stall by stall
(one long pump coalesced three stalls into one frame and could not fail —
caught by the mutation check).

### SR2-L5 — The arrow row was 280 pt; a 320 pt phone has 256 (subagent)

iOS 15 still runs on the 320 pt iPhone SE. **Applied:** arrows share the row
at 48–64 pt each. A registry test now pumps **every** game at 320 × 568 in
the ringing slot; all eight fit.

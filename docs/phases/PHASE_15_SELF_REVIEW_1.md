# Phase 15 — Self-review #1

Reviewed: everything Phase 15 wrote, against the revised plan, `CLAUDE.md`,
and a first iPhone 14 Pro capture (`tool/capture.sh`). 3 High, 5 Medium,
2 Low; all applied, none invalid.

## High

### SR1-H1 — "Tap the beat" was a twin of Snooze

The capture showed it plainly: the beat button was a `CapyButton`, the same
chunky orange call to action as **Snooze**, which sits one outcome line below
the card. Shake DJ asks for 20–40 taps from someone half-asleep; one slip
snoozes the alarm. **Applied:** a game control — paper pill, ink border, note
icon — like Capy Rocket's and Tilt Maze's buttons. A test asserts no
`CapyButton` inside the view and that the control names itself to a screen
reader and works from the semantics tree.

### SR1-H2 — Tilt read upside down when the screen faced down

Pitch was `atan2(y, z)`. Lying on your back with the phone above your face
(screen down, z < 0), lowering the bottom edge **decreased** that angle — Capy
rolled up — and a grip near flat face-down sat on the ±180° seam, where a 2°
wobble read as a 358° tilt. **Applied:** pitch is `atan2(y, √(x²+z²))`, the
angle the screen's own vertical axis points below level, the way a ball would
roll in any orientation; roll already had that form. A face-down test fails
on the old formula (checked) and passes on the new.

### SR1-H3 — After a maze, a screen-reader user lost the distance

The escape line was "Out! On to the next maze." — no number. The by-ear test
solver got stuck at the second maze exactly where a blind user would: the
only distance cue was gone until a step happened to be taken. **Applied:** the
escape line is followed by the new maze's steps ("Out! Next maze. 7 steps to
the flag."), and the escape strings were shortened to fit.

## Medium

### SR1-M1 — The cards measured 445–489 pt against the 424 pt cap

Pre-review M3 predicted it; the per-locale test caught it. Two causes: the
instructions wrapped to three lines, and the stall line to three (German,
French), which would also have moved Snooze when it appeared. **Applied:**
fields 164 → 142 pt, Shake DJ's EQ 120 → 100 pt, shorter copy in six locales.
Both views now test at the ringing slot's width that the card is ≤ 424 pt in
all ten locales **and** that the outcome line keeps its height when the stall
or wall line appears.

### SR1-M2 — Forty beats would draw forty pips and announce every beat

`GameHeader` draws one pip per step and its count is a live region. Shake DJ's
hard goal would wrap pips into three rows and speak 40 times. **Applied:**
progress in five-beat phrases (`ShakeDjRound.phrases`, max 8); the EQ shows
the beat.

### SR1-M3 — The flag failed non-text contrast

`accentDeep` on `surfaceAlt` is ~2.2:1; the flag is the goal, so it needs
3:1 (WCAG 1.4.11). **Applied:** a cocoa flag glyph on an accent disc.

### SR1-M4 — The escape-rebaseline test was a guard on trust

Mutation check: deleting `_letGo()` on escape left all tests green. The test
solved by arrows, which rebaseline on every press. A first rewrite by tilt
still passed — the next maze happened to be walled in the held direction, so
H2's quiet stop hid the carried-over roll. **Applied:** the test searches for
a seed whose next maze is open in the last direction, solves by tilt, and now
fails without the guard (checked). The other three guards (H1 press-levels,
H2 quiet stop, H3 screen reader ignores tilt) and Shake DJ's two (screen
reader stills, sensor swap) were each mutation-checked and fail as they
should.

### SR1-M5 — `lib/core/games` fell to 99.82%

`MazeGrid.stepsToFlag` ended in an unreachable `throw`. **Applied:** the loop
is `while (true)`; on a broken maze `Queue.removeFirst` throws on its own.
Back to 100%.

## Low

### SR1-L1 — The plan drifted from the build

Flag wave dropped (the maze's motion is the roll and the bump), field and EQ
sizes, copy, the re-arm level. **Applied:** `PHASE_15_PLAN.md` §12.

### SR1-L2 — The test files needed a shared slot width

Card heights were first measured at the full 393 pt; the ringing slot is
361 pt. **Applied:** `ringingSlotWidth()` in `test/features/games/_pump.dart`.

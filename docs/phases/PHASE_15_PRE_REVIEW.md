# Phase 15 — Pre-review (adversarial, before any code)

Target: `PHASE_15_PLAN.md` as first written. Every finding is applied in the
revised plan (§11 there) or marked invalid with a reason.

## High

### H1 — Always-on tilt fights the always-on buttons, and the natural grip reads as a tilt

The plan measures tilt against a phone lying flat. Nobody plays flat in bed:
a phone held in portrait at 45–70° reads y ≈ +7 to +9 m/s² — "down" — the
whole time. Capy would roll down on mount, bump the first wall, and keep
pressing down while a button user tries to go right. The always-on fallback
(§2) is only safe if the motion input can be neutral in any grip.

**Applied:** tilt is relative to a **baseline** — the attitude captured from
the first reading, again at the start of each maze, and again whenever an
arrow is pressed (pressing an arrow says "I am playing with buttons; this grip
is level"). A new baseline also clears any held direction, so a tilt held
through a maze change does not roll Capy into the next maze.

### H2 — Rolling to the end of a corridor is counted as a struggle

A held tilt rolls Capy until a wall stops it. That is how a tilt maze is
played: you tilt down a corridor and it stops at the end. The plan counts the
stop as a bump — struggle, "A wall. Try another way." — for correct play. The
escape rising early is harmless; the feedback is a false scold every corridor.

**Applied:** a hold that has already moved Capy **stops silently** at a wall
(outcome `stepped` stays). Only a hold, or a button press, that cannot move at
all is a bump. Core gains `canMove` checks; the view tracks "moved this hold".

### H3 — A screen-reader user's own hand movement moves Capy

Under VoiceOver/TalkBack the user navigates by the outcome line and the arrow
labels. Any tilt of the phone (lifting it to the ear, turning in bed) would
move Capy behind their back and invalidate the map they are building. The
"screen-reader solvable" claim does not hold with tilt live.

**Applied:** under `accessibleNavigation` (re-read every build) Tilt Maze
ignores tilt; the arrows are the input. Shake DJ keeps shake live — a stray
shake only adds a beat, it cannot mislead.

## Medium

### M1 — 12 m/s² is not catchable half-asleep

A brisk wrist shake from bed peaks around 8–15 m/s² away from gravity; 12
drops a third of honest shakes. Walking with the phone in hand stays under
~5.

**Applied:** `shakeDeviation` **8 m/s²**, re-arm under **3 m/s²**, refractory
150 ms.

### M2 — A changed `motion` on rebuild leaks or deafens the subscription

Views subscribe once in `initState`. If a host rebuilds with a different
`MotionSensor` (a provider override in a test, or a recreated container), the
old stream stays subscribed and the new one is never heard.

**Applied:** `didUpdateWidget` cancels and resubscribes when `motion` changes;
a test swaps sensors and checks `hasListener` on both.

### M3 — The card height is assumed, not measured

The plan sums 16 + 164 + 8 + 56 + 8 = 252 to match Capy Rocket, but the
header's instruction wraps by locale and Tilt Maze's ("Tilt the phone to roll
Capy to the flag, or use the arrows.") is the longest yet. The clock guard is
the binding check.

**Applied:** both games join `ringing_host_game_test`'s clock guards (393×852
at the device inset, and 375×667), and a view test measures the card in all
ten locales against 424 pt. Instructions kept to one short sentence each.

### M4 — The production override can be forgotten silently

`platformEngineScope` is untestable (plugin init). If the
`motionSensorProvider` override is dropped, release builds get a
`FakeMotionSensor`: shaking does nothing and no test fails (the buttons still
work, so it is not a lockout — it is a dead headline feature).

**Applied:** `motion_providers.dart` exposes `platformMotionOverride()`;
`platformEngineScope` adds it; a test checks it yields a
`PlatformMotionSensor`, and another greps `platform_engine_overrides.dart`
for the call.

### M5 — Tilt in RTL: the plan mirrors nothing, but the arrow labels must still read

Keeping the maze physical is right (a map). But an `ltr` island inside an RTL
card must not flip the arrow *icons* either, and the labels "Left"/"Right"
must stay physical in Arabic. The plan said so for layout only.

**Applied:** the arrow row and the maze sit in `Directionality(ltr)`; icons are
`arrow_back`/`arrow_forward` **with `matchTextDirection: false`** (the
default) and an Arabic test checks order and labels.

## Low

### L1 — String estimate is high

Counted: Shake DJ 3 (instruction, button, stall), Tilt Maze 8 (instruction,
four arrows, wall label, steps plural, wall line, escaped line) = **11**, not
14–20.

**Applied:** estimate restated as **+10 to +13**.

### L2 — The purpose string is never shown

`NSMotionUsageDescription` is only displayed when CoreMotion prompts, and the
accelerometer never prompts. Localizing it into `InfoPlist.strings` would be
ten translations nobody sees.

**Applied:** English only, recorded in the plan and in `OPEN_QUESTIONS.md`; a
test asserts the key exists (the crash guard).

### L3 — "Shake the phone" with no grip cue

A half-asleep user shaking hard can drop the phone on their face.

**Applied:** instruction reads "Give the phone a shake to keep the beat
going." — a shake, not shaking hard; nothing urges speed.

### L4 — Stall copy blames the user

"The beat stopped" is fine; "Shake harder" would not be. The plan's line
offers the button, which is the point.

**Applied:** kept, worded "The beat stopped. Shake the phone, or tap the
button." Nothing about effort.

## Invalid

### X1 — "The fallback should be a separate `GameChallenge` the host switches to"

Considered: report `motionFallback` when the user taps instead of shaking.
**Invalid:** the host never reads `motionFallback` — the escape is computed
from `struggleCount` against tolerance, identically for both. Both inputs
advance one round; switching challenges per input would make progress
depend on which hand moved. The fallback stays a declaration.

## Checked and found sound

- No runtime permission (accelerometer), so no just-in-time prompt rule bites.
- `GameChallenge.motion`'s assert (`!fallback.requiresMotion`) is satisfied by
  construction: the fallback is `GameChallenge.touch`.
- Win headlines `gameWinHeadlineShakeDj` / `…TiltMaze` already exist (Phase 12).
- The puzzle/game vocabulary guard scans `puzzle*` keys only; all new keys are
  `game*`.

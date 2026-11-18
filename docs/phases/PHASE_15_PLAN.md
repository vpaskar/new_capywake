# Phase 15 — Motion games: Shake DJ, Tilt Maze

Status: **revised after the pre-review** (§11 lists the deltas).

Reference: `reference/01_REFERENCES/games/posters/03_SHAKE_DJ.png`,
`07_TILT_MAZE.png`. Posters are bezel-wrapped storyboards, not native
geometry: **Tier A binds nothing** here (as Phases 11–14).

## 1. Objective

Make the last two unblocked games playable on the Phase 11/12 contract, and
land the one piece of infrastructure they need: the accelerometer.

- **Shake DJ** — shake the phone to pump up Capy's beat. Each shake is one
  beat; fill the goal.
- **Tilt Maze** — tilt the phone to roll Capy through a small maze to the flag.
  Three mazes (the poster's three dots).

Both are **motion games**: `GameChallenge.motion` with a non-motion fallback
(the a11y rule asserted since Phase 11). Both are dynamic (owner, Phase 12),
and still under reduce-motion or a screen reader.

## 2. The design call: the fallback is always on screen

A motion game needs a non-motion way to finish. Three shapes were weighed:

| Shape | Cost | Verdict |
|---|---|---|
| A mode switch (Shake ⇄ Buttons) | a chip that must fit 10 locales at 2× text inside a 424 pt card; a screen-reader transition rule; a "no sensor" timer to flip it | rejected |
| Fallback only under a screen reader | a sighted user with a broken accelerometer, a cast, or a phone on a stand cannot finish → **locked out of silencing their alarm** (High, safety) | rejected |
| **Controls always live; motion also works** | none of the above | **chosen** |

So Shake DJ's poster button ("Shake!") is a real button that drops one beat,
and Tilt Maze has four arrow buttons under the maze. Shaking and tilting are
the headline input; the buttons are never hidden, never gated, never timed.
`GameChallenge.motion(fallback: GameChallenge.touch(...))` records that the
fallback exists and needs no motion. The trade-off — a user may simply tap —
goes to `OPEN_QUESTIONS.md` with the alternative ready.

## 3. Dependency and platform

- **`sensors_plus: ^7.1.0`** (7.1.0 in the pub cache; Phase 11's plan reserved
  `^7.0.0` for this phase). Only `lib/data/motion/platform_motion_sensor.dart`
  imports it, as `package:alarm` is fenced in `lib/data/engine/`.
- **No runtime permission on either platform.** The raw accelerometer prompts
  nothing on Android or iOS (it is why it was chosen over step counting).
- **iOS needs `NSMotionUsageDescription` in `Info.plist`** — the plugin's
  README: "a requirement and not doing so will crash your app when it attempts
  to access motion data". English purpose string, honest about scope. Logged
  in `OPEN_QUESTIONS.md` (store-visible text, owner may reword).
- Android: plugin needs AGP ≥ 8.12.1, Kotlin ≥ 2.2.0, Gradle ≥ 8.13; the app
  has AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0. **Android stays untested** (no
  emulator).
- Sampling: `SensorInterval.gameInterval` (20 ms) — a shake peak lasts
  ~100 ms; the default 200 ms would miss it. Only while a game is mounted.

### Axis convention (from the plugin source, not hardware)

`sensors_plus` reports Android's convention on both platforms (iOS multiplies
CoreMotion's g by −9.81, `FPPStreamHandlerPlus.swift:81`). Phone flat face-up:
z ≈ +9.81. Right edge down → x < 0. Bottom edge down (toward the user) →
y > 0. **Verified against source only; no physical device was run.**

## 4. Shared core — `lib/core/motion/`

- **`ShakeDetector`** (pure): `bool register(MotionSample s, Duration at)`.
  A shake is a reading whose magnitude leaves gravity by more than
  `shakeDeviation` (12 m/s²); it **re-arms** only once a reading falls back
  under `rearmDeviation` (4 m/s²) and `refractory` (150 ms) has passed. So one
  long jerk is one beat, and walking (2–5 m/s²) is none.
- **`TiltReader`** (pure): `TiltDirection? read(MotionSample s)` with
  hysteresis — a direction starts when its axis passes `engage` (3.4 m/s²,
  ≈ 20°) and is held until it falls under `release` (1.7 m/s², ≈ 10°); the
  dominant axis wins. Physical directions: `up`, `down`, `left`, `right`.

## 5. Shake DJ

### 5.1 Round — `lib/core/games/shake_dj.dart` (pure, 100%)

- `ShakeDjRound.start(difficulty)`: target **easy 20 / medium 30 / hard 40**
  beats. No randomness — there is nothing to shuffle.
- `beat()` → `beats + 1`, outcome `null`; a no-op once complete.
- `stall()` → `stalls + 1`, outcome `stalled`; a no-op once complete. The
  struggle: the view calls it after `stallAfter` (8 s) with no beat — the
  user may be asleep, stuck, or have a dead sensor, and the escape should come
  forward for all three.
- `challenge` → `GameChallenge.motion(target, completed: beats,
  struggleCount: stalls, fallback: GameChallenge.touch(same))`.
- `level` → `beats / target`, drives the EQ height.
- `grooveFor(difficulty)`: idle bob period 900 / 750 / 600 ms — the speed that
  scales with difficulty.

### 5.2 View — `lib/features/games/shake_dj_view.dart`

Card: `GameHeader` (live count) → field **164 pt** → `sm` → beat button
**56 pt** → `GameOutcomeLine`.

- Field: `game.capy.listening` (collection_06, 260 px → drawn at **86 pt**,
  sharp at 3×) centred; two EQ columns of five UI bars each side (rounded
  rects, not art), lit up to `level` plus a per-beat kick; a music-note icon
  rises on each beat.
- Dynamic: Capy bobs at the groove, scales on each beat; EQ wiggles; notes
  float. **Still** (`reduceMotion` or `accessibleNavigation`, re-read every
  build): no bob, no wiggle, no notes; EQ shows `level` exactly.
- Input: `motion.samples` → `ShakeDetector` → `beat()`; the button → `beat()`.
  Subscription opened once, cancelled on completion and in `dispose`; stream
  errors are ignored (the button still works).
- Stall timer: one `Timer`, reset on each beat, cancelled on completion and
  dispose; works in still mode too (input, not animation).
- Outcome line: only the stall line ("The beat stopped. Shake, or tap the
  button."); never per beat — the header count is already a live region.

## 6. Tilt Maze

### 6.1 Round — `lib/core/games/tilt_maze.dart` (pure, 100%)

- `MazeGrid.generate(cols, rows, seed)`: a perfect maze by seeded
  iterative depth-first carving (every cell reachable, one path between any
  two). Start top-left, flag bottom-right.
- Size: **easy 5×4, medium 6×4, hard 7×4**; **3 mazes** at every difficulty
  (the poster's dots) — target 3.
- `TiltMazeRound.start(difficulty, seed)`; `move(MazeDirection d)`:
  - wall → `bumps + 1`, outcome `bumped`, no move;
  - open → step, outcome `stepped`;
  - reaching the flag → `solved + 1`, next maze from the advanced seed, Capy
    back at the start, outcome `escaped`;
  - no-op once complete.
- `isOpen(d)`, `stepsToFlag` (breadth-first over open edges).
- `challenge` → `GameChallenge.motion(target: 3, completed: solved,
  struggleCount: bumps, fallback: GameChallenge.touch(same))`.
- `rollFor(difficulty)`: one cell per **420 / 340 / 280 ms** while tilted.

### 6.2 View — `lib/features/games/tilt_maze_view.dart`

Card: `GameHeader` → field **164 pt** → `sm` → arrow row **56 pt** →
`GameOutcomeLine`.

- Field: the maze painted as UI (`CustomPaint`, cocoa rounded strokes like the
  poster's walls — geometry, not illustration); the flag is
  `Icons.flag_rounded` on an accent disc; Capy is `game.capy.curledAsleep`
  (moments_00, 270 px) in a cell-sized box.
- **Physical, not mirrored.** A maze is a map and tilting is physical: under
  RTL the maze, the tilt and the arrows keep their left/right. The arrow row
  is `Directionality(ltr)` with `Semantics` labels "Left"/"Right"; this is the
  one deliberate exception to direction-aware layout, recorded here.
- Tilt: `TiltReader` → while a direction is held, move once at once, then
  every `rollFor`; a bump stops the repeat until the tilt changes (one hold =
  at most one struggle).
- Buttons: ← ↑ ↓ →, 64 × 56; a blocked direction stays enabled (pressing it
  bumps), and its label says so ("Up, wall") — the screen-reader path.
- Outcome line: "3 steps to the flag." / "A wall. Try another way." / "Out!
  On to the next maze." — the screen-reader solves by it.
- Dynamic: Capy slides cell to cell (`rollFor`), wobbles on a bump, the flag
  waves. Still: Capy jumps cell to cell, no wobble, no wave.

## 7. Wiring

- `lib/data/motion/platform_motion_sensor.dart`,
  `lib/data/motion/motion_providers.dart` (`motionSensorProvider`, default
  `FakeMotionSensor`, overridden in `platformEngineScope`).
- `GameLaunch` gains **`required MotionSensor motion`**; both hosts
  (`ringing_host.dart`, `game_practice_screen.dart`) read the provider.
- Catalogue: `shake_dj`, `tilt_maze` → `playable`,
  `screenReaderSolvable: true` (buttons + spoken outcome). Registry +2.
- `gameWinHeadlineShakeDj` / `…TiltMaze` already exist.
- `capture_test.dart` gains both games; `_win` taps the button / the arrows
  along the solution path.
- `Info.plist`: `NSMotionUsageDescription`.

## 8. Strings (estimate +14 to +20 keys × 10 locales)

Instructions, the beat button, the stall line, four arrow labels, the wall
suffix, three outcome lines with a plural for steps. Game and puzzle
vocabularies kept apart (vocabulary guard).

## 9. Tests (estimate +70 to +100)

Core: detector and reader edges (threshold, re-arm, refractory, hysteresis,
dominant axis), round transitions, every maze connected and perfect across 200
seeds, BFS distance, no-op once complete. Views: shake → beat via
`FakeMotionSensor`; button → beat; stall after 8 s and not before; listener
cancelled on win and on dispose; still mode stops each motion (and the test
fails without the guard); tilt hold rolls repeatedly and stops at a wall; one
bump per hold; arrows; RTL keeps physical order; text scale 2; dark mode;
locales fit. Host: launch on a card with the escape, struggle raises the
escape at tolerance 0, a win dismisses once, clock guards (both phones).
Data: `PlatformMotionSensor` maps a mocked event channel.

## 10. Acceptance, risks, rollback

Acceptance: both games playable on a ring and in practice; a screen-reader
user can finish both; no motion under still mode; card ≤ 424 pt; validation
gates green; captures recorded for both.

Risks: real-device thresholds untested (no hardware run) → constants named
and logged; iOS crash without the plist key → added and asserted by a test
reading `Info.plist`. Rollback: flip the two entries back to `comingSoon`,
remove the registry lines and the dependency.

## 11. Pre-review deltas

From `PHASE_15_PRE_REVIEW.md` (3 High, 5 Medium, 4 Low, 1 invalid). These
override the sections above where they disagree.

- **H1** Tilt is relative to a baseline: the first reading, each maze start,
  and every arrow press. A new baseline clears the held direction.
- **H2** A hold that moved Capy stops silently at a wall; only a hold or press
  that cannot move at all is a bump.
- **H3** Under `accessibleNavigation` Tilt Maze ignores tilt; arrows only.
- **M1** `shakeDeviation` 8 m/s², re-arm under 4. No refractory window: a
  time window needs a clock the views cannot fake in a test, and the re-arm
  hysteresis alone makes one jolt one beat.
- **H1 detail** Tilt is read as **angles** (pitch `atan2(y, z)`, roll
  `atan2(x, √(y²+z²))`), engage 18°, release 9°: raw m/s² differences shrink
  near vertical (60° → 80° moves y by only 1.2), so a held-upright grip could
  never reach the threshold.
- **M2** `didUpdateWidget` resubscribes when `motion` changes.
- **M3** Both games in the clock guards; card ≤ 424 pt in all ten locales.
- **M4** `platformMotionOverride()` in `motion_providers.dart`, tested, used by
  `platformEngineScope`.
- **M5** Maze and arrow row in `Directionality(ltr)`; Arabic test.
- **L1** Strings **+10 to +13**. **L2** Purpose string English only, key
  asserted by a test. **L3/L4** Copy: "Give the phone a shake to keep the beat
  going." / "The beat stopped. Shake the phone, or tap the button."

## 12. Self-review deltas (as built)

From `PHASE_15_SELF_REVIEW_1.md` and `_2.md`; these override the sections
above.

- Fields are **142 pt** (not 164) and Shake DJ's EQ tops out at 100 pt: the
  card measured 445–489 pt at the ringing slot's width before.
- Shake DJ progress is shown in **five-beat phrases** (4 / 6 / 8 pips).
- The beat button is a **game control** (paper pill, ink border), not the
  orange `CapyButton`: Snooze sits right below it.
- The escape line is "Out! Next maze." alone; the first step in the new maze
  reads its distance (SR2-L1 reversed SR1-H3's combined line, which grew past
  its reserved height).
- Tilt is read from the **first** grip only. An arrow press or an escape does
  not adopt the current grip as level (SR2-M2): it sets tilt aside until the
  phone is back near level, so letting go is never read as the reverse.
- Pitch is a full turn, `atan2(y, s·z)` with `s` the side the screen faced at
  the start, wrapped to ±180° — no saturation near upright (SR2-M1).
- With a screen reader, Tilt Maze's instruction names the arrows.
- Arrows narrow to fit (48–64 pt), so the row fits a 320 pt phone.
- `GameOutcomeLine(reserveFor:)` reserves the tallest result a game can show,
  in every game, so a result never moves Snooze at 2× text.
- The flag is a cocoa glyph on an accent disc (non-text contrast), and does not
  wave: the maze's motion is the roll and the bump.
- Copy as shipped: "Shake the phone to keep the beat going." / "Beat stopped.
  Shake or tap." / "Tilt the phone to roll Capy to the flag."

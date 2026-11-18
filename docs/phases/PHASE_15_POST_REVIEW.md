# Phase 15 — Post-review: Motion games (Shake DJ, Tilt Maze)

**Done 2026-11-18, unattended.** The last two unblocked games are playable on a
ringing alarm and in practice, and the app now has an accelerometer:
`sensors_plus ^7.1.0` behind `core/motion/MotionSensor`, faked in every test,
real only in the production scope.

## What shipped

- **Shake DJ** — each shake (or tap of "Tap the beat") is one beat; 20 / 30 /
  40 beats by difficulty, shown as 4 / 6 / 8 five-beat phrases. Eight quiet
  seconds stall the beat (a struggle; nothing lost). Capy grooves at a
  difficulty tempo, kicks on each beat; EQ bars rise with the level.
- **Tilt Maze** — tilt (or the four arrows) to roll Capy through three seeded
  perfect mazes (5×4 / 6×4 / 7×4) to the flag; a held tilt rolls one cell per
  420 / 340 / 280 ms and stops quietly at a wall; a tilt or press that cannot
  move is a bump (the struggle). The outcome line says how far the flag is.
- **The fallback is always on screen** (plan §2): the button and arrows work at
  all times; motion works alongside. Under a screen reader Tilt Maze ignores
  tilt and its instruction names the arrows; both games are solvable by ear
  (a test solves three mazes from the wall labels and spoken distance alone).
- `GameOutcomeLine(reserveFor:)` — every game's result line now reserves its
  tallest result, so nothing moves Snooze at 2× text (FP-M1).
- `NSMotionUsageDescription` in `Info.plist`; no Android permission.

## Numbers

| | Before | After |
|---|---|---|
| Tests | 1,987 | **2,133** (+146; registered +70–100, restated: two review passes added 50+) |
| `lib` | 98.46% | **98.55%** |
| `lib/core` | 99.70% | **99.72%** |
| `lib/core/games`, `lib/features/games` | 100% | **100%** |
| `lib/core/motion` (new gate) / `lib/data/motion` | — | **100% / 100%** |
| `lib/data` | 89.17% | **89.31%** |
| `lib/features/ringing` | 98.71% | **98.71%** |
| ARB keys × 10 | 544 | **557** (+13; registered +10–13) |
| Comment baseline | 113 | **113** (+0) |

## Findings

Pre-review 3 H / 5 M / 4 L + 1 invalid; SR1 3 H / 5 M / 2 L; SR2 3 M / 5 L;
full-project 3 M / 1 L + 1 carried. **34 applied, 1 invalid (pre-review X1,
with its reason), 1 carried as the owner's** (Settings' motion check, already
owed). The ones that mattered:

- **SR1-H1** "Tap the beat" was the same orange `CapyButton` as Snooze, right
  below it — 20–40 half-asleep taps with a snooze one slip away. Found on the
  first capture.
- **SR1-H2 → SR2-M1** Tilt was read wrongly twice: `atan2(y, z)` inverted face
  down; its replacement saturated near upright (+40° from 80° read "up"). Now a
  full turn from the starting face, wrapped.
- **SR2-M2** Letting go of a tilt read as the reverse tilt, and bumped at
  every new maze's start. Found by the unanchored subagent with a probe.
- **Four guards were on trust until mutation-checked** (escape rebaseline,
  stall announcement, and two test-mechanics slips: a test solved by arrows
  that rebaseline anyway, and one long `pump` that coalesced three timers into
  one frame). Every guard in this phase was then proven to fail without its
  code.

## Captures (Tier A binds nothing — posters are storyboards)

`docs/visual/ringing_shake_dj/`, `win_shake_dj/`, `ringing_tilt_maze/`,
`win_tilt_maze/` — written and verified by `tool/capture.sh` on the iPhone 14
Pro; `_win` plays both games to the end (Shake DJ by its button, Tilt Maze by
ear). Both cards clear the clock at the device inset; on a 375 × 667 phone
neither reaches higher than Catch the Capy (guards in `ringing_host_game_test`).
Home: Shake DJ's tile lost "Soon"; `compare.dart` worst delta 2.7 pt, no Tier A
change.

**Device:** Shake DJ practice ran on the iPhone 18 Pro simulator **with the
real `sensors_plus` plugin** — it subscribed without crashing and taps
registered. **No accelerometer was exercised:** the simulator has none, and no
physical phone was run. The thresholds (shake 8 m/s²; tilt 18° / 9°) are from
physics and the plugin's source; logged for the owner. **Android untested** (no
emulator).

## Tier B substitutions (reported in session, logged)

- **G39** Shake DJ: no DJ decks, no dancing headphones Capy →
  `game.capy.listening` (purple headphones, 260 px at 86 pt) + UI EQ bars.
- **G40** Tilt Maze: no rolling Capy, no goal flag → `game.capy.curledAsleep`
  (baked "zz") in a 27–35 pt cell + a Material flag glyph on an accent disc;
  walls are UI geometry.

Requests #13 and #14 in `docs/visual/ART_REQUESTS.md`.

## Owner questions added (`docs/sessions/OPEN_QUESTIONS.md`)

Buttons always work (vs a "Can't shake?" switch); the iOS motion purpose
string; thresholds never felt on a device.

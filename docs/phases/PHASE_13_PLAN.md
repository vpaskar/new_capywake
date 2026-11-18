# Phase 13 — Touch games II: Rhythm Rescue, Capy Rocket

**Revised after `PHASE_13_PRE_REVIEW.md` (15 findings, 5H/6M/4L, all applied).**
The deltas are folded in below; one line each in §12.

Two more wake-up games on the Phase 11 contract and the Phase 12 selection model.
**No new dependency, no permission, no schema bump, no change to the alarm flow:**
a game arrives by flipping its catalogue entry and adding one registry line.

This phase ran **unattended** (owner, 2026-11-18): questions go to
`docs/sessions/OPEN_QUESTIONS.md` with the conservative choice taken meanwhile.

Reference: `reference/01_REFERENCES/games/posters/09_RHYTHM_RESCUE.png`,
`10_CAPY_ROCKET.png`. **Tier A binds nothing** — the posters are bezel-wrapped
storyboards (1122×1402, Russian side copy), not 851×1847 native geometry, as for
every game since Phase 11.

---

## 1. Objective

- Rhythm Rescue and Capy Rocket are playable on a ringing `DismissMethod.puzzle`
  alarm (via the wake pool) and in practice (chooser "Try it").
- Both are **dynamic** (owner rule, Phase 12) and both stop all motion under
  `disableAnimations` **or** a screen reader, staying finishable there.
- Both count a **struggle** so the host can raise the escape against the alarm's
  resolved tolerance. The escape stays `RingingScreen`'s.

## 2. What the posters ask for, and what this phase builds

| Poster | Built |
|---|---|
| RR: "repeat a short rhythmic pattern"; ▶ + pattern slots; four coloured pads | Simon-style: the pads light the pattern in time, the user repeats it in order. ▶ replays it. |
| RR: "Level 2 · Series 2/4" | `GameHeader` progress `2 / 3` + pips (shared look across games) |
| RR: headphones capybara over the card | the painted `tile.rhythmRescue` in a rounded panel, bobbing on each beat — **Tier B** |
| CR: "swipe to speed the Capy rocket to the sun"; ‹ hand › panel | each swipe in the arrow's direction boosts the rocket up the sky; ‹ › are also large buttons |
| CR: "Reach the sun!" progress bar | `GameHeader` progress — **Tier B**, the shared header |
| CR: flying capybara on a rocket, sun, clouds | `pose.capyRocket` (landed win pose) over the `morning_sunrise` sky — **Tier B** |

**Timing is never judged.** "Rhythm" is how the pattern is *shown*; repeating
it is about order only. A timing window is precision input for a half-asleep
user (`CLAUDE.md`: no precision tapping).

## 3. Rhythm Rescue

### 3.1 Core — `lib/core/games/rhythm_rescue.dart` (pure Dart, 100%)

`RhythmRescueRound` (immutable, seeded):

- `padCount = 4`.
- `patternLengthFor`: easy 3, **medium 4** (poster: four slots), hard 5.
- `targetFor` (patterns to repeat): easy 2, medium 3, hard 4.
- `beatFor` (playback interval): easy 750 ms, medium 600 ms, hard 480 ms —
  difficulty is how fast the rhythm plays.
- State: `pattern` (unmodifiable), `entered`, `rescued`, `wrongTaps`,
  `phase` (`listening` | `repeating`), `lastOutcome` (`null` | `rescued` |
  `missed`).
- Patterns never repeat a pad twice in a row (a pad lit twice in a row is hard
  to see as two beats).
- `heard()` → `repeating` (playback finished, or no playback).
- `replay()` → back to `listening`, `entered = 0`, **no struggle**.
- `tap(pad)`: no-op unless `repeating` and unfinished. Right pad → `entered + 1`;
  the last one → `rescued + 1`, a new seeded pattern, `listening`, outcome
  `rescued`. Wrong pad → `wrongTaps + 1`, `entered = 0`, **the same pattern**,
  `listening`, outcome `missed` — it eases, it never gets harder.
- `challenge` → `GameChallenge.touch(target, completed: rescued,
  struggleCount: wrongTaps)`.

### 3.2 View — `lib/features/games/rhythm_rescue_view.dart`

Card: `GameHeader` (**one** instruction, H1) → art row → pads → outcome line.
A `Column`, no fixed height (M5).

- **Art row**: the `tile.rhythmRescue` panel (88 pt); beside it a status line
  ("Listen…" / "Your turn", fixed slot, H1), then ▶ replay (56 pt) and one slot
  per beat.
- **Pads**: four pads in a row, square with a 72 pt minimum that grows with the
  numeral (M5), poster colours (sampled, §8), each with a **numeral 1–4** via
  `gameRhythmRescuePadNumber` (H4, a non-colour channel) and a 1.5 pt
  `cocoaSoft` border (the pale pads alone fail 3:1 against cream). While
  listening they are disabled in semantics and drawn at reduced opacity (L1).
- **Moving** (default): on `listening` the pads light one by one at the beat
  (`Timer` chain, a lit pad scales to 1.08), the art panel bobs on each beat,
  then `heard()`. While repeating, slots fill as beats are entered and **the
  pattern is hidden** (a memory game). ▶ replays it at no cost.
- **Still** (`reduceMotion` or `accessibleNavigation`, **read every build**, H5
  — turning still mid-playback cancels it and shows the pattern): no playback;
  `heard()` immediately; **every slot shows its pad numeral throughout**, so the game is
  follow-the-pattern and finishable without sight. ▶ is not shown.
- Semantics: each pad a `button` "Pad {n}"; each slot "Beat {b}: pad {n}" when
  shown, "Beat {b}: done" when entered; outcome line is a live region in an
  always-present slot two body lines tall at the current text scale (M3). The
  miss line is mode-neutral (M4).
- Timers: one `Timer?`, cancelled in `dispose` and on completion (M2); art
  pre-cached in `didChangeDependencies` (M6).
- No sound: the alarm is already ringing.

## 4. Capy Rocket

### 4.1 Core — `lib/core/games/capy_rocket.dart` (pure Dart, 100%)

`CapyRocketRound` (immutable, seeded):

- `targetFor` (boosts): easy 6, medium 8, hard 10.
- `climbFor` (one boost's climb): easy 700 ms, medium 550 ms, hard 420 ms.
- `cue`: `RocketSide.start` | `RocketSide.end` — **logical**, so RTL mirrors
  it with the layout. Seeded per boost.
- `boost(side)`: no-op once complete. Matching → `boosts + 1`, new seeded cue,
  outcome `boosted`. Not matching → `wobbles + 1`, **cue unchanged**, outcome
  `wobbled`; no progress is ever lost.
- `challenge` → `GameChallenge.touch(target, completed: boosts,
  struggleCount: wobbles)`.

### 4.2 View — `lib/features/games/capy_rocket_view.dart`

Card: `GameHeader` → sky field (280 pt, a `Stack`) → control panel → outcome
line (same reserved slot as RR, M3).

- **Field**: `game.sky` (`themes/morning_sunrise.png`, re-imported at game-scene
  size) `BoxFit.cover`; the rocket (`pose.capyRocket`, `ArtUse.winPose.renderBoxPt`
  = 100 pt wide, H3) starts at the field's foot and climbs `boosts / target` of
  the way to the top. The **cue pill** ("Swipe left") sits at the field's top
  (H2), where the poster draws "Reach the sun!".
- **Panel**: a start-side arrow button, a swipe-hint icon, an end-side arrow
  button, each button ≥ 64×56 pt; the row never changes height (H2). The cue's button is filled
  `accentDeep` with a light icon, the other outlined (shape + fill + text, not
  colour alone).
- A horizontal swipe anywhere on the field or panel (≥ 32 pt or a fling) is a
  boost toward that side; RTL maps physical to logical.
- **Moving**: each boost animates the climb over `climbFor(difficulty)`; between
  climbs the rocket hovers (one 1.6 s bob, then a 150 ms rest — a `Timer` beat,
  as Catch the Capy's footfall, so `pumpAndSettle` can settle); a wrong swipe
  wobbles it (400 ms tilt).
- **Still**: no hover, no wobble, the climb jumps.
- Semantics: buttons "Fly left" / "Fly right" (the **physical** side each sits
  on, resolved from `Directionality`, L2), the cue a live region, the field and
  art excluded. Still mode read every build (H5); one `Timer?` cancelled in
  `dispose` (M2); art pre-cached (M6).

## 5. Wiring

- `GameCatalogue`: both → `playable`, `screenReaderSolvable: true` (still mode
  shows the pattern; the cue is announced and the buttons are labelled).
- `GameRegistry.builders`: two lines. `game_registry_test` pins equality.
- `RingingHost`, practice, chooser, Add/Edit pool: **unchanged** — all read the
  catalogue and registry. Home rail: unchanged (`homeRail` is the mockup's four).
- `integration_test/capture_test.dart`: `ringing_rhythm_rescue`,
  `win_rhythm_rescue`, `ringing_capy_rocket`, `win_capy_rocket`; the win helper
  plays each game as a user would (watch the lit pads, then tap them; tap the
  cued button).

## 6. Strings (estimate +14 to +18 keys × 10 locales)

RR: listen / repeat instructions, replay label, pad label, beat-shown / beat-done
/ beat-hidden labels, rescued / missed outcomes. CR: instruction, cue left /
right, fly left / right labels, boosted / wobbled outcomes. Puzzle and game
vocabularies stay apart (`puzzle_game_vocabulary_test`).

## 7. Art

| Use | Asset | State |
|---|---|---|
| RR art panel | `tile.rhythmRescue` (bundled, 360 px) at 88 pt = 264 px ✓ | **Tier B** for the poster's headphones cutout — gap |
| CR rocket | `pose.capyRocket` (bundled, 300×256) at 104 pt = 312 px | **Tier B**, 4 % short; a landed pose with baked confetti — gap |
| CR sky | `themes/morning_sunrise.png` 1200×800 → `games/sky.webp` 1080 px | new import, `ArtUse.gameScene` |
| Win poses | `pose.rhythmRescue`, `pose.capyRocket` | bundled |

No art generated. Every gap reported in session and logged in
`docs/visual/asset_gaps.md` + `ART_REQUESTS.md`.

## 8. Tokens

Four pad colours sampled from the poster's pads (median of a 7×7 grid), in their
own `CapyPadColors` group (L3): `orange F8A455`, `yellow FED181`,
`green B7D187`, `blue B3D2E1`.
`tokens_contrast_test` gains cocoa-on-pad (text ≥ 4.5:1) and the pad border.

## 9. Tests (estimate +70 to +100)

- Core: both rounds to 100% — targets/beat/climb tables, seeded determinism,
  no adjacent repeats, the ease rules (wrong tap keeps the pattern; wrong swipe
  keeps progress), no-ops once complete, `challenge` mapping.
- Views, mounted in the real `RingingScreen` (Phase 12 SR1), playback driven by
  explicit `pump(beat)`, never `pumpAndSettle` (M1): playback lights in
  order and ends in `repeating`; taps fill slots; wrong tap counts and replays;
  replay costs nothing; still mode shows numerals and never animates
  (`hasRunningAnimations` false); swipe and buttons boost; RTL mirrors the cue
  and the swipe; completion reported once; semantics labels; dark mode;
  `accessibleNavigation` flipped mid-playback (H5); dispose mid-playback and
  mid-hover (M2); the pads and buttons do not move between phases (H1, H2, M3).
- Host: each game launches from a one-game pool, raises the escape past
  tolerance, dismisses on completion.
- Registry/catalogue tests updated to four playable.

## 10. Acceptance

All validation gates green; both games played to a win on the iPhone 18 Pro in
practice; ringing + win captures for both via `tool/capture.sh`; gaps reported.

## 11. Risks and rollback

- **Playback timers leaking past dispose** → cancel in `dispose`; tested.
- **A continuous animation hangs `pumpAndSettle`** (capture, host tests) →
  every loop is a finite tween plus a `Timer` rest.
- **Horizontal swipe fights the ringing slot's vertical scroll** → only a
  horizontal recognizer on the game; verified on device.
- Rollback: revert the phase commit; no schema or stored-data change.

## 12. Pre-review deltas

- **H1** one RR instruction; the phase shows in a fixed status slot.
- **H2** CR cue in a pill on the fixed field; the button row is constant.
- **H3** rocket width = `ArtUse.winPose.renderBoxPt` (100 pt).
- **H4** pad numerals through an ARB `int` placeholder.
- **H5** still mode re-read every build; turning still cancels playback.
- **M1** explicit `pump(beat)`; capture watches the lights. **M2** timers
  cancelled on dispose/completion. **M3** reserved outcome slot. **M4**
  mode-neutral miss line. **M5** RR is a `Column`, pads grow with text.
  **M6** pre-cache.
- **L1** pads disabled while listening. **L2** physical labels, logical layout.
- **L3** `CapyPadColors`. **L4** the cue kept; question logged.

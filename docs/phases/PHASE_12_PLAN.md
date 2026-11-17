# Phase 12 — Touch games I: Catch the Capy, Memory Hideout

**Revised after `PHASE_12_PRE_REVIEW.md` (16 findings, 7H/6M/3L, all applied).**
The deltas are folded in below; one line each in §11.

The first two real wake-up games, built on Phase 11's contract, **plus the shared
selection model** that decides, on a ringing alarm, whether the user gets a
generated puzzle or a game. No new permissions, no new dependency, no schema bump.

Reference: `reference/01_REFERENCES/games/posters/04_CATCH_THE_CAPY.png`,
`06_MEMORY_HIDEOUT.png`, the portrait boards `games/portrait/04_*`, `06_*`, and
the tile `reference/02_ASSETS/game_tiles/catch_the_capy.png`. **Tier A binds
nothing** — the posters are bezel-wrapped storyboards with Russian side copy, not
851×1847 native geometry (as Phases 06/09/10/11).

---

## 0. The owner decision this phase implements (2026-11-17, in session)

Phase 11 left "which challenge does a ringing alarm get" open. The owner settled it:

1. **Games join the existing Puzzle dismissal** — not a new `DismissMethod`.
2. **The puzzle rotation is the default.** The puzzle chooser gets a **Games**
   section: each game can be enabled or disabled alongside the puzzle types.
3. **Per-alarm overrides**: an alarm either inherits the app-wide settings or
   selects **a specific game, or a subset of games**.
4. **Home tiles always launch practice mode** and never touch alarm configuration.
5. **Reuse the existing settings and override JSON** (no schema bump). Preserve
   the dismissal, escape and reliability rules.
6. **Build the shared selection model now**, so a future game registers without
   changing alarm behaviour or rebuilding UI.

---

## 1. Objective

- A ringing `DismissMethod.puzzle` alarm draws **one challenge per ring** from a
  pool: "puzzles" (the existing generated rotation) plus every enabled, launchable
  game. Seeded per ring, reproducible across rebuilds, as `PuzzleRound` is today.
- Catch the Capy and Memory Hideout are playable on that surface and in practice.
- The chooser and Add/Edit expose the pool; Home/chooser offer practice.

---

## 2. The selection model (core, pure Dart)

### 2.1 `PuzzleSettings` gains two fields

- `enabledGames: Set<String>` — catalogue ids, default `{}`, unmodifiable.
- `includePuzzles: bool` — whether the generated puzzles are in the pool, default
  `true`.

Invariants (in `checkInvariants`, `ArgumentError`, release-safe):

- **The pool is never empty:** `includePuzzles || enabledGames.isNotEmpty`. The
  existing `enabledTypes.isNotEmpty` invariant **stays** — the types remain
  configured while excluded, so `PuzzleRound.start`, `isVisualOnly`, the type grid
  floor and every ported test keep holding unchanged.
- **Every game id is a catalogue id.** Unknown ids are dropped by the mapper on
  read, never thrown on (the existing tolerant-read rule).

Why a boolean rather than allowing `enabledTypes` to empty: "a specific game only"
needs the puzzles out of the pool; emptying `enabledTypes` would break the ported
invariant that `PuzzleRound` and `RingingHost` both rely on, at 03:00.

### 2.2 `AlarmPuzzleOverride` gains the same two, nullable

`enabledGames: Set<String>?`, `includePuzzles: bool?` — `null` follows the default.
**Invariant: `includePuzzles == false` requires a non-empty `enabledGames`** on the
override itself. Otherwise an override "puzzles off, games follow default" would
resolve to an empty pool the day the user disables their last default game —
throwing in `resolveFor` on the ringing path. `from`, `isEmpty`, `copyWith`, `==`,
`hashCode`, `resolveFor` all extended.

### 2.3 `WakeChallengeSelector` (`lib/core/games/wake_challenge.dart`)

`sealed class WakeChallenge` → `PuzzleWakeChallenge` | `GameWakeChallenge(gameId)`.

`WakeChallengeSelector.pick({settings, seed, isLaunchable})`:

- pool, in a fixed order: `puzzles` if `includePuzzles`, then each id in
  `GameCatalogue.entries` order that is in `enabledGames` **and** `isLaunchable`;
- uniform seeded pick (`math.Random(seed)`);
- **empty pool → `PuzzleWakeChallenge`**: an enabled game that is not launchable
  in this build (retired, or a registry/catalogue mismatch) must never leave a
  ringing alarm without something to solve. `enabledTypes` is never empty, so the
  fallback always has a puzzle.

`isLaunchable` is passed in: `core` cannot see the widget registry.

### 2.4 Game difficulty

Puzzle shape is user-configurable (`CLAUDE.md`). Games read the resolved
`difficulty`; `taskCount` stays puzzle-only and the chooser says so.

| | easy | medium | hard |
|---|---|---|---|
| Catch the Capy — catches | 3 | **5** (poster) | 7 |
| Memory Hideout — rounds × bushes | 2 × 3 | **3 × 3** (poster) | 4 × 4 |

### 2.5 `GameCatalogue`

- `catch_the_capy`, `memory_hideout` → `playable`.
- `GameEntry.screenReaderSolvable` (default `false`; `true` for the two built).
- `GameCatalogue.byId`, `GameCatalogue.ids`.
- `PuzzleSettings.isVisualOnly` widens to the pool: visual-only when no member of
  the pool is screen-reader solvable (puzzles count when included and any enabled
  type is solvable).

---

## 3. The two games (core state + feature view)

**Both are static: no tween, no ticker, no timer.** `CLAUDE.md`: no animation on
the ringing surface, honor `disableAnimations` everywhere. A state change on tap
is not an animation. `reduceMotion` therefore has nothing to suppress, and a test
asserts `hasRunningAnimations` is false after every interaction with the flag
either way.

### 3.1 Catch the Capy

- **Core** `CatchTheCapyRound` (immutable): `target`, `caught`, `misses`, `spot`
  (index into a fixed grid of spots), `seed`. `catchCapy()` → `caught + 1`, new
  seeded spot **≠ the current one**; `miss()` → `misses + 1`. `challenge` →
  `GameChallenge.touch(target, completed: caught, struggleCount: misses)`.
- **View**: a meadow field; the capybara (`collection_10`, running) sits at the
  spot. Tap on it = catch; tap on the grass = miss. **The capybara moves only when
  caught** — no relocation timer: a moving target under time pressure is
  precision tapping for a half-asleep user, and it would be an animation.
- Target ≥ 88 pt (well over the 44 pt floor). Header: name pill, instruction
  ("Catch the capybara 5 times."), progress `3 / 5` + pips (poster).
- Semantics: the capybara is a `button` labelled "Catch the capybara"; the field
  is excluded so a screen reader cannot "miss".

### 3.2 Memory Hideout

- **Core** `MemoryHideoutRound`: `bushCount`, `target`, `found`, `wrongPicks`,
  `hiddenAt`, `phase` (`revealing` | `guessing`), `seed`. `ready()` →
  `guessing`. `pick(i)`: correct → `found + 1`, new seeded `hiddenAt`, back to
  `revealing` (unless complete); wrong → `wrongPicks + 1`, back to `revealing` at
  **the same spot** — the game eases, it never gets harder for struggling.
- **View**: a row of bushes; while revealing, the hidden bush shows `moments_14`
  (capy peeking over a bush) and a **Ready** button hides it. **No timed reveal**:
  the user controls when Capy hides, so a screen-reader user hears the reveal
  ("Capy is behind bush 2 of 3") before it goes.
- Bushes: `bush_round.png` drawn at **32 pt** (`ArtUse.gameBush` — restated from 35: trimmed to ink the file is 97 px, not 107 — the size the
  107 px file supports) inside ≥ 88 pt tap cards — **G29 reported** (H2).
- After a pick, an outcome line, shown and announced: "Found Capy." / "Not
  there. Capy is behind bush {n}." (H4).

### 3.3 The view contract

Each view is a `GameRingingView` subclass taking `seed` and `difficulty` in
addition to the contract's three. Built only through the registry.

---

## 4. The registry (`lib/features/games/game_registry.dart`)

`GameRegistry.builders: Map<String, GameViewBuilder>` — id → builder taking a
`GameLaunch` (seed, difficulty, onProgress, onCompleted, reduceMotion).
`GameRegistry.isLaunchable(id)` = registered **and** catalogue-playable. A test
pins **registered ids == `GameCatalogue.playable` ids**, so a later phase that
flips a catalogue entry without a view (or the reverse) fails.

---

## 5. Ringing wiring (`RingingHost`)

- Per ring (occurrence id + snooze count, the existing key) pick a
  `WakeChallenge` with the existing seed.
- Puzzle → today's `PuzzleView` path, unchanged.
- Game → `GameRingingSlot` → registry builder, **keyed by the ring** so a snooze
  re-ring starts fresh. `onProgress` stores the latest `GameChallenge`; when
  `challenge.escapeVisibilityFor(toleratedStruggles:
  settings.toleratedWrongAnswers)` is prominent, call
  `raiseEscapeVisibility()` and fold it into the session this frame (as
  `_withRoundVisibility` does for puzzles). `onCompleted` → `controller.dismiss`.
- The escape is `RingingScreen`'s, untouched.

---

## 6. Practice

- Route `/games/:id` (root navigator, pushed). Screen: header with back, the game
  via the registry with `seed` from the clock, `difficulty` from the app-wide
  settings; `onProgress` ignored; `onCompleted` → a "Practice done" state with
  **Play again**. Reads settings, **writes nothing**.
- Unknown / non-launchable id → the existing unavailable sheet's copy in a page,
  never a crash.
- New keys `gamePracticeNote`, `gameTryAction` (M3); the onboarding strings stay
  unused. Seed from an overridable `practiceSeedProvider` (M1).

## 7. Entry points

- **Home rail**: a playable tile pushes practice; others keep the sheet.
- **Chooser**: a **Games** section above the types — a "Puzzles" switch and one
  switch per playable game, each game row with a "Try it" link to practice. The
  last pool member cannot be switched off (floor held in the controller too).
- **Add/Edit**: when the alarm carries its own settings, the same pool picker,
  bound to the draft override.

---

## 8. Strings (estimate +12 to +16 keys × 10 locales)

Instruction per game, progress value, capybara button label, Memory's reveal /
guess / ready / bush label / capy-here, practice done / play again, chooser
section label + puzzles label + help, Add/Edit pool label.

## 9. Art

| Use | Asset | State |
|---|---|---|
| Catch capybara | `mascots/collection_10.webp` (267 px) | bundled; ≥ 88 pt × 3 = 264 ✓ |
| Memory reveal | `mascots/moments_14.webp` (288 px) | bundled ✓ |
| Memory bush | `asset_library/decor/bush_round.png` (107 px) | **G29, under-resolved** |
| `tile.memoryHideout` | `moments_14` on a cream tile | **G23 Tier B substitution** |

No art generated.

## 10. Tests, acceptance, risks

- Core: selector (pool order, fallback, determinism, launchable filter), settings
  and override invariants, mappers (round-trip, unknown ids dropped, the
  `includePuzzles:false` + all-games-dropped read path does not throw), both games
  to 100%.
- Features: each view (catch, miss, reveal/ready/pick, semantics, no animation),
  registry == playable, host launches a game, raises the escape against the user's
  tolerance, dismisses on completion, snooze restarts; chooser and Add/Edit
  picker floor; practice route; Home tile routing.
- Gates: all of `CLAUDE.md`'s validation list. Device: play both games on the
  iPhone 18 Pro, ringing and practice.
- **Risks**: invariant break on the read path (mitigated §2.2/§10); registry drift
  (pinned §4); a game swallowing the escape (structurally impossible, kept).
- **Rollback**: revert the phase commit; no schema change, stored JSON stays
  readable (new keys ignored by older readers).

## 11. Pre-review deltas

- **H1** fixed-height game fields; views tested inside the real `RingingScreen`.
- **H2** bush at 32 pt (`ArtUse.gameBush`; 35 restated on measurement); the import guard is not relaxed; G29.
- **H3** Add/Edit summary built from the pool; no task count for games-only.
- **H4** Memory Hideout outcome line, shown and announced.
- **H5** both mappers restore puzzles when the read pool would be empty.
- **H6** tolerance, difficulty and pool all from the alarm's resolved settings.
- **H7** rounds no-op once complete; completion reported once.
- **M1** `practiceSeedProvider`. **M2** chooser writes `includePuzzles`, tested.
- **M3** new `gameTryAction`/`gamePracticeNote`. **M4** task-count caption.
- **M5** rail tests + Home re-capture. **M6** odds stated, selector pinned.
- **L1** `screenReaderSolvable` required. **L2** practice deep link to a
  non-playable id renders the unavailable copy. **L3** copy written fresh.

## 12. Owner directions mid-phase (2026-11-17, in session) — supersede §3's "static"

After seeing the first version on device, the owner asked, in order:

1. A small capybara beside the outcome line ("Found Capy.").
2. **Catch the Capy must move**, not sit still; it should **run away** in
   different directions, **face the way it runs**, run **non-stop**, and its
   **speed should follow difficulty**.
3. **All games dynamic** — Memory Hideout became a shell game: after Ready the
   bushes swap places (1/2/3 swaps by difficulty) while you watch.
4. **Not only a green field** — the meadow carries the package's decor.
5. **Moving legs, dust, footsteps** — no art exists; reported as G32 with the
   exact frames needed. Not drawn in code.

What changed as a result, and the guardrails kept:

| | Catch the Capy | Memory Hideout |
|---|---|---|
| Motion | runs continuously: a run, a 150 ms footfall, the next run; bolts to the far side of a missed tap; faces its direction; three bounces per run | 1/2/3 animated swaps, 550 ms each; picks wait for the shuffle |
| Difficulty | run 1300 / 1000 / 750 ms (easy / medium / hard) | swaps 1 / 2 / 3 (with 3 / 3 / 4 bushes) |
| Reduce-motion or screen reader | holds still; moves only when caught; a miss does not move it | no shuffle; guess straight away |

`CLAUDE.md`'s "no animation on the ringing surface" is narrowed to the ringing
**chrome** (clock, Snooze, escape), with the owner's direction recorded beside it.

## 13. Owner game art (2026-11-17, in session)

The owner supplied the six files G32 asked for. Catch the Capy now draws the
meadow backdrop, plays the 8-frame nightcap gallop (two leg cycles per run, so a
harder setting also moves the legs faster) with a small bounce per stride,
drops a dust puff where each run starts and four alternating paw prints that
fade along the path. Memory Hideout draws the plain bush on every card; on the
reveal card Capy (the same nightcap character, run frame 4) stands behind it
with its head over the top. The painted tile replaces the `moments_14`
stand-in. Reduce-motion and screen-reader behaviour unchanged: one still frame,
no dust, no prints, no shuffle. Import, validation and the two supply defects
(tile frame, bush edge) are recorded in `asset_gaps.md`.

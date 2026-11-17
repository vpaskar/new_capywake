# Current phase

**Phase 11 — Game foundation: done, 2026-11-17. `Current phase: 12`.**

**1,572 tests**, analyze clean including infos, lib 97.95% / `lib/core` 99.61% /
**`lib/core/games` 100.00%** / `lib/data` 88.95% / `lib/features/ringing` 98.53%,
**446 ARB keys × 10 locales** (+6). Comment baseline +0 (113).

## What this phase is, and the one decision it settled

**The shared contract the ten wake-up games (Phases 12-17) slot into — built with
NO specific game and NO new visible surface.** The games are ten NEW products,
disjoint from the ten already-ported puzzle *types* (zero overlap).

The architectural call, settled in the plan and stress-tested in the pre-review:
**a game is not a fourth `DismissMethod`.** Adding one would bump the Drift
`schemaVersion` and ripple through the mapper, `AlarmDismissSummary`, the Phase 10
chooser and 1,547 tests — for a Phase 12 product that does not exist. A game is a
**puzzle-parallel challenge surface**, launched into the same
`RingingScreen.puzzleSlot` that `PuzzleView` uses.

## What shipped

- **`lib/core/games/game_challenge.dart`** (pure Dart): goal in steps
  (`target`/`completed`/`isComplete`), `struggleCount` the game defines,
  `escapeVisibilityFor({toleratedStruggles})`. Reuses the **enum**
  `PuzzleEscapeVisibility`, **not** `PuzzleEasingState`'s `wrongThisRound`
  arithmetic — a game has no wrong answer (pre-review H1). Six public members, no
  score/streak/best (M4). Motion variant requires a non-motion fallback at the
  call site, asserted to not itself need motion (H4 + SR1).
- **`lib/features/ringing/game_ringing_view.dart`**: `GameRingingView` (two
  callbacks + `reduceMotion`) and `GameRingingSlot` (reads
  `MediaQuery.disableAnimations`). **The escape is owned by `RingingScreen`; a
  game has no seam to hide or gate it** (H2).
- **`GameCatalogue` 4 → 10** (zero `playable`) + a **`homeRail` subset of four** so
  Home does not regress (M2/M3). Six name keys (ARB +6), six tile gaps G23-G28.

## Findings that matter for Phase 12 and later

### 1. The escape policy stays the user's — pass `toleratedWrongAnswers` in (SR2 M1)

A game-launch path must call
`GameChallenge.escapeVisibilityFor(toleratedStruggles: settings.toleratedWrongAnswers)`.
A test proves a game and a puzzle offer the escape identically against that
setting; a Phase 12 game that reads anything else, or maps it differently, fails
the test. The `core` layer cannot read settings (headless), so wiring the source
is Phase 12's job — the guard stands watch.

### 2. A motion game's fallback must be usable without motion (SR1 H1)

`GameChallenge.motion` requires a `fallback` AND asserts `!fallback.requiresMotion`
— a "fallback" that also needs motion used to compile and defeated the a11y rule.
Phase 15's Shake DJ and Tilt Maze inherit this; the fallback cannot be skipped or
faked.

### 3. The foundation stayed headless on purpose (pre-review H3)

No onboarding demo shipped. The three unused onboarding strings
(`onboardingTryGame`, `onboardingPracticeNote`, `onboardingPracticeRetry`) stay
unused — a playable demo is a future-phase surface ("Do not implement future
phases"). A games phase that wants a live demo may spend them; the foundation did
not.

### 4. The pre-review's own L1 was wrong, and the full-project review caught it

The pre-review called Home's "See All" games action dangling with "no
destination". It is not — `PHASE_03_PLAN.md:202` routes it to the Stats Games
segment deliberately (both tabs, `go` not `push`). Corrected in the post-review.
A review's own earlier finding is still subject to the later review.

### 5. Device verification is a regression check when nothing new ships

No new interactive surface → the device run confirmed the ringing surface and the
Home rail are **unchanged**: Home draws exactly the four tiles (not the ten),
Step Quest opens the blocked/step-count sheet. The catalogue grew to ten in data
while the rail stayed at four in render — proven on the iPhone 18 Pro, not just in
a synthetic-viewport widget test.

## Next session — Phase 12, Touch games I (Catch the Capy, Memory Hideout)

**The first two REAL games**, built on Phase 11's contract. No new permissions.
Each is a `GameRingingView` subclass driving a `GameChallenge`; each must pass
`settings.toleratedWrongAnswers` into the escape mapping and honor `reduceMotion`.
Flip the catalogue entry `comingSoon → playable` and add its tile art (close the
G23/… gap). **Still owed by nobody** (carried): the sleep-boundary /
`package:health` restoration (unbuilt across 07-11); `CapyNavBar` 98.7 vs 79.9;
`MeadowFooter` 2× grass (G19); `SceneHeader` flat top (G18); Alarms 3 / Add-Edit 8
Tier A failures. Android untested, no emulator.

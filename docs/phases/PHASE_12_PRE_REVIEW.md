# Phase 12 — Pre-review (adversarial, before any code)

Target: `PHASE_12_PLAN.md` draft 1. Read against the code it touches —
`RingingScreen` (`ringing_screen.dart`), `RingingHost`, `PuzzleSettings`,
`AlarmPuzzleOverride`, both mappers, `tool/import_art.dart`, the chooser, the
Add/Edit dismiss card and `game_rail.dart`.

**16 findings: 7 High, 6 Medium, 3 Low. All applied; none invalid.**

---

## High

### H1 — A game view in the ringing slot gets unbounded height

`RingingScreen` puts `puzzleSlot` inside a `SingleChildScrollView`
(`ringing_screen.dart:66`). A game field built with `LayoutBuilder`/`Expanded`,
the natural way to place a capybara "anywhere on the meadow", receives
`maxHeight: infinity` and asserts. Every view test that mounts the view in a bare
`MaterialApp` would pass.

**Applied:** both fields have a **fixed height** (Catch the Capy 280 pt, Memory
Hideout's card row sized by its cards); the spot grid is normalised against that
fixed box. A host test mounts each game **inside the real `RingingScreen`**.

### H2 — The planned bush asset fails the import guard

`tool/import_art.dart:146` reports `UNDER-RESOLVED` and exits 1 for any job whose
width is below `renderBoxPt × 3`. `bush_round.png` is 107 px. Draft 1 said "G29,
reported" — which, at any decor size, either fails the pipeline or needs the guard
relaxed. Relaxing it is the wrong fix.

**Applied:** a new `ArtUse.gameBush` render box of **32 pt** (restated at implementation from 35: trimmed to ink the file is 97 px, and the pipeline measures after trimming), so
the bush is drawn at the size the file supports and the guard stays untouched. The
tap card around it stays ≥ 88 pt. **G29 is reported in session** (a ≥ 288 px
plain-bush cutout would let the bush fill its card).

### H3 — Add/Edit's summary would claim a task count for a games-only alarm

`alarm_edit_screen.dart:280` renders "Medium · 2 tasks". `taskCount` is
puzzle-only (§2.4); an alarm set to "Catch the Capy only" would advertise two
tasks it never asks for, and say nothing about the game. A summary that misstates
what wakes you is the overpromise rule's quieter cousin.

**Applied:** the summary is built from the pool: difficulty, the task count
**only when puzzles are in the pool**, then each enabled game's name. Tested for
puzzles-only, mixed and games-only.

### H4 — Memory Hideout gives no feedback on a pick

Draft 1: a correct pick goes back to `revealing` at a new spot; a wrong pick goes
back to `revealing` at the same spot. **Both look identical**: a bush shows Capy
and a Ready button. Neither a sighted nor a screen-reader user learns whether the
pick was right — the game would read as broken.

**Applied:** the round carries the last outcome; the view shows and announces
(`liveRegion`) "Found Capy." or "Not there. Capy is behind bush {n}." Neutral
wording, no cheer, no taunt. +2 keys.

### H5 — The app-wide read path can throw too

Draft 1's §2.2 normalises the **override** read. `PuzzleSettingsMapper.fromJson`
has the same hole: `includePuzzles:false` with every stored game id unknown to
this build constructs `PuzzleSettings` with an empty pool and throws — on the
stream the ringing surface watches.

**Applied:** both mappers normalise: after dropping unknown ids, a pool that would
be empty restores puzzles (`includePuzzles: true`, or `null` on an override).
Tested for both.

### H6 — "The user's tolerance" must be the alarm's resolved tolerance

Draft 1 §5 says `settings.toleratedWrongAnswers` without saying which settings.
`RingingHost` holds both the app-wide stream and the alarm's override. Reading
the app-wide value would silently ignore a per-alarm tolerance — the Phase 06
defect (`escapeStrictness` read from defaults) in a new place.

**Applied:** the host resolves through `_renderableSettings(alarm)` for
difficulty, tolerance and the pool alike. A test sets an override tolerance
different from the default and proves the escape rises at the override's
threshold, for a game exactly as for a puzzle.

### H7 — The last catch can complete twice

A double tap on the final catch calls `onCompleted` twice. The controller's latch
holds, but the view and the round must not rely on it.

**Applied:** `catchCapy()`/`pick()` are no-ops once complete; each view reports
completion once. Tested with a double tap.

## Medium

### M1 — Practice seeds from the wall clock

Untestable as written. **Applied:** `practiceSeedProvider` (overridable), default
from `DateTime.now()`.

### M2 — `includePuzzles` must have a writer

Phase 10 shipped settings persisted since Phase 02 and written by no UI. **Applied:**
the chooser's "Puzzles" switch writes it; a test drives it through the controller
and reads it back from the repository.

### M3 — Spending `onboarding*` keys outside onboarding

`onboardingPracticeNote` says "Practice the **puzzle**…" — wrong for a game — and
keying the chooser to onboarding names couples two unrelated screens.
**Applied:** new `gameTryAction`, `gamePracticeNote`. The three onboarding strings
stay unused, as Phase 11 recorded.

### M4 — The chooser's task-count control reads as governing games

**Applied:** a caption under task count: "Applies to puzzles only." +1 key.

### M5 — Home and the rail tests change

Catch the Capy turns playable: its "Soon" badge goes and its label changes;
`game_rail_test` asserts `tile.memoryHideout` throws (G23). **Applied:** tests
updated to the new truth, the G23 test now asserts the substituted tile resolves,
and Home is **re-captured** to show the rail still measures as before.

### M6 — The pool's odds are unstated

Uniform per member: two games plus puzzles means puzzles one morning in three.
**Applied:** the chooser help says each alarm draws one at random; the selector
test pins uniform, order-independent membership.

## Low

### L1 — `screenReaderSolvable` defaulting to `false` is forgettable

**Applied:** a required parameter on all ten entries.

### L2 — A deep link to a non-playable game

**Applied:** the practice route renders the existing "not built yet" copy for an
unknown or non-launchable id; tested.

### L3 — Poster copy is Russian storyboard text

**Applied:** game copy is written fresh in ARB, calm and instructional; nothing
is transcribed from the posters' side panels.

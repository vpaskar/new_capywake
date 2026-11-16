# Current phase

**Phase 06 — Ringing and emergency stop: done, 2026-11-16. `Current phase: 07`.**

**1,372 tests**, analyze clean including infos, lib 97.63% / `lib/core` 99.49%
/ `lib/data` 88.95% / `lib/features/ringing` 94.67%, **405 ARB keys × 10
locales (zero new)**.

## What this phase actually found

### 1. The legacy has no dismiss-exactly-once guard — the defect this row is named after

`../capywake/lib/features/ringing/ringing_controller.dart:339` (`dismiss`) and
`:500` (`escape`) both open with `if (session == null) return;` and then await
twice before `_emit(null)` clears `_current`. The screen holds no busy flag
(grep finds only `_puzzleOpen`), and `test/features/ringing/` has no test for
a double call. **The previous project shipped it.**

### 2. A third duplicate-row path, found by this phase's own test

`AlarmScheduleService.targetForRing` returns the fire instant when a ring has
"no window left to belong to" — its own doc names **a snooze** as such a case.
Measured: a 07:00 Berlin alarm resolves `06:00Z` then `06:09Z`. So matching an
occurrence on `scheduledAt` alone created **a second row on every snooze
re-ring**, `snoozeCount` back at 0, silently defeating the cap and the
final-alarm boundary. The final-alarm test is what surfaced it.

### 3. The emergency escape threw instead of opening

Self-review #1. `RingingHost` sits in `MaterialApp.builder`, **above** the
router's Navigator, so `showModalBottomSheet` had no Navigator in context:
*in the app as wired, the escape did not work.* Every standalone screen test
passed, because they wrap `RingingScreen` in their own `MaterialApp`. Only the
host test — which rings an alarm into the live app — could see it.

Also: `escapeStrictness` was resolved from `PuzzleSettings.defaults()`,
discarding the user's app-wide settings, so *Confirm, then hold* was one tap.

### 4. The guard's test passed for the wrong reason — proven by mutation

Self-review #2. Disabling `_claim` left **all six "exactly once" tests green**
and failed only the ring test: with in-memory fakes the async window the latch
defends never opens. Fixed with an engine whose `cancel` blocks until the test
releases it; disabling the latch now fails **three** tests.

**Generalisable:** a guard whose test cannot fail when the guard is removed is
a guard on trust. Mutate it and see.

### 5. Twelve ported dartdoc references name the wrong phase

Full-project review. Phase 02 ported 62 files with dartdoc verbatim, carrying
the **legacy's** numbering: "settings UI (Phase 19)" where 19 is Release QA,
"wake surface (Phase 18)" where 18 is Animation polish, "lifecycle layer
(Phase 07)" where 07 is Settings. Five phases read past it. All now name the
**layer**, which cannot go stale when phases renumber.

### 6. `tool/capture.sh`'s DEBUG-banner detector was wrong

`r>140 and g<90 and b<90` called painted brown **(151, 92, 48)** a banner, so
the first screen whose art reaches the top-right corner failed its capture.
Flutter's ribbon is ~(244, 67, 54): **r−g ≈ 177 against the art's 63.**
Tightened on saturation and verified it still fires on a synthetic banner.

## Predictions, both restated

- **Tests:** registered 55–80 new, measured **93**. The scope grew for stated
  reasons after the band was set.
- **`lib` coverage:** registered a **fall** to 95.5–97.3%, measured a **rise**
  to 97.63%. The first measurement was 96.95% — inside the band. The two
  self-reviews' 18 extra tests lifted it past its own starting point. *A
  prediction made before the reviews cannot account for the reviews.*

## No Tier A claim for this screen

There is **no primary mockup** for ringing. The only reference is a board
panel — a ~333×467 px crop of a 1448×1086 board. Declared non-Tier-A in the
plan before measuring. Held instead to design tokens, the tap-target floor
measured with `tester.getRect`, and board **order and presence**; 6 deviations
named in `docs/visual/ringing/README.md`, including that **the board shows no
escape at all** and we ship one anyway.

## Next session — Phase 07, Settings

`04_SETTINGS.png` is a real Tier A mockup, so the fidelity contract applies in
full again. **Phase 07 owes two things from earlier phases:**

1. **`AlarmPermissionGate` is still called by nothing in `lib/`.** Phase 05
   said "Phase 06 or 07"; Phase 06 declined it with a reason (it fires on the
   alarm-enable path, not the ringing one). It is Phase 07's.
2. **The sleep-boundary restoration** — when `package:health` and
   `live_sleep_gateway.dart` land, `test/core/sleep/sleep_boundary_test.dart`
   goes back to `exactly one` importer and re-asserts
   `NSHealthShareUsageDescription` + `READ_SLEEP`.

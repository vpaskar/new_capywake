# Next session — start here

## State

Phases 00–06 are **done** and committed.

**Current phase: `07` — Settings, reliability checklist, walkthrough.**
`04_SETTINGS.png` is a **real Tier A mockup**, so the full fidelity contract
applies again — unlike Phase 06, which had no primary mockup at all.

**1,372 tests** pass. `lib` 97.63%, `lib/core` 99.49%, `lib/data` 88.95%,
`lib/features/ringing` 94.67%. **405 ARB keys × 10 locales.**

Home, Alarms and Add/Edit are built and captured. A saved alarm reaches the
platform (Phase 05) — **and as of Phase 06 a ringing alarm reaches a surface
the user can actually stop, including without solving the puzzle.**

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 06 found.
4. `docs/phases/PHASE_06_POST_REVIEW.md` — including what did **not** run.
5. `docs/visual/tier_a_blocks.md` and `docs/visual/asset_gaps.md` — append.

## What Phase 07 owes, from two earlier phases

1. **`AlarmPermissionGate` is still called by nothing in `lib/`.** Phase 05
   said "Phase 06 or 07 wires it". **Phase 06 declined it with a reason**
   (pre-review M3): the gate fires on the first transition leaving an alarm
   enabled — a save/enable event on the Alarms screen — so by the time an
   alarm rings the permission was granted or the alarm would not have fired.
   A prompt on the ringing path is a no-op at best and a modal over a ringing
   alarm at worst. **It belongs to the alarm-enable path and it is yours.**
2. **The sleep-boundary restoration.** When `package:health` and
   `live_sleep_gateway.dart` land, `test/core/sleep/sleep_boundary_test.dart`
   must go back to `exactly one` importer (it is `at most one` now) and
   re-assert `NSHealthShareUsageDescription` + `READ_SLEEP`.

## What Phase 06 leaves you

**The ringing surface is hosted in `MaterialApp.builder`, above the router.**
That is deliberate — a ring must cover a pushed Settings route too — and it
has a sharp edge you will hit if you touch it: **there is no root Navigator in
that context.** `RingingHost` supplies its own, and `showEscapeSheet` must
never pass `useRootNavigator: true`. Phase 06 shipped a version where the
emergency escape threw instead of opening for exactly this reason, and every
standalone screen test passed throughout.

**Seven of ten puzzle types have no renderer.** `RingingHost.renderableTypes`
restricts the enabled set to arithmetic / sequence-next / missing-operator;
`PuzzleView` **throws** on anything else rather than captioning it wrongly.
The puzzle chooser is Phase 10 — until then a puzzle alarm always shows a
puzzle that can be answered.

**Escape visibility is held on the occurrence, not the round.** A snooze
re-ring regenerates the round, which would reset `wrongThisRound` to zero and
demote the escape at the worst possible moment. `RingingController` keys it by
occurrence id.

**`AlarmEngine.ringNow` is called by nothing in `lib/`** — like
`AlarmScheduleCoordinator` was for three phases before Phase 05 noticed.
Recorded so it is inherited, not rediscovered. It exists for the post-dismiss
motion check, which has no phase row.

## The measurement rule, now with a fourth half

Phase 03: a row-mean detector cannot tell text from a layout edge — state the
method next to the number.

Phase 04: a method named beside a number is not enough if it ran against the
wrong artifact.

Phase 05: when a tool reports a failure, check whether the tool is wrong
before believing it about your code.

**Phase 06: a guard whose test cannot fail when the guard is removed is a
guard on trust.** Disabling `_claim` left all six "exactly once" tests green —
with in-memory fakes, the async window the latch defends never opens. **Mutate
the thing and see the test fail**, or you have tested nothing.

Phase 06 also hit Phase 05's rule again twice: `tool/capture.sh`'s
DEBUG-banner detector called painted brown a banner, and a "the tap gets
through" test was measuring its own bad coordinates.

## Owed, and honest gaps

- **Android is untested and has no emulator.** Never mark it tested.
- **An alarm was not watched ringing by hand.** Phase 06 drove the simulator
  but the `flutter run` session kept ending before the surface could be
  exercised interactively; the evidence is 93 tests against the real provider
  graph plus a **verified capture of the live ringing surface** taken by
  firing a ring into the running app. **Do not inherit this as "tested by
  hand".**
- **`check_bundle_size.dart` cannot see the three native plugins.** It
  measures `assets/` only and reads 95% of budget.

## Validation (every phase)

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build                                 # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales
dart run tool/check_bundle_size.dart                        # every asset tree
flutter test --coverage       # incl. art audit, manifest + comment budget
dart run tool/check_coverage.dart --path lib                # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
dart run tool/check_coverage.dart --min 85 --path lib/data  # data >= 85%
```

Read coverage from the `Coverage (...)` line, never from `PASS` alone — pipe
through `tr '\r' '\n'`.

## The simulator

**`flutter build ios --simulator` fails for a reason that is not ours**
(Xcode 27.2's `lipo` refuses two architectures; a stock `flutter create`
project fails identically). Use **`flutter run -d <udid>`** — and run it
somewhere that persists, not a backgrounded shell: the Xcode build outlives a
short-lived process and the app then launches with no Dart VM attached.

| Job | Device |
|---|---|
| Interaction, taps | iPhone 18 Pro, iOS 27.0 (`0B2FFE02-34B9-4C9A-9A86-61AE61F508E2`) |
| Tier A capture | iPhone 14 Pro via `tool/capture.sh` — 393×852 is the mockup geometry |

**Never measure Tier A on the 18 Pro** (it is 402×874).

`integration_test/capture_test.dart` now has a **ringing** case: the surface
has no route, so it fires a ring into the live provider graph.

## Standing reminders

- `../capywake` is **read-only** and was already dirty before the rebuild.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture.
- A finding is applied or invalid. Never deferred.
- `main` only. **No branches, no worktrees, no stashes.**
- The comment budget bites every new file. Trim by hand — the auto-fix cuts
  mid-sentence. **Never add a file to the baseline**; a file that improves must
  tighten its entry (`--update-baseline`, which may only shrink).
- **Name the layer, not the phase number**, in any doc comment. Phase 06 found
  12 ported references pointing at phases that mean something else here.
- Store publishing is drafts only.

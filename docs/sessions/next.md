# Next session — start here

## State

Phases 00–09 are **done** and committed.

**Current phase: `10` — Puzzle chooser and the ten existing puzzle types.**

**1,513 tests** pass. `lib` 97.84%, `lib/core` 99.61%, `lib/data` 88.95%,
`lib/features/onboarding` **100.00%**. **438 ARB keys × 10 locales.**

All five primary screens are built and captured. A saved alarm reaches the
platform, a ringing alarm reaches a surface the user can stop, permissions are
asked for when an alarm is first enabled, Stats renders nothing it cannot
measure, and a **fresh install now opens on a cozy onboarding welcome** that
hands off to the first-alarm screen.

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 09 found.
4. `docs/phases/PHASE_09_SELF_REVIEW_1.md` — **read this one.** A screen every
   test passed was broken on device; the fix is pinned by a test that fails
   against the bug.
5. `docs/visual/tier_a_blocks.md` and `docs/visual/asset_gaps.md` — append.

## What Phase 10 owes

1. **The sleep-boundary restoration — still owed, now three times over.**
   `package:health` and `live_sleep_gateway.dart` **did not land in Phase 07,
   08 or 09**, and each said so explicitly.
   `test/core/sleep/sleep_boundary_test.dart` is still at `at most one`
   importer with the negative invariant for `NSHealthShareUsageDescription`
   and `READ_SLEEP`. If the health path lands, restore `exactly one` and the
   positive assertions (`PHASE_02_SELF_REVIEW_1.md` F5). **If it does not, say
   so explicitly** — three phases have.

   The Sleep segment renders a permanent "sleep is not available yet" notice,
   and `sleepHistoryEmpty` ("Connect Health") sits unused in all 10 locales. A
   widget test asserts it is **not** rendered.

2. **The nine ported puzzle/strictness onboarding strings are unused on
   purpose** — Phase 09 shipped the welcome only, naming them out of scope as
   Phase 10's domain. `test/features/onboarding/onboarding_screen_test.dart`
   asserts the welcome does **not** render them, so a Phase 10 wiring is
   deliberate, not accidental. Phase 10 may now use `onboardingPuzzle*`,
   `onboardingStrictness*`, `onboardingArithmeticExample`, `onboardingTryGame`
   and the practice keys — they are already ported in 10 locales.

## What Phase 09 leaves you

**A screen every test passed can be broken on device.** The onboarding CTA
bounced to Home on the iPhone 18 Pro while the suite was green: a `go_router`
redirect pull-branch raced the CTA's own navigation, and the fake async clock
in widget tests ordered them the other way. **Run the screen on the device
before claiming an interaction works** — a widget test's clock is not the real
event loop. The fix is pinned by a test that fails against the buggy redirect
(reinstate it and watch it go red).

**A `go_router` redirect is read on every navigation.** A provider it reads
must never throw on a non-data state — `requireValue` on an errored stream is a
crash on the hot path (SR2 M1). Fold streams to a value only when **all** have
data.

**`routerProvider` now builds the app's router with a `Ref`.** A `ref`-less
`createRouter` runs **no** redirect — which is how every existing screen-test
harness stays green (it constructs `createRouter(initialLocation: …)` directly).
A new app-level test that needs the gate builds `CapyWakeApp` with a scope, or
passes a `ref`.

**There was no onboarding mockup, and that was said in the plan, not papered
over.** The `screens/alternative/onboarding_*` boards are superseded
explorations at device-bezel geometry. If a later phase is tempted to add
onboarding to `capture_test.dart`, don't — `compare.dart` `exit(2)`s on a
screen with no block table. `docs/visual/onboarding/README.md` says so.

## The measurement rule, now with a seventh entry

Phase 03: a row-mean detector cannot tell text from a layout edge.
Phase 04: a method named beside a number is not enough if it ran against the
wrong artifact.
Phase 05: when a tool reports a failure, check whether the tool is wrong
before believing it about your code.
Phase 06: a guard whose test cannot fail when the guard is removed is a guard
on trust.
Phase 07: a tool that cannot see a block will match it to one it can.
Phase 08: the tool and the code can both be right while the table between them
is wrong — and a gate that exists is not the same as a rule that holds.

**Phase 09: a widget test's fake async clock is not the device's event loop. A
flow that passes every test can bounce on the real device, and the only way to
know is to run it there.**

## Owed by nobody — carried forward

- **`CapyNavBar` is 98.7 pt against the mockup's 79.9**, and that single fact
  pushes **three** tabs' meadows up: every tab's grass ends at 694.3 while the
  pushed Settings route reaches 793.0. Phase 07 recorded this as three
  separate screen-local defects; Phase 08 measured it as one. Fixing it moves
  three screens, so it needs a phase that will measure all of them.
- **`MeadowFooter` paints ~2× the mockup's grass** (29.1 pt drawn vs 60.6
  painted) — `asset_gaps.md` **G19**. No Tier A block measures painted extent,
  which is why four phases shipped past it.
- **`SceneHeader` draws a flat-topped sheet; all five mockups draw a scalloped
  cloud** — **G18**. Costs Stats its title position (budget negative by
  1.35 pt).
- **Alarms fails 3 real Tier A blocks** (card 3 bottom +4.8, card 4 top +5.6,
  meadow +10.0) and **Add/Edit fails 8.** Phase 07's numbers, unchanged.
- **`AlarmEngine.ringNow` is still called by nothing in `lib/`.**
- **The Settings theme tiles have no art** — **G12**.
- **`check_bundle_size.dart` cannot see the three native plugins.** 95% of
  budget on `assets/` alone.
- **Android is untested and has no emulator. Never mark it tested.**
- **No control has been exercised by hand on a device since Phase 06.** The
  evidence is 1,493 tests and verified captures. Do not inherit this as
  "tested by hand".

## Validation (every phase)

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build                                 # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales
dart run tool/check_bundle_size.dart                        # every asset tree
dart run tool/check_no_fake_stats.dart                      # lib/features/
flutter test --coverage       # incl. art audit, manifest + comment budget
dart run tool/check_coverage.dart --path lib                # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
dart run tool/check_coverage.dart --min 85 --path lib/data  # data >= 85%
```

Read coverage from the `Coverage (...)` line, never from `PASS` alone — pipe
through `tr '\r' '\n'`.

## The simulator

**`flutter build ios --simulator` fails for a reason that is not ours**
(Xcode 27.2's `lipo`; a stock `flutter create` project fails identically).
Use **`flutter run -d <udid>`**, somewhere that persists.

| Job | Device |
|---|---|
| Interaction, taps | iPhone 18 Pro, iOS 27.0 (`0B2FFE02-34B9-4C9A-9A86-61AE61F508E2`) |
| Tier A capture | iPhone 14 Pro via `tool/capture.sh` — 393×852 is the mockup geometry |

**Never measure Tier A on the 18 Pro** (it is 402×874).

`integration_test/capture_test.dart` captures six screens: home, alarms,
add_edit_alarm, stats, settings, ringing.

## Standing reminders

- `../capywake` is **read-only** and was already dirty before the rebuild.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture — **and name the
  blocks it fails, not only the ones it passes** (Phase 07 full-project H1).
- A finding is applied or invalid. Never deferred.
- `main` only. **No branches, no worktrees, no stashes.**
- The comment budget bites every new file. Trim by hand — the auto-fix cuts
  mid-sentence. **Never add a file to the baseline**; it stands at **113** and
  Phase 08 added zero.
- **Name the layer, not the phase number**, in any doc comment.
  `grep -rn "Phase [0-9]" lib/` returns **0**.
- Store publishing is drafts only.

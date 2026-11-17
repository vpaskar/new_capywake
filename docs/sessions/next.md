# Next session — start here

## State

Phases 00–10 are **done** and committed.

**Current phase: `11` — Game foundation ("what a 'game' is in this codebase").**

**1,547 tests** pass. `lib` 97.93%, `lib/core` 99.61%, `lib/data` 88.95%,
`lib/features/puzzle` **99.30%**, `lib/features/onboarding` **100.00%**. **440
ARB keys × 10 locales.** Comment baseline **113** (+0).

All five primary screens are built and captured. A saved alarm reaches the
platform, a ringing alarm reaches a surface the user can stop, permissions are
asked for just-in-time, Stats renders nothing it cannot measure, onboarding is a
three-step flow, and — new in Phase 10 — **the user can finally configure the
wake puzzle** (types, difficulty, count, escape strictness, tolerance) from a
chooser pushed off Settings, from the onboarding strictness step, and per-alarm
in Add/Edit.

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 10 found.
4. `docs/phases/PHASE_10_SELF_REVIEW_1.md` — **read this one.** A control that
   could be handed a state it cannot display (a `holdToDismiss` alarm shown as
   Tap) is a latent correctness bug even when no current path produces that
   state. The dismiss section now names an unrepresentable method read-only.
5. `docs/visual/tier_a_blocks.md` and `docs/visual/asset_gaps.md` — append.

## What Phase 11 is

**Game foundation — what a "game" is in this codebase.** Phase 10 built the
puzzle CHOOSER and wired the ten existing puzzle TYPES (`lib/core/puzzle/`, which
were already ported and tested). Phase 11 begins the GAMES — the ten playable
mini-games that are Phases 11–17. Phase 11 is the **foundation**: the shared shape
every game slots into, not any specific game.

Read the legacy's game scaffolding in `../capywake` (READ-ONLY) for what a game
abstraction looked like, and the handoff's game posters in
`reference/01_REFERENCES/games/` and `reference/02_ASSETS/game_tiles/`.

## What Phase 10 leaves you

1. **Three ported onboarding strings are unused ON PURPOSE** —
   `onboardingTryGame` ("Try it"), `onboardingPracticeNote`,
   `onboardingPracticeRetry`. They were written for a *playable* practice puzzle
   (a live mini-game "Try it" button). Phase 10's onboarding "try" step is a
   **static** preview of three spoken examples (no `puzzle_generator` import).
   A playable onboarding demo is a games-phase concern, not the chooser's — so
   these three wait for a games phase that wants a live demo, or stay unused. No
   guard test asserts their absence (unlike Phase 09's); they are simply not
   referenced.

2. **A control that cannot represent a state it is handed is a latent bug.** The
   dismiss segment showed Tap for a `holdToDismiss` alarm (SR1 H1). No UI creates
   Hold today, but the enum/mapper/summary all carry it. If a games phase adds a
   new dismiss affordance, make its control honest for every `DismissMethod`.

3. **The onboarding completion path can throw.** `_complete()` wraps its writes;
   a games phase that adds a write to a flow's commit should do the same
   (`onboardingSaveError` exists for exactly this) — Phase 09's SR2, Phase 10's
   SR2, same shape.

4. **Device verification is not optional.** The stepped onboarding CTA was
   verified on the iPhone 18 Pro to land on Add Alarm, not Home. A games phase
   with any real interaction must run on the device before claiming it works — a
   green suite is not proof (Phase 09's central finding, re-confirmed here).

## The measurement rule, now with an eighth entry

Phase 03: a row-mean detector cannot tell text from a layout edge.
Phase 04: a method named beside a number is not enough if it ran against the
wrong artifact.
Phase 05: when a tool reports a failure, check whether the tool is wrong before
believing it about your code.
Phase 06: a guard whose test cannot fail when the guard is removed is a guard on
trust.
Phase 07: a tool that cannot see a block will match it to one it can.
Phase 08: the tool and the code can both be right while the table between them is
wrong — and a gate that exists is not the same as a rule that holds.
Phase 09: a widget test's fake async clock is not the device's event loop.

**Phase 10: a registered estimate that disagrees with measurement is restated,
not quietly shipped — the ARB count was +2 against a registered +10–14 because
the port was more complete than the plan or the pre-review assumed. And a control
that cannot represent a state it may be handed is a latent correctness bug, even
when no path produces that state today.**

## Owed by nobody — carried forward

- **The sleep-boundary restoration — still owed, now four times over.**
  `package:health` and `live_sleep_gateway.dart` did **not** land in 07, 08, 09
  or 10. `test/core/sleep/sleep_boundary_test.dart` stays at `at most one`
  importer. The Sleep segment renders a permanent "not available yet" notice.
- **`CapyNavBar` is 98.7 pt against the mockup's 79.9**, pushing three tabs'
  meadows up. One fact, three screens — needs a phase that measures all of them.
- **`MeadowFooter` paints ~2× the mockup's grass** — `asset_gaps.md` **G19**.
- **`SceneHeader` draws a flat-topped sheet; the mockups draw a cloud** — **G18**.
- **Alarms fails 3 Tier A blocks, Add/Edit fails 8.** Phase 07's numbers.
- **`AlarmEngine.ringNow` is still called by nothing in `lib/`.**
- **The Settings theme tiles have no art** — **G12**.
- **`check_bundle_size.dart` cannot see the three native plugins.**
- **Android is untested and has no emulator. Never mark it tested.**

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

**`flutter build ios --simulator` fails for a reason that is not ours** (Xcode
27.2's `lipo`; a stock `flutter create` project fails identically). Use **`flutter
run -d <udid>`** via the **Bash tool with `run_in_background: true`** (the
Terminal panel is blocked on an SSH passphrase prompt — do NOT use
`run_in_terminal` for `flutter run`). A `nohup ... &` in a foreground Bash call's
child keeps running even after the wrapper exits (the build continues); watch the
log for "Dart VM Service".

| Job | Device |
|---|---|
| Interaction, taps | iPhone 18 Pro, iOS 27.0 (`0B2FFE02-34B9-4C9A-9A86-61AE61F508E2`) |
| Tier A capture | iPhone 14 Pro via `tool/capture.sh` — 393×852 is the mockup geometry |

**Never measure Tier A on the 18 Pro** (it is 402×874). Attach the simulator
control panel BEFORE building. If writes fail silently, `xcrun simctl uninstall
0B2FFE02-34B9-4C9A-9A86-61AE61F508E2 com.capywake.capywake` then relaunch.

`integration_test/capture_test.dart` captures six screens: home, alarms,
add_edit_alarm, stats, settings, ringing. The chooser and onboarding are NOT in
it (no block table → `compare.dart` `exit(2)`s).

## Standing reminders

- `../capywake` is **read-only** and was already dirty before the rebuild.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture — and name the blocks
  it fails, not only the ones it passes.
- A finding is applied or invalid. Never deferred.
- `main` only. **No branches, no worktrees, no stashes.**
- The comment budget bites every new file (2 lines / 300 chars per block, a blank
  `///` separator counts as a line). Trim by hand. **Never add a file to the
  baseline**; it stands at **113** and Phase 10 added zero.
- **Name the layer, not the phase number**, in any doc comment.
  `grep -rn "Phase [0-9]" lib/ --include="*.dart"` excl. generated returns **0**.
- Store publishing is drafts only.

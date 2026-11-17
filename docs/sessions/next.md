# Next session — start here

## State

Phases 00–11 are **done** and committed.

**Current phase: `12` — Touch games I (Catch the Capy, Memory Hideout).**

**1,572 tests** pass. `lib` 97.95%, `lib/core` 99.61%, `lib/core/games`
**100.00%**, `lib/data` 88.95%, `lib/features/ringing` **98.53%**. **446 ARB keys
× 10 locales.** Comment baseline **113** (+0).

All five primary screens are built and captured. A saved alarm reaches the
platform, a ringing alarm reaches a surface the user can stop, permissions are
asked for just-in-time, Stats renders nothing it cannot measure, onboarding is a
three-step flow, the user can configure the wake puzzle, and — new in Phase 11 —
**the game foundation exists**: `GameChallenge` (headless), the `GameRingingView`
widget contract, and a `GameCatalogue` of all ten games (zero playable). **No game
is built yet** — Phase 11 is the contract, Phases 12–17 are the ten products.

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 11 built and found.
4. `docs/phases/PHASE_11_SELF_REVIEW_1.md` — **read this one.** A motion game's
   "fallback" could itself require motion and compile, defeating the a11y rule.
   Now asserted against. The foundation is where the ten games inherit their
   invariants, so a hole there is a hole in six phases.
5. `docs/phases/PHASE_11_SELF_REVIEW_2.md` — a game and a puzzle must offer the
   escape identically against the user's tolerance; a test pins it, Phase 12
   passes the setting in.
6. `docs/visual/tier_a_blocks.md` and `docs/visual/asset_gaps.md` — append.

## What Phase 12 is

**Touch games I — Catch the Capy, Memory Hideout. No new permissions.** The first
two REAL games, built on Phase 11's contract. Each is a `GameRingingView` subclass
driving a `GameChallenge`. Read `reference/01_REFERENCES/games/posters/` (04 Catch
the Capy, 06 Memory Hideout) and the four tiles in `reference/02_ASSETS/game_tiles/`.

## How a game plugs into the foundation (Phase 11's contract)

- **`GameChallenge`** (`lib/core/games/game_challenge.dart`) is the headless
  state: `target`/`completed`/`isComplete`, `struggleCount`, and
  `escapeVisibilityFor({toleratedStruggles})`. A game updates it each interaction.
- **`GameRingingView`** (`lib/features/ringing/game_ringing_view.dart`) is the
  widget contract: `onProgress(challenge)` (the host raises the escape when
  struggle crosses tolerance) and `onCompleted()` (the host dismisses). It also
  takes `reduceMotion`, supplied by **`GameRingingSlot`** from
  `MediaQuery.disableAnimations` — honor it.
- **The escape is NOT yours.** `RingingScreen` owns and renders it; a game never
  hides, gates, or draws the escape. Just signal via `onProgress`.
- **Pass the user's setting in.** The escape policy is the user's: a game-launch
  path must call `escapeVisibilityFor(toleratedStruggles: settings.toleratedWrongAnswers)`,
  not a hard-coded tolerance (SR2 M1 — a test proves games and puzzles agree; it
  fails if you diverge).
- **Flip the catalogue + add art.** Set the entry `comingSoon → playable` and add
  its tile art (closing the G23/… gap). The `homeRail` subset stays four unless
  `01_HOME.png` changes.
- **A motion game (Phase 15, not 12)** must use `GameChallenge.motion(fallback:)`
  with a non-motion fallback. Touch games (12) are `.touch`, no fallback.

## What Phase 11 leaves you

1. **No game is wired to a live alarm.** Phase 11 is the contract; the ringing
   host still launches only `PuzzleView` for `DismissMethod.puzzle`. Phase 12
   adds the first real game-launch path.
2. **The three onboarding strings stay unused** (`onboardingTryGame`, …) — a
   playable onboarding demo was deferred from the foundation (pre-review H3). A
   games phase may spend them on a live demo, deliberately.
3. **Device verification is not optional.** Phase 11 confirmed on the iPhone 18
   Pro that Home draws four tiles (not ten) and the blocked sheet renders. A
   games phase ships real interaction — RUN THE GAME on the device before claiming
   it works. A green suite is not proof (Phase 09's central finding).

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
Phase 10: a registered estimate that disagrees with measurement is restated, not
quietly shipped; and a control that cannot represent a state it may be handed is a
latent correctness bug, even when no path produces that state today.

**Phase 11: an invariant that a later pass can defeat is not yet enforced — a
motion game's required fallback could itself require motion and compile, so "the
fallback is required" was true while "a non-motion path exists" was not. The
foundation is the one place the ten games inherit their invariants, so a hole
there is a hole in six phases. And a review's own earlier finding is still subject
to the later review: the pre-review's L1 ("See All" is dangling) was wrong, and
the full-project pass caught it against `PHASE_03_PLAN.md`.**

## Owed by nobody — carried forward

- **The sleep-boundary restoration — still owed, now five times over.**
  `package:health` and `live_sleep_gateway.dart` did **not** land in 07, 08, 09,
  10 or 11. `test/core/sleep/sleep_boundary_test.dart` stays at `at most one`
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

# Next session — start here

> **Phase 15 done (2026-11-18, unattended).** The pointer is `16` — **Capy
> Step Quest, which is BLOCKED**: it needs a step-count permission
> (ACTIVITY_RECOGNITION / Motion & Fitness), a store-visible owner decision.
> Phase 17 (QR Treasure Hunt) needs a camera dependency, also the owner's call.
> **Do not start either without the owner's answer.** If the owner wants to
> skip ahead to Phase 18 (animation and visual polish), the tracker must be
> re-pointed by the owner — never by a session.

## State

Phases 00–15 are **done** and committed.

**Current phase: `16` — blocked on the owner.**

**2,133 tests** pass. `lib` 98.55%, `lib/core` 99.72%, `lib/core/games`,
`lib/features/games`, `lib/core/motion` and `lib/data/motion` **100%**,
`lib/data` 89.31%, `lib/features/ringing` 98.71%. **557 ARB keys × 10
locales.** Comment baseline **113**.

Eight games are playable, including the two motion games. **Read
`docs/sessions/OPEN_QUESTIONS.md` first** — ten owner questions are open; three
are new (buttons always work in the motion games; the iOS motion purpose
string; shake/tilt thresholds never felt on a phone).

## Read in this order

1. `CLAUDE.md` — note the **"Games are dynamic"** rule (owner, Phase 12) and the
   narrowed animation rule (ringing chrome only).
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol.
3. `memory/current-phase.md` — the selection model and what Phase 12 found.
4. `docs/phases/PHASE_12_PLAN.md` §12 — the owner's mid-phase directions.
5. `docs/phases/PHASE_12_FULL_PROJECT_REVIEW.md` — the two cross-app defects.
6. `docs/visual/asset_gaps.md` — G29–G32 closed by owner art; how sprite sheets
   were validated and imported.
7. `docs/phases/PHASE_14_POST_REVIEW.md` — `DriftingGrid`, why a motion must
   not point at the answer, and the art the authored games still lack (G37,
   G38).
8. `docs/phases/PHASE_15_POST_REVIEW.md` — the accelerometer, why the fallback
   is always on screen, and the three ways tilt was read wrongly.

## How a game plugs in now (Phase 11 contract + Phase 12 model)

- Headless round in `lib/core/games/` (pure Dart, 100%): goal, struggle, seeded.
- View: a `GameRingingView` subclass with `seed` + `difficulty`, built only via
  `GameRegistry.builders` from a `GameLaunch`. Wrap it in a `CapyCard`; give it a
  **fixed height** (the ringing slot scrolls). Report completion once.
- Flip the catalogue entry to `playable`, set `screenReaderSolvable` honestly,
  add the registry line — `game_registry_test` pins the two equal.
- Motion: required (owner). Stop it under `widget.reduceMotion` **and**
  `MediaQuery.accessibleNavigationOf`, and keep the game finishable there.
  Scale speed with difficulty, catchable half-asleep. A continuously animating
  game needs a short idle beat or tests must `pump(duration)` explicitly.
- Escape: never yours. Struggle → `onProgress`; the host compares against the
  **alarm's resolved** tolerance.
- Copy: keep the puzzle and game vocabularies apart in all ten locales — the
  vocabulary guard fails otherwise.
- Art: never generated. Report every gap in session, then log it.
- **Still mode is re-read every build** (`didChangeDependencies`), never once:
  VoiceOver turned on mid-game must stop motion and show what was hidden.
- **Results go in `GameOutcomeLine`** (live region, two measured lines
  reserved); nothing that changes per phase may change height above the
  controls — `IndexedStack` the variants or put them on a fixed field.
  `GameHeader` progress is a live region already.
- **Card height ≤ 424 pt** (Catch the Capy's). `ringing_host_game_test`'s clock
  guard fails otherwise: at 393×852 + 47 pt inset the card must clear the
  clock; at 375×667 nothing may reach higher than Catch the Capy.
- **Size sprites from the decoded file.** The win poses are 205–246 px: sharp
  only to ~72 pt.
- Add the game to `capture_test.dart`'s list and teach `_win` to play it.
- **A grid that moves:** `DriftingGrid` (Phase 14) — `swap` trades two
  unresolved cards, `carousel` steps every card round a two-row ring. Pick the
  one whose motion does not point at the answer (a find-the-odd-one game must
  carousel). No beat while a finger is down anywhere on the grid; still snaps
  every card home. Rest ≥ 2.6 s at medium when cards carry words.
- **Authored banks** (Morning Sort, Find the Impostor only): an enum in
  `lib/core/games/` + one ARB key per entry in all ten locales; a pose label is
  the screen-reader answer key — written against the picture.
- **Motion** (Phase 15): `GameLaunch.motion`; `ShakeDetector`, `TiltReader`
  (first grip is level; `suppressUntilLevel()` after a press, never a new
  baseline on a tilted grip). The non-motion control is always live.
- **`GameOutcomeLine(reserveFor:)`** — every result the game can show.
- **Never a `CapyButton` inside a game** — Snooze is one, right below.

## The measurement rule, now with a ninth entry

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

**Phase 15: a guard you have not watched fail is a guard on trust — four were,
two of them because of how the test pumped or played, not the code.** And a
reviewer who was not told the author's reasoning found the defect the author's
two passes reasoned past (letting go of a tilt read as the reverse).

**Phase 14: a test that reads the screen in the same pump that changed it reads
the old frame.** One `pump(every * 3)` fires the timer, but the frame it builds
only starts the slide — the H3/H5 drift guards passed with the guards deleted.
Pump rest and slide per beat, then prove the test fails without the guard. And
a test cell that does not hit-test never receives the finger it claims to hold.

**Phase 13: a guard measured on a surface the user never sees is a guard on
trust.** The clock guard passed at zero status-bar inset while a real capture
showed the card over the clock; it now runs at the device's inset and was
proven to fail. And a size read off a sheet goes stale when the art is
replaced — decode the bundled file.

**Phase 12: a layout box is not what is painted.** Settings' title painted over
its value for five phases while every rect-overlap check would have passed —
measure glyphs, not boxes. And a capture can race image decoding: an empty card
in a screenshot was the harness, not the app (pre-cache before capturing).

## Owed by nobody — carried forward

- **The device ring check is manual:** `flutter test
  integration_test/ring_lifecycle_test.dart -d <iPhone 14 Pro udid>` after any
  change to `lib/data/engine/` or the ringing controller. Every widget test uses
  the fake engine, which cannot see the plugin silence a ring (it did, from the
  engine's first phase until 2026-11-18).
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

`integration_test/capture_test.dart` captures six screens plus every game's ring and win (eight games): home, alarms,
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

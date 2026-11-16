# Next session — start here

## State

Phases 00–03 are **done** and committed.

**Current phase: `04` — Alarms list and Add/Edit (`02_ALARMS.png`,
`03_ADD_EDIT_ALARM.png`).**

1,116 tests pass. `lib` 97.38%, `lib/core` 99.41%, `lib/data` 86.40%. 395 ARB
keys × 10 locales. Home is built, captured and its deviations are named.

## Read in this order

1. `CLAUDE.md` — the project's rules. **Two sections are new in Phase 03**:
   "Measuring a block" and "Running the app on the simulator".
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 03 found, which is mostly about
   earlier phases being wrong in writing.
4. `docs/phases/PHASE_03_FULL_PROJECT_REVIEW.md` — the five project-level
   findings, one of which Phase 04 has to decide (P4).
5. `docs/visual/tier_a_blocks.md` — **the corrected block table**.
6. `docs/visual/asset_gaps.md` — append, never restart.

## What Phase 04 inherits that Phase 03 did not have

**The capture actually measures something now.** `compare.dart` reported 4 of
13 documented blocks before this phase; it reports 14. If your screen's blocks
pass, that means something.

**`SceneHeader` is fixed.** Every screen's hero band was 11.1 pt short. If you
had built Alarms against the old one, every block below the hero would have
been displaced and the cause would have looked like your layout.

**`bootstrap()` exists and is called.** Nothing in `lib/` initialized `intl`
before Phase 03; any screen rendering a clock time would have thrown.

**The comment budget is enforced** (2 lines / 300 chars, inside `flutter
test`). New files must meet it outright. Do not add a file to the baseline to
silence it; long rationale goes in `docs/phases/`.

## Measuring blocks — the rule that cost Phase 03 three wrong rows

A row-mean luminance detector **cannot tell a line of text from a layout
edge**. Three rows of Phase 03's plan were glyph edges, and a fourth value was
inferred arithmetically from two of them and came out 27% wrong.

- Between two flat areas → the detector is fine.
- Adjacent to text, or between textured regions → **read a crop** and
  cross-check against something the detector cannot confuse (Phase 03 used the
  My Stats row's orange icon; the tiles were found by saturation scan).
- **State the method next to the number.** An inference is not a measurement.
- Measure what a widget *renders* (`tester.getRect`), not the constant you
  gave it. Phase 03's next-alarm card was built at 167 pt against a mockup's
  65 because nobody measured the rendered box.

## One decision left for Phase 04

`compare.dart`'s `_nearest` snaps each reference block to the closest detected
edge, so a displaced layout matches several blocks to one edge and overstates
the damage. Phase 03 **recorded this and did not change it** — tuning the
matcher while 13 blocks were red would be fitting the instrument to the result.

Decide it on a screen that passes. See full-project review P4.

## Palette constraint F1 — settled by the owner

**"Do as in the mockups."** Do not retune tokens to chase a contrast ratio;
`test/design/tokens_contrast_test.dart` asserts the current weakness
deliberately. Design around it: in light mode no control may use `accent`,
`accentDeep`, `success` or `grass` as its **only** channel for boundary or
state. Accent as a fill under `cocoa` text is the preferred pattern.

Where the mockup and an accessibility minimum genuinely cannot both hold,
follow the mockup for the colour, carry the redundant channel in structure,
and **record the pair with its measured ratio** in the post-review. Phase 03
did this once — the Step Quest ring, green 2.68:1 in the mockup, drawn in
`cocoa` 11.8:1 — and named it as a deviation.

## Running the app — you can, so do

An **iPhone 14 Pro simulator** is available at exactly the mockup geometry
(1179×2556 px = 393×852 pt).

| Want | Use |
|---|---|
| A verified PNG for `docs/visual/<screen>/` | `tool/capture.sh <screen>` |
| To drive the app — tap, scroll, screenshot | the iOS-simulator tools |

`tool/capture.sh` verifies the artifact rather than trusting an exit code, and
is the **only** acceptable Tier A evidence. **Never** run
`integration_test/capture_test.dart` with `flutter test` — it passes while
writing nothing.

Captures are taken against a **seeded** in-memory database (`captureSeed` in
the integration test) so screens are comparable to the mockups; the app's own
default is the empty state, and demo data never enters `lib/`.

**No Android emulator on this machine.** Never mark Android tested.

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

Read coverage from the `Coverage (...)` line, never from `PASS` alone — the
build-hooks preamble shares stdout, so pipe through `tr '\r' '\n'`.

## Reference paths

| What | Where |
|---|---|
| Master brief | `reference/00_AGENT_MASTER_PROMPT.md` |
| Mockups (source of truth) | `reference/01_REFERENCES/screens/primary/` |
| Hero scenes | `reference/02_ASSETS/header_scenes/*_integrated.png` |
| Mascots | `reference/02_ASSETS/asset_library/mascots/` + `mascot_fixes/` |
| Legacy (READ-ONLY) | `../capywake` |

`reference/` is reference material, never bundled (348 MB, git-ignored).

## Standing reminders

- `../capywake` is **read-only** and was already dirty before the rebuild —
  compare `git status --porcelain` to the baseline in `PHASE_02_PLAN.md`.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture.
- A finding is applied or invalid. Never deferred.
- `main` only. **No branches, no worktrees, no stashes** — Phase 03 used a
  stash while diagnosing and recorded it as a violation (self-review #1 F5).
- Store publishing is drafts only; the owner presses every final button.

## Owed restorations

**Phase 07/08** — when `package:health` and `live_sleep_gateway.dart` land,
`test/core/sleep/sleep_boundary_test.dart` must go back to `exactly one`
importer and re-assert `NSHealthShareUsageDescription` + `READ_SLEEP` are
present.

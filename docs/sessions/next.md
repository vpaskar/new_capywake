# Next session — start here

## State

Phases 00–08 are **done** and committed.

**Current phase: `09` — Onboarding.** Just-in-time permissions.

**1,493 tests** pass. `lib` 97.85%, `lib/core` 99.61%, `lib/data` 88.95%,
`lib/features/stats` **100.00%**. **437 ARB keys × 10 locales.**

All five primary screens are built and captured. A saved alarm reaches the
platform, a ringing alarm reaches a surface the user can stop, permissions are
asked for when an alarm is first enabled, and Stats renders **nothing it
cannot measure**.

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 08 found.
4. `docs/phases/PHASE_08_FULL_PROJECT_REVIEW.md` — **read this one.** A gate
   that exists is not the same as a rule that holds.
5. `docs/visual/tier_a_blocks.md` and `docs/visual/asset_gaps.md` — append.

## What Phase 09 owes

1. **The sleep-boundary restoration — still owed, now twice over.**
   `package:health` and `live_sleep_gateway.dart` **did not land in Phase 07
   or Phase 08**, and both said so explicitly rather than leaving it
   ambiguous. `test/core/sleep/sleep_boundary_test.dart` is still at `at most
   one` importer with the negative invariant for
   `NSHealthShareUsageDescription` and `READ_SLEEP`. If the health path lands,
   restore `exactly one` and the positive assertions
   (`PHASE_02_SELF_REVIEW_1.md` F5). **If it does not, say so explicitly.**

   **It now has a user-visible cost.** The Sleep segment renders a permanent
   "sleep is not available yet" notice, and `sleepHistoryEmpty` — which says
   *"Connect Health"* — sits unused in all 10 locales waiting for the phase
   that builds the control. A widget test asserts it is **not** rendered.

2. **Nothing else is owed by a specific phase.** Phase 08 discharged the gate
   and the hero band. What remains is listed under "Owed by nobody" below.

## What Phase 08 leaves you

**The gate is real, and so are its blind spots.**
`dart run tool/check_no_fake_stats.dart` scans all of `lib/features/` and is
in both validation blocks. It catches a bare number in `Text()`, a numeric
`value:`/`label:`, and figures like `'7 h 32 m'` / `'94%'`.

**It is blind to a `??` fallback, a provider default, and arithmetic over
constants — measured, not assumed.** A planted numeric `?? 6` passes it
completely; only the widget test fails. If you add a screen that shows
numbers, the gate is half the protection and a test asserting the empty token
is the other half. `test/style/check_no_fake_stats_test.dart` asserts the
blind spots so they cannot be quietly forgotten.

**A block's name and its value must describe the same edge.** Phase 08's table
said `segment track bottom` and held the *pill's* 280.3. `compare.dart` finds
the *track's* border, 3 pt outside, and printed `+4.4 TIER A FAIL` for a pill
**0.2 pt** from its mark. On a control with a selected state, the detector
finds the container, not the selection.

**Declare which blocks you claim, and do not claim what your own state cannot
render.** Phase 08's plan claimed 13 and had already specified a default that
cannot reach 8 of them. Cut to 5 in pre-review; the other 8 keep their
measured mockup values in `tier_a_blocks.md` for whoever builds the filled
state.

**`compare.dart` reads whatever `actual.png` is on disk, without checking its
age.** Phase 08's committed capture was **Phase 03's**. Run the capture before
the final review passes and record the mtime.

## The measurement rule, now with a sixth half

Phase 03: a row-mean detector cannot tell text from a layout edge.
Phase 04: a method named beside a number is not enough if it ran against the
wrong artifact.
Phase 05: when a tool reports a failure, check whether the tool is wrong
before believing it about your code.
Phase 06: a guard whose test cannot fail when the guard is removed is a guard
on trust.
Phase 07: a tool that cannot see a block will match it to one it can.

**Phase 08: the tool and the code can both be right while the table between
them is wrong.** And its corollary — **a gate that exists is not the same as a
rule that holds**; the only way to tell was to mutate it and count.

Also: **a method validated on two screens is validated for those two.** The
green-collapse hero-edge method reproduces Settings (213.1 vs 212.9) and
Alarms (252.4 vs 252.5) and produces **nothing** on Stats, whose cream is a
scalloped cloud rather than a rounded rectangle.

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

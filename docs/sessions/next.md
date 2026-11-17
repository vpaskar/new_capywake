# Next session — start here

## State

Phases 00–07 are **done** and committed.

**Current phase: `08` — Stats.** `05_STATS.png` is a real Tier A mockup.

**1,452 tests** pass. `lib` 97.80%, `lib/core` 99.61%, `lib/data` 88.95%,
`lib/features/settings` 98.49%. **427 ARB keys × 10 locales.**

Home, Alarms, Add/Edit and Settings are built and captured. A saved alarm
reaches the platform, a ringing alarm reaches a surface the user can stop, and
as of Phase 07 the permissions an alarm needs are asked for **at the moment
one is first enabled** — never on app start.

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 07 found.
4. `docs/phases/PHASE_07_FULL_PROJECT_REVIEW.md` — **read this one.** Three
   screens fail their own Tier A tables and two phases reported only the
   blocks they passed.
5. `docs/visual/tier_a_blocks.md` and `docs/visual/asset_gaps.md` — append.

## What Phase 08 owes

1. **The sleep-boundary restoration.** `package:health` and
   `live_sleep_gateway.dart` **did not land in Phase 07** — Settings has no
   sleep row. `test/core/sleep/sleep_boundary_test.dart` is still at `at most
   one` importer with the negative invariant for
   `NSHealthShareUsageDescription` and `READ_SLEEP`. If the health path lands
   with Stats, restore `exactly one` and the positive assertions
   (`PHASE_02_SELF_REVIEW_1.md` F5). **If it does not land, say so
   explicitly** — Phase 07 did, rather than leaving it ambiguous.
2. **`tool/check_no_fake_stats.dart` has never existed.** `CLAUDE.md` claimed
   it enforced "no numeric literal in a user-facing position in
   `lib/features/stats/`" — on the screen `CLAUDE.md` itself calls the one
   most likely to lie. The line now says the rule is prose. **Writing the gate
   is Phase 08's**, and it is the phase that can actually test it.
3. **Stats still carries Home's hero band.** `stats_screen.dart:12` says so in
   as many words: *"Phase 08 measures this from `05_STATS.png`; Home's 188.4
   until then."* Four screens now have four different bands (188.4 / 148.6 /
   112.1 / 109.0) and five different meadows.

## What Phase 07 leaves you

**`CapyToggle.trackSize` is required.** Four mockups draw four toggles
(59.6 / 54.0 / 48.0 / 44.3 wide). If Stats has one, measure it — do not reach
for `homeTrack`.

**`compare.dart` is fixed but its block table is per-screen.** Add a `settings`
-style entry for `stats` or it `exit(2)`s; `_topInsetPt` reads
`docs/visual/stats/inset.txt`, which only `tool/capture.sh` writes. **Run the
capture before the final review passes**, not after.

**Only claim the blocks you can defend.** Phase 07 declared *before* capturing
which blocks it would claim, because its row cuts move everything below
Appearance. Stats' empty state is the default, so its block positions depend
on what it renders with no data — decide and declare that first.

**The tap floor can outrank the mockup.** Settings' rows are 44.0 pt against a
mockup's 41.1, and group 1 is +4.5 pt as a consequence. That is a declared
rule conflict, not a defect. If Stats' mockup draws rows under 44 pt, the same
applies — and the arithmetic goes in `docs/visual/stats/README.md`.

## The measurement rule, now with a fifth half

Phase 03: a row-mean detector cannot tell text from a layout edge.

Phase 04: a method named beside a number is not enough if it ran against the
wrong artifact.

Phase 05: when a tool reports a failure, check whether the tool is wrong
before believing it about your code.

Phase 06: a guard whose test cannot fail when the guard is removed is a guard
on trust.

**Phase 07: a tool that cannot see a block will match it to one it can.**
`compare.dart` searched ±40 pt, found the card's own edge undetected, and
printed "−18.7 TIER A FAIL" for a card 2.7 pt from its mark. `absent` is the
honest answer and still counts as a failure. **It also hit Phase 06's rule:**
nine of ten permission-gate tests passed with the gate deleted, because a
second rule was quietly covering for the first.

## Owed, and honest gaps

- **Alarms fails 3 real Tier A blocks** (card 3 bottom +4.8, card 4 top +5.6,
  meadow +10.0) and **Add/Edit fails 8.** Recorded in Phase 07's full-project
  review with numbers; **not fixed there**, because another phase's screen is
  not a phase's to change blind. Home's 6 failures are all `absent` — its
  worst *measured* delta is 1.4 pt and its layout is fine.
- **Android is untested and has no emulator.** Never mark it tested.
- **No control was exercised by hand on a device in Phase 07.** The evidence
  is 80 tests against the real provider graph plus a verified capture. Do not
  inherit this as "tested by hand".
- **`AlarmEngine.ringNow` is still called by nothing in `lib/`.** Now
  user-visible: Settings can set the motion-check kill switch and the motion
  layer that reads it does not exist.
- **`check_bundle_size.dart` cannot see the three native plugins.** It
  measures `assets/` only, at 95% of budget.
- **The Settings theme tiles have no art** — `asset_gaps.md` **G12**. Drawn
  from palette tokens.

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
(Xcode 27.2's `lipo`; a stock `flutter create` project fails identically).
Use **`flutter run -d <udid>`**, somewhere that persists.

| Job | Device |
|---|---|
| Interaction, taps | iPhone 18 Pro, iOS 27.0 (`0B2FFE02-34B9-4C9A-9A86-61AE61F508E2`) |
| Tier A capture | iPhone 14 Pro via `tool/capture.sh` — 393×852 is the mockup geometry |

**Never measure Tier A on the 18 Pro** (it is 402×874).

`integration_test/capture_test.dart` now captures six screens: home, alarms,
add_edit_alarm, stats, **settings**, ringing.

## Standing reminders

- `../capywake` is **read-only** and was already dirty before the rebuild.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture — **and name the
  blocks it fails, not only the ones it passes** (Phase 07 full-project H1).
- A finding is applied or invalid. Never deferred.
- `main` only. **No branches, no worktrees, no stashes.**
- The comment budget bites every new file. Trim by hand — the auto-fix cuts
  mid-sentence. **Never add a file to the baseline**; a file that improves
  must tighten its entry (`--update-baseline`, which may only shrink).
- **Name the layer, not the phase number**, in any doc comment. Phase 06 fixed
  12 stale references; Phase 07 found **19 more**.
- Store publishing is drafts only.

# Next session — start here

## State

Phases 00–04 are **done** and committed.

**Current phase: `05` — Alarm engine and reliability.** Device test required.

**1,189 tests** pass. `lib` 97.54%, `lib/core` 99.41%, `lib/data` 86.40%.
**399 ARB keys × 10 locales.** Home, Alarms and Add/Edit are built, captured
and their deviations named.

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 04 found.
4. `docs/phases/PHASE_04_FULL_PROJECT_REVIEW.md` — six project-level findings,
   one of which (P6) Phase 05 owns.
5. `docs/visual/tier_a_blocks.md` — now carries Alarms and Add/Edit.
6. `docs/visual/asset_gaps.md` — append, never restart.

## Do this before anything else: fix the simulator build

**`flutter build ios --simulator --debug` fails on this machine** with an
opaque `Uncategorized (Xcode): Exited with status code 255`. Taps sent to the
booted simulator through the control tools did not reach the app either.

`flutter drive` — which `tool/capture.sh` uses — builds and runs the same app
fine, which is why all four captures are verified. **But Phase 05 is the alarm
engine, and `CLAUDE.md` says it needs a device test.** You cannot confirm an
alarm fires from a widget test.

Phase 04 did **not** work around this and did **not** claim any control was
exercised by hand. Do not inherit the claim; fix the path.

## What Phase 04 leaves you

**`SceneHeader.bandHeight` is now required**, because its 188.4 default was
Home's measurement and two screens inherited it silently. Stats still carries
Home's number with a comment saying Phase 08 must measure it. **Assume no
shared default is right for your screen until you have measured it** — this
has now caught three phases.

**`compare.dart` sees card hairlines**, including dimmed ones at 55% opacity.
Its probe column is hardcoded at x=360 pt, text-free on Alarms by measurement
and on Add/Edit by luck. A screen with content there will mis-detect; the
honest fix is per-screen probe columns in the block table.

**`AlarmFormat.timeParts` exists** and returns the digits and the AM/PM marker
separately, for any surface that styles them differently. The ringing screen
will want it.

**The capture driver no longer dumps PNG bytes into `docs/visual/`.** It was
writing every `reportData` key, and the framework's own `screenshots` key
holds every image — 18.8 MB of it reached the Phase 03 commit. Fixed; the
bytes are still in that history object, which no phase has been asked to
rewrite.

**`MeadowFooter` takes a `height`** (Home's 65.2 is the default, Alarms 52.2,
Add/Edit 59.1).

**The comment budget is enforced** and bites often — two lines / 300 chars per
block, and it caught this phase four times. Long rationale goes in
`docs/phases/`, never in the code.

## The measurement rule, now with a second half

Phase 03: a row-mean detector cannot tell a line of text from a layout edge —
read a crop, anchor to a colour, **state the method next to the number**.

Phase 04 adds: **a method named beside a number is not enough if the method
ran against the wrong artifact.** This phase's own pre-review wrote
"meadow starts ~780" with its method named; 780.5 was where the *Alarms*
meadow ends, carried across and never re-derived. Re-derive the number for the
thing you are naming.

And: **when the instrument says a block is absent, check whether it can see
that class of block at all** before believing the layout is wrong.

## Tier A state

| Screen | Worst | Outside ±4 |
|---|---|---|
| Home | 29.5 | 8 |
| Alarms | 21.6 | 5 |
| Add/Edit | 31.1 | 9 |

Alarms is close (hero −0.2, cards 1–3 within 3.6, pitch 102.3 against 102.1);
its remaining `absent` rows are the fourth card below the fold, which the
mockup cannot show. **Add/Edit is the weaker screen**: its anchor is right and
its card *contents* are taller than the mockup's, so error accumulates down the
form. Closing it needs per-card measurement inside `CapyCard`, shared with
Home — a deliberate change, not an end-of-phase tweak.

## Palette constraint F1 — settled by the owner

**"Do as in the mockups."** No token is retuned;
`test/design/tokens_contrast_test.dart` asserts the current weakness. Design
around it: in light mode no control may use `accent`, `accentDeep`, `success`
or `grass` as its **only** channel. Accent fill under `cocoa` text is the
preferred pattern — Phase 04's Add pill and selected chips both use it, and the
chips carry a weight change as a second channel.

## Controls smaller than 44 pt

Three of Phase 04's controls are under the reachable minimum in the mockup
(chevrons 19.4, chips 31.8, Add pill 36.9). The resolution is **paint the
mockup's size, grow only the hit region** — the split `CapyToggle` introduced.
Both halves are asserted. Use it again rather than re-deciding.

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

Captures: `tool/capture.sh` (default list is now
`home alarms add_edit_alarm stats`). **Never** run
`integration_test/capture_test.dart` with `flutter test`. The seed is four
alarms matching `02_ALARMS.png`, two of them disabled.

## Standing reminders

- `../capywake` is **read-only** and was already dirty before the rebuild.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture.
- Never mark Android tested — there is no emulator on this machine.
- A finding is applied or invalid. Never deferred.
- `main` only. **No branches, no worktrees, no stashes.**
- Store publishing is drafts only.

## Owed restorations

**Phase 07/08** — when `package:health` and `live_sleep_gateway.dart` land,
`test/core/sleep/sleep_boundary_test.dart` must go back to `exactly one`
importer and re-assert `NSHealthShareUsageDescription` + `READ_SLEEP` are
present.

# Phase 01 — post-review

Written after implementation, the two phase self-reviews and the full-project
review. Records what the phase actually produced, what it got wrong on the way,
and what it is handing Phase 02.

## The gate

**Met.** `tool/capture.sh` writes `docs/visual/{shell,alarms,stats}/actual.png`
from the iPhone 14 Pro simulator at **1179×2556 px = 393×852 pt**, and verifies
each: exists, non-empty, right dimensions, newer than the run, no DEBUG banner.
The script exits non-zero if any check fails.

That bar is deliberately higher than the plan's original "has produced a real
PNG", because the pre-review proved a command can satisfy that while writing
nothing.

## What the pre-review was right about

All 14 findings applied. The three that mattered could only be found by running
the thing:

- **H1** — `flutter test` + `takeScreenshot` passes and writes no file. The fix
  is `flutter drive` plus a driver that writes the bytes, and a script that
  checks the artifact instead of the exit code.
- **H3** — `flutter create` emits `IPHONEOS_DEPLOYMENT_TARGET = 13.0`, which
  cannot build for the simulator on Flutter 3.44.7.
- **H4** — the DEBUG banner renders into the capture's top-right corner, where
  the header gear sits.

## What implementation found that no review predicted

### The plan's downscale target was wrong

"Downscale to 2× the largest render box" is wrong for a 3× device. The first
import run emitted nine `UNDER-RESOLVED` warnings against its own sharpness
check — the rule and the check contradicted each other. Target is now 3×, and
the check fails the import rather than shipping soft art.

### The sticker sheets do not slice on gutters alone

Three cells in `capybara_cozy_moments_sticker_sheet.png` each held **two
touching poses** — useless as a mascot asset, and the kind of defect that ships
silently because the file looks fine in a listing. `splitWideCell` cuts at
coverage valleys instead.

My first version of it derived a part count from the aspect ratio and then
forced that many cuts, which split one wide subject into three. The tests caught
it before it reached the bundle. 31 individual poses now, 0 merged, asserted.

### Comparison has to be inset-relative

The mockup draws a 44 pt status bar; the simulator reports a 59 pt inset. An
absolute comparison charges every block below the header a constant ~15 pt
error that no code change can fix.

The harness now records the inset it actually rendered with, and `compare.dart`
**refuses to guess it from pixels** — an integration-test capture has no status
bar to detect, and an earlier version silently fell back to 44, which hid the
real number behind a plausible one.

## Self-review findings

**Self-review #1 (tokens and claims).** 7 findings, all Low, all applied: an
inline `Color(0xFFC4452B)` in `theme.dart` and six magic sizes across the three
components, now `CapyColors.error` and `CapyIconSize`. No hardcoded user-facing
strings, no RTL violations (`EdgeInsetsDirectional` throughout, no
`Alignment.centerLeft`, no `TextAlign.left`).

**Self-review #2 (safety and a11y).** One Medium, applied: the ported ARB
spelled the product **"Capywake"** in **194 places across all 10 locales**,
against the mockup wordmark's **"CapyWake"**. Fixed before Phase 02 ports more
strings on top of it.

Otherwise clean. Every tap target clears 44 pt (nav 64.6, button 55.4). No
overpromising copy — the only grep hits are the legacy's own *anti*-overpromise
guidance. No numeric literal in a user-facing position anywhere in `features/`.
No animation yet, so nothing to gate on `disableAnimations`; Phase 18 owns that.

**Full-project review.** Scope is clean: no `lib/core/` (Phase 02 owns it), none
of the alarm/Drift/health/sensors dependencies, no TODO placeholders, no
comments that restate the next line.

## Tier A — the honest number

`dart run tool/compare.dart shell 01_HOME`, offsets from the status bar:

| Block | Ref | Actual | Delta | |
|---|---|---|---|---|
| header band lower edge | 59.9 | 60.0 | **+0.1** | ✅ |
| hero scene lower edge | 248.3 | 237.3 | −11.0 | expected |
| card top (overlap) | 259.4 | 237.3 | −22.1 | expected |
| nav bar top | 730.5 | — | absent | expected |

**The tool fails today, and that is correct.** The header matches to 0.1 pt. The
other three are off because the screens have no bodies — the hero band collapses
to its art and the nav bar sits at the screen bottom. Phase 03 closes them when
Home gets content.

A comparison tool that passed on an empty shell would be worthless. This one
reports a measurement Phase 03 inherits rather than a claim it has to re-earn.

## Validation

| Gate | Result |
|---|---|
| `flutter analyze` | No issues |
| `dart format --set-exit-if-changed` | Clean |
| `tool/check_arb.dart` | 10 locales, 384 keys |
| `tool/check_bundle_size.dart` | 1818 KB of 2182 KB (83%) |
| `flutter test` | **43 passing** |
| `tool/check_coverage.dart --path lib` | **97.92%** against 85% |
| `tool/check_coverage.dart --min 95 --path lib/core` | **skipped — see below** |
| `tool/capture.sh` | 3 PNGs, verified |

The core gate is skipped because `lib/core/` does not exist until Phase 02, and
`check_coverage.dart` `exit(2)`s on an absent path rather than passing
trivially. **Phase 02 must re-enable it explicitly** — a skip nobody turns back
on is how a gate dies.

## Art

The patch closed four gaps including the only Blocking one. One new defect
found by measuring: **G11**, ~91% of ink at alpha 250–254 rather than 255,
leaving the art ~2% translucent. Fixed in the pipeline, not by asking for new
art — verified first that the band is interior fill, not antialiased edge
(3,243 interior vs 64 edge-adjacent), so snapping does not harden outlines.

**G9 was withdrawn**, after being measured wrong twice in opposite directions.
Edge detection separated the header (59.9 pt) from the art (188.4 pt), giving a
real crop of **28.1%** — large, but benign, which is what decides it. Rendered
all three alignment extremes: the face stays clear in every one.

## Handed to Phase 02

- `lib/core/` is empty and the port is the phase's whole job.
- **Re-enable the `lib/core` ≥ 95% gate** in the plan's acceptance criteria.
- 384 ARB keys × 10 locales are already in place, so the five `core/` files
  that take `AppLocalizations` as a parameter can port directly.
- `schemaVersion = 1`, not the legacy's 6.
- `docs/visual/asset_gaps.md` is the register; append, never restart it.

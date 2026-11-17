# Phase 10 — post-review

Puzzle chooser, onboarding puzzle/strictness steps, and per-alarm dismiss
method. Written after four review passes (pre, SR1, SR2, full-project), all
findings applied, and the whole flow run on the iPhone 18 Pro.

## What shipped

Three surfaces that give the user, for the first time, a way to configure the
wake puzzle — which was **persisted but written by no UI** before this phase
(every alarm used `PuzzleSettings.defaults()` forever):

1. **Puzzle chooser** (`lib/features/puzzle/`) — a pushed route from Settings
   ("Preferences" → "Wake puzzle"). Ten real `PuzzleType`s in a 2-column grid
   grouped spoken-then-visual, difficulty, puzzle count, escape strictness,
   tolerance. Writes the `puzzle_settings` singleton the ringing surface reads.
2. **Onboarding puzzle + strictness steps** — the single welcome became a
   three-step flow (welcome → puzzle preview → strictness). Completion moved to
   the last step only.
3. **Per-alarm dismiss method** (`lib/features/alarms/edit/dismiss_method_section.dart`)
   — Tap / Puzzle control, a follow-defaults switch, and a summary row linking to
   the chooser. Delegates every state transition to the domain.

## Predictions vs. measurement (restate, never quietly pass)

| Metric | Registered (pre-review) | Measured | Note |
|---|---|---|---|
| Tests | +45 to +75 | **+34** (1,513 → 1,547) | Lower: the puzzle domain was already fully tested; new tests are widget-level, and a config screen has less to assert than a generator. Restated. |
| ARB keys | +10 to +14 | **+2** (438 → 440) | Far fewer: nearly the whole chooser/onboarding/per-alarm vocabulary was already ported in 10 locales. Only the Settings entry row needed new strings. The pre-review's H1 over-corrected the plan's optimism; measurement settled it. |
| lib coverage | ≥ 97.8% | **97.93%** | Held. |
| core coverage | 99.61% (unchanged) | **99.61%** | Unchanged — no `lib/core` edit. |
| data coverage | 88.95% (unchanged) | **88.95%** | Unchanged — the singleton already existed. |
| Comment baseline | 113 (+0) | **113 (+0)** | Nine new files, all trimmed by hand, none baselined. |
| features/puzzle | — | **99.30%** | New. |
| features/onboarding | — | **100.00%** | New. |

## Tier A

**Binds nothing**, and this is measured, not assumed. The three supplied
references (`10_PUZZLE_CHOOSER.png` 378×1161, `09_ONBOARDING_*` 382–384×930) are
crops from one combined storyboard, not the 851×1847 native geometry the Tier A
contract requires — the handoff's own README says so. Held to tokens, the 44 pt
tap floor, RTL, large-text reflow, and the puzzle safety rules. Deviations named
in `docs/visual/puzzle_chooser/`. Not added to `capture_test.dart`.

## The three domain conflicts the mockups carried (domain won each)

- **Escape strictness** is two-value (`confirm` / `confirmAndHold`, no "off"),
  not the mockup's three; "Never" is not rendered (`CLAUDE.md` safety rule). The
  owner chose keep-domain. Verified on device: exactly two options everywhere.
- **"After 1 min"** was split back into the escape-strictness control and the
  separate tolerance stepper — two real, separately-persisted fields.
- **Ten real types, Material icons, no Shake.** The mockup's six illustrative
  cards and "Shake" dismiss method do not exist in the domain; `DismissMethod` is
  Tap / Puzzle (/ Hold, not surfaced). Logged `asset_gaps.md` G21, G22.

## Findings across four passes — 15 total, all applied, none deferred

- **Pre-review (14):** 3H/6M/4L (L1–L4). H1 ARB estimate corrected; H2 the
  onboarding redirect race made a hard constraint; H3 the type-floor double-
  guarded.
- **SR1 (4):** 1H/1M/2L. **H1 — the dismiss segment misrepresented a
  `holdToDismiss` alarm** (showed Tap selected while storing Hold); the section
  now names an unrepresentable method read-only, pinned by a seeded test.
- **SR2 (3):** 1H/1M/1L. **H1 — the onboarding completion path swallowed a write
  failure**, stranding the user on a dead-looking button with the ported
  `onboardingSaveError` string unused; now wrapped, holds position, shows the
  error, pinned by a throwing-repository test.
- **Full-project (4):** 0H/2M/2L. The headline: the ARB count was +2, not +10–14;
  and the three playable-practice onboarding strings remain unused **on purpose**
  (a playable demo is a games-phase concern), stated outright so the next phase
  is not surprised — Phase 09's ambiguity lesson applied.

## Device verification (iPhone 18 Pro, iOS 27.0) — not optional (Phase 09's rule)

The whole flow was run on the device, not inferred from the green suite:

- Onboarding: welcome → Next → puzzle preview → Next → strictness → **"Set your
  first alarm" lands on Add Alarm, not Home.** The Phase 09 redirect race does
  **not** recur under the new multi-step flow.
- The strictness step shows exactly two escape options, no "Never".
- Add Alarm: the Dismiss section shows Tap / Puzzle (no Shake); Puzzle reveals
  the follow-defaults switch and the "Medium · 1 puzzle" summary; the summary
  opens the chooser.
- The chooser renders all ten types, the floor note, Difficulty, Puzzles to
  solve (1–5), the two-value escape control, and the tolerance stepper.

## Safety

The puzzle escape is reachable in every configuration — no "Never", no "off",
confirmed on device. No scores/streaks/bests. Puzzle copy is a quiet
instruction. Phase 06's ringing surface (which consumes `PuzzleSettings`) is not
rebuilt and is verified unbroken by the controller round-trip test (M3).

## Acceptance

All criteria met. Android untested (no emulator) — never marked tested.

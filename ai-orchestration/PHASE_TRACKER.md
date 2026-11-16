# CapyWake (rebuild) — Phase Tracker

Single source of truth for phase sequencing. The `Current phase:` line below is
the pointer. The token is a zero-padded two-digit phase id matching a row in the
table, or the literal word `none`.

Convention inherited from `../capywake/ai-orchestration/PHASE_TRACKER.md`
(read-only reference). Advancing the pointer is part of each phase's completion.

Current phase: `03`

## Protocol per phase

Combines the handoff's **pre**-review with the legacy's **post**-reviews.
Both, not either.

1. Read `04_WORKSPACE_STATE/PROJECT_STATE.md` (handoff) and `memory/current-phase.md`.
2. Consult `../capywake` for relevant prior decisions. **Never modify it.**
3. Write `docs/phases/PHASE_XX_PLAN.md`: objective, reference screenshots,
   exact assets, asset-to-mockup mapping, dependencies, scope, exclusions,
   tests, acceptance criteria, risks, rollback.
4. Write `docs/phases/PHASE_XX_PRE_REVIEW.md` — adversarial, **before any
   code**. Classify High/Medium/Low. Apply all, or mark invalid with a reason.
5. Revise the plan.
6. Implement only that phase.
7. Run validation (below).
8. Phase self-review #1 → classify → apply all → re-validate.
9. Phase self-review #2 → classify → apply all → re-validate.
10. One full-project self-review → classify → apply all → re-validate.
11. Capture screenshots for any UI work; write `docs/visual/<screen>/`.
12. Write `docs/phases/PHASE_XX_POST_REVIEW.md`: discrepancies, Tier A deltas,
    Tier B substitutions, acceptance failures, resolutions.
13. Update tracker, `memory/current-phase.md`, `memory/progress.md`,
    `docs/sessions/next.md`.
14. Commit to `main`.

**A finding is applied or invalid. "Deferred", "out of scope" and "minor —
skipped" are not outcomes.** Low findings are fixed in the phase that raised
them.

**Steps 8–10 apply to documentation phases too.** Phase 00 skipped them on the
reasoning that a planning phase produces no code to review; the self-review it
should have had then found a High defect (it had banned reuse of 9,825 lines of
verified pure-Dart domain code and its 932 passing tests). Documents are the
deliverable of a planning phase, so reviewing them is reviewing the work.

## What is ported from `../capywake`

**If a file imports Flutter, it is not ported.** The sole exception is
`lib/core/theme.dart`, which imports Flutter *and* is not ported.

Ported: `lib/core/` minus `theme.dart` (62 files, 9,825 lines), `test/core/`
(48 files, 932 passing tests), `lib/l10n/` (383 keys × 10 locales),
`lib/data/` tables and mappers (at `schemaVersion = 1`, not the legacy's 6),
`tool/check_arb.dart`, `tool/check_coverage.dart`, `tool/generate_tones.dart`,
`assets/sounds/`.

Not ported: everything under `lib/features/`, `test/features/`, `lib/app/`,
and `lib/core/theme.dart`. File-level verdicts in `CAPYWAKE_REUSE_AUDIT.md`.

## Validation

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build --delete-conflicting-outputs    # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales complete
dart run tool/check_bundle_size.dart              # every bundled asset tree
flutter test --coverage                      # incl. the art audit + manifest
dart run tool/check_coverage.dart --path lib                # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
dart run tool/check_coverage.dart --min 85 --path lib/data  # data  >= 85%
```

The `lib/data` gate was added in Phase 02 (self-review #2, G1): `lib/data` was
the repository's weakest tree at 85.08% and cleared the project gate only
because `lib/core`'s 2,526 lines at 99.41% dominated the average. Its figure is
depressed by 67 structurally uncoverable lines — Drift `Table` column getters,
which run at build time to generate `app_database.g.dart` and never at runtime
— so the hand-written data code is really **422/429 = 98.4%**. Do not "fix" the
8% on `app_database.dart` with a meaningless test, a `// coverage:ignore`, or a
lowered gate. See `PHASE_02_SELF_REVIEW_2.md` G2.

Generators run **before** the format check. A generator reporting "nothing to
do" is acceptable.

**There is no `tool/audit_art.dart`.** This block listed one until Phase 02's
self-review (F3) found the documented command failing with "Could not find
file". The art audit is `lib/design/art_audit.dart`, applied by
`tool/import_art.dart` and gated by `test/design/art_audit_test.dart` +
`art_manifest_test.dart`, so it runs inside `flutter test`.

**Phase 01 exception, now closed:** the `--path lib/core` coverage line was
skipped in Phase 01 because `lib/core/` was not ported yet and
`check_coverage.dart` does **not** pass trivially on an absent path — it
`exit(2)`s with "No coverage data matched". **Phase 02 turned it back on
(99.41% against the 95% gate) and it stays on.**

## Git

`main` is the only branch. No feature branches, no worktrees, no stashes.
Per-phase commit `feat: complete phase <id> - <name>`, then
`chore: record phase <id> commit hash`.

## Phases

| ID | Name | Status | Phase file | Commit | Completed | Notes |
|----|------|--------|------------|--------|-----------|-------|
| 00 | Discovery, legacy audit, architecture and navigation decision | done | `docs/phases/PHASE_00_PLAN.md` | `f49a882` | 2026-11-16 | Legacy audited read-only: 40/47 phases done, 137 Dart files, 99 test files, full phase ritual found. Root cause of the failed retrofit identified: the "capybara is vector CustomPaint, never a raster cutout" rule made the mockups unreachable. Nav conflict resolved from the primary mockups: **Home/Alarms/Stats tabs, Settings pushed from the gear**. Owner decisions: raster art, all three Stats segments, full rigor incl. 10 locales. Pre-review raised 12 findings (4H/5M/3L), all applied. **Re-opened and self-reviewed 2026-11-16** (see `PHASE_00_SELF_REVIEW.md`): 8 further findings (2H/3M/3L), all applied — the Highs being that Phase 00 had banned reuse of the legacy's 9,825-line pure-Dart domain and 932 passing tests, and had skipped its own post-implementation review. `CAPYWAKE_REUSE_AUDIT.md` added. |
| 01 | Foundation: tokens, type, art pipeline, shell, capture harness | done | `docs/phases/PHASE_01_PLAN.md` | `ebe89e4` | 2026-11-16 | Gate met: `tool/capture.sh` writes 3 verified PNGs at 1179x2556 (393x852pt) and **checks the artifact, not the exit code** — the pre-review proved the planned `flutter test` mechanism passes while writing nothing, the legacy's 40-phase failure but green. 14 pre-review findings (5H/6M/3L) + 8 self-review (7L/1M), all applied. Typeface **Baloo 2**, chosen on measurements; it does **not** cover Cyrillic/Arabic/Japanese (a `getmask` check wrongly said it did — only rendering shows tofu), so `ru`→Nunito, `ar`/`ja`→system. Art patch closed G1/G2/G3/G10; **G11** found (91% of ink at alpha 250–254) and fixed in-pipeline; **G9 withdrawn**. Tier A: header matches to **0.1pt**; 3 blocks still off because the screens have no bodies — Phase 03's work, recorded as a measurement. 43 tests, lib coverage 97.92%, art 1818KB of 2182KB. |
| 02 | Domain and persistence — **port from `../capywake`** | done | `docs/phases/PHASE_02_PLAN.md` | `PENDING` | 2026-11-16 | Ported 62 `lib/core/` files (9,825 lines) + 47 `test/core/` files + 4 `lib/data/` files at `schemaVersion = 1` + 4 `test/data/` files + 12 sound assets. **The `lib/core` ≥95% gate is back on at 99.41%** and the Phase 01 exception is closed. **Test identity closed exactly as pre-registered: 912 + 83 + 43 ported/existing** (the pre-review fixed all three before implementation; its own first draft estimated the data tests at 66 and measurement gave **83**). N came out 13 not 5, restated rather than passed. **1,051 tests**, analyze clean, project 97.14%. **Not 932 ported but 912** — `theme_test.dart` is 20 of the legacy's 932 and tests the unported `theme.dart`; its replacement `tokens_contrast_test.dart` then found **two real AA failures** in Phase 01's palette (accent/success/grass never clear 3:1 on light surfaces; error is 3.93:1 on surfaceAlt) — recorded as checked constraints, owner-reported, Tier A decision deferred to a UI phase. 7 tests failed after the raw copy, none a logic defect, none skipped: `assets/sounds/` was missing from the plan (would have shipped a catalogue of 12 absent files), 3 sleep-boundary tests asserted phase-07/08 infrastructure, and iOS/Android app labels still read "Capywake". 40 findings across 4 review passes, all applied, none invalid. Also fixed: `tool/audit_art.dart` was documented in `CLAUDE.md` **and this tracker** but does not exist; `check_bundle_size.dart` measured art only while the real asset payload had grown to 10.5 MB; `lib/data` had no gate at 85.08% |
| 03 | Home / Today | pending | | | | `01_HOME.png`. **Inherits palette constraint F1 from Phase 02:** in light mode no control may use `accent`, `accentDeep`, `success` or `grass` as its *only* channel for boundary or state — they measure 1.76–2.68:1 against the three light surfaces, under the 3:1 UI minimum. Accent as a **fill** under `cocoa` text is fine. Error text may not sit on `surfaceAlt` (3.93:1). Both are asserted in `test/design/tokens_contrast_test.dart`; see `PHASE_02_POST_REVIEW.md` |
| 04 | Alarms list and Add/Edit | pending | | | | `02_ALARMS.png`, `03_ADD_EDIT_ALARM.png` |
| 05 | Alarm engine and reliability | pending | | | | Device test required |
| 06 | Ringing and emergency stop | pending | | | | Dismiss-exactly-once; reachable escape |
| 07 | Settings, reliability checklist, walkthrough | pending | | | | `04_SETTINGS.png`. **Owes a restoration:** when `package:health` + `live_sleep_gateway.dart` land, `test/core/sleep/sleep_boundary_test.dart` must go back to `exactly one` importer (it is `at most one` now) and re-assert `NSHealthShareUsageDescription` + `READ_SLEEP` are **present**. Phase 02 weakened those three to the negative invariant because asserting a key it may not add is satisfiable only by adding it — see `PHASE_02_SELF_REVIEW_1.md` F5 |
| 08 | Stats | pending | | | | `05_STATS.png`; empty state is the default. Same sleep-boundary restoration as 07 if the health path lands here |
| 09 | Onboarding | pending | | | | Just-in-time permissions |
| 10 | Puzzle chooser and the ten existing puzzle types | pending | | | | |
| 11 | Game foundation | pending | | | | What a "game" is in this codebase |
| 12 | Touch games I — Catch the Capy, Memory Hideout | pending | | | | No new permissions |
| 13 | Touch games II — Rhythm Rescue, Capy Rocket | pending | | | | |
| 14 | Authored games — Morning Sort, Find the Impostor | pending | | | | Content-bank ban lifted for these two (owner, 2026-11-15) |
| 15 | Motion games — Shake DJ, Tilt Maze | pending | | | | a11y fallback mandatory |
| 16 | Capy Step Quest | pending | | | | **Blocked** — needs a step-count permission; owner decision required |
| 17 | QR Treasure Hunt | pending | | | | **Blocked** — needs a camera dependency; owner decision required |
| 18 | Animation and visual polish | pending | | | | 5 WebP loops, reduce-motion, dark mode pass |
| 19 | Release QA | pending | | | | iOS + Android regression, bundle size, store readiness |

## Session log

- **2026-11-16** — Phase 02. Ported the domain: 62 `lib/core/` files, 47
  `test/core/` files, 4 `lib/data/` files at `schemaVersion = 1`, 4 `test/data/`
  files, 12 sound assets. **1,051 tests**, `lib/core` **99.41%** behind the
  re-enabled 95% gate. The pre-review registered every test count *before*
  implementing and its own first draft was 26% out on the data tests (estimated
  66, measured 83) — the discipline caught its author. Seven tests failed after
  the raw copy, none a logic defect: `assets/sounds/` was missing from the plan
  (the audit lists it; the plan paraphrased), three sleep-boundary tests asserted
  phase-07/08 infrastructure, and the iOS/Android app labels still read
  "Capywake". The dropped `theme_test.dart`'s replacement found **two real AA
  failures** in Phase 01's palette. Four gates were found green for the wrong
  reason: a documented `tool/audit_art.dart` that does not exist, an art-only
  bundle check while assets reached 10.5 MB, an ungated `lib/data` at 85.08%, and
  that 85.08% itself concealing 67 uncoverable Drift getters. 40 findings, all
  applied.

- **2026-11-16** — Phase 00. Handoff package read in full (7 docs, 11 phase
  briefs, workspace state). All five primary mockups inspected and measured:
  851×1847 px = **393×853 pt**, i.e. iPhone 14 Pro, which is available as a
  simulator — so screenshot comparison is exact. Palette sampled. `../capywake`
  audited read-only. Evidence saved to `docs/visual/_evidence/` that the Home
  mockup hero (nightcap, duck, nightstand clock) is **not**
  `today_integrated.png` (no cap, no duck, mug and books) — the two were
  generated separately, which is why the fidelity contract is two-tier. No app
  code written, by design.

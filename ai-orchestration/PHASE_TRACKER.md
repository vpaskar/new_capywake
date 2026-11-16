# CapyWake (rebuild) — Phase Tracker

Single source of truth for phase sequencing. The `Current phase:` line below is
the pointer. The token is a zero-padded two-digit phase id matching a row in the
table, or the literal word `none`.

Convention inherited from `../capywake/ai-orchestration/PHASE_TRACKER.md`
(read-only reference). Advancing the pointer is part of each phase's completion.

Current phase: `01`

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

## Validation

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build --delete-conflicting-outputs    # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales complete
dart run tool/audit_art.dart                                # alpha/size/manifest
dart run tool/check_bundle_size.dart                        # art budget
flutter test --coverage
dart run tool/check_coverage.dart                           # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
```

Generators run **before** the format check. A generator reporting "nothing to
do" is acceptable.

## Git

`main` is the only branch. No feature branches, no worktrees, no stashes.
Per-phase commit `feat: complete phase <id> - <name>`, then
`chore: record phase <id> commit hash`.

## Phases

| ID | Name | Status | Phase file | Commit | Completed | Notes |
|----|------|--------|------------|--------|-----------|-------|
| 00 | Discovery, legacy audit, architecture and navigation decision | done | `docs/phases/PHASE_00_PLAN.md` | `f49a882` | 2026-11-16 | Legacy audited read-only: 40/47 phases done, 137 Dart files, 99 test files, full phase ritual found. Root cause of the failed retrofit identified: the "capybara is vector CustomPaint, never a raster cutout" rule made the mockups unreachable. Nav conflict resolved from the primary mockups: **Home/Alarms/Stats tabs, Settings pushed from the gear**. Owner decisions: raster art, all three Stats segments, full rigor incl. 10 locales. Pre-review raised 12 findings (4H/5M/3L), all applied. |
| 01 | Foundation: tokens, type, art pipeline, shell, capture harness | pending | `docs/phases/PHASE_01_PLAN.md` | | | Must end with a real PNG from `tool/capture.sh` |
| 02 | Domain and persistence | pending | | | | `Alarm`, recurrence, schedule math, Drift. Headless, ≥95% core |
| 03 | Home / Today | pending | | | | `01_HOME.png` |
| 04 | Alarms list and Add/Edit | pending | | | | `02_ALARMS.png`, `03_ADD_EDIT_ALARM.png` |
| 05 | Alarm engine and reliability | pending | | | | Device test required |
| 06 | Ringing and emergency stop | pending | | | | Dismiss-exactly-once; reachable escape |
| 07 | Settings, reliability checklist, walkthrough | pending | | | | `04_SETTINGS.png` |
| 08 | Stats | pending | | | | `05_STATS.png`; empty state is the default |
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

- **2026-11-16** — Phase 00. Handoff package read in full (7 docs, 11 phase
  briefs, workspace state). All five primary mockups inspected and measured:
  851×1847 px = **393×853 pt**, i.e. iPhone 14 Pro, which is available as a
  simulator — so screenshot comparison is exact. Palette sampled. `../capywake`
  audited read-only. Evidence saved to `docs/visual/_evidence/` that the Home
  mockup hero (nightcap, duck, nightstand clock) is **not**
  `today_integrated.png` (no cap, no duck, mug and books) — the two were
  generated separately, which is why the fidelity contract is two-tier. No app
  code written, by design.

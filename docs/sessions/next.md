# Next session — start here

## State

Phases 00, 01 and 02 are **done** and committed.

**Current phase: `03` — Home / Today (`01_HOME.png`).**

The domain layer is real and tested: 1,051 tests pass, `lib/core` is at 99.41%
coverage behind a 95% gate, and the Drift database is at `schemaVersion = 1`.

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 02 established and decided.
4. `docs/phases/PHASE_02_POST_REVIEW.md` — **especially the palette section**.
5. `reference/01_REFERENCES/screens/primary/01_HOME.png` — the source of truth.
6. `docs/visual/asset_gaps.md` — the standing register. Append, never restart.

## Do, in this order

1. Pre-flight: `pwd && git branch --show-current` → `new_capywake`, `main`.
2. Write `docs/phases/PHASE_03_PLAN.md`.
3. Write `docs/phases/PHASE_03_PRE_REVIEW.md` — adversarial, **before any
   code**. Classify High/Medium/Low. Apply all, or mark invalid with a reason.
4. Revise the plan against the findings.
5. **Then** implement.
6. Validate → self-review #1 → self-review #2 → full-project review.
7. `PHASE_03_POST_REVIEW.md`, update tracker + memory + this file, commit.

## What Phase 03 may assume

**Real and available:** all of `lib/core/` — models, DST-correct schedule math
(`AlarmScheduleService`, `NextAlarmService`), today formatting, the puzzle
engine, `HistoryService`, the lifecycle FSM, sleep aggregation, wake window,
reliability copy. Plus the Drift database, mappers, `CapyWakeRepository`, and the
Riverpod provider graph in `lib/data/providers.dart`.

**Interface + fake only — no platform implementation:** `AlarmEngine`,
`NotificationService`, `SleepGateway`, `MotionSensor`, `PermissionService`.
`lib/core/engine/alarm_engine.dart` exists, **but nothing rings.** Adapters land
in phase 05 (engine, notifications) and 07/08 (permissions, sleep). Do not
conclude from the presence of these files that an alarm can fire.

**Not available:** any platform plugin (`alarm`, `flutter_local_notifications`,
`health`, `sensors_plus`, `permission_handler`); migration history; sleep reads
from Apple Health / Health Connect.

## Palette constraint F1 — binding on Phase 03

Phase 02's contrast test found two real AA failures in Phase 01's sampled tokens:

| Pair | Measured | Required |
|---|---|---|
| `accent` / `accentDeep` / `success` / `grass` on cream, surface, surfaceAlt | 1.76–2.68:1 | 3.0 (UI components) |
| `error` on `surfaceAlt` | 3.93:1 | 4.5 (body text) |

So, in **light mode**:

- No control may use accent, success or grass as its **only** channel for
  boundary or state. It needs ink, a shape change or a label too.
- Error text may not sit on `surfaceAlt`.
- The accent as a **fill** under `cocoa` text clears AA comfortably. That
  pairing is fine and is asserted.

`test/design/tokens_contrast_test.dart` asserts the current weakness and **fails
if a token strengthens**, so improving the palette is a deliberate act: update
the test and the constraint together. Retuning tokens sampled from the mockups is
a **Tier A decision for the owner**, not something a phase does in passing.

## Measurement discipline that paid off, twice

**Fix every countable term before implementing.** Phase 02's pre-review
registered the expected test counts in advance; its own first draft *estimated*
the four data-test files at 66 and measurement gave **83**. Had the estimate
stood, the post-review would have found 83 where it expected 66 and had to decide
after the fact whether a surplus was good news. Final identity:
912 + 83 + 43 + 13 = **1,051**, restated when N came out 13 rather than 5.

**Work through the reuse audit item by item, do not paraphrase it.**
`CAPYWAKE_REUSE_AUDIT.md` lists `assets/sounds/`; Phase 02's plan missed it, and
three ported tests failed. Without those tests the app would have shipped a
sound catalogue pointing at twelve absent files, failing only when a user tapped
one.

## Reading coverage figures

Read the number from the `Coverage (...)` line, **never from `PASS` alone** — the
Dart build-hooks preamble shares stdout, so pipe through `tr '\r' '\n'`:

```bash
dart run tool/check_coverage.dart --min 95 --path lib/core 2>&1 | tr '\r' '\n' | grep Coverage
```

`lib/data` reads **85.08%** and that is expected: 67 of its 496 lines are Drift
`Table` column getters, evaluated at build time to generate
`app_database.g.dart` and never executed at runtime. Hand-written data code is
**422/429 = 98.4%**. **Do not** "fix" it with a meaningless test, a
`// coverage:ignore` (forbidden by `CLAUDE.md`), or a lowered gate.

## Owed restorations

**Phase 07/08** — when `package:health` and `live_sleep_gateway.dart` land,
`test/core/sleep/sleep_boundary_test.dart` must go back to `exactly one`
importer (it is `at most one` now) and re-assert that
`NSHealthShareUsageDescription` and `READ_SLEEP` are **present**. Phase 02
weakened those three to the negative invariant because asserting the presence of
a key it may not add is satisfiable only by adding it — i.e. by implementing a
future phase.

## There is no `tool/audit_art.dart`

`CLAUDE.md` and the tracker both listed it as a per-phase gate until Phase 02
found it does not exist — running it errors. The art audit is
`lib/design/art_audit.dart`, applied by `tool/import_art.dart` and gated by
`test/design/art_audit_test.dart` + `art_manifest_test.dart`, so it runs inside
`flutter test`. **Running the documented validation list should never error.**

## Validation (every phase)

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build                                 # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales
dart run tool/check_bundle_size.dart                        # every asset tree
flutter test --coverage                     # incl. the art audit + manifest
dart run tool/check_coverage.dart --path lib                # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core   # core >= 95%
dart run tool/check_coverage.dart --min 85 --path lib/data   # data >= 85%
```

Generators run **before** the format check.

For screenshots use `tool/capture.sh`, which verifies the artifact. **Never**
run `integration_test/capture_test.dart` with `flutter test` — it passes while
writing nothing.

## Reference paths

| What | Where |
|---|---|
| Master brief | `reference/00_AGENT_MASTER_PROMPT.md` |
| Mockups (source of truth) | `reference/01_REFERENCES/screens/primary/` |
| Hero scenes | `reference/02_ASSETS/header_scenes/*_integrated.png` |
| Mascots | `reference/02_ASSETS/asset_library/mascots/` + `mascot_fixes/` |
| Clean icons | `reference/02_ASSETS/clean_icons/` |
| Legacy (READ-ONLY) | `../capywake` |

`reference/` is reference material, never bundled (348 MB, git-ignored).

## Environment

- Dart 3.12.2 stable, macos_arm64.
- **iPhone 14 Pro simulator** — matches the mockup geometry exactly (1179×2556
  px = 393×852 pt).
- A physical iPhone is reachable for real alarm testing in phase 05.
- **No Android emulator has been run.** Android is unverified; never mark it
  tested until one actually runs.

## Standing reminders

- `../capywake` is **read-only**. It was **already dirty before this rebuild
  began** — 10 modified `lib/features/`/`test/features/` files and 1 untracked
  phase brief, all mtime 2026-11-15, legacy HEAD `80d009b`. That is the legacy's
  own unfinished work. Acceptance compares `git status --porcelain` against that
  recorded baseline, not against "clean".
- **If a file imports Flutter, it is not ported.** Asserted by
  `test/core/no_flutter_in_core_test.dart`.
- Never claim a screen matches without a recorded capture.
- A finding is applied or invalid. Never deferred.
- `main` only. No branches, no worktrees, no stashes.
- Store publishing is drafts only; the owner presses every final button.

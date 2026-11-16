# Phase 02 — Domain and persistence: port from `../capywake`

**Status:** draft 2 — revised against `PHASE_02_PRE_REVIEW.md` (20 findings,
6H/8M/6L, all applied)
**Tracker row:** `02 | Domain and persistence — port from ../capywake`

## Objective

Give CapyWake a complete, headless, tested domain layer and a persistence layer
at a fresh `schemaVersion = 1`, by **porting** verified pure-Dart code from the
read-only `../capywake` rather than rewriting it.

This phase writes **no UI**. Nothing under `lib/features/` or `lib/design/`
changes. The deliverable is `lib/core/`, `lib/data/`, and the test suite that
proves them.

## Why this is a port, not a rewrite

Measured, not assumed (commands re-run this session, read-only against the
legacy):

| Check | Result |
|---|---|
| `find ../capywake/lib/core -name '*.dart' \| wc -l` | **63** files |
| `wc -l` over those | **10,529** lines |
| Minus `theme.dart` (704 lines) | **62** files, **9,825** lines |
| `grep -rln "package:flutter" ../capywake/lib/core/` | **`theme.dart` only** |
| `grep -rn "package:capywake/features\|/data/\|/app/" ../capywake/lib/core/` | **NONE** |
| `flutter test test/core` in `../capywake` | **932 passed** |
| `flutter test test/core/theme_test.dart` | **20** of those 932 |

The 932 include DST spring-forward, leap day, skip-next sequencing, and a
one-time 00:30 alarm set at 23:55 firing after midnight. Those are years of
edge-case discovery. The failed retrofit failed in the **view layer** for a
documented reason (the vector-`CustomPaint` rule); nothing in `lib/core/` has an
opinion about how a capybara is drawn.

## The port rule, in two parts (M3)

**Part 1 — `lib/`: if a file imports Flutter, it is not ported.** Sole
exception: `lib/core/theme.dart`, which imports Flutter *and* is not ported.
Enforced by a test (acceptance 9), not by vigilance.

**Part 2 — `test/core/`: `package:flutter/widgets.dart` is permitted solely to
construct a `Locale`.** Six `test/core/` files import `package:flutter`.
Five need it only for `Locale`, to call
`AppLocalizations.delegate.load(locale)` — verified by reading every import and
use site; nothing else Flutter-shaped appears. `Locale` lives in `dart:ui` and is
merely re-exported by `widgets.dart`. Those five port. Applying Part 1 literally
to tests would drop 1,463 lines and a large share of the 912 for a category
error: a test of localized output must build a `Locale`, because the production
API takes an `AppLocalizations`, which is itself generated Flutter code.

The sixth is `test/core/theme_test.dart`, which imports
`package:flutter/material.dart` to test `AppTheme` — the one `lib/` file not
being ported. **It is dropped**, and H2 below replaces what it guarded.

### Why five, and not the six that `grep` reports (M2)

`grep -rln "l10n" ../capywake/lib/core/` returns **six** files. The sixth,
`alarm_draft.dart`, matches only in a doc comment ("Calm, plain wording lives in
`lib/l10n`") — no import, no parameter. The count that matters is files that
**import** `app_localizations.dart`: exactly five.

## H2 — what dropping `theme_test.dart` costs, and how it is replaced

Those 20 tests were not a file-existence check. They asserted **WCAG AA contrast
between primary controls and semantic text**, that dark mode exposes exactly one
separator (the hairline), and that the scaffold background is the warm-sand
token. Those are accessibility and design-system invariants about *a palette* —
and CapyWake has a palette, `lib/design/tokens.dart`, sampled from the mockups in
Phase 01.

Phase 01's `test/design/components_test.dart` asserts **no contrast at all** —
verified by reading it. So a verbatim port drops 20 palette-correctness tests and
leaves the replacement palette unguarded. That is the shape of Phase 00's High
finding: a correct local decision quietly discarding a load-bearing capability.

**Deliverable:** `test/design/tokens_contrast_test.dart` — WCAG AA (4.5:1 body,
3:1 large text) over the foreground/background pairs `tokens.dart` defines, in
both light and dark. Not a port of `theme_test.dart` (the tokens differ), but the
invariant restored rather than lost in a port's rounding error. Counted in N.

## Expected test count — an exact arithmetic identity (H1)

`theme_test.dart` contributes exactly 20 of the legacy's 932. Dropping it leaves
**912**. The handoff brief and the tracker both say "932 ported tests must
pass"; that number is correct about the legacy suite and wrong about the ported
one, because it was written before anyone counted `theme_test.dart`'s share
(M1 corrects the four documents that repeat it).

Every term is measured, none estimated. Data-test counts come from running each
file in the legacy this session:

| Term | Tests | Source |
|---|---|---|
| ported `test/core/` | **912** | 932 measured − 20 measured (`theme_test.dart`) |
| `test/data/mappers_test.dart` | 18 | measured |
| `test/data/puzzle_mappers_test.dart` | 15 | measured |
| `test/data/sleep_mappers_test.dart` | 18 | measured |
| `test/data/capywake_repository_test.dart` | 32 | measured |
| Phase 01 existing | **43** | measured |
| new this phase (N) | **5** | §Tests below (N1–N5) |
| **expected total** | **1,043** | |

N = 5: no-Flutter-in-core, the `Locale`-only carve-out, no-`onUpgrade`,
schema-columns, token-contrast. **Acceptance is the identity, not a floor**: a
total that is not 1,043 — above or below — is a finding to explain before the
phase closes. A test that turns out to need splitting into several cases changes
N, and the identity is restated with the new figure rather than quietly passed.

## Scope — what is ported

### 1. `lib/core/` — 62 files, 9,825 lines

Ported as-is, modulo the mechanical adaptations in "Adaptations" below.

| Area | Files | Lines | Notable |
|---|---|---|---|
| root formatters | 10 | 1,232 | `alarm_draft` (462), `alarm_sound` (174), `next_alarm` (114), `countdown_format`, `alarm_format`, `time_stepper`, `today_format`, `alarm_repeat`, `alarm_dismiss_summary` |
| `models/` | 10 | 1,054 | `Alarm`, `AlarmOccurrence`, `UserSettings`, `WakeMode`, `DismissMethod`, `ProStatus`, `AlarmStatus`, `ThemeModePreference`, `TimeFormat`, barrel |
| `puzzle/` | 12 | 2,657 | `puzzle_generator` (622), `puzzle_content` (364), `puzzle_round` (329), `puzzle_validator` (302), `puzzle_settings` (220), `puzzle_difficulty`, `puzzle_selector`, `puzzle_exposure`, `puzzle_type`, `puzzle_equality`, `alarm_puzzle_override`, `puzzle` |
| `schedule/` | 2 | 643 | `alarm_schedule_service` (578) — DST/timezone/recurrence; `local_time_of_day` |
| `engine/` | 6 | 883 | `alarm_schedule_coordinator` (272), `fake_alarm_engine` (176), `alarm_engine` (127), `notification_schedule_calculator` (125, the iOS 64-cap), `notification_service`, `fake_notification_service` |
| `sleep/` | 10 | 1,133 | `sleep_sync_service` (202), `sleep_aggregator` (222), `sleep_gateway` (78, **no write method**), `sleep_night`, `sleep_segment`, `sleep_stage`, `sleep_sync_state`, `sleep_format`, `fake_sleep_gateway`, barrel |
| `history/` | 1 | 649 | `history_service` — feeds the Stats Alarms segment |
| `lifecycle/` | 2 | 440 | `alarm_status_service` (255), `snooze_service` (185) |
| `reliability/` | 2 | 635 | `reliability_checklist_service` (377), `reliability_copy_service` (258) |
| `wake/` | 2 | 383 | `wake_window_service` (283), `wake_volume_ramp` |
| `motion/` | 3 | 251 | `motion_check_service`, `motion_sensor`, `fake_motion_sensor` |
| `permissions/` | 2 | 190 | `permission_service`, `fake_permission_service` |
| `onboarding/` | 1 | 37 | `onboarding_status` |

### 2. `test/core/` — 47 files, 15,245 lines, 912 tests

All of `../capywake/test/core/` **except `theme_test.dart`**. The audit's
"48 files, 15,503 lines" is the legacy total; ported is 48 − 1 = **47** files and
15,503 − 258 = **15,245** lines (L2).

### 3. `lib/data/` — tables, mappers, repository, at `schemaVersion = 1`

| Ported | Lines | Note |
|---|---|---|
| `database/app_database.dart` | 311 → ~190 | Tables kept verbatim; `schemaVersion` 6 → **1**; the entire `onUpgrade` body **dropped** |
| `database/mappers.dart` | 502 | Verbatim — verified to reference no dropped column |
| `repositories/capywake_repository.dart` | 336 | Verbatim — imports only core + drift |
| `database/app_database.g.dart` | — | **Regenerated**, never copied |

**Not ported in this phase:** `data/engine/`, `data/sleep/live_sleep_gateway.dart`,
`data/motion/`, `data/permissions/`. Each pulls a platform package (`alarm`,
`flutter_local_notifications`, `health`, `sensors_plus`, `permission_handler`)
whose phase is 05 (engine), 07/08 (sleep, permissions) or later. Adding five
platform plugins now would be implementing future phases, which `CLAUDE.md`
forbids. The **abstractions** they implement (`AlarmEngine`,
`NotificationService`, `SleepGateway`, `MotionSensor`, `PermissionService`) and
their **fakes** all live in `lib/core/` and port now, so nothing downstream is
blocked.

`data/sleep/repository_sleep_night_store.dart` (31 lines) **is** ported — it
imports only core + the repository, no platform package.

**`data/providers.dart` is ported minus the sleep-gateway providers (M4).**
Draft 1 excluded it whole, on the stated grounds that it imports
`flutter_riverpod` *and* `live_sleep_gateway`. The first half is wrong —
`flutter_riverpod` has been a dependency since Phase 01, where the shell uses it.
The only real blocker is the `live_sleep_gateway` import, which pulls `health`.

Excluding the file entirely would leave Phase 03 with no way to read an alarm out
of the database, forcing it to invent the provider graph as a side quest while
building Home — which is how a UI phase starts making architecture decisions.
What is dropped is exactly the platform sleep-read path; the repository-backed
sleep-night **store** is already in scope, so the graph stays coherent.

### 4. `test/data/` — the four portable files

| Ported | Lines |
|---|---|
| `mappers_test.dart` | 379 |
| `puzzle_mappers_test.dart` | 205 |
| `sleep_mappers_test.dart` | 246 |
| `capywake_repository_test.dart` | 629 |

All four open the DB with `NativeDatabase.memory()` via `AppDatabase.forTesting`,
import no platform package and no `package:flutter`. **Not ported:**
`migration_test.dart` (921) and `migration_v6_test.dart` (232) — they assert the
migration history this phase deliberately drops; `engine/*`, `providers_test.dart`,
`live_sleep_gateway_test.dart` — their subjects are not ported this phase.

## Dependencies to add

| Package | Version | Why, and why now |
|---|---|---|
| `timezone` | `^0.11.0` | `alarm_schedule_service` and `alarm_schedule_coordinator` import it. Non-negotiable: it is the DST correctness substrate |
| `drift` | `^2.32.1` | The tables and mappers |
| `sqlite3_flutter_libs` | `^0.5.40` | Runtime SQLite for device/simulator |
| `path` | `^1.9.1` | `_openConnection` joins the db path |
| `path_provider` | `^2.1.5` | `_openConnection` finds app-support dir |
| `uuid` | `^4.5.3` | Stable domain ids |
| `drift_dev` | `^2.32.1` | **dev** — generates `app_database.g.dart` |
| `build_runner` | `^2.10.0` | **dev** — runs the generator |

Versions read from the legacy `pubspec.yaml` (L4): the first six from its
`dependencies` block, the last two from its `dev_dependencies` — where
`build_runner` is `^2.10.0`, not the `^2.9.0` draft 1 guessed. All eight are
required by code ported in *this* phase. No platform plugin (`alarm`,
`flutter_local_notifications`, `health`, `sensors_plus`, `permission_handler`)
is added.

### `sqlite3_flutter_libs` adds native artifacts, and no existing gate covers that (H3)

`sqlite3_flutter_libs` ships prebuilt **iOS and Android native libraries**.
Adding it changes the pod install, the link step and the shipped binary size.

`tool/check_bundle_size.dart` measures the **art** budget. It will therefore
report green after this change — for a reason entirely unrelated to the risk.
A gate that is green for the wrong reason reads as coverage and is worse than no
gate, so **this phase makes no claim that bundle size is unchanged.**

What replaces the false comfort: acceptance requires `tool/capture.sh` to still
succeed. It builds and runs the app on the simulator, so a broken pod install or
a native link failure surfaces in this phase rather than in Phase 03. The phase
changes no pixel — the point of the run is the build, not the image.

## Adaptations required

1. **Package name.** Both projects are `name: capywake`, so
   `package:capywake/...` imports resolve unchanged. **No rewriting of imports.**
   Verified: `../capywake/pubspec.yaml` and `./pubspec.yaml` both declare
   `name: capywake`.
2. **l10n path.** Legacy core imports
   `package:capywake/l10n/generated/app_localizations.dart`; Phase 01 generates
   to exactly that path. Verified present.
3. **`schemaVersion` 6 → 1** and the `MigrationStrategy` reduced to `onCreate`.
   The per-column "Added in schema vN" comments in the table definitions become
   false the moment there is one version — they are **removed**, not kept.

   **The dropped-column trap (H4).** The legacy's v3 → v4 step does not only add
   columns: it **drops** `alarms.final_alarm_minutes_after` and
   `alarm_occurrences.final_at` by rebuilding each table from the then-current
   Dart schema. So "start at v1 with `createAll()`" reproduces the legacy's live
   schema *only if* those two columns are genuinely absent from the table
   classes. Verified by reading `app_database.dart`: they are absent.

   That was luck rather than design. Had a dropped column still been declared,
   `createAll()` would resurrect it and the mappers — which never reference it —
   would leave it NULL forever: exactly the unbacked claim the legacy's own v4
   comment was written to remove. So the schema is asserted, not read off a
   migration comment (see §Tests).
4. **"Capywake" → "CapyWake"** in every ported doc comment and string
   (32 occurrences in `lib/core/`). Phase 01 corrected 194 in the ARB;
   reintroducing the old casing from legacy source would undo that silently.

   **Checked before applying (M6):** the rename also hits test *fixtures*, not
   just prose — `reliability_copy_service_test.dart:253,269` pass
   `'Battery optimization may stop Capywake.'` as `firstAttentionBody`. That is
   a caller-supplied literal asserted with `startsWith('Battery optimization')`,
   so renaming it is behaviour-neutral. Verified rather than assumed, because a
   blind `sed` is safe 31 times and silently wrong once. Separately: the new ARB
   says "optimis**a**tion" (British) where the fixture says "optimiz**a**tion";
   the fixture never compares against the ARB, so nothing breaks.
5. **Comment budget (L6, revised by self-review #1 F4).** `pets/CLAUDE.md`
   forbids comments that **restate the next line**. The committed rule is
   exactly that, checked by reading: no comment that restates the code, and
   nothing kept that only narrates phase history.

   L6 originally set a 12-line numeric ceiling, borrowed from `gastrowerk`.
   Measured after the port: **50 runs over 12 lines across 33 files** — and
   reading them showed the rule was wrong, not the code. The long runs are a
   state-machine transition table, DST gap/overlap/travel semantics, the iOS
   64-pending cap, and why `totalAsleepMinutes` is not the sum of the stage
   columns. `gastrowerk`'s number was derived from `gastrowerk`'s tree and
   ratchets there; imported here it would delete precisely the knowledge this
   port exists to inherit. Withdrawn, with the reasoning in F4.
6. **Lint set — measured before the porting approach is fixed (H5).** The legacy
   excludes `tool/**` from analysis and this repo does **not**; this repo also
   escalates `missing_required_param` and `missing_return` to `error`, which the
   legacy did not. So ~10,800 lines of core + data face `very_good_analysis`
   9.0.0 under stricter settings for the first time, and draft 1 scheduled that
   measurement *after* committing to a verbatim port.

   **Mandatory step, before any hand-editing:** copy core + data in, run
   `flutter analyze`, and record the issue count and per-rule histogram in this
   plan. If the volume is large enough that mechanical fixing risks behaviour
   change, that is a finding raised at that point with evidence — not a surprise
   found at hour three. The escalated `errors:` block is **not** relaxed, and no
   lint is silenced in `analysis_options.yaml`.

## Tests

Ported: **912** core (47 files), **83** data (4 files, 1,459 lines).
Existing: Phase 01's **43**. New this phase: **5 tests in 4 files**, below.

The identity in §Expected test count uses N = **5** tests. The five are N1–N5;
N1 and N2 are two tests in one file, which is why the file count is 4.

### N1 — `lib/core/` imports no Flutter

Walks `lib/core/` and asserts no file imports `package:flutter`. The port rule is
the backbone of this architecture and currently rests on nobody making a mistake.

### N2 — `test/core/` uses Flutter only for `Locale` (M3)

The complement of N1. Asserts that any `package:flutter` import under
`test/core/` is `widgets.dart` and that the file's Flutter usage is `Locale`
alone — so Part 2 of the port rule is a checked narrow carve-out rather than an
unbounded exemption that would make N1 meaningless.

### N3 — a fresh database is the only supported origin (H6)

Draft 1 proposed asserting `schemaVersion == 1`. That test fails the moment a
future phase legitimately adds migration v2, and the obvious fix is to bump the
constant — at which point the *reason* v1 was chosen (greenfield, zero users, do
not inherit migrations for data nobody has) is gone from the code with nothing
left in its place. That is how Phase 01's coverage skip would have died if the
tracker had not recorded it; repeating the pattern one level down is not
acceptable.

So the test asserts the **`MigrationStrategy` exposes no `onUpgrade`**, carrying a
one-line reason naming the greenfield decision, with `schemaVersion == 1` as the
weaker second assertion. A future phase adding a real migration then deletes a
test whose purpose is explicit, instead of silently editing a number.

### N4 — the created schema's columns are exactly right (H4)

Enumerates each table's actual columns from the opened database and asserts the
set exactly: **no `final_alarm_minutes_after`, no `final_at`**, and every column
the mappers touch present. Makes "the fresh v1 schema equals the legacy's end
state" a checked property of the database rather than an inference from a
migration comment.

### N5 — token contrast (H2)

`test/design/tokens_contrast_test.dart`, replacing what `theme_test.dart`
guarded. Counted in N above; see §H2.

*(N is 4 new test files; N2 and N1 live in one file, so the four files are
no-Flutter/Locale-shape, migration-origin, schema-columns, token-contrast.)*

## Acceptance criteria

1. `flutter analyze` — **zero issues, including infos**. (This also proves no
   ARB key is missing: a missing generated getter is an analyze error, so L3
   needs no separate check.)
2. `dart format --set-exit-if-changed .` clean.
3. `dart run build_runner build --delete-conflicting-outputs` runs **before**
   the format check and regenerates `app_database.g.dart`.
4. `dart run tool/check_arb.dart` — 10 locales, still passing (ARB untouched).
5. `dart run tool/audit_art.dart` passes. `check_bundle_size.dart` passes but
   **is not evidence about binary size** — it measures the art budget only, and
   this phase adds native SQLite artifacts it cannot see (H3).
6. **The test identity holds exactly: 912 + 83 + 43 + 5 = 1,043.** Not a floor.
7. `dart run tool/check_coverage.dart --path lib` — project **≥ 85%**.
8. **`dart run tool/check_coverage.dart --min 95 --path lib/core` — ≥ 95%.**
   The gate Phase 01 skipped legitimately and this phase turns back on.
   **It stays on from here.**
9. `lib/core/` imports no Flutter (N1), and `test/core/`'s Flutter use is
   `Locale`-only (N2) — both asserted by tests.
10. The `MigrationStrategy` has no `onUpgrade` and `schemaVersion == 1` (N3);
    the created column set is exact (N4).
11. No platform plugin added to `pubspec.yaml`.
12. **`../capywake` unchanged — its `git status --porcelain` is byte-identical
    to the baseline recorded below (M7).** The legacy was *already dirty* when
    this session began; "clean" is unsatisfiable and asserting it would send a
    later session hunting a defect that does not exist.
13. `tool/capture.sh` still succeeds — proving the native dependency change did
    not break the simulator build (H3). Never `flutter test
    integration_test/capture_test.dart`, which passes while writing nothing.

### `../capywake` baseline, recorded before any file was copied (M7)

```
 M lib/features/alarms/alarm_edit_screen.dart
 M lib/features/common/capy/capy_nav_bar.dart
 M lib/features/common/capy/capy_scaffold.dart
 M lib/features/common/state_views.dart
 M lib/features/history/history_screen.dart
 M lib/features/reliability/reliability_screen.dart
 M lib/features/settings/sleep_screen.dart
 M test/features/alarms/alarm_edit_screen_test.dart
 M test/features/cartoon_settings_screens_test.dart
 M test/features/history/history_screen_test.dart
?? ai-orchestration/phases/phase-47-statistics-screen.md
```

Legacy HEAD `80d009b`. Every entry is mtime **2026-11-15 21:14–21:51** — the day
before this rebuild — and every path is under `lib/features/` or
`test/features/`, precisely the trees this phase never reads. So a modification
to anything this phase *does* touch cannot hide inside the tolerance.

## What Phase 03 may assume (M8)

Phase 02's output is the substrate for every later phase, so the contract is
stated rather than inferred.

**Available and real:** all of `lib/core/` — models, schedule math, puzzle
engine, history, lifecycle, sleep aggregation, wake window, reliability copy —
plus the Drift database, mappers, repository, and the Riverpod provider graph
minus the sleep-gateway providers.

**Available as an interface plus a fake, with no platform implementation:**
`AlarmEngine`, `NotificationService`, `SleepGateway`, `MotionSensor`,
`PermissionService`. `lib/core/engine/alarm_engine.dart` exists — but nothing
rings. The platform adapters land in phase 05 (engine/notifications) and
07/08 (permissions, sleep). **Phase 03 must not conclude from the presence of
these files that an alarm can fire.**

**Not available:** any platform plugin; migration history; sleep reads from
Apple Health / Health Connect.

## Safety rules — inert this phase, services ported with their tests (L5)

This phase ships no UI and no user-facing copy, so `CLAUDE.md`'s overpromising,
emergency-escape, just-in-time-permission and motion-fallback rules have no
surface to apply to here. The *services* that later enforce them —
`reliability_copy_service`, `reliability_checklist_service`, `permission_service`
— port **with** their tests, which do assert the honest behaviour (no silent-mode
bypass claim on iOS, no exact-alarm copy on iOS, `permanentlyDenied` treated as
`denied`). `SleepGateway` ports with no write method, and
`test/core/sleep/sleep_boundary_test.dart` asserts CapyWake writes no sleep.

## Exclusions

- No UI. No change to `lib/features/`, `lib/design/`, `lib/app/`.
- No platform adapters (phases 05+).
- No migration history.
- No new ARB keys — Phase 01 finished the ARB.
- No new Tier A measurement: this phase changes no pixel, so `compare.dart`'s
  existing recorded state stands. `tool/capture.sh` still **runs**, as a build
  check (acceptance 13), not as a fidelity claim.

## Risks

| Risk | Mitigation |
|---|---|
| Generated `app_database.g.dart` differs from legacy in a way mappers depend on | Regenerate, then run the ported mapper + repository tests, which exercise every column |
| `very_good_analysis` 9 is stricter: this repo analyzes `tool/**` (legacy excluded it) and escalates two rules to `error` | Measure **before** fixing the porting approach — mandatory step in Adaptation 6 (H5) |
| Coverage on `lib/core` falls under 95% because fakes/barrels are counted | The legacy measured **98.97–99.30%** on core with these same 62 files and 6 fakes (tracker rows 02–06), so 95% is known-achievable and a shortfall is a porting defect, not an unrealistic gate (M5) |
| A ported test depends on legacy `test/support/` | Verified: `grep -rn "support/" test/core/` is **empty** |
| Dropping `theme_test.dart` silently loses coverage of something still ported | `theme.dart` is a verified leaf: `grep -rln "core/theme" ../capywake/lib/core/` is empty |

## Rollback

Single phase commit on `main`. `git revert` restores Phase 01's state. No
migration, no stored data, no published artifact — nothing outside the repo
changes.

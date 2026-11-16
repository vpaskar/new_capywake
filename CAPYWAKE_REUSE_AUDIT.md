# What to copy from `../capywake` — file-level audit

Written 2026-11-16, after Phase 00 was committed. Measured, not estimated:
every number below came from running the command, not from reading a doc.

This document **revises Phase 00**, which said *"no code copied from
`../capywake`; behavior is reproduced, the widget tree is written fresh."* That
was right about the widget tree and wrong about everything beneath it. See
`docs/phases/PHASE_00_SELF_REVIEW.md` for how the error happened.

## Verification performed

| Check | Command | Result |
|---|---|---|
| Does `core/` import Flutter? | `grep -rln "package:flutter" lib/core/` | **One file only** — `theme.dart` |
| Is `theme.dart` depended on from inside `core/`? | `grep -rln "core/theme" lib/core/` | **Empty** — it is a leaf, drops cleanly |
| Do core tests import feature code? | `grep -rl "capywake/features" test/core` | **0 of 48** |
| Do the core tests pass today? | `flutter test test/core` | **932 passed** |
| ARB keys coupled to the old navigation | script over `app_en.arb` | **3 of 383** |

The 932 include DST spring-forward, leap day, skip-next sequencing, and a
one-time 00:30 alarm set at 23:55 firing after midnight. That is years of
edge-case discovery we would otherwise rediscover by shipping bugs.

## Copy — high confidence

### `lib/core/` minus `theme.dart` — 62 files, 9,825 lines

Verified pure Dart. Port as-is.

| Area | Files | Notable |
|---|---|---|
| `models/` | 10 | `Alarm`, `AlarmOccurrence`, `UserSettings`, `WakeMode`, `DismissMethod` |
| `schedule/` | 2 | `alarm_schedule_service.dart` (578 lines) — DST/timezone/recurrence |
| `puzzle/` | 12 | Generators, selector, validator, exposure tracking (2,657 lines) |
| `engine/` | 6 | `AlarmEngine` + `NotificationService` abstractions, the **iOS 64-cap calculator**, `alarm_schedule_coordinator.dart`, and **fakes** |
| `sleep/` | 10 | `SleepGateway` (no write method), aggregator, sync service — feeds the Stats Sleep segment |
| `history/` | 1 | `history_service.dart` (649 lines) — feeds the Stats Alarms segment |
| `lifecycle/` | 2 | Status state machine, snooze sequencing incl. the final no-snooze alarm |
| `wake/`, `motion/`, `permissions/`, `reliability/`, `onboarding/` | 13 | Wake window, volume ramp, motion check, honest grant states |
| Root formatters | 10 | `alarm_format`, `countdown_format`, `next_alarm`, `time_stepper`, `today_format` |

**Five files take `AppLocalizations` as a parameter** —
`alarm_dismiss_summary`, `alarm_repeat`, `alarm_sound`,
`reliability_copy_service`, `reliability_checklist_service`. The coupling is
shallow: it is an argument, never a global. They port once the ARB keys exist.

### `test/core/` — 48 files, 15,503 lines

Ports with the code. Zero feature imports; 5 files need an l10n harness. This
is the regression net for the alarm core and the single strongest argument for
porting rather than rewriting.

### `lib/l10n/` — 383 keys × 10 locales, 17,662 lines

Human-quality translations including Arabic RTL and Japanese. Re-translating
is the most expensive thing we could choose to do.

Only **3 keys** are navigation-coupled: `navTodayLabel`, `navAlarmsLabel`,
`navSettingsLabel`. Everything else ports:

- 39 `today*` keys → reusable for Home
- 22 `history*` keys → move into the Stats Alarms segment
- 30 `sleep*` keys → the Stats Sleep segment
- 87 `alarm*`, 84 `puzzle*`, 35 `settings*`, 32 `reliability*` → as-is

New keys needed: `navHomeLabel`, `navStatsLabel`, the Stats segment labels, and
the Games segment. Roughly 15–25 new keys × 10 locales, not 383.

### `lib/data/` — 12 files, 2,500 lines

Drift schema at **`schemaVersion = 6`** with a real `MigrationStrategy`, DAOs,
repositories, and the platform adapters (`alarm`, `flutter_local_notifications`,
`permission_handler`, `health`, `sensors_plus`).

**Caveat:** this is a *greenfield* app with no users, so we start at
`schemaVersion = 1` with a fresh schema rather than inheriting six migrations
for data nobody has. Port the table definitions and mappers; drop the migration
history. The architecture plan already warns the new app must not accidentally
read old user data.

### `tool/` and `assets/sounds/`

`check_arb.dart`, `check_coverage.dart`, `generate_tones.dart`, and the 12
generated WAVs with a clean `LICENSES.md` (no third-party material).
Uncompressed 16-bit mono on purpose — MP3/AAC padding clicks at loop junctions
and `loopAudio` is on.

### `test/support/widget_test_harness.dart`

Worth reading before writing ours; port if it fits the new shell.

## Do not copy — this is what the rebuild replaces

| What | Size | Why |
|---|---|---|
| `lib/features/` | 45 files, **13,943 lines** | The widget tree built against the vector-capybara rule |
| `test/features/` | 37 files, 12,767 lines | Asserts the old UI, incl. "no capybara on the ringing surface" |
| `lib/features/common/capy/` | 1,939 lines | The `CustomPaint` cast — the root cause |
| `lib/core/theme.dart` | 704 lines | Old tokens; our palette is sampled from the mockups |
| `lib/app/shell.dart`, `router.dart` | 590 lines total | Today/Alarms/Settings — wrong navigation |
| `assets/art/` | — | Re-import from the handoff package through `audit_art.dart` |

## Net effect on the plan

| | Before | After |
|---|---|---|
| Phase 02 | Build the domain from scratch | **Port and adapt** the domain + its 932 tests |
| Phase 02 risk | Rediscover DST/snooze/re-arm bugs | Inherit the fixes with their tests |
| l10n | Write 383 keys × 10 locales | Port 380, add ~20 |
| Lines written by hand | ~28,000 | ~3,000 of adaptation |

Roughly **45,000 lines** of tested, translated, non-UI work is portable.

## Why this is not the retrofit that failed

The retrofit failed in the **view layer**, for a documented reason: a rule
requiring the capybara be vector `CustomPaint`. Nothing in `lib/core/` has an
opinion about how a capybara is drawn. Porting a verified-pure, 932-test domain
layer and then building a genuinely new UI on top of it is the opposite of
reskinning old widgets — it keeps what was proven and discards exactly what was
wrong.

The line is clean and it is enforceable: **if a file imports Flutter, it is not
ported.** The one exception is `theme.dart`, which imports Flutter *and* is not
ported.

# What to copy from `../capywake` — file-level audit

Written 2026-11-16, after Phase 00 was committed. Measured, not estimated:
every number below came from running the command, not from reading a doc.

**Revised 2026-11-16 by Phase 02, which executed the port.** Three figures here
were right about the legacy and wrong about what ports; they are corrected in
place and marked ⟲. The verdicts and reasoning are unchanged — only numbers
implementation disproved. See `docs/phases/PHASE_02_FULL_PROJECT_REVIEW.md` P1.

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
| Do the core tests pass today? | `flutter test test/core` | **932 passed** (⟲ 912 of them port) |
| ARB keys coupled to the old navigation | script over `app_en.arb` | **3 of 383** (⟲ ARB now done: 384 keys × 10 locales) |

The 932 include DST spring-forward, leap day, skip-next sequencing, and a
one-time 00:30 alarm set at 23:55 firing after midnight. That is years of
edge-case discovery we would otherwise rediscover by shipping bugs.
**All of those cases are in the 912 that ported, and all pass.**

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

### `test/core/` — ⟲ 47 of 48 files port: 15,245 lines, **912 tests**

Zero feature imports; 5 files need an l10n harness. This is the regression net
for the alarm core and the single strongest argument for porting rather than
rewriting.

**⟲ `theme_test.dart` does not port** — it tests `lib/core/theme.dart`, which
this document excludes two sections below, so the two claims contradicted each
other. Measured: that file is **20 of the 932**, leaving **912** ported tests
(48 − 1 = 47 files, 15,503 − 258 = 15,245 lines). All 912 pass.

Its 20 tests were not a formality: they asserted AA contrast and separator
discipline on the legacy palette. CapyWake's palette is `lib/design/tokens.dart`
and nothing asserted its contrast, so Phase 02 wrote
`test/design/tokens_contrast_test.dart` rather than let the port drop an
accessibility invariant. That test found two real AA failures in the sampled
palette — see `PHASE_02_POST_REVIEW.md`.

### `lib/l10n/` — ⟲ **done in Phase 01**: 384 keys × 10 locales

Phase 01 ported the ARB in full and adapted the three nav-coupled keys
(`navHomeLabel`, `navStatsLabel`, `navSettingsOpenLabel`), correcting 194
occurrences of "Capywake" to "CapyWake" along the way. `check_arb.dart` reports
all 10 locales complete. The "roughly 15–25 new keys" estimate below is
**discharged, not pending** — Phase 02 added none, and all 48 l10n keys the
ported `core/` files reference resolve.

The original assessment, kept for its reasoning:

#### 383 keys × 10 locales, 17,662 lines

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

**⟲ This section is load-bearing and Phase 02's plan missed it.** The plan
ported `lib/core/alarm_sound.dart` and its test without the sounds, so three
ported tests failed ("every asset exists on disk", "is a non-trivial file", "is
declared in pubspec.yaml"). Had that test not existed, the app would have
shipped a catalogue pointing at twelve absent files and nothing would have
failed until a user tapped a sound. The WAVs are **7,752 KB**, which is why
`tool/check_bundle_size.dart` now budgets every asset tree rather than art
alone. A session porting from this document should work through it item by item,
not paraphrase it.

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

| | Before | After | ⟲ Actual (Phase 02) |
|---|---|---|---|
| Phase 02 | Build the domain from scratch | **Port and adapt** the domain + its 932 tests | ported, **912** core + 83 data tests pass |
| Phase 02 risk | Rediscover DST/snooze/re-arm bugs | Inherit the fixes with their tests | inherited; all DST/leap/snooze cases green |
| l10n | Write 383 keys × 10 locales | Port 380, add ~20 | done in Phase 01: 384 × 10, **0 added in 02** |
| Lines written by hand | ~28,000 | ~3,000 of adaptation | far less: `schemaVersion`, provider trim, 4 new test files |

Roughly **45,000 lines** of tested, translated, non-UI work is portable.

⟲ **Realised.** Phase 02 ported 62 `lib/core/` files (9,825 lines), 47
`test/core/` files (912 tests), four `lib/data/` files at `schemaVersion = 1`,
four `test/data/` files (83 tests) and 12 sound assets, for a suite of **1,051
tests** with `lib/core` at **99.41%** coverage. The adaptation was mechanical:
`schemaVersion` 6 → 1 with `onUpgrade` dropped, the sleep-gateway providers
left out until `package:health` arrives, and the "Capywake" → "CapyWake"
casing fix.

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

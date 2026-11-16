# Phase 02 — post-review

**Domain and persistence: ported from the read-only `../capywake`.**
Complete 2026-11-16.

## Final state

| Gate | Result |
|---|---|
| `flutter analyze` | **zero issues**, including infos |
| `dart format --set-exit-if-changed .` | clean |
| `build_runner` | regenerated `app_database.g.dart` (4,661 lines) before the format check |
| `check_arb.dart` | 10 locales complete, 384 keys, **unchanged by this phase** |
| `check_bundle_size.dart` | every tree inside budget: art 1818/2182 KB, sounds 7752/7800 KB, fonts 946/1100 KB — **10,517 KB total** |
| `flutter test` | **1,051 pass**, 0 fail |
| coverage `lib` | **97.14%** (3262/3358) against 85% |
| coverage **`lib/core`** | **99.41%** (2511/2526) against **95% — the gate this phase re-enabled** |
| coverage `lib/data` | 85.08% (422/496) against 85% — **new gate** (self-review #2 G1) |
| `tool/capture.sh` | 3 PNGs verified at 1179×2556 — the native-dependency build check |
| `../capywake` | **byte-identical to the pre-port baseline** |

### The test identity closed exactly

The pre-review (H1) fixed every term **before** implementation so the result
could not be rationalised afterwards:

| Term | Expected | Actual |
|---|---|---|
| ported `test/core/` | 912 | **912** |
| ported `test/data/` | 83 | **83** |
| Phase 01 existing | 43 | **43** |
| new this phase (N) | 5 | **13** |
| **total** | 1,043 | **1,051** |

N came out 13, not 5: the token-contrast test split into 9 cases because the
palette has three surfaces in each of light and dark. Per the plan's own rule
the identity is **restated, not quietly passed** — 912 + 83 + 43 + 13 = 1,051.
Every ported term hit its pre-registered figure exactly.

## The two things that gated this phase

**1. The `lib/core` ≥ 95% coverage gate is back on, at 99.41%.** Phase 01 skipped
it legitimately (`lib/core/` did not exist and `check_coverage.dart` `exit(2)`s
on an absent path rather than passing trivially). It is now in `CLAUDE.md`, the
tracker and this phase's acceptance criteria, and the Phase 01 exception note is
marked closed. The figure matches the legacy's own 98.97–99.30% on the same
files, which is what self-review M5 predicted.

**2. The 912 ported tests pass**, including the regression net this port exists
for: DST spring-forward, fall-back overlap, leap day, skip-next sequencing, and a
one-time 00:30 alarm set at 23:55 firing after midnight.

Seven tests failed after the raw copy. None was a defect in ported logic and none
was deleted or skipped — see "What failed and why" below.

## Review tally

| Pass | Findings | Applied | Invalid |
|---|---|---|---|
| Pre-review | 20 (6H / 8M / 6L) | 20 | 0 |
| Self-review #1 | 9 (3H / 4M / 2L) | 9 | 0 |
| Self-review #2 | 6 (2H / 3M / 1L) | 6 | 0 |
| Full-project review | 5 (1H / 2M / 2L) | 5 | 0 |
| **Total** | **40** | **40** | **0** |

Two findings caught errors in the pre-review's own first draft: H1's data-test
count was estimated at 66 and measured at **83** (26% out), and M7's assumption
that `../capywake` was clean was false before a single file moved.

## What failed and why — the seven

| Failures | Cause | Resolution |
|---|---|---|
| 3 × `alarm_sound_test` "bundled assets" | `assets/sounds/` was never ported. `CAPYWAKE_REUSE_AUDIT.md` lists it; the plan and its pre-review both missed it | Ported the 12 WAVs + `LICENSES.md` + `tool/generate_tones.dart`, declared in `pubspec.yaml`. **Would have shipped a catalogue pointing at twelve absent files** had the test not existed |
| 3 × `sleep_boundary_test` | Asserted the *presence* of `live_sleep_gateway.dart`, `NSHealthShareUsageDescription` and `READ_SLEEP` — infrastructure phase 07/08 adds | Rewrote as the negative invariant they protect (never write, never spread) plus a conditional that binds the moment `READ_SLEEP` appears. Restoration obligation recorded in the tracker's 07/08 rows, not only in a code comment |
| 1 × iOS plist read `Capywake` | Phase 01's 194-occurrence ARB casing fix never reached the platform manifests | `CFBundleDisplayName` and `android:label` now read **CapyWake** — both user-visible |

## Adaptations made

- **`schemaVersion` 6 → 1**, `onUpgrade` dropped entirely, and the five
  now-false "Added in schema vN" column comments removed. **The dropped-column
  trap was checked** (H4): the legacy's v3 → v4 step *drops*
  `alarms.final_alarm_minutes_after` and `alarm_occurrences.final_at` by
  rebuilding each table, so starting at v1 with `createAll()` would resurrect
  either one if it were still declared. Both verified absent, and now asserted
  by N4 against the live schema rather than inferred from a migration comment.
- **`data/providers.dart` ported minus the two sleep-gateway providers** — the
  only lines needing `package:health`. Draft 1 excluded the file whole on the
  wrong grounds (it also cited `flutter_riverpod`, a dependency since Phase 01),
  which would have left Phase 03 unable to read an alarm from the database.
- **"Capywake" → "CapyWake"** across 39 prose occurrences, plus the identifier
  `CapywakeRepository` → `CapyWakeRepository` and its two files renamed.
  `capywake.sqlite` and `CFBundleName` stay lowercase — a filename and a bundle
  short name, not display strings.
- **No platform plugin added.** The five abstractions and their fakes all live
  in `lib/core/` and port now, so nothing downstream is blocked.
- **Three `// ignore_for_file: prefer_initializing_formals`**, each with the
  one-line fact: a *private named* initializing formal (`A({required this._x})`)
  compiles but is **not callable** — verified with a minimal program, not
  assumed. `analysis_options.yaml` is untouched. Two earlier attempts were
  reverted, one of which would have made five ported fields public to satisfy a
  style info.

## Palette: two real AA failures found, recorded not silenced

Dropping `theme_test.dart` would have lost 20 contrast and separator assertions
with no equivalent for CapyWake's own palette (pre-review H2). Its replacement,
`test/design/tokens_contrast_test.dart`, immediately found two defects in the
Phase 01 tokens:

| Pair | Measured | Required | Verdict |
|---|---|---|---|
| `cocoa` on cream / surface / surfaceAlt | ≥ 4.5 | 4.5 body | passes |
| `cocoaSoft` on cream | 4.49 | 4.5 body | large text only |
| **`accentDeep`** on the three light surfaces | 2.60 / 2.62 / **2.26** | 3.0 UI | **fails everywhere** |
| **`accent`** on the three | 2.03 / 2.04 / 1.76 | 3.0 UI | **fails everywhere** |
| **`success`, `grass`** on the three | 2.30–2.68, 1.87–2.17 | 3.0 UI | **fails everywhere** |
| **`error`** on surfaceAlt | **3.93** | 4.5 body | **fails** |
| `error` on cream / surface | 4.53 / 4.56 | 4.5 body | passes, marginally |
| dark `darkInk`, `darkInkSoft`, `accent` | all clear | — | passes |

**Two open design constraints, with owner impact — reported in-session:**

- **F1.** In light mode, no control may use `accent`, `accentDeep`, `success` or
  `grass` as its *only* channel for boundary or state. It needs ink, a shape
  change or a label too. (The accent as a **fill** under `cocoa` text clears AA
  comfortably — that pairing is fine and is asserted.)
- **F2.** Error text may not sit on `surfaceAlt`.

Both are now **checked properties**: the tests assert the current weakness and
fail if a token strengthens, forcing a deliberate update rather than silent
drift. Retuning a palette sampled from the mockups is a Tier A decision for the
owner and a UI phase, not for a domain port — so this phase measured and
recorded rather than changed it. **Phase 03's Home screen is the first consumer
and should be designed against F1.**

## Coverage: the figure that needs its explanation attached

> **⟲ Corrected by Phase 03.** The structural explanation below is true, and
> the conclusion drawn from it — that 85.08% was therefore the honest figure —
> was not. Part of that number was an **accident**: five providers
> (`proStatusStreamProvider`, `puzzleSettingsStreamProvider`,
> `sleepNightStoreProvider`, `sleepSyncStateStreamProvider`,
> `sleepNightsStreamProvider`) were never read by any test and counted as
> covered only because something in the suite constructed the graph far enough
> to execute their declarations. When Phase 03's Home tests began overriding
> `appDatabaseProvider` with an in-memory database, that stopped and the figure
> fell to **82.76%** — the first honest measurement of the tree, not a
> regression Home caused. A typo in any of those five would have shipped.
> `test/data/providers_test.dart` now reads every provider against a real
> database; `lib/data` is **86.40%**, earned rather than incidental. The
> general lesson: *"this number is depressed for a structural reason"* needs
> its own evidence, because it is equally consistent with the number being
> inflated somewhere else. See `PHASE_03_FULL_PROJECT_REVIEW.md` P3.

`lib/data` reads **85.08%** (422/496) and is the repository's weakest tree. The
reason is structural, not a testing gap: `lib/data/database/app_database.dart`
measures 8% (6/73) because its `Table` column getters —

```dart
TextColumn get id => text()();
```

— are evaluated by Drift at **build time** to generate `app_database.g.dart`,
and never execute at runtime. They are unreachable by any test that could be
written, while the generated file that does the work is excluded from coverage by
design. Over lines a test can actually reach, `lib/data` is **422/429 = 98.4%**;
`mappers.dart` is 263/263 and the repository 144/151.

Written down because the three obvious "fixes" — a meaningless test, a
`// coverage:ignore` (which `CLAUDE.md` forbids), or a lowered gate — are all
wrong, and someone will reach for one otherwise.

| Tree | Coverage | Lines |
|---|---|---|
| `lib/core` | 99.41% | 2,526 |
| `lib/app` | 100.00% | 58 |
| `lib/features` | 100.00% | 11 — Phase 01 placeholders; carries no information |
| `lib/design` | 97.38% | 267 |
| `lib/data` | 85.08% | 496 (98.4% of reachable lines) |

## Documents corrected

Four documents asserted things the implementation disproved:

- **`CAPYWAKE_REUSE_AUDIT.md`** — said `test/core/` is "48 files… ports with the
  code" while the same document excluded `theme.dart`; said "932 tests" as the
  ported figure; said ~15–25 ARB keys were still needed. Now 47 files / 912
  tests / ARB discharged, each marked ⟲ with its measurement. Its
  `assets/sounds/` section is flagged as load-bearing, since skipping it cost
  three test failures.
- **`CLAUDE.md`** and **`PHASE_TRACKER.md`** — both listed
  `dart run tool/audit_art.dart` as a per-phase gate. **No such file exists**;
  running it errors. The art audit is `lib/design/art_audit.dart`, applied by
  `tool/import_art.dart` and gated by two design tests inside `flutter test`.
  A validation line that errors is one a session learns to skip.
- **`PHASE_TRACKER.md`** — gained the `lib/data` gate, the G2 explanation, and
  the sleep-boundary restoration obligation on rows 07/08.

## Tier A

Unchanged, and deliberately so: this phase ships no UI. `capture.sh` ran as the
native-dependency build check (H3 — `sqlite3_flutter_libs` ships prebuilt
iOS/Android SQLite that `check_bundle_size.dart` cannot see) and Xcode fetched
CSQLite via SPM without error. The three captures were regenerated as a **build
artifact, not a new fidelity measurement**. Phase 01's recorded state stands:
header matches to **0.1 pt**, three body blocks still absent because the screens
have no bodies — Phase 03's work.

> **⟲ Corrected by Phase 03.** The clause "because the screens have no bodies"
> is wrong and was repeated here from `PHASE_01_POST_REVIEW.md`. Only the nav
> bar row had that cause. The two hero rows were a real `SceneHeader` defect —
> the cream card drawn inside the art's `Stack`, shortening every hero band by
> 11.1 pt — which Phase 03's first capture of a screen with a body exposed as
> 13 of 14 blocks failing. Fixed; the hero lower edge now measures **0.0 pt**.
> See `PHASE_03_FULL_PROJECT_REVIEW.md` P1.

## What Phase 03 may assume

**Real and available:** all of `lib/core/` — models, DST-correct schedule math,
the puzzle engine, history, lifecycle FSM, sleep aggregation, wake window,
reliability copy — plus the Drift database at v1, mappers, repository, and the
Riverpod provider graph.

**Interface + fake only, no platform implementation:** `AlarmEngine`,
`NotificationService`, `SleepGateway`, `MotionSensor`, `PermissionService`.
`lib/core/engine/alarm_engine.dart` exists, **but nothing rings.** Adapters land
in phase 05 (engine, notifications) and 07/08 (permissions, sleep). Do not
conclude from the presence of these files that an alarm can fire.

**Not available:** any platform plugin; migration history; sleep reads from
Apple Health / Health Connect.

## Honest limitations

- **Android is unverified.** No emulator was run. `android:label` was corrected
  but nothing Android was executed.
- **No device testing.** Phase 05 owns that; nothing here is marked "tested on
  device".
- **The 83 ported data tests exclude the migration suite** (`migration_test.dart`,
  `migration_v6_test.dart`, 1,153 lines) by design — they assert the history this
  phase drops.
- **`lib/data/engine/`, `motion/`, `permissions/` and `live_sleep_gateway.dart`
  are not ported.** Their phases are 05–08.
- **The palette failures above are recorded, not fixed.**

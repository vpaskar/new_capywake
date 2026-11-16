# CapyWake legacy audit

Written 2026-11-16 against `../capywake` @ `main`, read-only. Required by
`CapyWake_Flutter_Rebuild_Handoff/00_AGENT_MASTER_PROMPT.md` before any code.

Nothing in `../capywake` was modified. Every claim below is a file I opened.

## Headline

The handoff package describes the legacy project as a source of "product logic
and workflow". It undersells it. `../capywake` is a **mature, 40-phase,
99-test-file Flutter app** with a fully tested alarm core, 10 shipped locales,
and a phase/review ritual far stricter than the one the handoff proposes.

The thing that is genuinely wrong with it is the thing we are here to fix: its
**visual layer does not look like the mockups, and could not**, because of a
rule it imposed on itself. That rule is identified below and is the single most
important finding in this audit.

## 1. Process artifacts actually found

Reported as found, not invented. All paths are real.

| Artifact | Path | What it is |
|---|---|---|
| Phase tracker | `ai-orchestration/PHASE_TRACKER.md` | Single source of truth, `Current phase:` pointer read by a runner |
| Phase files | `ai-orchestration/phases/phase-00..47-*.md` | 48 files, one per phase |
| Phase template | `ai-orchestration/templates/phase-template.md` | Goal / Must implement / Must not implement / Acceptance / Validation / reviews |
| Workflow spec | `ai-orchestration/prompts/do-whats-next.md` | 30-step unattended-run protocol |
| Run logs | `ai-orchestration/logs/phase-*.log` + `.transcript.jsonl` | 13 real recorded runs |
| Project rules | `CLAUDE.md` (33 KB) | Hard rules, design rules, copy rules, git rules |
| Running narrative | `memory/current-phase.md`, `memory/progress.md` | Updated on every phase completion |
| Session docs | `docs/sessions/current.md`, `docs/sessions/next.md` | Session handoff |
| Redesign audit | `CAPYWAKE_REDESIGN_AUDIT.md` | The failed retrofit's own audit, 2026-11-15 |
| Architecture | `docs/architecture/capywake-architecture.md` | |
| Reliability | `docs/platform/capywake-alarm-reliability.md` | Platform limits with sources |

**Status: 40 of 47 phases `done`.** Pointer sits at phase `40`. Phases 40–46
(the ten games) are `pending` and were never built.

### The review ritual, as actually practiced

Per phase, from `phase-template.md` and `do-whats-next.md`:

1. Phase file is canonical for scope.
2. Implement only that phase.
3. Run validation.
4. **Phase self-review #1** → classify every finding High/Medium/Low → apply
   *all* of them.
5. Re-validate. **Phase self-review #2** → same.
6. Re-validate. **One full-project self-review** → same.
7. Final validation, tracker update, memory update, commit to `main`.

The rule with teeth: **"deferred", "out of scope", "minor — skipped" are not
acceptable outcomes for a finding.** A finding is either *applied* or marked
*invalid with a one-line reason*. Low findings get fixed in the phase that
raised them.

Note the asymmetry with the handoff: the handoff asks for a **pre**-review
before implementation; the legacy practices **two post**-reviews plus a
full-project review. The new repo will do **both** — see the architecture plan.

### Validation gates actually enforced

```
flutter pub get
flutter gen-l10n                                           # if ARB changed
dart run build_runner build --delete-conflicting-outputs   # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                            # zero issues, incl. infos
dart run tool/check_arb.dart                               # all 10 locales complete
flutter test --coverage
dart run tool/check_coverage.dart                          # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
```

Generators run **before** the format check. `very_good_analysis` lints.

### Git rules

`main` is the only permitted branch. No feature branches, no worktrees, no
stashes. Commit per phase: `feat: complete phase <id> - <name>`, followed by
`chore: record phase <id> commit hash`.

## 2. Why the previous visual attempt failed

This is the finding that shapes the entire rebuild.

`CLAUDE.md` → Design states, verbatim:

> The capybara is **drawn** (`CapyFigure` / `CapyScene` / `CapyThumb`, never a
> raster cutout) and appears only where a surface is genuinely calm — never on
> the ringing surface, never on a functional control, never as an icon, never
> tinted […] never more than once on a surface.

`CAPYWAKE_REDESIGN_AUDIT.md` → Stage A reinforces it:

> Native-drawn cartoon mascot + scenery component model (CustomPaint/vector —
> **no raster cutouts** from the posters, which are flattened and won't theme).

The result is `lib/features/common/capy/` — 1,939 lines of `CustomPaint`
(`capy_painter.dart`, `capy_figure.dart`, `capy_scene.dart`, `capy_scenery.dart`,
`capy_pose.dart`, `capy_palette.dart`). It is competent code. It themes
perfectly in light and dark. It is also a geometric approximation of a
capybara, and the mockups are **painted storybook illustrations** with textured
fur shading, rim light from a bedroom lamp, a sunrise gradient through a
window, hanging pothos leaves and a ceramic mug with a capybara face on it.

**No amount of `CustomPaint` reaches that.** The rule guaranteed the gap. The
retrofit was not under-executed; it was correctly executing an instruction that
made the goal unreachable.

Two further self-imposed constraints compounded it:

- **"never more than once on a surface"** — but `01_HOME.png` shows a capybara
  in the wordmark, a capybara in the hero scene, and four capybaras in the
  game cards. Six on one screen.
- **"never on the ringing surface"** — phase 39 added a test asserting no
  figure appears while an alarm rings. The game posters all feature a capybara
  mid-challenge.

These were reasonable rules for the app the legacy team was building. They are
wrong for the app the mockups describe. **The new repo does not inherit them**
(owner decision, 2026-11-16 — see Decisions).

### The navigation claim that was also wrong

`CAPYWAKE_REDESIGN_AUDIT.md` asserts:

> The handover mandates **Today / Alarms / Settings** […] **No navigation
> change is needed**, and the handover's own reference PNGs showing
> Games/Stats/Premium/Profile tabs are explicitly disregarded.

That was defensible against the *older* boards. It is not defensible against
`01_REFERENCES/screens/primary/`, which is dated later and is the user's
explicit latest direction. Resolved below.

## 3. Alarm domain — what is proven and worth preserving

Behavior, not code. These are the semantics the new app must reproduce.

### `Alarm` (`lib/core/models/alarm.dart`)

Immutable, value-equal, pure Dart, no derived state (no cached "next fire
time" — derived data is computed on demand "to stay honest").

| Field | Semantics |
|---|---|
| `id` | UUID, survives edits |
| `label` | May be empty |
| `enabled` | Disabled alarm produces **no** occurrences |
| `targetTimeMinutes` | **Minutes since local midnight**, 0..1439 |
| `repeatWeekdays` | ISO-8601, Mon=1..Sun=7. **Empty set = one-time** |
| `wakeMode` | Gentle / Standard / Strict |
| `wakeWindowStartMinutesBefore` | Soft-start offset; 0 = none |
| `soundId` | Empty = vibration only |
| `vibrationEnabled`, `snoozeEnabled`, `snoozeDurationMinutes`, `maxSnoozes` | `maxSnoozes: null` = unlimited |
| `dismissMethod` | normal / hold / puzzle |
| `dismissChallengeDifficulty`, `puzzleOverride` | **Throws** if set while `dismissMethod != puzzle` |
| `confirmationEnabled`, `motionConfirmationEnabled` | Post-dismiss "still up?" |

Constructor asserts every range. Corrupt data fails the round-trip test rather
than producing a nonsense 03:00 schedule.

**Convention to carry over verbatim:** clock times are integer
minutes-since-midnight in data/calc layers, formatted to a display string only
at the UI boundary via `intl`. Durations are integer minutes.

### Core services

| Path | Responsibility |
|---|---|
| `core/schedule/alarm_schedule_service.dart` | Occurrence computation; weekday loops, timezone, DST |
| `core/schedule/local_time_of_day.dart` | Minutes-since-midnight value type |
| `core/wake/wake_window_service.dart` | Soft-start window |
| `core/wake/wake_volume_ramp.dart` | Volume escalation |
| `core/lifecycle/alarm_status_service.dart` | Armed / ringing / snoozed / done state machine |
| `core/lifecycle/snooze_service.dart` | Snooze sequencing incl. the **final no-snooze alarm** |
| `core/engine/alarm_engine.dart` | Platform abstraction (+ `fake_alarm_engine.dart`) |
| `core/engine/notification_schedule_calculator.dart` | Caps pending notifications at the **iOS 64 limit** |
| `core/engine/alarm_schedule_coordinator.dart` | Reconciles DB state against armed OS alarms |
| `core/permissions/` | Honest per-platform grant states |
| `core/reliability/` | All caution copy funnelled through `ReliabilityCopyService` |
| `core/puzzle/` | 12 files: generation, selection, validation, exposure tracking |
| `core/history/` | Real logged wake events |
| `core/sleep/` | `SleepGateway` — **read-only, no write method** |

### Edge cases the legacy learned the hard way

Named in phase titles and memory files, each a real bug that shipped a fix:

- phase 34 — *"A finished occurrence must stop being re-armed"*
- phase 33 — *"Name the final alarm on the ringing surface"*
- phase 32 — final-alarm semantics (the alarm after the last snooze)
- phase 24 — post-dismiss motion "still up?" check
- dismiss-exactly-once (`ringing_screen.dart:116`)
- iOS 64-pending-notification cap
- Reboot / DST / device-time-change reconciliation

### Dependency stack (locked and justified in `pubspec.yaml`)

`alarm: ^5.3.0` (silent audio session on iOS, exact alarms + foreground service
on Android) · `drift ^2.32.1` · `flutter_riverpod ^3.3.1` (**no**
`riverpod_generator` — incompatible with pinned `meta`) · `go_router ^17.2.2` ·
`flutter_local_notifications ^21.0.0` (supporting reminders only) ·
`timezone ^0.11.0` · `permission_handler ^12.0.1` · `health ^13.3.2`
(read-only) · `sensors_plus ^7.0.0` — **deliberately chosen over `pedometer`**
to avoid `ACTIVITY_RECOGNITION` (Android 10+) and Motion & Fitness (iOS).

That last one is a real platform decision with a cost: **Step Quest cannot be
built without reversing it.**

### Puzzle types actually shipped

`arithmetic`, `sequenceNext`, `missingOperator`, `compareValues`,
`oddOneOutNumeric`, `digitRecall`, `digitRecallReversed`, `gridPatternRecall`,
`spotTheChange`, `shapeRotation`.

**Disjoint from the handoff's ten games.** Zero overlap. The ten games are ten
new products, as the legacy audit itself concluded.

### Audio assets worth reusing

`assets/sounds/` — 12 generated WAVs with `LICENSES.md` confirming no
third-party material. Uncompressed 16-bit mono **on purpose**: MP3/AAC encoder
padding clicks at every loop junction and `loopAudio` is on. Generated by
`tool/generate_tones.dart`.

## 4. Safety rules worth inheriting unchanged

These are good and they stay:

- No "never oversleep" claims, no implied silent-mode/DND bypass, no
  sleep-stage detection, no fear/shame copy. Overpromising = High finding.
- Never claim more reliable than the OS clock app, especially on iOS.
- **No puzzle without a reachable emergency escape.** Locking someone out of
  silencing their own alarm is a safety defect and always a High finding.
- Puzzle shape is user-configurable: type, task count, difficulty, tolerated
  wrong answers.
- No gamifying the puzzle: no scores, streaks, personal bests on the *puzzle*.
- No auth, cloud sync, backend, social/leaderboard features, fake analytics.
- Core alarm controls large and reachable — a half-asleep user, no precision
  tapping.
- Calm copy. "Alarm set for 07:00", not "Crush your morning".

## 5. Rules deliberately NOT inherited

Owner decisions, 2026-11-16, recorded here because reversing a documented
legacy rule silently would be exactly the failure mode the handoff warns about.

| Legacy rule | New rule | Why |
|---|---|---|
| Capybara is vector `CustomPaint`, never a raster cutout | **Raster art is the medium.** Bundle the supplied PNGs and composite real widgets over them | The vector rule is why the retrofit could not match the mockups |
| Never more than one capybara per surface | As many as the mockup shows | `01_HOME.png` shows six |
| Never a capybara on the ringing surface | Allowed where the mockups show one | Game posters all feature one mid-challenge |
| Nav = Today / Alarms / Settings (3 tabs) | **Home / Alarms / Stats** tabs, Settings via gear | Resolved below from the primary mockups |
| No sleep metrics | Sleep tab fed by Apple Health / Health Connect, read-only | The `SleepGateway` already exists and is read-only |

Costs accepted with the raster decision: bundle grows to roughly 3–6 MB, and
the art does not re-tint for dark mode (dark mode becomes a scrim/overlay
treatment, decided per-screen, not a repaint).

## 6. Navigation conflict — resolved

The master prompt requires this be settled explicitly in Phase 0.

**Evidence from the primary mockups**, which are the user's latest direction:

| Screen | Bottom nav | Settings reached by |
|---|---|---|
| `01_HOME.png` | Home (active) · Alarms · Stats | gear, top-right |
| `02_ALARMS.png` | Home · Alarms (active) · Stats | gear, top-right |
| `03_ADD_EDIT_ALARM.png` | none — pushed route with back chevron | — |
| `04_SETTINGS.png` | none — pushed route with back chevron | — |
| `05_STATS.png` | Home · Alarms · Stats (active) | gear, top-right |

Four of five screens agree. Settings carries a back chevron and no bottom nav,
so it is unambiguously a **pushed route, not a tab**.

**Decision: three tabs — Home / Alarms / Stats. Settings is a pushed route from
the gear in the header. History lives inside Stats. Reliability Checklist and
Setup Walkthrough live inside Settings.**

This supersedes `CAPYWAKE_REDESIGN_AUDIT.md`'s "no navigation change is
needed". Settings remains always accessible, as the product contract requires.
No fourth or fifth tab is introduced.

## 7. Stats data — resolved

`05_STATS.png` shows `Sleep | Alarms | Games` segment tabs and, under Sleep,
Avg. Sleep 7h32m, a 7-day duration chart, Current Streak, Goal 8h, and average
bedtime/wake-up/total.

The handoff forbids fabricated sleep metrics. The legacy app already reads real
sleep from Apple Health / Health Connect through a read-only `SleepGateway`.

**Decision: build all three segments.** Sleep from Health (with an explicit
"connect Health" empty state and no numbers at all until data exists), Alarms
from real logged wake events, Games from real puzzle/game history. The mockup's
layout is matched; none of its numbers are hardcoded.

The one copy change: the mockup's "Goal 8h / Avg. 94%" is only shown once the
user has set a sleep goal and Health has supplied enough nights to compute it.
No invented percentage ships.

## 8. The ten games — honest status

Zero of ten exist in the legacy app. Phases 40–46 are `pending` and were never
run. Two carry real platform blockers:

- **Step Quest** needs step counting. `sensors_plus` was chosen specifically to
  avoid `ACTIVITY_RECOGNITION` / Motion & Fitness. Reinstating a pedometer is a
  deliberate permission decision, not a side effect.
- **QR Treasure Hunt** needs a camera dependency that does not exist today.

Also: `Morning Sort` and `Find the Impostor` need authored content banks, which
the legacy `CLAUDE.md` bans for locale reasons. The ban was lifted for these
two specifically (owner, 2026-11-15) — to be recorded in guardrail docs when
those games are built, not before.

They are sequenced late and tracked individually as
implemented / adapted / blocked with test evidence. **Four game cards appear on
the Home mockup** (Step Quest, Shake DJ, Catch the Capy, Find the Impostor), so
Home must render the card rail gracefully before any game is playable.

## 9. Toolchain verified on this machine

- Dart SDK **3.12.2** stable, macos_arm64
- iPhone 14 Pro simulator (iOS 16.4) — **matches the mockup geometry**
- A physical iPhone (iOS 27.2.1) is reachable for real alarm testing
- Mockups are **851 × 1847 px**, aspect 0.4607 ≈ **393 × 852 logical pt** at
  2.166×. iPhone 14 Pro is 393 × 852. Screenshot comparison is therefore exact,
  not approximate.

No Android emulator is currently running — Android verification is an explicit
open item, not an assumed pass.

## 10. What this audit does not claim

- No code has been copied from `../capywake`, and none will be. Behavior is
  reproduced; the widget tree is written fresh.
- No device screenshots have been taken yet. The legacy repo never captured any
  either (`CAPYWAKE_REDESIGN_AUDIT.md`: "the auto-chain has no display").
- The legacy test suite has not been run; its pass state is taken from the
  tracker, not re-verified.
- Android behavior is unverified on this machine today.

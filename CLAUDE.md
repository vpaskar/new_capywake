# CLAUDE.md — CapyWake (greenfield rebuild)

A cozy, capybara-themed smart alarm for iOS and Android, rebuilt from scratch
against the illustrated mockups in
`~/Downloads/CapyWake_Flutter_Rebuild_Handoff/`.

## First-session checklist

1. `pwd && git branch --show-current` — must be `new_capywake` on `main`.
2. Read `ai-orchestration/PHASE_TRACKER.md` → `Current phase:`.
3. Read `memory/current-phase.md` and `docs/sessions/next.md`.
4. Read `CAPYWAKE_LEGACY_AUDIT.md` and `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md`.
5. Read the handoff's `04_WORKSPACE_STATE/PROJECT_STATE.md`.
6. Write the phase plan, then the **adversarial pre-review**, then revise, then
   implement. Never code first.

## The two projects

- **This repo** is the only place anything is written.
- **`../capywake` is READ-ONLY.** It is the behavior and process reference.
  Never edit, refactor, reformat or delete anything in it. Harvest semantics
  and edge cases; never copy widget code.

## Source of truth for the UI

`~/Downloads/CapyWake_Flutter_Rebuild_Handoff/01_REFERENCES/screens/primary/`
— `01_HOME.png`, `02_ALARMS.png`, `03_ADD_EDIT_ALARM.png`, `04_SETTINGS.png`,
`05_STATS.png`. These override every earlier board and exploration.

**They are 851×1847 px = 393×853 pt = iPhone 14 Pro.** Compare captures at that
exact viewport.

### The fidelity contract

**Tier A — structural. Binding, ±4 pt on major block positions at 393×852.**
Geometry, proportions, palette, type scale and weight, radii, control shapes
and states, art placement. Deltas over tolerance are defects.

**Tier B — illustration. Best-effort, always declared.** The mockups contain
art that is not in the asset package (verified: the Home hero's nightcap, duck
and nightstand clock do not exist in `today_integrated.png`). Use the nearest
supplied asset and **log the substitution by name**. Never generate new art.
Never claim a substitute is the original.

A screen is done when the comparison is captured and its deviations are named
— not when it functions.

## Navigation — decided in Phase 00, do not relitigate

Three tabs: **Home · Alarms · Stats**. Settings is a **pushed route** from the
gear in the header, reachable from all three tabs. History lives in Stats;
Reliability Checklist and Setup Walkthrough live in Settings. No fourth tab.

## Art rules

Raster is the medium (owner decision, 2026-11-16). The legacy's "capybara is
vector `CustomPaint`, never a raster cutout" rule is **not inherited** — it is
why the previous attempt could not match the mockups.

- Art goes **behind** content, never on top of a control.
- Text is always a real `Text`; buttons are always real widgets. **Never** ship
  a raster button with baked-in copy — it cannot localize into 10 languages.
- Scenes crop (`BoxFit.cover` + per-scene `Alignment`), never distort, never
  cut the capybara's face.
- As many capybaras per screen as the mockup shows. `01_HOME.png` has six.
- Every imported asset passes `tool/audit_art.dart` (alpha, ghost pixels,
  margins, intrinsic size).
- No animation on the ringing surface. Honor `disableAnimations` everywhere.

## Content integrity — the three screens that will try to lie

- **Stats:** the empty state is the **default**, not the fallback. No numeric
  literal in a user-facing position in `lib/features/stats/`
  (`tool/check_no_fake_stats.dart` enforces it). Demo data lives in tests and
  goldens only. No fabricated sleep averages, goals or percentages.
- **Settings:** show only implemented rows. Backup & Sync and Restore Purchases
  are dropped — there is no backend and nothing to restore.
- **Home:** the game rail reads from a typed catalogue; a `comingSoon` card is
  marked and opens a "not built yet" sheet, never a dead tap.

## Safety rules — inherited from the legacy, unchanged

- **No overpromising.** No "never oversleep", no implied silent-mode/DND
  bypass, no sleep-stage detection, no fear or shame copy. Never claim more
  reliable than the OS clock app, especially on iOS. Overpromising is a High
  finding.
- **Never ship a puzzle without a reachable emergency escape.** Locking someone
  out of silencing their own alarm is a safety defect and always a High finding.
- Puzzle shape is user-configurable: type, task count, difficulty, tolerated
  wrong answers. No scores, streaks or personal bests on the puzzle.
- Core alarm controls are large and reachable — a half-asleep user, no
  precision tapping.
- No auth, cloud sync, backend, social/leaderboard features, or fake analytics.
- Permissions are requested **just-in-time**, with the reason shown.
- Motion-based games need a non-motion fallback.

## Copy

Calm, neutral, practical, non-judgmental. Good: "Alarm set for 07:00", "Soft
wake starts 06:45", "You're up", "Snoozed once", "No alarm set". Avoid: "Crush
your morning", "Never oversleep again", "You failed", and any fake
sleep-science claim.

Puzzle copy is a quiet instruction, never a taunt or a cheer: "Which number
comes next?" not "Prove you're awake".

## Architecture

```
lib/
  app/       bootstrap, router, theme wiring, AppShell
  core/      pure Dart domain — NO Flutter widgets
  data/      Drift, DAOs, repositories, platform adapters
  design/    tokens + shared illustrated components
  features/  home alarms stats settings onboarding ringing games reliability
  l10n/      10 ARB files
```

- `core/` imports no Flutter. It is headless and fully testable.
- The platform alarm engine sits behind `core/engine/AlarmEngine`; only `data/`
  imports the `alarm` package.
- Clock times are **integer minutes since local midnight** in data/calc layers,
  formatted at the UI boundary via `intl`. Durations are integer minutes.
- Models carry no derived state — no cached "next fire time".
- `SleepGateway` has **no write method**. CapyWake reads sleep, never writes.
- Riverpod 3 only, no `riverpod_generator`.
- Tests mirror `lib/` under `test/`.

## Validation (every phase)

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build --delete-conflicting-outputs    # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales
dart run tool/audit_art.dart
dart run tool/check_bundle_size.dart
flutter test --coverage
dart run tool/check_coverage.dart                           # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
```

Generators run **before** the format check.

Locales: `en de ru es tr fr it pt ar ja`. Arabic is RTL — direction-aware
widgets only (`EdgeInsetsDirectional`, `start`/`end`), never hardcoded
`left`/`right`. Adding a key to one ARB without the other nine fails the gate.

## Review discipline

Per phase: plan → **adversarial pre-review** → revised plan → implement →
validate → self-review #1 → self-review #2 → full-project review → post-review
→ tracker/memory/session update → commit.

Classify every finding **High/Medium/Low**. **Apply all of them.** The only
alternative is marking a finding **invalid with a one-line reason**.
"Deferred", "out of scope" and "minor — skipped" are not outcomes. A Low
finding that feels too small to fix takes 30 seconds — fix it.

## Git

- **`main` is the only branch.** No `checkout -b`, no worktrees, no stashes.
- Per-phase commit `feat: complete phase <id> - <name>`, then
  `chore: record phase <id> commit hash`.
- Never `--no-verify`, never `push --force`, never amend a commit on `main`.
- Pre-flight every session: `pwd && git branch --show-current`.

## Store publishing

Drafts only. Never submit, publish, release or roll out. The owner presses
every final button. (Inherited from `pets/CLAUDE.md`.)

## Comments

The code explains itself. Do not write comments that restate the next line.
The only exception is a fact that cannot be expressed in code — a platform
quirk, a store constraint, a persisted enum order — and then it is one line.
(Inherited from `pets/CLAUDE.md`.)

## Hard rules

- Do not implement future phases.
- Do not add a dependency not listed in the current phase file.
- Do not leave TODO-only placeholders.
- Do not lower or bypass the coverage gate; never add `// coverage:ignore` or
  thin a test to game the ratio.
- Do not hardcode user-facing strings in widgets.
- Do not claim a screen matches without a recorded capture.
- Do not mark anything "tested on device" that was not actually run on one.
- If the tracker and a phase file conflict, **stop and explain** — do not guess.

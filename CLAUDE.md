# CLAUDE.md — CapyWake (greenfield rebuild)

A cozy, capybara-themed smart alarm for iOS and Android, rebuilt from scratch
against the illustrated mockups in
`~/Downloads/CapyWake_Flutter_Rebuild_Handoff/`.

## Start of every session — do this before anything else

**"Start phase NN", "continue", or "do what's next" all mean: run this
checklist first.** It is not optional and it is not a formality — Phase 00
skipped its own reviews and shipped a High defect because of it.

1. `pwd && git branch --show-current` — must be `new_capywake` on `main`.
2. Read `ai-orchestration/PHASE_TRACKER.md` → `Current phase:` and the
   protocol. **The tracker is canonical for what phase you are on and what
   that phase contains.** Never take the phase number from the user's message
   if the tracker disagrees — stop and explain instead.
3. Read `memory/current-phase.md` and `docs/sessions/next.md`.
4. Read `CAPYWAKE_REUSE_AUDIT.md` — what is ported from `../capywake`.
5. Read `CAPYWAKE_LEGACY_AUDIT.md` and `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md`.
6. Read `docs/phases/PHASE_<NN>_PLAN.md` for the current phase.
7. Revise that plan, then write `docs/phases/PHASE_<NN>_PRE_REVIEW.md` —
   adversarial, **before any code** — then revise again, then implement.
   **Never code first.** A session that writes code before its pre-review
   exists has broken the process, regardless of how the request was phrased.
8. Full protocol — including the two self-reviews and the full-project review
   that follow implementation — is in the tracker.

The decisions already settled in Phase 00 (navigation, raster art, the
two-tier fidelity contract, what is ported) are **not reopened** unless the
owner says so. They are recorded with their evidence; re-deciding them wastes
the session.

## The two projects

- **This repo** is the only place anything is written.
- **`../capywake` is READ-ONLY.** Never edit, refactor, reformat or delete
  anything in it. Read-only means *never modify it* — it does **not** mean
  never take code from it.

### What is ported, and what is not

**If a file imports Flutter, it is not ported.** The sole exception is
`lib/core/theme.dart`, which imports Flutter *and* is not ported.

| Ported | Size |
|---|---|
| `lib/core/` minus `theme.dart` | 62 files, 9,825 lines — verified pure Dart |
| `test/core/` | 48 files, **932 passing tests**, zero feature imports |
| `lib/l10n/` | 383 keys × 10 locales; only 3 are navigation-coupled |
| `lib/data/` tables + mappers | **at `schemaVersion = 1`** — drop the legacy's 6-version migration history; this app has no users |
| `tool/check_arb.dart`, `check_coverage.dart`, `generate_tones.dart`, `assets/sounds/` | — |

| Not ported | Why |
|---|---|
| `lib/features/`, `test/features/` | 26,710 lines of the old view tree |
| `lib/features/common/capy/` | 1,939 lines of `CustomPaint` — the root cause |
| `lib/core/theme.dart` | Our palette is sampled from the mockups |
| `lib/app/shell.dart`, `router.dart` | Wrong navigation |

File-level verdicts: `CAPYWAKE_REUSE_AUDIT.md`. The retrofit failed in the
**view layer**; nothing in `lib/core/` has an opinion about how a capybara is
drawn.

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

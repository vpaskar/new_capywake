# Phase 02 — full-project review

Not a review of Phase 02's diff — self-reviews #1 and #2 did that. This pass
asks whether **the project as a whole** is consistent after the port: do the
documents still describe the repository, do the rules still hold everywhere, and
does anything Phase 00 or 01 decided now contradict what exists.

Checked by running commands against the whole tree, not by reading the phase
plan.

**5 findings — 1 High, 2 Medium, 2 Low.**

---

## Rule compliance sweep — what passes

Every `CLAUDE.md` hard rule, verified by command:

| Rule | Check | Result |
|---|---|---|
| `lib/core/` imports no Flutter | `grep -rl "package:flutter/" lib/core/` | clean, **and asserted by N1** |
| No TODO-only placeholders | `grep -rn "TODO\|FIXME" --include='*.dart' lib/` | none |
| No `// coverage:ignore` | `grep -rn "coverage:ignore" lib/ test/` | none |
| No hardcoded user-facing strings | `grep -rnE "Text\('[A-Z]" lib/features/ lib/design/` | none |
| `SleepGateway` has no write method | read `lib/core/sleep/sleep_gateway.dart` | read-only by construction, asserted by `sleep_boundary_test` |
| `schemaVersion = 1` | `lib/data/database/app_database.dart:172` | 1, asserted by N3 |
| No platform plugin added | `pubspec.yaml` | none of `alarm`, `flutter_local_notifications`, `health`, `sensors_plus`, `permission_handler` |
| `../capywake` unmodified | `git -C ../capywake status --porcelain` | **byte-identical to the M7 baseline** |
| `main` only, no branches | `git branch` | `main` |

Safety invariants survived the port and are tested, not just present:

- **Emergency escape** — `puzzle_validator.dart:50` ("no combination of them ever
  locks the alarm — the emergency escape stays reachable throughout"),
  `puzzle_round.dart:171` surfaces `escapeVisibility`, and
  `puzzle_settings.dart` carries its reachability and deliberateness. Covered by
  `puzzle_validator_test`, `puzzle_round_test`, `puzzle_settings_test`.
- **No scores or streaks on the puzzle** — `puzzle_round.dart:41` and
  `puzzle_difficulty.dart:50` both state it. The `stepUpStreak` /
  `consecutiveCorrect` fields in `puzzle_difficulty.dart` are an internal easing
  counter, documented at line 99 as "not a score, is never displayed, and does
  not affect difficulty" beyond easing.
- **No overpromising** — the only matches for "never oversleep", "guarantee",
  "bypass silent mode" in ported code are the **prohibitions themselves** in
  `reliability_copy_service.dart:26-28`, plus honest ARB copy ("stays honest
  about what each phone can and cannot guarantee").

---

## High

### P1 — `CAPYWAKE_REUSE_AUDIT.md` is now partly wrong, and it is the document the next porting session will trust

The audit is the file-level verdict `CLAUDE.md` points sessions at. Three of its
claims no longer match the repository:

1. **"`test/core/` — 48 files, 15,503 lines. Ports with the code."** It does not
   all port: `theme_test.dart` tests `lib/core/theme.dart`, which the same
   document correctly excludes. Ported is **47 files, 15,245 lines, 912 tests**.
2. **"932 passing tests"** as the ported figure. 932 is the legacy's count;
   `theme_test.dart` is 20 of them.
3. **"`lib/l10n/` — 383 keys"**, and "New keys needed: roughly 15–25". Phase 01
   shipped **384 keys × 10 locales** and adapted the three nav-coupled ones, so
   the work is done, not pending.

Phase 00's self-review found a High defect *because* a planning document had
banned reusable code; this is the same risk in reverse — a document promising
code that cannot be ported as described. The next session to port anything will
read it and work from stale numbers.

**Applied.** The audit is corrected in place, each change marked with how it was
measured and when, and a "revised by Phase 02" note at the head so the
provenance is visible rather than silent. The reasoning and verdicts are
unchanged — only the figures that implementation proved wrong.

---

## Medium

### P2 — `lib/data/` is described in two documents as including platform adapters this phase deliberately did not port

`CLAUDE.md`'s architecture block says `data/` is "Drift, DAOs, repositories,
platform adapters" and that "only `data/` imports the `alarm` package". That is
the target architecture, and it is right — but nothing says which parts exist
*now*.

What exists: `database/` (tables, mappers, generated code), `repositories/`,
`sleep/repository_sleep_night_store.dart`, and `providers.dart` minus the
sleep-gateway providers. What does not: `engine/`, `motion/`, `permissions/`,
`sleep/live_sleep_gateway.dart` — all four blocked on platform plugins belonging
to phases 05–08.

Read literally, a Phase 03 session could conclude the alarm engine is wired.
Self-review #1's F5 fixed this for the sleep boundary specifically; it is the
same gap one layer up.

**Applied.** The plan's "What Phase 03 may assume" section (pre-review M8) is
the authoritative statement and is now also summarised in
`docs/sessions/next.md`: the abstractions and their fakes exist, **nothing
rings**, and the platform adapters land in 05/07/08. `CLAUDE.md`'s architecture
block keeps describing the target, which is its job.

### P3 — `memory/current-phase.md` still describes Phase 01 as current

The file opens "**Phase 01 — Foundation: done, 2026-11-16. `Current phase: 02`.**"
and its "Next session — Phase 02" section describes this phase as upcoming work,
including "re-enable the `lib/core` ≥ 95% coverage gate", which is now done
(99.41%).

Ordinary end-of-phase bookkeeping, but it is step 13 of the protocol and the
phase is not complete without it. Recording it as a finding so it cannot be
skipped under time pressure — Phase 00 skipped its reviews for exactly that
reason.

**Applied** in the tracker/memory/session update step below.

---

## Low

### P4 — Per-tree coverage is uneven in a way worth stating once

| Tree | Coverage | Lines |
|---|---|---|
| `lib/app` | 100.00% | 58 |
| `lib/features` | 100.00% | 11 |
| `lib/design` | 97.38% | 267 |
| `lib/core` | 99.41% | 2,526 |
| `lib/data` | 85.08% | 496 |

`lib/features`' 100% is 11 lines of Phase 01 placeholder screens and carries no
information; `lib/data`'s 85.08% is explained by self-review #2 G2 (67
structurally uncoverable Drift table getters; hand-written data code is 98.4%).

**Applied.** Reported with line counts beside percentages wherever these figures
appear, so an 11-line 100% is not mistaken for a 2,526-line 99.41%.

### P5 — Phase 01's recorded Tier A state is unchanged, and the captures were regenerated

`tool/capture.sh` ran as this phase's native-build check (pre-review H3) and
rewrote `docs/visual/{shell,alarms,stats}/actual.png`. All three verify at
1179×2556. This phase changed no pixel, so Phase 01's recorded Tier A finding
stands: the header matches to **0.1 pt**, and three body blocks remain off
because the screens have no bodies — Phase 03's work.

**Applied.** The post-review states that the captures are a build artifact of
this phase rather than a new fidelity measurement, so nobody reads a Phase 02
capture as a Phase 03 claim.

---

## Verdict

The project is internally consistent after the port, with one real documentation
defect (P1) in the file future porting sessions are told to trust.

What this pass confirms is the thing the rebuild was for: **the port did not
import the failure.** `lib/core/` is Flutter-free by assertion, the safety
invariants that make this an alarm clock rather than a toy — reachable emergency
escape, no shame copy, no overpromised reliability, no displayed scores — all
survived with their tests, and the legacy reference is untouched.

All 5 findings applied. None invalid.

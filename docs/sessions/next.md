# Next session — start here

Paste `NEXT_SESSION_PROMPT.md` into a fresh session, or point the agent at
this file.

## State

Phases 00 and 01 are **done** and committed. The app builds, runs on the
iPhone 14 Pro simulator, and `tool/capture.sh` produces verified screenshots —
the gate Phase 01 existed to prove.

**Current phase: `02` — Domain and persistence (port from `../capywake`).**

## Read in this order

1. `CLAUDE.md` — the project's rules, incl. what is ported from the legacy.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 00 established and decided.
4. `CAPYWAKE_REUSE_AUDIT.md` — file-level verdicts on `../capywake`.
5. `docs/phases/PHASE_00_SELF_REVIEW.md` — 8 findings, incl. the two Highs.
6. `CAPYWAKE_LEGACY_AUDIT.md` — what the legacy contains.
7. `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md` — the revised plan.
8. `docs/phases/PHASE_00_PRE_REVIEW.md` — the original 12 findings.
9. `docs/phases/PHASE_01_PLAN.md` — the draft to revise.

## Do, in this order

1. Pre-flight: `pwd && git branch --show-current` → `new_capywake`, `main`.
2. Revise `docs/phases/PHASE_01_PLAN.md`.
3. Write `docs/phases/PHASE_01_PRE_REVIEW.md` — adversarial, **before any
   code**. Classify High/Medium/Low. Apply all, or mark invalid with a reason.
4. Revise the plan again against the findings.
5. **Then** implement Phase 01.
6. Validate → self-review #1 → self-review #2 → full-project review.
7. `PHASE_01_POST_REVIEW.md`, update tracker + memory + this file, commit.

## The gate Phase 01 met

`tool/capture.sh` writes three verified PNGs at 1179×2556 px (393×852 pt) and
**checks the artifact rather than the exit code** — the planned `flutter test`
mechanism was proven to pass while writing nothing.

Use it. Never run `integration_test/capture_test.dart` with `flutter test`.

## The two things that gate Phase 02

1. **Re-enable the `lib/core` ≥ 95% coverage gate.** Phase 01 skips it
   legitimately; a skip nobody turns back on is how a gate dies.
2. The 932 ported tests must pass. They are the regression net for DST,
   leap day, skip-next sequencing and the 00:30-set-at-23:55 case.

## Reference paths

The handoff package now lives **inside the repo** at `reference/`, git-ignored
(348 MB). Paths are relative to the project root.

| What | Where |
|---|---|
| Master brief | `reference/00_AGENT_MASTER_PROMPT.md` |
| Mockups (source of truth) | `reference/01_REFERENCES/screens/primary/` |
| Hero scenes | `reference/02_ASSETS/header_scenes/*_integrated.png` |
| Mascots | `reference/02_ASSETS/asset_library/mascots/` + `mascot_fixes/` |
| Clean icons | `reference/02_ASSETS/clean_icons/` |
| Decor | `reference/02_ASSETS/asset_library/decor/` |
| Animations | `reference/02_ASSETS/animations/*/loop.webp` |
| Legacy (READ-ONLY) | `../capywake` |

`reference/` is reference material, never bundled. Phase 01's
`tool/audit_art.dart` imports selected production assets from it into
`assets/`.

## Environment

- Dart 3.12.2 stable, macos_arm64.
- **iPhone 14 Pro simulator** (iOS 16.4) — matches the mockup geometry exactly.
- A physical iPhone (iOS 27.2.1) is reachable for real alarm testing in phase 05.
- **No Android emulator was running.** Android is unverified; never mark it
  tested until one actually runs.

## Standing reminders

- `../capywake` is **read-only** — never modify it. That does *not* mean never
  take code from it: see the port table in `CLAUDE.md`.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture.
- A finding is applied or invalid. Never deferred.
- `main` only. No branches, no worktrees, no stashes.
- Store publishing is drafts only; the owner presses every final button.

# Next session — start here

Paste `NEXT_SESSION_PROMPT.md` into a fresh session, or point the agent at
this file.

## State

Phase 00 is **done**, committed, and has been re-reviewed. No app code exists
yet, by design — the master prompt forbids implementation before a plan has
survived a critical review.

**Current phase: `01` — Foundation.**

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

## The one thing that gates Phase 01

**`tool/capture.sh` must produce a real PNG of the shell at 393×852**,
committed under `docs/visual/shell/`.

The legacy captured zero screenshots across 40 phases because its runner had no
display. Every fidelity claim depends on this harness working. Prove it on the
empty shell before building any real screen. If it cannot work, that is a
blocker to raise in Phase 01, not a surprise in Phase 03.

## Reference paths

| What | Where |
|---|---|
| Mockups (source of truth) | `~/Downloads/CapyWake_Flutter_Rebuild_Handoff/01_REFERENCES/screens/primary/` |
| Hero scenes | `.../02_ASSETS/header_scenes/*_integrated.png` |
| Mascots / decor / icons | `.../02_ASSETS/asset_library/`, `clean_icons/`, `mascot_fixes/` |
| Animations | `.../02_ASSETS/animations/*/loop.webp` |
| Legacy (READ-ONLY) | `../capywake` |

**Recommendation for the owner:** the handoff package lives in `~/Downloads`,
which is where browsers dump files and users clean up. Moving or copying it to
`new_capywake/reference/` (git-ignored) would stop every reference path in the
project from breaking at once if it disappears.

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

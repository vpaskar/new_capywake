# Next-session prompt

Copy everything between the lines into a fresh Claude Code session started in
`/Users/I552351/SAPDevelop/src/pets/new_capywake`.

---

Continue the CapyWake Flutter greenfield rebuild. You are in the NEW repo
(`new_capywake`), on `main`. **Phase 00 is done and committed; Phase 01 is
next.** No app code exists yet — that is deliberate, not an oversight.

## Read first, in this order

1. `CLAUDE.md`
2. `ai-orchestration/PHASE_TRACKER.md`
3. `memory/current-phase.md`
4. `CAPYWAKE_REUSE_AUDIT.md`
5. `docs/phases/PHASE_00_SELF_REVIEW.md`
6. `CAPYWAKE_LEGACY_AUDIT.md`
7. `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md`
8. `docs/phases/PHASE_00_PRE_REVIEW.md`
9. `docs/phases/PHASE_01_PLAN.md`

Also read `reference/00_AGENT_MASTER_PROMPT.md`
— it is the governing brief.

## What Phase 00 settled, so you do not relitigate it

- **Navigation: Home · Alarms · Stats** bottom tabs, Settings a pushed route
  from the gear in the header. Decided from 4-of-5 primary mockups.
- **Raster art is the medium.** The legacy's "capybara is vector `CustomPaint`,
  never a raster cutout" rule is **not inherited** — it is precisely why the
  previous attempt could not resemble the mockups.
- **Fidelity is two-tier.** Tier A (geometry, palette, type, radii, control
  states, art placement) is binding at ±4 pt on 393×852. Tier B (illustration)
  is best-effort with every substitution logged by name, because the mockups
  contain art the asset package does not have — verified, with saved crops in
  `docs/visual/_evidence/`.
- **Mockups are 851×1847 px = 393×853 pt = iPhone 14 Pro**, available as a
  simulator here, so screenshot comparison is exact.
- **Port from `../capywake`, do not rewrite.** If a file imports Flutter it is
  not ported; the sole exception is `lib/core/theme.dart`, which imports
  Flutter *and* is not ported. See the table in `CLAUDE.md`.
- **Full rigor:** 10 locales, coverage ≥85% project / ≥95% core, pre-review +
  two self-reviews + one full-project review per phase.

## Your task this session: Phase 01 — Foundation

Follow the protocol in the tracker. In order:

1. Pre-flight: `pwd && git branch --show-current` → must be `new_capywake`,
   `main`.
2. **Revise** `docs/phases/PHASE_01_PLAN.md`.
3. **Write `docs/phases/PHASE_01_PRE_REVIEW.md` before writing any code.**
   Adversarial. Classify every finding High/Medium/Low. Apply all of them, or
   mark one invalid with a one-line reason. "Deferred" is not an outcome.
4. Revise the plan against the findings.
5. Implement Phase 01 only.
6. Validate, then self-review #1, self-review #2, full-project review — applying
   all findings after each.
7. Write `PHASE_01_POST_REVIEW.md`; update the tracker, `memory/current-phase.md`,
   `memory/progress.md` and `docs/sessions/next.md`; commit to `main` as
   `feat: complete phase 01 - foundation`, then
   `chore: record phase 01 commit hash`.

### Phase 01 delivers

- `flutter create`, iOS + Android, `very_good_analysis`, zero analyze issues.
- Typeface chosen by rendering "CapyWake 7:00" at mockup size in Nunito,
  Baloo 2, Quicksand and Fredoka and comparing against a reference crop. Bundle
  it with its OFL licence. The **wordmark is an asset**, not a font match.
- `lib/design/tokens.dart` from the sampled palette: cream `#FEF3E7`, surface
  `#FEF4E8`, surfaceAlt `#F8E1CC`, accent `#F89736`, accentDeep `#E97C22`,
  cocoa `#2F1106`, cocoaSoft `#8A6A55`, success `#57AA3A`, grass `#85B83B`.
  Refine against crops before freezing. Light and dark decided together.
- Art pipeline: `tool/audit_art.dart` (alpha, ghost pixels, margins, intrinsic
  size) and `tool/encode_art.dart` (downscale to 2× render box, WebP).
  **Measure the total, then set `check_bundle_size.dart` at measured + 20%** —
  do not inherit a guessed number.
- `lib/design/` components, chiefly **`SceneHeader`** (hero art, per-scene
  crop alignment, overlapping cream card) — five screens share it.
- `go_router` `StatefulShellRoute` for the three tabs, `/settings` declared
  **outside** it with branch state preserved so pop returns to the originating
  tab. Router test asserts that for all three.
- **Port the 10 ARB files and `tool/check_arb.dart` from `../capywake`.**
  Rename the 3 nav keys; keep the rest.
- **The gating deliverable: a working capture harness.**
  `integration_test/capture_test.dart`, `tool/capture.sh`, `tool/compare.dart`.

### Phase 01 is not done until

`tool/capture.sh` has produced a real PNG of the shell at 393×852, committed
under `docs/visual/shell/`.

The legacy repo captured **zero** screenshots across 40 phases because its
runner had no display. Every fidelity claim in this rebuild depends on this
harness existing. Prove it on the empty shell. If it cannot be made to work,
raise it as a blocker now — not in Phase 03 when five screens are waiting on it.

### Do not build in Phase 01

No Home/Alarms/Add-Edit/Settings/Stats screens. No `core/` port (Phase 02 owns
that). No `Alarm` model, Drift or repositories. No alarm engine, notifications
or permissions. No games or puzzles. No dependency beyond the ones the phase
plan lists.

## Hard rules

- `../capywake` is **READ-ONLY** — never modify it. It already has 11
  uncommitted files from 2026-11-15 that are not yours; leave them.
- `main` only. No branches, no worktrees, no stashes.
- Never claim a screen matches without a recorded capture.
- Never mark anything "tested on device" that was not run on one. No Android
  emulator was available; Android is unverified.
- Store publishing is drafts only — the owner presses every final button.
- No comments that restate the next line; the code explains itself.
- If the tracker and a phase file disagree, **stop and explain** — do not guess.

---

# Progress

Running narrative. Append a block per completed phase; never rewrite history.

---

## Phase 00 — Discovery, legacy audit, architecture and navigation decision

**Done 2026-11-16.** No app code, by design.

**Produced:** `CAPYWAKE_LEGACY_AUDIT.md`, `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md`,
`docs/phases/PHASE_00_PLAN.md`, `docs/phases/PHASE_00_PRE_REVIEW.md`,
`docs/phases/PHASE_01_PLAN.md` (draft), `CLAUDE.md`, the phase tracker, the
memory and session files, and `docs/visual/_evidence/`.

**Audited read-only:** `../capywake` — 40/47 phases done, 137 Dart files, 99
test files, 10 locales, coverage gates, a real phase ritual.

**Root cause of the failed retrofit:** the legacy's own rule that the capybara
must be vector `CustomPaint` and "never a raster cutout". Not inherited.

**Measured:** mockups are 851×1847 px = 393×853 pt = iPhone 14 Pro, available
here, so screenshot comparison is exact.

**Evidenced:** the Home mockup hero (nightcap, duck, nightstand clock) is not
`today_integrated.png` (no cap, no duck, mug and books). Separate generations,
hence the two-tier fidelity contract.

**Decided:** raster art · all three Stats segments · full rigor incl. 10
locales (owner). Navigation = Home/Alarms/Stats tabs + gear→Settings (from
4-of-5 mockup evidence).

**Pre-review:** 12 findings, 4H/5M/3L, all applied, none deferred. The Highs
moved the domain ahead of the first screen, made the capture harness a gating
deliverable, replaced "1:1" with a measurable contract, and hardened Stats
against fabricated numbers.

**Next:** Phase 01 — Foundation. Gated on `tool/capture.sh` producing a real
PNG of the shell at 393×852.

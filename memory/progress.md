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

### Phase 00 addendum — reuse audit and self-review (same day)

Owner asked what could be reused from `../capywake`. Answer: far more than
Phase 00 allowed. Self-review found 8 findings (2H/3M/3L), all applied.

Verified by running the commands, not by reading docs: only `lib/core/theme.dart`
imports Flutter in all of `core/`; nothing in `core/` depends on it; 0 of 48
core test files import feature code; `flutter test test/core` → **932 passed**;
3 of 383 ARB keys are navigation-coupled.

**SR-1 (High)** — Phase 00's "no code copied, and none will be" was wrong, and
contradicted its own correctly-scoped "no copied *widget* code". Corrected to
a greppable rule: **if a file imports Flutter, it is not ported.**

**SR-2 (High)** — Phase 00 skipped its own post-implementation reviews, which
is how SR-1 shipped. Tracker now applies steps 8–10 to documentation phases.

Phase 02 changes from "build the domain" to "port and adapt the domain".
~45,000 lines of tested, translated, non-UI work is portable.

Added: `CAPYWAKE_REUSE_AUDIT.md`, `docs/phases/PHASE_00_SELF_REVIEW.md`,
`NEXT_SESSION_PROMPT.md`.

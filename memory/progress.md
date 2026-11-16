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

---

**Phases 01–03 added no entry here.** The tracker carried their detail and this
file was left at Phase 00 — found in Phase 04. Summarised below from the
tracker and post-reviews rather than left as a hole.

## Phase 01 — Foundation: tokens, type, art pipeline, shell, capture harness

`ebe89e4`. The gate: `tool/capture.sh` writes verified PNGs at 1179×2556 and
**checks the artifact, not the exit code** — the pre-review proved the planned
`flutter test` mechanism passes while writing nothing, which is the legacy's
40-phase failure, green throughout. Typeface **Baloo 2**, which does *not*
cover Cyrillic/Arabic/Japanese (a `getmask` check wrongly said it did — only
rendering shows tofu), so `ru`→Nunito, `ar`/`ja`→system. 43 tests.

## Phase 02 — Domain and persistence, ported from `../capywake`

`4376154`. 62 `lib/core/` files, 47 `test/core/` files, Drift at
`schemaVersion = 1`. **Test identity closed exactly as pre-registered.** Not
932 ported but **912** — `theme_test.dart` tests the unported `theme.dart`,
and its replacement `tokens_contrast_test.dart` then found two real AA
failures in the palette. 1,051 tests.

## Phase 03 — Home / Today

`b3b0574`. The first screen with a body, so the first real test of the
fidelity contract — and it found a defect latent since Phase 01.
`SceneHeader` drew the cream card *inside* the hero art's `Stack`, reading the
mockup's 292.3/303.4 edges as two positions when they are one edge plus a
corner radius. Every hero band was **11.1 pt short** and Phase 01 had recorded
those exact deltas and blamed "the screens have no bodies" — **wrong in three
documents**, all corrected in place. Also: three of Phase 03's own block rows
were **glyph edges**, and `initializeDateFormatting` was never called in
`lib/`. 1,116 tests.

## Phase 04 — Alarms list and Add/Edit alarm

The first screens that **write**. Four findings about earlier work:

1. **`SceneHeader.bandHeight` defaulted to Home's 188.4.** Alarms is 148.6,
   Add/Edit 112.1 — both opened +39.8 pt out. Making it **required** surfaced
   **Stats silently carrying Home's number** too. Third occurrence of a shared
   default standing in for a per-screen measurement.
2. **`compare.dart` could not see a card border** — a 1-px line moves a 393-pt
   row mean by under one unit, so four correctly-placed cards read `absent`;
   the first fix still missed the two **disabled** rows at 55% opacity.
3. **`lib/core` could not drive either screen** — `AlarmFormat.time` returns
   one string where both mockups style digits and marker apart. `timeParts`
   added; a proposed `periodLeads` field was **dropped on measurement**.
4. **`CapyNavBar` overflowed at 2× text on every screen**, found incidentally.

Phase 03's **P4 matcher decision** was made here, on screens that pass, with
its limits stated. **1,189 tests**, 399 ARB keys, lib 97.54% / core 99.41% /
data 86.40%. 31 findings across four passes, 27 applied, 2 invalid with a
test, none deferred.

**No control was exercised by hand**: `flutter build ios --simulator` fails
with Xcode 255 and taps did not reach the simulator. `flutter drive` works, so
all four captures are verified. Phase 05 owns the fix.

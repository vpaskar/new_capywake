# Current phase

**Phase 18 — Animation and visual polish: done, 2026-11-18.
`Current phase: 19` — Release QA (iOS + Android regression, bundle size,
store readiness). Not blocked.**

**2,459 tests**, analyze clean, lib 98.74% / `lib/core` 99.74% / `lib/data`
90.98%, **587 ARB keys × 10 locales**. Comment baseline 113. Bundle unchanged.

## What Phase 18 adds to the recipe

- **Theme:** `CapyWakeApp` applies `UserSettings.themeMode`; the first frame
  is held ≤ 400 ms for it (`CapyWakeApp.themeWait`), cross-fade off meanwhile.
- **Contrast:** `test/design/text_contrast_test.dart` gates every route, every
  game's practice and both ring kinds in **both** themes. Brand orange/green
  and text over art are pinned counts per screen; `cocoaSoft` on cream (4.49)
  is the named palette near-miss. A new screen must pass it.
- **Dark captures:** `tool/capture.sh` writes and verifies `dark.png` next to
  `actual.png`; onboarding and the chooser are dark-only.
- **Never `TickerMode(false)` over a subtree with a side-effecting watch** —
  Riverpod pauses it (the shell's alarm arming).
- **Art:** check on cream *and* dark; `outlineCoverage` gates masked outlines.
- **Disabled rows are full ink** (mockup); the toggle carries the state.

## Open for the owner

Loops G43–G47 (`ART_REQUESTS.md` #15–16); white on orange/green below
contrast; everything Phase 17 listed.

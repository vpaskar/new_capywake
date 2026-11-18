# Advanced wake controls capture (Phase 20)

`actual.png` / `dark.png`: iPhone 14 Pro simulator via `tool/capture.sh`,
verified (1179×2556, non-empty, fresh, no debug banner), at scroll 0 on the
shared `captureSeed`. `side_by_side.png`: reference left, capture right.

Reference: `reference/01_REFERENCES/screens/settings_redesign/05_WAKE_PUZZLE_ADVANCED.png` — a
crop from a design composite, not a native 393×852 frame, so it binds order,
grouping, control shapes and states (structural only, plan §1). No ±4 pt
block table.

## Deviations, named

- **Title "How it works"**, not "Wake puzzle": a screen reader would otherwise announce two screens identically (self-review #2 U7).
- The strictness explanation and the "puzzles only" caption are kept under their controls; the tolerance explanation is the callout, as drawn.
- Selected segments use `successDeep` (4.94:1 under white); the mockup's lighter green fails AA for a label.

# Wake puzzle overview capture (Phase 20)

`actual.png` / `dark.png`: iPhone 14 Pro simulator via `tool/capture.sh`,
verified (1179×2556, non-empty, fresh, no debug banner), at scroll 0 on the
shared `captureSeed`. `side_by_side.png`: reference left, capture right.

Reference: `reference/01_REFERENCES/screens/settings_redesign/02_WAKE_PUZZLE_REFINED.png` — a
crop from a design composite, not a native 393×852 frame, so it binds order,
grouping, control shapes and states (structural only, plan §1). No ±4 pt
block table.

## Deviations, named

- **No "Wake challenges" master switch:** no domain field backs it (pre-review X2).
- **No "Save changes" button:** every setting autosaves (X1).
- **Value rows, not inline controls:** Difficulty, Puzzles to solve, Stopping without the puzzle and the tolerance read their value and open Advanced (owner decision); inline segments do not survive German or 2× text at 393 pt.
- **Hero:** `scene.settings` in an 80 pt band; the mockup's nightcap is not in any asset (gap **G49**).
- **Counts are real:** "0 of 10 selected" is the default pool; the mockup's "6 of 8" / "4 of 10" are samples. Puzzle types reads "Off" while puzzles are out of the pool.
- Both cards share one style; `02`'s orange Games border reads as a focus state.

# Home capture

`actual.png` is a real capture from the iPhone 14 Pro simulator, written by
`tool/capture.sh` and verified by it: 1179×2556 px (393×852 pt), non-empty,
newer than the run, no DEBUG banner.

Captured against a **seeded** in-memory database — one alarm, 07:00, Mon–Fri
(`captureSeed` in `integration_test/capture_test.dart`) — so the screen is
comparable to `01_HOME.png`, which shows the same. The app's own default is the
empty state; demo data lives in the test, never in `lib/`.

Offsets are measured from the bottom of the status bar. The mockup draws a
44 pt one; the simulator reports 59 pt, recorded per capture in `inset.txt`.
Comparing absolute offsets would charge every block below the header a constant
15 pt error that no code change could fix.

## Phase 01 recorded this screen's defect and misattributed it

This directory replaces `docs/visual/shell/`, where Phase 01 captured the same
route under the name `shell`. Its record is worth keeping, because it contains
the Phase 03 bug a phase earlier:

| Block | Ref | Actual | Delta | Phase 01 called it |
|---|---|---|---|---|
| header band lower edge | 59.9 | 60.0 | **+0.1** | ✅ |
| hero scene lower edge | 248.3 | 237.3 | −11.0 | "expected — no content yet" |
| card top (overlap) | 259.4 | 237.3 | −22.1 | "expected — no content yet" |
| nav bar top | 730.5 | — | absent | "expected — no content yet" |

Only the last was really about the empty body. The −11.0 and −22.1 are
`SceneHeader` drawing the cream card *inside* the art's `Stack`, 11.1 pt above
its bottom, on a misreading of the two edges at 292.3 and 303.4 pt as two
positions rather than one edge and a corner radius. Phase 03's full-project
review P1 has the detail; the fix is in `lib/design/scene_header.dart`.

**A measurement with a plausible explanation attached is still a measurement.**
Phase 01 was right to record the numbers and wrong about their cause, and
recording them is what let Phase 03 find it.

## 2026-11-18 — owner art package

Re-captured. `MeadowFooter` now draws the owner's meadow band
(`decor/meadow_footer.webp`): `meadow footer top` is found for the first time,
669.7 vs 672.4 (−2.7, inside tolerance); 6 → 5 blocks outside tolerance, worst
delta 1.4 → 2.7 pt, all others unchanged. Home keeps its rounded card — the
mockup draws no cloud here. Catch the Capy's tile now wears the nightcap (G33).

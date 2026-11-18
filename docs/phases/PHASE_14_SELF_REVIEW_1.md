# Phase 14 — Self-review #1

After implementation and the first green validation run (1,969 tests), against
the iPhone 18 Pro (iOS 27, `flutter run`) and a contact sheet of the first
captures. **9 findings: 2 High, 4 Medium, 3 Low. All applied; none invalid.**

---

## High

**H1 — Find the Impostor's drift gave the answer away, or did nothing.** Seen on
device. Pairwise swaps (the plan's `DriftStyle.swap`) move two cards: with five
identical Capys and one odd one, 10 of 15 pairs swap two identical pictures —
no visible motion — and the other 5 move the odd one, which is then one of the
only two cards moving: a pointer at the answer. **Applied:** a
`DriftStyle.carousel` — every card steps one place round the two-row ring, so
all cards move together and none stands out. Rest slowed to easy 3.2 s /
medium 2.6 s / hard 2.0 s (each step moves every card). Tested: after one step
every card's position changed; the ring order is pinned.

**H2 — The H3 and H5 guards were guards on trust.** Each test advanced time in
one `pump(every * 3)`: the timer fires and `setState` runs, but the frame built
at the end of that pump only *starts* the slide, so positions read afterwards
are the old ones whether or not a swap happened. A negative test (guards
deleted) passed. Worse, the grid test's cells were bare `SizedBox`es that do
not hit-test, so the "finger down" never reached the grid at all. **Applied:**
a `_beats()` helper pumps rest + slide per beat; test cells are opaque
`ColoredBox`es; the view tests' still-mode checks use the same beats. Re-run
with each guard removed: the H3 test fails without the pointer hold, the H5
tests (grid + both views) fail without the snap to identity.

## Medium

**M1 — Morning Sort's outcome line sat flush under the grid** (device). The `xs`
gap was dropped while chasing the clock guard, but the failing game at that
moment was Find the Impostor, not Morning Sort. **Applied:** `sm` gap
restored; the clock guard stays green for all six games.

**M2 — The state badge covered long names** (device: the home badge sat on the
"l" of "Bowling ball"). **Applied:** the badge sits out over the card's corner
on a cream disc (26 pt, `badgeOverhang` 8 pt), off the name; the grid's `Stack`
no longer clips, so a top-row badge shows above the row.

**M3 — Words drifting every 2 s are hard to read half-asleep.** Item cards are
text; a swap of two words at medium 2.0 s often landed mid-read on device.
**Applied:** Morning Sort's rests match Find the Impostor's (3.2 / 2.6 /
2.0 s).

**M4 — A finger in the gap between cards did not hold the drift.** The
`Listener` deferred to its children; an 8 pt gap is easy to touch half-asleep.
**Applied:** `HitTestBehavior.translucent`; a test presses in a gap and the
grid stays put (and fails with the old behaviour).

## Low

**L1 — A convoluted test loop** in `find_the_impostor_test` ("every find
completes"). **Applied:** a plain loop.

**L2 — Morning Sort measured 18 names on every rebuild** (each tap, each drift
beat). **Applied:** the height is memoised on width, text scale, locale and
brightness.

**L3 — The simulator-control tool cannot play a moving grid.** Its tap lands
3–7 s after the screenshot it was aimed from; a carousel rest is 2.6 s. Seen:
taps landed on the card that had moved in. A person's reach is under a second,
so this is the instrument, not the game (`capywake-check-the-instrument`).
**Applied:** hand-play on the iPhone 18 Pro covers drift, a miss, packing, a
left-out card and a finished bag; **full moving-mode wins of both games** come
from `tool/capture.sh` (`flutter drive`, iPhone 14 Pro, real engine, the alarm
dismissed), recorded as such in the post-review — not claimed as hand-played.

---

Re-validated after applying: `flutter analyze` clean, `test/features/games`
and `test/features/ringing` green.

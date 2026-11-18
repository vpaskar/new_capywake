# Phase 13 — Self-review #1

Against the implementation as first written, the revised plan and the
pre-review. **6 findings: 2 High, 2 Medium, 2 Low. All applied; none invalid.**
Every one was found by a measurement or a test written to the pre-review's
findings, not by reading.

## High

**SR1-H1 — Rhythm Rescue's beat slots each filled a whole row.** A slot was a
`Container` with `alignment`, which expands to the incoming max width; in the
`Wrap` each slot took the full 261 pt, so the beats stacked vertically down the
card. Every assertion on slot *content* passed. It surfaced only because the
H1 "pads do not move" test measured the pads in German and found them 17 pt
lower than expected. **Applied:** the slot sizes to its numeral
(`Center(widthFactor: 1, heightFactor: 1)`) over a 34 pt minimum; a new test
asserts all five hard-mode beats are 34 pt wide and centred on the replay
button's line.

**SR1-H2 — The Capy Rocket card was 566 pt tall** (Catch the Capy 424, Memory
Hideout 323, Rhythm Rescue 368, measured with one probe over all four at
393 × 852). On the ringing surface the card is bottom-aligned over the hero; at
566 pt it would climb to the clock on any phone shorter than the reference.
**Applied:** the two arrow buttons moved into the sky field's lower corners
(the poster draws its controls over the sky too), the separate control row was
removed, the field went 280 → 240 pt; the card is **458 pt**. A host test now
asserts, for all four games on the reference phone, that the game card's top is
below the clock — and it was **run against a 480 pt field and failed**, so it
guards something.

## Medium

**SR1-M1 — The reserved outcome slot was 0.8 pt short.** M3 reserved
`fontSize × height × 2` = 43.2 pt; the laid-out two-line text is 44 pt, so the
first miss line still nudged Snooze. **Applied:** `GameOutcomeLine` measures one
line with a `TextPainter` in the live style and text scaler.

**SR1-M2 — A status that wraps differently moved the pads.** "Schau auf die
Felder" is two lines where "Du bist dran" is one; H1 moved the phase out of the
header but into a line that still changed height. **Applied:** both statuses are
laid out in an `IndexedStack`, which sizes to the taller; the H1 test in German
passes.

## Low

**SR1-L1 — `lib/features/games` fell from 100% to 99.77%.** The replay
button's semantics action and a press dragged off a pad were untested.
**Applied:** both tested (the first through `tester.semantics.tap`); 100%.

**SR1-L2 — `game_registry_test` still built only the first two views.**
**Applied:** it builds all four.

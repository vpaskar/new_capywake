# Phase 13 — Self-review #2

After SR1, on the iPhone 18 Pro (practice, both games, real taps and real
swipes in both directions) and against an earlier iPhone 14 Pro capture found
in `docs/visual/`. **6 findings: 2 High, 2 Medium, 2 Low. All applied; none
invalid.**

## High

**SR2-H1 — SR1's clock guard was blind to the real phone.** The guard measured
the clock with no status-bar inset; on the device the hero is pushed down
47 pt. A capture of the pre-SR1 layout (566 pt card) taken on the iPhone 14 Pro
shows the Capy Rocket card **drawn over the clock** — while the guard, run
against the same card size, passed. **Applied:** the guard now runs at
393 × 852 with a 47 pt top / 34 pt bottom inset and the labelled alarm; at the
current layout the clock ends at 138 pt and the rocket card starts at 209 pt;
**re-run against a 350 pt field it fails (card at 99 pt)**, reproducing what the
capture shows. Phase 07's rule again: a tool that cannot see a block will
match it to one it can.

**SR2-H2 — The rocket was drawn from a stale aspect and 28 % past its pixels.**
`rocketAspect = 300 / 256` was read off a stale size; the bundled pose
(`replacements_2026_11_18`, imported 2026-11-18) is **217 × 195**, already
recorded short in `art_manifest_test` for its 100 pt pose box. Pre-review H3
had sized the rocket to 100 pt — "the art's own box" — which is exactly the box
the art cannot fill. **Applied:** the rocket is a 72 pt square (217 px / 3,
drawn sharp), `BoxFit.contain`, bottom-aligned; the test decodes the bundled
file and asserts `size × 3 ≤ pixels`, so replacement art cannot silently make
it blurry. The smaller sprite also climbs further (115 pt of travel, not 95).

## Medium

**SR2-M1 — A repeated outcome is not announced.** A live region announces a
*change*; "Up we go." eight times in a row is heard once, so a screen-reader
user flying the rocket gets no confirmation after the first boost (the same for
a second "Not quite." in Rhythm Rescue, and for Catch the Capy's catches).
**Applied:** `GameHeader`'s progress (`2 of 8`) is a live region, so every step
is announced in all four games; the test fails without the flag (checked).

**SR2-M2 — The climb read as a twitch on device.** With an `easeOut` curve a
12–14 pt step under a 6 pt hover is barely visible. **Applied:** `easeOutBack`
(a small overshoot per boost) plus the longer travel from SR2-H2. The ceiling
remains the art: logged in G36.

## Low

**SR2-L1 — A pattern shown while still disappeared when motion came back.** If
a screen reader is turned off mid-repeat, the slots went blank under the user's
finger. **Applied:** a pattern shown still stays shown until a playback replaces
it; tested both ways.

**SR2-L2 — G36's first wording described the wrong file** (the blue-capped
original pose, not the bundled orange replacement). **Applied:** rewritten
against the file the app actually bundles.

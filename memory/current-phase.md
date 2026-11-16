# Current phase

**Phase 03 — Home / Today: done, 2026-11-16. `Current phase: 04`.**

The first screen with a body, and therefore the first real test of the
fidelity contract. **1,116 tests**, analyze clean, lib 97.38% / `lib/core`
99.41% / `lib/data` 86.40%, 395 ARB keys × 10 locales.

## What this phase actually found

Four defects, none of them in Phase 03's own new code. All four were found by
**running something and reading the result**.

### 1. `SceneHeader` shortened every hero band by 11.1 pt

`tier_a_blocks.md` records two edges: 292.3 ("hero scene lower edge") and
303.4 ("card top"). Phase 01 read the 11.1 pt between them as *the card riding
up over the art* and drew the cream card **inside** the art's `Stack`.

They are **one edge and a corner radius** — the card begins flush at 292.3 and
its 28 pt radius reaches full width at 303.4. The first capture of a screen
with content failed **13 of 14 blocks**, worst delta 38.7 pt, all inheriting
that shortfall. After the fix the hero lower edge is **0.0 pt**.

**Phase 01 measured −11.0 and −22.1 on exactly those rows and attributed them
to "the screens have no bodies".** Only the nav-bar row had that cause. The
same wrong explanation was repeated in Phase 02's post-review and the tracker —
**wrong in three documents, all corrected in place.**

### 2. Three of this phase's own block rows were glyph edges

A row-mean luminance detector **cannot tell a line of text from a layout
edge**. "Game rail top 605.0" was the tile art's *bottom*; "my stats row top
662.7" was a glyph edge inside a label's second line. The tile size was then
*inferred arithmetically* from two of those wrong rows: **94 pt against a
measured 74**, 27% large.

Fixed by reading a crop and anchoring to the My Stats row's orange icon, a
colour the detector cannot confuse. **The rule is now in `CLAUDE.md`**, not
only in a phase file.

### 3. `initializeDateFormatting` was never called in `lib/`

`main.dart` was three lines. Every clock time goes through `DateFormat`, which
throws until symbol data is loaded. It survived two phases because the ported
`test/core/` suite calls it in its own `setUpAll` — **912 formatter tests
passed against a domain that was covered, while the app would have thrown on
the first screen that rendered a time.** Home is that screen.

`lib/app/bootstrap.dart` now does it, gated by a test that asserts the **app's
own entry point** handles all ten locales.

### 4. `lib/data`'s 85.08% was partly an accident

Five providers (`proStatus`, `puzzleSettings`, and three sleep ones) were
**never read by any test** and counted as covered only because something
constructed the graph far enough to execute their declarations. Home's
in-memory override removed the accident and the figure fell to **82.76% — the
first honest measurement**, not a regression Home caused.

A real provider test took it to **86.40%**, above both the gate and Phase 02's
figure. **Phase 02's post-review claimed 85.08% was the honest number; that is
corrected.** The general lesson: *"this number is depressed for a structural
reason"* needs its own evidence, because it is equally consistent with the
number being inflated somewhere else.

Also: `compare.dart` reported **4 of the 13** documented blocks. Now 14.

## Decisions this phase made

| Question | Decision |
|---|---|
| Palette F1 | **Owner, mid-phase: "do as in the mockups."** No token retuned; `tokens.dart`'s only diff is the measured `gutter = 11.0` |
| The mockup's green ring on Step Quest | Drawn in `cocoa` (11.8:1), not green (2.68:1) — a ring has no second channel, and Step Quest is `blocked`, so a highlight reading "available" would be a content lie. **Recorded as a named Tier A deviation** |
| Header mascot | Ships. The plan filed it as a missing asset (G12); the pre-review found two matching cells already bundled. The fallback would have shipped five capybaras where the mockup has six |
| Meadow band | Drawn, not raster (G13) — no supplied decor is the right shape, and tiling a 90 px tuft across 393 pt reads as a repeat. **Not** a return of the banned `CustomPaint` rule, which was about the mascot |
| Toggle tap target | Paint stays at the mockup's 34.6 pt (Tier A); hit area grows to 44 pt. Both asserted |
| Comment budget | Ported from `../protio` (trimmer) + `../gastrowerk` (ratchet) at the owner's request: **2 lines / 300 chars**, 113 inherited files baselined, **0 Phase 03 files** |

## Tier A state

Closed to within tolerance: hero lower edge **0.0**, CTA top **+0.9**, CTA
bottom **+0.9**, rail tiles **−1.4**, labels end **+1.1**.

8 blocks remain outside ±4 pt, recorded with their measured deltas in
`docs/visual/home/`. Several are the matcher snapping two reference blocks onto
one detected edge (full-project review P4) rather than independent defects.

**A screen is done when the comparison is captured and its deviations are
named.** They are.

## Next session — Phase 04, Alarms list and Add/Edit

`02_ALARMS.png`, `03_ADD_EDIT_ALARM.png`. Measure their blocks with the method
`CLAUDE.md` now requires — crop and colour anchor for anything near text — and
append to `tier_a_blocks.md`.

**P4 is left for Phase 04 to decide:** `compare.dart` snaps each reference
block to the nearest detected edge, so a displaced layout can match several
blocks to one edge. Changing the matcher while blocks are red would be tuning
the instrument to the result; decide it on a screen that passes.

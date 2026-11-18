# Phase 14 — Pre-review (adversarial, before any code)

Against `PHASE_14_PLAN.md` draft 1, the Phase 11/12/13 contract, `CLAUDE.md`, and
the code it plugs into (`memory_hideout_view.dart`, `rhythm_rescue_view.dart`,
`game_header.dart`, `game_outcome_line.dart`, `art.dart`,
`art_manifest_test.dart`, `ringing_host_game_test.dart`, `capture_test.dart`), and
against the 31 bundled mascots, looked at one by one (`poses` contact sheet).
**15 findings: 5 High, 6 Medium, 4 Low. All applied; none invalid.**

---

## High

**H1 — Three pose labels describe art that is not there.** Draft 1 names the
poses from the file list, not from the pictures. Looked at: `collection_08` is
not dancing — it is a Capy seen from the side, stretching both arms up, and its
silhouette is close to `collection_15` (waving). `moments_07` is not "on a
pillow" in the sleeping sense — it sits upright on a cushion, eyes closed.
`collection_07` holds a mug, not a coffee specifically. A screen-reader user
plays Find the Impostor **by its labels**, so a label that does not describe the
picture is a wrong answer key. **Applied:** every label is written against the
contact sheet; `collection_08` leaves the bank (joy gains `moments_09`, blushing
with a heart); `moments_07` is "resting on a cushion"; `collection_07` "holding
a warm mug".

**H2 — Morning Sort's card is over the clock budget.** Draft 1's layout sums to
~428 pt (header 112, bag row 64, grid 136, outcome 44, gaps and padding 72)
against Catch the Capy's 424 pt — the `ringing_host_game_test` clock guard would
fail on the small phone. **Applied:** the bag row is 56 pt (art 56 pt), the grid
cells are measured rather than padded, gaps are `sm`; the plan registers a
height check against Catch the Capy's card in the view test, and both games join
the guard's game list (six games).

**H3 — A swap can start under a finger.** Draft 1 restarts the countdown on
pointer *down*; a slide already in flight continues, and a new one can start
while the finger is down (a long press, a slow tap). The card the user aimed at
slides out and the tap lands on a neighbour — counted as a wrong tap. Struggle
only brings the escape forward, but the game would be blaming the user for its
own motion. **Applied:** no swap starts while any pointer is down on the grid;
the countdown restarts on pointer up; a slide in flight finishes (it is what the
user sees, and the hit test follows the painted card).

**H4 — Hard Find the Impostor can pair two near-identical poses.** "Same group"
admits `cheering` / `partying`: both arms up, mouth open, confetti — the party
hat is the only difference at 72 pt. The bundle also holds five near-twin
pairs (`collection_00`/`moments_13` …) the plan already keeps out. Hard must be
harder, not a precision test for a half-asleep user (`CLAUDE.md`: no precision
tapping). **Applied:** an authored `excludedPairs` set (`cheering`/`partying`)
on top of the twin exclusion; a core test asserts every hard pair the round can
deal is outside it.

**H5 — Still mode read once.** Draft 1 says "Still: no swaps" without saying when
it is read. A screen reader turned on mid-game must stop a pending swap and a
slide in flight. **Applied:** `DriftingGrid` takes `moves` every build; when it
turns false the timer is cancelled and the permutation **snaps back to
identity** (semantics order = reading order again). Tested by flipping
`accessibleNavigation` mid-slide.

## Medium

**M1 — Text-only item cards are a Tier B substitution, not a design.** The plan
says it; the session must also report it, and the owner must be able to fix it.
**Applied:** reported in session; **G37** (Morning Sort item art) and **G38**
(lookalike animals) in `asset_gaps.md`; two `ART_REQUESTS.md` rows with sizes.

**M2 — The mascots are bundled but not catalogued.** `CapyArt` lists two of the
31; a view calling `Image.asset('assets/art/mascots/…')` with a literal path
would bypass the manifest and size checks. **Applied:** `ArtUse.gameCapy`
(72 pt → 216 px) and `CapyArt.gameCapys` (`game.capy.<pose>`), in `all`; the
manifest's resolution test then covers every pose; a view test asserts every
`CapyPose` resolves.

**M3 — Mascot halos in dark mode.** These cutouts came off sticker sheets; on a
dark surface a matte edge can show (G34 found one on the win frames). **Applied:**
Impostor cells and the bag's art keep a cream backing in dark mode (as the
art's own ground); checked in a dark capture.

**M4 — `pumpAndSettle` settles between swaps.** A pending `Timer` schedules no
frame. **Applied:** tests drive drift with explicit `pump(swapEvery)` then
`pump(slide)`; the capture's win helper taps by key (the hit test follows the
painted card).

**M5 — Timers outliving the widget.** **Applied:** one `Timer?` in
`DriftingGrid`, cancelled in `dispose`, on completion, and when still; a test
disposes mid-slide.

**M6 — A long name moves the grid between bags.** Draft 1 measures "the bank's
longest name" — right, but only if the measurement uses the *current locale's*
strings at the *current* text scale and cell width; and a name that does not fit
two lines would clip. **Applied:** the cell height is the tallest of all 18
localized names laid out at the cell width (no `maxLines`), computed in
`LayoutBuilder`; never `FittedBox`, never clamped scaling.

## Low

**L1 — Swapping resolved cards is noise.** A packed or left-out card moving
carries no decision. **Applied:** only unresolved cards swap; with fewer than
two left, nothing moves.

**L2 — A repeat set.** Two finds in a row could deal the same pair. **Applied:**
a new set never repeats the previous `common`.

**L3 — Hard Morning Sort is medium plus a bag.** True and intended: hard drifts
faster and asks one bag more; decoys stay absurd (a subtle decoy is a judgement
call, not a fair wrong answer). Recorded in the plan.

**L4 — The poster's pizza.** Dropped (§3.1); logged in `OPEN_QUESTIONS.md` with
the bank, so the owner can veto any entry.

---

## Checked and found sound

- No `DismissMethod`, schema, host or pool change: `RingingHost` builds through
  `GameRegistry.build`; practice and the chooser read `GameCatalogue.playable`.
- Both win headlines (`All sorted!`, `Spotted it!`) and win poses exist; the
  Morning Sort pose carries a backpack, which now matches the game.
- No new art file → no bundle growth.
- Outcome lines never interpolate an item name into a sentence (gender and case
  in de/ru/fr/es/it/pt/ar); names appear only as `label: value`.

# Phase 14 — Post-review

**Authored games — Morning Sort, Find the Impostor. Done 2026-11-18,
unattended.**

## What shipped

- **Morning Sort** (`lib/core/games/morning_sort.dart`,
  `lib/features/games/morning_sort_view.dart`): pack what Capy needs this
  morning. An authored bank of 10 useful items and 8 absurd decoys (no pizza —
  logged); 2/3/3 pockets per bag, 2/3/4 bags to win. A decoy is set aside
  ("Capy can leave that at home."), counts as a struggle, loses nothing. Cards
  are the item's **name** (no item art exists — G37); pockets fill with a check;
  the backpack Capy beside them. The final bag stays on show, packed.
- **Find the Impostor** (`lib/core/games/find_the_impostor.dart`,
  `lib/features/games/find_the_impostor_view.dart`): one Capy doing something
  different among identical ones — 16 bundled poses in four groups (no
  lookalike-animal art exists — G38). 4/6/8 cards, 2/3/4 finds; easy and medium
  pair across groups, hard within one, cheering/party hat never paired. A wrong
  tap keeps the same set. Each card's screen-reader label names its pose.
- **`DriftingGrid`** (`lib/features/games/drifting_grid.dart`): the motion both
  games share — `swap` (Morning Sort: two unresolved cards trade places) or
  `carousel` (Find the Impostor: every card steps round the ring, so motion
  never points at the odd one). Rest 3.2/2.6/2.0 s, 450 ms slide. No beat while a
  finger is anywhere on the grid; a tap mid-slide goes to the card the user
  aimed at; still (reduce-motion or a screen reader, read every build) snaps
  every card home.
- **`GameOutcomeLine.serial`**: a repeated outcome from a new answer is
  announced again — now in Rhythm Rescue and Capy Rocket too.
- `ArtUse.gameCapy` + `CapyArt.gameCapys` (16 poses, already bundled — no new
  file), **+46 ARB keys × 10 locales**, both games `playable` and registered.
  The content-bank lift is recorded in `CLAUDE.md`.

## Numbers

**1,987 tests** (+99 against 1,888; registered +80–110 — within range). Analyze
clean incl. infos. `lib` **98.46%**, `lib/core` **99.70%**, `lib/core/games`
**100%**, `lib/features/games` **100%**, `lib/data` 89.17%,
`lib/features/ringing` 98.71%. **544 ARB keys × 10 locales** (+46; registered
+45–55). Comment baseline **113** (+0). `assets/art` unchanged (no new file).
`grep "Phase [0-9]" lib` (hand-written Dart) = 0.

## Review trail

Pre-review 15 (5H/6M/4L) · SR1 9 (2H/4M/3L) · SR2 8 (0H/2M/6L, an unanchored
subagent read, re-checked here) · full-project 5 (0H/2M/3L) — **37 findings,
all applied, none invalid.**

## Discrepancies and resolutions

| Plan said | Shipped | Why |
|---|---|---|
| Both games drift by pairwise swaps | Find the Impostor drifts as a carousel | A swap showed nothing or pointed at the odd card — found on device (SR1-H1) |
| Impostor rest 2.4/1.8/1.3 s, Sort 2.6/2.0/1.5 s | 3.2/2.6/2.0 s for both | A carousel moves every card; words need reading time (SR1-H1, M3) |
| Impostor rows 88 pt | 84 pt | The small-phone clock guard: 1 pt over Catch the Capy |
| Hit test follows the painted card | Hit test follows the card aimed at | Mid-slide taps were lost or mis-counted (SR2-G1) |
| Packed card: `accentDeep` border + check | cocoa border, cocoa check on an accent disc | 2.6:1 → ~8:1 (SR2-G5) |
| A badge reserved under the name | Badge over the card's corner | It covered long names (SR1-M2); the cell keeps its measured height |
| Tests +80–110, ARB +45–55 | +99, +46 | Within the registered ranges |

## Tier A / Tier B

**Tier A binds nothing**: the posters are bezel storyboards (1122 × 1402), as
for every game since Phase 11. **Tier B, reported in session and logged:**
- **G37** — Morning Sort: no item art, no open backpack. Names only; pockets
  drawn as UI; the backpack Capy (`collection_02`) beside them.
  `ART_REQUESTS.md` #10–11.
- **G38** — Find the Impostor: no lookalike animals. The bundled Capy poses
  instead; the game's question changes from "which is the real capybara" to
  "which Capy is doing something different". `ART_REQUESTS.md` #12.
- `moments_13` stands in for `collection_00` (same sleeper) so the header
  mascot keeps a unique path.

**Home changed:** Find the Impostor's Home tile no longer shows "Soon"
(`docs/visual/home/actual.png`, recaptured). `01_HOME.png` draws no badge
there, so this moves Home toward the mockup.

## Device and capture evidence

- **iPhone 18 Pro** (`flutter run`, iOS 27, 2026-11-18): Find the Impostor from
  the Home tile — the carousel steps every card one place (seen across
  screenshots), a miss gives "That one matches. Look again."; the chooser lists
  six games with "Try it"; Morning Sort practice — drift, a decoy left at home
  (badge clear of the name after the SR1 fix, hot-reloaded), items packed into
  pockets, **a bag finished** ("Bag packed.", 1 / 3, a new bag dealt).
- **Not hand-won on the iPhone 18 Pro.** The simulator-control tool's taps land
  3–7 s after the screenshot they were aimed from, longer than a carousel rest,
  so a moving grid cannot be played by hand through it (SR1-L3). Turning on
  Reduce Motion from the tool did not take effect in the running app.
- **iPhone 14 Pro** (`tool/capture.sh`, after the last code change, nothing
  else running): `home ringing_morning_sort win_morning_sort
  ringing_find_the_impostor win_find_the_impostor` — **All captures verified.**
  Both games **won on a ringing alarm in moving mode** by the harness as a user
  would (read each card's name / find the picture that appears once), the alarm
  dismissed and the win shown ("All sorted!", "Spotted it!").
- Android: **not tested** (no emulator).

## Open questions logged

Morning Sort's bank (pizza dropped; every entry vetoable); Find the Impostor's
adaptation; words-only item cards until icons arrive. All in
`docs/sessions/OPEN_QUESTIONS.md`, conservative choice taken.

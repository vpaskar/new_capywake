# Phase 14 — Authored games: Morning Sort, Find the Impostor

**Revised after `PHASE_14_PRE_REVIEW.md` (15 findings, 5H/6M/4L, all applied).**
The deltas are folded in below; one line each in §11.

Two more wake-up games on the Phase 11 contract and the Phase 12 selection
model. **No new dependency, no permission, no schema bump, no change to the
alarm flow, no new art file:** a game arrives by flipping its catalogue entry and
adding one registry line.

Ran **unattended** (owner, 2026-11-18): questions go to
`docs/sessions/OPEN_QUESTIONS.md` with the conservative choice taken meanwhile.

**The content-bank ban is lifted for these two games only (owner,
2026-11-15).** The legacy banned authored content because every entry must ship
in ten locales; this phase authors two small banks and translates every entry.
`CAPYWAKE_LEGACY_AUDIT.md` §8 says the lift is "to be recorded in guardrail docs
when those games are built" — this phase records it in `CLAUDE.md`.

Reference: `reference/01_REFERENCES/games/posters/08_MORNING_SORT.png`,
`05_FIND_THE_IMPOSTOR.png`. **Tier A binds nothing** — bezel-wrapped storyboards
(1122×1402, Russian side copy), as for every game since Phase 11.

---

## 1. Objective

- Morning Sort and Find the Impostor are playable on a ringing
  `DismissMethod.puzzle` alarm (via the wake pool) and in practice.
- Both are **dynamic** (owner rule, Phase 12): their cards drift — two swap
  places on a beat — and both stop all motion under `disableAnimations` **or**
  a screen reader, staying finishable there.
- Both count a **struggle** (a wrong tap) so the host can raise the escape
  against the alarm's resolved tolerance. The escape stays `RingingScreen`'s.

## 2. What the posters ask for, and the art that exists

| Poster | Asks for | In the package | Built |
|---|---|---|---|
| MS | "Pack Capy's morning backpack"; six item cards with icon + name (toothbrush, apple, sock / duck, brick, pizza); a backpack with three dashed pockets | **No item art at all** (`asset_library/icons` are 65–128 px UI icons, none an item); no open backpack | item cards with the **name only** (a real `Text`); the bag's pockets drawn as UI (dashed slots, not art); the bundled backpack capybara (`mascots/collection_02.webp`) beside the bag — **Tier B, reported** |
| FI | "Which one is the real capybara?"; a 3×3 grid of lookalike faces (beaver, otter, hamster, guinea pig) and one capybara | **No lookalike-animal art** | the 31 bundled capybara poses: one Capy doing something different among identical ones — **Tier B adaptation, reported** |

Never generated: no drawn icon, no emoji, no `CustomPaint` animal.

## 3. Morning Sort

### 3.1 Content bank — `lib/core/games/morning_sort.dart`

`MorningItem` enum, each with `useful`:

- useful (10): toothbrush, toothpaste, apple, banana, waterBottle, keys, socks,
  shoes, comb, towel.
- left at home (8): brick, anchor, trafficCone, bowlingBall, cactus,
  rubberDuck, anvil, snowman.

Decoys are absurd on purpose: a half-asleep decision must be quick and
unambiguous. The poster's **pizza is dropped** (some people do eat it for
breakfast — a judgement call is not a fair wrong answer); logged.

### 3.2 Round — `MorningSortRound` (pure Dart, 100%)

- `pocketsFor` (useful per bag): easy 2, medium 3, hard 3.
- `decoysFor`: easy 2, medium 3, hard 3.
- `targetFor` (bags): easy 2, medium 3, hard 4.
- A bag's items: `pockets` useful + `decoys` left-at-home, drawn from two
  seeded decks (each category shuffled once, dealt in order, wrapping), then
  shuffled together.
- State: `items`, `packed` (set), `leftOut` (set), `bags`, `wrongTaps`,
  `lastOutcome` (`packed` | `leftOut` | `bagDone`).
- `tap(index)`: no-op once complete or on a resolved card. Useful → packed; the
  last pocket → `bags + 1`, a new bag, outcome `bagDone`. Decoy →
  `wrongTaps + 1`, the card is marked left-out (it cannot be tapped twice),
  outcome `leftOut`. Nothing packed is ever lost.
- `challenge` → `GameChallenge.touch(target, completed: bags,
  struggleCount: wrongTaps)`.

### 3.3 View — `lib/features/games/morning_sort_view.dart`

Card: `GameHeader` (one instruction) → bag row → item grid → outcome line.

- **Bag row**: the backpack capybara (56 pt, H2) and a row of pocket slots, one per
  useful item; a packed pocket fills with `accentDeep` and a check. Semantics
  "Pocket {n} of {total}: empty" / "Pocket {n}: {item}".
- **Item grid**: 2 rows; 2 columns on easy, 3 on medium/hard. Each card is a
  button "{item}"; packed → check + "{item}: packed", left out → dimmed +
  "{item}: left at home". Card height fixed per game from the bank's longest
  name — all 18 localized names laid out at the cell width and current text
  scale, no `maxLines`, no `FittedBox` (M6) — so nothing moves between bags.
- **Drift** (moving): every `swapEveryFor` (easy 2.6 s, medium 2.0 s, hard
  1.5 s) two **unresolved** cards swap places over 500 ms (L1).
- **Still**: no swaps; packing is instant.

## 4. Find the Impostor

### 4.1 Content bank — `lib/core/games/find_the_impostor.dart`

`CapyPose` enum, 16 poses in four groups of visibly different silhouettes:

| Group | Poses (bundled file) |
|---|---|
| rest | asleepNightcap (`collection_00`), curledAsleep (`moments_00`), underBlanket (`moments_01`), onPillow (`moments_07`) |
| busy | hiking (`collection_02`), jogging (`collection_10`), liftingWeights (`moments_03`), holdingClock (`collection_11`) |
| joy | cheering (`collection_03`), partying (`collection_09`), superhero (`moments_12`), blushing (`moments_09`) |
| calm | holdingMug (`collection_07`), reading (`moments_06`), listening (`collection_06`), detective (`collection_05`) |

Every label is written against the picture (H1): "asleep in a nightcap",
"curled up asleep", "tucked under a blanket", "resting on a cushion",
"walking with a backpack", "jogging in a headband", "lifting weights",
"holding an alarm clock", "cheering", "in a party hat", "in a superhero cape",
"blushing with a heart", "holding a warm mug", "reading a book",
"wearing headphones", "with a magnifying glass". `collection_08` (side-on
stretch, close to `collection_15`) is not in the bank.

Near-twins in the bundle (`collection_00`/`moments_13`, `collection_02`/
`moments_02`, `collection_04`/`moments_04`, `collection_12`/`moments_06`,
`collection_13`/`moments_10`) never appear together: only one of each is in the
bank. On top, `excludedPairs` = {cheering/partying} — at 72 pt the hat is the
only difference (H4). A test asserts no deal is ever a twin or excluded pair.

### 4.2 Round — `FindTheImpostorRound` (pure Dart, 100%)

- `cellsFor`: easy 4, medium 6, hard 8.
- `targetFor` (finds): easy 2, **medium 3** (the poster's three dots), hard 4.
- easy/medium: the odd one is from a **different** group; hard: the **same**
  group (subtler, still a different silhouette).
- State: `common`, `odd`, `oddAt`, `found`, `wrongTaps`, `lastOutcome`
  (`found` | `missed`).
- `tap(cell)`: odd → `found + 1`, a new seeded set; other → `wrongTaps + 1`, the
  **same** set (it eases, it never gets harder). A new set never repeats the
  previous `common` (L2).

### 4.3 View — `lib/features/games/find_the_impostor_view.dart`

Card: `GameHeader` → grid (2 rows, `cells / 2` columns, 88 pt rows) → outcome.
Each cell a button "Capy {n} of {total}: {pose}", art 72 pt
(`ArtUse.gameCapy`), excluded from semantics; the cell keeps a cream backing in
dark mode, the art's own ground (M3). Drift as Morning Sort (easy 2.4 s, medium 1.8 s, hard 1.3 s, 450 ms).

## 5. Shared — `DriftingGrid`

`lib/features/games/drifting_grid.dart`: a fixed-height `Stack` of
`AnimatedPositionedDirectional` cells, a permutation, one `Timer?`, a seeded
swap source (`lib/core/games/game_drift.dart`, pure), a `generation` that resets
the permutation, and which cells may move.

- **No swap starts while a pointer is down** on the grid; the countdown
  restarts on pointer up; a slide in flight finishes — the hit test follows the
  painted card (H3).
- `moves` is passed **every build**; turning false cancels the timer and snaps
  the permutation back to identity, so reading order is grid order (H5).
- One `Timer?`, cancelled in `dispose`, on completion and when still (M5).
- Swaps seeded from the ring's seed: a replay and a capture are reproducible.

## 6. Wiring

- `GameCatalogue`: both → `playable`, `screenReaderSolvable: true` (every card
  is a labelled button and the labels carry the answer).
- `GameRegistry.builders`: two lines.
- `ArtUse.gameCapy` (72 pt → 216 px; the narrowest bundled pose is 230 px);
  `CapyArt.gameCapys` catalogues the 16 poses as `game.capy.<pose>`, in `all`,
  so the manifest's resolution and existence tests cover them (M2). Morning
  Sort's bag Capy is `game.capy.hiking`.
- `integration_test/capture_test.dart`: `ringing_morning_sort`,
  `win_morning_sort`, `ringing_find_the_impostor`, `win_find_the_impostor`.
- `CLAUDE.md`: record the content-bank lift.

## 7. Strings (estimate +45 to +55 keys × 10 locales)

18 item names, 16 pose descriptions, instructions, pocket / cell / state
labels, outcomes.

## 8. Tests (estimate +80 to +110)

Core to 100% (tables, determinism, bank invariants, ease rules, no-ops,
challenge); `game_drift` to 100%; views mounted in `RingingScreen`; drift with
explicit `pump`; still mode never animates; RTL; dark; semantics; dispose
mid-swap; completion once; host launch, escape, dismissal; clock guard over six
games (H2). Drift driven with explicit `pump(swapEvery)` + `pump(slide)` (M4);
still flipped mid-slide (H5); no swap while a pointer is held (H3).

## 9. Acceptance

All gates green; both games won on the iPhone 18 Pro in practice; ringing + win
captures via `tool/capture.sh`; gaps reported.

## 10. Risks and rollback

- Long translated item names overflow a 3-column card → measured height, wrap,
  no `FittedBox`.
- Drift under the finger → countdown restarts on touch.
- Rollback: revert the phase commit; no stored data changes.

## 11. Pre-review deltas

- **H1** labels written against the pictures; `collection_08` out, `moments_09` in.
- **H2** bag row 56 pt, `sm` gaps; both games in the clock guard.
- **H3** no swap while a pointer is down; countdown restarts on pointer up.
- **H4** `excludedPairs` (cheering/partying) on top of the twin exclusion.
- **H5** `moves` every build; still snaps to identity.
- **M1** G37/G38 + `ART_REQUESTS.md`, reported in session. **M2**
  `ArtUse.gameCapy`, `CapyArt.gameCapys`. **M3** cream backing in dark.
  **M4** explicit pumps. **M5** one timer, cancelled. **M6** measured height.
- **L1** only unresolved cards swap. **L2** no repeated `common`. **L3** hard =
  one more bag + faster drift. **L4** pizza dropped, bank logged for the owner.

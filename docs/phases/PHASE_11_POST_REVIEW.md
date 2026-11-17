# Phase 11 — post-review

**Game foundation — what a "game" is in this codebase.** The shared contract the
ten wake-up games (Phases 12-17) slot into. **No specific game built, no new
visible surface shipped** (pre-review H3). Foundation stayed headless; proven by a
test-only conformer mounted in the real `RingingScreen`.

## What shipped

- **`lib/core/games/game_challenge.dart`** — the headless contract, pure Dart.
  Goal in discrete steps (`target`/`completed`, `isComplete`); `struggleCount`
  the game defines; `escapeVisibilityFor({toleratedStruggles})` mapping struggle
  to `PuzzleEscapeVisibility` — the **enum** reused, `PuzzleEasingState`'s
  puzzle-answer arithmetic **not** (pre-review H1). Public surface is six members,
  **no** score/streak/best/elapsed (pre-review M4). Motion variant **requires** a
  non-motion fallback at the call site, and asserts the fallback does not itself
  need motion (pre-review H4 + SR1 H1).
- **`lib/features/ringing/game_ringing_view.dart`** — the widget contract beside
  `PuzzleView`: `onProgress` + `onCompleted`, `reduceMotion` threaded through
  `GameRingingSlot` (reads `MediaQuery.disableAnimations`, pre-review M1). **The
  escape is owned by `RingingScreen`; a game has no seam to render, hide, or gate
  it** (pre-review H2).
- **`GameCatalogue` → ten entries** (was four), zero `playable`, with a
  **`homeRail` subset of four** so the Home rail does not regress (pre-review
  M2/M3). Six product name keys added (**ARB +6 → 446**); six tile gaps logged
  **G23-G28**.

## Registered vs. measured (restated, not widened)

| Metric | Baseline | Registered | Measured | Note |
|---|---|---|---|---|
| Tests | 1,547 | +18 to +30 | **1,572 (+25)** | Inside the band. The +25 = catalogue/contract/widget tests plus SR1's 3 bound/fallback guards and SR2's policy-equivalence guard. |
| ARB keys | 440 | **+6** (restated in pre-review from the plan's +0) | **+6 → 446** | The six game name keys M2 required; the plan's +0 was corrected in the pre-review, not at commit. |
| lib coverage | 97.93% | ≥ 85% | **97.95%** | Rose — the SR guards. |
| lib/core | 99.61% | ≥ 95% | **99.61%** | `lib/core/games` 100%. |
| lib/data | 88.95% | ≥ 85% | **88.95%** | Untouched — no data code. |
| Comment baseline | 113 | +0 | **113 (+0)** | Every new file met the budget by hand. |
| `grep Phase` (Dart, excl. generated) | 0 | 0 | **0** | Name the layer, not the phase. |

analyze clean including infos; `dart format` clean; `check_arb`, `check_bundle_size`,
`check_no_fake_stats` (now 49 files) all pass.

## Tier A

**Binds nothing.** The only references are the ten game posters and six portrait
boards — bezel-wrapped storyboard crops with marketing annotations
(`04_CATCH_THE_CAPY.png` is a phone render on a cream board with Russian copy),
not 851×1847 native geometry. Same as Phases 06/09/10. Phase 11 ships no new
visible surface to capture; the Home rail is unchanged (four tiles) and its Tier A
block test still passes.

## The reviews

- **Pre-review:** 13 findings (4H/5M/4L), all applied. The four Highs reshaped the
  work: escape signaled in the game's own terms (H1), escape owned by
  `RingingScreen` (H2), **foundation stays headless** (H3), motion fallback
  compile-required (H4).
- **SR1:** 3 findings (1H/1M/1L). **H1 — a motion game's fallback could itself
  require motion**, defeating the a11y guarantee; now asserted against. M1 — goal
  bounds (`target > 0`). L1 — the escape-reachability test is correct, not vacuous.
- **SR2:** 2 findings (1M/1L) + a mutation check. **M1 — the escape policy source
  was implicit**; a test now proves a game and a puzzle offer the escape
  identically against the user's `toleratedWrongAnswers`, so a Phase 12 game that
  diverges fails. The mutation check (suppress completion → dismiss test fails)
  confirmed the widget test is not a guard on trust (Phase 06's rule).
- **Full-project:** one candidate examined and found **valid, not a defect**. The
  Home "See All" games action routes to the Stats tab (`home_screen.dart:103`).
  The pre-review L1 called this a dangling action with "no destination" — **that
  was wrong**: `PHASE_03_PLAN.md:202` records it as a deliberate decision (See All
  → the Stats Games segment, both tabs, `go` not `push`). With ten games it is
  still coherent. Corrected here; no change.

## Device verification

**Phase 11 ships no new interactive surface**, so there is nothing new to drive by
hand — the pre-review (H3) made this a **regression** check, not a new-surface one.
The one runtime-visible touch is the Home game rail, whose rendering source
changed (`entries` → `homeRail`) while its output (four tiles, same taps, same
sheet) did not. The widget suite pins this (Home Tier A block test + rail tests
green), and the app was **launched on the iPhone 18 Pro (iOS 27.0)** to confirm it:
Home draws **exactly the four tiles** (Step Quest, Shake DJ, Catch the Capy, Find
the Impostor) in order — **not the ten** the catalogue now holds — each marked
"Soon", with "See All ›" present and no broken image. Tapping Step Quest opened the
"Not built yet" sheet reading *"Step Quest needs a permission CapyWake does not ask
for yet"* — the `blocked`/`stepCount` reason rendering correctly from the grown
catalogue. The rail did not regress and the game interaction is intact. Android
untested, no emulator — never marked tested.

## Carried forward (owed by nobody)

Unchanged from Phase 10's list: the sleep-boundary / `package:health` restoration
(now unbuilt across 07-11); `CapyNavBar` 98.7 vs 79.9 (three meadows);
`MeadowFooter` 2× grass (G19); `SceneHeader` flat top (G18); Alarms 3 / Add-Edit 8
Tier A failures; `AlarmEngine.ringNow` called by nothing; Settings theme tiles no
art (G12); `check_bundle_size` blind to the three native plugins.

**New, for Phase 12:** a game-launch path must pass `settings.toleratedWrongAnswers`
into `GameChallenge.escapeVisibilityFor` (SR2 M1 — the policy stays the user's),
and must honor `reduceMotion` from `GameRingingSlot`. The six tile gaps G23-G28
are each a game-phase's to fill. No game is wired to a live alarm yet — Phase 11 is
the contract, not a product.

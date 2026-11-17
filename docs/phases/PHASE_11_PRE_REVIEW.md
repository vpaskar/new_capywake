# Phase 11 — pre-review (adversarial, before any code)

Read against `PHASE_11_PLAN.md`, the ringing surface as it is wired today
(`ringing_host.dart`, `ringing_screen.dart`, `ringing_controller.dart`,
`puzzle_view.dart`), the ported domain (`puzzle_round.dart`,
`puzzle_difficulty.dart`, `puzzle_settings.dart`, `dismiss_method.dart`), the
existing `GameCatalogue`, and `CLAUDE.md`'s content-integrity / safety / comment
/ coverage rules.

**13 findings: 4 High, 5 Medium, 4 Low. All applied in the revised plan or marked
invalid with a reason.** The plan is revised after this pass (protocol step 5).

## Registered expectations (restate on measurement, do not pass quietly)

- **Tests:** baseline 1,547. Phase 11 is mostly headless contract + tests, no new
  product. Expected **+18 to +30**. Low end if the catalogue stays at four and no
  onboarding demo ships; high end if ten entries + a widget-contract test + a
  `disableAnimations` test + negative guards land. **If measurement lands outside
  this band, restate it in the post-review with the reason — do not widen the
  band after the fact** (Phase 10's rule).
- **ARB keys:** baseline 440. Expected **+0** if the foundation stays headless
  (H3 settles this). Any key added is named and justified against a shipped
  surface.
- **Coverage:** lib ≥ 85% (currently 97.93%), `lib/core` ≥ 95% (99.61%),
  `lib/data` ≥ 85% (88.95%, untouched — Phase 11 adds no data code). New
  `lib/core/games` and `lib/features/ringing` code at the core/feature bar.
- **Comment baseline:** 113. Expected **+0**. Every new file meets 2 lines / 300
  chars per block by hand.
- **`grep "Phase [0-9]" lib/ --include=*.dart` excl. generated:** must stay **0**.

---

## High

### H1 — The plan reuses `PuzzleEasingState` for a game's escape-raise; it does not fit a game

`PHASE_11_PLAN.md` §0/§1/R3 say the game contract should reuse
`PuzzleEasingState` / `escapeVisibilityFor` to raise the escape. **But**
`PuzzleSettings.escapeVisibilityFor` (`puzzle_settings.dart:166`) raises the
escape on `state.wrongThisRound > toleratedWrongAnswers` — a count of **wrong
puzzle answers**. A game like Catch the Capy has no "wrong answer"; it has missed
taps, elapsed time, abandoned rounds. Threading a game's "struggle" through a
field named `wrongThisRound` is a semantic lie that the next six phases would
inherit, and it would force every game to fabricate a puzzle-answer count it does
not have.

**This is the same class as Phase 10 SR1 H1** (a control handed a state it cannot
honestly represent) and Phase 08 (a gate blind to a shape). Reusing the *enum*
`PuzzleEscapeVisibility` (available / prominent) is right — reusing the *puzzle's
trigger arithmetic* is wrong.

**Applied (plan revised).** The contract exposes an **abstract escape signal in
the game's own terms**: a game reports, each progress update, whether the user is
**struggling** (a boolean the game computes however fits it — missed attempts,
elapsed rounds, a retry count). The foundation maps that to prominence against
the **same user setting** the puzzle uses (`toleratedWrongAnswers` →
generalized/renamed at the contract boundary to a tolerance the game reads), so
the *policy* (how strict the escape is) stays the user's single setting and the
*measurement* (what "struggling" means) belongs to each game. The enum
`PuzzleEscapeVisibility` is reused; `PuzzleEasingState` is **not** a game
dependency. The contract test asserts: struggling beyond tolerance → prominent;
within tolerance → available (never hidden).

### H2 — "The escape threads through" must be non-optional *and* independently reachable, or Phase 12 can ship a lockout

The safety rule: "Never ship a puzzle **or game** without a reachable emergency
escape" — always a High finding if violated. The plan says the contract makes the
escape non-optional (R2), but a contract where a game *supplies* its own escape
widget could still let a game draw a broken/unreachable one and pass. Phase 06's
real defect was exactly this: `showModalBottomSheet` had no Navigator ancestor
and the escape threw in the live app while every screen test passed.

**Applied (plan revised).** The escape is **not** the game's to render. It stays
owned by `RingingScreen._Actions` / `_confirmEscape` / `showEscapeSheet` — the
surface the foundation already ships and Phase 06 proved reachable. A game's only
responsibility is to *signal* when the escape should be raised to prominent (H1);
it never draws, hides, or gates the escape control itself. The contract has **no
seam through which a game can suppress the escape**. A test places the reference
conformer in the real `RingingScreen` and asserts the escape control is present
and tappable regardless of game state — the exact structure of Phase 06's
`escape_sheet` wiring, so a Phase 12 game inherits a reachable escape for free.

### H3 — "A playable onboarding demo conformer" risks building a game in the foundation phase

The plan flirts (R4, §0, §5) with shipping a visible "demo" conformer wired into
the onboarding "Try it" step, to use the three unused strings. **That is a game
surface** — interactive, drawn, device-verifiable — in the phase whose entire
discipline is *not to build a game*. `CLAUDE.md`: "Do not implement future
phases." Phase 10 left those three strings for "a games phase that wants a live
demo" — **a games phase, not the foundation phase.** Spending them here blurs
exactly the games≠foundation line this phase exists to draw, and pulls in ARB/UI
scope the phase does not need.

**Applied (plan revised).** **The foundation stays headless.** No onboarding demo
ships in Phase 11. The reference conformer is **test-only** — no route, no ARB, no
catalogue entry, no poster, no tile, no product name. The three onboarding
strings stay unused, exactly as Phase 10 left them, and the post-review restates
that they wait for a *games* phase (12–17), not the foundation. This also pins
**ARB +0** (registered above). The widget contract is proven by a widget **test**
that mounts the conformer in the real `RingingScreen`, which is stronger evidence
than a demo button and needs no new strings. Device verification (H9/plan §7)
becomes a **regression** check — the ringing surface still rings and dismisses
unchanged — not a new-surface check.

### H4 — The motion-fallback invariant must be unrepresentable-when-violated, not merely tested

The plan (§1.1, §6) says a motion game without a fallback should "fail to
construct / throw". A runtime `assert` is stripped in release (`flutter run
--release`), so an `assert`-only invariant is **not** a safety guarantee — it is a
debug-only one. Phase 15's motion games are the ones this protects, and they ship
in release. A motion game that silently has no fallback in a release build is a
safety defect (motion-based games need a non-motion fallback — mandatory).

**Applied (plan revised).** The invariant is enforced by the **type**, not a
runtime assert: `requiresMotion` and the fallback are modeled so that *declaring a
motion game forces supplying a fallback at the call site* — e.g. a sealed
constructor split (`GameChallenge.motion({required fallback})` vs
`GameChallenge.touch()`), so a motion game with no fallback **does not compile**.
If a pure-type encoding proves impractical, the fallback is a *required*
non-nullable constructor parameter on the motion variant (still compile-enforced),
**plus** a test — never an `assert` as the only guard. The contract test asserts a
motion conformer always yields a usable non-motion path.

---

## Medium

### M1 — `disableAnimations`: the plan says "define the seam" but a seam no game is forced to use is Phase 06's "guard on trust"

`CLAUDE.md` demands `disableAnimations` be honored "everywhere", and grep confirms
**zero** readers in `lib/` today. A foundation that merely *offers* a read seam
the games *may* call is a guard on trust (Phase 06's lesson): Phase 12 forgets to
call it and nothing fails. 

**Applied (plan revised).** The seam is **threaded into the contract**, not left
beside it: the game-view contract receives `reduceMotion` as a constructor input
the foundation reads from `MediaQuery.disableAnimations` at the single launch
point (the ringing host building the slot), so a game cannot *not* receive it. A
test asserts the host passes the real platform flag through, and the reference
conformer asserts it does not animate when the flag is set. (Retrofitting the five
built screens stays out of scope — §6/R6 — but the *games'* path is closed, which
is what Phase 11 owns.)

### M2 — `GameCatalogue` to ten introduces six tile-id gaps and six name keys; the plan leaves which, undecided

R5 leaves ten-vs-four open. Leaving it open into implementation is how Phase 03
shipped a wrong constant. Decide now.

**Applied (plan revised): grow to ten.** The foundation's whole point is to be the
shape all ten slot into; a catalogue of four cannot express that, and Phases
12–17 each need their entry to exist to flip `comingSoon → playable`. So all ten
ship now, **zero `playable`**, with:
- **Name keys:** the six missing games need name keys
  (`gameMemoryHideout`, `gameRhythmRescue`, `gameCapyRocket`, `gameTiltMaze`,
  `gameMorningSort`, `gameQrTreasureHunt`). **These are ARB additions** — so
  **ARB is +6, not +0.** This contradicts H3's "+0"; H3 is about *not shipping a
  demo surface*, M2 is about *catalogue completeness*. The six name keys are
  justified (a real, rendered See-All list naming ten games) and are **product
  names**, localized like the existing four. **Registered ARB expectation is
  therefore revised to +6**, restated here, not discovered at commit.
- **Tile ids:** the six have no tile art. They carry a tile id and the absence is
  logged as an **asset gap** (`asset_gaps.md` G23–G28). A test asserts the gap is
  *recorded* (not that the asset exists). The Home rail still shows only the four
  that `01_HOME.png` draws (it reads the first four, or a `homeRail` subset — see
  M3); the See-All list shows ten with the six using a **placeholder tile
  treatment that is clearly not final art**, never a broken `Image.asset`.

### M3 — Growing the catalogue to ten will change what the Home rail renders unless scoped

`GameRail` builds from `GameCatalogue.entries` (all of them). Today that is four,
matching `01_HOME.png`. If `entries` becomes ten, the Home rail silently grows to
ten tiles — a **Tier A regression on a shipped primary screen** (`01_HOME.png`
draws four), and six of them would have no tile art. This is a real
behaviour-change hiding inside a "foundation" catalogue edit.

**Applied (plan revised).** The catalogue gains an explicit **`homeRail`** subset
(the four `01_HOME.png` draws, in its order) distinct from the full `entries`
(ten). `GameRail` reads `homeRail`; the See-All list reads `entries`. A test pins
the Home rail at exactly the four, in order, so this phase cannot regress Home.
The existing `game_rail_test.dart` is checked and extended to assert the count is
four against `homeRail`, not `entries`.

### M4 — "No score/streak/timer" asserted structurally is weaker than it sounds

The plan (§6) asserts "no score/streak/timer field exists" structurally. A Dart
test cannot reflect over fields to prove a *negative*. What it can do is assert
the contract's public surface exposes none and that a conformer cannot report one.
State the real guarantee.

**Applied (plan revised).** The guarantee is: the `GameChallenge` public API
exposes **only** `target`, `completed`, `isComplete`, `isStruggling`,
`requiresMotion`, and the motion fallback — **no** `score`, `streak`, `best`,
`elapsed`, `rank`, `points`. The test asserts the *present* API shape (these
getters exist and behave) and a **comment-free** compile-time fact: there is no
public numeric achievement member. The post-review states plainly that Dart cannot
prove the negative by reflection, so the guard is the small, reviewed public
surface plus the safety rule, exactly as `PuzzleRound` guarantees it
(`puzzle_round.dart:41` is a *doc comment*, not a test — the foundation does one
better with an API-shape test).

### M5 — The reference conformer must not become a de-facto eleventh product

Phase 06 warns against infrastructure that drifts into a feature. A "reference
conformer" rich enough to be interesting is a game; one trivial enough to be
honest proves the contract. It must live in `test/`, not `lib/`.

**Applied (plan revised).** The reference conformer is defined **in the test
file**, not shipped in `lib/`. It is the minimum that exercises every contract
member: a counter game that completes at `target` taps, reports `isStruggling`
after a set number of resets, declares `requiresMotion == false`. No art, no name
key, no catalogue entry, no route. If a motion variant is needed to test H4, it is
likewise test-only.

---

## Low

### L1 — "See All" already has a string but no destination

`homeGamesSeeAll` ("See All") exists in ARB (Phase 03) and the Home rail heading
has a trailing action slot, but there is **no See-All screen**. If M2 grows the
catalogue to ten, a See-All list is the natural place the ten show — but building
a *screen* is scope the plan did not claim.

**Applied.** Phase 11 does **not** build a See-All screen (that is a Home/catalogue
surface, not the game foundation). The catalogue grows to ten so a future See-All
*can* list them, but the destination stays unbuilt and the trailing action stays
as it is. Noted so Phase 11 is not blamed later for a dangling "See All" it did
not introduce — the string and the dangling action predate it (Phase 03). The
post-review records this as pre-existing, not a Phase 11 regression.

### L2 — `blockedReason` covers stepCount and camera; the ten games map cleanly, verify no third reason is needed

Step Quest → `stepCount`, QR Treasure Hunt → `camera`. The other eight are
`comingSoon`. Confirm none of the eight needs a *third* blocked reason (e.g.
microphone for a rhythm game).

**Applied.** Checked against the ten posters and the legacy audit §8: only Step
Quest (step count) and QR Treasure Hunt (camera) carry platform blockers. Rhythm
Rescue is a **touch** rhythm game (tap-to-the-beat), not microphone-driven — the
poster shows tapping, and the legacy audit lists no audio-input dependency. Shake
DJ and Tilt Maze are **motion** (accelerometer, already in the stack via
`sensors_plus`), so they are `comingSoon`, not `blocked` — motion is not a
permission-gated capability the way step-count/camera are. No third
`GameBlockedReason` is added.

### L3 — The contract's file placement: `lib/core/games/` vs `lib/features/ringing/`

The headless challenge state is domain (`lib/core/games/`, Flutter-free — the
`core` rule). The widget-side launch contract is a feature concern
(`lib/features/ringing/` or `lib/features/games/`). The plan mentions both; be
explicit so `core` stays Flutter-free.

**Applied.** `lib/core/games/game_session.dart` (or `game_challenge.dart`) is
**pure Dart, no Flutter import** — the `core` rule, verified by the fact that
`game_catalogue.dart` already lives there importing only `meta`. The widget
contract (the two callbacks + `reduceMotion`) lives in the **ringing** feature
beside `PuzzleView`, since that is where the slot is. **No new `lib/features/games/`
top-level** is created in Phase 11 — the games themselves (12–17) will each add
their own feature module; the foundation does not pre-create an empty one (a
TODO-only placeholder is forbidden by `CLAUDE.md` hard rules).

### L4 — Comment budget will bite every new file

Every new `lib/` file is comment-budgeted (2 lines / 300 chars per block, blank
`///` separator counts as a line). Phases 05/06/07/08 each had the budget bite
all new files; all were trimmed by hand, none baselined.

**Applied.** Every new file is written to the budget from the start, trimmed by
hand, and the baseline stays at **113**. `dart run tool/trim_comments.dart` is run
to confirm, never `--update-baseline`.

---

## Outcome and plan deltas

13 findings, all applied, none deferred, none invalid.

The ones that change the shape of the work:

1. **H1** — the game's escape-raise is signaled in the game's own terms
   (`isStruggling`), mapped to the user's tolerance setting at the contract
   boundary. `PuzzleEasingState` is not a game dependency.
2. **H2 + M1** — the escape stays owned by `RingingScreen`; a game can only
   *signal* prominence, never render/hide/gate the escape. `reduceMotion` is
   threaded through the contract, not offered beside it.
3. **H3** — **the foundation stays headless.** No onboarding demo, no new route,
   no new visible surface. Proven by a widget test mounting a test-only conformer
   in the real `RingingScreen`. The three onboarding strings stay unused.
4. **H4** — the motion-fallback invariant is **compile-enforced** (type / required
   param), not an `assert`.
5. **M2 + M3** — catalogue grows to **ten** (zero `playable`), with an explicit
   `homeRail` subset of four so Home does not regress; **ARB is +6** (six product
   name keys), restated here, not the plan's original +0. Six tile gaps logged
   G23–G28.
6. **M4/M5/L3** — the no-gamification guarantee is an API-shape test; the
   conformer is test-only; `core` stays Flutter-free, no empty feature module.

**Revised registered expectations:** tests **+18 to +30**, **ARB +6** (not +0),
coverage bars unchanged, comment baseline +0, `grep Phase` 0.

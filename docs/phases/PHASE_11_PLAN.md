# Phase 11 — Game foundation

**Revised after `PHASE_11_PRE_REVIEW.md` (13 findings, 4H/5M/4L, all applied).**
The deltas are folded in below; the one-line summary of each is in §10.

**What a "game" is in this codebase.** The shared contract every one of the ten
wake-up games (Phases 12–17) slots into. This phase builds **no specific game**
and **ships no new visible surface** (pre-review H3 — the foundation stays
headless): only the abstraction — what interface a game implements, how it is
launched from the ringing surface, how it reports progress / completion to the
dismiss flow, how the emergency escape (owned by `RingingScreen`, never the game)
threads through it, how an a11y / non-motion fallback is *compile-required* of
every motion game, and how `disableAnimations` is honored.

Reference screenshots: **the ten game posters** in
`reference/01_REFERENCES/games/posters/` and the six portrait boards in
`.../games/portrait/`, plus the four home tiles in
`reference/02_ASSETS/game_tiles/`. **Tier A binds nothing** — see §2.

---

## 0. The one architectural decision, and why it is settled here

`DismissMethod` (`lib/core/models/dismiss_method.dart`) is `normalButton` /
`holdToDismiss` / `puzzle`. **There is no `game` value, and Phase 11 adds none.**

A game is **not** a fourth `DismissMethod`. Adding one would be a `lib/core`
domain change rippling through the Drift mapper (`schemaVersion` bump — forbidden,
no users or not), `AlarmDismissSummary`, the Phase 10 chooser, the per-alarm
dismiss section, and 1,547 tests — for a Phase 12 product that does not exist yet.
Phase 10's SR1/the owner's rule is explicit: "Shake" and games are **not**
`DismissMethod`s (`asset_gaps.md` G21/G22; Phase 10 current-phase §3).

So the model is: **a game is a kind of *puzzle challenge surface*, parallel to
`PuzzleView`, launched by the same `DismissMethod.puzzle` path.** A game is one
more thing the ringing surface can draw in its `puzzleSlot` instead of the
arithmetic/sequence puzzle. The *selection* of which challenge (a generated
puzzle type vs. a playable game) is a later-phase concern — Phase 11 only defines
the slot's contract and proves it with the existing puzzle as its first
conformer, plus a trivial foundation-only reference conformer.

**Consequence, stated up front:** Phase 11 does **not** wire any game into a live
alarm. No alarm can launch a game after Phase 11, because no game exists. What
Phase 11 ships is the *contract and the launch plumbing*, demonstrated by a
**test-only** reference conformer mounted in the real `RingingScreen`
(pre-review H3/M5). **No onboarding demo ships** — the three unused onboarding
strings (`onboardingTryGame`, `onboardingPracticeNote`, `onboardingPracticeRetry`)
stay unused, waiting for a *games* phase (12–17), not the foundation. "Do not
implement future phases" (`CLAUDE.md`) — a playable demo is a future-phase
surface.

---

## 1. Objective

Define, in `lib/`, the shared game contract and the plumbing that lets a future
game launch from ringing, report completion, and thread the escape — with a test
harness that proves the contract holds, and zero behaviour change to any existing
screen.

Concretely:

1. **`lib/core/games/game_challenge.dart`** — the headless contract, **pure Dart,
   no Flutter import** (the `core` rule, pre-review L3). What a game *is* as domain
   state. A `GameChallenge` abstraction with:
   - a goal in discrete steps: `target` and `completed` — the poster shape
     (`3 / 5` pips; `Серия 2/4`), matching `PuzzleRound`'s
     `solvedCount`/`taskCount`.
   - `isComplete` — `completed >= target`.
   - `isStruggling` — a boolean the game computes **in its own terms** (missed
     taps, resets, elapsed rounds), **not** a borrowed `wrongThisRound`
     (pre-review H1). The foundation maps `isStruggling`, against the user's
     single tolerance setting, to `PuzzleEscapeVisibility.prominent` /
     `.available` — reusing the *enum*, not `PuzzleEasingState`'s puzzle-answer
     arithmetic. The escape is **never** hidden; `available` is already a
     labelled reachable control.
   - **public API exposes only** `target`, `completed`, `isComplete`,
     `isStruggling`, `requiresMotion`, and the motion fallback — **no** `score`,
     `streak`, `best`, `elapsed`, `rank`, `points` (pre-review M4). An API-shape
     test pins the present surface; the post-review states Dart cannot prove the
     negative by reflection, so the guard is the small reviewed surface plus the
     safety rule.
   - a **compile-enforced** motion-fallback invariant (pre-review H4): a motion
     game is constructed through a variant that **requires** a non-motion
     fallback at the call site, so a motion game with no fallback **does not
     compile** — not an `assert` (stripped in release). The contract test asserts
     a motion conformer always yields a usable non-motion path.
2. **The widget-side launch contract, in `lib/features/ringing/`** beside
   `PuzzleView` (pre-review L3 — no new `lib/features/games/` module; an empty
   module is a forbidden placeholder). A game view slots into
   `RingingScreen.puzzleSlot` exactly as `PuzzleView` does, with **two callbacks
   and nothing else**: `onProgress` (→ the host raises the escape to prominent
   when `isStruggling` crosses tolerance) and `onCompleted` (→
   `controller.dismiss`). **The escape control itself stays owned by
   `RingingScreen._Actions` / `showEscapeSheet`** (pre-review H2) — a game can
   only *signal* prominence; it has **no seam to render, hide, or gate** the
   escape. It also receives `reduceMotion` (pre-review M1), read once by the host
   from `MediaQuery.disableAnimations`, so a game cannot *not* receive it.
3. **`GameCatalogue` → ten entries** (pre-review M2). Today **4** Home-rail
   entries; Phase 11 completes it to **all ten games** with availability
   (`comingSoon` for eight, `blocked` for Step Quest/`stepCount` and QR Treasure
   Hunt/`camera`). **Zero `playable`.** An explicit **`homeRail` subset of four**
   (the `01_HOME.png` games, in order) is added distinct from `entries` (ten), so
   **the Home rail does not regress** to ten tiles (pre-review M3). `GameRail`
   reads `homeRail`; `entries` is the full list a future See-All would show. Six
   new games need **product name keys** → **ARB +6**; six have **no tile art** →
   logged as gaps G23–G28, and the rendering path for a gap tile **must not call
   `CapyArt.byId`** (it throws `ArgumentError` on an unknown id, `art.dart:130`) —
   a guarded placeholder, never a broken `Image.asset`. (No See-All *screen* is
   built — pre-review L1; that destination predates this phase.)
4. **`disableAnimations` honoring** — threaded through the widget contract
   (pre-review M1), not merely offered beside it: the host reads the flag and
   passes it in, a test asserts the host passes the real platform flag, and the
   reference conformer asserts it does not animate when set. **grep finds zero
   current readers in `lib/`** — this closes the gap for the *games' path* only;
   retrofitting the five built screens is out of scope (§5).

Nothing in `lib/app/`, no new dependency, no Drift change. **ARB +6** (six game
name keys), restated from the pre-review, not discovered at commit.

---

## 2. Reference and the fidelity contract

**Tier A binds nothing for this phase.** The only references are the ten game
posters and six portrait boards — each is a storyboard crop inside an iPhone
*bezel* with marketing annotations beside it (verified: `04_CATCH_THE_CAPY.png`
is a phone render on a cream board with Russian "Идея/Будит/Интересно" copy), not
851×1847 native geometry. This is the same situation as Phases 06 (ringing), 09
(onboarding) and 10 (chooser), and it is declared, not worked around.

The posters nonetheless fix the **shared game shape** every game inherits, and
the foundation encodes it: header + "Alarm!" banner (already the ringing hero), a
**game title**, a **one-line instruction**, a **progress indicator** (`N / total`
+ pips), and a **play area**. These are Tier-B-illustration-level facts about
layout, logged if a foundation surface renders, never a Tier A claim.

If Phase 11 ships **any** visible surface (the onboarding demo conformer, or a
foundation scaffold widget), it is captured only to the extent a block table
exists; absent a native mockup, its deviations are *named*, not scored. Most of
Phase 11 is headless contract + tests and renders nothing new.

---

## 3. Assets and asset→mockup mapping

No new art is imported. The four existing tiles (`tile.stepQuest`,
`tile.shakeDj`, `tile.catchTheCapy`, `tile.findTheImpostor`) stay and remain the
`homeRail` four. The six games without a tile (`memory_hideout`, `rhythm_rescue`,
`capy_rocket`, `tilt_maze`, `morning_sort`, `qr_treasure_hunt`) enter `entries`
(pre-review M2) carrying a tile id the art package does not supply — logged as
**asset gaps G23–G28** (`asset_gaps.md`), never generated and never shipped as a
broken image. A catalogue-gap test asserts each gap is **recorded**, not that the
asset exists. Because `CapyArt.byId` throws on an unknown id (`art.dart:130`), the
foundation must never resolve a gap tile through it — but in Phase 11 the six gap
tiles are **not rendered anywhere** (the Home rail reads `homeRail`, the four with
art; no See-All screen is built), so no placeholder widget is needed yet. The
guarded-placeholder requirement is recorded for the phase that first renders the
full `entries` list.

---

## 4. Dependencies

**None added.** `sensors_plus ^7.0.0` is already in the locked stack (legacy
audit §3) and belongs to Phase 15 (motion games), not Phase 11. Phase 11 defines
the *requirement* that a motion game declares `requiresMotion` and ships a
fallback; it imports no sensor. `package:health`, camera, pedometer — all out of
scope and some blocked by owner decision (Phases 16/17).

---

## 5. Scope

In:

- The headless `GameChallenge` / `GameSession` contract in `lib/core/games/`.
- The widget-side game-view contract in `lib/features/ringing/`.
- A **reference conformer** used only by tests (and possibly the onboarding demo)
  that implements the contract trivially, proving it is implementable and that
  completion → dismiss and escape-raise both fire. This is the foundation's own
  "hello world", disjoint from the ten products.
- The `GameCatalogue` completion to ten (or a reasoned decision to hold at four).
- The `disableAnimations` read seam the games inherit.
- Tests mirroring every new `lib/` file under `test/`.
- Any ARB keys a *shipped* surface strictly needs (expected: **0** if no new
  visible surface ships; small and named if the onboarding demo ships).

Out (named, not deferred silently):

- **Any specific game.** Catch the Capy, Shake DJ, etc. are Phases 12–17.
- Wiring a game into a live alarm's dismiss (no game exists to wire).
- Retrofitting `disableAnimations` onto the five built screens.
- The sleep-boundary / `package:health` restoration (owed by nobody, carried).
- `CapyNavBar` 98.7 vs 79.9, `MeadowFooter` 2× grass, `SceneHeader` flat top —
  carried-forward Tier A debt, not this phase's.
- Motion sensors, camera, pedometer.

---

## 6. Tests

Mirror `lib/` under `test/`. Planned:

- **Contract tests** (`test/core/games/game_challenge_test.dart`): a test-only
  reference conformer reaches `isComplete` only at `target`; below `target` is not
  complete; the **public API shape** is exactly the six members, no achievement
  member (pre-review M4); `isStruggling` beyond the user tolerance → `prominent`,
  within → `available`, **never hidden** (pre-review H1); the motion variant
  **cannot be constructed without a fallback** (compile-enforced — the negative is
  proven by the absence of a no-fallback constructor, demonstrated in the plan,
  and the positive by a motion conformer always yielding a non-motion path,
  pre-review H4).
- **Catalogue tests** (extend `game_catalogue_test.dart`): **the existing
  `'has the four entries 01_HOME.png shows'` test is updated** — it now asserts
  **`GameCatalogue.homeRail`** is exactly those four in order, and a new test
  asserts `entries` is the **ten** with zero `playable`; every `blocked` entry
  carries a reason and every non-blocked none (over ten); every `homeRail` tile id
  resolves in `CapyArt`; every `entries`-only tile id is **recorded in
  `asset_gaps.md`** (a test asserting the gap is logged); all ten name keys resolve
  in ARB.
- **Widget-contract test** (`test/features/ringing/...`): the reference conformer,
  placed in the **real** `RingingScreen.puzzleSlot`, (a) calls `onCompleted` at
  goal → dismiss, (b) its `onProgress` raises the escape to prominent when
  `isStruggling` crosses tolerance, and (c) **the escape control is present and
  tappable regardless of game state** (pre-review H2 — a game cannot suppress the
  escape; the structure mirrors Phase 06's `escape_sheet` wiring). Pinned so a
  Phase 12 game that forgets to signal, or that tries to own the escape, **fails**.
- **`reduceMotion` / `disableAnimations` test** (pre-review M1): the host passes
  the real `MediaQuery.disableAnimations` into the game view; the reference
  conformer does not animate when the flag is set. Fails if the host drops the
  flag.
- Guard-style negative tests where a finding warrants (Phase 06's rule: a guard
  whose test cannot fail when the guard is removed is a guard on trust) — notably
  the escape-reachability test must fail if the conformer is allowed to hide it.

Registered counts are in `PHASE_11_PRE_REVIEW.md` (tests **+18 to +30**, **ARB
+6**); restated in the post-review on measurement, never silently widened.

---

## 7. Acceptance criteria

- `GameChallenge`/`GameSession` contract exists, headless, in `lib/core/games/`,
  with the escape-visibility, no-gamification, and motion-fallback invariants
  **enforced by tests that fail when removed**.
- A reference conformer proves completion → dismiss and escape-raise, placed in
  the real `RingingScreen.puzzleSlot`, behaving as `PuzzleView` does.
- `GameCatalogue` has **ten `entries`** (zero `playable`) and a **`homeRail`
  subset of four**; the Home rail is pinned at the four so it cannot regress.
- `reduceMotion` / `disableAnimations` is threaded through the game-view contract,
  with a test that the host passes the real platform flag.
- Full validation block green, read from the `Coverage (...)` line: lib ≥ 85%,
  `lib/core` ≥ 95%, `lib/data` ≥ 85%. `lib/features` new code covered.
- `flutter analyze` zero issues **including infos**.
- ARB complete across all ten locales: **+6 game name keys** (`gameMemoryHideout`,
  `gameRhythmRescue`, `gameCapyRocket`, `gameTiltMaze`, `gameMorningSort`,
  `gameQrTreasureHunt`), each × 10 locales = 440 → **446**.
- Comment budget: every new file meets 2 lines / 300 chars; **baseline stays at
  113**, none added.
- `grep -rn "Phase [0-9]" lib/ --include="*.dart"` excl. generated returns **0** —
  name the layer, not the phase number.
- No new dependency; no Drift change; no `schemaVersion` bump.
- Device check on the iPhone 18 Pro if any visible surface ships; otherwise the
  ringing surface still rings and dismisses unchanged (regression check).

---

## 8. Risks

- **R1 — Over-building.** The temptation is to build a game "to prove the
  contract". The reference conformer must be trivial and test-only (or the single
  onboarding demo), never one of the ten products. Guard: the conformer has no
  poster, no tile, no catalogue entry, no product name.
- **R2 — Faking the escape thread.** A game-view contract that *allows* skipping
  the escape would let Phase 12 ship a lockout (always a High finding). The
  contract must make the escape non-optional and a test must fail if a conformer
  omits it. Mirror Phase 06's guard discipline.
- **R3 — Inventing a parallel easing/visibility.** Reuse `PuzzleEasingState` /
  `PuzzleEscapeVisibility` / `escapeVisibilityFor`. A second escape-raising
  mechanism is a second thing to get wrong.
- **R4 — Spending the onboarding demo surface prematurely.** The three unused
  onboarding strings may now be used (Phase 10 said so, deliberately) — but a
  playable onboarding demo is itself a small game surface. Pre-review decides
  whether it ships in Phase 11 or whether the foundation stays headless + the
  demo waits. Default lean: **stay headless**; a demo is only justified if it is
  the cheapest honest way to prove the widget contract renders on device.
- **R5 — Catalogue to ten vs. four.** Ten entries makes the See-All real but
  introduces six tile gaps and six name-key additions (or reuse). Four keeps it
  honest to what renders today. Pre-review decides; whichever way, it is explicit
  and `asset_gaps.md` records any introduced gap.
- **R6 — `disableAnimations` scope creep.** The seam is for the games. Not a
  retrofit of the five screens (out of scope, §5). The temptation to "fix it
  everywhere" is a different phase.
- **R7 — ARB over-provisioning.** Phase 10's lesson (ARB came in at +2 vs a
  registered +10–14) cuts both ways: do not add keys for surfaces that do not
  ship. Expected +0.

## 9. Rollback

Single commit on `main`. New files: the `game_challenge` contract, the ringing
game-view contract, their tests. Edits to existing files: the `GameCatalogue`
extension (ten entries + `homeRail`), the updated catalogue test, the six ARB keys
× 10 locales, and `asset_gaps.md` (G23–G28). `PuzzleView` and the Home rail keep
working unchanged (the rail reads the new `homeRail`, same four). Revert the commit
to roll back; no migration, no data shape change, no `schemaVersion` bump.

## 10. Pre-review deltas folded in (one line each)

- **H1** — escape-raise signaled via the game's own `isStruggling`, mapped to the
  user tolerance at the contract boundary; `PuzzleEasingState` is not a game dep.
- **H2** — the escape stays owned by `RingingScreen`; a game can only signal
  prominence, never render/hide/gate it. No suppression seam.
- **H3** — **foundation stays headless**: no onboarding demo, no new route/surface;
  the three onboarding strings stay unused for a games phase. Proven by a widget
  test mounting a test-only conformer in the real `RingingScreen`.
- **H4** — motion-fallback invariant is **compile-enforced** (variant requires a
  fallback), not a release-stripped `assert`.
- **M1** — `reduceMotion` threaded through the contract, read from
  `disableAnimations` at the single host launch point.
- **M2** — catalogue grows to **ten** (zero `playable`); **ARB +6** name keys; six
  tile gaps G23–G28.
- **M3** — explicit **`homeRail`** subset of four so Home does not regress to ten.
- **M4** — no-gamification is an **API-shape** test over the six public members.
- **M5 / L3** — reference conformer is **test-only**; `core` stays Flutter-free; no
  empty `lib/features/games/`.
- **L1** — no See-All screen built (pre-existing dangling action, not Phase 11's).
- **L2** — only Step Quest (`stepCount`) and QR Treasure Hunt (`camera`) are
  blocked; Rhythm Rescue is touch, Shake DJ / Tilt Maze are motion (`comingSoon`).
  No third `GameBlockedReason`.
- **L4** — comment budget met by hand on every new file; baseline stays 113.

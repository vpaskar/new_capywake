# Phase 13 — Post-review

**Touch games II — Rhythm Rescue, Capy Rocket. Done 2026-11-18, unattended.**

## What shipped

- **Rhythm Rescue** (`lib/core/games/rhythm_rescue.dart`,
  `lib/features/games/rhythm_rescue_view.dart`): four numbered pads light a
  pattern in time (3/4/5 beats at 750/600/480 ms by difficulty), the user taps it
  back in order; 2/3/4 patterns to win. Timing is never judged. A wrong pad is a
  struggle and replays the same pattern; ▶ replays for free. Still mode
  (reduce-motion or a screen reader, re-read every build) shows every beat's
  numeral and never animates.
- **Capy Rocket** (`lib/core/games/capy_rocket.dart`,
  `lib/features/games/capy_rocket_view.dart`): swipe (or tap the arrow button)
  the way the cue points; 6/8/10 boosts, climb 700/550/420 ms. A wrong way
  wobbles the rocket, counts as a struggle, loses nothing. The rocket hovers in
  finite cycles with a 150 ms rest (so `pumpAndSettle` settles); still mode
  neither hovers nor wobbles. RTL mirrors layout and swipe; button labels name
  the physical side.
- Shared: `GameOutcomeLine` (a live region reserving two measured lines), and
  `GameHeader` progress is now a live region in all four games.
- `CapyPadColors` (four tokens sampled from the poster), `games/sky.webp`
  (21 KB), **+18 ARB keys × 10 locales**, both games `playable` and registered.

## Numbers

**1,888 tests** (+121 against 1,767; registered +70–100 — **restated**: the
four review passes added layout, live-region, timer and clock guards the plan
did not foresee, ~40 of them). Analyze clean incl. infos. `lib` **98.34%**,
`lib/core` **99.69%**, `lib/core/games` **100%**, `lib/features/games`
**100%**, `lib/data` 89.17%, `lib/features/ringing` 98.71%. **498 ARB keys × 10
locales** (+18; `next.md`'s "466" before this phase was stale — HEAD had 480).
Comment baseline **113** (+0). `assets/art` 1,582 / 2,182 KB.
`grep "Phase [0-9]" lib/*.dart` (excl. generated) = 0.

## Review trail

Pre-review 15 (5H/6M/4L) · SR1 6 (2H/2M/2L) · SR2 6 (2H/2M/2L) · full-project
5 (1H/2M/2L) — **32 findings, all applied, none invalid.**

## Discrepancies and resolutions

| Plan said | Shipped | Why |
|---|---|---|
| Rocket 100 pt (pre-review H3) | 72 pt | The bundled pose is 217 px (SR2-H2) |
| Sky field 280 pt + control row | 228 pt, buttons in the field's corners | 566 pt card covered the clock (SR1-H2, SR2-H1, FP-H1) |
| Instruction "…to fly Capy up." | "Swipe the way the arrow points." | One line, so the card fits Catch the Capy's height (FP-H1) |
| Pads square, 72 pt min | 72 pt min height, width from the row (~76 pt) | Square would cap at the row width; height grows with text |
| ARB +14–18 | +18 | Within the registered range |
| Tests +70–100 | +121 | Review-pass guards (restated above) |

## Tier A / Tier B

**Tier A binds nothing**: the posters are bezel storyboards (1122 × 1402), as
for every game since Phase 11. **Tier B, logged in `asset_gaps.md`:** G35 (no
headphones capybara — the painted tile stands in) and G36 (no flying rocket — the
win pose at 72 pt; no sun bar — the shared pips). Both requested in
`ART_REQUESTS.md` (#8, #9) and reported in session.

## Device and capture evidence

- **iPhone 18 Pro** (`flutter run`, 2026-11-18): chooser lists all four games;
  Rhythm Rescue practice plays the pattern, a wrong pad gives the calm line and
  replays; Capy Rocket practice boosts on the cued button and on **real swipes
  right and left**; the 72 pt rocket checked after hot restart.
- **iPhone 14 Pro** (`tool/capture.sh`, after the last layout change):
  `home ringing ringing_{catch_the_capy,memory_hideout,rhythm_rescue,capy_rocket}
  win_{…same four}` — **All captures verified.** Both new games won by the
  harness the way a user would (Rhythm Rescue: watch the lit pads in real time,
  tap them back; Capy Rocket: follow the cue). Both new cards clear the clock
  (`docs/visual/ringing_rhythm_rescue/`, `ringing_capy_rocket/`).
- Android: **not tested** (no emulator).

## Open questions logged

Capy Rocket cue vs any-swipe; Rhythm Rescue timing not judged; short-phone clock
overlap (FP-H1). All in `docs/sessions/OPEN_QUESTIONS.md`.

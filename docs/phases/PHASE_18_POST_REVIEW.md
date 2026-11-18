# Phase 18 — Post-review

## What shipped

1. **The theme picker works.** `MaterialApp.themeMode` follows Settings →
   Theme (System / Light / Dark), re-themes the open app, and the first frame
   waits ≤ 400 ms for the saved choice — with the theme cross-fade off until
   then — so a night ring never flashes light.
   Before this phase the picker saved a value nothing read.
2. **A dark-mode pass with evidence.** Eight dark captures through the real
   setting (`docs/visual/dark_mode.md`), a WCAG contrast gate over 25
   surfaces in **both** themes (every route, every game's practice, both ring
   kinds), and five defects fixed: the invisible header wordmark and gear, the
   ringing page's cream band, the reliability card's text (dark, and light
   since Phase 07), and disabled alarm rows faded below legibility — the
   mockup draws them at full ink.
3. **The clock preference reaches the ringing clock and the soft-wake
   reminders** (re-written when it changes), which both ignored it.
4. **A new art gate**, `outlineCoverage`, on every bundled sticker.

## What did not ship, and why

**The five loops.** Four are damaged (G43–G46); the clean one (G47) has no
surface that would not undo the owner's 2026-11-18 win art. `04_shake_dj` was
encoded (241 KB against a 220 KB prediction) before it was seen on cream with
its outline masked away, and removed. Reported in session; `ART_REQUESTS.md`
#15–16. No bundle change.

**Muting the app under a ring.** Tried and reverted (self-review #1 H1):
Riverpod pauses every watch under `TickerMode(false)`, the alarm-arming one
included. Now guarded by a test.

## Reduce-motion

Recorded, not rebuilt: the framework runs every ordinary animation at 5 %
under the platform flag, `Image` pauses multi-frame art, and each game stops
under reduce-motion **and** a screen reader (tested per game since Phase 11).
The phase's one new motion source was the loop, which did not ship.

## Tier A / Tier B

Tier A: disabled alarm rows are no longer faded — closer to `02_ALARMS.png`,
which draws them at full ink (re-measured below). The ringing clock changes
only under a 24 h preference. Tier B: the wordmark is re-inked in dark (`srcIn` on a
one-colour glyph, the art itself unchanged).

## Instruments, and what they cannot see

- The contrast gate cannot see raster lettering or measure text over art
  (counted per screen as `art`); the wordmark was found by capture and has its
  own test. `CustomPaint` text is invisible to it (none in `lib/`).
- `outlineCoverage` catches masked outlines (G44, G46), not flat cuts inside
  the frame (G43) or a missing part (G45); dark fur near the edge reads as
  outline.
- The reminder format provider and its re-sync are tested; the closure that
  reads it lives in `platform_engine_overrides.dart`, which no test can build.
- Android has no emulator; nothing here ran on Android.

## Mutation checks

Every guard was removed and its test watched fail: themeMode (3 tests), the
first-frame hold, its cap, the no-cross-fade first frame, the reminder
re-sync, the light reliability text, the ringing clock format (host), the night page (widget test and gate),
the header wordmark/gear, the reliability card (via the gate), and the gate's
planted dark-on-dark label.

## Alarms re-measured (`tool/compare.dart alarms 02_ALARMS`)

Removing the disabled-row fade changes no geometry: worst delta is card 4 top
**+5.6 pt** (Tier A fail, carried since Phase 07 under "Owed by nobody"),
everything else within ±3.6; the compare reports the hero edge and nav bar
`absent`, its known blind spots. The tracker's earlier "card 3 bottom +4.8,
meadow +10.0" now read −2.2 and +0.4.

## Follow-up (owner, same day): every win picks its art

Owner: "show all of them in random order". `WinArt.forSeed` (pure, uniform —
checked over 3,000 sequential and 30,000 random-id seeds) picks the game's own
pose, the shared cheer or the trophy loop per win, from the ring's seed (a
random occurrence id) or the practice round's. The trophy is
`animations/loop_celebration.webp` (36 × 80 ms, 320 KB, audited per frame;
art budget still inside). `TickerMode` holds it on frame 0 under reduce-motion
**and** a screen reader. Ten device captures show all three kinds.

**Harness defect found on the way:** three win captures (QR, Step Quest, Tilt
Maze) had been taken mid fade-in since Phase 16–17 — a live binding draws only
pumped frames and an animation's clock starts on its first, so the single
pump before the screenshot was the entrance's frame 0. The capture now pumps,
waits in real time, pumps again.

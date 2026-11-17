# Phase 12 — Full-project review

Read across the whole app with Phase 12's surfaces in place, on device (iPhone
18 Pro) and in verified captures (iPhone 14 Pro). **6 findings: 2 High,
2 Medium, 2 Low. All applied; none invalid.**

## H1 — Settings painted a row's title over its value (shipped in Phase 07)

Seen on device on the way to the chooser: **"Default snooze leng9 minutes"**. It
is in Phase 07's own committed capture (`docs/visual/settings/actual.png`), unseen
for five phases. `SettingsChevronRow` gave title and value one `Flexible` each
(half the row apiece) and set the title to `overflow: visible`, `softWrap:
false` — a long title kept its single line and painted straight over the value.
The comment beside it said "a title is never truncated", which was true and was
the bug.

**Applied:** the value is capped at 40 % of the row and ellipsizes; the title
takes the rest and wraps if it must. **Guard:** a row test in all ten locales
asserts no title glyph paints past its own box and the two rects do not overlap.
Run against the Phase 07 file it **fails 10 of 10**; against the fix it passes.
Re-captured: Settings' Tier A is unchanged (header +0.1, hero +0.1, group 2 top
−0.6; group 1 bottom +4.5 is Phase 07's declared 44 pt tap-floor conflict).

## H2 — Four locales called the puzzles "games"

es (*juego*), fr (*jeu*), it (*gioco*) and ar (*لعبة*) translated "puzzle" as
"game" across 17–19 keys each. Harmless while no game existed; after Phase 12
the chooser reads, in French, "Types de jeux" under a section that lists actual
games — a user cannot tell the two apart. pt uses *desafio* for puzzle
consistently, which collided with my new pool label "Desafios para acordar";
ja's new label used パズル where the bundle says 問題. The Arabic task count also
read "1 game".

**Applied:** 73 strings retranslated to acertijo / énigme / rompicapo / لغز; my
pt and ja keys reworded to each bundle's existing term; one unused Turkish key
fixed. **Guard:** `test/l10n/puzzle_game_vocabulary_test.dart` forbids each
locale's word for "game" in puzzle copy — against the old Spanish bundle alone it
finds 19 offenders.

## M1 — Memory Hideout's Ready was a twin of Snooze

In the ringing capture, the filled orange **Ready** sat directly above the filled
orange **Snooze**. `PuzzleView`'s own submit is an in-card secondary control; a
half-asleep user should not have to tell two identical orange pills apart.

**Applied:** Ready is an outlined, full-width, `CapyButton.height` control in ink,
with no splash (no animation on the ringing surface). Test pins it.

## M2 — A ringing capture could show empty game cards

The second capture of Memory Hideout showed bare cards: `pumpAndSettle` does not
wait for image decoding, so the screenshot raced the art. The device and the
first capture both showed the art — the harness, not the app (Phase 05's rule:
check the instrument). **Applied:** the capture pre-caches every on-screen image
before the screenshot.

## L1 — `PuzzleSettingsFields` claimed a second caller it never had

Its doc said "shared by the chooser and the per-alarm override"; Add/Edit has
never used it. **Applied:** corrected.

## L2 — Home after the rail change

Re-captured to discharge pre-review M5: the same six `absent` blocks and worst
measured delta **1.4 pt** as Phase 07's honest figure. Catch the Capy lost its
"Soon" badge, which the mockup never drew. No change needed beyond the record.

## Still owed by nobody (carried, unchanged)

The sleep-boundary / `package:health` restoration; `CapyNavBar` 98.7 vs 79.9;
`MeadowFooter` 2× grass (G18/G19); Alarms 3 / Add-Edit 8 Tier A failures;
`AlarmEngine.ringNow` uncalled. Android untested, no emulator.

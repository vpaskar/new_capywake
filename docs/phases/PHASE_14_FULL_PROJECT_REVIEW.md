# Phase 14 — Full-project review

The whole app against this phase's changes: every game that shares a widget
this phase touched, the screens whose captures moved, and the documents that
describe the game set. **5 findings: 0 High, 2 Medium, 3 Low. All applied; none
invalid.**

---

## Medium

**FP1 — Rhythm Rescue and Capy Rocket swallow a repeated outcome too.** SR2 G4
fixed `GameOutcomeLine` for the two new games; the two Phase 13 games use the
same widget and repeat outcomes as often ("Not quite…" after two wrong pads,
"Other way…" after two wrong swipes). **Applied:** both pass a serial
(`rescued + wrongTaps`, `boosts + wobbles`); a Rhythm Rescue test hears the
second miss. Memory Hideout and Catch the Capy do not use the widget — checked:
Memory Hideout's miss line names the bush (consecutive misses rarely read the
same) and its found line is paired with the header's progress live region,
which changes on every find.

**FP2 — The first captures may show code that never shipped.** `tool/capture.sh`
ran while self-review #1's negative tests were editing `drifting_grid.dart` in
the same checkout (the build reads `lib/` when it compiles). **Applied:** every
capture in the post-review was retaken after the last code change, with no
other process touching the tree.

## Low

**FP3 — Home's fourth tile changed.** Find the Impostor is playable, so its Home
tile lost its "Soon" badge (the recaptured `docs/visual/home/actual.png` shows
it). `01_HOME.png` draws no badge on that tile, so this moves Home toward the
mockup; Step Quest and Shake DJ keep theirs. The rail tests are
catalogue-driven and pass unchanged. **Applied:** recorded in the post-review.

**FP4 — "Four games are playable" in the hand-over documents.**
`docs/sessions/next.md` and `memory/current-phase.md` described Phase 13's set.
**Applied:** both rewritten for six games.

**FP5 — The legacy audit still said the bank lift was "to be recorded".**
`CAPYWAKE_LEGACY_AUDIT.md` §8. **Applied:** a pointer to the `CLAUDE.md`
"Content integrity" entry this phase wrote.

## Checked and found sound

- Stats' Games segment names games through `gameName`; both new ids resolve
  (`game_names_test` covers every catalogue entry) and the history stores the
  id the host launched.
- `RingingHost`, practice, the chooser and the Add/Edit pool read the catalogue
  and registry — no change needed; both games appear in the chooser with
  "Try it" (seen on the iPhone 18 Pro).
- No new asset file: the bundle is unchanged.

---

Re-validated with the full list after applying (post-review has the figures).

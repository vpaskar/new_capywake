# Open questions for the owner

The phase chain runs without the owner. Any question a session would have asked
goes here instead, and the session carries on with the most conservative
choice that `CLAUDE.md` allows. Newest at the bottom. The owner answers inline;
the next session reads this file first.

Format: `## <date> — Phase NN — <one-line question>`, then what was decided
meanwhile and what would change if the owner answers differently.

## 2026-11-18 — art import — per-game win poses wear blue nightcaps

Used meanwhile (the Home hero's Capy also wears blue). If the owner wants
orange only, delete the `winPoseAssetId`s in `lib/core/games/game_catalogue.dart`
and the win screen falls back to the orange-capped shared animation.

## 2026-11-18 — Phase 13 — Capy Rocket: follow an arrow, or any swipe?

The poster says only "swipe to speed up". Built meanwhile: an arrow cue (left or
right, random per boost); a swipe the other way wobbles the rocket, costs no
progress, and counts as a struggle (it brings the escape forward — in the
user's favour). Without a cue every swipe succeeds and the game asks for no
attention. If the owner prefers any-swipe, `CapyRocketRound.boost` would accept
every side and the cue pill would go; one change in core, one in the view.

## 2026-11-18 — Phase 13 — Rhythm Rescue: timing is not judged

"Rhythm" is how the pattern is shown (pads light in time); repeating it checks
order only, never timing — a timing window is precision input for a half-asleep
user. If the owner wants timing judged, that is a new mode, not a tweak.

## 2026-11-18 — Phase 13 — Short phones: should a game card cover the clock, or scroll?

On a 375 × 667 phone (iPhone SE) the ringing game card reaches over the foot of
the clock: Catch the Capy by ~19 pt since Phase 12. Tried meanwhile: keeping
the card below the clock — then the card scrolls, and on a short phone the
bottom of Catch the Capy's field sits below the fold mid-game (a half-asleep
user would have to scroll). **Kept the overlap** (the shipped behaviour) and
capped it: a test fails if any game reaches higher than Catch the Capy on that
phone; Capy Rocket was cut to Catch the Capy's height (424 pt). On the
reference phone (393 × 852) every game clears the clock, tested. Options for
the owner: (a) keep; (b) shrink game fields on short screens; (c) a smaller
clock on short screens while a game is up.

## 2026-11-18 — Phase 13 — The chain could not start Phase 14 by itself

`start_session` is refused to a session that was itself started by another
session. Meanwhile: Phase 13 is committed (ea784fe, 52b8c5d), `Current phase:
14`, and a proposal card for Phase 14 sits in the Phase 13 session. Start it
there with one click, or start a new session with the command at the top of
`docs/sessions/next.md`. If the owner wants the chain to run hands-off, each
phase must be started from the owner's own session, not from a linked one.

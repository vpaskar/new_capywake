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

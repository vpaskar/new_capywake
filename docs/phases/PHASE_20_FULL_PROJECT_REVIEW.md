# Phase 20 — Full-project review

Every surface outside the five screens that touches what this phase changed.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| P1 | Med | Add/Edit's summary row (`dismiss_method_section.dart`) still pushes `Routes.settingsPuzzle` — which now lands on the overview, not on the controls themselves. | **Invalid as a defect:** the row is labelled "Wake puzzle" plus the summary, which is exactly the overview's title and content; every control is one tap further. Same route constant, no dead link. |
| P2 | Med | The per-alarm override still uses `ChallengePoolPicker` (puzzles + all games in one list). The app-wide pool is now split across two screens; the two must agree on the floor. | Applied: `ChallengePoolPicker` already floors on playable games only (`GameCatalogue.playable`); the new screens now use the same rule through `hasPlayableGame` (U4). |
| P3 | Med | The ringing surface, the selector and the onboarding strictness step read `PuzzleSettings`; any change of semantics would reach a ring. | Checked fine: no file under `lib/core/`, `lib/data/` or `lib/features/ringing/` changed in this phase; the controller's setters keep their floors. |
| P4 | Low | `docs/visual/dark_mode.md` and `docs/visual/puzzle_chooser/` still described the removed chooser. | Applied: index updated, the stale folder removed. |
| P5 | Low | `SettingsGroup`'s band (28.2 → 24.0) and gap (13.9 → 15.8) are shared with Reliability and Walkthrough. | Applied as intended: both are Settings' siblings and now match `01`. Their tests pass unchanged. |
| P6 | Med | This checkout also holds the "Home stats removal" session's uncommitted owner requests (alarm pictures, dev tools, All Games, 14 tap-action fixes), interleaved with this phase in the same files (ARBs, router, capture harness). | Applied as a stop: nothing is committed until the owner chooses the split (one combined commit, or the other session's work first). Reported in the session. |

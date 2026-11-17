# Win screen — Catch the Capy (and Memory Hideout, `win_memory_hideout/`)

Captured by `tool/capture.sh win_catch_the_capy win_memory_hideout` on the
iPhone 14 Pro simulator: a ring whose alarm draws only that game, finished
through the game's own targets, captured after the 700 ms entrance.

- The alarm is already stopped when this shows (`RingingHost._onGameWon`
  dismisses first); it closes itself after 2.6 s or on **Close**.
- Art: the game's own pose (`animations/pose_*.webp`, blue nightcap — G34
  follow-up), springing in; a still under reduce-motion or a screen reader.
- Text: per-game headline in an accent pill (`gameWinHeadline*`, 10 locales),
  then "Alarm stopped". Practice uses the same panel with "Practice done".
- **Found on this capture, not by the widget tests:** the overlay sat outside
  any `Material`, so every line drew Flutter's yellow-underlined fallback
  style. Fixed (`Material` root); `ringing_host_game_test` now asserts the
  paragraph style and was shown to fail without the fix.
- No mockup exists for this screen; Tier A binds nothing. The pose renders at
  100 pt — the largest the supplied 300 px stays sharp at 3×.

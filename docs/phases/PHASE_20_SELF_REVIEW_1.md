# Phase 20 — Self-review #1

Against the implementation after the first green suite. Every finding is
applied or marked invalid.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| S1 | High | The Games rows overflowed by 114 px at 2× text in German and Portuguese: tile + "Ausprobieren" + switch do not fit 393 pt. Found by the 10-locale × 4-route sweep, not by reading. | Applied: past 1.3× text, "Try it" moves under the title (`PoolSwitchRow.maxInlineTryTextScale`). Sweep green in all locales. |
| S2 | Med | `SettingsChevronRow`'s semantics label joined title and value but not the subtitle — every overview value row (Difficulty · Hard, …) was silent to a screen reader. | Applied: label is title, value, subtitle; an optional hint carries the notification row's manage note (pre-review M3). |
| S3 | Med | `CapyToggle`, the header's back control, the chevron and status rows and the puzzle type card each wrapped their gesture in `ExcludeSemantics` with no `onTap` on the node: a screen reader saw a control it could not activate. Same shape the "Home stats removal" session reported in 14 places. | Applied to the five this phase owns; each node now carries `onTap` (and `enabled` on the toggle). A Games test activates a switch through the semantics owner and reads the write back. |
| S4 | Low | Four existing semantics tests asserted the old node shape (no tap action) — they encoded the defect. | Applied: they now require `hasTapAction` and `isEnabled`. |
| S5 | Med | Settings' Tier A test pinned the header at 59.9 pt from `04_SETTINGS.png`. | Applied: pins the 44 pt compact header and the 92.4 pt hero band from `01`; `compare.dart` and `tier_a_blocks.md` re-measured, method per row. |
| S6 | Low | `settingsPreferencesHeading`, `settingsReliabilityEntryDescription`, `settingsOnboardingEntryDescription` lost their last reader. | Applied: removed from ten ARBs. |
| S7 | Low | `tool/capture.sh` expected a light `all_games` capture the harness never takes (added by the other session's All Games screen), so the verifier would fail. | Applied: `all_games` joined `DARK_ONLY` beside onboarding. |
| S8 | Low | A Settings test found the hero image by `.at(1)`. | Applied: matched by `SceneCrop.settings.asset`. |
| S9 | Low | The old "the overview reads Off" test passed only by accident of seed size (a one-game seed made the Games card read "1 of 10" too). | Applied: seed has two games, so only the Types card can match. |
| S10 | — | "The nav-card titles wrap to three or four lines in Turkish and Portuguese — narrow the icon." | **Invalid:** the widget-test font draws every glyph as a full em square; the capture on the device font decides. Checked there (see post-review). |

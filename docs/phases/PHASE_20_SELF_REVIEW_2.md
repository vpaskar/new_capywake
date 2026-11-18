# Phase 20 — Self-review #2 (unanchored)

A subagent was given the code, `CLAUDE.md` and the owner's spec, not this
session's conclusions or its first review. Static reading only. No High
findings; it confirmed every setting is still reachable, persistence is
unchanged, the escape has no "off", locked switches explain themselves, RTL is
clean and the plurals are valid. Every finding below is applied or invalid.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| U1 | Med | `SettingsHeader` was a fixed 44 pt box: at 2× text the 64 pt title was squeezed into it, clipped top and bottom, on Settings and all four puzzle screens. | Applied: `minHeight`, so the header grows with the title. The new test compares the paragraph's needed height with its laid-out height. **Mutation-checked:** a first version compared rectangles and passed with the defect restored (the squeezed `Text` never leaves its box); rewritten until it failed. |
| U2 | Med | Type cards sat in a fixed-ratio `GridView` with `maxLines: 2` + ellipsis: long German or Russian names, and anything at 2×, truncated. The spec says names wrap. | Applied: rows of two `Expanded` cards at intrinsic height, no line cap. Test: every type name at 2× German sits inside its card with `maxLines == null`. |
| U3 | Med | The 2× sweep only checked `takeException()`; neither silent clipping nor ellipsis throws. | Applied: U1's and U2's tests are the sweep's missing assertions. |
| U4 | Low | The last-game lock counted raw `enabledGames`, so a coming-soon id could stand in as the pool's last member. Latent: all ten games are playable today. | Applied: `hasPlayableGame` is the one floor for the Games lock, the Puzzles lock and both controller setters; unit-tested. |
| U5 | Low | Russian and Japanese new strings used "головоломки" / "パズル" while the switch they name says "Задачи" / "問題". | Applied: the existing nouns. |
| U6 | Low | Russian `one` form "Выбрана" is feminine — wrong for "тип". | Applied: "Выбрано: {selected} из {total}" in every form. |
| U7 | Low | Advanced reused the overview's "Wake puzzle" title, so a screen reader announced two screens identically. | Applied: Advanced is titled "How it works", the heading of the card that opens it. Named deviation from `05`. |
| U8 | Low | `challengePoolLabel` had no reader left (the other three were already removed in self-review #1). | Applied: removed from ten ARBs. |
| U9 | Low | The "overview and stepper name the same wrong answer" test compared a function with its own definition. | Applied: it now finds the rendered value on the overview, opens Advanced, and finds the same text inside the stepper. |
| U10 | Low | The last-type test passed without the card lock: the controller refuses an empty set anyway. | Applied: asserts the locked card's semantics node has no tap action and carries the floor note. |
| U11 | Low | A locked switch's reason named the other pool member's screen with no way to reach it; the visual-only warning had moved off the overview. | Applied: a locked row offers a link to the other screen (Games ↔ Puzzle types), tested both ways; the overview shows `VisualOnlyNotice` when it applies. |
| U12 | Low | `PuzzleHelpText` and `PuzzleHeaderGlyph` doc comments restated their names. | Applied: deleted. |

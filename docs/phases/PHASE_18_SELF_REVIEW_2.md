# Phase 18 — Self-review #2 (unanchored)

A subagent was given the diff and the project rules, not this phase's
reasoning. No High findings; two Medium, six Low; all applied or invalid.

**M1 — The held first frame still flashed light.** The saved theme arrived
while the frame was held, `MaterialApp`'s `AnimatedTheme` started its 200 ms
tween, and the frame was released on its first tick: a cream page fading to
dark at a night ring. The old test checked only `sendFramesToEngine`.
*Applied:* `themeAnimationStyle: noAnimation` while the first frame is held;
a test asserts the first frame sent is `darkCream`, and fails without it.

**M2 — The contrast probe never saw `Stack` siblings.** Text over the ringing
scene was measured against the scaffold, so reverting the night page would not
trip the gate. *Applied:* the probe now composites painted-below `Stack`
children that cover the text, reports text over a raster as `art` (pinned per
screen, judged by the captures), and the night-page revert now fails the gate
(checked).

**L1 — Faded subtrees were skipped.** A disabled alarm row (opacity 0.55) can
still be tapped to edit, so WCAG's inactive-control exemption does not apply.
*Applied:* the probe folds every opacity into both colours, and the seed has a
disabled alarm. It measured the row's label at **3.16:1**. **`02_ALARMS.png`
draws its disabled 8:00 row at full ink** — only the toggle is off — so the
fade matched neither the mockup nor the contrast bar and was removed; the tile
test now pins full ink.

**L2 — Child spans, colourless spans and typed fields were not measured.**
*Applied:* every `TextSpan` with its inherited style; `EditableText` values; a
span with no colour is now a failure, not a skip. `CustomPaint` text is named
as a blind spot (none in `lib/`).

**L3 — The reminder body's clock format went stale.** It was read only at
schedule time, and nothing re-synced when 12/24 h changed. *Applied:*
`notificationTimeFormatProvider`; the coordinator re-syncs on it (tested,
mutation-checked); the production closure checks `ref.mounted`.

**L4 — The root rebuilt on every settings write.** *Applied:* it watches
`select((isLoading, themeMode))`.

**L5 — `outlineCoverage` skipped the outer 3 px and passed alpha-less files.**
*Applied:* every pixel is judged (bounds-checked; a test with ink at the
canvas edge), and the manifest gate requires alpha. Dark fur within 3 px of
the edge still counts as outline — a known limit, named in the post-review.

**L6 — A default `capture.sh` run checked few dark captures; the suffix was
duplicated.** *Applied:* every screen the harness writes is in the default
list; `integration_test/capture_names.dart` holds the suffix for both sides.

**Invalid:** none.

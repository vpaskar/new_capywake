# Phase 18 — Self-review #1

**H1 — Muting the app under a ring pauses alarm arming.** Pre-review M1's
`TickerMode(enabled: false)` around `RingingHost.child` passed its own test
and broke nine host-game tests with a pending resync timer. Cause, read in
`flutter_riverpod` 3.5.0 `consumer.dart:405–430`: a `Consumer` **pauses every
subscription** while `TickerMode` is off — including `AppShell`'s watch on
`alarmScheduleCoordinatorProvider`, the one thing that keeps alarms armed
(`shell.dart:8`). A snooze written during the ring would wait for the ring to
end before arming. *Applied: reverted; a host test now fails if the app beneath
a ring is ever muted, and a two-line note at the call site says why.* Frames
painted under the ring are the accepted cost.

**M1 — The ringing clock ignored the clock preference.** Home, Alarms and
Add/Edit honour 12/24 h; `RingingScreen` hard-coded `system`. *Applied:*
`RingingScreen.timeFormat`, passed by the host from the saved settings; screen
and host tests, the host one mutation-checked.

**M2 — The soft-wake notification ignored it too** (`platformEngineScope` took
`timeFormat` once, defaulting to `system`, and `main` never passed it).
*Applied:* the body reads the saved preference at schedule time through the
override's `ref`. Production-only wiring, like the rest of that file: no test
can build the plugins; recorded.

**L1 — Pre-review M1's remount premise was wrong.** The old shape (bare child
↔ `Stack`) never lost state: the router's navigator `GlobalKey` reparents it.
Proven by putting the old shape back under the identity test — it passed.
*Recorded as invalid; the shape is unchanged.*

**L2 — The contrast gate is blind to two of the defects the captures found**:
the wordmark (raster lettering, no `RichText`) and the ringing page's cream
band (a `Stack` sibling, not an ancestor of any text). *Applied:* each has a
widget test (`capy_header_test`, `ringing_screen_test`), both mutation-checked;
the blind spots are named in the post-review.

**L3 — An enclosed-hole metric was tried for knocked-out ink and was wrong**:
it flagged the wordmark's letter counters and `moments_12`'s gap above the
rock. *Applied:* replaced by `outlineCoverage`, which separates every bundled
sticker (≥ 0.30) from `04_shake_dj` (0.18) and `02_sleep_breathing` (0.20).

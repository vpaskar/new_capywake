# Motion check — Pre-review (adversarial, before any code)

Target: `PHASE_15_MOTION_CHECK_PLAN.md` as first written.

## High

### H1 — The re-ring would ring with no screen to stop it

`RingingController._onRinging` finds this morning's row by its target, sees it
is terminal (dismissed) and returns. A `ringNow` re-ring would therefore play
with no ringing screen. The legacy avoided it by creating a fresh row; the
rebuild's controller does not. **Applied (plan §4):** a claimed re-ring
re-opens the morning's row as `triggered` with `isMotionReRing: true`. Tests:
the re-ring shows the ringing screen, and dismissing it opens no window.

### H2 — A ring's own write re-runs the schedule, which calls `stopAll()`

**Confirmed on the iPhone 14 Pro simulator with the real plugin, and it is not
only the re-ring's problem: every alarm went silent 35 ms after it started.**
A ring's `triggered` write re-runs the schedule; `PlatformAlarmEngine.
rescheduleAll` called `plugin.Alarm.stopAll()`, silencing the ringing alarm,
and re-armed tomorrow. The ringing screen still appeared, so no widget test
(fake engine) could see it. Probe: `ringing=[id]` at 12:32:00.048, `[]` at
.083, tomorrow armed by .175.

**Applied:** `rescheduleAll` stops every stored alarm **except the ringing
ones** and does not re-arm a ringing id (`AlarmPlanMapper.platformIdsToStop`,
`plansToArm`, unit-tested); `cancel` drops the id from the ringing set at once,
so the resync after a dismiss arms tomorrow. Re-probed: `ringing=true` from
12:35:00.13 through +3 s with the screen up.

## Medium

### M1 — Turning the check off mid-window still re-rang

The plan reads the switches at dismiss only. Someone up and in Settings within
the 90 seconds who turns it off would still get the ring. **Applied:** before
`ringNow`, re-read the alarm (deleted, disabled or its switch off → nothing)
and Settings' switch.

### M2 — The window note promised the wrong rule

"Does not move within 90 seconds" — but one movement is not enough; the check
needs 45 separate moving seconds. **Applied (plan §6).**

### M3 — The global-off note said "stops with a tap"

Wrong for a puzzle or game alarm. **Applied (plan §6).**

### M4 — The background limit was unstated

The check runs in the app. If iOS suspends it, readings stop and no extra ring
comes. **Applied:** `alarmMotionCheckLimitNote` in all ten locales, shown under
the description. This is the "never claim more than the OS" rule.

### M5 — A re-ring of a puzzle alarm asks the puzzle again

Considered changing the dismiss method for the re-ring. **Kept** the alarm's
own method: a re-ring is the same alarm, and the escape stays reachable (the
safety rule). Recorded for the owner in `OPEN_QUESTIONS.md`.

## Low

### L1 — The probe test must not ship

`integration_test/zz_ring_probe_test.dart` writes to the simulator's real
database and the real plugin. **Applied, then revised by SR1:** the probe is
deleted; a clean version that removes its own alarm is kept as
`integration_test/ring_lifecycle_test.dart` (run by hand), because it is the
only instrument that saw H2.

### L2 — Form row placement

After the dismiss card, extending the existing Phase 10 deviation; Save's
Tier A row is already off. Logged in the post-review.

## Invalid

### X1 — "Expire the window on a timer, so a silent sensor still re-rings"

**Invalid:** a silent stream is indistinguishable from a suspended app, and in
a suspended app the timer does not fire either; in a live app with a dead
sensor it would ring every morning on no evidence. The legacy's rule stands: a
missing sensor cannot invent an alarm — and the copy now says so (M4).

### X2 — "Show a banner after dismiss: keep moving"

**Invalid:** the user opted in on a card that explains the rule; a post-dismiss
demand to move is the kind of nagging copy `CLAUDE.md` rules out, and the
legacy deliberately showed nothing.

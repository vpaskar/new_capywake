# Phase 15 follow-up — the post-dismiss motion check

Owner decision, 2026-11-18: **build the check** (asked at the end of Phase 15:
"Settings' motion-check switch still does nothing — hide it or build the
check?"). Recorded against Phase 15, not as a new phase: the tracker pointer
stays at `16`, which is blocked on a separate owner decision.

Status: **revised after the pre-review** (§9 lists the deltas).

## 1. Objective

Make "Motion check after dismiss" true. When an alarm the user opted in is
stopped, CapyWake watches the accelerometer for 90 seconds; if the phone moved
in fewer than half of those seconds, the alarm rings **once more**. That second
ring never opens another check.

Ported design: `../capywake/lib/features/ringing/ringing_controller.dart`
(`_startMotionWindow`, `_reRing`, `_claimMotionReRing`), which the legacy
shipped with tests. The pure decision layer (`MotionCheckService`), the
persisted `AlarmOccurrence.isMotionReRing`, `Alarm.motionConfirmationEnabled`,
`UserSettings.motionConfirmationEnabled`, `AlarmEngine.ringNow` and all ten
locales' copy are already ported and unused.

## 2. Gates — all must pass

1. The alarm's own switch (`Alarm.motionConfirmationEnabled`, new Add/Edit card).
2. Settings' switch, read fresh from the repository at dismiss (it wins).
3. The ring is not itself a motion re-ring (`isMotionReRing` — persisted, so
   the bound holds across a restart).
4. The ring ended by **dismiss** — never by the escape (the user said they need
   quiet) and never by snooze.

## 3. The window

- Pure core: `MotionWindow` (`lib/core/motion/`) — opened at the dismiss
  instant, fed `(sample, now)`, answers `pending | satisfied | expired` using
  `MotionCheckService`'s buckets. 100% covered.
- Sample-driven, no timer (legacy): each reading carries the clock. **If the
  sensor stops delivering, the window never expires and no extra ring comes**
  — a missing sensor cannot invent an alarm. The copy must say so (§6).
- Closed on: satisfied, expired, the next ring of any alarm, controller
  dispose. One window at a time.

## 4. The re-ring

- Expired → `engine.ringNow(alarm)` with a claim `(alarmId, at)`; nothing is
  written before the platform is asked (a write re-runs the schedule).
- The ring event is matched to the claim (same alarm, within 5 minutes) and
  **re-opens this morning's occurrence** as `triggered` with
  `isMotionReRing: true`, so the ringing screen shows and stops it. Without
  this, `_onRinging` sees a terminal row and ignores the ring — the phone would
  ring with no screen to stop it (pre-review H1).
- `ringNow` failing → log, drop the claim, no retry, no claim of a ring.

## 5. The form

A **Motion check** card after the dismiss card in Add/Edit: the toggle, the
honest description, and — when on — the window note and, if Settings has it
off, the global-off note. The dismiss card already sits between Snooze and
Save (Phase 10 deviation), so this extends the same deviation; Save's Tier A
row is already off.

## 6. Copy (ported keys, two corrected)

- `alarmMotionCheckWindowNote`: "does not move within 90 seconds" is wrong — the
  check needs movement in 45 separate seconds. → "If the phone stays mostly
  still for the next {seconds} seconds, the alarm rings once more."
- `alarmMotionCheckGlobalOffNote`: "stops with a tap as usual" is wrong for a
  puzzle alarm. → "The motion check is off in Settings, so nothing happens
  after you stop this alarm."
- New `alarmMotionCheckLimitNote`: "If your phone pauses CapyWake in the
  background, the check stops quietly and no extra ring comes." (§3; the
  rule "never claim more reliable than the OS").

## 7. Tests (estimate +40 to +60)

Core window edges; controller: each gate, satisfied/expired, one re-ring ever
(also across a restart), escape and snooze open nothing, next ring cancels,
dispose cancels the sensor, ringNow failure, claim expiry and mismatch, the
re-ring re-opens the screen and its dismiss opens no window. Form card:
toggle, notes, global-off note, saved to the alarm. Every guard
mutation-checked.

## 8. Risks

- **The schedule re-run after a ring calls the plugin's `stopAll()`** (probe in
  progress, §9). If a ring's own write silences it, the re-ring inherits that.
- Background delivery of accelerometer readings on iOS is unverified (no
  device); the copy and §3 fail safe.

## 9. Pre-review and review deltas (as built)

- **H2 (pre-review) — a core fix, not only the check's:** every real alarm went
  silent 35 ms after it started (the ring's write re-ran the schedule, whose
  `stopAll()` silenced it). `rescheduleAll` now leaves ringing alarms alone.
- **M1** Both switches and the alarm are re-read before the re-ring.
- **M2–M4** Copy fixed; `alarmMotionCheckLimitNote` added (ten locales).
- **SR1-H1 — the claim is read from the database, not held in memory:** a
  ring of an opted-in alarm within 90 s + 5 min of its morning's dismissal,
  not already re-rung, re-opens that row. The in-memory claim lost the re-ring
  on a restart and, unclaimed, opened a row for the wrong morning.
- **SR1-M1** Any new ringing session closes the watch (a ring that started
  during a dismissal would otherwise run under an open window).
- **L1 revised:** the device probe is kept as
  `integration_test/ring_lifecycle_test.dart`, run by hand — the only check
  that can see the plugin silence a ring. It uses and removes its own alarm.

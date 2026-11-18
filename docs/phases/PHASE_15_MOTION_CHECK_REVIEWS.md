# Motion check — Self-reviews and full-project review

All findings applied; none invalid. Every guard was mutation-checked: removing
it fails at least one test, except `PlatformAlarmEngine.cancel` clearing the
ringing set, which calls the plugin directly and is covered by the device test
`integration_test/ring_lifecycle_test.dart` instead.

## Self-review #1

### SR1-H1 — The re-ring was lost on restart and landed on the wrong morning

The first build held the re-ring claim in memory, as the legacy did. A tested
restart between `ringNow` and its arrival lost it; the unclaimed ring at
07:01:30 then resolved to a *different* target than the 07:00 row and created
a new one, which could open a second window. **Applied:** the claim is read
from the database — a ring of an opted-in alarm within 90 s + 5 min of its
morning's dismissal, not already re-rung, re-opens that row
(`AlarmStatusService.motionReRing`, dismissed → triggered once). Tests: after
a restart, after another alarm rang, too late, and an alarm without the check.

### SR1-M1 — A ring that started during a dismissal ran under an open window

`dismiss` awaits Settings before opening the window; a second alarm's ring in
that gap left the window open while it rang, and its expiry could re-ring the
first alarm over the second. Reproduced by a test. **Applied:** any new
ringing session closes the watch. A `_current == null` check tried first was
redundant (mutation survived) and was removed.

### SR1-M2 — The probe file was going to be deleted, losing the only instrument

Pre-review L1 said delete it. But the defect it found (H2) is invisible to
every fake-engine test. **Applied:** rewritten as a clean device test that
rings, checks it keeps ringing, dismisses, checks tomorrow is armed, re-rings
through the real `ringNow`, checks the reopened screen, dismisses again.

## Self-review #2

### SR2-M1 — Re-ring of a puzzle alarm asks the puzzle again

Pre-review M5 kept it. Confirmed the escape stays reachable on the reopened
session (it is a normal ringing session). Logged for the owner.

### SR2-L1 — The reopened row's `triggeredAt` is the re-ring time

The first trigger time is overwritten. Stats reads dismissals, not triggers;
the missed rule then counts from the re-ring, which is right for a ring nobody
has answered yet. Kept, recorded here.

## Full-project review

### FP-H1 — Core: alarms went silent as they started (pre-review H2)

Fixed in `PlatformAlarmEngine.rescheduleAll` / `cancel` with
`AlarmPlanMapper.platformIdsToStop` / `plansToArm`. Present since the engine
landed; every phase's ringing tests used `FakeAlarmEngine`, whose
`rescheduleAll` never touched a ring. **Android shares the code and is
untested.**

### FP-M1 — The Settings row is now true

`settingsMotionCheckDescription` ("Lets alarms watch whether the phone moves
after you stop them. Off here means off for every alarm.") describes the
built behaviour; the owed-list entry is closed.

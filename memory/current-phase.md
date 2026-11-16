# Current phase

**Phase 05 — Alarm engine and reliability: done, 2026-11-16. `Current phase: 06`.**

The phase that made a saved alarm actually reach the platform. **1,279 tests**,
analyze clean, lib 97.46% / `lib/core` 99.49% / `lib/data` 88.95%, **405 ARB
keys × 10 locales**.

## What this phase actually found

### 1. Nothing armed anything, and the code to do it was already written

`AlarmScheduleCoordinator` — 275 lines of orchestration, fully tested in
Phase 02 — was **never constructed anywhere in `lib/`**. Four grep hits, all
doc comments. Alarms could be created, edited, enabled and deleted, and no
platform alarm was ever set.

So the phase wrote no scheduling logic, no DST handling, no 64-cap calculator
and no snooze math. It wrote three adapters and the wiring.

### 2. `initializeTimeZones()` was never called in `lib/` — Phase 03's defect, one layer down

The whole schedule engine is built on `package:timezone`. Every test loaded
the database itself (`setUpAll(tzdata.initializeTimeZones)`), and **nothing in
`lib/` ever did**. The suite could stay green forever while the app threw on
the path that arms alarms.

This is exactly Phase 03's `initializeDateFormatting` finding — tests
initialising what the app does not — and it is worse here, because a formatter
throwing is a visibly broken screen while this is an alarm that does not ring.

### 3. The plan said "reboot" and nothing in it survived a reboot

The draft re-synced "on app resume and on timezone change". **Neither fires
after a reboot** — the app is not running and there is no resume event.
Shipping that under a tracker row headed "reboot" is an overpromise, which
`CLAUDE.md` makes a High finding. Now stated per platform: Android persists
via `package:alarm`, iOS does not survive termination and the adapter never
claims it does.

### 4. Two defects in this phase's own code, found by self-review

- **`arm`'s idempotence guard could never match.** It keyed on the ring time
  *floored to now*, which for a past-due plan differs on every call — so the
  alarm was re-armed on every sync, and the stored key could collide with a
  genuine re-arm. The rule now lives in `AlarmPlanMapper.armKeyFor`, tested.
- **`Alarm.ringing` is a seeded `BehaviorSubject`**, so a late subscriber
  replays the current set and one ring was reported twice.

### 5. The coverage prediction was right about the mechanism, wrong in the good direction

The pre-review proved the legacy's 750 adapter lines would take `lib/data`
from 86.40% to under 70% against an 85% gate, and forced the **pure-mapper /
thin-shell split**. Measured result: **88.95%, up**. Registered 25–40 new
tests; measured **87**. Both restated rather than passed quietly.

## The simulator build — solved, and it was never ours

`flutter_tools` runs `lipo <binary> -verify_arch arm64 x86_64`; Xcode 27.2's
lipo refuses two architectures in one call. **A stock `flutter create` project
fails identically.** Use `flutter run`, never `flutter build ios --simulator`.

**Taps land on the iOS 27.0 runtime, not 16.4** — the rest of Phase 04's
symptom. But the iPhone 18 Pro is 402×874, not the mockup's 393×852, so
**Tier A capture stays on the iPhone 14 Pro**. Two devices, two jobs.

## What ran on a device, and what did not

Verified on iPhone 18 Pro (iOS 27.0): the app builds and launches with all
three plugins, and **`PlatformNotificationService` really reached iOS
UserNotifications** (device log: pending queried, 1 category registered).
Navigation by hand worked.

**Not verified:** the Save button did not respond while the `flutter run`
session was ending, so **no alarm was created through the UI and no arming was
watched interactively.** Recorded, not claimed. Android untested — no emulator.

## Next session — Phase 06, ringing and emergency stop

`AlarmEngine.ringingStream` is the surface it gets. **Never ship a puzzle
without a reachable emergency escape** — always a High finding. Nothing in
this phase constrains that escape. `AlarmFormat.timeParts` (Phase 04) is the
formatter the ringing screen wants.

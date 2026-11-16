# Phase 05 — Alarm engine and reliability

**Objective.** Make a saved alarm actually ring. Today an alarm can be created,
edited, enabled and deleted, and nothing arms it: `AlarmScheduleCoordinator` is
never constructed anywhere in `lib/`. This phase builds the platform adapters
behind the ported `lib/core/` abstractions, wires the coordinator to the
repository streams, and requests permissions just-in-time with the reason
shown.

Tracker scope: *"Platform scheduling, timezone/DST, reboot, iOS 64-cap,
just-in-time permissions, device test."*

## What already exists — read before planning anything

Phase 04's most expensive mistake was assuming `lib/core/` could not do
something it already did. The audit of what is ported, verified by reading the
files rather than the prose:

| Already built, tested, 99.41% covered | Lines |
|---|---|
| `core/schedule/alarm_schedule_service.dart` — DST, timezone, recurrence | 578 |
| `core/engine/alarm_schedule_coordinator.dart` — the whole orchestration | 275 |
| `core/engine/notification_schedule_calculator.dart` — **the iOS 64-cap** | 126 |
| `core/engine/alarm_engine.dart` — `AlarmEngine`, `RingingAlarm`, exception | 128 |
| `core/engine/notification_service.dart` — `NotificationService`, `PendingNotification` | 119 |
| `core/engine/fake_alarm_engine.dart`, `fake_notification_service.dart` | 2 files |
| `core/lifecycle/` — status FSM, snooze math incl. final alarm | 2 files |
| `core/permissions/permission_service.dart` + fake | 2 files |
| `core/reliability/` — checklist + honest copy | 2 files |

**So this phase writes no scheduling logic, no DST handling, no 64-cap
calculator and no snooze math.** Those exist and are tested. It writes the
three platform adapters and the wiring that drives them.

The repository already exposes everything the coordinator consumes:
`watchAlarms`, `watchFinishedOccurrences`, `watchSnoozedOccurrences`,
`upsertOccurrence`.

## Scope

### 1. Three platform adapters in `lib/data/`, each split in two

Per `CLAUDE.md`, only `lib/data/` may import the plugins.

**Pre-review F2 forced a structural change here.** The legacy's three adapters
are 750 lines; dropping that into `lib/data/` uncovered takes the tree from
86.40% to under 70% against an 85% gate, and all three ways out (lower the
gate, `// coverage:ignore`, a test that executes without asserting) are
banned. So every adapter is split:

| Pure mapper (tested) | Plugin shell (thin) | Plugin |
|---|---|---|
| `alarm_plan_mapper.dart` | `platform_alarm_engine.dart` | `alarm` |
| `notification_mapper.dart` | `platform_notification_service.dart` | `flutter_local_notifications` |
| `permission_mapper.dart` | `platform_permission_service.dart` | `permission_handler` |

Every **decision** lives in the mapper — what an `AlarmOccurrencePlan` becomes
as plugin settings, how a plugin error becomes `AlarmEngineException`, how a
plugin grant enum becomes `PermissionGrant`. The shell only calls the plugin
with what the mapper returned. Same split that makes
`NotificationScheduleCalculator` testable while the plugin is not.

The shells still add uncovered lines. **The phase reports the measured figure
and, if it lands under 85%, says so plainly** rather than reaching for a
banned move. It does not promise the number in advance.

`../capywake` has all three (413 + 226 + 111 lines) as a **read-only
reference** for the plugin API surface. They import Flutter so they are not
ported; they are read and re-written against this repo's abstractions.

### 2. Provider graph `lib/data/engine/engine_providers.dart`

Defaults to the **fakes** so the whole test suite stays headless and no test
touches a real alarm. `bootstrap()` overrides with the platform adapters on
device. This is the single test seam.

### 3. The coordinator driver

The piece that does not exist in either repo in the shape this one needs: a
provider that watches `alarmsStreamProvider`, `finishedOccurrencesStreamProvider`
and `snoozedOccurrencesStreamProvider` and calls `coordinator.sync(...)` on
every change. Without it, saving an alarm changes the database and nothing
else.

#### The arming race the driver must not lose

`alarmsStreamProvider`, `finishedOccurrencesStreamProvider` and
`snoozedOccurrencesStreamProvider` all start together and answer in whatever
order the database reaches them. Arming on the alarms stream alone means
arming from a picture with **no finished rows in it**.

If the app is launched inside a wake window the user has already dismissed,
that picture says the alarm is still due, `arm` floors its past soft start to
the clock, and **the phone goes off in their hand.** Android fires a past
`setAlarmClock` trigger immediately, so the milliseconds between the two
emissions are enough.

So `syncLatest` returns early while either occurrence stream is still loading.
An *errored* stream is not waited for: arming from an incomplete picture beats
leaving someone unwoken, the same trade the `?? const []` fallbacks make.

(Recorded here rather than in the code — the comment budget is 2 lines, and
this is exactly the "long rationale belongs in `docs/phases/`" case.)

### 4. Just-in-time permissions

Requested on **the first transition that results in at least one enabled
alarm**, whatever causes it (create-enabled, toggle-on, import), with the
reason shown — never on app start, and once per state rather than on every
toggle (pre-review F6). The capture fixture must not trigger a prompt or it
would block `tool/capture.sh`.

Denial degrades **honestly**: the UI must not say an alarm is set when it is
not.

### 5. Re-sync, and what "reboot" actually means

`sync()` re-runs on app resume and on timezone change, so a device that
crossed a timezone re-arms from the database rather than trusting what was
armed before.

**Reboot is not that, and pre-review F5 caught the plan implying it was.**
After a reboot the app is not running and there is no resume event:

- **Android** — `package:alarm` persists across boot; the manifest entries it
  needs are part of this phase, and the app re-syncs from the database on next
  start.
- **iOS** — a terminated app's ring does **not** survive, and the adapter must
  never claim it does (`AlarmEngine`'s own doc: "must NEVER claim termination
  survival on classic iOS"). The honest surface is the reliability copy.

"Reboot" is not ticked off as done on both platforms.

### 6. Timezone database initialisation

**Pre-review F1.** `initializeTimeZones()` is called nowhere in `lib/` — only
in test `setUpAll`s. `bootstrap()` initialises it and sets the local location
before the first frame, beside `initializeDateFormatting()`, with a test
asserting `lib/` does it. Same defect shape as Phase 03's
`initializeDateFormatting`, one layer down.

## Dependencies to add

Exactly three, matching the legacy's proven versions:

```yaml
alarm: ^5.3.0
flutter_local_notifications: ^21.0.0
permission_handler: ^12.0.1
```

`timezone: ^0.11.0` is already present and already matches.

## Exclusions

- **The ringing UI is Phase 06.** This phase makes the alarm fire and exposes
  `ringingStream`; it does not build the ringing screen, the puzzle, or the
  emergency escape. If engine work constrains Phase 06's escape, say so.
- The Reliability **checklist screen** is Phase 07 (`04_SETTINGS.png`). The
  service exists; this phase does not draw it.
- No sleep/health path (Phase 07/08).
- No Android verification of any kind — there is no emulator on this machine.

## Tests

Mirrors `lib/` under `test/`. The adapters are thin translation layers over
plugins that cannot run headless, so the testable surface is: the provider
graph defaults, the driver's sync-on-change behaviour, permission gating, and
the honest-degradation path.

Registered expectations, to be restated if measurement disagrees:

- **Baseline: 1,189 tests.**
- Expected new: **25–40**.
- Expected ARB keys: **399 + 3–8** (permission rationale, denial copy).

## Acceptance criteria

1. Saving an enabled alarm arms a platform alarm — verified **on device**.
2. The full validation block passes, including all three coverage gates.
3. `lib/core/` and `lib/features/` import no plugin; only `lib/data/` does.
4. No claim of Android testing anywhere.
5. No overpromising copy: nothing claims more reliable than the OS clock app,
   nothing implies silent-mode or DND bypass.

## Device test — now possible

Phase 04 could not run one. **Phase 05 found why and it is not this app:**
`flutter_tools` runs `lipo <binary> -verify_arch arm64 x86_64`, and Xcode
27.2's `lipo` rejects multiple architectures in one `-verify_arch`
("requires exactly one input file"). A stock `flutter create` project fails
identically. The binary is correct; the verifier is broken.

The working path, proven this session:

- `flutter run -d <udid>` builds, installs and runs (single-arch, so
  `-verify_arch` gets one argument — which is also why `flutter drive` and
  `tool/capture.sh` always worked).
- **Taps reach the app only on the iOS 27.0 runtime.** On the iPhone 14 Pro
  (iOS 16.4) every tap reports success and nothing happens — exactly Phase
  04's symptom. The iPhone 18 Pro (iOS 27.0) navigates correctly.

**Cost:** the iPhone 18 Pro is 402×874 pt, not the mockup's 393×852. So
interaction testing runs on iOS 27 and **Tier A capture stays on the iPhone 14
Pro** via `tool/capture.sh`. Two devices, two jobs. Tier A is never measured on
the 18 Pro.

## Risks

| Risk | Mitigation |
|---|---|
| Three plugins change the iOS pod install and the shipped binary | `check_bundle_size.dart` cannot see pods; state the impact rather than assume none |
| `alarm` 5.x needs iOS background modes + Android permissions in manifests | Manifest edits are part of this phase, not a follow-up |
| Adapters are largely untestable headless, dragging `lib/data` coverage below its 86.40% gate | Keep adapters thin; put every decision in testable code. **Measure before claiming.** |
| Plugin init on app start is a plugin call in `bootstrap()`, which tests run | Override in tests; verify the headless suite never initialises a plugin |
| iOS cannot survive app termination | Say so honestly in copy; never claim otherwise |

## Rollback

Single commit on `main`. Revert restores Phase 04's state; the three
dependencies come out with it.

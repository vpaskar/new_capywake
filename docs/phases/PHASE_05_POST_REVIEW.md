# Phase 05 — post-review

Alarm engine and reliability. The phase that makes a saved alarm actually
reach the platform, and the first with a working device path since Phase 03.

## Measured against what was registered

| Registered in the pre-review | Measured | Restated |
|---|---|---|
| Baseline 1,189 tests | **1,189** | — |
| Expected **25–40** new | **+90** (1,279) | **Yes — 2× the estimate.** F2's pure/shell split made far more testable than predicted |
| Expected **3–8** new ARB keys | **6** (399 → 405) | Inside the range |
| `lib/data` ≥85%, at risk of falling | **88.95%**, *up* from 86.40% | **Yes — the opposite of the predicted direction** |
| `lib/core` ≥95% | **99.49%**, up from 99.41% | — |
| `lib` ≥85% | **97.46%** | — |

Dependencies resolved, recorded rather than copied from the legacy's numbers:
**`alarm 5.15.0`** (not the legacy's 5.3.0), `flutter_local_notifications
21.0.0`, `permission_handler 12.0.3`, `timezone 0.11.2`. 24 transitive
packages added. No existing constraint was loosened.

## The simulator build: diagnosed, and it was never ours

Phase 04 left `flutter build ios --simulator` failing with an opaque
`Uncategorized (Xcode): Exited with status code 255` and asked Phase 05 to fix
the path. **The cause is a bug in `flutter_tools` against Xcode 27.2, not in
CapyWake.**

`thinFramework` (`build_system/targets/darwin.dart:83`) runs:

```
lipo <binary> -verify_arch arm64 x86_64
```

Xcode 27.2's `lipo` answers `-verify_arch requires exactly one input file` and
exits 1, so the tool reports the framework "does not contain architectures"
while printing a `lipo -info` line showing it contains both. Each arch
verifies individually. **A stock `flutter create` project fails identically**,
which is the test that settles whose defect it is.

`flutter run` works because `ONLY_ACTIVE_ARCH=YES` yields a single arch, so
`-verify_arch` gets one argument — the same reason `flutter drive` and
`tool/capture.sh` have worked throughout.

**Second half of the Phase 04 symptom, also explained:** taps reach the app on
the **iOS 27.0** runtime and not on **iOS 16.4**. Phase 04 tried the iPhone 14
Pro (16.4) and concluded taps did not work; on the iPhone 18 Pro (27.0) they
navigate correctly. The runtime was the variable.

**The cost, stated:** the iPhone 18 Pro is 402×874 pt, not the mockup's
393×852. So **interaction testing runs on iOS 27 and Tier A capture stays on
the iPhone 14 Pro** via `tool/capture.sh`. Two devices, two jobs. Tier A is
never measured on the 18 Pro.

## What ran on a device, and what did not

Honest scope, per `CLAUDE.md`'s rule against claiming a device test that did
not happen:

**Verified on the iPhone 18 Pro (iOS 27.0):**

- The app builds and launches with all three plugins (`flutter run`, exit 0,
  43 s Xcode build, "Errored: 0").
- `PlatformNotificationService.initialize()` **really ran against iOS
  UserNotifications**, proved by the device log at 21:51:03–04: it queried
  pending requests ("Got 0 pending notification"), registered **1 notification
  category**, and read delivered notifications. The adapter is wired to the
  real framework, not merely compiled.
- Navigation by hand: Home → Alarms → Add Alarm.

**Not verified by hand:** the Save button did not respond to taps while the
`flutter run` session was ending, so **no alarm was created through the UI and
no arming was observed interactively.** That is recorded rather than
papered over.

**Android: not tested. There is no emulator on this machine.**

## Findings

### Pre-review — 4 High, 4 Medium, 2 Low, all applied

The two most expensive:

**F1 (High) — `initializeTimeZones()` was never called in `lib/`.** The whole
schedule engine is built on `package:timezone`, and every passing test loaded
the database itself in `setUpAll`. The suite could stay green forever while
the app threw on the path that arms alarms. **This is Phase 03's
`initializeDateFormatting` defect exactly, one layer down** — same mechanism,
same shape, one phase later. Fixed in `bootstrap()`.

**F5 (High) — the plan said "reboot" and nothing in it survived a reboot.**
§5 proposed re-syncing "on app resume and on timezone change", neither of
which happens after a reboot: the app is not running and there is no resume
event. Shipping that under a tracker heading reading "reboot" would have been
an **overpromise**, which `CLAUDE.md` makes a High finding. Now stated per
platform — Android persists via `package:alarm`, iOS does not survive
termination and the adapter never claims it does.

**F2 (High)** predicted the adapters would break the `lib/data` gate (+50
uncovered lines → 78.85% against an 85% floor) and forced the pure-mapper /
thin-shell split. It was right about the mechanism and **wrong about the
outcome in the good direction**: coverage rose to 88.95%.

### Self-review #1 — 2 defects in my own code

**S1 (High).** `arm`'s idempotence guard keyed on
`ringAtFor(plan, now: _now())`, which for a past-due plan returns *now* — a
different value on every call. The guard could never match, so a past-due
alarm would be **re-armed on every sync**, and the stored key was a floored
value that could collide with a genuine re-arm. Fixed by keying on the plan's
own instant, extracted to `AlarmPlanMapper.armKeyFor` so the rule is tested
rather than buried in an untestable shell.

**S2 (Medium).** `Alarm.ringing` is a **seeded `BehaviorSubject`**, so a late
subscriber replays the current set and one ring would be reported twice. Now
de-duplicated against the previously reported set.

**S3 (Medium).** The ring notification interpolated `alarm.label`, whose
default is `''` — the body would have read "` is ringing.`". The list tile
already had a precedent for empty labels; the notification now falls back to
the alarm title.

### Self-review #2 — architecture rules verified, not assumed

- **Only `lib/data/` imports a plugin.** Three `lib/core/` files matched a
  naive grep; all three were doc-comment mentions, verified by reading their
  import blocks.
- **`lib/core/` imports no Flutter** — still true.
- **No fake on the production path** — `main.dart` and `lib/app/` contain no
  `Fake*`.
- **No new copy overpromises.** Three strings matched an overpromise scan;
  all three are inherited *disclaimers* that say what CapyWake does **not** do
  (iOS silent mode, DND, what each phone cannot guarantee).

### Full-project review

**P-A (High) — the capture harness now builds a real coordinator.** `AppShell`
watches `alarmScheduleCoordinatorProvider` for the life of the app, which is
what keeps alarms armed; `integration_test/capture_test.dart` builds the app
through its own `UncontrolledProviderScope` with **no engine overrides**, so
every capture now constructs a coordinator and starts its database listeners.

Two consequences, judged separately:

1. **Safety: fine.** With no overrides the graph falls through to
   `FakeAlarmEngine` / `FakeNotificationService`, so a capture arms nothing
   real. This is the pre-review F7 seam doing its job.
2. **Liveness: checked, because the coordinator schedules a
   `Timer(Duration.zero, …)` and the capture harness runs `pumpAndSettle`.**
   A pending timer is exactly what makes `pumpAndSettle` hang.

**P-B (Low) — `AppShell` changed from `StatelessWidget` to
`ConsumerStatefulWidget`** and `router.dart` constructs it unchanged; the
router tests pass.

## Honest gaps, named rather than closed

- **The interactive arming test did not happen** (see above). The evidence
  that arming works is 87 new tests against the real provider graph plus the
  device log proving the notification adapter reaches iOS.
- **`check_bundle_size.dart` cannot see what these plugins add.** It measures
  `assets/` trees only and reports 10517 KB of 11082 KB (95%) — unchanged,
  while the shipped binary certainly grew by three native plugins. Pre-review
  F10 predicted this and it is stated rather than gated, because inventing a
  binary-size gate for platforms this phase cannot measure is how the 188.4
  default got written.
- **`LocalLocationResolver` identifies a zone by behaviour, not by name.** No
  plugin in this phase supplies the IANA name, so zones indistinguishable from
  the clock alone (same offsets all year) resolve by a preference list. It
  returns `null` rather than guessing when nothing matches, and the caller
  falls back to UTC.
- **Phase 06 constraint.** `AlarmEngine.ringingStream` is the only surface the
  ringing screen gets from this phase; the emergency escape is Phase 06's and
  nothing here constrains it. `AlarmFormat.timeParts` (Phase 04) is still the
  right formatter for it.

## Files added

```
lib/data/engine/alarm_plan_mapper.dart            pure, tested
lib/data/engine/notification_mapper.dart          pure, tested
lib/data/engine/local_location_resolver.dart      pure, tested
lib/data/permissions/permission_mapper.dart       pure, tested
lib/data/permissions/alarm_permission_gate.dart   pure, tested
lib/data/engine/platform_alarm_engine.dart        plugin shell
lib/data/engine/platform_notification_service.dart plugin shell
lib/data/permissions/platform_permission_service.dart plugin shell
lib/data/engine/engine_providers.dart             provider graph + driver
lib/data/engine/platform_engine_overrides.dart    production scope
integration_test/engine_device_test.dart          device evidence
```

## Comment budget

Bit **13 times** — every new file. All trimmed by hand rather than
auto-trimmed (the tool cuts mid-sentence), and the long arming-race rationale
moved into `PHASE_05_PLAN.md` where it belongs. **No file was added to the
baseline.**

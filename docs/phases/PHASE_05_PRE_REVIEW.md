# Phase 05 — pre-review (adversarial, before any code)

Written against `PHASE_05_PLAN.md` by reading the files it describes rather
than its prose. Phase 04's three High findings all came from that habit; two of
the three below are the same shape.

Every finding is **applied** or **invalid with a reason**. Nothing is deferred.

---

## F1 — `initializeTimeZones()` is never called in `lib/`

**High. Applied.**

`AlarmScheduleService` and `AlarmScheduleCoordinator` are built on
`package:timezone`. Both take a `tz.Location` by injection, so `lib/core/` is
clean and its 99.41% coverage is real. But **nothing in `lib/` ever loads the
timezone database**:

```
grep -rn "initializeTimeZones" lib/   →  no match
```

Every passing test supplies it itself — `test/core/engine/alarm_schedule_coordinator_test.dart:88`
is `setUpAll(tzdata.initializeTimeZones)`, then uses `tz.UTC`. So the suite can
stay green forever while the app throws the first time it resolves a real
location.

**This is exactly Phase 03's `initializeDateFormatting` defect.** There, 912
ported formatter tests passed while the app would have thrown on the first
screen that rendered a time, because the tests initialised what the app did
not. Same mechanism, same layer, one phase later.

It matters more here: a formatter throwing is a visibly broken screen, whereas
this throws on the path that arms alarms, which the user cannot see until the
alarm does not ring.

**Applied:** `bootstrap()` initialises the tz database and sets the local
location before the first frame, beside `initializeDateFormatting()`. A test
asserts `lib/` initialises it rather than relying on a test's `setUpAll`.

---

## F2 — The adapters will break the `lib/data` ≥85% coverage gate

**High. Applied — the plan's mitigation was not one.**

The plan says "keep adapters thin" and "measure before claiming". That is a
hope, not a design. The arithmetic, against Phase 04's measured 451/522:

| New uncovered lines in `lib/data` | Resulting figure |
|---|---|
| +50 | **78.85%** |
| +100 | **72.51%** |
| +150 | **67.11%** |

The gate is **85%**. The legacy's three adapters are **413 + 226 + 111 = 750
lines**. Even one of them lands this well under the floor.

The three wrong ways out are all explicitly banned: lowering the gate,
`// coverage:ignore`, and a meaningless test that executes lines without
asserting (`CLAUDE.md`, and `memory/capywake-data-coverage-explained.md`).

**Applied — the structural answer.** Every adapter is split:

- a **pure, fully-tested mapper** holding each decision — which plugin
  settings an `AlarmOccurrencePlan` becomes, how a plugin error becomes
  `AlarmEngineException`, how a plugin grant enum becomes `PermissionGrant`;
- a **thin plugin shell** that only calls the plugin with what the mapper
  returned, containing no branch worth testing.

This is the same split that makes `NotificationScheduleCalculator` testable
while the notification plugin is not. The pre-registered counts below assume
it.

**The honest part:** the shells still add uncovered lines. The phase states the
measured figure and, if it lands under 85%, says so plainly rather than
reaching for any of the three banned moves. It does not promise in advance
that the number will be fine.

---

## F3 — "The coordinator is never constructed" needs checking, not asserting

**Medium. Verified, claim stands.**

The plan's central premise is that nothing arms an alarm today. Asserted
premises are how Phase 04 lost time, so it was checked:

```
grep -rn "AlarmScheduleCoordinator" lib/app lib/data lib/features
  → 4 hits, all doc comments in providers.dart and the repository
```

No construction, no `sync()` call. The premise holds: alarms are written to
the database and nothing arms them.

---

## F4 — Three plugins is a dependency claim the plan did not verify

**Medium. Applied.**

The plan lists `alarm ^5.3.0`, `flutter_local_notifications ^21.0.0`,
`permission_handler ^12.0.1` because the legacy uses them. The legacy resolved
them against **its own** constraint set; this repo has a different one
(`flutter_riverpod 3.x`, `go_router 17.x`, `drift 2.32`), and `flutter pub get`
already reports 29 packages held back by existing constraints.

**Applied:** resolve the three before writing adapter code, and record the
versions actually resolved. If one cannot resolve, the phase says so rather
than loosening an unrelated constraint to force it.

---

## F5 — The plan says "reboot" but nothing in it survives a reboot

**High. Applied.**

Tracker scope names reboot. The plan's §5 says `sync()` re-runs "on app resume
and on timezone change" — **neither of which happens after a reboot.** After a
reboot the app is not running; there is no resume event. On Android the alarm
clock is cleared and only a `BOOT_COMPLETED` receiver re-arms it; on iOS a
terminated app's scheduled ring does not survive at all.

Shipping §5 as written and calling it "reboot handled" would be an
**overpromise**, which `CLAUDE.md` classifies as a High finding.

**Applied, in two parts:**

1. **Android:** `package:alarm` provides boot-persistence; the manifest entries
   it needs are part of this phase, and the app re-syncs from the database on
   next start.
2. **iOS:** it is **not** survivable on classic iOS, and the adapter must never
   claim it is — `AlarmEngine`'s own doc says "the adapter must NEVER claim
   termination survival on classic iOS". The honest surface is the reliability
   copy, not a silent pretence.

The phase states what each platform actually does. "Reboot" is not ticked off
as done on both.

---

## F6 — Just-in-time permission has no defined trigger

**Medium. Applied.**

"Requested at the moment the user enables their first alarm" is ambiguous
across four real paths: creating an alarm already enabled, toggling an existing
one on, the seeded alarms in the capture fixture, and an import. Left
unspecified, the implementation picks one and the gap shows up on device.

**Applied:** the trigger is **the first transition that results in at least one
enabled alarm**, whatever causes it, and it is requested once per state — never
re-prompted on every toggle. The capture fixture must not trigger a prompt,
or it would block `tool/capture.sh`.

---

## F7 — `bootstrap()` runs in tests, and plugin init in it would break the suite

**Medium. Applied.**

`main()` calls `bootstrap()`; adding plugin initialisation there puts a plugin
call on a path tests execute. The suite is headless and must never touch a real
alarm or notification.

**Applied:** plugin initialisation lives in the **override** that production
installs, not in `bootstrap()` itself. The provider defaults stay fakes.
Asserted by a test that the default graph constructs no platform adapter.

---

## F8 — The device test must not become a claim

**High. Applied.**

`CLAUDE.md`: never mark anything "tested on device" that was not run on one,
and never mark Android tested. This phase has a working iOS path for the first
time, which makes the opposite failure easy — overstating what it proved.

Verified this session, and the limits are part of the record:

- `flutter run -d <udid>` installs and runs. `flutter build ios --simulator`
  does **not**, and the cause is a broken `lipo -verify_arch` call in
  `flutter_tools` against Xcode 27.2 — **a stock `flutter create` project fails
  identically**, so it is not this app's defect and not worth further chasing.
- **Taps land only on the iOS 27.0 runtime.** On iOS 16.4 every tap reports
  success and nothing happens.

**Applied:** the device test states the device, the runtime, and what was
observed. Android is not tested and is not claimed. An alarm that was not
watched to fire is not written up as one that fired.

---

## F9 — Test-count registration

**Low. Applied.**

Phase 04 registered ~1,192 and measured 1,189, and restated it. Same
discipline here.

- **Baseline: 1,189.**
- Expected new: **25–40**, on F2's split — mappers are testable, shells are
  not.
- Expected ARB keys: **399 + 3–8**.

Measurement is restated, never quietly passed.

---

## F10 — `check_bundle_size.dart` cannot see what these plugins add

**Low. Applied as a statement, not a gate change.**

The three plugins ship native iOS/Android code and change the shipped binary.
`check_bundle_size.dart` measures `assets/` trees only and will stay green
while the real app grows — the same shape as the Phase 02 finding where it
reported 83% while the payload had reached 10 MB.

**Applied:** the post-review states the plugins' effect on the binary as
unmeasured by any gate, rather than letting a green bundle check imply nothing
changed. No gate is invented for screens and platforms that do not exist yet.

---

## Summary

| ID | Severity | Outcome |
|---|---|---|
| F1 | High | Applied — `initializeTimeZones` in `bootstrap()`, asserted |
| F2 | High | Applied — adapters split pure/shell; figure reported honestly |
| F3 | Medium | Verified — premise holds |
| F4 | Medium | Applied — resolve and record real versions |
| F5 | High | Applied — reboot stated per platform; no overpromise |
| F6 | Medium | Applied — trigger defined precisely |
| F7 | Medium | Applied — plugin init in the override, not `bootstrap()` |
| F8 | High | Applied — device claim bounded to what ran |
| F9 | Low | Applied — counts registered |
| F10 | Low | Applied — stated, not gated |

**4 High, 4 Medium, 2 Low. All applied; one verified. None deferred.**

The two findings that would have cost the most are F1 (a repeat of Phase 03's
defect one layer down, invisible to a green suite) and F5 (shipping an
overpromise under a tracker heading that says "reboot").

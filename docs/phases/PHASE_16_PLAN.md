# Phase 16 — Capy Step Quest

Status: **revised after the pre-review** (§11 lists the deltas).

Reference: `reference/01_REFERENCES/games/posters/01_STEP_QUEST.png` ("Walk
20 steps to wake Capy!", a backpack capy on a path, "8 / 20 steps" over a
bar). Posters are bezel-wrapped storyboards: **Tier A binds nothing** here
(as Phases 11–15).

## 0. Owner decision (2026-11-18) — what unblocked this phase

Step Quest was `blocked` since Phase 00 because counting steps adds a
store-visible permission. Asked at the start of this session, the owner
answered: *"make the best choice … I need the most accurate one no matter the
difficulty and should work for as much phones as possible, maybe multiple
depending on phone."*

So the phase counts steps with **the best source each phone has**, in order:

| Tier | Source | When | Accuracy |
|---|---|---|---|
| 1 | The OS step sensor — Android `TYPE_STEP_DETECTOR` (else `TYPE_STEP_COUNTER`), iOS `CMPedometer` | The phone has one **and** the user allowed it | Best: the OS's own trained detector, usually on a coprocessor |
| 2 | CapyWake's own step detector on the accelerometer (`sensors_plus`, already shipped) | No step sensor, access refused, or the sensor stays silent | Good for walking; less exact |
| 3 | A "Take a step" button | **Always on screen** | Exact by definition; the safety fallback |

Permission is **just-in-time with the reason shown**, and **never while an
alarm rings** (an OS dialog over the ringing screen covers Snooze and the
escape). A ring uses whatever is already allowed.

## 1. Why not the `pedometer` package (read from its 4.2.0 source)

- Android's per-step stream (`TYPE_STEP_DETECTOR`) is reduced in Dart to
  `walking`/`stopped` with a 2 s timer (`_androidStream`) — the step events
  themselves are thrown away.
- Its count stream is `TYPE_STEP_COUNTER`, registered without a report latency,
  so the OS may batch it.
- iOS counts from the last reboot; Android has no authorization check at all.

A ~150-line channel of our own gives per-step events on Android with
`maxReportLatencyUs = 0` (no batching), a count since the game started on
iOS, and an honest availability + authorization answer on both. **No new
dependency.** `permission_handler` (already a dependency) asks for Android's
`ACTIVITY_RECOGNITION`; iOS authorization is CoreMotion's own.

## 2. Platform

- **Android:** `<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>`.
  Runtime-requested on API 29+; `permission_handler` treats it as granted
  below Q (plugin source: `PermissionUtils` returns no names pre-Q). Channel in
  `MainActivity.configureFlutterEngine`. Compiled with `flutter build apk
  --debug` if the toolchain allows; **never run** (no emulator, no device).
- **iOS:** `CMPedometer` needs `NSMotionUsageDescription` — already present for
  the motion games; reworded to name step counting. Authorization is
  `CMPedometer.authorizationStatus()`; a request is a one-minute
  `queryPedometerData`, which shows the system prompt. Channel registered in
  `AppDelegate.didInitializeImplicitFlutterEngine`. The simulator has no
  pedometer: it must report `unavailable` and fall to tier 2/3 — that path
  **is** run.

## 3. Core — `lib/core/motion/` (pure, 100%)

- **`StepSensor`** (interface): `access()`, `requestAccess()`,
  `openSettings()`, `Stream<int> steps` (new steps since listening began, each
  event ≥ 1). `StepAccess { ready, needsPermission, permanentlyDenied,
  unavailable }`.
- **`FakeStepSensor`**: settable access, `emit(n)`, listen/cancel counters.
- **`MotionSample.timestamp`** (optional `DateTime`): `sensors_plus` events
  carry one; step timing needs it. Missing timestamps assume the 20 ms
  sampling period.
- **`StepDetector`** (accelerometer, tier 2): gravity removed by a slow EMA,
  light smoothing, peak with hysteresis, 300–2000 ms between steps, a peak over
  a jolt ceiling is a shake (rejected, rhythm reset), and **four steps in
  rhythm before any counts** — then the four are released together. Constants
  named, untested on hardware.
- **`StepTally`** (fusion): picks the source in force (`sensor` when access is
  ready and the stream is open, else `motion`), adds taps always, ignores
  accelerometer steps while the sensor is in force — **unless the sensor has
  delivered nothing while the accelerometer has counted 16 steps**, which
  demotes to `motion` for the rest of the round and keeps those 16. Once the
  sensor has delivered, it is trusted.

## 4. Round — `lib/core/games/step_quest.dart` (pure, 100%)

Target 20 / 30 / 40 (easy matches the poster's 20). Milestones of five steps
for the header pips. A 15 s pause stalls (struggle), no step lost.
`GameChallenge.motion(fallback: touch)`.

## 5. View — `lib/features/games/step_quest_view.dart`

`CapyCard`: `GameHeader` (milestones) → a fixed-height field: the meadow,
Capy with a backpack (`game.capy.hiking`, the poster's pose) walking from the
start edge to the end edge as steps land, a bob per step, and the big
"8 of 20 steps" count → a one-line source caption ("Counting with your step
sensor" / "Counting from motion") → the "Take a step" game button → a
`GameOutcomeLine` (stall).

Motion stops under `disableAnimations` or a screen reader (Capy jumps, never
glides). RTL walks the other way, image mirrored. Card ≤ 424 pt; fits 320 pt.
Never a `CapyButton`.

## 6. Access prompt — `lib/features/games/step_access_prompt.dart`

One widget, two hosts: a card above the game in **practice**, and a bottom
sheet when the user **switches Step Quest on** in a wake pool (Add/Edit, the
chooser). Reason shown first, then "Allow step counting" / "Not now";
`permanentlyDenied` shows "Open Settings". Never in the ringing host.

## 7. Wiring

- `GameLaunch.steps` (`StepSensor`); both hosts read `stepSensorProvider`
  (silent `FakeStepSensor` with `unavailable` by default,
  `platformStepOverride()` in `platformEngineScope`).
- Catalogue: `step_quest` → `playable`, `screenReaderSolvable: true` (the
  button + a live region), new `countsSteps: true`. `GameBlockedReason.stepCount`
  removed — nothing is blocked on it now.
- Registry +1. `capture_test.dart` gains the game; `_win` taps the button.

## 8. Strings (estimate +11 keys × 10 locales)

Instruction, step button, stall line, the count (plural), two source captions,
and the prompt's title/body/allow/not-now/settings/denied body.

## 9. Tests (estimate +90)

Core: detector (threshold, rhythm gate, shake rejection, gap reset, bounce,
missing timestamps), tally (source choice, demotion at 16 not 15, no demotion
after a delivery, taps always), round. Data: the channel and the access
mapper over mocked channels; `Info.plist` and the manifest carry their keys.
Views: hardware steps, accelerometer steps, demotion, taps, stall at 15 s not
before, subscriptions cancelled on win and dispose, resubscribe on a new
sensor, still mode, screen reader solves it, RTL, 2× text, 320 pt, dark.
Prompt: practice card, pool sheet on enabling, never on a ring. Host: real
`RingingScreen`, clock guard, escape at tolerance 0, single win.

## 10. Acceptance, risks, rollback

Acceptance: playable on a ring and in practice; the simulator run reaches the
game with the pedometer unavailable and does not crash; the button finishes it;
gates green; a capture recorded.

Risks: no step sensor or accelerometer was ever exercised (simulator only) —
thresholds named and logged; the Android channel is compile-only; the store
listing gains Motion & Fitness / Physical activity — owner note. Rollback: flip
the entry back to `blocked`, drop the registry line, the channel and the
manifest permission.

## 11. Pre-review deltas

- **H1** The view listens to `steps` only after `access()` returned `ready`.
- **H2** An error or done on the step stream demotes to `motion` at once.
- **H3 / M2** The round starts in `motion`; `ready` promotes to `sensor`
  (steps kept); demotion is final. Access is re-read on app resume and when
  the prompt resolves.
- **H4** Any throw from the channel maps to `unavailable`.
- **M1** The accelerometer subscription is cancelled on the sensor's first
  delivery.
- **M3** iOS `restricted` → `unavailable`.
- **M4** The pool toggle applies first; the sheet only follows an off → on
  change with `needsPermission` / `permanentlyDenied`.
- **M5** A host test proves no prompt and no `requestAccess()` on a ring.
- **M6** iOS events are dispatched to the main queue.
- **M7** Field height set from a measured card; clock guard runs.
- **L1–L7** as recorded in `PHASE_16_PRE_REVIEW.md` (L2 invalid).

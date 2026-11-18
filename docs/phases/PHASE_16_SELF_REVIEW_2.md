# Phase 16 — Self-review #2 (unanchored)

Run by a reviewer given the code and the project rules, **not** the author's
reasoning or the first review (the Phase 15 method: it found the defect the
author's own passes had reasoned past). Six findings, each read against the
code; all six applied, each with a test proven to fail without the fix.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| R1 | Medium | `PlatformStepSensor.steps` called `receiveBroadcastStream()` on every read. The event channel keeps one handler, so a second Step Quest view (practice under a ringing alarm — `RingingHost` stacks the ring over the app) replaced the first's handler, and the first's cancel then stopped the native sensor under the ring. The fake shared one controller, so no test could see it. | **Applied.** One cached stream for all listeners (`late final`); the native cancel runs when the last listener leaves. Platform test: two listeners, one cancels, the other still hears and the native side was listened once. |
| R2 | Low | iOS: a pedometer update queued before `stopUpdates()` could land after the next `onListen` reset `delivered`, replaying the old session's total as fresh steps. | **Applied.** A session number is captured per listen; stale updates are dropped. (Swift; compiled by the capture build, not unit-testable here.) |
| R3 | Low | Android counter fallback: a counter that reports only after a run of steps turned that whole run into the baseline. | **Applied.** `SensorManager.flush` right after registering the counter delivers the baseline at once. (Compiled; never run.) |
| R4 | Low | Android: an engine torn down while listening left the `SensorManager` listener registered on the application context. | **Applied.** `MainActivity.cleanUpFlutterEngine` disposes the channel. (Compiled; never run.) |
| R5 | Low | Practice: "Open Settings" re-read access the instant Settings opened, so the card stayed stale on return; the test set the new access *before* the tap and so passed without any re-read on return. | **Applied.** The practice screen re-reads on resume; the sheet closes when Settings opens. The test now changes access after the tap and resumes. |
| R6 | Low | The view re-read access over the channel on every rebuild while not counting by sensor — on a ring, once per step. | **Applied.** Re-read only when the sensor changes, on resume, or when the sensor announces a request answered (`StepSensor.accessChanges`); never after a demotion. Tests count `access()` calls. |

The reviewer's "consider demoting a proven sensor that falls silent" is
**invalid as a separate change**: its only cause found was R1, now removed;
a proven sensor that stops is a stream error or done, which already demotes.

## Mutation checks

5 of 5 new guards fail without their code (shared stream, practice resume,
no re-read on rebuild, no re-read after demotion, re-read on `accessChanges`).

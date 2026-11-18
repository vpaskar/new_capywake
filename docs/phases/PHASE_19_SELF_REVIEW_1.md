# Phase 19 — Self-review #1

Read every changed file against the plan, the pre-review and the memory files.

## Medium

**SR1-M1 — The step rationale still says "nothing leaves your phone".** True of
the steps, but on Android the same app process carries ML Kit's diagnostics,
and the sentence reads as device-wide — the exact claim F3 retired for the
camera. *Applied:* "your steps never leave your phone", ten locales; the
privacy-claims test covers `stepAccessBody` too.

**SR1-M2 — `next.md` says `AlarmEngine.ringNow` is called by nothing.** The
motion check's re-ring calls it (`ringing_controller.dart:322`). *Applied:*
the line is removed from "Owed by nobody".

## Low

**SR1-L1 — `whileOnScreen` never starts if practice opens while the app is
`inactive`** (a call banner, Control Center): `onShow` fires only out of
`hidden`. *Applied:* `onResume` starts it too (idempotent), and `inactive`
counts as on screen at listen time.

**SR1-L2 — The probe is not in `next.md`.** *Applied:* listed with the manual
ring check, with how to drive it (`scratchpad` script reproduced in the
post-review).

## Checked, no finding

- Zone channel: one platform listener (`static final`), one handler per
  channel; iOS resets the cached zone before reading; Android unregisters on
  cancel and engine clean-up, null-guarded.
- `UNUserNotificationCenter.current().delegate = self`: `FlutterAppDelegate`
  forwards to plugins; both plugins' guides ask for it.
- The coordinator is the same instance across a zone change (tested,
  mutation-checked); the platform `rescheduleAll` skips ringing ids whatever
  triggered it.
- `didChangeLocales` removal: its comment claimed it covered zone changes; no
  test depended on it; the zone now has its own path.

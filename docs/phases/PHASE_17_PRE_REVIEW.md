# Phase 17 — Pre-review (adversarial, before any code)

Reviewed: `PHASE_17_PLAN.md` draft, `mobile_scanner` 7.5.0 source (controller,
widget, error codes, Android manifest), `permission_handler_apple` 9.6.5's SPM
macro handling, `WakeChallengeSelector`, `RingingHost._challengeFor`, the
`Singletons` table, Phase 16's step-access code.

## High

**H1 — The camera must never start on its own during a ring.** A live camera
opening the moment an alarm rings, phone on a nightstand facing the ceiling or
the sleeper, is a privacy surprise and a battery cost. **The scanner widget is
not built until "Scan QR" is tapped** (`autoStart` only inside that widget),
and it is torn down on win, dispose and app pause (`useAppLifecycleState`).
Host test: a ring shows no scanner until the tap. *Applied.*

**H2 — Readiness read at ring time must not race.** If `qrHuntReadyProvider`
is still loading when the ring picks, QR must not be picked (it might be
unfinishable). **Loading or error = not ready**, and the provider is watched
by `RingingHost` from app start so it is warm; a refresh keeps the previous
value. *Applied; test with a never-completing future.*

**H3 — Camera revoked after the check, or held by another app.** The scanner
then fails at start. **A start failure is a struggle with a plain line ("The
camera did not start."), "Scan QR" retries, and each failed retry is another
struggle** — the escape rises at the user's tolerance and is always reachable.
No state in which only scanning can end the ring. *Applied.*

**H4 — The checkpoint's raw value can be a secret.** Wi-Fi QR codes carry the
password; a URL can carry a token. **Store a digest, never the raw value**
(FNV-1a 64-bit hex + length, pure Dart — equality is all the game needs), and
never show the value on screen or in logs. *Applied.*

## Medium

**M1 — A held wrong code is reported every frame.** Dedupe: a wrong code
counts once until a different code (or the checkpoint) is seen. *Applied in
the round, tested.*

**M2 — One permission abstraction, not two copies.** Step access and camera
access are the same shape. **`DeviceAccess` (renamed from `StepAccess`) and a
`DevicePermission` interface** that `StepSensor` and `CameraAccess` both
implement; `StepAccessPrompt` becomes `DeviceAccessPrompt` taking its copy.
*Applied.*

**M3 — `permission_handler_apple` under SPM derives macros itself; relying on
that for the camera is brittle.** iOS camera status/request go through
`capywake/camera` (Swift, 25 lines). Android uses `permission_handler`.
*Applied.*

**M4 — Plugin fence.** Only `lib/data/camera/platform_code_scanner.dart`
imports `mobile_scanner`; a test reads every `lib/` file. *Applied.*

**M5 — Card height.** A useful viewfinder (~150 pt) plus header, button and
outcome line is near 424 pt. **Measured per locale; the field shrinks before
the card grows.** *Applied.*

**M6 — `NSCameraUsageDescription` is shown in an OS dialog** — all ten
`InfoPlist.strings`, as Phase 16 did for motion. *Applied.*

**M7 — Switching QR on in a pool with no checkpoint would silently never ring
QR.** The sheet after the switch says so and opens setup. *Applied.*

## Low

**L1 — `GameBlockedReason.camera` becomes a lie, and no blocked game remains.**
Remove `GameBlockedReason` and `blockedReason`; keep
`GameAvailability.blocked` (generic sheet copy) for a future game; the tests'
synthetic entry needs no reason. *Applied.*

**L2 — Practice says "Nothing you do changes an alarm"; saving a checkpoint
changes a shared setting.** The setup copy says the checkpoint is used by every
alarm with QR Treasure Hunt. *Applied.*

**L3 — `autoTorch` lights the torch in the dark.** It runs only after the
user's tap, in the room they walked to. *Invalid as a defect — kept.*

**L4 — A user may pick a code they keep by the bed.** Their choice; the setup
copy suggests another room. *Invalid as a defect.*

**L5 — Bundled ML Kit size.** Logged with the alternative (unbundled, needs
Play Services). *Applied (owner note).*

**L6 — Tracker, architecture plan and catalogue doc comments still say
"blocked".** Updated in the same commit. *Applied.*

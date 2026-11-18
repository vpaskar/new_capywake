# Phase 17 — QR Treasure Hunt

Status: **revised after the pre-review** (§9 lists the deltas).

Reference: `reference/01_REFERENCES/games/posters/02_QR_TREASURE_HUNT.png` —
"Find your morning checkpoint", a camera view of a QR taped in a bathroom,
"Scan QR". Idea: find and scan a code; it all but forces you out of the
bedroom. Tier A binds nothing (storyboard poster), as Phases 11–16.

## 0. Owner decision (2026-11-18)

"Add the camera" — answered to *"QR Treasure Hunt needs the camera and its
permission. Should Phase 17 add them?"*. That unblocks the last game.

## 1. The shape

1. **Set a checkpoint once.** In the game's practice screen (and from the pool
   sheet), the user scans any QR code or barcode at the place they want to walk
   to — a printed QR on the bathroom mirror, the coffee jar's barcode. Its raw
   value is stored app-wide (one checkpoint, replaceable).
2. **On a ring**, the card says "Find your morning checkpoint", shows a
   viewfinder, and "Scan QR" starts the camera. The checkpoint's code wins;
   any other code is a struggle ("That's not your checkpoint"), counted once
   per different code.
3. **QR joins a ring only when it can run:** a checkpoint is saved **and**
   camera access is already granted. Otherwise the ring picks from the rest of
   the pool, and an empty pool is a puzzle (existing rule). Never a camera
   prompt on a ring.

## 2. Dependency and platform

- **`mobile_scanner: ^7.5.0`** (published 2026-11-01). Android CameraX + ML
  Kit **bundled** (works without Google Play Services — "as many phones as
  possible"; costs ~2–3 MB per ABI, logged for the owner), iOS AVFoundation/
  Vision. Only `lib/data/camera/` imports it (a test fails otherwise).
- **Android:** `CAMERA` + `uses-feature camera required=false` come from the
  plugin's manifest; status and request via `permission_handler`.
- **iOS:** `NSCameraUsageDescription` in `Info.plist` and all ten
  `InfoPlist.strings`. Status and request via our own channel
  (`capywake/camera`: `AVCaptureDevice.authorizationStatus` /
  `requestAccess`) — `permission_handler_apple` needs per-permission macros we
  do not want to manage.
- The simulator has no camera: the scanner reports an error there; the real
  path is proven by a channel test, the game by a fake scanner.

## 3. Core (pure, 100%)

- `CameraAccess` (interface, like `StepSensor`): `access()`,
  `requestAccess()`, `openSettings()`, `accessChanges`; reuses `StepAccess`'s
  shape as `DeviceAccess { ready, needsPermission, permanentlyDenied,
  unavailable }` — `StepAccess` is renamed to it.
- `QrCheckpoint` model (`value`, `savedAt`), JSON for the singleton.
- `QrHuntRound`: target 1; `scan(code)` → win on match, else a struggle with
  `wrongCode` (the same wrong code twice in a row counts once);
  `cameraFailed()` → a struggle with `noCamera`. `GameChallenge.touch` — the
  game needs no motion; it needs sight (`screenReaderSolvable: false`).

## 4. Data

- Repository: `getQrCheckpoint`, `watchQrCheckpoint`, `saveQrCheckpoint`,
  `clearQrCheckpoint` on the `Singletons` table (new key; no schema change).
- `PlatformCameraAccess` (`lib/data/camera/`), `CameraAccessMapper`.
- `PlatformCodeScanner` — the only file importing `mobile_scanner`: a widget
  that runs a `MobileScannerController` (back camera, all formats,
  `autoTorch`), reports each detected raw value and any start error.
- Providers: `cameraAccessProvider`, `codeScannerProvider` (fakes by default,
  platform overrides in `platformEngineScope`), `qrHuntReadyProvider`
  (checkpoint saved && camera ready), refreshed on resume.

## 5. Features

- `QrTreasureHuntView` (`GameRingingView`): header, viewfinder field (scene
  art behind, corner brackets, the live camera only after "Scan QR"), the
  button (a game control, never a `CapyButton`), `GameOutcomeLine`. Brackets
  pulse unless still mode. Card ≤ 424 pt; fits 320 pt.
- `QrCheckpointSetup`: the reason, the camera prompt (just-in-time), scan to
  save, "Checkpoint saved", "Change checkpoint".
- Practice screen for QR: setup first if no checkpoint, else the game plus
  "Change checkpoint".
- Pool: switching QR on when not ready opens a sheet → "Set a checkpoint"
  (opens practice). The switch is saved first.
- Ring host: `isLaunchable` also asks `qrHuntReadyProvider`.

## 6. Strings (≈ 18 keys × 10)

Instruction, scan button, wrong code, camera failed, the setup copy (title,
body, scan to save, saved, change), the camera prompt (title, body, allow,
denied), the pool sheet (title, body, action).

## 7. Tests (≈ 110)

Core round + model; mapper; repository round-trip; channel over a mocked
channel; manifest/plist/strings; fence (only `lib/data/camera/` imports the
plugin); view (start, match, wrong once, camera error, still mode, 320 pt,
424 pt × 10 locales, 2× text, dark, RTL); setup (prompt order, save, change);
practice; pool sheet; host (ready → QR rings, not ready → never QR, never a
camera prompt or a scanner start without a tap, win dismisses once, escape at
tolerance 0, clock guard).

## 8. Acceptance, risks, rollback

Acceptance: playable on a ring and in practice with a fake scanner; never in a
ring it cannot finish; gates green; captures recorded; the iOS channel answers
on the simulator.

Risks: no camera was ever run (simulator has none, no Android device); the
bundled ML Kit adds size; a lost checkpoint leaves the escape (always there).
Rollback: flip the entry back to `blocked`, drop the registry line, the
dependency and the channel.

## 9. Pre-review deltas

- **H1** No camera until "Scan QR" is tapped; torn down on win, dispose, pause.
- **H2** Readiness loading or failed = not ready; provider warm from app start.
- **H3** A camera start failure is a struggle with a plain line; retry; each
  failure counts.
- **H4** The checkpoint is stored as an FNV-1a 64 digest + length; never shown.
- **M1** A wrong code counts once until a different code is seen.
- **M2** `DeviceAccess` + `DevicePermission`; `DeviceAccessPrompt` takes copy.
- **M3** iOS camera access over `capywake/camera`; Android `permission_handler`.
- **M4–M7, L1–L6** as in `PHASE_17_PRE_REVIEW.md` (L3, L4 invalid).

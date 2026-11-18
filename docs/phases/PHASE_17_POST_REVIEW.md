# Phase 17 — Post-review: QR Treasure Hunt

**Done 2026-11-18.** Unblocked by the owner: "Add the camera". All ten games
are now playable; no catalogue entry is blocked.

## What shipped

- **A checkpoint, set once.** Practice explains it, asks for the camera (reason
  first), and saves one scan as a **salted digest** — never the code, which can
  be a Wi-Fi password. App-wide; "Change checkpoint" (with Cancel) replaces it.
- **The game.** "Scan QR" turns the camera on; the checkpoint wins; any other
  code (once per look) or a camera that will not start is a struggle that
  raises the escape. The camera stops on a win, a tap, leaving the app, or an
  alarm ringing above practice.
- **It rings only when it can be finished:** checkpoint saved and camera
  allowed. Otherwise the pool's other members ring, and an empty pool is a
  puzzle. On a cold start the pick waits up to 2 s for readiness (escape
  visible). **Never a camera prompt on a ring**, and the scanner is never built
  without a grant, so the plugin cannot prompt either.
- **`mobile_scanner` 7.5.0**, fenced to `lib/data/camera/platform_code_scanner.dart`;
  iOS camera permission over our own `capywake/camera` channel; Android via
  `permission_handler`. `NSCameraUsageDescription` in all ten languages.
- **One permission abstraction:** `DeviceAccess` / `DevicePermission` shared by
  the step sensor and the camera; `DeviceAccessPrompt` takes its copy.

## Reviews

Pre-review 4H/7M/6L (L3, L4 invalid). Self-review #1: 6 (5 applied, 1
invalid). Self-review #2 (unanchored subagent): 10 applied — the Mediums were
a hidden practice camera holding the one camera session under a ring (and
able to overwrite the checkpoint), and a cold-start pick on an unloaded
readiness. Full-project: 5 (all applied or recorded). **25 guards
mutation-checked**, every one fails without its code; three were first on
trust and were fixed.

## Evidence

- `docs/visual/ringing_qr_treasure_hunt/`, `win_qr_treasure_hunt/` — captured on
  the iPhone 14 Pro simulator via `tool/capture.sh`, verified 1179×2556 (the
  win frame is taken mid-entrance, as for every game).
- `integration_test/camera_channel_test.dart` on the same simulator: the Swift
  camera channel is registered and answers.
- Release APK (arm64 target) builds: 53.6 MB; declares `CAMERA`, camera
  feature not required. Bundled ML Kit: 4.9 MB native (arm64) + 0.9 MB models
  per installed ABI.

## Tier A / Tier B

Tier A binds nothing (storyboard poster). Tier B: **G42** — no checkpoint
scene, no peeking Capy; the detective Capy on a plain field, reported in
session.

## Not verified

**No code was scanned by a real camera** — the simulator has none and Android
has no device here. The plugin's start/permission failure path is tested over
its channel.

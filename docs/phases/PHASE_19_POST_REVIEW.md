# Phase 19 — Post-review

## What shipped

1. **iOS alarms ring in the background.** `alarm` 5.15's iOS setup had never
   been done (background modes `audio` + `fetch`, the plugin's BGTask id,
   `registerBackgroundTasks()`), so iOS suspended the app and an alarm rang only
   when the app came back. Simulator probe, same test before and after:
   **46.8 s late before (the moment the app was reopened), 248 ms after**
   (`docs/release/evidence/`). Every earlier ring test ran in the foreground.
2. **The zone is read, and followed.** The device's IANA name over a native
   channel (fingerprint fallback); re-read on resume and on the platform's
   change notice; a change re-runs the schedule on the same coordinator.
3. **Store-facing honesty.** Android's scanner (ML Kit) sends Google
   diagnostics, so "nothing leaves your phone" went from the camera and step
   rationales; the wake window promises the phone's volume, not "full";
   restart and silent mode stated without promising; the plugin's English
   "You killed the app" notice is now localized and calm. Ten locales each.
4. **Release configuration.** Interim icon on every size (G48), launch screens
   in the app's light and dark background, iPhone + portrait only, two unused
   Android permissions removed, release signing from `key.properties`,
   `1.0.0+1`, export compliance answered.
5. **Practice stops its sensors off screen** — the app now stays alive in the
   background, so a practice round left open would have kept reading.
6. **Drafts for the owner** in `docs/release/`: listing (every field counted),
   privacy policy + both stores' answer keys, release checklist with a device
   matrix.

## Release artifacts (2026-11-18, before the review fixes; re-built after)

| Artifact | Result |
|---|---|
| `flutter build ios --release --no-codesign` | pass, `Runner.app` 35 MB |
| `flutter build appbundle --release` | pass, 83.6 MB AAB |
| `flutter build apk --release --split-per-abi` | arm64 41.5 MB, armv7 37.5 MB, x86_64 43.9 MB |
| Merged Android permissions | `READ_EXTERNAL_STORAGE` and `ACCESS_NOTIFICATION_POLICY` gone; `INTERNET` / `ACCESS_NETWORK_STATE` remain (ML Kit) |
| Signing path | AAB signed with a throwaway scratchpad key through `key.properties`, verified with `jarsigner`, key deleted (see the session log) |

## Captures

`tool/capture.sh`: all screens, light and dark, verified. Pixel diff against
`HEAD`: 14 files changed, every change inside a seeded content area (another
puzzle, impostor round or win art); no frame, block or layout moved, so no
Tier A delta and no new Tier B substitution. The launch screen and the app
icon are not in the capture path; the icon is checked by
`test/platform/app_icon_test.dart` and by eye.

## Reviews

Pre-review 20 findings; self-review #1 4; self-review #2 (unanchored) 15;
full-project 5. All applied, except: L1 (`CupertinoIcons`) invalid — no
Cupertino widget in `lib/`; P2 (Portuguese variant) and P1 (the ring-test
failure) reported to the owner with the evidence, because neither has a fix
that can be chosen or proven here.

## Mutation checks

Each guard removed, its test watched fail: coordinator reads the zone (watch →
fails), coordinator listens to it, practice sensors gated (2), wrapper
equality, inactive start, done forwarding, production zone override,
reported-name trust.

## Not verified — say it plainly

- **Nothing ran on Android.** No emulator, no device.
- **No real iPhone.** The background ring is proven on the simulator only.
- The zone-change notice was never fired on either platform.
- `ring_lifecycle_test` failed twice, then passed 9 times; cause not found
  (full-project review P1). Release checklist row 13a.

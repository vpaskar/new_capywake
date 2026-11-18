# Phase 19 — Release QA

## Objective

Make the build a release candidate: find what would stop it ringing, get it
rejected, or make it say something untrue — on the real release artifacts, not
the debug app the earlier phases ran — fix it, and write the drafts the owner
needs to press the store buttons. **Drafts only** (`CLAUDE.md`): no console is
touched, nothing is uploaded, nothing is submitted.

## What the audit found before any code (2026-11-18)

Read against `alarm` 5.15.0's install guide, the merged release manifest
(`aapt2 dump permissions` of `flutter build apk --release`), the Flutter
template defaults still in `ios/` and `android/`, and Google's ML Kit data
disclosure page.

| # | Finding | Evidence | Sev |
|---|---|---|---|
| F1 | **iOS cannot ring in the background.** No `UIBackgroundModes` (`audio`, `fetch`), no `BGTaskSchedulerPermittedIdentifiers`, no `SwiftAlarmPlugin.registerBackgroundTasks()`. iOS suspends a backgrounded app, so the plugin's silent audio session never keeps it alive — an alarm only rings with the app open. `reliabilitySummaryIos` ("rings reliably while the app is open or in the background") is untrue today. `PHASE_05_PLAN.md` §risks put these edits in Phase 05; they never landed, and every ring test ran in the foreground. | `help/INSTALL-IOS.md`; `ios/Runner/Info.plist`; `AppDelegate.swift`; legacy plist has them | High |
| F2 | **Both app icons are the stock Flutter logo**, and the package has no app icon to replace it. | `Icon-App-1024x1024@1x.png`; `find reference -iname '*icon*'` | High |
| F3 | **"Nothing leaves your phone" is false on Android for the camera.** Bundled ML Kit (via `mobile_scanner`) sends diagnostics and usage analytics — device/app info, installation identifiers, performance metrics — to Google; it is why the release APK declares `INTERNET` and `ACCESS_NETWORK_STATE` (`com.google.android.datatransport`). No image is sent. `cameraAccessBody` shows on both platforms. | manifest-merger report; developers.google.com/ml-kit/android-data-disclosure | High |
| F4 | **A timezone change while the app is alive is never applied.** `platformEngineScope` resolves the zone once at launch; resume and `didChangeLocales` re-run the schedule against that frozen zone (the shell's comment says a locale change covers a zone change — it does not). With F1 fixed the app stays alive across a flight, so a 07:00 alarm set in Berlin rings at 01:00 in New York. | `platform_engine_overrides.dart:24`; `shell.dart:40` | High |
| F5 | The zone itself is guessed from four UTC offsets, not read. Two zones with equal offsets at the probes but different transition dates pick by a hard-coded preference list. | `local_location_resolver.dart` | Medium |
| F6 | `alarm` merges `READ_EXTERNAL_STORAGE` and `ACCESS_NOTIFICATION_POLICY`; neither is used by its code nor by ours (assets only, no DND access). Both are store-visible. | `grep` of the plugin's Kotlin | Medium |
| F7 | Release builds sign with the **debug key** (template TODO); Play rejects a debug-signed bundle. | `build.gradle.kts` | Medium |
| F8 | Version `0.1.0` with no build number. | `pubspec.yaml` | Medium |
| F9 | iPad is a target (`TARGETED_DEVICE_FAMILY = "1,2"`) and iPhone allows landscape. Nothing was ever measured on iPad or in landscape; an iPad target needs iPad screenshots and iPad review. | `project.pbxproj`, `Info.plist` | Medium |
| F10 | Both launch screens are white: the night user Phase 18 protected from a flash still gets one before the first frame. | `LaunchScreen.storyboard`, `launch_background.xml` | Medium |
| F11 | `CFBundleName` is `capywake` (lowercase). | `Info.plist` | Low |
| F12 | The build warns `CupertinoIcons` is referenced but not bundled. | build log | Low |

## Scope

1. **F1** — `UIBackgroundModes` `audio` + `fetch`, `BGTaskSchedulerPermittedIdentifiers`
   `com.gdelataillade.fetch`, `registerBackgroundTasks()` and the
   notification-centre delegate in `AppDelegate` (the plugin guide's steps).
   A gate test reads `Info.plist` and `AppDelegate.swift`. **Evidence:** a
   simulator probe — arm an alarm, send the app home, let it fire — run before
   and after.
2. **F2** — report as **G48** + `ART_REQUESTS.md` #17, in session. Interim:
   `tool/make_app_icon.dart` writes every iOS and Android size (adaptive
   foreground/background included; 1024 without alpha) from one supplied
   mascot on the brand cream. **Tier B, declared:** placement of supplied art,
   no art drawn. A test pins the set: every `Contents.json` file present at its
   size, no alpha at 1024, not the Flutter logo. Re-running the tool on the
   owner's art replaces it.
3. **F3** — `cameraAccessBody` says what is true on both platforms (the picture
   never leaves the phone), 10 locales. The Play Data safety key in
   `docs/release/PRIVACY.md` declares ML Kit's diagnostics. Owner question:
   strip the telemetry (needs a device test) or keep and disclose.
4. **F4 + F5** — a native `capywake/timezone` channel (iOS
   `TimeZone.current` after `resetSystemTimeZone`, Android `ZoneId`) gives
   the IANA name; the resolver stays as the fallback. The zone is held by a
   provider; the schedule location reads it. It is re-read on resume and on
   the platform's zone-change notification (iOS
   `NSSystemTimeZoneDidChange`, Android `ACTION_TIMEZONE_CHANGED`, one event
   channel, one handler), and a change re-runs the schedule.
5. **F6** — `tools:node="remove"` for both; a test reads the manifest; the
   release APK's permission dump is the evidence.
6. **F7** — `signingConfigs.release` from `android/key.properties` (already
   git-ignored) with `key.properties.example`; without the file the build
   falls back to debug signing and says so.
7. **F8** — `1.0.0+1`.
8. **F9** — iPhone only, portrait only on both platforms. Owner question.
9. **F10** — launch background = `cream` / `darkCream`, light and dark, on both
   platforms (Android 12+ splash included).
10. **F11** — `CFBundleName` `CapyWake`.
11. **F12** — confirm no Cupertino widget is reachable from `lib/`.
12. **Regression on the release candidate:** every gate; `tool/capture.sh` for
    every screen, light and dark, diffed against the Phase 18 captures;
    `ring_lifecycle_test` on the iPhone 14 Pro simulator; `flutter build ios
    --release --no-codesign`, `flutter build appbundle --release`; sizes
    recorded per ABI.
13. **Store drafts** in `docs/release/`: `RELEASE_CHECKLIST.md` (versioning,
    signing, permission declarations, review notes, the manual device matrix
    for this app), `PRIVACY.md` (policy text, App Privacy and Data safety
    answer keys), `STORE_LISTING.md` (English listing within every limit,
    screenshot plan). Price, IAP and other locales are the owner's.

## Revised after the pre-review

- **H1:** sensors live in practice stop when the app leaves `resumed`; a ring
  keeps its sensors.
- **H2:** the schedule reads the zone when it computes; a mid-ring zone change
  stops nothing (tested); `ring_lifecycle_test` re-run.
- **H3:** `integration_test/background_ring_probe_test.dart`, run before and
  after F1.
- **H4:** the icon tool refuses an undersized source; otherwise placeholder,
  said in session.
- **H5:** camera rationale only claims what both platforms do.
- **M1–M3:** alias fallback, `TimeZone.getDefault()`, `RECEIVER_NOT_EXPORTED`.
- **M6:** post-release migration rule in `CLAUDE.md` and the checklist.
- **M9:** `ITSAppUsesNonExemptEncryption = false`.
- **M10, M11:** debug-surface grep; pixel diff of every capture against `HEAD`.
- **L2:** drop the iPad orientation key. **L3:** no monochrome icon, requested.

## Exclusions

No console, upload, TestFlight distribution or submission. No release key
created (a throwaway scratchpad keystore proves the signing path, then is
deleted). Nothing marked tested on Android or on a device. No art drawn. No
Health integration. No price decision. No new dependency.

## Tests

`test/platform/` (new): iOS setup, Android manifest, app icon set. Zone
provider, channel reader and refresh in `test/data/engine/`. Shell: resume and
zone-change refresh re-run the schedule with the new zone. Copy test: the
camera rationale makes no device-wide claim. Every guard mutation-checked.

## Acceptance

All gates green; F1–F12 applied or invalid with a reason; background-ring
probe recorded before and after; release builds succeed with sizes and the
permission list recorded; captures show no unexplained change; drafts written;
Android and device rows marked untested.

## Risks

- `fetch` and `audio` background modes draw App Review questions for alarm
  apps — the checklist carries the review note.
- The zone-change event cannot be produced on this machine (the simulator
  follows the host's zone); its Dart side is tested, its native side is not.
- The interim icon is a judgement on the owner's brand; it is reversible by
  one tool run.

## Rollback

One commit; `git revert`.

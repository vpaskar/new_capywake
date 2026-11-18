# CapyWake — release checklist

The owner presses every store button (`CLAUDE.md`: drafts only). Pairs with
`STORE_LISTING.md` and `PRIVACY.md`. Written in Phase 19 against the release
artifacts; re-check each row after a dependency change.

## Blocking before a public release

1. **App icon is interim** (G48): supplied alarm-clock art on cream, no
   capybara. A Capy icon at ≥ 1024 px (and a monochrome glyph for Android 13
   themed icons) → `dart run tool/make_app_icon.dart <file>` regenerates every
   size.
2. **No Android device or emulator has ever run this app.** Every Android row
   below is unverified.
3. **Release signing**: create the upload key (below); Play rejects a
   debug-signed bundle.
4. **Owner decisions** in `docs/sessions/OPEN_QUESTIONS.md` (Phase 19): price,
   ML Kit diagnostics, iPhone-only, URLs.
5. **From the first public build, schema changes need a migration** from every
   shipped version, tested from a populated v1 database.
   `test/data/migration_origin_test.dart` is deleted on purpose by the first
   phase that adds one.

## Versioning

`pubspec.yaml` `version: 1.0.0+1`. Bump `+N` on **every** upload to either
store; bump the name per release. iOS `CFBundleShortVersionString` /
`CFBundleVersion` and Android `versionName` / `versionCode` derive from it.

## Build and sign

**Android** — app id `com.capywake.capywake` (permanent after first publish).

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

macOS's `/usr/bin/keytool` needs a Java runtime this machine lacks; Android
Studio's bundled one works. Copy `android/key.properties.example` to `android/key.properties` and fill it
(both git-ignored). Prefer Play App Signing. Without the file the build warns
and signs with the debug key.

```bash
flutter build appbundle --release
```

**iOS** — bundle id `com.capywake.capywake`, iPhone only, portrait. Set the
team in Xcode (automatic signing). Background modes `audio` + `fetch` are
required for the alarm and must survive any Xcode edit
(`test/platform/ios_platform_setup_test.dart` fails otherwise). No Critical
Alerts entitlement, no push.

```bash
flutter build ipa --release
```

Upload with Xcode Organizer or Transporter; TestFlight distribution is the
owner's.

## Store declarations

- **Play:** exact-alarm, full-screen-intent and media-playback foreground
  service declarations (texts in `PRIVACY.md`); Data safety answer key in
  `PRIVACY.md`; target audience 18+ or "not for children".
- **Play lint:** the activity is portrait-only; Android 16 ignores that on
  large screens (≥ 600 dp), and Play shows a large-screen advisory. Phones are
  the target.
- **App Store:** App Privacy "Data Not Collected"; export compliance is
  answered in `Info.plist` (`ITSAppUsesNonExemptEncryption = false`); review
  notes in `STORE_LISTING.md` explain the background modes.

## Automated gate

The `CLAUDE.md` validation list, all green, plus:

```bash
flutter build ios --release --no-codesign
```

```bash
flutter build appbundle --release
```

## Manual device matrix

Run on a **release** build on a real iPhone and a real Android phone. Record
build, device, OS, pass/fail per row. Rows 1–4, 9, 13 and 13a block a release.

| # | Scenario | Android | iOS |
|---|---|---|---|
| 1 | Alarm, app in foreground | Rings on time | Rings on time |
| 2 | Alarm, app in background, phone locked | Rings (exact alarm + foreground service) | Rings — **proven on the simulator only** (`integration_test/background_ring_probe_test.dart`, 248 ms late vs 46.8 s before Phase 19) |
| 3 | App swiped away | Rings | Does **not** ring; copy says so |
| 4 | Phone reboot | Re-armed | Not re-armed until opened; `reliabilityCautionTerminationIos` and the listing say so |
| 5 | Notification permission denied, then granted | Checklist flags, guides | Same |
| 6 | Silent switch / Focus | Alarm stream rings | The plugin plays as media (`.playback`), which the silent switch does not mute; copy promises nothing either way. Tester records what happens |
| 7 | Battery optimisation on (Xiaomi, Samsung) | Checklist flags it | n/a |
| 8 | Travel: change the zone with the app alive | Next alarm moves to the new zone without opening the app | Same — the native notice was never fired on this machine |
| 8a | Travel with the app not running | Armed alarms keep their old instant until CapyWake opens (the listing says to open it once) | Same |
| 9 | Each puzzle and game: wrong answer keeps ringing, solving stops, **Stop without solving** always stops | Same | Same |
| 10 | Shake DJ / Tilt Maze / Step Quest on a real accelerometer and pedometer | Thresholds felt as fair | Same |
| 11 | QR Treasure Hunt with a real camera and printed code | Scans; ML Kit diagnostics only | Scans (Vision) |
| 12 | Motion check: phone left still rings once more, carried away does not | Same | Same |
| 13 | Snooze rings again; final snooze shows no Snooze | Same | Same, app alive |
| 13a | **Dismiss re-arms the next ring** — dismiss a repeating alarm, then check the next one is set (Home card) | Same | Same; on the simulator `ring_lifecycle_test` failed this twice in Phase 19 and was not reproduced in 9 runs since — run it 5× before each release |
| 14 | Practice a motion game, send the app home | Sensor stops (battery) | Same |
| 15 | Light and dark, all ten locales, Arabic RTL | No overflow | Same |
| 16 | Fresh install → onboarding → first alarm rings | Same | Same |
| 17 | Launch at night in dark mode | No white flash | No white flash |

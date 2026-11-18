# CapyWake — privacy (draft for the owner)

Drafts only. Nothing here has been entered in App Store Connect or Play
Console. Every answer below is tied to what the release build contains, not to
intent; re-check it when a dependency changes.

## What the build does, verified 2026-11-18 (Phase 19)

| Fact | Evidence |
|---|---|
| No account, no backend, no sync, no ads, no analytics written by CapyWake | `lib/` has no HTTP client; `pubspec.yaml` has no network, ads or analytics package |
| Everything the user creates stays in a local SQLite file | `lib/data/database/app_database.dart` (Drift, app-support directory) |
| The QR checkpoint is stored as a salted digest, never the code | Phase 17, `lib/core/games/` |
| **iOS build: no network use at all** | `mobile_scanner` uses Apple Vision on iOS (no ML Kit in `darwin/`); no other plugin opens a connection |
| **Android build: ML Kit diagnostics** | Bundled ML Kit barcode scanning (via `mobile_scanner`) sends device and app information, installation identifiers and performance metrics to Google for diagnostics and usage analytics; **no image is sent**. It is why the release manifest has `INTERNET` and `ACCESS_NETWORK_STATE` (`com.google.android.datatransport`). Source: developers.google.com/ml-kit/android-data-disclosure |
| Sleep data is never read in this release | The Sleep segment says "not available yet"; `package:health` is not a dependency |

**Owner question (open):** keep ML Kit's diagnostics and disclose them, or
strip them (remove `INTERNET` from the merged manifest and test the scanner on
a real Android phone). `docs/sessions/OPEN_QUESTIONS.md`.

## Privacy policy text (to host at a public URL)

> **CapyWake privacy policy** — effective [date]
>
> CapyWake is an alarm clock. It has no account and no server. The alarms,
> settings, wake history and game choices you create are stored only on your
> phone and are deleted when you delete the app. CapyWake does not sell,
> share or upload them.
>
> **Permissions.** CapyWake asks for each permission only when you turn on the
> feature that needs it, and explains why first:
> - *Notifications and exact alarms* — to ring at the time you set.
> - *Camera* (QR Treasure Hunt only) — to read your checkpoint code while you
>   scan it. No picture is saved or sent anywhere.
> - *Motion & Fitness / physical activity* (Step Quest) — to count steps while
>   you play. Shake DJ and Tilt Maze read motion without a permission. Steps and
>   motion stay on your phone.
>
> **Android code scanner.** On Android, the code scanner is Google's ML Kit,
> which sends Google technical information — device and app details,
> installation identifiers and performance figures — to help Google fix and
> improve it. It does not send camera images. Google's notice:
> https://developers.google.com/ml-kit/android-data-disclosure
>
> **Children.** CapyWake is not directed at children and collects no personal
> data from anyone; see the Android code scanner note above.
>
> **Contact.** [owner's support email]

## App Store Connect — App Privacy

- Data collection: **"No, we do not collect data from this app."**
- Tracking: none. No `NSUserTrackingUsageDescription`; no IDFA.
- Privacy policy URL: [owner].
- Valid only while the iOS build has no network use — re-check after any new
  dependency.

## Play Console — Data safety (answer key)

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any required user data types? | **Yes** | ML Kit (Android only) |
| Is all collected data encrypted in transit? | Yes | ML Kit sends over HTTPS |
| Do you provide a way to request deletion? | No account exists; uninstalling deletes all local data. Answer per Play's current wording |
| **Device or other IDs** | Collected, not shared; purpose **Analytics** | ML Kit installation identifier |
| **App info and performance → Diagnostics** | Collected, not shared; purpose **Analytics** | ML Kit performance metrics |
| Photos and videos | **Not collected** | Frames are processed on device; none is sent |
| Fitness info → Physical activity | **Not collected** | Steps are read on device and never leave it |
| Personal info, location, messages, contacts, financial, health | Not collected | — |

"Not shared" follows Play's definition: data sent to a service provider (here
Google, processing for the app's own SDK) is not sharing. If the owner strips
ML Kit's diagnostics, every row becomes "not collected".

## Permission declarations (Play)

| Permission | Declaration |
|---|---|
| `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM` | Alarm clock app: the core function is ringing at a user-set time |
| `USE_FULL_SCREEN_INTENT` | Alarm clock: the ringing screen over the lock screen |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Plays the alarm sound until the user stops it |
| `ACTIVITY_RECOGNITION` | Step Quest counts steps while the user plays; asked only when they pick it |
| `CAMERA` (feature not required) | QR Treasure Hunt reads the user's own checkpoint code |
| `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `VIBRATE` | Ring, re-arm after reboot, vibrate |
| `INTERNET`, `ACCESS_NETWORK_STATE` | Not used by CapyWake; merged by ML Kit (see above) |

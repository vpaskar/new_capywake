# CapyWake — store listing (English draft)

Drafts only: nothing is entered in either console. Counts are computed from
`listing_fields.json` and `listing_description.txt` (the source of truth for
copy-paste). Other locales: not drafted — the app ships ten, the listing one.

Checked against the store rules and `CLAUDE.md`: no competitor names, no price,
no "best"/"#1", no "never oversleep", no sleep-stage or "smart alarm" claim,
no silent-mode bypass, the emergency stop and the iOS limits stated, only
features in this build (no sleep data — the Sleep segment says "not available
yet"; no timer; no loudness claim — the ring rises to the phone's own volume).

## Apple App Store

**App Name (28/30)**

```text
CapyWake: Puzzle Alarm Clock
```

**Subtitle (29/30)**

```text
Wake up with a cozy mini game
```

**Keywords (98/100)**

```text
morning,math,riddle,challenge,snooze,routine,heavy,sleeper,brain,qr,shake,steps,habit,gentle,early
```

No word repeats the name or subtitle. "heavy,sleeper" is search intent, not a
promise. Dropped: "smart" (reads as sleep-cycle detection), "timer", "loud".

**Promotional Text (144/170)**

```text
Ten cozy capybara games and ten puzzles to wake your brain. Pick the ones you like, set how hard, and stop without solving whenever you need to.
```

**Description (2727/4000)**

```text
CapyWake is a cozy alarm clock with a capybara who wants you up. Before the alarm stops, it asks for one small thing: a quick puzzle or a short capybara game. Just enough to get your brain moving, never a test.

YOU CHOOSE THE CHALLENGE
• Ten puzzles: arithmetic, number sequences, missing sign, compare numbers, odd one out, remember digits, digits backwards, grid patterns, spot the change and rotated shapes.
• Ten capybara games: Catch the Capy, Memory Hideout, Rhythm Rescue, Capy Rocket, Morning Sort, Find the Impostor, Shake DJ, Tilt Maze, Capy Step Quest and QR Treasure Hunt.
• Keep the ones you enjoy, switch off the rest. Each alarm draws one at random.
• Set how hard, how many tasks, and how many wrong answers are fine.
• Try every game in practice first. Practice never touches an alarm.

ALWAYS A WAY OUT
Every puzzle and game has an emergency stop. If you cannot solve it, you can still stop the alarm. CapyWake never locks you out of your own alarm.

GENTLE OR STRAIGHT TO THE POINT
• Plain alarms with a big Stop button, when you just want to wake up.
• A wake window that starts quietly and rises to your phone's volume by your alarm time.
• Snooze with a length and a limit you choose.
• An optional check after you stop the alarm: if the phone has not moved in about 90 seconds, it rings once more.

MADE FOR HALF-ASLEEP HANDS
• Large controls, calm wording, no streaks, no scores, no shaming.
• Motion games always have buttons too, so they work with the phone on a stand.
• Light and dark mode, screen reader support and reduced motion.
• Ten languages: English, German, Russian, Spanish, Turkish, French, Italian, Portuguese, Arabic and Japanese.

PRIVATE BY DESIGN
No account. Your alarms and history stay on your phone. Permissions are asked only when you turn on the feature that needs them, with the reason first: the camera for QR Treasure Hunt, motion and fitness for Step Quest.

HONEST ABOUT RELIABILITY
CapyWake shows a checklist of what affects your alarm on your phone.
• On iPhone, alarms ring while CapyWake is open or in the background. If you force-quit the app, iOS closes it or your iPhone restarts, alarms cannot ring until you open CapyWake again. CapyWake can't promise to ring through silent mode or Focus.
• On Android, CapyWake uses exact alarms. Some phones close background apps to save battery; the checklist shows how to exempt CapyWake. After changing time zone, open CapyWake once so your alarms follow.
CapyWake is not more reliable than your phone's own clock app. Keep a backup alarm for anything you cannot miss.

STATS THAT DO NOT MAKE THINGS UP
See your alarm history and the games you played. Until there is history, Stats stays empty rather than inventing numbers.
```

**What's New (1.0)** — `First release.`

- **Primary category:** Utilities. **Secondary:** Lifestyle. Not Games — the
  games serve the alarm, and filing under Games invites the wrong review lens.
- **Age rating:** 4+ — no objectionable content, no web access, no user
  content, no ads. Answer "None" to every questionnaire item.
- **Review notes:** "CapyWake is an alarm clock. It uses the audio and
  background-fetch modes so an armed alarm can ring while the app is in the
  background (the `alarm` plugin keeps a silent audio session until the ring).
  To test: Alarms → + → set a time 2 minutes ahead → save → lock the phone.
  Every puzzle and game has an emergency stop (Stop without solving)."

## Google Play

**App Title (28/30)**

```text
CapyWake: Puzzle Alarm Clock
```

**Short Description (77/80)**

```text
A cozy alarm clock that asks a quick puzzle or capybara game before it stops.
```

**Full Description (2727/4000)** — the same text as Apple's description.

- **Category:** Tools. **Tags:** Alarm clock, Productivity, Puzzle (only tags
  Play offers for Tools; confirm in the console).
- **Content rating (IARC):** Everyone; no violence, no user interaction, no
  purchases.
- **Graphics:** 512×512 icon = `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
  downscaled (interim, G48). Feature graphic 1024×500 — **no art exists**;
  owner request in `docs/visual/ART_REQUESTS.md` #17.

## Screenshot plan (both stores)

From a current build only. iPhone: Apple's current required size set (check
App Store Connect's screenshot specifications before capturing; the iPhone 17
Pro Max simulator here is the 6.9" class). Captions are text overlays, real
UI underneath.

| # | Screen | Caption |
|---|---|---|
| 1 | A game on the ring (Catch the Capy) | Wake up with a cozy mini game |
| 2 | Puzzle chooser / challenge pool | Pick the puzzles and games you like |
| 3 | Ringing, emergency stop visible | Always a way to stop |
| 4 | Home with the next alarm | Your next alarm at a glance |
| 5 | Add/Edit alarm (wake window) | Start gently, or straight away |
| 6 | Dark mode Home | Easy on the eyes at night |
| 7 | Reliability checklist | Honest about what your phone allows |

Stats is left out: on a fresh install it is empty by design, and a filled
Stats shot would need demo data the app never shows.

## Pre-submission questions for the owner

Price (free, paid, or IAP — the app has no purchase code today), support
email and URL, privacy-policy URL (`PRIVACY.md` has the text), seller name,
and the Android ML Kit decision (`PRIVACY.md`).

# Open questions for the owner

The phase chain runs without the owner. Any question a session would have asked
goes here instead, and the session carries on with the most conservative
choice that `CLAUDE.md` allows. Newest at the bottom. The owner answers inline;
the next session reads this file first.

Format: `## <date> — Phase NN — <one-line question>`, then what was decided
meanwhile and what would change if the owner answers differently.

## 2026-11-18 — art import — per-game win poses wear blue nightcaps

Used meanwhile (the Home hero's Capy also wears blue). If the owner wants
orange only, delete the `winPoseAssetId`s in `lib/core/games/game_catalogue.dart`
and the win screen falls back to the orange-capped shared animation.

## 2026-11-18 — Phase 13 — Capy Rocket: follow an arrow, or any swipe?

The poster says only "swipe to speed up". Built meanwhile: an arrow cue (left or
right, random per boost); a swipe the other way wobbles the rocket, costs no
progress, and counts as a struggle (it brings the escape forward — in the
user's favour). Without a cue every swipe succeeds and the game asks for no
attention. If the owner prefers any-swipe, `CapyRocketRound.boost` would accept
every side and the cue pill would go; one change in core, one in the view.

## 2026-11-18 — Phase 13 — Rhythm Rescue: timing is not judged

"Rhythm" is how the pattern is shown (pads light in time); repeating it checks
order only, never timing — a timing window is precision input for a half-asleep
user. If the owner wants timing judged, that is a new mode, not a tweak.

## 2026-11-18 — Phase 13 — Short phones: should a game card cover the clock, or scroll?

On a 375 × 667 phone (iPhone SE) the ringing game card reaches over the foot of
the clock: Catch the Capy by ~19 pt since Phase 12. Tried meanwhile: keeping
the card below the clock — then the card scrolls, and on a short phone the
bottom of Catch the Capy's field sits below the fold mid-game (a half-asleep
user would have to scroll). **Kept the overlap** (the shipped behaviour) and
capped it: a test fails if any game reaches higher than Catch the Capy on that
phone; Capy Rocket was cut to Catch the Capy's height (424 pt). On the
reference phone (393 × 852) every game clears the clock, tested. Options for
the owner: (a) keep; (b) shrink game fields on short screens; (c) a smaller
clock on short screens while a game is up.

## 2026-11-18 — Phase 13 — The chain could not start Phase 14 by itself

`start_session` is refused to a session that was itself started by another
session. Meanwhile: Phase 13 is committed (ea784fe, 52b8c5d), `Current phase:
14`, and a proposal card for Phase 14 sits in the Phase 13 session. Start it
there with one click, or start a new session with the command at the top of
`docs/sessions/next.md`. If the owner wants the chain to run hands-off, each
phase must be started from the owner's own session, not from a linked one.

## 2026-11-18 — Phase 14 — Morning Sort's bank: is every entry fair?

Built meanwhile: Capy needs a toothbrush, toothpaste, apple, banana, water
bottle, keys, socks, shoes, comb, towel; Capy leaves at home a brick, anchor,
traffic cone, bowling ball, cactus, rubber duck, anvil, snowman. The decoys are
absurd on purpose — a half-asleep choice must be quick and never a judgement
call. **The poster's pizza is dropped** (some people do eat it for breakfast).
To change the bank: one `MorningItem` value in `lib/core/games/morning_sort.dart`
and one ARB key in all ten locales.

## 2026-11-18 — Phase 14 — Find the Impostor: "different Capy" instead of "real capybara"

The poster's lookalike animals do not exist in the package (G38), and art is
never generated. Built meanwhile: one Capy doing something different among
identical Capys, from the 16 bundled poses; hard pairs two poses of the same
kind (two sleepers, two calm ones). If the owner supplies the lookalike faces
(`ART_REQUESTS.md` #12), the game becomes the poster's: the bank swaps poses
for species, the round and view stay.

## 2026-11-18 — Phase 14 — Item cards are words only until icons arrive

Morning Sort's cards show the item's name with no picture (G37, request #10).
Meanwhile they are plain, readable and screen-reader complete. When the icons
arrive they go above the name; the card height is measured, so nothing else
changes.

## 2026-11-18 — Phase 15 — Motion games: should the buttons always work?

The posters say the motion games wake you "because they need movement, not
just taps". The a11y rule says a motion game needs a non-motion way to finish.
Built meanwhile: **the buttons are always on screen and always work** — Shake
DJ's "Tap the beat", Tilt Maze's four arrows — and shaking or tilting works
alongside. Hiding the buttons until a screen reader is on would lock out a
sighted user with a dead sensor, a phone on a stand or a hand in a cast
(safety). The alternative, if the owner wants motion to be required: a small
"Can't shake?" switch that reveals the buttons — one boolean in each view, no
change to the rounds.

## 2026-11-18 — Phase 15 — iOS motion purpose string (store-visible)

`ios/Runner/Info.plist` now carries `NSMotionUsageDescription` — the
`sensors_plus` plugin crashes without it. Text: "CapyWake reads motion only
while you play Shake DJ or Tilt Maze, to notice a shake or a tilt. Nothing
leaves your phone." English only: the accelerometer never prompts, so the
string is never shown on screen; App Review may read it. Reword freely.

## 2026-11-18 — Phase 15 — Shake and tilt thresholds were never felt on a device

Shake: 8 m/s² away from gravity, re-arm under 4. Tilt: 18° from the grip
where the game started (or the last arrow press), release under 9°. Chosen
from the physics and the plugin's source; **no physical phone was run** (the
simulator has no accelerometer, Android has no emulator here). If the owner
tries it and a shake is missed or a tilt fires too easily, the constants are
`ShakeDetector.defaultShakeDeviation` and `TiltReader(engageDegrees:)`.

## 2026-11-18 — Motion check — the re-ring asks the same puzzle or game

When the motion check rings once more, the alarm rings exactly as before — a
puzzle or game alarm asks for its puzzle or game again (the escape is there as
always). The alternative: make the re-ring a plain "Stop" alarm. One line in
`RingingController._sessionFor` plus a session flag; ask if wanted.

## 2026-11-18 — Phase 16 — Step Quest adds a store-visible permission

Owner decision this session: count steps as accurately as each phone allows.
So the app now declares **`ACTIVITY_RECOGNITION`** (Android — the Play listing
shows "physical activity") and asks iOS **Motion & Fitness** (the prompt shows
the `NSMotionUsageDescription` text, now in all ten languages). Both are asked
only from practice or when Step Quest is switched on, with the reason first,
never while an alarm rings. Without them (or on a phone with no step sensor)
steps are counted from the accelerometer, and "Take a step" always works.
The Play Data safety form may need "Fitness info → Physical activity",
processed on device, not collected. Reword the purpose string freely.

## 2026-11-18 — Phase 16 — Step thresholds were never felt on a device

The accelerometer step detector (for phones without a step sensor, or when
access is refused) counts a lift of 1.2 m/s² over gravity, 0.3–2 s apart, and
only after four steps in rhythm; a peak over 10 m/s² is a shake, not a step.
If the step sensor is silent while the accelerometer counts 16 steps, the round
switches to the accelerometer and keeps them (`StepTally.defaultDemoteAfter`).
**No phone was walked with** — the simulator has no pedometer or
accelerometer, Android has no emulator. Shaking the phone in rhythm can pass
as walking on the accelerometer path; the step sensor is not fooled as easily.

## 2026-11-18 — Phase 16 — Android builds now (desugaring)

`flutter build apk --debug` had never succeeded: `flutter_local_notifications`
needs core-library desugaring. Enabled in `android/app/build.gradle.kts` (its
README's lines). The debug APK builds; **it has never run** — no device, no
emulator.

## 2026-11-18 — Phase 17 — The camera permission and the scanner's size

Owner decision this session: "Add the camera". QR Treasure Hunt now uses
`mobile_scanner` 7.5.0 with **bundled ML Kit on Android** (works without
Google Play Services, so on more phones; costs a few MB per ABI — the APK size
change is recorded in `PHASE_17_POST_REVIEW.md`). The unbundled alternative
(`dev.steenbakker.mobile_scanner.useUnbundled=true`) saves that space but needs
Play Services and downloads the model on first use.

Store-visible: Android declares `CAMERA` (feature not required); iOS shows the
`NSCameraUsageDescription` text, in all ten languages. The camera is asked for
only in practice or after switching the game on, with the reason first, and
never during a ring. A ring picks QR only when a checkpoint is saved **and**
the camera is allowed; otherwise it picks another pool member or a puzzle.

## 2026-11-18 — Phase 17 — One checkpoint for every alarm

The checkpoint is app-wide (one code, replaceable from practice). Per-alarm
checkpoints (a different room on weekends) would be a small addition to the
alarm override; not built. The code itself is never stored — only a digest —
because a QR can carry a Wi-Fi password.

## 2026-11-18 — Phase 17 — No camera was run

The simulator has no camera and Android has no device here. The camera
permission channel is proven on the simulator (it answers), the scanner's
failure path in a widget test over the plugin's channel; **no code was ever
scanned by a real camera**.

## 2026-11-18 — Phase 18 — Four of the five loops are damaged; none shipped

`04_shake_dj` lost its dark outline and eyes to masking (fine on dark, holes on
light); `02_sleep_breathing` and `01_wake_up` are cut flat inside the frame;
`03_walk_cycle` lost its backpack. `05_celebration` is clean, but the win
screen already shows your 2026-11-18 replacement, so it would undo a decision.
Meanwhile every screen keeps its still art. Re-cut frames (`ART_REQUESTS.md`
#15) drop straight in: Shake DJ's dancer and the Alarms empty state are the
places a loop replaces a still of the same pose. Say where the trophy loop
should go (#16), or that it should replace the win frames.

## 2026-11-18 — Phase 18 — White on orange and green is below contrast

Every CTA's white label on the brand orange (2.07:1) and the ringing "Tap to
stop" / "Solve a puzzle" pill (white on grass, 2.36:1) fail even the 3:1 bar
for large text, in both themes. It is the palette recorded in Phase 02 and a
Tier A choice, so it is counted (and pinned per screen in
`test/design/text_contrast_test.dart`), not retuned. Cocoa on orange passes
(7.9:1) if you want the labels dark.

# Phase 13 — Pre-review (adversarial, before any code)

Against `PHASE_13_PLAN.md` draft 1, the Phase 11/12 contract, `CLAUDE.md` and the
code it plugs into (`catch_the_capy_view.dart`, `memory_hideout_view.dart`,
`game_header.dart`, `game_registry.dart`, `art.dart`, `check_no_fake_stats.dart`,
`capture_test.dart`). **15 findings: 5 High, 6 Medium, 4 Low. All applied; none
invalid.**

---

## High

**H1 — Rhythm Rescue's instruction changes per phase, so the pads jump under the
finger.** Draft 1 gives `GameHeader` a listen / repeat instruction. The header
sits above the pads; when the two strings wrap to different line counts (likely
in de/ru/tr at 393 pt, certain at large text) the pads move by a line the moment
playback ends — exactly when the user reaches for them. Phase 12 SR2 found the
same defect on device ("Ready jumped ~30 pt under the finger").
**Applied:** one instruction for the whole game ("Tap the pads in the order
shown."), true in both modes. The phase is shown by the ▶ row (a "Listen…" /
"Your turn" status in a fixed slot), not by the header.

**H2 — Capy Rocket's cue line sits in the button row, so the buttons can move.**
A cue that wraps differently for "left" and "right" changes the row height and
re-centres both buttons between boosts. **Applied:** the cue moves into a pill at
the top of the fixed-height sky field (where the poster draws "Reach the sun!");
the panel row holds only the two buttons and a swipe-hint icon — constant height.

**H3 — The rocket is drawn larger than its art supports.** `pose.capyRocket` is
`ArtUse.winPose` (100 pt, 300 px). Draft 1 renders it at 104 pt: 4 % under-resolved
on purpose, and a size the manifest does not declare. **Applied:** the rocket's
width is `ArtUse.winPose.renderBoxPt` (no second literal); still reported as a
gap (a landed pose standing in for a flying one).

**H4 — Pad numerals in a `Text` would be a numeric literal in `lib/features/` and
would not localize.** `Text('${pad + 1}')` matches `_interpolatedDigit` in
`check_no_fake_stats.dart`; and a numeral is user-facing text that intl may render
with locale digits. **Applied:** a `gameRhythmRescuePadNumber` key `{number}` with
an `int` placeholder, the same route `gameProgressValue` takes; slots reuse it.

**H5 — "Still mode" cannot be one flag read once.** Draft 1 says the pattern is
hidden while repeating "when moving". If `accessibleNavigation` turns on mid-game
(a user starts VoiceOver to find the escape), a hidden pattern stays hidden and a
playback `Timer` keeps lighting pads a screen reader cannot see. **Applied:** the
view derives `_moves` from `widget.reduceMotion` and
`MediaQuery.accessibleNavigationOf(context)` on every build (as Catch the Capy
does); when it turns false, playback timers are cancelled, `heard()` is applied,
and the pattern shows. Tested by flipping `accessibleNavigation` mid-playback.

## Medium

**M1 — `pumpAndSettle` returns mid-playback.** A pending `Timer` schedules no
frame, so `pumpAndSettle` settles between beats; a test (or the capture) that
assumes "settled = playback done" asserts on `listening`. **Applied:** tests drive
playback with explicit `pump(beat)`; the capture's win helper watches the lit pad
beat by beat, as a user would.

**M2 — Timers outliving the widget.** A playback chain or rocket hover `Timer`
still pending at dispose fails every widget test ("A Timer is still pending") and
leaks on device. **Applied:** one `Timer?` per view, cancelled in `dispose` and
on completion; a test disposes mid-playback and mid-hover.

**M3 — The outcome line grows and pushes Snooze.** It sits last in the card;
below it on the ringing surface is the chrome. A first outcome appearing (or a
two-line translation) moves Snooze and the escape. **Applied:** the outcome slot
is always present with a minimum height of two body lines at the current text
scale; the text fades in, the layout does not move.

**M4 — "Not quite. Listen again." is false in still mode**, where nothing plays.
**Applied:** one mode-neutral line: "Not quite. Start again from the first beat."

**M5 — Rhythm Rescue does not need, and should not have, a fixed field height.**
Draft 1 inherited "fixed height" from the stack-based games. The rule exists
because a `Stack`/`LayoutBuilder` field in the scrolling slot has unbounded
height; RR is a `Column`. A fixed height would clip 1:1 pads whose numerals grow
with text scale. **Applied:** pads are square with a 72 pt minimum and grow with
the numeral; no `FittedBox`, no clamped scaling. Capy Rocket's sky field keeps
its fixed 280 pt (it is a `Stack`).

**M6 — Images decode after the first frame** (Phase 12's first-second flicker).
**Applied:** both views pre-cache their art in `didChangeDependencies`.

## Low

**L1 — Taps during playback do nothing, silently.** Correct (a tap while listening
must not count as a wrong answer — that would punish the user for the game's own
timing), but the pads must read as unavailable. **Applied:** pads are
`enabled: false` in semantics and drawn at reduced opacity while listening.

**L2 — Physical words in a direction-aware app.** `CLAUDE.md` forbids hardcoded
`left`/`right` in *layout*. The rocket's buttons are laid out with
`start`/`end` (they mirror in RTL); only their **labels** name the physical side,
because a swipe is physical. **Applied:** the label is computed from
`Directionality`; an RTL test asserts the start-side button says "right".

**L3 — Four new colour tokens are not from the five primary mockups.** The
`CapyColors` header says "sampled from the mockups". **Applied:** the pad
colours sit in their own `CapyPadColors` group whose one-line doc names the
poster they were sampled from.

**L4 — Capy Rocket's struggle model is a design choice the owner has not seen.**
The poster says "swipe to speed up"; draft 1 adds a direction cue. Without one
every swipe succeeds, the game asks for no attention, and its struggle count is
always 0. **Applied:** kept the cue (a wrong swipe costs nothing but raises the
escape — in the user's favour) and logged the question in `OPEN_QUESTIONS.md`.

---

## Checked and found sound

- No `DismissMethod`, schema, host or pool change: `RingingHost` builds through
  `GameRegistry.build`, practice and the chooser read `GameCatalogue.playable`.
- Escape ownership unchanged: a game only reports `GameChallenge`.
- Both win headlines and win poses already exist (art import, 2026-11-18).
- Bundle: `assets/art` 1,561 / 2,182 KB; one ~80 KB scene fits.

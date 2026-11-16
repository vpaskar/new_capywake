# Phase 04 — post-review

**Alarms list and Add/Edit alarm. Done, 2026-11-16.**

**1,189 tests**, analyze clean (zero issues including infos), `lib` 97.54% /
`lib/core` 99.41% / `lib/data` 86.40%, **399 ARB keys × 10 locales**, four
verified captures at 1179×2556.

---

## Registered expectations, measured and restated

The plan registered numbers so measurement could contradict them. It did,
three times.

| Registered | Measured | Note |
|---|---|---|
| ~1,192 tests | **1,189** | within 3 of the estimate |
| "≥3 new ARB keys" | **4** | and two of my six were already ported |
| Add/Edit meadow "starts ~780" | **793.4** | the pre-review's own number was wrong |

**The ARB restatement is the interesting one.** The plan's first draft said
*0 new keys*, drawn from a prefix search rather than from the screens. The
pre-review (M1) corrected it to "≥3" and named three gaps: empty state, Add
button label, edit title. On measurement, **`alarmsEmptyTitle` and
`alarmsEmptyBody` already existed** — Phase 02 ported them. The real count is
4 (`alarmAddAction`, `alarmAddTitle`, `alarmEditTitle`, `alarmBackAction`),
and the existing empty-state body already read "Tap *Add alarm* to create your
first one", which matched the button label the pre-review said was missing.

So the pre-review was right that the plan's zero was unfounded and wrong about
one of the three gaps. Both are recorded; neither was quietly adjusted.

---

## What this phase found that earlier work had written down wrongly

### 1. `SceneHeader.bandHeight` defaulted to Home's measurement

188.4 pt is `01_HOME.png`'s band. Alarms is **148.6**, Add/Edit **112.1**. Both
Phase 04 screens took the default; the first capture read the hero **+39.8 pt**
and every block below inherited it.

Making the parameter required surfaced two more callers — Home (correct, now
explicit) and **Stats, which was silently carrying Home's number** and will
have to measure it in Phase 08.

The same was true of `MeadowFooter.height` (65.2 Home, **52.2** Alarms, **59.1**
Add/Edit); the too-tall band is why the fourth alarm card fell off the fold.

**Third occurrence of this shape**, after Phase 03's overlap bug: a
design-system default that is one screen's measurement is wrong on every other
screen, silently, and the compiler cannot help while a default exists.

### 2. `compare.dart` could not see a card border at all

A 1-px border moves a 393-pt row mean by **under one unit**. Every alarm card
was reported `absent` while all four were on screen and correctly placed. The
first fix (`L < 235`) still could not see the two **disabled** rows, whose
55%-opacity borders land near 236 — the screen's own content hiding it from
its own measurement. Threshold now 244, read down a text-free column.

Phase 03 extended this tool from 4 blocks to 14 and the gap survived, because
Home's blocks are all large flat bands.

### 3. `narrowWeekday`'s doc sent the next phase to the wrong formatter

`AlarmFormat.narrowWeekday`'s dartdoc said it is "used for the seven repeat-day
toggles, which are a fixed square and have room for one glyph". That describes
the **legacy's** control. `03_ADD_EDIT_ALARM.png` draws ~48 pt pills reading
"Mon". Corrected in place, as Phase 03 corrected the `SceneHeader` explanation
in three documents.

### 4. `lib/core` could not drive either screen

`AlarmFormat.time` returns one string (`'7:00 AM'`). The list styles "AM"
smaller than the digits; the form needs three controls. Splitting the string
in a widget is locale-fragile — `ar` renders `ص`, `it` `m.`, `tr` `ÖÖ`, and a
24-hour locale emits none.

`ClockTimeParts` + `AlarmFormat.timeParts` added to `lib/core/`, built from
`intl` skeletons, tested across ten locales. A `lib/core/` change in a UI phase,
justified because the gap was in the domain, not the view.

**A speculative field was dropped on measurement.** The pre-review proposed
`periodLeads` for locales that put the marker first. Probing all ten with the
explicit `h:mm a` pattern: **none do.** An always-false field would have been
shipped on reasoning alone.

### 5. The capture driver committed 18.8 MB of PNG bytes as a text file

`test_driver/integration_test.dart` wrote every `reportData` key to
`docs/visual/<key>/inset.txt`. The framework adds a `screenshots` key holding
every PNG's bytes, so it produced a 24 MB `docs/visual/screenshots/inset.txt`
— **18,821,998 bytes of which are in the Phase 03 commit.**

No gate could see it: not bundled, so `check_bundle_size.dart` never looked;
not Dart, so nothing analysed it; and `docs/visual/` is exactly where a
capture phase expects new files. Found at `git status` review before
committing. Driver now writes only numeric values; directory removed; a
re-capture confirms it stays gone and all four screens still verify.

### 6. `CapyNavBar` overflowed at 2× text on every screen

Found incidentally: Phase 04's first 2×-text test on Alarms failed inside
`capy_nav_bar.dart`, not in new code. Home's tests never caught it because
they pump `HomeScreen` directly, without the shell. Fixed in the nav bar.

---

## Tier A — where the two screens landed

**A screen is done when the comparison is captured and its deviations are
named.** Both are captured; the deviations are below.

### Alarms — 5 blocks outside ±4 pt

| Block | Delta |
|---|---|
| Header band lower edge | **+0.1** |
| Hero scene lower edge | **−0.2** |
| Alarm card 1 top | **−0.0** |
| Alarm card 1 bottom | **−1.0** |
| Alarm card 2 top | **+0.2** |
| Alarm card 2 bottom | **+2.1** |
| Alarm card 3 top | **+3.6** |
| Alarm card 3 bottom | +4.8 |
| Alarm card 4 top | +5.6 |
| Alarm card 4 bottom | +21.6 |
| Meadow footer top | absent |
| Nav bar top | absent |

Card pitch is **102.3 against the mockup's 102.1** and card height 88.6
against 89.6 — the rows themselves are right. Cards 3b/4 drift 4.8–5.6 by
accumulation, and card 4's bottom plus the meadow and nav read `absent`
because the fourth row sits below the fold: the list scrolls, which the mockup
does not show and cannot show.

### Add/Edit — 9 blocks outside ±4 pt

| Block | Delta |
|---|---|
| Header band lower edge | **+0.1** |
| Hero scene lower edge | **0.0** |
| Time stepper card top | **+0.2** |
| Time stepper card bottom | +15.2 |
| Repeat card top | −8.9 |
| Repeat card bottom | +31.1 |
| Label card top | +15.3 |
| Sound card top | +22.2 |
| Snooze card top | −9.4 |
| Save CTA top | +6.4 |
| Save CTA bottom | absent |

The stack's **anchor is correct** (hero 0.0, first card +0.2) and the
individual card heights are not: each card's content is taller than the
mockup's, and the error accumulates down the form. The CTA's bottom falls
below the fold.

**This screen is the weaker of the two and is named as such.** Closing it
needs per-card internal measurement — the row paddings inside `CapyCard`,
which is shared with Home — and that is a change to a component three screens
use. It is recorded here rather than attempted at the end of a long phase.

---

## Deviations taken deliberately

| Deviation | Measured | Why |
|---|---|---|
| Stepper chevrons | mockup **19.4 pt**, ours 19.4 painted in a **44 pt** hit region | 19.4 is under the reachable minimum, and `CLAUDE.md` makes large alarm controls a safety rule. Same split `CapyToggle` uses |
| Weekday chips | mockup **31.8 pt**, ours 31.8 painted in **44 pt** | same |
| Add Alarm pill | mockup **36.9 pt**, ours 36.9 painted in **44 pt** | same |
| Alarm row height | mockup **89.6 pt**, ours ≥89.6 | a minimum, not a cap: the row grows at accessibility text sizes rather than clipping the label |
| Nav bar height | mockup **64.6 pt**, ours ≥64.6 | same, and it was overflowing at 2× |
| Hero scene | `alarms.webp` on **both** screens | the mockups show two further compositions, neither in the package. Tier B, logged |

**Constraint F1 (palette):** no control added this phase uses `accent`,
`accentDeep`, `success` or `grass` as its only channel. The Add pill and the
selected chips are accent **fills under `cocoa` text** — the pattern the
constraint prefers. Selected chips also carry a weight change; the toggle
carries knob position; the disabled rows carry opacity *and* knob position.
No token was retuned.

---

## Asset gaps reported this phase

**G14** the four row thumbnails are cutouts standing in for painted panels
(`moments_01`, `moments_03`, `collection_02`, `collection_06` — the last has
purple headphones against the mockup's blue); **G15** all four are
under-resolution for a 124 pt box at 3× (230–288 px against 372 needed), and
are the largest poses the package supplies; **G16** 26 bundled mascot cells
are still unreferenced.

G15 is recorded by name in `knownUnderResolution` so the manifest gate still
protects every other asset and a *worse* file fails. **Reported in-session,
not only here**, as `CLAUDE.md` requires.

---

## Review passes

| Pass | Findings | Applied | Invalid |
|---|---|---|---|
| Pre-review | 3H / 5M / 2L | 10 | 0 |
| Self-review #1 | 3H / 3M / 2L | 8 | 0 |
| Self-review #2 | 2H / 3M / 1L | 4 | **2** |
| Full-project | 3H / 2M / 1L + 1 decision | 6 | 0 |

**32 findings, 28 applied, 2 marked invalid with a reason and a test, none
deferred.** The two invalid ones (a `TextEditingController` with a single
writer, and a double-Save that is unreachable and idempotent) carry their
tests so a later phase that makes `_save` slower sees the assertion already
there.

---

## Decision carried from Phase 03

**P4 — the `_nearest` matcher — is decided.** An edge is consumed by the first
block that claims it, so one displacement is not reported as several failures.
Its limits are stated in the full-project review: matching is greedy in table
order rather than a global assignment, and consuming edges makes the block
table's *completeness* matter — a missing reference row now corrupts the row
after it, which is exactly what happened to card 3's top until both missing
card bottoms were added.

---

## Left for later, named

- **Add/Edit's internal card heights** (above) — needs a `CapyCard` change.
- **`compare.dart`'s hairline column is hardcoded at x=360 pt**, text-free on
  Alarms by measurement and on Add/Edit by luck. The honest fix is per-screen
  probe columns; inventing that mechanism for screens that do not exist yet is
  how the 188.4 default got written.
- **`flutter build ios --simulator` fails with Xcode status 255** on this
  machine, and taps did not reach the booted simulator. `flutter drive` works,
  which is why the captures are verified. **No control was exercised by hand
  this phase and nothing claims otherwise.** Phase 05 needs a working device
  path for the alarm engine.
- **26 unreferenced mascot cells** — payload until a later screen uses them.

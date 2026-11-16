# Current phase

**Phase 04 — Alarms list and Add/Edit: done, 2026-11-16. `Current phase: 05`.**

The first screens that **write**, and the first to use the ported `AlarmDraft`
as the form model it was built to be. **1,189 tests**, analyze clean, lib
97.54% / `lib/core` 99.41% / `lib/data` 86.40%, **399 ARB keys × 10 locales**.

## What this phase actually found

### 1. A design-system default was one screen's measurement — the third time

`SceneHeader.bandHeight` defaulted to **188.4 pt**, which is `01_HOME.png`'s
band. Alarms measures **148.6**, Add/Edit **112.1**. Both new screens took the
default and the first capture read the hero **+39.8 pt**, displacing
everything below.

Making the parameter **required** immediately surfaced two more callers: Home
(correct, now explicit) and **Stats, which was silently carrying Home's
number** and must measure it in Phase 08.

`MeadowFooter.height` was the same shape — 65.2 Home, **52.2** Alarms, **59.1**
Add/Edit — and its excess is why the fourth alarm card fell off the fold.

**The pattern is the finding.** After Phase 03's overlap bug this is the third
occurrence: a shared widget whose default is one screen's measurement is wrong
on every other screen, silently, and the compiler cannot help while a default
exists. `bandHeight` is required now; `MeadowFooter.height` is not, because a
footer that is slightly tall is cosmetic rather than displacing — an
asymmetry that is deliberate and recorded.

### 2. `compare.dart` could not see a card border at all

A 1-px border moves a 393-pt row mean by **under one unit**, so all four alarm
cards read `absent` while on screen and correctly placed. The first fix
(`L < 235`) still could not see the two **disabled** rows, whose 55%-opacity
borders land near 236 — the screen's own content hiding it from its own
measurement.

Phase 03 extended this tool from 4 blocks to 14 and the gap survived, because
Home's blocks are all large flat bands. **Three phases, four blindnesses.**

### 3. `lib/core` could not drive either screen

`AlarmFormat.time` returns one string (`'7:00 AM'`); both mockups style the
digits and the marker differently. Splitting it in a widget is locale-fragile
(`ar` → `ص`, `it` → `m.`, `tr` → `ÖÖ`, 24-hour locales → none).

`ClockTimeParts` + `timeParts` added to `lib/core/`, tested across ten locales.
**A proposed `periodLeads` field was dropped on measurement** — probing all
ten showed no locale leads with the marker. It would have shipped
always-false, on reasoning alone.

### 4. `CapyNavBar` overflowed at 2× text on every screen

Found incidentally by Phase 04's first accessibility test. Home's tests never
caught it because they pump `HomeScreen` directly, without the shell.

### 5. `narrowWeekday`'s doc pointed at the wrong control

It said the formatter is "used for the seven repeat-day toggles… room for one
glyph" — describing the **legacy's** control. The mockup draws ~48 pt pills
reading "Mon". Corrected in place.

## Decisions this phase made

| Question | Decision |
|---|---|
| Phase 03's **P4** (`_nearest`) | **Decided.** An edge is consumed by the block that claims it. Limits stated: greedy in table order, and the table's *completeness* now matters — two missing card-bottom rows were corrupting the row after them |
| Mockup control sizes under 44 pt | Paint the mockup's size, grow only the hit region (chevrons 19.4, chips 31.8, Add pill 36.9). The split `CapyToggle` already used |
| Row and nav-bar heights | A **minimum**, not a cap — they grow at accessibility text sizes rather than clipping |
| Two gutters | `CapySpacing.gutterWide = 15.0` beside `gutter = 11.0`. Both measured; Tier A binds each screen to its own mockup |
| Add/Edit's route | Root navigator, not the shell branch — the mockup draws no tab bar |

## Tier A state

**Alarms is close.** Hero **−0.2**, cards 1–3 at −0.0 / −1.0 / +0.2 / +2.1 /
+3.6, pitch 102.3 against the mockup's 102.1. Cards 3b/4 drift 4.8–5.6 by
accumulation; card 4's bottom, the meadow and the nav read `absent` because
the list scrolls.

**Add/Edit is the weaker screen and is named as such.** Its anchor is right
(hero 0.0, first card +0.2) and its card *contents* are taller than the
mockup's, so the error accumulates down the form. Closing it needs per-card
internal measurement inside `CapyCard`, which three screens share.

## Next session — Phase 05, alarm engine and reliability

**Chase the simulator build first.** `flutter build ios --simulator` fails with
an opaque Xcode 255 on this machine and taps did not reach the booted
simulator, so **no control was exercised by hand this phase** and nothing
claims otherwise. `flutter drive` works, which is why all four captures are
verified. Phase 05 needs a working device path.

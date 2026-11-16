# Phase 04 — adversarial pre-review

Written **before any code**, against `PHASE_04_PLAN.md`. Every finding is
applied or marked invalid with a one-line reason. "Deferred" is not an
outcome.

Findings were produced by **reading the ported APIs the plan proposes to use**,
not by inspecting the plan's prose. That is where six of the nine came from.

---

## H1 — Nothing in `lib/core/` splits a clock time into hour, minute and period, and both mockups need the parts separately

**High.**

`AlarmFormat.time` returns one string: `'7:00 AM'`. The plan assumes it can
drive both screens from it. Neither screen can use it.

- `02_ALARMS.png` renders **"7:00"** in a large weight and **"AM"** in a much
  smaller one, on the same baseline. Measured: the digits occupy a ~30 pt cap
  height and the period ~16 pt. One `Text` cannot do that.
- `03_ADD_EDIT_ALARM.png` needs **three independent controls** — an hour well
  reading `7`, a minute well reading `00`, and a two-state AM/PM pill.

Splitting `'7:00 AM'` back apart in the widget layer with a string search is
exactly the kind of locale-fragile code `AlarmFormat` exists to prevent: `ja`
renders `午前7:00`, `de` has no period at all, and `ar` uses Arabic-Indic
digits with `ص`/`م`.

**The widget layer must not do this, and `lib/core/` currently cannot.**

**Applied.** Add to `lib/core/alarm_format.dart`:

```dart
/// The parts of a clock time, already localized, for surfaces that style
/// the period differently from the digits.
class ClockTimeParts {
  final String time;      // '7:00'  / '07:00' / '٧:٠٠'
  final String? period;   // 'AM'    / null in h24 and in de
  final bool periodLeads; // ja puts 午前 before the digits
}

static ClockTimeParts timeParts({
  required int minutes,
  required String localeName,
  required TimeFormatPreference format,
});
```

Built from `intl` skeletons (`DateFormat.j()` / `DateFormat('a')`), never from
substring surgery on a formatted string. Unit-tested in `test/core/` across
all ten locales, including that `de` yields `period == null` and `ja` yields
`periodLeads == true`.

**This is a `lib/core/` change in a UI phase.** Justified because the gap is in
the domain, not the view: the alternative is locale-fragile parsing in two
widgets. Flutter-free, so the `lib/core` ≥95% gate still applies to it.

---

## H2 — The seven weekday chips show three letters, and the plan's control uses the one-letter formatter

**High.**

`AlarmFormat` carries both `shortWeekday` ("Mon") and `narrowWeekday` ("M"),
and its own dartdoc says narrow is "used for the seven repeat-day toggles,
which are a fixed square and have room for one glyph."

**The mockup disagrees.** `03_ADD_EDIT_ALARM.png`'s chips read **Mon, Tue,
Wed, Thu, Fri, Sat, Sun** — measured 31.8 pt tall, spanning x 27.2–271.1 for
five chips, so ~48 pt wide each. They are pills, not squares.

The ported comment describes the *legacy's* control, which this project is not
rebuilding. Following it would ship a row of "M T W T F S S" against a mockup
that plainly shows words — and in English two pairs are ambiguous.

**Applied.** The chips use `shortWeekday`. `narrowWeekday` stays in
`lib/core/` unused by this phase (it is covered by its own ported tests). The
stale dartdoc on `narrowWeekday` is corrected in place, the same way Phase 03
corrected the `SceneHeader` explanation in three documents — a comment that
tells the next phase to use the wrong formatter is a defect, not prose.

---

## H3 — The list is ordered by `createdAt`, and the mockup is ordered by time

**High.**

`watchAlarms()` sorts by `createdAt` ascending. `alarmsStreamProvider` is that
stream unmodified. Home gets away with it because it shows only the *next*
alarm, computed by `NextAlarm`.

The mockup's four rows read **7:00, 7:30, 8:00, 9:30** — ascending by
`targetTimeMinutes`. With creation order, adding a 6:00 alarm last would put it
at the bottom, under 9:30. For a list whose entire purpose is "when do I get
up", that is wrong in a way the user notices immediately.

**Applied.** The screen sorts by `(targetTimeMinutes, createdAt)` — the second
key makes the order total, so two alarms at 07:00 do not swap on every rebuild.
The sort lives in the screen, not the repository: `watchAlarms`'s creation
order is correct for its other callers and is covered by ported tests.
Asserted with a test that seeds out of order and expects sorted output.

---

## M1 — "Expected new ARB keys: 0" is stated but three UI strings have no key

**Medium.**

The plan checked the ported ARB and found `alarmTimeStepper*`, `alarmSound*`,
`alarmSnooze*` and `alarmDelete*` present, and concluded zero new keys. That
conclusion was drawn from a prefix search, not from the screens.

Grepping for what the two mockups actually render finds no key for:

1. the **empty state** of the alarm list (the mockup never shows it, but
   `CLAUDE.md` makes it the default and Phase 03 set the precedent);
2. the **"Add Alarm"** pill's visible label — `addAlarmTooltip` exists, but a
   tooltip is not a button label and reusing it would put tooltip phrasing on
   a CTA;
3. the **screen title** for the edit route in its two states ("Add Alarm" vs
   editing an existing one).

**Applied.** The plan's "0" is replaced by a registered expectation: **≥3 new
keys × 10 locales**, measured and restated after implementation. Phase 02
estimated 66 data tests and measured 83 and said so; the same discipline
applies to a count of zero, which is the easiest number to be wrong about
because nothing contradicts it until the gate runs.

---

## M2 — Two gutters, and the plan records the difference without saying which one the shared components use

**Medium.**

Measured: Alarms 11.5 pt, Add/Edit 14.8 pt. The plan records both and says
"recorded rather than normalized", which is the right call. But `CapyCard`,
`CapyButton` and `MeadowFooter` are *shared*, and `CapySpacing.gutter = 11.0`
is a single token. The plan does not say what the Add/Edit screen passes.

Left unsaid, the implementation will either silently use 11.0 (a 3.8 pt Tier A
error on every card edge of a screen, close to the 4 pt tolerance) or hardcode
14.8 in six places.

**Applied.** `CapySpacing.gutterWide = 15.0` is added as a named token beside
`gutter`, with a one-line comment naming the screen it was measured from.
Add/Edit passes it explicitly. No shared component changes its default.

---

## M3 — The capture harness seeds one alarm and the mockup has four, and the seed carries no label

**Medium.**

`captureSeed` holds a single `Workdays` alarm. A capture of Alarms against it
would show one row where the mockup shows four, and `compare.dart` would
measure card 2's top against empty background — every card block below the
first would read "absent" or snap to the meadow, exactly the matcher behaviour
P4 is about.

**Applied.** `captureSeed` is extended to the mockup's four rows (07:00
weekdays, 07:30 Mon/Wed/Fri, 08:00 weekends **disabled**, 21:30 daily
**disabled**) so both toggle states are captured. The existing
`capture-weekday` id is preserved so Home's capture is unchanged — Phase 03's
Home capture is evidence already recorded, and silently changing the data
under it would invalidate a published comparison.

---

## M4 — Add/Edit is a pushed route, so `compare.dart`'s 14 shared blocks are mostly inapplicable to it

**Medium.**

`referenceBlocks` is a single const map applied to **every** screen, by
design (finding M5 of Phase 01: a screen must not pick the blocks it already
matches). Add/Edit has no nav bar, no game rail, no My Stats row and no
next-alarm card. Nine of the fourteen rows cannot exist on it.

Running the current tool against it would report ~9 fabricated failures and
bury the five real ones.

**Applied.** `referenceBlocks` becomes a map of screen → blocks, with a
**shared** group that every screen still gets (header band, hero lower edge,
card top) so the anti-cherry-picking property M5 protects is preserved. A
screen may add rows; it may not remove a shared one. The tool fails if a
screen is not in the map, rather than silently reporting nothing.

---

## M5 — The plan claims Add/Edit has "no `MeadowFooter` room" on a measurement that does not support it

**Medium.**

The plan's risk table says: "Measured: CTA ends 778.1, meadow starts ~780 — it
is a pushed route with no nav bar." The 780 figure came from the luminance
scan's `778.1, 779.5, 780.0` cluster, which is **the CTA's own lower edge**,
not the start of a meadow band.

This is precisely Phase 03's error — reading a glyph or control edge as a
layout boundary — committed in the document that was written to avoid it.

**Applied.** Re-measured by green-saturation run, the method the rule
prescribes for a textured boundary: the meadow band on `03_ADD_EDIT_ALARM.png`
runs **793.4 → 852.5** (page bottom), i.e. it **is** present and is ~59 pt
tall. Alarms' band runs **728.3 → 780.5** and is ~52 pt, ending where the nav
bar begins. The plan's row is corrected; Add/Edit gets a `MeadowFooter`.

**This finding's own first figure was wrong, and that is recorded rather than
silently fixed.** The draft above originally gave the Add/Edit meadow as
"780.5 → 853". 780.5 is where the **Alarms** meadow run *ends* — a number
carried across from the adjacent measurement and never re-derived. It was
caught by running the green-run scan on both screens in one command and
reading two different answers.

The finding accused the plan of reading a control edge as a layout boundary,
and then did the same class of thing itself: **reused a number instead of
measuring the thing it was naming.** `CLAUDE.md`'s rule — "state the method
next to the number" — is necessary but not sufficient; this figure *had* a
method named beside it and was still wrong, because the method was run against
a different image. The operative discipline is re-deriving the number for the
artifact it describes.

---

## L1 — The sound row navigates nowhere and the plan does not say what it looks like

**Low.**

The plan excludes the sound picker and says the row is "marked as opening a
picker in a later phase, following Home's `comingSoon` precedent". Home's
precedent is a **sheet that says the game is not built yet**, not an inert row.

**Applied.** The sound row shows the current sound name and opens the same
kind of "not built yet" sheet Home uses, reusing
`alarmSoundPreviewUnavailable`. An inert tap target is the dead tap
`CLAUDE.md` forbids.

---

## L2 — Four thumbnails are added to `CapyArt` as `mascotSmall`, whose render box is 44 pt

**Low.**

`ArtUse.mascotSmall` declares `renderBoxPt: 44` and the audit derives
`requiredPixels` from it. The thumbnail panel is **~124 × 88 pt**. Registering
the four cells as `mascotSmall` would make the manifest test assert 132 px when
the real requirement is ~372 px — the gate would pass on art that is visibly
soft, which is worse than no gate.

**Applied.** A new `ArtUse.thumbnail(renderBoxPt: 124)` is declared and the
four cells use it. The audit then measures them against the box they are
actually drawn into — and will **fail**, which is correct and is gap G15. The
manifest test's expectation is adjusted to record a known shortfall by name
rather than by lowering the requirement.

---

## Invalid

**"Delete is not in the mockup, so it is out of scope."** Not raised as a
finding because it would be wrong: `03_ADD_EDIT_ALARM.png` shows the **Add**
state, where there is nothing to delete. The edit state needs it, the ARB
carries `alarmDeleteAction`/`ConfirmTitle`/`ConfirmBody`, and shipping an edit
screen with no way to remove an alarm would strand the user. It stays in scope.

---

## Summary

| ID | Severity | Outcome |
|---|---|---|
| H1 | High | Applied — `ClockTimeParts` added to `lib/core/` |
| H2 | High | Applied — chips use `shortWeekday`; stale dartdoc corrected |
| H3 | High | Applied — list sorts by time, totally ordered |
| M1 | Medium | Applied — "0 new keys" replaced by ≥3, restated after measurement |
| M2 | Medium | Applied — `gutterWide` token |
| M3 | Medium | Applied — seed extended to four rows, both toggle states |
| M4 | Medium | Applied — `compare.dart` per-screen blocks with a shared group |
| M5 | Medium | Applied — meadow re-measured 780.5→853; plan row corrected |
| L1 | Low | Applied — sound row opens a "not built yet" sheet |
| L2 | Low | Applied — `ArtUse.thumbnail`; G15 recorded by name |

3 High, 5 Medium, 2 Low. **All applied, none deferred, none invalid.**

Three of the Highs were found by reading the ported API the plan intended to
call. The plan was wrong about what `lib/core/` provides, not about what the
screens need — which is the failure mode a phase that ports a domain is most
exposed to.

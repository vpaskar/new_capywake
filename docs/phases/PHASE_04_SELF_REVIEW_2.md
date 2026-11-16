# Phase 04 — self-review #2

A second pass after #1's findings were applied and re-validated. #1 was
geometry; this one went looking for behaviour the widget tests do not reach.

---

## G1 — Deleting an alarm flashed the not-found screen over the user's own action

**High.**

`AlarmEditScreen` re-derived `existing` from `alarmsStreamProvider` on every
build. Confirming a delete writes to the database, Drift emits, the row is
gone — and the stream emits **before** `context.pop()` lands. For that frame
the screen rendered `_MissingAlarm`, so the last thing a user saw after
choosing Delete was an error-shaped screen telling them the alarm was not
there.

Proven, not reasoned about: a test taps Delete, confirms, pumps **one frame**
and finds the empty-state title on screen twice — the list's behind, and the
form's own on top.

**Applied.** The screen latches the alarm once it arrives and keeps showing it
while the route pops; `_MissingAlarm` is now only for a route opened with an
id that was never there. The test asserts one frame after confirm that the
form is still mounted, and that it is gone after settle.

**Why #1 missed it.** #1 checked that every `await` was followed by a
`mounted` guard, and they were. The defect was not unsafe async — it was a
correct async sequence rendering an incorrect intermediate state.

---

## G2 — `TextEditingController` was seeded from the draft and never reconciled

**Medium — invalid on inspection, recorded because the reasoning matters.**

`_label` is built in `initState` from `_draft.label` and never updated if the
draft changes elsewhere. That is a real hazard in general: two sources of
truth for one string.

Here it is not reachable. The controller is the **only** writer of
`_draft.label` (`onChanged` copies into the draft, nothing copies back), and
`_Form` is keyed by `ValueKey(alarmId)`, so switching alarms rebuilds the
state rather than mutating it.

**Invalid: the controller is the sole writer and the key rebuilds on identity
change.** Left as is rather than adding a sync that would introduce the second
writer the finding was worried about.

---

## G3 — A second Save tap could write twice

**Medium — tested, does not occur.**

`_save` awaits an `upsertAlarm` and then pops, with no in-flight guard. Two
fast taps would be two writes.

Tested directly: two `tap` calls with no pump between them, then settle —
**one row**. The first tap's write completes and pops before the second
hit-tests, and `upsertAlarm` is an upsert on the same id, so even a double
write is idempotent.

**Invalid: not reachable, and idempotent if it were.** Recorded with its test
so a later phase that makes `_save` slower (an engine call in Phase 05) sees
the assertion already there.

---

## G4 — `compare.dart` could not see any card border it was asked to measure

**High.**

The tool's detector is a row-mean luminance scan with `|ΔL| > 18`. A 1-px card
border moves a 393-pt-wide row mean by **under one unit**. So every alarm card
was reported `absent` — including four cards that were on screen, correctly
laid out, within 15 pt of their reference.

"Absent" reads as *the layout did not draw this*. It meant *the instrument
cannot see this*. Phase 03 extended this tool from 4 blocks to 14 and the gap
survived, because Home's blocks are all large flat bands.

**Applied.** `_hairlines` reads local minima down the same text-free column
the mockup's own rows were measured at, and merges them into the edge list.
A second pass was needed: the first cut at `L < 235` still missed the two
**disabled** rows, whose 55%-opacity borders land near 236 — the screen's own
content hiding it from its own measurement. Threshold now 244.

**This is the Phase 03 lesson in a new place.** That phase found three
reference rows were glyph edges; this one found the detector blind to a real
block class. Both are the instrument being wrong while reporting confidently.

---

## G5 — Four reference rows were missing from the Alarms block table

**Medium.**

The table listed card 1 top/bottom, cards 2/3/4 tops and card 4 bottom — but
not cards 2 and 3 bottoms. With the matcher consuming each detected edge, the
unlisted card-2 bottom was claimed by *card 3's top* reference, reporting
−9.7 pt on a block that is actually +3.6.

A missing reference row does not merely go unmeasured: it corrupts the row
after it.

**Applied.** Both bottoms added. Cards 1–3 now read −0.0 / −1.0 / +0.2 / +2.1
/ +3.6.

---

## L1 — The interactive simulator pass did not happen, and is not claimed

**Low.**

`CLAUDE.md` asks for the simulator-control tools to confirm controls work.
`flutter build ios --simulator` fails on this machine with an opaque Xcode
status 255 (`flutter drive`, which `tool/capture.sh` uses, builds and runs
fine), and taps sent to the booted simulator did not reach the app.

**Applied as a report, not a workaround.** The evidence for Phase 04's
behaviour is 63 widget tests — navigation both ways, writes, deletes,
toggles, RTL, 2× text — plus four verified captures. **No claim is made that
any control was exercised by hand on a device.** The build failure is written
up in the post-review for a later phase to chase.

---

## Summary

| ID | Severity | Outcome |
|---|---|---|
| G1 | High | Applied — alarm latched while the route pops |
| G2 | Medium | **Invalid** — sole writer, keyed rebuild |
| G3 | Medium | **Invalid** — tested, not reachable, idempotent |
| G4 | High | Applied — hairline detection, twice |
| G5 | Medium | Applied — two missing reference rows |
| L1 | Low | Applied — reported, not papered over |

2 High, 3 Medium, 1 Low. Four applied, **two marked invalid with a reason and
a test**, none deferred.

# Phase 04 — full-project review

Across the whole tree, not only this phase's files.

---

## P1 — `SceneHeader.bandHeight` defaulted to one screen's measurement

**High. Applied.**

The default was `188.4` — Home's band. Alarms measures 148.6 and Add/Edit
112.1. Both Phase 04 screens took the default and the first capture read
**+39.8 pt** on the hero, displacing every block below it.

The parameter is now **required**. Making it required immediately surfaced
the other two callers: `home_screen.dart` (correct at 188.4, now explicit)
and `stats_screen.dart`, which was silently carrying Home's number and now
carries it with a comment saying Phase 08 must measure it.

**This is the third time a Home constant has been found standing in for a
per-screen measurement**, after Phase 03's `SceneHeader` overlap bug. The
pattern is the finding: a design-system widget whose default is one screen's
measurement will be wrong on every other screen, silently, and the compiler
cannot help while a default exists.

`MeadowFooter.height` was the same shape — 65.2 is Home's, Alarms is 52.2,
Add/Edit 59.1 — and the too-tall band is why the fourth alarm card fell off
the fold. It now takes a `height` with Home's as the default; **it is not
required**, because unlike the hero band a footer that is slightly tall is
cosmetic rather than displacing. That asymmetry is deliberate and recorded.

---

## P2 — `SceneHeader.overlap` was a dead parameter kept "for callers"

**Medium. Applied.**

Phase 03 fixed the overlap bug and kept the parameter with the comment "Kept
for callers". Nothing in `lib/`, `test/` or `integration_test/` passes it —
verified by grep. It was a 11.1 pt number sitting in the constructor of the
widget whose misreading of that exact number caused Phase 03's defect.

A dead parameter carrying a discredited number is an invitation to use it.
Removed.

---

## P3 — Phase 03's P4 (the `_nearest` matcher) is decided

**Decided, as the handoff asked, on screens that pass.**

Phase 03 recorded that `_nearest` snapped each reference block to the closest
detected edge, so a displaced layout matched several blocks to one edge and
overstated the damage. It deliberately did not change it — tuning the
instrument while 13 blocks were red would have been fitting it to the result.

**Decision: an edge is consumed by the first block that claims it.** Each
reference block is now answered by a distinct edge or by none, so a count of
failures means how many blocks are wrong rather than how many are downstream
of one that is.

**Its limits, stated rather than hidden:**

- Matching is **greedy in table order**, not a global assignment. A
  worse-than-optimal pairing is still possible. A global match would report
  fewer failures for the same pixels, which is the direction a measuring
  instrument should not drift on its own.
- Consuming edges makes the table's **completeness** matter. With card 2's
  bottom missing from the Alarms table, that edge was claimed by card 3's
  *top* reference and reported −9.7 pt on a block that is +3.6. A missing
  reference row no longer merely goes unmeasured — it corrupts the next row.
  Both missing rows were added (self-review #2 G5).

The second point is a real cost of the change and is why the decision was
worth making only on a screen whose blocks mostly pass.

---

## P4 — The comparison tool is still the project's weakest instrument

**High. Partly applied; the rest is named.**

Phase 04 found two separate blindnesses in `compare.dart`, in a tool Phase 03
had just extended from 4 blocks to 14:

1. A **1-px card border** moves a 393-pt row mean by under one unit, so every
   alarm card read `absent` while all four were on screen and correctly
   placed. Fixed with a hairline scan down a text-free column.
2. That fix at `L < 235` still could not see the two **disabled** rows, whose
   55%-opacity borders land near 236. Threshold now 244.

Both reported *the layout is broken* when the truth was *the instrument
cannot see this*. Across three phases this tool has now been wrong about
glyph edges (03), block coverage (03), and two classes of invisible boundary
(04).

**Named, not fixed:** the hairline column is hardcoded at x=360 pt, which is
text-free on Alarms by measurement and on Add/Edit by luck. A screen whose
content sits there will mis-detect. The honest fix is per-screen probe
columns in the block table; it is not done here because inventing a mechanism
for screens that do not exist yet is how the 188.4 default got written.

---

## P5 — `lib/data` coverage held at 86.40%, and that is now load-bearing

**Low. Verified, no action.**

Phase 03 earned 86.40% after finding five providers that were never read by
any test and counted as covered by accident. Phase 04 added two providers
(`alarmsClockProvider`, `alarmEditClockProvider`) and an id factory, all in
`lib/features/`, and the figure is **unchanged at 86.40%** (451/522).

Checked rather than assumed: a phase that adds providers is exactly the shape
of change that re-introduces the accident.

---

## P6 — The simulator build path is broken and the interactive pass did not run

**Medium. Reported, not worked around.**

`flutter build ios --simulator --debug` exits with an opaque Xcode status 255
on this machine. `flutter drive` — which `tool/capture.sh` uses — builds and
runs the same app fine, which is why all four captures are verified.

Taps sent to the booted simulator through the control tools did not reach the
app either.

`CLAUDE.md` says the interaction path "beats guessing" and should be used to
confirm a control actually works. **It was not available this phase, and
nothing in this phase claims a control was exercised by hand.** The evidence
is 63 widget tests and four verified captures. Phase 05 needs a working
device path for the alarm engine and should chase the 255 first.

---

## P7 — The capture driver committed 18.8 MB of raw PNG bytes as a text file

**High. Applied.**

`test_driver/integration_test.dart` wrote **every** `reportData` key to
`docs/visual/<key>/inset.txt`. The integration-test framework adds its own
`screenshots` key holding every captured PNG's bytes, so the driver produced
`docs/visual/screenshots/inset.txt` — a text file containing the decimal byte
values of every screenshot.

**18,821,998 bytes of it are in the Phase 03 commit.** Phase 04's fourth
screen grew the working copy to 23,953,242.

Found at `git status` review before committing, not by any gate: it is not
bundled, so `check_bundle_size.dart` never saw it; it is not Dart, so no
analyzer or test touched it; and `docs/visual/` is exactly where a capture
phase expects new files to appear.

**Applied.** The driver now writes only numeric values, the directory is
removed from the index and disk, and a re-capture confirms it does not come
back while all four screens still verify. The bytes remain in Phase 03's
history object; rewriting `main` to purge them is not something this phase
does unprompted.

---

## Summary

| ID | Severity | Outcome |
|---|---|---|
| P1 | High | Applied — `bandHeight` required; two more callers surfaced |
| P2 | Medium | Applied — dead parameter removed |
| P3 | — | **Decided** (Phase 03's P4), with its limits stated |
| P4 | High | Partly applied; the hardcoded probe column is named |
| P5 | Low | Verified, no action |
| P6 | Medium | Reported; Phase 05 owns it |
| P7 | High | Applied — driver fixed, 18.8 MB removed |

3 High, 2 Medium, 1 Low, 1 decision. All applied or named; none deferred.

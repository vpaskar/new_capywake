# Phase 07 — full-project review

One pass over the whole repository, not just this phase's code. Findings about
earlier phases are the point of it.

**5 findings: 2 High, 2 Medium, 1 Low. All applied, or applied as a recorded
obligation where the work belongs to another phase's screen.**

---

## High

### H1 — Three of the four captured screens fail their own Tier A tables, and two phases reported only the blocks they passed

Running `tool/compare.dart` across every captured screen — which no phase
since 04 appears to have done — gives:

| Screen | Blocks outside tolerance | Worst measured delta | Of which `absent` |
|---|---|---|---|
| Home | 6 | **1.4** | **6** |
| Alarms | 5 | 10.0 | 2 |
| Add/Edit | 8 | 10.5 | 4 |
| Settings | 2 | 4.5 | 1 |

**Home is the serious part of this finding, and it is a reporting failure, not
a layout one.** Every one of its six failures is `absent` — a block the tool
cannot see — and every block it *can* see is within **1.4 pt**. Home is in
good shape.

But Phase 03's tracker row reads: *"Tier A: hero **0.0**, CTA top/bottom
**+0.9**, rail tiles **−1.4**, labels **+1.1**; remaining deviations named
with their deltas in `docs/visual/home/`."* Those four numbers are real and
appear in the output. The other ten rows of the table are not mentioned, and
`docs/visual/home/README.md` records only **Phase 01's** pre-fix deltas — the
post-fix comparison Phase 03 claims to have captured is not in that directory.

Run under **Phase 03's own tool against Phase 03's own committed capture**
(`git show b3b0574:tool/compare.dart`, `docs/visual/home/actual.png`
unmodified since), Home reports **8 blocks outside tolerance, worst 36.2 pt**.

Phase 04's row has the same shape: *"Alarms hero −0.2, cards 1-3
−0.0/−1.0/+0.2/+2.1/+3.6"* — six numbers, all of them passing rows, out of
eleven. Card 4 and the meadow, which fail, are not named. The phase did say
Add/Edit was "the weaker screen", so the omission there was partly declared.

This is the exact failure `compare.dart`'s own `sharedBlocks` comment was
written to prevent: *"Blocks reported for every screen, so a screen cannot
pick the ones it already matches."* The tool refused to let a screen pick its
blocks; the **phase write-ups** picked them anyway.

**Applied, as far as this phase legitimately can.** The tool is fixed (H2
below) so the numbers are honest, every screen's current state is recorded in
this document and in `PHASE_07_POST_REVIEW.md`, and the tracker rows for 03
and 04 are corrected in place. **The remaining real failures — Alarms' card
3/4 drift and meadow, Add/Edit's eight — are not fixed here**: they are other
screens' layout, this phase did not touch them, and fixing another phase's
screen inside this one would be exactly the untested, unreviewed change this
process exists to prevent. They are recorded as owed, with their numbers.

### H2 — `compare.dart` fabricated a delta for a block it had not measured

Settings reported **"group 1 card top −18.7 TIER A FAIL"** for a card sitting
**−2.7** from its mark. Two defects compounding:

1. `_hairlines` scanned **a single column at x=360 pt** — text-free on Alarms,
   where Phase 04 chose it, and **under the hero art** on Settings, where it
   collected dozens of art minima (L≈90–135) and never saw the card edge.
2. `_nearest` then searched **±40 pt** for *something* to match, found the
   hero's edge, and printed a confident number for a position never measured.

The second is worse than the first. A tool that says `absent` is telling the
truth; a tool that says `−18.7` is inventing evidence, and a phase acting on
it would "fix" a layout that was already right.

**Applied.** Three columns merged, paint rejected below L=150, search narrowed
to ±12 pt. Verified against all three prior captures before keeping: no new
failures anywhere, and the false deltas collapsed (Home 36.2 → 1.4,
Add/Edit 31.1 → 10.5).

**Third phase running into Phase 05's rule** — *when a tool reports a failure,
check whether the tool is wrong first* — and the second time in this same
tool, after Phase 04's "a boundary the tool cannot see is reported as a layout
failure it never measured".

---

## Medium

### M1 — `CLAUDE.md` claims a gate that has never existed

`CLAUDE.md:166`, under *"Content integrity — the three screens that will try
to lie"*:

> No numeric literal in a user-facing position in `lib/features/stats/`
> (`tool/check_no_fake_stats.dart` enforces it).

**There is no such file.** `tool/` contains eight scripts and none is it. The
rule it claims to enforce protects the screen `CLAUDE.md` itself calls the
most likely to lie.

Precisely Phase 02's finding about the documented `tool/audit_art.dart`, which
also did not exist, and the same family as Phase 06's twelve dartdocs pointing
at the wrong phases: **a document asserting something about the repository
that the repository does not support.**

**Applied.** The line states the rule as prose and names **Phase 08** as owing
the gate. Not written here: Stats is Phase 08's screen, and a gate written a
phase early against an unbuilt screen is one nobody has run in anger.

### M2 — Nineteen more ported dartdocs name phases that mean other work here

Phase 06's full-project review found twelve and fixed them. A fresh sweep
found **nineteen more** — counted, not estimated: `grep -rn "Phase [0-9]"
lib/` (excluding generated l10n and the ARB) returned **20** lines before this
phase and **1** after, and the survivor is correct. Several name numbers that
do not exist in this project's twenty-phase plan at all:

| File | Said | Reality |
|---|---|---|
| `alarm_dismiss_summary.dart` | "before Phase 37" | there is no Phase 37 |
| `alarm_occurrence.dart` | "Until Phase 34" | no Phase 34 |
| `snooze_service.dart` | "Until Phase 32" | no Phase 32 |
| `notification_service.dart` | "Since Phase 31" | no Phase 31 |
| `alarm_format.dart` | "Until Phase 29" | no Phase 29 |
| `wake_volume_ramp.dart` | "Phase 08 built WakeRamp" | 08 is Stats here |
| `alarm_schedule_service.dart` ×3 | "the Phase 06 alarm engine" | 06 is Ringing; the engine is 05 |
| `user_settings.dart` ×2 | "a Phase 09 screen", "The Phase 09 ReliabilityChecklistService" | 09 is Onboarding; the checklist is **this phase** |
| `reliability_copy_service.dart` | "ARB keys … (added in Phase 06)" | Phase 06 added **zero** ARB keys, by its own tracker row |
| `models/alarm.dart`, `models/wake_mode.dart` ×2, `wake_window_service.dart`, `capy_wake_repository.dart`, `next_alarm.dart` | various | the layer, not a number |

**Applied.** All nineteen now name the **layer** — "the alarm engine", "the
reliability layer", "the legacy" — which cannot go stale when phases
renumber. `grep -rn "Phase [0-9]" lib/` now returns one line, and it is
correct: `stats_screen.dart` naming Phase 08 as the phase that will measure
`05_STATS.png`.

Worth stating plainly: **Phase 06's sweep found 12 of 31.** A grep that found
most of a problem reads exactly like one that found all of it — which is why
this review counted the lines before and after instead of trusting that the
previous pass had finished the job.

---

## Low

### L1 — `AlarmEngine.ringNow` is still called by nothing in `lib/`

Inherited from Phase 06's handover and still true. It exists for the
post-dismiss motion check, which has no phase row.

**Applied as a recorded obligation**, not as code: `UserSettings`
`motionConfirmationEnabled` is now *settable* from this phase's Settings
screen, so the kill switch a user flips has nothing behind it yet. That is
honest — the switch stores a preference the motion layer will read — but it
is the first time the gap is user-visible, so it is carried forward explicitly
in `next.md` rather than left in a review nobody re-reads.

---

## Outcome

5 findings: 2 High, 2 Medium, 1 Low. All applied, with H1's layout half
recorded as owed by the screens that own it rather than fixed blind here.

The finding that matters most is **H1**, and not because of the deltas —
Home's are tiny. It is that two phases wrote down the blocks they passed and
omitted the blocks they failed, in a project whose fidelity contract says *"a
screen is done when the comparison is captured and its deviations are
named"*. The tool was built to stop a screen choosing its blocks. Nothing was
watching the write-ups.

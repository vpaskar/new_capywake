# Phase 08 — full-project review

One pass over the whole repository, not just this phase's code. Findings about
earlier phases are the point of it.

**5 findings: 2 High, 2 Medium, 1 Low. All applied.**

---

## High

### H1 — The gate `CLAUDE.md` has claimed since Phase 00 now exists, and widening it cost nothing

Phase 07's full-project review M1 found `CLAUDE.md` asserting that
`tool/check_no_fake_stats.dart` enforced the no-fake-numbers rule when no such
file existed — the same shape as Phase 02's finding about the documented
`tool/audit_art.dart`. It rewrote the line to call the rule prose and named
Phase 08 as owing the gate.

**Written, tested and wired into validation.** Two things found while doing it
are worth recording:

1. **The rule was scoped too narrowly.** `CLAUDE.md` restricted it to
   `lib/features/stats/`, but "no number the app does not have" is not a
   property of one screen. Run across **all of `lib/features/` — 38 files —
   the gate is already clean**, so the wider scope costs nothing and protects
   Home's next-alarm card, the ringing surface and anything later.
   Default scan path is now `lib/features`.
2. **The gate is measurably blind to the shape most likely to ship.** Three
   mutations were run (`PHASE_08_SELF_REVIEW_1.md` H2). A planted
   `?? '7 h 32 m'` string is caught; a planted **numeric** `?? 6` fallback
   **passes the gate entirely** and is caught only by the widget test.

Point 2 is the part that matters for the project, not just this phase.
`CLAUDE.md` now states the blind spots next to the rule, because a documented
gate invites exactly the belief Phase 07 warned about: *the file exists,
therefore the rule is enforced.* It is enforced by a gate **plus** a test, and
the test is the half that catches the realistic defect.

### H2 — A phase's own block table can be wrong in a way that looks like a layout failure

`compare.dart` reported Stats failing `segment track bottom` by **+4.4** and
`card 1 top` by **−7.9**. Both were artefacts of this phase's block table, not
of the screen:

- The table **named the track and measured the pill** (249.4–280.3). The
  tool's detector finds the track's border, 3 pt outside the pill, so it
  compared the capture's track against the mockup's pill. Measured directly,
  the rendered pill is **30.7 pt against the mockup's 30.9**.
- `card 1 top` is on the **Alarms** segment; the capture renders **Sleep**.
  The block did not exist in the artifact being measured.

Re-measuring the track at both edges: `-1.4` and `+3.5`, both inside
tolerance.

**This is the fourth consecutive phase caught by Phase 05's rule, and the
third inside this same tool** — but it is a new variant worth naming. Phase 04:
a boundary the tool could not see. Phase 07: a block matched to a distant edge.
**Phase 08: the table itself described a different edge than it measured.**

The tool was right, the widget was right, and the table between them was
wrong. Recorded in `docs/visual/tier_a_blocks.md` as a naming hazard:
**a block's name and its value must describe the same edge**, and on a screen
with a selected-state control, the detector will find the container's border
rather than the selection's fill.

---

## Medium

### M1 — Three screens' meadows are one defect, not three

`meadow footer bottom` reports `absent` on Stats. Checked across every
captured screen rather than assumed:

| Screen | Painted grass ends | Nav bar |
|---|---|---|
| home | 694.3 | present |
| alarms | 694.3 | present |
| stats | 694.3 | present |
| settings | 793.0 | absent — pushed route |

**Every tab ends at exactly 694.3; the pushed route reaches the screen
bottom.** The nav bar occupies 98.7 pt where the mockup allots 79.9.

Phase 07 recorded Alarms' meadow as failing **+10.0** and Home's as `absent`,
and treated them as separate per-screen facts owed by their own phases. They
are **one fact**: `CapyNavBar` is taller than the mockup's tab bar, and every
meadow above it is pushed up by the same amount.

**Applied as a correction to how it is recorded**, not as a code change —
changing `CapyNavBar` from inside the Stats phase would move three screens
this phase has not measured, which is the untested blind edit the process
exists to prevent. `next.md` and the tracker now carry it as a single
shell-geometry item with the measurement, instead of three screen-local ones.

### M2 — `MeadowFooter` paints roughly twice the grass the mockups draw

Independent of M1 and found while checking it. The widget box heights are
correct per screen, but `_MeadowPainter` fills far more of the box than the
mockup inks: the mockup's Stats meadow is **29.1 pt** of painted grass
(scalloped top 744.0–764.3 down to a flat 773.1), the capture's is **60.6**.

No Tier A block measures painted extent, so no screen has ever failed on it —
which is why four phases have shipped past it. Recorded in
`docs/visual/asset_gaps.md` with the numbers.

---

## Low

### L1 — `SceneHeader` draws a flat-topped sheet; every mockup draws a cloud

Measured on `05_STATS.png` while deriving the hero band: the cream shape's
top is a **scalloped cloud with lobes rising ~65 pt above its flat top**, and
"Statistics" sits 6.7 pt *above* that flat top, inside a lobe.
`SceneHeader` renders `BorderRadius.vertical(top: 28)`.

The consequence is small but real and is now declared rather than absorbed:
Stats' title cannot start where the mockup's does, so `titleTopGap` and
`titleToSwitcherGap` are both **0.0** — the entire spacing budget above the
switcher is consumed by the title's own line box, and the track still lands
1.4 pt low.

This affects all five screens, not Stats. Recorded in `asset_gaps.md` as a
structural art gap, with the Stats arithmetic in
`docs/visual/stats/README.md`.

---

## Outcome

5 findings, all applied.

The one to carry forward is **H1's second half**. Phase 07's finding was that
a document claimed a gate that did not exist. The obvious fix is to write the
file — and a phase that stopped there would have left `CLAUDE.md` making a
*different* false claim: that the rule is enforced. It is enforced against the
easy shape and blind to the realistic one, which is now written next to the
rule and asserted in a test.

**A gate that exists is not the same as a rule that holds**, and the only way
to tell the difference was to mutate it and count.

# Phase 07 — adversarial pre-review

Written **before any code**, against `PHASE_07_PLAN.md` as first drafted.
Every finding is applied or marked invalid with a one-line reason. There is no
"deferred".

Method: read the plan as an adversary looking for (a) a claim the plan cannot
support, (b) a defect this project has already shipped once, (c) a number that
is an inference wearing a measurement's clothes, (d) a safety rule the plan
quietly weakens.

**19 findings: 3 High, 8 Medium, 8 Low.**

---

## High

### H1 — The plan measures Settings' toggle and then plans to ship Home's

§1.4 measures the Settings toggle at **44.3 × 25.0 pt**. §7 lists no change to
`CapyToggle`, which is a hard-coded **59.6 × 34.6** with no size parameter and
eight call sites. The plan therefore measures a number and ships a different
one — a **15.3 pt width error**, nearly four times Tier A tolerance, on a
control the mockup draws twice.

This is the **fourth** instance of the same defect class in this project:

| Phase | Shared default | Per-screen truth |
|---|---|---|
| 03 | `SceneHeader` card inside the art `Stack` | every hero band 11.1 pt short |
| 04 | `SceneHeader.bandHeight` = 188.4 (Home's) | Alarms 148.6, Add/Edit 112.1 |
| 04 | `MeadowFooter.height` = 65.2 (Home's) | Alarms 52.2, Add/Edit 59.1 |
| **07** | **`CapyToggle` 59.6 × 34.6 (Home's)** | **Settings 44.3 × 25.0** |

Phase 04's fix — make the parameter **required** — is what exposed Stats
silently carrying Home's number. The same move is available here and nothing in
the plan takes it.

**Applied.** Plan §9 rewritten: `CapyToggle` takes a **required `trackSize`**.
Every existing call site must then state its own measurement, which is the
point. `minTapTarget` stays 44 pt independent of track size, so a smaller track
never yields a smaller target.

**Also applied:** the plan must re-measure the Alarms toggle, because
`tier_a_blocks.md` records "30.5 pt tall" while this phase's green-anchor method
reads 22.6 on the same mockup. One of the two is wrong and a phase that notices
a contradiction and leaves it is the behaviour this project keeps finding.

### H2 — "Alarm Notifications" as a toggle is a user-operable way to silence every alarm

§4's table ships the mockup's **Alarm Notifications** toggle. The plan never
says what it writes to.

There are only two possibilities and both are defects:

1. **It maps to the OS notification permission.** A toggle cannot revoke an OS
   permission, so "off" must mean a local flag that suppresses scheduling —
   i.e. a switch, inside a settings screen, that **stops every alarm from
   ringing**, with no statement of that consequence. `CLAUDE.md` classes
   locking a user out of silencing their alarm as a High finding; this is the
   same safety rule one step earlier — locking them out of it *ringing*.
2. **It maps to nothing.** Then it is a dead control, which §4's own rule
   forbids more strictly than a dead row, because a switch that moves and
   changes nothing is worse than a chevron that opens nothing.

The mockup is not evidence for either — it is an illustration drawn before the
product had an alarm engine.

**Applied.** Plan §4.1 added: the row becomes a **status row**, not a switch.
It reads live `PermissionState`, states plainly whether alarm notifications are
allowed, and its action grants (or opens OS settings when permanently denied).
**It can grant, never revoke.** Revocation stays in the OS, where the OS states
the consequence. The group keeps its mockup position; the deviation is declared
in §8.

### H3 — The plan claims Tier A on blocks its own §4 makes incomparable

§8's first draft claimed the full block table while §4 cut four rows, replaced
one and added a fifth group. Every block below Appearance is then a different
distance down the screen **by design**, and a ±4 pt claim against the mockup
for those blocks is a claim that cannot be true and cannot be made honest by
measuring more carefully.

`CLAUDE.md`: *"A screen is done when the comparison is captured and its
deviations are named — not when it functions."* Naming a deviation requires
saying which blocks are and are not comparable **before** the capture, or the
capture becomes a negotiation.

**Applied.** §8 rewritten into two explicit lists: six blocks claimed
(everything from the header to Group 2's top, which the row cuts cannot move,
plus the gutter and card width), and the rest **not claimed with the reason
stated**. The reason is §4, not layout error, and `docs/visual/settings/` must
say so.

---

## Medium

### M1 — `CapyToggle` has no `trackSize`; making it required is a breaking change the plan does not budget

Covered by H1's fix, but the cost is its own finding: eight call sites across
Home, Alarms, Add/Edit and the design tests must each supply a number, and two
of those numbers are not currently measured anywhere (Add/Edit's toggles,
`alarm_form_rows.dart:114`).

**Applied.** §9 states the breaking change explicitly. Where a call site has no
measured value, it passes `CapyToggle.homeTrackSize` **named as an inheritance,
not a measurement**, and that inheritance is listed in the post-review as an
open measurement — the same treatment Phase 04 gave Stats.

### M2 — The walkthrough row is a dead row unless the plan says what it opens

§2.3's first draft shipped "the entry point", with onboarding in Phase 09.
An entry point to a flow that does not exist is precisely the dead row
`CLAUDE.md` forbids, and the plan's own §4 cuts App Icon for exactly that.

**Applied.** §5 added: the row opens a real screen built from
`OnboardingStatus`, replayable, honest about what is not yet configurable —
**or the row is cut**. A cut row is an acceptable outcome; a dead row is not.

**Evidence the design is right:** `OnboardingStatus`'s own dartdoc already
anticipates it — *"The Settings replay keeps the shell alive underneath instead
(it is pushed, not navigated to)"*. The ported domain assumed this screen.

### M3 — The sleep-boundary restoration is mentioned but not discharged or refused

The plan's first draft noted the obligation without saying whether this phase
discharges it. `next.md` and the tracker both put it on Phase 07. Leaving it
ambiguous is how an obligation gets lost — and it was already weakened once
deliberately (`PHASE_02_SELF_REVIEW_1.md` F5).

**Applied.** §6 states plainly: **`package:health` does not land in this
phase**, the test stays at `at most one`, and the obligation moves to Phase 08
with a tracker edit. Stated, not dropped.

### M4 — "Registered 70–100 tests" with no basis

Phase 06 registered 55–80 and measured 93; Phase 05 registered 25–40 and
measured 87. Both restated the miss with a reason, which is the required
behaviour — but a band drawn from nothing is not a prediction, it is a range
wide enough to be right.

**Applied.** §10 keeps the band but it is now decomposed: ~8 per row type × 4,
~12 checklist, ~10 gate (incl. the mutation test), ~8 row-set integrity, ~6
RTL/scale, ~6 ringing-over-settings, ~10 sheets, ~12 controller. The band is
the sum, so a miss can be attributed to a component rather than to vagueness.

### M5 — No test that the ringing surface still covers a *pushed* Settings route

`next.md` names this as Phase 06's sharpest edge: `RingingHost` lives in
`MaterialApp.builder`, above the router, and Phase 06 shipped a version where
the escape **threw instead of opening** because of it. Settings is the first
screen pushed on the **root** navigator since that was fixed.

The plan's first draft had no such test.

**Applied.** §11 adds it: with Settings pushed, a ring covers it **and** the
escape sheet opens. Both halves — Phase 06's bug passed every test that only
checked the first.

### M6 — `compare.dart` has no `settings` entry and `_topInsetPt` reads a file the capture must write

`blocksFor()` calls `exit(2)` for an unknown screen — correct, but it means the
tool cannot run until the table is added, and `_topInsetPt` reads
`docs/visual/settings/inset.txt`, which only `tool/capture.sh` writes. A phase
that measures first and captures last discovers this at the end.

**Applied.** §7 lists both edits, and the capture is run **before** the final
review passes rather than after, so a tooling gap surfaces while there is time
to fix it.

### M7 — The group-header band's 28.2 pt is taken from three groups and contradicted by the fourth

§1.2 records G1 at **31.4** and G2/G3/G4 at **28.2**, and the plan takes 28.2.
The reason given — the hero art's soft edge overlapping G1 — is plausible but
it is an **explanation offered for a disagreement, not a measurement of G1**.
Phase 03 lost a screen to exactly this shape of reasoning.

**Applied.** The plan states 28.2 as the value **and** names G1's 31.4 as
unexplained-by-measurement. The capture settles it: if the shipped G1 band
lands at 28.2 and the mockup's reads 31.4, the 3.2 pt is inside tolerance and
the explanation held; if it lands outside, the explanation was wrong and the
post-review says so.

### M8 — Two stale ported dartdoc references, same class as Phase 06's twelve

Phase 06's full-project review found 12 ported dartdocs naming the legacy's
phase numbers and fixed all of them. Reading the domain for this phase found
two more it missed, both in files this phase consumes:

- `lib/core/models/user_settings.dart:17` — *"a Phase 09 screen can iterate
  values"* and `:41` — *"The Phase 09 `ReliabilityChecklistService` writes
  here."* Phase 09 is **Onboarding** here; the checklist is **Phase 07**.
- `lib/core/reliability/reliability_copy_service.dart:31` — *"The ARB keys it
  consumes (added in Phase 06)"*. Phase 06 added **zero** ARB keys (its own
  tracker row says so); these keys came with the Phase 02 port.

**Applied.** Fixed in this phase, naming the **layer** not a number, per
`CLAUDE.md`. Recorded here because it means Phase 06's sweep was incomplete —
a finding about a previous phase's finding.

---

## Low

### L1 — `MeadowFooter.height` for Settings is derived, not measured
853 − 770.3 = **82.7**, which assumes the meadow runs to the exact bottom of
the mockup. **Applied:** stated as an inference in §1.6; the capture tests it.

### L2 — The hero band's 103.9 upper edge is inherited from Home
§1 cross-checks it against the art's fade-in (≈103–104) but does not derive it
independently. **Applied:** the method column now says "inherited, cross-checked,
not independently derived".

### L3 — Row heights are divisions, not measurements
≈39.1 and ≈37.5 come from dividing a span by a row count. Phase 03's tile size
was wrong by 27 % for exactly this reason. **Applied:** both marked inference
in §1.6 and neither is used as a layout constant; rows size to content.

### L4 — "About CapyWake — v1.0.0" implies a version source the plan does not name
**Applied:** the version comes from `package_info_plus` if already a dependency,
otherwise from `pubspec.yaml` at build time. **A hard-coded "1.0.0" is a fake
value on a screen `CLAUDE.md` lists as one that will try to lie**, and is
forbidden here.

### L5 — The theme tiles are art, and the plan does not check they exist
Three illustrated tiles (sunrise / sunset / night). §1.4 measures them in the
mockup; nothing confirms the asset package has them. **Applied:** checked during
implementation; if absent it is an **asset gap**, reported in the session and
appended to `docs/visual/asset_gaps.md` per `CLAUDE.md`, not papered over.

### L6 — Three theme tiles vs `ThemeModePreference`'s system/light/dark
The mockup's tiles read as light / sunset / dark, but the enum is
**system / light / dark** and `settingsThemeSystem` exists. A sunset tile would
be a fourth theme that does not exist. **Applied:** the three tiles map to the
three enum values; the middle tile is **System**, and the tile art is chosen to
read as "follows your phone" rather than inventing a sunset theme.

### L7 — No stated behaviour for the back affordance when Settings is deep
The checklist and walkthrough are pushed **under** Settings, itself pushed on
the root navigator. **Applied:** each sub-route pops to Settings; Settings pops
to the tab it was opened from. Asserted in a test, because `go_router` nesting
is where this breaks silently.

### L8 — The plan does not say the screen scrolls
The content is ~770 pt tall in a 852 pt viewport **before** a fifth group is
added, so it must scroll. §8's claim set and the capture both depend on it.
**Applied:** §8 states the capture is taken at scroll offset 0 and that blocks
below the fold are offset-dependent.

---

## Outcome

19 findings — **3 High, 8 Medium, 8 Low. All 19 applied; none invalid, none
deferred.** `PHASE_07_PLAN.md` is revised; the revisions are marked ⟲.

The two findings that change what ships rather than how it is measured are
**H2** (the Alarm Notifications toggle becomes a status row — a switch that
silences every alarm is a safety defect, whatever the mockup draws) and **H1**
(`CapyToggle.trackSize` becomes required — the fourth time a shared default has
stood in for a per-screen measurement, and the second time the fix is to make
the parameter mandatory so the other call sites have to confess).

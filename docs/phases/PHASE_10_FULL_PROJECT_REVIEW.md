# Phase 10 — full-project review

A pass beyond this phase's new files, at what Phase 10 touched or revealed across
the project. In the tradition of every phase since 03, the most valuable output
is a thing an earlier phase (or a handoff) wrote down that turns out not to hold.

**4 findings: 0 High, 2 Medium, 2 Low. All applied.**

---

## The headline: the ARB estimate was wrong by an order of magnitude, the right way

The pre-review (H1) corrected the plan's "few, possibly zero" ARB keys to a
registered **+10 to +14**. Measurement during implementation corrected it again,
downward: the real delta is **+2** (`settingsPuzzleEntryLabel`,
`settingsPuzzleEntryDescription`). Nearly the entire puzzle, chooser, onboarding
and **per-alarm** vocabulary was already ported in all ten locales — including
`alarmPuzzleSectionLabel`, `alarmPuzzleUseDefaultsLabel/Description`,
`alarmPuzzleCustomDescription`, the onboarding step content, and the dismiss-
method labels (`alarmDismissMethodNormal/Puzzle/Hold`). The two surfaces with no
ported string were the Settings *entry row* and nothing else.

This is the restate-don't-pass discipline working in both directions: the plan
was optimistic, the pre-review over-corrected, and the measurement settled it at
+2 — stated here rather than quietly shipped. Registered expected: +10–14.
Actual: **+2**. The reason is good news (the port was thorough), but the number
is what matters and it is written down.

---

## Medium

### M1 — Three ported onboarding strings remain unused, and this must be said explicitly

`onboardingTryGame` ("Try it"), `onboardingPracticeNote`, and
`onboardingPracticeRetry` are **still unused** after Phase 10. They were written
for a *playable* practice puzzle — a "Try it" button on a live mini-game. Phase
10's onboarding "try" step is a **static preview** of three spoken examples
(SR1 L2: no `puzzle_generator` import, no scoring), because a playable mini-game
is the game engine, which is Phases 11–17.

Phase 09 left its puzzle strings unused and only *implicitly* named them Phase
10's domain, which cost a guard-test interaction (M2). This review states it
outright so the next phase is not surprised: **the playable-practice trio is
unused on purpose, and a playable onboarding demo — if one is ever wanted — is a
games-phase concern, not a chooser concern.** `docs/sessions/next.md` records
this.

**Applied.** No code change — using them would mean building a playable demo,
which is out of scope and would overreach into Phases 11–17. Documented so the
unused state is a decision, not an oversight. No guard test is added (unlike
Phase 09's, which asserted the welcome did *not* render puzzle strings): these
three are simply not referenced, and `check_arb` does not fail on an unused key.

### M2 — Add/Edit now draws six cards; the "five cards" test name is stale but correct

`03_ADD_EDIT_ALARM.png` (the primary) draws five cards; the handoff's
`03_ALARM_DISMISS_METHOD_DETAIL.png` adds a sixth (dismiss method). The existing
`'shows the five cards the mockup draws'` test still passes — it asserts specific
widgets, not a count — but its name now undercounts. SR1 L1 noted this.

**Applied.** The dismiss-method card is owned by its own test file
(`dismiss_method_section_test.dart`, 8 tests including the SR1 H1
`holdToDismiss` pin). The existing test's name is left as-is rather than renamed
mid-phase — renaming a passing test another phase wrote risks obscuring its
history — but the sixth card is documented here and in
`docs/visual/puzzle_chooser/` as a deliberate handoff addition, not drift. A
later phase touching that test should update its name.

---

## Low

### L1 — The Settings puzzle entry sits under "Preferences", not its own "Wake puzzle" group

The chooser entry row was first placed in its own `SettingsGroup` headed
`settingsPuzzleHeading` ("Wake puzzle") — which collided with the row's own
label (also "Wake puzzle"), making `find.text` ambiguous and breaking a Settings
test with `Iterable.single: Too many elements`. Fixed by placing the row under
the ported `settingsPreferencesHeading` ("Preferences") group instead — no new
ARB key, no collision, and arguably the more correct grouping (the puzzle chooser
is a preference, alongside sound/snooze/appearance).

**Applied.** The collision was a real latent bug (two identical visible strings),
caught by the existing Settings test, not invented. Resolved by reusing a ported
heading. Recorded because the first instinct (a dedicated group) read better on
paper and was wrong in the tree.

### L2 — `check_bundle_size` still cannot see the three native plugins (carried forward)

Unchanged from Phase 05/08: the bundle gate measures `assets/` only. Phase 10
adds no native dependency (no `pubspec.yaml` change), so the gate's blind spot is
not widened, but it remains. Noted, not this phase's to fix.

---

## What held

- `grep -rn "Phase [0-9]" lib/ --include="*.dart"` excl. generated: **0**. No new
  doc comment names a phase number (the layer is named instead).
- The ported `puzzleSettings*` vocabulary is now wired to a real surface for the
  first time — before Phase 10 every key was read by nothing.
- The push-only onboarding redirect (Phase 09's fix) holds across the new
  multi-step flow: verified on the iPhone 18 Pro (the CTA lands on Add Alarm, not
  Home).
- `AlarmPuzzleOverride`'s field-by-field `null`-follows-default contract is
  honoured by the per-alarm section, which delegates every transition to the
  domain (`withDismissMethod`, `withPuzzleCustomisation`) rather than hand-rolling
  state.

---

## Outcome

4 findings, all applied, none invalid.

The headline is the ARB count: registered +10–14, measured **+2**, because the
port was far more complete than the plan or pre-review assumed — restated, not
hidden. M1 (the unused playable-practice strings) is the Phase-09-shaped finding:
an ambiguous "leave it for later" is what cost Phase 09 a guard-test tangle, so
this phase says outright that those three are unused on purpose and why.

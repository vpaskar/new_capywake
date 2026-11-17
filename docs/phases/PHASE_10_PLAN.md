# Phase 10 — Puzzle chooser and the ten existing puzzle types

## Objective

Give the user a way to configure the wake puzzle. The whole puzzle **domain**
is ported and tested (`lib/core/puzzle/`, `PuzzleSettings`,
`AlarmPuzzleOverride`, ten `PuzzleType`s, selector, generator, easing,
validator). The whole puzzle **vocabulary** is ported in 10 locales
(~28 `puzzleSettings*` keys, all ten `puzzleType*` labels, difficulty, escape,
tolerance, and nine `onboarding*` puzzle/strictness keys). What is missing is
**any UI that writes it**: `savePuzzleSettings`, the singleton table and
`puzzleSettingsStreamProvider` exist and are *read* by the ringing surface, but
nothing in the app lets the user change the defaults. Every alarm wakes someone
with `PuzzleSettings.defaults()` forever.

Phase 10 closes that across **three surfaces** (owner-confirmed scope,
2026-11-17):

1. **Puzzle chooser** — an app-wide Puzzle Settings screen, pushed from
   Settings. The core deliverable (`10_PUZZLE_CHOOSER.png`).
2. **Onboarding puzzle + strictness steps** — wire the two ported onboarding
   steps into the first-run flow (`09_ONBOARDING_PUZZLE_TRY.png`,
   `09_ONBOARDING_STRICTNESS.png`). Phase 09 shipped the welcome only and named
   these Phase 10's domain; a guard test asserts the welcome does not render
   their strings, to be updated deliberately.
3. **Per-alarm dismiss method** — an Add/Edit section to pick Tap vs Puzzle and
   carry a per-alarm override, with a summary that links to the chooser
   (`03_ALARM_DISMISS_METHOD_DETAIL.png`). Our Add/Edit currently exposes **no**
   dismiss-method UI at all.

The ten puzzle **games themselves are Phases 11–17 and are out of scope.** The
onboarding "try a puzzle" step is explicitly a *practice example*, not the game
engine (handoff `SCREENS_AND_BEHAVIOR.md`): a static matching-pairs demo, no
generator wiring, no scoring.

## Reference screenshots and the fidelity decision

New references, copied into `reference/01_REFERENCES/` from the owner's
`CapyWake_Puzzle_Chooser_Onboarding_Handoff` (2026-11-17):

| File | Surface | Pixel size |
|---|---|---|
| `screens/primary/10_PUZZLE_CHOOSER.png` | Chooser | **378×1161** |
| `screens/primary/09_ONBOARDING_PUZZLE_TRY.png` | Onboarding practice | **382×930** |
| `screens/primary/09_ONBOARDING_STRICTNESS.png` | Onboarding strictness | **384×931** |
| `screens/secondary/03_ALARM_DISMISS_METHOD_DETAIL.png` | Add/Edit component | 565×307 |
| `source/ORIGINAL_PUZZLE_STORYBOARD.png` | Combined source | 1199×1312 |

**Tier A binds nothing on any Phase 10 surface, and this is measured, not
assumed.** The Tier A contract (`CLAUDE.md`) requires the mockup at
**851×1847 px = 393×852 pt** and compares captures at that exact viewport to
±4 pt. None of these crops is that geometry: the chooser is a 378-px-wide tall
scroll crop at roughly 1×, not 2.166×; the onboarding steps are 382/384 wide;
the dismiss detail is a 565×307 component panel. The handoff's own
`README_START_HERE.md` says so outright — *"cropped from one existing combined
mockup; they are not independent native-resolution screenshots… do not
stretch."* The handoff text calls them "Tier A layout references," but the
repo's fidelity contract is canonical and its tolerance cannot be evaluated
against a non-native crop.

So these are **structural/layout references**, not Tier A geometry. Phase 10 is
held — exactly as Phase 06 (ringing) and Phase 09 (onboarding) were — to:
tokens, the 44 pt tap-target floor, RTL (`EdgeInsetsDirectional`, `start`/`end`),
large-text reflow (every surface scrolls), no-overpromise copy, and the puzzle
safety rules below. Deviations from the layout references are **named**, by
section, in `docs/visual/puzzle_chooser/`, `docs/visual/onboarding/` and
`docs/visual/_evidence/`. A screen is "done" when its deviations are named, not
when every block matches — there are no blocks to match.

**Not added to `integration_test/capture_test.dart`.** `compare.dart`'s
`blocksFor()` `exit(2)`s on a screen with no block table, and there is no block
table because Tier A binds nothing. A device run on the iPhone 18 Pro is the
evidence instead (see Validation).

## The three domain conflicts the mockups carry

The art was drawn against a simplified mental model. Our ported domain is the
source of truth; where they disagree, the domain wins and the deviation is
logged.

### C1 — Escape strictness is 2-value, the mockup draws 3 (owner decision: keep domain)

The chooser and the strictness step both draw **Always / After 1 min / Never**,
and the chooser's "Never" card reads *"The alarm can only be dismissed by
solving the puzzles."* Our domain's `PuzzleEscapeStrictness` has exactly two
values — `confirm` and `confirmAndHold` — and **no "off"**, by safety-rule
design: the escape is always reachable (`CLAUDE.md`: "Never ship a puzzle
without a reachable emergency escape… always a High finding"). The handoff's own
`AGENT_PROMPT.md` even says *"'Never' does not eliminate emergency/accessible
alarm stopping."* So the mockup's "Never" is **misleading art**.

**Resolution (owner-confirmed): keep the domain, adapt the labels.** Render our
real two-value escape-strictness control with the ported honest copy
(`puzzleSettingsEscapeConfirm` = "One confirmation", `puzzleSettingsEscapeHold`
= "Confirm, then hold", `puzzleSettingsEscapeExplanation` = "You can always stop
the alarm without solving. This only sets how deliberate that has to be."). No
"Never". No control that removes the escape. This is logged as a named
deviation; it is a safety requirement, not a near-miss.

### C2 — "After 1 min" conflates strictness with tolerance

The mockup's middle escape segment ("After 1 min") blends escape *strictness*
(`PuzzleEscapeStrictness`) with the *tolerance* threshold
(`toleratedWrongAnswers`) — two distinct, separately persisted domain fields,
each with its own ported ARB (`puzzleSettingsToleranceLabel`/`Value`/
`Explanation`/`Sooner`/`Later`). Phase 10 renders them as **two controls**: the
escape-strictness segmented control (C1) and a separate tolerance stepper, as
the legacy `PuzzleSettingsFields` did. The onboarding strictness step offers the
two real strictness values; the "After 1 minute" radio's *time* framing is not
in our model and is dropped — the ported `onboardingStrictness*` strings are
used, and if they are time-framed the deviation is logged and the honest
strictness copy is preferred.

### C3 — Six sample cards → ten real types; "Shake" is not a dismiss method

The chooser draws six example cards (Memory/Logic/Pattern/Match/Sort/Find It)
and the dismiss detail draws a **Shake** segment. The handoff is explicit: render
the **actual ten** puzzle types with their real localized names and icons, and
implement **only** dismissal modes the app supports. Our `DismissMethod` enum is
`normalButton` / `hold` / `puzzle` — **there is no Shake**. The per-alarm
dismiss-method control therefore offers **Tap (`normalButton`) / Puzzle
(`puzzle`)** only. `hold` is a third supported value but has no mockup segment
and no current UI; it is left as-is (not surfaced this phase) unless the
pre-review finds it already reachable. No "Shake". The ten type cards use their
ported labels (`puzzleTypeArithmetic` … `puzzleTypeShapeRotation`) and the
reference icon library (`math`, `numbers`, `operators`, `number_blocks`,
`shapes`, `shuffle`, `memory_cards`, `color_grid`, `matching`,
`question_cards` — all present).

## Asset-to-mockup mapping

No new art is generated (Tier B rule). The chooser is a settings list, not a
puzzle-playing surface, so it needs **type icons**, not shape primitives (those
belong to the games engine, Phases 11–17). Mapping (candidate icons from
`reference/02_ASSETS/asset_library/icons/`, finalized against the art audit in
implementation):

| Type | Candidate icon |
|---|---|
| arithmetic | `math.png` |
| sequenceNext | `numbers.png` / `number_blocks.png` |
| missingOperator | `operators.png` |
| compareValues | `graph.png` / `numbers.png` |
| oddOneOutNumeric | `shuffle.png` / `shapes.png` |
| digitRecall | `number_blocks.png` / `memory_cards.png` |
| digitRecallReversed | `shuffle.png` / `flip_cards.png` |
| gridPatternRecall | `color_grid.png` / `color_dots.png` |
| spotTheChange | `matching.png` / `question_cards.png` |
| shapeRotation | `shapes.png` |

Hero scenery for the chooser/onboarding: the capybara-with-puzzle-piece hero is
**Tier B illustration** that may not exist as a supplied cutout. If it does not,
the nearest supplied mascot/scene is substituted and **logged by name** in
`docs/visual/asset_gaps.md` — never generated, never claimed as the original.
Every imported asset (if any new one is imported) passes
`lib/design/art_audit.dart` via `tool/import_art.dart`. If no suitable hero
cutout exists, the chooser uses an existing `SceneCrop`, logged.

## Architecture / what lands where

**All chooser/onboarding UI is a fresh view against our tokens.** The legacy's
`puzzle_settings_fields.dart` / `puzzle_type_picker.dart` import Flutter → **not
ported**. Their *structure and per-field callback shape* are a validated
reference, rebuilt fresh.

### New / changed `lib/` files (expected)

- `lib/features/puzzle/puzzle_chooser_screen.dart` — the pushed Puzzle Settings
  screen (Scaffold, `SceneHeader`, scroll body).
- `lib/features/puzzle/puzzle_settings_fields.dart` — the shared composite of
  five controls (type grid, difficulty, task count, escape strictness,
  tolerance), per-field callbacks, hosted by the chooser and the per-alarm
  override and the onboarding steps, so one concept has one shape.
- `lib/features/puzzle/puzzle_type_grid.dart` — the 2-column selectable type
  cards, grouped spoken/visual, at-least-one-stays-on rule, screen-reader
  accessibility label per card.
- `lib/features/puzzle/puzzle_settings_controller.dart` — writes
  `savePuzzleSettings` through the repository; per-field setters that fold the
  current settings and persist.
- `lib/features/onboarding/steps/` — the stepped flow:
  `onboarding_flow.dart` (progress dots + back + step routing),
  `puzzle_try_step.dart` (static matching-pairs practice demo),
  `strictness_step.dart` (strictness radio cards). The current single welcome
  becomes step 1 of the flow.
- `lib/features/alarms/edit/dismiss_method_section.dart` — the Tap/Puzzle
  segmented control, follow-defaults switch, and summary card linking to the
  chooser; writes `dismissMethod` + `puzzleOverride` on the draft.
- Providers: `puzzleSettingsControllerProvider`; the chooser/onboarding read
  `puzzleSettingsStreamProvider` (already exists).

### What is NOT built

- No puzzle game engine, no generator wiring into the practice demo (static art
  only), no scoring/streaks/bests anywhere (safety rule).
- No Shake dismiss method, no removable escape, no new backend state.
- No `package:health` / sleep-boundary restoration (still owed, see below — if
  it does not land, say so explicitly, as Phases 07/08/09 did).

## Dependencies

**None added.** `pubspec.yaml` is unchanged — everything needed
(Riverpod 3, go_router, intl, Drift) is present. Hard rule: no dependency not
listed in the current phase file.

## l10n

**Expected new ARB keys: few, possibly zero.** The entire chooser + onboarding
vocabulary is already ported in 10 locales. Candidates that may be missing and
would be added (×10 locales, `check_arb.dart` gate): a per-alarm
"follow defaults vs custom" switch label/subtitle if not already present
(`alarmPuzzleFollowDefaults*`), a dismiss-method section header/subtitle, and
the Tap/Puzzle segment labels. Exact need is measured in the pre-review and
registered there; if measurement disagrees with the estimate it is **restated,
not quietly passed** (the project's standing discipline). Any new key is added
to all ten ARBs together or the gate fails.

## Scope / exclusions

**In:** the three surfaces above; wiring `savePuzzleSettings`; the ten real
types; difficulty/count/escape/tolerance controls; onboarding stepped flow with
the two new steps; per-alarm Tap/Puzzle override with summary.

**Out:** the ten games (11–17); the practice demo as a real mini-game; Shake;
sleep/health; `CapyNavBar`/`MeadowFooter`/`SceneHeader` carried-forward defects
(a dedicated phase owns those); Alarms/Add-Edit's existing Tier A failures;
`AlarmEngine.ringNow` wiring.

## Tests

Mirror `lib/` under `test/`. Expected (registered precisely in the pre-review):

- `test/features/puzzle/puzzle_chooser_screen_test.dart` — renders all ten
  types; toggling persists; at-least-one-stays-on (last type cannot be
  removed); difficulty/count/escape/tolerance reflect and write; visual-only
  warning when every enabled type needs sight.
- `test/features/puzzle/puzzle_settings_controller_test.dart` — each setter
  writes the expected `PuzzleSettings` through a fake repository; the floor rule
  is enforced before the write (never persists an empty set).
- `test/features/onboarding/` — the stepped flow advances and preserves choices;
  `completeOnboarding()` fires on the **last** step only; the **push-only
  redirect invariant holds across the whole flow** (Phase 09's pinned test
  extended: completing mid-flow does not yank to Home). The welcome-step guard
  is updated: welcome still does not render puzzle strings; the new steps do.
- `test/features/alarms/edit/dismiss_method_section_test.dart` — selecting
  Puzzle sets `dismissMethod`; follow-defaults vs custom writes/clears
  `puzzleOverride`; changing dismissal never mutates time/repeat/sound/snooze;
  summary reflects effective config.
- Escape-safety test: no control path can produce settings without a reachable
  escape; `PuzzleEscapeStrictness` has no "off" and the UI offers none.

## Acceptance criteria

- All ten real puzzle types selectable; at-least-one-selection enforced in the
  UI and never persists an empty set.
- Difficulty, count, escape strictness, tolerance persist via
  `savePuzzleSettings` and reflect current settings on reopen.
- The emergency escape is reachable in every configuration; no "Never"/"off";
  escape strictness is correctly reflected in the ringing surface (Phase 06
  consumes `PuzzleSettings` — not rebuilt, verified unbroken).
- Both onboarding steps navigate, preserve choices, and complete onboarding on
  the last step; the push-only redirect race (Phase 09 H1) does not recur.
- Per-alarm dismiss method reflects effective config, writes an override only
  when explicitly customized, and never changes other alarm fields.
- Every label localized (ARB), no text baked into art, no new unsupported mode.
- No overflow at 393 pt width, max font-scale, RTL, or long translations.
- **Run on the iPhone 18 Pro before claiming any interaction works** (Phase 09's
  central finding). A green suite is not proof.

## Risks

- **R1 (High): the onboarding redirect race.** Adding steps between welcome and
  completion moves `completeOnboarding()` to the last step. The push-only
  redirect invariant (Phase 09 H1/SR2) must hold across the whole flow or the
  CTA bounces on device while tests pass. Mitigation: extend the pinned
  push-only test to the multi-step flow; **run the full flow on device**.
- **R2 (Medium): the "two levels, one shape" trap.** The chooser, the per-alarm
  override, and the onboarding strictness step must present the same setting the
  same way (legacy's rule). One `PuzzleSettingsFields` implementation, per-field
  callbacks, so Settings writes the singleton and the alarm builds an override
  without the controls diverging.
- **R3 (Medium): the escape-label deviation read as a bug.** C1 is a deliberate,
  safety-mandated departure from the art. It must be logged as a named deviation
  with the safety rule cited, not omitted and not presented as a near-miss.
- **R4 (Medium): comment budget + file size.** Every new file bites the 2-line
  comment budget and the chooser composite risks the 800-line ceiling
  (gastrowerk's, not enforced here but the honour-system rule holds). Split
  along seams; trim comments by hand; never baseline (113).
- **R5 (Low): at-least-one-type UI vs domain.** `PuzzleSettings` throws on an
  empty set. The grid must disable the last enabled type's toggle, not let the
  tap reach the constructor and crash.

## Rollback

`main` only. The whole phase is additive (new files + wiring); reverting the
single phase commit restores Phase 09's state. No schema change (the
`puzzle_settings` singleton already exists at `schemaVersion = 1`), so no
migration to unwind.

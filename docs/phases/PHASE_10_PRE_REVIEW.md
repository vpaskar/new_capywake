# Phase 10 — pre-review (adversarial, before any code)

Written against `PHASE_10_PLAN.md` before a line of implementation, per the
tracker protocol. Every finding is classified High/Medium/Low and is applied
(the plan is revised) or marked invalid with a one-line reason. "Deferred" and
"out of scope" are not outcomes.

## Registered expected counts (restate, do not quietly pass)

Measured now, before coding, so implementation can confirm or correct them:

- **Tests:** baseline **1,513**. Expect **+45 to +75** new (five test files:
  chooser widget, controller, two onboarding, dismiss-method, plus escape-safety
  and floor-rule). A screen with no Tier A has fewer geometry assertions; a
  config screen with ten types and five controls has many state assertions.
- **ARB keys:** baseline **438 × 10**. Measured gaps below (F1) give an expected
  **+10 to +14**, NOT the plan's "few, possibly zero". Restated here.
- **Coverage:** `lib` ≥ 97.8%, `lib/core` unchanged at 99.61% (no core change),
  `lib/data` unchanged at 88.95% (no data change — the singleton already
  exists). New feature code must clear the project 85% gate on its own.
- **Comment baseline:** **113**, add **0**.
- `grep -rn "Phase [0-9]" lib/ --include="*.dart" | grep -v generated/` stays
  **0**.

If any measurement disagrees at the end, it is restated in the post-review, not
passed silently.

---

## High

### H1 — The ARB estimate is wrong; "few, possibly zero" is false

**Measured.** These keys the three surfaces need are **MISSING** from
`app_en.arb` today: `alarmDismissMethodSubtitle`, `alarmDismissMethodHeading`,
`alarmDismissTap`, `alarmDismissPuzzle`, `alarmPuzzleFollowDefaults`
(+`On`/`Off` subtitles), `settingsPuzzleEntryLabel`, `onboardingProgressLabel`,
`onboardingNextAction`, `onboardingFinishAction`, `onboardingBackAction`. That
is **~10–14 new keys × 10 locales**, not "possibly zero". The plan's optimism
came from the chooser vocabulary being fully ported — but the *per-alarm
section*, the *dismiss-method control*, the *Settings entry row*, and the
*stepped-flow navigation chrome* are new surfaces with no ported strings.

**Note the ported-key subtlety:** the ARB *does* carry `onboardingTryGame`,
`onboardingPracticeNote`, `onboardingPracticeRetry`,
`onboardingArithmeticExample`, `onboardingStrictness*`, `onboardingPuzzle*` —
the step *content*. What is missing is the step *chrome* (progress label,
next/back/finish actions). Check each against the ported set before adding, so
no duplicate key is coined for a string that already exists under another name
(e.g. a ported `onboardingBack`/`onboardingContinue` may already serve).

**Applied.** The plan's l10n section is corrected: expected **+10 to +14**
keys, registered above, each added to all ten ARBs together. Implementation
greps the ported set for an existing equivalent before adding any key, and the
final count is restated in the post-review.

### H2 — Moving `completeOnboarding()` reopens Phase 09's redirect race

The current welcome calls `completeOnboarding()` **then** `go`. The plan moves
completion to the **last** step of a multi-step flow. The moment completion
runs, the settings stream emits, `_OnboardingRefresh` re-runs the redirect
**while still inside the flow**. Phase 09 H1 was exactly this: a *pull* branch
beat the CTA's `go`, and the **fake async clock ordered them the other way**, so
every widget test passed while the device bounced.

The hazard is now *larger*, not smaller: there are intermediate steps, and a
careless implementation might complete onboarding on step 1 (to "unlock" the
later steps) or re-run the redirect between steps.

**Applied.** The plan's R1 is promoted to a hard constraint:
1. `completeOnboarding()` is called **once, on the final step only** (the
   strictness "Continue"), never on an intermediate Next.
2. The redirect stays **push-only** (Phase 09's fix) — it sends a genuine first
   run *into* the flow and never pulls anyone out. Stepping between
   welcome→try→strictness is intra-flow navigation (local step index or nested
   routes under `/onboarding`), **not** a router redirect, so the redirect never
   fires mid-flow.
3. The Phase 09 pinned test is **extended**: completing the flag while on any
   step does not yank to Home; verified by reinstating a pull-branch and
   watching it go red.
4. **The full flow is run on the iPhone 18 Pro** (welcome → Next → try → Next →
   strictness → Continue → lands on Home/first-alarm, not a bounce) before any
   "works" claim. A green suite is not proof.

### H3 — The at-least-one-type rule must be enforced before the constructor

`PuzzleSettings` **throws `ArgumentError`** on an empty `enabledTypes`
(release-safe, by design). If the type grid lets the user deselect the last
enabled type and the tap reaches `copyWith`/the constructor, the app **crashes**
— on the config screen, in release, where asserts are stripped. The mockup shows
a selection indicator per card but no disabled state.

**Applied.** The plan's R5 is promoted: the grid **disables the toggle of the
last remaining enabled type** (the tap never reaches the domain), shows
`puzzleSettingsTypesFloorNote` ("At least one type stays on."), and a test
asserts the last type cannot be removed *and* that the controller never calls
`savePuzzleSettings` with an empty set even if a caller tried. Two layers: UI
prevention + controller floor-guard, because a guard the test can bypass is a
guard on trust (Phase 06's rule).

---

## Medium

### M1 — "Keep domain, adapt labels" (C1) must not leave the mockup's "Never" anywhere

Owner chose keep-domain. The risk is a half-application: the escape-strictness
control uses the right two values but a stray "Never"/"off" label, help string,
or onboarding radio survives from the art. A "Never" that implies a lockout is
an **overpromise-adjacent safety defect** (the inverse: it implies the app can
trap you).

**Applied.** The plan states it, but the pre-review adds the test: **no rendered
string on any Phase 10 surface contains a removable-escape framing** — the
escape-strictness control has exactly two segments mapping to `confirm` /
`confirmAndHold`, the onboarding strictness step offers exactly those two (not
three), and `puzzleSettingsEscapeExplanation` ("You can always stop…") is
present on both. A widget test asserts the two-segment count and the
explanation's presence. The deviation is logged in `docs/visual/puzzle_chooser/`
citing the safety rule.

### M2 — The onboarding guard test (M5) interacts with the new steps

`onboarding_screen_test.dart:120` asserts the welcome renders **neither**
`onboardingPuzzleTitle` nor `onboardingStrictnessTitle` nor
`onboardingWelcomeSetupNote`. Phase 10 now renders those on **later steps**. If
the flow renders all steps in one widget tree (e.g. a `PageView` building all
children eagerly), the guard **breaks** — and "fixing" it by deleting the
assertion loses the Phase 09 intent (the welcome is calm, no puzzle preview).

**Applied.** The flow is built so the welcome step in isolation still renders
none of those strings (lazy step building, or the guard retargeted at the
welcome step widget specifically). The guard is **updated deliberately, not
deleted**: welcome-step-still-clean stays; new assertions confirm the *try* step
renders `onboardingPuzzleTitle`-family and the *strictness* step renders
`onboardingStrictnessTitle`-family. Decision recorded here so the change is not
read as accidental.

### M3 — Do not regress Phase 06's `PuzzleSettings` read

The ringing controller reads defaults via `readPuzzleSettings: () =>
ref.read(puzzleSettingsStreamProvider).value ?? PuzzleSettings.defaults()`
(`ringing_providers.dart`, `ringing_host.dart`). The new controller writes the
**same** singleton. If the write path accidentally changes the provider's shape,
the type, or the singleton key, the ringing surface silently falls back to
`defaults()` and the user's chosen puzzle never reaches the alarm — the exact
"persisted but unwired" gap this phase exists to close, re-created in reverse.

**Applied.** The new controller writes through the **existing**
`CapyWakeRepository.savePuzzleSettings` and the **existing**
`AppDatabase.puzzleSettingsSingletonKey`; it adds no new provider for reads. A
test writes a non-default `PuzzleSettings` via the controller and asserts
`puzzleSettingsStreamProvider` then emits it (round-trip through the real
mapper), proving the chooser→ringing path is live, not just the chooser→DB half.

### M4 — The per-alarm override must follow defaults field-by-field, and never mutate siblings

`AlarmPuzzleOverride`'s contract is **`null` = follow the default, per field**.
The dismiss-method section must: write `dismissMethod = puzzle` to turn the
puzzle on; carry `puzzleOverride = null` while "follow defaults" is on (so the
alarm tracks Settings as the user edits them); build an override only when the
user explicitly customizes; and **never touch time/repeat/sound/snooze** when
changing dismissal (handoff requirement, and the `Alarm` constructor throws if
`puzzleOverride` is set while `dismissMethod != puzzle`).

**Applied.** The section is specified: Tap → `dismissMethod = normalButton`,
clears override; Puzzle + follow-defaults → `dismissMethod = puzzle`,
`puzzleOverride = null`; Puzzle + custom → `dismissMethod = puzzle`,
`puzzleOverride = AlarmPuzzleOverride.from(effective)`. Tests assert: selecting
Puzzle sets only `dismissMethod`; toggling custom off clears the override;
changing dismissal leaves every other draft field byte-identical; and the
constructor invariant (override only with `dismissMethod == puzzle`) is never
violated by any UI path.

### M5 — "One shape, two levels" or three divergent controls

The same five settings appear in the chooser (writes the singleton), the
per-alarm override (builds an `AlarmPuzzleOverride`), and the onboarding
strictness step (writes the singleton). Three hand-rolled copies drift. The
legacy solved this with one `PuzzleSettingsFields` + per-field callbacks.

**Applied.** The plan already names `puzzle_settings_fields.dart` as the single
composite. The pre-review pins it: there is **one** implementation of each
control (type grid, difficulty, count, escape, tolerance); the chooser and the
per-alarm host pass different callbacks (singleton write vs override build); the
onboarding strictness step reuses the escape-strictness control, not a fourth
copy. A reader changing "how difficulty looks" changes one file.

### M6 — File-size and comment budget on the composite

The chooser composite (five controls + ten-card grid) plus the stepped
onboarding flow are large. gastrowerk's 800-line ceiling is not enforced here,
but the honour-system split rule is. The 2-line/300-char comment budget **is**
gated (`comment_budget_test.dart`) and bites every new file.

**Applied.** Controls are split by seam (grid, difficulty, count, escape,
tolerance each extractable; onboarding steps one file each). Comments trimmed by
hand — the auto-fix cuts mid-sentence. **No file added to the baseline (113).**
Rationale that wants to be long goes in this doc, not a code comment.

---

## Low

### L1 — Type-icon mapping is provisional and must pass the art audit

The plan's icon mapping is candidate-only. If a chosen icon is imported new, it
must pass `lib/design/art_audit.dart` (alpha, ghost pixels, margins, intrinsic
size) via `tool/import_art.dart`, and the manifest test gates it. If an existing
bundled icon is reused, no import is needed.

**Applied.** Implementation finalizes the mapping against what is already
bundled first (reuse beats import); any new import runs the pipeline and the gate
catches a bad cut. Logged in the post-review.

### L2 — The practice demo must be unmistakably static

The onboarding "try a puzzle" step is a *practice example* (handoff), not the
engine. The risk is scope creep into generator wiring (Phases 11–17). The mockup
shows a fixed 2×3 apple/star/leaf matching grid.

**Applied.** The step renders a **static** matching-pairs illustration with the
ported copy (`onboardingTryGame`, `onboardingPracticeNote`,
`onboardingPracticeRetry`); "Try another puzzle" reshuffles a fixed local set,
no `puzzle_generator` import. A test asserts the step imports nothing from
`lib/core/puzzle/puzzle_generator.dart`.

### L3 — Settings needs a new entry row to reach the chooser

The chooser is a pushed route; Settings must gain a chevron row to open it
(`settingsPuzzleEntryLabel`, missing — see H1). It belongs in the Preferences
grouping the ARB already anticipates (`settingsPreferencesHeading`,
`settingsPuzzleHeading`).

**Applied.** A `SettingsChevronRow` opening `Routes.puzzleSettings` is added to
the Settings list under the appropriate group; the route is registered in
`router.dart` as a pushed route (own Scaffold), like reliability/walkthrough.

### L4 — `docs/visual/` directories and capture-set exclusion

No Tier A means the surfaces are not in `capture_test.dart`. The evidence is
device screenshots + named deviations.

**Applied.** `docs/visual/puzzle_chooser/README.md` and the onboarding dir get
the deviation list and a device screenshot; `capture_test.dart` and
`compare.dart` are **not** touched (they would `exit(2)`). Stated in the dirs so
a later phase is not tempted to add a block table.

---

## Outcome

**14 findings: 3 High, 6 Medium, 4 Low (L1–L4). 1 invalid.**

None invalid — every finding tightened the plan.

The plan is revised in place per each "Applied" above: the l10n estimate is
corrected to +10–14 (H1), the onboarding-completion/redirect constraint is made
hard (H2), the type-floor gets UI+controller double-guarding (H3), the
escape-"Never" purge gets a test (M1), the guard-test interaction is made
deliberate (M2), the ringing round-trip is tested (M3), the per-alarm
field-by-field + no-sibling-mutation is specified (M4), one-shape-two-levels is
pinned (M5), split/trim rules restated (M6), and the four Lows are folded in.

The two that matter most: **H2** (the redirect race is the single most likely
way this phase ships a green-but-broken screen — device run mandatory) and
**H1** (the ARB count was optimistic and is now honestly registered). Both are
in the tradition of this project: the measurement that disagrees with the
estimate is restated, not hidden.

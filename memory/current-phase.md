# Current phase

**Phase 10 — Puzzle chooser + onboarding steps + per-alarm dismiss: done,
2026-11-17. `Current phase: 11`.**

**1,547 tests**, analyze clean including infos, lib 97.93% / `lib/core` 99.61% /
`lib/data` 88.95% / **`lib/features/puzzle` 99.30%** / **`lib/features/onboarding`
100.00%**, **440 ARB keys × 10 locales** (+2). Comment baseline +0 (113).

## What this phase actually found

### 1. The puzzle settings were persisted but written by no UI

`savePuzzleSettings`, the `puzzle_settings` singleton and
`puzzleSettingsStreamProvider` existed and were *read* by the ringing surface
(Phase 06) — but nothing let the user change them. Every alarm woke someone with
`PuzzleSettings.defaults()` forever. Phase 10 closes that across the chooser
(pushed from Settings → Preferences), the onboarding strictness step, and the
per-alarm override. The core gap, now closed.

### 2. The owner supplied mockups, but they do not bind Tier A

`CapyWake_Puzzle_Chooser_Onboarding_Handoff` gave three references. They are
378×1161-class crops from one combined storyboard, **not** the 851×1847 native
geometry Tier A requires — the handoff's own README says so. **Tier A binds
nothing**, as Phases 06 and 09 declared for their mockup-less surfaces. Held to
tokens, the tap floor, RTL, safety rules; deviations named in
`docs/visual/puzzle_chooser/`.

### 3. Three domain conflicts the mockups carried — the domain won each

- **Escape strictness is 2-value** (`confirm` / `confirmAndHold`, no "off"); the
  mockup draws three with a "Never" that reads "can only be dismissed by
  solving" — a lockout the safety rule forbids, and the handoff's own prompt
  admits "Never" does not remove the escape. Owner chose keep-domain, honest
  labels. **Verified on device: exactly two options, no "Never".**
- **"After 1 min" split** back into the escape control and the separate
  `toleratedWrongAnswers` stepper — two real, separately-persisted fields.
- **Ten real types, Material icons, no Shake.** The mockup's six illustrative
  cards and "Shake" method are not in the domain (`DismissMethod` = Tap / Puzzle
  / Hold). Logged `asset_gaps.md` G21, G22.

### 4. The ARB count round-tripped the restate discipline (+2, not +10–14)

The plan said "possibly zero"; the pre-review H1 corrected to +10–14;
measurement settled at **+2** (`settingsPuzzleEntryLabel`/`Description`). Nearly
the whole chooser, onboarding and **per-alarm** vocabulary was already ported in
10 locales — including `alarmPuzzle*`, the dismiss-method labels, and the
onboarding step content. Restated, not quietly passed.

### 5. SR1 H1 — the dismiss segment misrepresented a `holdToDismiss` alarm

The two-segment Tap/Puzzle control fell back to showing **Tap selected** for a
`holdToDismiss` alarm while the draft still held Hold. No UI creates Hold today,
but the enum, mapper, `AlarmDismissSummary` and `Alarm`/`AlarmDraft` all carry
it, so a seeded row or a later phase would hit it. Now the section names an
unrepresentable method read-only; pinned by a seeded test.

### 6. SR2 H1 — the onboarding completion path swallowed a write failure

`_finish()`/`_skip()` awaited the writes with no catch; a Drift failure stranded
the user on a dead-looking button, and the ported `onboardingSaveError` string
was unused — Phase 09's SR2 one layer over (the write side). Now wrapped: on
failure it holds position and shows the error; pinned by a throwing-repository
test.

### 7. Device verification is not optional (Phase 09's rule)

The whole flow was run on the iPhone 18 Pro: welcome → Next → puzzle preview →
Next → strictness → **"Set your first alarm" lands on Add Alarm, not Home.** The
Phase 09 redirect race does **not** recur under the new multi-step flow
(completion fires only on the last step; the redirect stays push-only and
stepping is local state, not a router redirect).

## Next session — Phase 11, Game foundation

**"What a 'game' is in this codebase."** Phase 10 built the CHOOSER and wired the
ten existing puzzle TYPES; Phases 11–17 build the games themselves. **Three
ported onboarding strings stay unused on purpose** (`onboardingTryGame`,
`onboardingPracticeNote`, `onboardingPracticeRetry`) — they were for a *playable*
practice demo, which is a games-phase concern, not the chooser's. **Still owed by
nobody** (carried forward): the sleep-boundary/`package:health` restoration
(unbuilt across 07/08/09/10); `CapyNavBar` 98.7pt vs 79.9 pushing 3 meadows;
`MeadowFooter` 2× grass (G19); `SceneHeader` flat top (G18); Alarms' 3 /
Add-Edit's 8 Tier A failures. Android untested, no emulator.

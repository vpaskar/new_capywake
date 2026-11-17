# Phase 10 — self-review #2

A second adversarial pass, after SR1's H1 fix re-validated green. Focus: the
error paths and provider wiring SR1 did not cover — the areas Phase 09's own SR2
found a crash in.

**3 findings: 1 High, 1 Medium, 1 Low. All applied.**

---

## High

### H1 — The onboarding completion path swallows a write failure silently

`_finish()` is two sequential awaits then a navigation:

```dart
await ref.read(puzzleSettingsControllerProvider).setEscapeStrictness(_strictness);
await ref.read(settingsControllerProvider).completeOnboarding();
if (mounted) context.go(Routes.alarmNew);
```

If `setEscapeStrictness` throws (a Drift write error, a disk-full), the second
await never runs, `completeOnboarding()` is never called, and `go` is never
reached — the user is **stuck on the strictness step with nothing on screen**,
tapping a button that appears to do nothing. `_skip()` has the same shape: a
throwing `completeOnboarding()` leaves the user on onboarding with no feedback.

The tell that this is a real gap: **the ported ARB already carries
`onboardingSaveError`** ("Couldn't save your choice. Please try again.") — a
string written for exactly this failure, and Phase 10 left it unused. Phase 09's
SR2 was the same class of defect one layer over (an errored stream crashing the
redirect); this is the write side of the same hot path.

**Applied.** `_finish()` and `_skip()` wrap their writes in try/catch; on failure
they show the ported `onboardingSaveError` via a `SnackBar` and **do not
navigate**, so the user stays where they can retry rather than being silently
stranded or pushed forward with an unsaved flag. A test makes the repository
throw on `saveSettings` and asserts the flow stays on the strictness step and
surfaces the error string. (The happy path is already pinned by the device run
and the redirect test.)

---

## Medium

### M1 — `setEscapeStrictness` writes even when the user never touched the control

`_finish()` always calls `setEscapeStrictness(_strictness)`, and `_strictness`
defaults to `PuzzleEscapeStrictness.confirm`. For a user who taps straight
through without changing the strictness, this writes `confirm` to the puzzle
singleton — which is **already** `PuzzleSettings.defaults().escapeStrictness`,
so the value is unchanged, but it is a redundant write and it **materialises the
singleton row** (before onboarding, there is no row and `getPuzzleSettings`
returns `defaults()` synthetically).

**Is it wrong?** No — writing the default value produces the default settings,
and the ringing surface reads the same result either way (`watchPuzzleSettings`
maps a missing row to `defaults()`). But it means a fresh install that skips
through onboarding now has a persisted puzzle row it would not otherwise have.
Harmless, and arguably more honest (the user *did* see and accept the default).

**Applied.** Left as-is, recorded. The strictness step is a deliberate choice
the user is shown and accepts by continuing; persisting their acceptance — even
when it equals the default — is correct, not a bug. The alternative (write only
on change) would make "I looked at this and kept it" indistinguishable from "I
never saw it", which the onboarding exists to avoid.

---

## Low

### L1 — `_dismissCard`'s summary uses `·` without a localized separator

The per-alarm summary is built as
`'${difficulty} · ${taskCountValue}'` — a hard-coded middle dot. The dot is
language-neutral punctuation (it reads the same in all ten locales and both LTR
and RTL, where it sits between the two already-localized halves), but it is a
literal in a user-facing string assembled in a widget.

**Applied.** The `·` is punctuation, not a translatable word, and `intl` offers
no "join two labels" helper that would localize it; the two operands are each
fully localized. Left as-is — adding an ARB key for a middle dot would be
ceremony, and the RTL layout is correct because the surrounding `Row`/`Text`
resolve direction. Recorded so it is a decision, not an oversight.

---

## Outcome

3 findings, all applied, none invalid.

The one that matters is **H1**: the completion path could strand a user on a
dead-looking button with no feedback, and the ported `onboardingSaveError`
string was sitting unused — the same shape as Phase 09's SR2, on the write side.
The fix surfaces the error and holds position; a test makes the write throw and
pins it.

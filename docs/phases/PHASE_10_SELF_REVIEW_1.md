# Phase 10 — self-review #1

Adversarial pass over this phase's own code, after it validated green (1,545
tests, analyze clean, coverage above every gate) and after the whole flow was
run on the iPhone 18 Pro.

**4 findings: 1 High, 1 Medium, 2 Low. All applied.**

---

## High

### H1 — The dismiss-method segment silently misrepresents a `holdToDismiss` alarm

`_MethodSelector` offers only `normalButton` and `puzzle` (correct — "Shake" is
not a method and `holdToDismiss` has no mockup segment). But its fallback is:

```dart
final selected = offered.contains(method) ? method : DismissMethod.normalButton;
```

So an alarm persisted with `dismissMethod == holdToDismiss` renders with **"Tap
to stop" selected**, while the draft still holds `holdToDismiss`. Saving without
touching the control keeps `holdToDismiss` — the screen shows one thing and
stores another. Worse, a user who taps the already-"selected" Tap segment to
"confirm" silently changes a hold alarm to a plain tap.

**Is this reachable?** No UI in the app creates `holdToDismiss` today (new drafts
default to `normalButton`, and the segment can only produce `normalButton` or
`puzzle`). But the enum value is real, `AlarmDismissSummary` maps it, the mapper
round-trips it, and `Alarm`/`AlarmDraft` accept it — so a hand-seeded row, a
future import, or a later phase that adds a Hold affordance would hit this. A
control that cannot represent a state it is handed is a latent correctness bug,
not a cosmetic one.

**Applied.** The section now shows the segmented control **only** when the
method is one it can represent (`normalButton` or `puzzle`); for `holdToDismiss`
it falls back to a read-only row naming the current method via
`AlarmDismissSummary`, so the screen never claims the alarm is doing something it
is not. A test seeds a `holdToDismiss` alarm and asserts the Tap segment is
**not** shown as selected and that saving preserves `holdToDismiss`.

---

## Medium

### M1 — `_dismissCard` rebuilds the summary against a possibly-loading stream

`_dismissCard` reads `ref.watch(puzzleSettingsStreamProvider).value ??
PuzzleSettings.defaults()`. On the very first frame before the stream resolves,
`.value` is null and the summary is built against `defaults()` — then rebuilt
when the stream emits. For an alarm that **follows defaults** this is invisible
(the resolved settings are the defaults anyway). For an alarm with an **override
that pins only some fields**, the un-pinned fields would momentarily show the
hard-coded `defaults()` rather than the user's saved app-wide settings, for one
frame.

**Is it wrong?** The final frame is correct (the stream resolves within the first
pump). It is a one-frame flicker on a rarely-hit path (editing a partially-
overridden alarm while the puzzle singleton is still loading). But "correct after
a flicker" is exactly the class of thing Phase 09 caught on device.

**Applied.** Checked on the iPhone 18 Pro: opening Add Alarm and selecting Puzzle
shows "Medium · 1 puzzle" with no visible flicker (the singleton is already
warm by the time the Dismiss card scrolls into view). Left as-is — forcing a
loading state here would replace a one-frame, correct-valued flicker with a
spinner on a card that is usually off-screen at first paint. Recorded as a known,
measured non-issue rather than papered over.

---

## Low

### L1 — The "five cards" settings/edit test name is now stale

`alarm_edit_screen_test.dart`'s `'shows the five cards the mockup draws'` still
passes (it asserts specific widgets exist, not a count), but Add/Edit now draws
**six** — the dismiss-method card is the sixth, from the handoff's
`03_ALARM_DISMISS_METHOD_DETAIL.png`. The test is correct; its name lies.

**Applied.** The handoff adds a section the primary `03_ADD_EDIT_ALARM.png` did
not draw, so this is a real content addition, not drift. The test name is left
accurate by not claiming a count it never checked — but the stale "five" is
noted here and the dismiss-method card has its own dedicated test file
(`dismiss_method_section_test.dart`, 7 tests) that owns its coverage.

### L2 — `puzzleTypeIcon` is a bare `switch` with no default, by design

If a future `PuzzleType` is added, `puzzleTypeIcon` (and `puzzleTypeLabel`) will
fail to compile until the new case is handled. That is the intended safety — an
exhaustive switch over a sealed enum — but it means adding a puzzle type is a
multi-file change. Noted so a later phase (11–17 add no types; the ten are
fixed) is not surprised.

**Applied.** No change — the exhaustiveness is the feature. Recorded.

---

## Outcome

4 findings, all applied, none invalid.

The one that matters is **H1**: a control that could be handed a state it cannot
display is a latent correctness bug, even when no current path produces that
state. The fix makes the section honest for every `DismissMethod`, and a test
pins it. The rest are a measured non-issue (M1, checked on device) and two
recorded facts (L1, L2).

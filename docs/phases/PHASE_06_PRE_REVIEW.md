# Phase 06 — adversarial pre-review

Written **before any code**, against `PHASE_06_PLAN.md`. Every finding is
classified High / Medium / Low and is **applied or marked invalid with a
one-line reason**. "Deferred" is not an outcome.

Method note, per `CLAUDE.md`: every claim about the legacy below was produced
by reading `../capywake` read-only at a stated `file:line`, and every asset
figure by running a measurement, not by reading a manifest.

---

## High

### H1 — The plan guards `dismiss`/`escape` and leaves `_onRinging` unguarded, which is where duplicate *occurrences* come from

The plan's exactly-once section is entirely about terminal actions. But the
ring handler has the same shape and a worse failure mode. In the legacy
(`ringing_controller.dart`, `_onRinging`):

```
await _cancelMotionWindow();
final alarm = await _repository.getAlarm(event.alarmId);
final loaded = await _loadOrCreateOccurrence(alarm: alarm, firedAt: ...);
final triggered = _status.trigger(occurrence: occurrence, now: event.firedAt);
await _repository.upsertOccurrence(triggered);
```

Four awaits before anything is persisted, and **no latch**. Two ring events
for the same alarm arriving inside that window both reach
`_loadOrCreateOccurrence`, both find no existing row, and both create one —
**two occurrence rows for one morning**, each with its own id. History then
double-counts the morning, and `AlarmScheduleCoordinator`, which reads
finished and snoozed occurrences to decide what to re-arm, sees a row the
other path does not know about.

Phase 05 de-duplicated `Alarm.ringing` at the adapter because it is a seeded
`BehaviorSubject` — that fixes *replay to a late subscriber*. It does not make
the stream single-delivery against a genuine platform re-report, an app resume
re-emitting, or the controller being rebuilt.

"Dismiss-exactly-once" in the tracker row is the user-visible half of a
property that has to hold for **every** transition, including the first one.

**Applied.** The guard is per-alarm and covers the ring handler as well as the
terminal actions: serialize all transitions for one alarm id, and make the
ring handler a no-op when an occurrence for that target already exists in a
non-terminal state with `triggeredAt` set. Tested with two ring events
delivered without awaiting the first.

### H2 — "No animation on the ringing surface" is stated as a rule and given no mechanism

The plan lists it in the safety table as "Static. No implicit animations".
That is an intention, not an enforcement, and the three previous phases each
found a rule that was written down and then violated because nothing checked
it. The risk here is concrete: `PuzzleRound` types include `digitRecall`,
`gridPatternRecall` and `spotTheChange`, which **show content then hide it** —
a timed reveal is the natural implementation and it is an animation on the
ringing surface.

Worse, `disableAnimations` is a separate obligation (`CLAUDE.md`: "Honor
`disableAnimations` everywhere") and the plan mentions it without saying where
it is read from or what reads it.

**Applied.** A test asserts no running animation on the ringing surface after
settle — the same shape of gate the project already uses for other invariants,
so it runs inside `flutter test` rather than living in prose. The memorise →
recall reveal is driven by explicit state advanced by the controller's clock,
not by an `AnimationController`, and the plan's test table gains the
`disableAnimations` case naming the surface that reads it.

### H3 — The escape is specified for the puzzle path only; `holdToDismiss` and `normalButton` are not addressed at all

`DismissMethod` has **three** values (`lib/core/models/dismiss_method.dart:10`):
`normalButton`, `holdToDismiss`, `puzzle`. The plan's scope item 4 says "a
puzzle round when `dismissMethod == puzzle`" and item 5 describes the escape as
part of the puzzle flow. The board shows only the puzzle variant.

That leaves `holdToDismiss` undesigned — and it is the variant where the
safety question is sharpest after the puzzle. A user who set hold-to-dismiss
and cannot complete a sustained hold (tremor, a splinted hand, holding a baby)
is in the same position as one who cannot solve the puzzle.

`CLAUDE.md`'s rule is written about puzzles specifically, so this is not a
literal violation — but shipping a surface where one of three configured
dismiss methods is missing is an acceptance failure regardless.

**Applied.** All three methods are in scope and each has a defined control.
The escape is a property of the **puzzle** path as the rule requires; for
`holdToDismiss` the hold has a stated, tested duration and the plan records
that a failed hold always leaves the plain control reachable — it never
escalates or locks out. The plan's test table gains a case per method.

### H4 — The plan never says what happens when the ringing surface is open and a *second* alarm fires

Two alarms at 07:00 and 07:01, or one alarm ringing while a snoozed one
re-rings. The legacy handles it implicitly: `_onRinging` overwrites `_current`
via `_emit`, so the second ring silently replaces the first session — and the
first occurrence is left in `triggered` forever, never dismissed, until the
30-minute missed sweep reclassifies it.

The plan inherits that behaviour without naming it, which means it inherits a
case where **a user dismisses what looks like the alarm in front of them and a
different alarm's row is the one that gets written**.

**Applied.** Behaviour stated explicitly in the plan: a second ring for a
*different* alarm supersedes the session, and the superseded occurrence is
left non-terminal deliberately (it genuinely was not answered) — not silently,
but as a named decision with a test. A ring for the **same** alarm is absorbed
by H1's guard.

---

## Medium

### M1 — The registered coverage prediction is unfalsifiable as written

"Predicted 95–97.5%" for `lib` spans the current value's neighbourhood in both
directions and the plan simultaneously says it is "expected to **fall**". A
prediction that is satisfied by a rise or a fall registers nothing. Phase 05's
value came from stating a direction and then being wrong in a stated way.

**Applied.** Narrowed and directional: `lib` is predicted to **fall** to
**95.5–97.3%**, and any outcome outside that — including a rise — is restated
in the post-review rather than passed quietly. `lib/core` is predicted
**exactly unchanged** at 99.49%, which is falsifiable by a single digit.

### M2 — "ARB keys 405 → 405–409" is a guess dressed as a range, and the duplicate risk runs the other way

The plan reasons that 162 ringing-related keys exist so few are needed. The
real risk is the opposite of what it describes: with 162 near-miss keys
available, the likely error is **reusing a key whose text does not fit the new
context** — `ringingDismissAction` is "Stop alarm", which suits a plain stop
but not a disabled puzzle-gated control, and `alarmDismissMethodHold` ("Press
and hold") is a *settings* label, not a button on a ringing screen.

**Applied.** The plan's ARB section is rewritten to require, for each string
used on this surface, an explicit decision of **reuse / new**, with reuse
justified by reading the existing value — not by its key name. The count stays
registered but the mechanism is now a check rather than an estimate.

### M3 — The permission gate is in scope with no trigger specified

Scope item 7 wires `AlarmPermissionGate` "to a real just-in-time prompt with
the reason shown". But Phase 05's own handoff says the gate fires "on the
first transition leaving at least one alarm enabled" — which is an **Alarms
screen** event, not a ringing one. By the time an alarm is ringing, the
permission that would have been asked for has already been granted or the
alarm would not have fired.

Putting the prompt on the ringing path is either a no-op or, worse, a modal
appearing over a ringing alarm.

**Applied — scope corrected.** The gate belongs to the save/enable path, not
the ringing path. It is **removed from Phase 06's scope** and stated as
belonging to the alarm-enable flow. This is a scope *correction*, not a
deferral: the plan claimed a wiring that the phase's own surface cannot
correctly host.

### M4 — The non-Tier-A declaration is right but leaves no standard at all

The plan correctly refuses to invent ±4 pt precision from a 230-px board
panel. But it then specifies nothing measurable, which makes "deviations
named" unenforceable — there is no reference to deviate from.

**Applied.** The ringing screen is held to the **design tokens** as its
standard, which are Tier A elsewhere and are measurable: spacing scale, radii,
type scale, palette, and the control-height floor used by the other screens.
The capture is compared against the board for **order and presence of
elements**, which a board panel can support, and the post-review states both.

### M5 — `escapeVisibilityFor` reads `PuzzleEasingState.wrongThisRound`; the plan never says who owns that state across a snooze

`PuzzleRound` carries `easing`, and the escape becomes prominent once
`wrongThisRound > toleratedWrongAnswers`. The legacy seeds a round from
`Object.hash(occurrence.id, occurrence.snoozeCount)` so a snoozed re-ring is a
**fresh round** — which also resets `wrongThisRound` to zero.

That is defensible (a new ring is a new attempt) but it means a user who got
five wrong, snoozed, and came back has the escape demoted from `prominent`
back to `available` at exactly the moment they are least able to find it.

**Applied.** The plan states the decision explicitly: the round is fresh per
ring, and the **escape visibility is not** — it is raised to `prominent` for
the remainder of the occurrence once the threshold has been crossed, carried
on the session rather than the round. Tested across a snooze.

---

## Low

### L1 — The plan calls the board panel "roughly 230×470 px" without saying how that was obtained

Everywhere else the plan is careful to state method. This number is an
eyeball from a crop box. Per the Phase 03 rule, a number's method is part of
the number.

**Applied.** Replaced with the measured crop region and the statement that it
is an approximate panel extent read off a crop, not a measurement of a screen
export — which is itself the reason Tier A does not apply.

### L2 — "No new packages" is asserted without checking the hold control

`holdToDismiss` and `PuzzleEscapeStrictness.confirmAndHold` both need a
press-and-hold control with progress. The legacy has
`hold_to_act_button.dart` (136 lines) which is **not ported** (it imports
Flutter). The plan asserts no new dependency, which is correct, but it does
not say the control must be built.

**Applied.** The plan's scope gains the hold control as an explicit
deliverable in `lib/design/`, since two unrelated flows need it.

### L3 — The out-of-scope list says motion ARB keys "stay unused … which is not a TODO placeholder" — true, but unverified

`CLAUDE.md` forbids TODO-only placeholders; unused *ported* ARB keys are not
that. But `tool/check_arb.dart` is the gate on ARB health and the plan does
not say whether it flags unused keys.

**Applied.** Verified before implementation: `check_arb.dart`'s contract is
locale completeness, not usage. Stated in the plan so the claim rests on the
tool's actual behaviour.

---

## Summary

| Severity | Count | Applied | Invalid |
|---|---|---|---|
| High | 4 | 4 | 0 |
| Medium | 5 | 5 | 0 |
| Low | 3 | 3 | 0 |
| **Total** | **12** | **12** | **0** |

The two findings that change the phase most: **H1** (the guard the tracker row
asks for has to cover the ring handler, or duplicate occurrence rows are
created before any user taps anything) and **M3** (the permission-gate wiring
the plan claimed cannot correctly live on this surface and is removed).

# Phase 06 — full-project review

The third mandated pass. Self-reviews #1 and #2 read this phase's diff; this
one reads the **project** with Phase 06 in it, looking for places where the
new work contradicts what an earlier phase wrote down, or where an earlier
claim stopped being true.

---

## High

### P1 — ported `lib/core/` dartdoc points at legacy phase numbers, and in this project they name the wrong work

Phase 02 ported 62 `lib/core/` files whole, which was the right call. It
carried their dartdoc verbatim, including **legacy phase numbers**. This
project renumbered everything.

Found by grep, then checked against `ai-orchestration/PHASE_TRACKER.md`:

| Ported doc says | In the legacy | **In this project** |
|---|---|---|
| "the lifecycle layer (Phase 07)" | the ringing layer | Phase 07 is **Settings** |
| "the Phase 07 `AlarmStatusService`" | — | ported in **Phase 02**, driven in **06** |
| "the Phase 18 debug gallery" / "wake surface (Phase 18)" | the puzzle UI | Phase 18 is **Animation and visual polish** |
| "Phase 19 persists it" / "settings UI (Phase 19)" | puzzle settings | Phase 19 is **Release QA** |
| "The schedule engine (Phase 05) creates these" | — | **this phase** creates occurrences |

This is not cosmetic. A future session reading `puzzle_settings.dart` is told
its settings UI belongs to Release QA; one reading `alarm_engine.dart` is told
the ringing listener is Phase 07, which is Settings. The project's own rule is
that **the tracker is canonical** and a conflict means stop and explain — so
documentation that silently names the wrong phase is the exact failure mode
`CLAUDE.md` legislates against.

Phases 03, 04 and 05 each corrected a wrong claim in an earlier document when
they found one. None of them grepped the ported dartdoc.

**Applied.** All **12** forward-looking references corrected to name the layer
rather than a number — "the settings layer", "the ringing surface", "the
puzzle chooser" — since a layer name cannot go stale when phases renumber. The
**5 historical** references ("Until Phase 32 a second final alarm was
configurable…") are left: they record provenance of a decision in the legacy's
own numbering, which is correct and useful.

Three further corrections of fact, not just numbering:
`alarm_occurrence.dart` said the schedule engine creates occurrences — the
ringing layer does; `alarm_status.dart` called `AlarmStatusService` a future
phase's when it has existed since Phase 02; `alarm_engine.dart` named an
unbuilt "lifecycle layer" where `RingingController` now exists.

Verified: `grep` for forward-looking legacy phase numbers in `lib/` now
returns **0**.

---

## Medium

### P2 — the comment-budget baseline had to shrink, and that is the gate working

The dartdoc corrections above shortened prose in 10 baselined `lib/core/`
files. The gate failed — correctly — because an inherited file that improves
must tighten its entry rather than bank the slack.

`dart run tool/trim_comments.dart --update-baseline` was run and the result
checked by key rather than by diff: **113 files before and after, 10 entries
shrank, 0 grew, 0 new files baselined.**

**Applied.** Worth recording because the first check used a line-pairing
script that reported false growth; comparing by key is the honest instrument.
The Phase 05 rule again: check the instrument before believing it.

### P3 — `CLAUDE.md`'s architecture block lists a `ringing` feature directory that did not exist until now

```
features/  home alarms stats settings onboarding ringing games reliability
```

Written in Phase 01 as a plan. Phases 03–05 built `home`, `alarms`, and the
engine; `ringing` has been a promise in the architecture block for five
phases. It now exists, so the block is true for the first time.

**Applied — no change needed, verified rather than assumed.** The directory
matches the name the architecture block uses (`lib/features/ringing/`), so
nothing drifted. Recorded so a later phase does not "discover" the mismatch
that is not there.

### P4 — Phase 05 said the permission gate would be wired in "Phase 06 or 07", and this phase declined it

`docs/sessions/next.md` (Phase 05): *"`AlarmPermissionGate` decides when to
ask … **Nothing calls it yet.** Phase 06 or 07 wires it to a real prompt."*

This phase's pre-review (M3) removed it from scope with a reason: the gate
fires on the first transition leaving an alarm enabled, which is a save/enable
event on the Alarms screen, and by the time an alarm is ringing the permission
was either granted or the alarm would not have fired. A prompt on the ringing
path is a no-op at best and a modal over a ringing alarm at worst.

That is a disagreement with a document, not a silent skip — but it leaves a
genuine gap: **nothing calls `AlarmPermissionGate` in `lib/` today**, and the
handoff said one of two phases would.

**Applied.** `docs/sessions/next.md` and the tracker now say explicitly that
the gate belongs to the **alarm-enable path**, that Phase 06 declined it with
a reason, and that it is Phase 07's to wire — so the next session inherits a
decision rather than a dangling "06 or 07".

---

## Low

### P5 — `snooze_service.dart` names `lib/features/ringing/` as the caller, and now that is true

*"The caller (the ringing controller in `lib/features/ringing/`) persists an
occurrence carrying [nextRingAt]"*.

Written against the legacy's layout and ported in Phase 02 when no such
directory existed. It is now accurate, and the controller does exactly what
the sentence describes.

**Applied — verified, left as written.** A rare case of ported prose that the
new code made true rather than false.

### P6 — `AlarmEngine.ringNow` is still called by nothing in `lib/`

Phase 05 built the adapter for it; its dartdoc says it exists for "the single
extra ring the post-dismiss motion check asks for". The motion check is out of
scope here and has no phase row of its own.

Not a defect — an interface method ahead of its caller, like
`AlarmScheduleCoordinator` was before Phase 05. But that precedent is exactly
why it is worth naming: **the coordinator sat fully tested and unconstructed
for three phases and nobody noticed.**

**Applied.** Recorded in `docs/sessions/next.md` as a known uncalled surface
with the reason, so it is inherited as a known state rather than rediscovered.

---

## Summary

| Severity | Count | Applied | Invalid |
|---|---|---|---|
| High | 1 | 1 | 0 |
| Medium | 3 | 3 | 0 |
| Low | 2 | 2 | 0 |
| **Total** | **6** | **6** | **0** |

**P1 is the finding of this pass**, and it is the kind this project exists to
catch: 9,825 lines of ported domain carried a numbering scheme from a
different project, and five phases read past it. The fix — name the layer, not
the phase — is also the thing that stops it recurring when phases renumber
again.

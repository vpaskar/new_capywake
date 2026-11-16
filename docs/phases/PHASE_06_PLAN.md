# Phase 06 — Ringing and emergency stop

**Tracker row:** "Dismiss-exactly-once; reachable escape."

**Status:** revised after `PHASE_06_PRE_REVIEW.md` — 12 findings (4H/5M/3L),
all applied. The revisions are marked **⟲** where they changed a decision.

## Objective

Make a ringing alarm answerable. The engine has armed platform alarms since
Phase 05 and `AlarmEngine.ringingStream` emits when one fires; nothing listens.
This phase builds the listener, the lifecycle writes behind it, and the surface
a half-asleep person actually touches.

Two properties are the phase, and both are in the tracker row:

1. **Dismiss exactly once.** One ring produces one terminal transition. Two
   taps, a tap plus an escape, or a tap arriving while an `await` is in flight
   must not produce two.
2. **A reachable escape.** The alarm can always be stopped without solving the
   puzzle. `CLAUDE.md` makes failing this *always a High finding*.

## What the domain already does — do not rewrite it

Phases 04 and 05 each lost time assuming `lib/core/` could not do something it
already did. Verified by reading, this phase:

| Already in `lib/core/` | File |
|---|---|
| `escape()` — triggered/snoozed → escaped, terminal, separate from dismiss | `lifecycle/alarm_status_service.dart:135` |
| `dismiss()`, `trigger()`, `snooze()`, illegal transitions throw | same file |
| Snooze math, strict shrinking, `canSnooze`, `isFinalAlarm` | `lifecycle/snooze_service.dart` |
| `isFinalAlarm` is **not** `!canSnooze` — documented, two different reasons | `snooze_service.dart:106-128` |
| `escapeVisibilityFor(easing)` — when the escape becomes prominent | `puzzle/puzzle_settings.dart:166` |
| `PuzzleEscapeStrictness.{confirm,confirmAndHold}` — **no "off" value** | `puzzle/puzzle_settings.dart:26` |
| Puzzle generation, rounds, validation, exposure, easing | `puzzle/` (12 files) |
| `timeParts` — digits and AM/PM separately, for styling them apart | `alarm_format.dart` |
| Volume ramp | `wake/wake_volume_ramp.dart` |

**Nothing about the escape is invented in this phase.** The visibility rule,
the strictness ladder and the terminal status all exist and are tested. Phase
06 wires them to a surface and must not re-decide them.

## Scope

### In

1. `RingingController` in `lib/features/ringing/` — listens to
   `ringingStream`, resolves/creates the `AlarmOccurrence`, drives the FSM,
   exposes a `RingingSession` value type.
2. **The dismiss-exactly-once guard**, in the controller, unit-tested.
3. `RingingScreen` — the surface from the Ringing board: header, `timeParts`
   clock, hero scene, snooze/dismiss row, final-alarm note.
4. **⟲ (H3) All three `DismissMethod` values**, not just `puzzle`:
   `normalButton` (a plain labelled stop), `holdToDismiss` (a sustained hold
   with a stated duration), `puzzle` (a round plus the escape).
5. The escape flow: labelled control → confirmation → optional hold, per
   `escapeStrictness`.
6. Route + presentation: ringing covers everything, is not dismissible by
   back, and is driven by the engine, not by navigation.
7. **⟲ (L2)** A reusable press-and-hold control in `lib/design/`, since two
   unrelated flows need it: `holdToDismiss` and
   `PuzzleEscapeStrictness.confirmAndHold`. The legacy's
   `hold_to_act_button.dart` imports Flutter and is therefore not ported;
   this is written fresh against our tokens.

### Out

- Motion confirmation / "still up?" re-ring. The legacy has it; it is a
  distinct feature with its own sensor plumbing, not part of "ringing and
  emergency stop". `ringingStillUp*` and `ringingMotionReRingNote` ARB keys
  already exist and stay unused this phase, which is not a TODO placeholder —
  they are ported vocabulary, not a stub. **⟲ (L3)** Verified rather than
  assumed: `tool/check_arb.dart`'s contract is locale completeness against the
  English template (missing / stray keys per locale) — it does **not** check
  usage, so unused ported keys are not a gate failure.
- **⟲ (M3) `AlarmPermissionGate` wiring — removed from this phase's scope.**
  The draft claimed it. It cannot correctly live here: the gate fires on *the
  first transition leaving at least one alarm enabled*, which is a save/enable
  event on the Alarms screen. By the time an alarm rings, the permission was
  either granted or the alarm would never have fired — so a prompt on this
  path is a no-op at best and a modal over a ringing alarm at worst. It
  belongs to the alarm-enable flow. This is a scope **correction**, not a
  deferral: the phase was claiming work its own surface cannot host.
- The settings UI for puzzle shape (Phase 07).
- History rendering of `escaped` (Phase 08, Stats).
- Android verification — **no emulator exists; never mark it tested.**

## The reference, and what it does not contain

**There is no primary mockup for the ringing screen.** The five Tier A
references are Home, Alarms, Add/Edit, Settings, Stats. Measured: no file
matching `*ring*`/`*wake*`/`*puzzle*` under
`reference/01_REFERENCES/screens/`.

The one reference that exists is a **board panel**, not a screen export:
`reference/01_REFERENCES/boards/01_earlier_all_screens.png`, bottom-right
panel, labelled "Ringing". **⟲ (L1)** Measured: the board file is 1448×1086
(PIL), and the ringing phone was read from the crop region
`x 0.615–0.845, y 0.54–0.97` — i.e. an extent of roughly 333×467 px, of which
the phone's screen content is smaller still. That figure is an **approximate
panel extent read off a crop box**, not a measurement of a screen export —
which is itself precisely why Tier A cannot apply.

**Consequence, stated up front: the ringing screen has no Tier A tolerance.**
Tier A is defined as "±4 pt on major block positions at 393×852" measured
against a 851×1847 mockup. A 230-px-wide board panel cannot produce a ±4 pt
measurement; scaling it up would be inventing precision. So:

- The ringing screen is built to the board's **structure and order**, which is
  legible, and to the existing design tokens, which are Tier A everywhere else.
- Its capture is recorded and its deviations named, as `CLAUDE.md` requires.
- **No Tier A block table row is claimed for it**, and no "matches the mockup"
  claim is made. This is declared here rather than discovered at review.

**⟲ (M4) The standard it *is* held to**, since "deviations named" is
unenforceable without a reference to deviate from:

| Standard | Measurable as |
|---|---|
| Design tokens | Spacing scale, radii, type scale and palette are the same constants Tier A screens use; a value off-scale is a defect |
| Control reachability | The action row meets or exceeds the control-height floor the other screens use — measured with `tester.getRect`, not asserted from the constant passed in (the Phase 03 rule) |
| Board comparison | **Order and presence** of elements, which a board panel can support: wordmark, label, clock, hero, puzzle card, action row, top to bottom |

The post-review states both: what the tokens gate confirmed, and what the
board comparison showed.

### What the board does show

Reading the panel top to bottom:

| Element | Board | Decision |
|---|---|---|
| Wordmark + capy | "CapyWake" with the small capy above | Use `AppArt.wordmark` |
| Alarm label row | ☀ "Wake up & move" | Real `Text` from `alarm.label` |
| Clock | `7:30` large, `AM` small | **`AlarmFormat.timeParts`** — exactly why it exists |
| Hero | Capybara stretching awake in bed, window, plant | See asset gap below |
| Puzzle card | "Wake Puzzle: Math Sprint" / "Solve to dismiss the alarm" / `12 + 9 = ?` / four answer chips | Real widgets, real `PuzzleRound` |
| Action row | `zZz Snooze (5 min)` · `🔒 Dismiss (Solve the puzzle first)` | See below |

### Where the board is wrong, and must not be copied

**The board shows no emergency escape.** The action row is Snooze + a *locked*
Dismiss reading "(Solve the puzzle first)". Taken literally that is a surface
where a person who cannot solve the puzzle has no way to stop the alarm.

`CLAUDE.md`: *"Never ship a puzzle without a reachable emergency escape.
Locking someone out of silencing their own alarm is a safety defect and always
a High finding."*

So the board is followed for layout and **overridden for safety**: the escape
is present, labelled, and reachable from the first frame. `puzzleEscapeAction`
("Stop without solving") already exists in ARB for exactly this. The
substitution is logged, and the deviation from the board is deliberate and
named here rather than silently resolved.

A second, smaller divergence: the locked Dismiss button with explanatory
sub-copy is a disabled control carrying a reason. Keeping a disabled primary
action on screen is defensible, but the *copy* in the board — "Solve the puzzle
first" — reads as an instruction that there is no other way out, which the
escape contradicts. The puzzle surface states the puzzle; the escape states
itself.

## Asset gaps — found by measurement, reported here and in `asset_gaps.md`

Per `CLAUDE.md`, these are reported **in the session**, not only in a document.

**G17 — filed as "no ringing scene exists", then largely withdrawn on
measurement.** The wrong first answer is recorded because the correction is
the useful part, and because this phase's own rule is to check the instrument
before believing it.

**What was filed.** `AppArt.scenes` holds exactly four entries
(`lib/design/art.dart:53-58`): `home`, `alarms`, `stats`, `settings`. None is
named for ringing, and the board's hero is a bedroom scene. The draft of this
plan proposed substituting `header_scenes/upscaled_older/cozy_bedroom.png`
(measured 1200×800 RGB) and logging two sub-gaps — that it is the older
generation, and that it **contains no capybara** where the board's hero is a
capybara waking.

**Why that was wrong.** `assets/art/scenes/alarms.webp` — measured
**1179×786 RGB**, the current generation, exactly the width a 393 pt hero
needs at 3× — **already is the board's ringing hero.** Viewed rather than
inferred from its filename: capybara in bed, both arms up mid-stretch, mouth
open yawning, sunrise through a window, and a ringing alarm clock on the
nightstand with motion marks. Element for element, the board's composition.

`asset_gaps.md`'s own G16 note already said it — *"`alarms.webp` … is a
waking-in-bed composition"* — and called it the weaker fit for Alarms and
Add/Edit, whose mockups show a capybara hugging a clock and a third
composition again.

So the asset is not missing. **It is currently used on the two screens it fits
worst and not on the one screen it fits best.**

| | |
|---|---|
| Verdict | **Not a gap** for this phase |
| Used | `assets/art/scenes/alarms.webp`, unmodified |
| Tier B substitution | **None** — the matching asset, not a stand-in |

What remains genuinely open is **not this phase's to fix**: Alarms and
Add/Edit keep a hero their own mockups do not show. Closing that needs *two*
new scenes (an Alarms hero per `02_ALARMS.png`, an Add/Edit hero per
`03_ADD_EDIT_ALARM.png`), which would free `alarms.webp` to be the ringing
scene it already is. Filed in `asset_gaps.md` as G17; no screen is blocked.

**No new art is generated** (Tier B rule), and nothing is substituted
silently.

## Dismiss-exactly-once — the actual risk, with the legacy's evidence

**The legacy does not have this guard.** Read read-only at
`../capywake/lib/features/ringing/`:

- `ringing_controller.dart:339` `dismiss()` — body is
  `final session = _current; if (session == null) return;` then `await
  _engine.cancel(...)`, `await _repository.upsertOccurrence(...)`, then
  `_emit(null)`.
- `ringing_controller.dart:500` `escape()` — the same shape.
- `ringing_screen.dart:116-117` — `onSolved:` and `onEscape:` call straight
  into those methods; the screen holds no busy flag (`grep` for
  `_busy|_acting|_dismissed` finds only `_puzzleOpen`).
- `test/features/ringing/` has no test for a double call.

`_current` is only cleared by `_emit(null)` **after two awaits**. A second
invocation entering during that window passes the null check and calls
`_status.dismiss()` on an occurrence whose in-memory copy is still
`triggered` — and on the *persisted* row, the second write would overwrite
`dismissedAt`. Worse, dismiss-then-escape in that window produces two terminal
writes of different statuses, and whichever lands last decides what History
says about the morning.

This is the defect the tracker row names, and the previous project shipped it.

### ⟲ (H1) The ring handler has the same defect, and it is worse

The draft of this plan guarded only the terminal actions. The pre-review found
that `_onRinging` has the identical shape — four awaits before anything is
persisted, no latch:

```
await _cancelMotionWindow();
final alarm = await _repository.getAlarm(event.alarmId);
final loaded = await _loadOrCreateOccurrence(alarm: alarm, firedAt: ...);
final triggered = _status.trigger(occurrence: occurrence, now: event.firedAt);
await _repository.upsertOccurrence(triggered);
```

Two ring events for one alarm inside that window both find no existing row and
both create one — **two occurrence rows for one morning**, each with its own
id. History double-counts, and `AlarmScheduleCoordinator` — which reads
finished and snoozed occurrences to decide what to re-arm — sees a row the
other path does not know about.

Phase 05's adapter de-duplication fixes `BehaviorSubject` *replay to a late
subscriber*. It does not make the stream single-delivery against a genuine
platform re-report, an app resume re-emitting, or the controller being rebuilt.

**"Dismiss-exactly-once" is the user-visible half of a property that must hold
for every transition, including the first one.**

### The guard this phase builds

Three layers, in order of what they actually defend:

1. **A per-alarm serialization latch**, set **synchronously** before the first
   `await` and cleared in a `finally`, covering `_onRinging`, `dismiss`,
   `escape` and `snooze` alike. Per-alarm rather than global so two genuinely
   different alarms are not serialized against each other.
2. **A status check**, because a latch only covers one process lifetime:
   refuse any transition whose current occurrence status `isTerminal`
   (`lib/core/models/alarm_status.dart:57`). This is what survives a restart.
3. **A ring-handler idempotence check**: a ring whose target already has a
   non-terminal occurrence with `triggeredAt` set is absorbed, not re-created.

The FSM's own `_expect` throws and is the fourth layer — but throwing from an
async gap is not a safe last line of defence for a person holding a ringing
phone, so it stays the assertion, not the mechanism.

Tested directly, without awaiting the first call in each pair:

- `dismiss()`×2 → one `upsertOccurrence`, status `dismissed`, no exception
- `escape()`×2 → one write, status `escaped`
- `dismiss()` + `escape()` interleaved → one terminal write, not two
- **two ring events for the same alarm → one occurrence row, not two**
- an action on an already-terminal occurrence → no-op, not a throw

### ⟲ (H4) A second alarm firing while one is ringing

Two alarms at 07:00 and 07:01, or one ringing while a snoozed one re-rings.
The legacy handles this implicitly — `_emit` overwrites `_current`, so the
second ring silently replaces the session and the first occurrence stays
`triggered` until the 30-minute missed sweep. That inherits a case where a
user dismisses what looks like the alarm in front of them and **a different
alarm's row is written**.

Stated rather than inherited:

- A ring for the **same** alarm is absorbed by the guard above.
- A ring for a **different** alarm supersedes the session, and the superseded
  occurrence is deliberately left non-terminal — it genuinely was not
  answered, and `evaluateMissed` is the right thing to classify it later.
- The session carries its alarm id, and a terminal action asserts it still
  matches the occurrence it is about to write.

Tested.

## Safety rules this phase is bound by

| Rule | How it is met |
|---|---|
| Escape always reachable | Present from first frame; `PuzzleEscapeStrictness` has no "off"; visibility from `escapeVisibilityFor` |
| No overpromising | No copy claims reliability beyond the OS clock; no DND/silent-mode implication |
| Large, reachable controls | Action row measured with `tester.getRect` against the control-height floor — not asserted from the constant passed in |
| **No animation on the ringing surface** | **⟲ (H2) A test**, not an intention — see below |
| Honor `disableAnimations` | Named surface, named reader, own test case |
| Puzzle copy is a quiet instruction | Ported ARB already is: "Which number comes next?" |
| No scores/streaks on the puzzle | None added |

### ⟲ (H2) "No animation" needs a mechanism, not an intention

The draft listed this as "Static. No implicit animations." Three previous
phases each found a rule that was written down and then violated because
nothing checked it. The risk here is concrete: `PuzzleType.digitRecall`,
`gridPatternRecall` and `spotTheChange` all **show content then hide it**, and
a timed reveal is the natural implementation — which is an animation on the
ringing surface.

- The memorise → recall reveal is driven by **explicit state advanced by the
  controller's injected clock**, not by an `AnimationController`. That also
  makes it testable without pumping real time, the same reasoning the legacy
  used for its motion window.
- A test asserts no running animation on the ringing surface after settle, so
  it runs inside `flutter test` rather than living in prose.
- `disableAnimations` is a separate obligation with its own case: the surface
  reads it from `MediaQuery` and the test asserts the reveal degrades to a
  non-timed presentation rather than silently keeping its timing.

## Tests

Mirrored under `test/features/ringing/`.

| Area | What is asserted |
|---|---|
| Controller — ring | A `RingingAlarm` creates/loads an occurrence and transitions it `triggered` |
| Controller — **exactly once** | double-dismiss, double-escape, dismiss+escape, each → one terminal write |
| **⟲ (H1) Controller — ring idempotence** | **two ring events for one alarm → one occurrence row, not two** |
| **⟲ (H4) Controller — second alarm** | a different alarm supersedes the session; the superseded row stays non-terminal; a terminal action writes the occurrence it is about |
| Controller — terminal refusal | an action on an already-terminal occurrence is a no-op, not a throw |
| Controller — snooze | uses `SnoozeService`; `isFinalAlarm` distinct from `!canSnooze`, both covered |
| Controller — escape | writes `escaped`, not `dismissed`; cancels the engine |
| Screen | clock renders via `timeParts`; final-alarm note; snooze hidden when unavailable |
| **⟲ (H3) Screen — per method** | one case each for `normalButton`, `holdToDismiss`, `puzzle` |
| **⟲ (H3) Screen — failed hold** | an abandoned hold leaves the control reachable; it never escalates or locks out |
| Screen — escape | the control is present **before any wrong answer**, and prominent after `toleratedWrongAnswers` is exceeded |
| **⟲ (M5) Screen — escape across a snooze** | visibility, once `prominent`, stays `prominent` for the occurrence |
| Screen — strictness | `confirm` → one confirmation; `confirmAndHold` → confirmation + hold |
| **⟲ (H2) Screen — no animation** | no running animation on this surface after settle |
| **⟲ (H2) Screen — `disableAnimations`** | the reveal degrades to a non-timed presentation |
| a11y | escape control has a semantic label; controls measured against the tap-target floor with `tester.getRect` |

### ⟲ (M5) Escape visibility is not reset by a snooze

`escapeVisibilityFor` reads `PuzzleEasingState.wrongThisRound`, and the legacy
seeds each round from `Object.hash(occurrence.id, occurrence.snoozeCount)` —
so a snoozed re-ring is a **fresh round**, which also resets `wrongThisRound`
to zero.

That would demote the escape from `prominent` back to `available` at exactly
the moment the user is least able to find it: they already failed five times,
snoozed, and came back.

**Decision:** the puzzle round is fresh per ring (a new ring is a new
attempt), and the **escape visibility is not**. Once the threshold has been
crossed it stays `prominent` for the remainder of the occurrence, carried on
the session rather than on the round. Tested across a snooze.

### Registered expectations — restated if measurement disagrees

- **New tests: 55–80.** (Phase 05 registered 25–40 and measured 87; this is a
  larger surface, so the band is raised but still a guess.)
- **⟲ (M2) ARB keys: 405 → 405–412**, but the count is not the mechanism. The
  draft reasoned "162 ringing keys exist, so few are needed" — the real risk
  runs the other way: with 162 near-miss keys available, the likely error is
  **reusing a key whose text does not fit**. `ringingDismissAction` is "Stop
  alarm", which suits a plain stop but not a puzzle-gated disabled control;
  `alarmDismissMethodHold` is "Press and hold", a *settings* label, not a
  button on a ringing screen. **So: for every string on this surface, an
  explicit reuse-or-new decision, justified by reading the existing value —
  never by its key name.**
- **⟲ (M1) Coverage, directional and falsifiable.** The draft predicted
  "95–97.5%" while also saying it would fall — a band satisfied by a rise or
  a fall registers nothing. Restated: `lib` **falls** to **95.5–97.3%**; a
  rise, or a fall past 95.5%, is restated in the post-review rather than
  passed quietly. Gates `lib` ≥ 85 / `lib/core` ≥ 95 / `lib/data` ≥ 85 hold.
- **`lib/core` exactly unchanged at 99.49%** — this phase adds no core code,
  so a single digit of movement falsifies it and means something was written
  in the wrong layer.

## Dependencies

**No new packages.** Everything needed is present: the engine seam, the
repository, Riverpod, the puzzle layer, the design system.

## Risks

| Risk | Mitigation |
|---|---|
| The surface invents safety rules already in `lib/core/` | Rules enumerated above with file:line; surface reads them |
| Guard put in the widget, untestable | Guard lives in the controller; test calls it directly |
| Board treated as a Tier A mockup | Declared non-Tier-A here, before measuring |
| Scope creep into motion confirmation | Explicitly out; ported ARB keys left unused and said so |
| Comment budget bites every new file | Trim by hand; never baseline |
| Claiming device verification not performed | Phase 05's standard: record what ran, never inherit |

## Acceptance

1. A platform ring opens the ringing surface; the occurrence becomes
   `triggered`.
2. Dismiss writes `dismissed` **exactly once** under concurrent invocation.
3. Escape writes `escaped`, never `dismissed`, and is reachable from the first
   frame with no puzzle solved.
4. Snooze respects cap, strict shrinking, and the final-alarm boundary.
5. Validation block passes, `flutter analyze` clean including infos.
6. A capture is recorded; deviations named; **no Tier A claim**.
7. Asset gap G14 filed with measurements and reported in-session.

---

## Implementation note — a third duplicate-row path, found by this phase's own test

The pre-review's H1 identified two ways one morning gets two occurrence rows:
racing ring events, and a terminal action on stale state. Implementation found
a **third**, and the test for the final-alarm boundary is what surfaced it.

`_findOccurrence` matched a ring to its morning on
`AlarmScheduleService.targetForRing`. That function's own doc says it returns
the alarm's wall-clock target only while the ring falls inside the wake window
leading up to it, and the fire instant otherwise — naming **"a late platform,
a snooze, the motion check's extra ring"** as the cases with "no window left
to belong to".

Measured, not inferred: for a 07:00 Europe/Berlin alarm with no wake window,
`targetForRing` returns `06:00Z` for the 06:00Z ring and `06:09Z` for the
06:09Z snooze re-ring.

So **every snooze re-ring resolved to a target the morning's row was never
stored under**, found nothing, and created a second row — with `snoozeCount`
reset to 0, which also silently defeats the cap and the final-alarm boundary.
The symptom that exposed it was the final-alarm test reading `false`.

Fixed by matching a live `snoozed` row on the ring it is waiting for
(`AlarmOccurrence.nextRingAt`) before trying the scheduled target. Both keys
are needed: the scheduled target names the morning, `nextRingAt` names the
pending re-ring.

A second implementation finding, same test: **escape visibility cannot live on
the live session.** The session is `null` between a snooze and its re-ring, so
a `_current`-based check lost the raised state exactly when M5 said it must
not. Now keyed by occurrence id, cleared when the occurrence terminates.

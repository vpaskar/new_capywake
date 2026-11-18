# Phase 16 — Pre-review (adversarial, before any code)

Reviewed: `PHASE_16_PLAN.md` draft, the `pedometer` 4.2.0 source, the Phase
15 motion recipe, `GameLaunch`, both hosts, `ChallengePoolPicker`,
`PermissionMapper`. Every finding is applied in the revised plan (§11) or
marked invalid with a reason.

## High

**H1 — Starting the step stream before access is `ready` prompts during a
ring.** On iOS, `CMPedometer.startUpdates` with `notDetermined` shows the
system dialog; the plan only says "never prompt while ringing" about the
prompt widget. The view must **never listen to `steps` unless `access()`
returned `ready`**, and a test must pin `listenCount == 0` for every other
answer. *Applied.*

**H2 — A stream error leaves the tally waiting for 16 accelerometer steps.**
A missing sensor (Android `getDefaultSensor == null`) or a revoked grant fails
the stream at once. Waiting 16 steps on a dead source is lost work for a
half-awake user. **An error or done on the step stream demotes to `motion`
immediately.** *Applied.*

**H3 — A grant given in the practice card does not reach the running game.**
The view reads access once at mount; the plan has no path for "allowed just
now", nor for "came back from Settings". **The view re-reads access on app
resume and when the prompt resolves, and `StepTally` promotes `motion →
sensor` mid-round, keeping every step counted so far.** Demotion stays final
(no flip-flop). *Applied.*

**H4 — `access()` can throw.** A `MissingPluginException` (channel not
registered, widget tests on the real implementation) or a `PlatformException`
would surface as an unhandled future error and leave the source undecided.
**Any throw maps to `unavailable`.** *Applied, tested over a channel with no
handler.*

## Medium

**M1 — Two sensors for the whole round is a battery bug.** The accelerometer
is only needed until the step sensor proves itself. **Cancel the motion
subscription on the sensor's first delivery**; keep it when in `motion`.
*Applied.*

**M2 — Before `access()` resolves, no source is in force.** Steps taken in the
first ~100 ms are lost, and a test that emits immediately races the future.
**Start in `motion`; promote when `ready` arrives.** *Applied (same rule as
H3).*

**M3 — iOS `restricted` mapped to `permanentlyDenied` shows "Open Settings"
that cannot fix it** (parental controls). **`restricted` → `unavailable`.**
*Applied in the mapper.*

**M4 — The pool sheet must never block the switch.** If the toggle waits for
the sheet, "Not now" could leave Step Quest off and the pool confused. **The
toggle applies first; the sheet only opens on an off → on change and only
for `needsPermission` / `permanentlyDenied`.** *Applied.*

**M5 — The prompt must be provably absent from the ringing host.** "Never on
a ring" is a sentence, not a guard. **A host test rings Step Quest with
`needsPermission` and asserts no prompt and no `requestAccess()` call;
mutation-checked by calling it from the view.** *Applied.*

**M6 — iOS update handler runs off the main thread.** `CMPedometer` delivers
on its own queue; an `eventSink` call there is undefined. **Dispatch to main**
(as `sensors_plus` does). *Applied.*

**M7 — Card height.** Shake DJ already uses most of 424 pt with a 142 pt field;
Step Quest adds a count and a source caption. **Field budget set from a
measured card, and the clock guard runs for this game.** *Applied.*

## Low

**L1 — The rhythm gate makes the count jump 0 → 4.** Expected behaviour of a
pedometer's regulation mode; the bob animates once per release, not four
times. *Applied (documented in the round test).*

**L2 — Shaking can count as steps (tier 2).** Peaks under the jolt ceiling at
≥ 300 ms spacing pass. The tap button already finishes the game, so this
grants nothing a user lacks; constants named. *Invalid as a defect — the
fallback makes it moot; recorded as an owner question.*

**L3 — `GameBlockedReason.stepCount` would become a lie** ("a capability
CapyWake does not ask for"). Remove it and its test line. *Applied.*

**L4 — `puzzle_pool_test` asserts Step Quest is not screen-reader solvable.**
It becomes solvable (button + live region). Update the test to the camera
game. *Applied.*

**L5 — Store-visible change.** Android's listing gains "physical activity";
iOS's purpose string changes. Owner note in `OPEN_QUESTIONS.md`, with the
exact strings. *Applied.*

**L6 — The architecture plan and tracker still say "blocked".** Update both
in the same commit. *Applied.*

**L7 — Asset gap.** The poster's capy walks; `game.capy.hiking` is one still
pose, so the walk is a bob, not a cycle. **Report in session and log as a
new gap** (no art generated). *Applied.*

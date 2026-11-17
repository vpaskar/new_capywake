# Phase 09 — pre-review (adversarial, before any code)

One pass against the plan, hunting for what it gets wrong, over-claims, or
leaves able to ship a defect. Every finding **High / Medium / Low**, applied or
marked invalid with a one-line reason. No "deferred".

**12 findings: 4 High, 5 Medium, 3 Low.**

---

## High

### H1 — The plan misattributes the `?? true` default; the real first-run path is simpler and the plan's test 2 would be testing a case that cannot occur

The plan (and the ported dartdoc) lean on `mappers.dart:257`
`(map['hasCompletedOnboarding'] as bool?) ?? true` to explain why the gate needs
two signals. I verified the actual data path and it is **not** what the plan
says:

- **True fresh install** = *no settings row at all*. `getSettings()` returns
  `UserSettings.initial` (`capy_wake_repository.dart:167`) and `watchSettings()`
  maps a null row to `UserSettings.initial` (`:174`). `UserSettings.initial`'s
  `hasCompletedOnboarding` is the **model default `false`**
  (`user_settings.dart:92`). So a fresh install yields `false` directly — the
  `?? true` mapper branch is **never reached**, because there is no row to map.
- The `?? true` branch only fires for a **row that exists but whose JSON lacks
  the key**. `toJson` (`mappers.dart:199`) *always writes the key*, so this
  app never produces such a row. In a greenfield rebuild at `schemaVersion = 1`
  with no users, **no legacy-shaped row can exist.** The `?? true` is dead-but-
  defensive, not a live grandfathering path.

**Consequence for the plan:** the two-signal design is still correct and still
worth keeping (the `hasExistingAlarms` signal is the real guard, and the safety
property holds), but the *reason* the plan gives is wrong, and **plan test 2
("a grandfathered row with flag absent → true") tests a row this app cannot
write.** A test that constructs an impossible artifact is Phase 08's "card 1
top on a segment with no cards" shape.

**Applied.** Rewrite the plan's persistence section to state the real path:
fresh install → no row → `initial` → `false` → onboarding shows; alarm-exists →
second signal suppresses; completed → flag write suppresses. Replace test 2:
instead of a fictional grandfathered row, test **the real race** — the
`watchSettings` stream emits `UserSettings.initial` *before* the DB read
resolves on a fresh install, and the gate must treat "settings not yet loaded"
and "settings loaded, fresh" both as safe (the first → don't redirect yet or
redirect, but never flap; the second → redirect). That is the live hazard, not
a legacy row. The `hasExistingAlarms` signal keeps its own real test.

### H2 — "No permission on the welcome screen" is an assertion the plan never makes testable, and it is the one safety-adjacent claim

The plan says the welcome requests no permission, but a widget test that merely
renders the screen and checks it "looks right" cannot prove a *negative* —
that no `requestNotification` fired. Phase 08's whole lesson is that a rule
stated is not a rule held unless something fails when it is violated.

**Applied.** Test 4 must use a `FakePermissionService` spy (or a counting fake)
and assert **zero** calls to `requestNotification`/`requestExactAlarm`/`read`
from the welcome screen's lifecycle, including its CTA tap *before* navigation.
Mutation: wire a stray `requestNotification()` into the welcome's `initState`
and confirm that specific test fails. Without the spy, the claim is on trust.

### H3 — The redirect can strand a returning user mid-flow, or loop, if "settings loading" is read as "fresh install"

`go_router`'s `redirect` runs on **every** navigation, synchronously, against
whatever the providers currently hold. On a cold start the settings stream has
not emitted yet; a naive `ref.read(userSettingsStreamProvider).value ??
UserSettings.initial` yields `initial` (flag `false`) for *everyone* for the
first frame — including a returning user with completed onboarding whose row
simply has not loaded. If the redirect fires on that transient, a returning
user is **bounced into onboarding** on every cold launch until the stream
catches up, and may complete it redundantly.

**Applied.** The redirect must distinguish **loading** from **loaded-fresh**.
`AsyncValue` carries this: `loading` → return `null` (no redirect, stay put);
`data` with `needsOnboarding` → redirect; `error` → `null` (fail safe to the
app, never trap). A dedicated test drives the redirect with a *pending* stream
and asserts **no redirect**, then with the resolved fresh value and asserts the
redirect. This is the H1 race made concrete and is the single most likely
real-world defect in the phase.

### H4 — Routing the first-alarm CTA to `/alarms/new` assumes the Add/Edit Save path both persists an enabled alarm and triggers the prompt — neither is this phase's code, and the plan asserts it works without checking

The plan's value rests on: welcome CTA → `/alarms/new` → user saves →
first-enable transition → `AlarmPermissionPrompt` fires. But `/alarms/new`'s
default enabled-state, whether Save returns to Home or to the (now-redirecting)
shell, and whether the prompt's `before`/`after` lists are computed across the
onboarding boundary are all **Phase 04/07 code this phase depends on but does
not own.** If a newly-created alarm defaults to *disabled*, the first-enable
transition never happens from onboarding and the "natural permission ask" claim
is false.

**Applied.** Before implementing, read `alarm_edit_screen.dart`'s save path and
the default `Alarm.enabled` for a new alarm, and confirm the prompt is wired to
fire on that save. If a new alarm defaults disabled (so the prompt waits for a
later toggle), **say so in the plan** — the onboarding hand-off then reaches
Add/Edit but the permission ask is still at the user's first enable, which is
*fine and honest* but must be described accurately, not as "the CTA triggers the
prompt". Verify on the simulator with taps landing (the task requires a real
interaction check, not an inference).

---

## Medium

### M1 — "+2 to +4 ARB keys" may be 0: the ported set might already cover the CTA and skip

21 onboarding keys are ported, including `onboardingSkip`, `onboardingNext`,
`onboardingFinish`, `onboardingWelcomeTitle/Body/SetupNote`. The welcome's
primary CTA might reuse an existing key (e.g. a "set your first alarm" may map
to an existing alarms string like the Add Alarm label) and Skip to
`onboardingSkip`. The plan should not *invent* keys that duplicate ported ones
— that is the cross-app drift `brand-voice` guards against, and locally it
bloats 10 ARB files.

**Applied.** Before adding any key, grep the ported ARB for a fit:
`onboardingSkip` for the secondary; check whether an existing alarms CTA string
suits the primary, or whether a new `onboardingFirstAlarmCta` is genuinely
needed. Register the real number after that check. If it is **0**, say so and
restate (Phase 04 planned 0 and measured +4; the discipline runs both ways).

### M2 — The plan names `SceneCrop.home` or "sunrise bedroom" but there is no sunrise scene asset verified present

`scene_header.dart` exposes `home`, `alarms`, `stats`→history, `settings`.
There is **no `sunrise`/`onboarding` scene**. The legacy welcome used
`CapyScenery.sunriseBedroom` — a legacy asset not necessarily in this repo's
package. Picking a scene that does not exist is a build break; picking `home`
reuses the Today hero, which is defensible but should be a stated Tier B
substitution per `CLAUDE.md` ("log the substitution by name").

**Applied.** Verify the asset list before implementing. Use `SceneCrop.home`
(present) as the welcome backdrop and **log it in `asset_gaps.md`** as the
substitution for the splash board's sunrise-bedroom scene, by name. No new art.

### M3 — The plan's redirect lives "in `lib/app/`" but does not say *where*, and `createRouter` takes `initialLocation` used by tests

`createRouter(initialLocation: ...)` is parameterized so tests deep-link. A
`redirect` added to the top-level `GoRouter` must not break the existing
`initialLocation: Routes.home` default or the per-route test entries (every
screen test that constructs a router). A global redirect that fires for a
first-run fixture could bounce *existing screen tests* into onboarding.

**Applied.** The redirect reads a provider; **existing tests supply a container
where settings resolve to a completed/alarm'd state** (or the redirect is
null-safe on loading, per H3, so a test that never emits settings never
redirects). Verify the full suite stays green — a redirect is a cross-cutting
change and the regression surface is every router-based test. Add the redirect
such that the *absence* of a settings emission = no redirect (H3), which also
protects every existing test by construction.

### M4 — `completeOnboarding()` writing through `_update`'s read-modify-write can race a concurrent settings write

`_update` does `getSettings()` → mutate → `saveSettings()`
(`settings_controller.dart:99-102`), a read-modify-write with no transaction.
If onboarding completes while another settings write is in flight (unlikely in
onboarding, but the CTA path touches Add/Edit which can write defaults), one
can clobber the other's field. This is pre-existing in every `_update` caller,
not new — but `completeOnboarding` is the first write whose *loss* re-triggers
a full-screen redirect, so its stakes are higher.

**Applied as a bounded check, not a rewrite.** Do not re-architect `_update`
(out of scope, touches every setter). Instead: complete onboarding via the
**same** `_update` path for consistency, and add a test that completing
onboarding and then reading settings shows the flag true. If a realistic race
exists it will show as a flaky test; if not, the single-write path is fine.
Note the shared-`_update` race as a carry-forward observation, not a Phase 09
fix.

### M5 — No test asserts the ported puzzle/strictness strings stay unused on purpose

The plan carries 9 ported strings forward unused and *names* them so they are
not mistaken for dead-string defects. But Phase 08 found `sleepHistoryEmpty`
exactly this way, and protected it with a test asserting it is **not** rendered.
Naming in a doc is weaker than a test.

**Applied.** Add a lightweight assertion that the onboarding welcome does **not**
render the puzzle/strictness onboarding strings (they belong to Phase 10), so a
later accidental wiring is caught. Mirrors Phase 08's `sleepHistoryEmpty`
guard. Keep it one test, not nine.

---

## Low

### L1 — "no onboarding capture compared to a mockup" needs a guard, or a later phase re-adds it to `capture_test.dart`

The plan correctly refuses a Tier A onboarding claim. But
`integration_test/capture_test.dart` captures six screens and `compare.dart`'s
`blocksFor()` `exit(2)`s for a screen with no block table. If onboarding is
never added to `capture_test.dart`, nothing breaks. If a well-meaning later
phase adds it, `compare.dart` will `exit(2)` and *look* like a regression.

**Applied.** Do **not** add onboarding to `capture_test.dart`. State in
`docs/visual/onboarding/README.md` that onboarding has no mockup, no block
table, and is deliberately excluded from the Tier A capture set — so a later
phase reads the reason instead of adding it and hitting `exit(2)`.

### L2 — The plan says `lib/core` and `lib/data` are "unchanged" but a new writer may need a new provider or export

`completeOnboarding` lives in the controller (features), reusing `_update` —
no core/data change expected. But if the gate needs a combined
"needsOnboarding" provider folding settings + alarm count, that provider lives
in `lib/` and must be placed correctly (features or app, not core — core stays
Flutter-free and the predicate is already there).

**Applied.** The combining provider, if any, lives in `lib/app/` or
`lib/features/onboarding/` (it reads Riverpod/Flutter-adjacent providers), never
`lib/core/`. `lib/core` and `lib/data` stay byte-unchanged; confirm with
`git diff --stat` before commit.

### L3 — Comment-budget risk on the gate file's rationale

The two-signal gate and the H3 loading/loaded distinction are subtle and invite
a long explanatory comment — exactly the 40-line block the budget exists to
stop. The ported `OnboardingStatus` dartdoc already carries the full rationale;
the new wiring must not duplicate it.

**Applied.** The redirect's reasoning lives in this phase doc, not in a code
comment. Any doc comment on the new files is ≤ 2 lines / 300 chars and names
the layer, not the rationale. The ported predicate is where the "why two
signals" prose belongs, and it is already there. `grep -rn "Phase [0-9]" lib/`
stays 0.

---

## Outcome

12 findings, all applied, none invalid, none deferred.

The two that change the plan materially:

- **H1** — the plan's persistence story was wrong about which case `?? true`
  covers. The gate design survives; the explanation and one test are corrected.
  A fresh install gives `false` via `UserSettings.initial`, not via the mapper
  default. (This is itself a small finding that contradicts the ported
  dartdoc's emphasis — the grandfathering path it describes cannot occur in a
  no-users greenfield rebuild.)
- **H3** — the live defect risk is the redirect firing on the cold-start
  loading transient and bouncing returning users into onboarding. The gate must
  treat `AsyncValue.loading` as "do not redirect". This gets its own test and is
  the phase's main correctness surface.

Everything else sharpens tests (H2, M5), avoids inventing ARB/art (M1, M2),
protects the existing suite (M3), and holds scope (L1–L3).

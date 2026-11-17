# Phase 09 — Onboarding (just-in-time permissions)

## Objective

Wire up the first-run flow that is already **half-built and wholly unwired**:
`OnboardingStatus.needsOnboarding` (ported pure Dart, tested), the
`hasCompletedOnboarding` settings field (ported, persisted, defaulted), and
21 ported onboarding ARB strings in 10 locales — none of which any line in
`lib/` reads or writes today. An install opens straight onto an empty Home.

This phase builds the `/onboarding` route outside the shell, a gate that
redirects a genuine first run to it, a cozy welcome that ends in a real
first-alarm CTA, and the single write that sets `hasCompletedOnboarding`. It
does **not** rebuild the just-in-time permission request Phase 07 already
ships — it *reuses* it, and the plan says exactly what onboarding adds over it.

## The reference I am building against — stated plainly

**There is no onboarding mockup in `reference/01_REFERENCES/screens/primary/`.**
That directory holds five screens — Home, Alarms, Add/Edit, Settings, Stats —
and none is onboarding. I checked the whole `reference/` tree:

- `screens/alternative/onboarding_full.png` and `onboarding_sunrise.png` are
  **byte-identical** (1,564,490 B) and are **not onboarding at all** — they are
  an early **Home/Alarms** variant with the rejected 4-tab nav (Home · Games ·
  Stats · Settings), a device bezel, 852×1846.
- `screens/alternative/onboarding_illustrated.png` and `onboarding_variant.png`
  are **byte-identical** (1,447,420 B) — a **brand splash**: wordmark, sleeping
  mascot in bed, "Fun wake-up challenges with Capy!", a "Set Alarm" CTA, and
  Games/Stats/Settings tiles. Device bezel, **887×1774**.
- `05_LEGACY_HANDOFFS/.../01_onboarding.png` is byte-identical to
  `onboarding_illustrated.png` — the same splash, re-handed-off.

The handoff's own screen-map
(`03_DOCUMENTATION/02_VISUAL_PRIORITY_AND_SCREEN_MAP.md:28`) points onboarding
at `onboarding_illustrated.png` and asks for: *"Cozy welcome, mascot, first
alarm CTA, optional try-puzzle step, permissions and check for reliable
scheduling; minimal text, no extra obligatory gates."*

**Verdict on fidelity.** The splash board is at **887×1774 (device-bezel
geometry), not the primary 851×1847**, and it draws the **rejected 4-tab/Games
navigation** that Phase 00 overruled. `CLAUDE.md` states the primary mockups
"override every earlier board and exploration." So the splash board is a
**directional reference** (cozy, mascot, first-alarm CTA, minimal text, no
obligatory gates) and **not a Tier-A binding mockup**. **Tier A has nothing to
bind for this phase.** I will not capture an onboarding screen and report
deltas against a mockup that does not exist — the task names that as the worst
defect this project could produce, and `CLAUDE.md` requires the plan to say so
rather than invent a fidelity claim. The onboarding screen is held to **tokens,
the 44 pt tap-target floor, RTL-correctness, no-overpromise copy, and the
reliability/content-integrity rules** — the same bar Phase 06's ringing screen
used when it, too, had no primary mockup.

Evidence of the board identities and dimensions is saved to
`docs/visual/_evidence/onboarding_boards.md`.

## What the legacy's onboarding did — read, not inherited

`../capywake/lib/features/onboarding/` (read-only) is a **three-step
preferences flow**: welcome → pick puzzle types → pick strictness, ending in a
write of `hasCompletedOnboarding`. **It requests no OS permission at any
step.** The legacy asked for permissions later, just-in-time, which is exactly
what this rebuild already does (Phase 07). So "Onboarding — just-in-time
permissions" is a slight misnomer inherited from the tracker: the just-in-time
permission request is *built and shipping*; what is missing is the **first-run
entry** that greets a new install and gets them to their first alarm.

The legacy's puzzle-picker and strictness steps belong to **Phase 10** (puzzle
chooser) and settings the user can already reach. Pulling them in here would
(a) implement a future phase's surface and (b) front-load choices the handoff
explicitly warns against ("no extra obligatory gates", "minimal text"). **This
phase ships the welcome + first-alarm CTA only.** The 9 ported puzzle/strictness
onboarding strings stay unused and are **not** claimed as wired — a deliberate
carry-forward, named here so it is not mistaken for a dead-string defect the
way Phase 08 found `sleepHistoryEmpty`.

## What onboarding adds over the existing permission story — honest answer

Phase 07 already ships: `AlarmPermissionGate` (pure), `AlarmPermissionPrompt`,
`permissionStateProvider` with `.requestNotification`/`.requestExactAlarm`/
`.openSettings`, `FakePermissionService`, the reliability checklist, the setup
walkthrough. **Permissions are already requested at first alarm enable, never
on app start, and the `permanentlyDenied` user is already routed to Settings**
(the Phase 07 bug is fixed: `alarm_permission_prompt.dart:38-40` computes
`sendToSettings` *outside* the `shouldRequestNotification` branch).

So onboarding adds **three** things that do not exist today, and nothing more:

1. **A first-run entry point.** `OnboardingStatus.needsOnboarding` is ported
   and tested but **no gate in `lib/app/` calls it** — `grep` confirms zero
   readers outside the model, the mapper and its own test. A brand-new install
   lands on an empty Home with no greeting. This phase adds the redirect.
2. **The write that closes the loop.** `hasCompletedOnboarding` has **no
   writer** anywhere in `lib/` — `settings_controller.dart` exposes no
   `completeOnboarding()`. Without it the flag can never flip true, so even a
   wired gate keyed on the flag alone would loop. This phase adds the single
   write.
3. **A cozy first-alarm hand-off.** The welcome ends in a CTA that routes to
   `/alarms/new` — the existing Add/Edit screen — so the *very next thing* is
   the first-enable transition the permission prompt already watches for. The
   permission ask stays exactly where it is (first enable), reached naturally
   instead of on a cold empty Home.

If the honest answer to "what does onboarding add" were "very little", the plan
would say so. It is not nothing — the entry point and the write are genuinely
absent — but it is **deliberately small**, and the permission request is
**reused, not rebuilt**. Reporting that the permission half was already done is
the finding, not a reason to pad the phase.

## The gate's two-signal design — corrected in pre-review (H1)

`OnboardingStatus.needsOnboarding(hasCompletedFlag, hasExistingAlarms)` returns
`!hasCompletedFlag && !hasExistingAlarms`. Both signals are load-bearing, but
the pre-review (H1) found the ported dartdoc's *grandfathering* story does not
apply to this greenfield rebuild, so the real data path is simpler:

- **True fresh install = no settings row at all.** `getSettings()` returns
  `UserSettings.initial` (`capy_wake_repository.dart:167`) and `watchSettings()`
  maps a null row to `UserSettings.initial` (`:174`), whose
  `hasCompletedOnboarding` is the **model default `false`**
  (`user_settings.dart:92`). So a fresh install yields `false` **directly**, and
  `needsOnboarding(false, false) == true`. The `mappers.dart:257` `?? true`
  branch is never reached — there is no row to map.
- The `?? true` only fires for a **row that exists but whose JSON lacks the
  key**. `toJson` always writes the key (`mappers.dart:199`), so this app never
  writes such a row, and at `schemaVersion = 1` with no users **no legacy-shaped
  row can exist.** The `?? true` is dead-but-defensive, not a live path. (This
  itself contradicts the ported dartdoc's emphasis — recorded as a finding.)

The **`hasExistingAlarms` signal is the real guard**, and it carries a safety
property (ported dartdoc): the redirect can only fire with **zero alarms**, so
it can never strand a ringing alarm — a ring requires an alarm to exist.

**The live hazard is not a legacy row but the cold-start race (H3).** On a cold
launch the settings stream has not emitted; a redirect reading
`AsyncValue.loading` as a fresh install would bounce **every returning user**
into onboarding for the first frame. The redirect therefore treats
`AsyncValue`: `loading` → no redirect, `data` + fresh → redirect, `error` → no
redirect (fail safe to the app). This is the Phase 03 `initializeDateFormatting`
/ Phase 05 `initializeTimeZones` class of bug — correct in a unit test, wrong
against live provider state — and gets its own test.

## Scope — exactly what ships

### New: `/onboarding` route + gate

- `lib/features/onboarding/onboarding_screen.dart` — a single cozy welcome:
  `SceneHeader` with **`SceneCrop.home`** (present; the splash board's exact
  sunrise-bedroom scene is not in the package — **Tier B substitution logged by
  name in `asset_gaps.md`**, no new art), real `Text` wordmark + one-line body,
  one primary CTA "Set your first alarm" → `/alarms/new`, and a "Skip for now"
  secondary (`onboardingSkip`) that completes onboarding and lands on Home.
  **No permission request on this screen** — the ask stays at first enable.
  Confirmed (H4): `AlarmDraft.create` defaults `enabled: true`
  (`alarm_draft.dart:101`), so Save from `/alarms/new` produces a first-enable
  transition and the **existing** `AlarmPermissionPrompt` fires from the Add/Edit
  Save path (`alarm_edit_screen.dart:322`) — onboarding reaches it naturally.
- Gate wiring in `lib/app/` — a `go_router` `redirect` (not a replaced shell)
  that sends a genuine first run to `/onboarding` and is a no-op otherwise. It
  reads `needsOnboarding` from settings + alarm count. The redirect must **not**
  fire once onboarding is complete, must **not** fire while an alarm rings
  (it can't — zero alarms is required), and must leave every deep link intact
  for a returning user.
- `/onboarding` lives **outside the `StatefulShellRoute`**, on the root
  navigator (architecture plan: "`/onboarding` outside the shell"), so it has
  no tab bar and `RingingHost` still sits above it.

### New: the completion write

- `settings_controller.dart` gains `completeOnboarding()` →
  `_update((s) => s.copyWith(hasCompletedOnboarding: true))`. One method, one
  field, reusing the existing `_update` path (so it persists through the same
  repository).

### Reused, not rebuilt

- `AlarmPermissionPrompt` / `AlarmPermissionGate` / `permissionStateProvider` —
  untouched. The first-alarm CTA routes into the Add/Edit screen whose Save +
  enable already triggers the prompt.

### New ARB keys (expected) — narrowed in pre-review (M1)

The welcome reuses ported keys where they fit: `appName`,
`onboardingWelcomeTitle`, `onboardingWelcomeBody`, and **`onboardingSkip`
(present)** for the secondary. The primary CTA could reuse
`todayCreateAlarmAction` ("Set an alarm", present) but onboarding's first-alarm
CTA reads better as its own line. I register **+1 to +2 ARB keys** — a
`onboardingFirstAlarmCta`, and possibly one body/subtitle line if the ported
welcome body does not fit a first-run greeting — and will restate on
measurement (Phase 04 planned 0, measured +4; the discipline runs both ways).

## Out of scope (named, not deferred)

- **Puzzle-picker and strictness steps** — Phase 10 / existing Settings. Not
  built. The 9 ported strings stay unused, named above.
- **The sleep-boundary / `package:health` restoration.** `package:health` and
  `live_sleep_gateway.dart` did **not** land in Phase 07 or 08, and **do not
  land here either** — stated explicitly, as the task requires.
  `test/core/sleep/sleep_boundary_test.dart` stays at `at most one` importer
  with the negative invariant for `NSHealthShareUsageDescription` /
  `READ_SLEEP`. Onboarding has no health touchpoint; pulling health in would be
  a second unrelated surface in one phase. Stats' "sleep not available yet"
  notice and the unused `sleepHistoryEmpty` string remain as Phase 08 left them.
- **`CapyNavBar` height, `MeadowFooter` 2× grass (G19), `SceneHeader` flat top
  (G18), Alarms' 3 / Add/Edit's 8 Tier A failures.** Owed by nobody; not this
  phase's screens. Not touched.
- **A new onboarding art asset.** Raster-only, no generated art (`CLAUDE.md`).

## Dependencies

No new package. `go_router` (present), Riverpod (present),
`OnboardingStatus` + `hasCompletedOnboarding` (ported). If the welcome needs a
scene the package lacks, log a Tier B substitution — do not add a dependency.

## Tests (mirrored under `test/`)

1. **Gate redirect** — `needsOnboarding` true (fresh, no alarms) → redirect to
   `/onboarding`; false in each other case (flag true; alarms exist; both) → no
   redirect. Drives the real `go_router` `redirect`, not just the predicate.
2. **The cold-start loading race (H3)** — the redirect run against a *pending*
   settings `AsyncValue` must **not** redirect (a returning user is never
   bounced on the first frame); run against the resolved fresh value, it
   redirects; against `error`, it does not. This is the phase's main
   correctness surface, replacing the fictional grandfathered-row test (H1).
3. **`completeOnboarding()`** — flips the flag, persists via repository, the
   gate stops firing afterward. **Mutation check:** disable the write, confirm a
   *specific* test fails (not an aggregate) — Phase 06/08's guard-on-trust rule.
4. **Welcome screen widget** — wordmark + body + CTA render; CTA routes to
   `/alarms/new`; Skip routes to Home and completes onboarding. **Permission
   spy (H2):** a counting `FakePermissionService` asserts **zero**
   `requestNotification`/`requestExactAlarm`/`read` calls across the welcome's
   lifecycle incl. the CTA tap before navigation. Mutation: a stray
   `requestNotification()` in `initState` must fail this specific test.
5. **Safety** — the redirect cannot fire while an alarm exists (never strands a
   ring); `RingingHost` still wraps `/onboarding`.
6. **No overpromise** — copy test over the welcome strings: no "never
   oversleep", no reliability claim beyond the OS clock (`CLAUDE.md` safety).
7. **RTL** — welcome lays out with `EdgeInsetsDirectional`/`start`/`end`; an
   `ar` render has no hardcoded `left`/`right`.
8. **Ported puzzle/strictness strings stay unused (M5)** — the welcome does
   **not** render the puzzle/strictness onboarding strings (Phase 10's), mirror-
   ing Phase 08's `sleepHistoryEmpty` guard. One test, not nine.
9. **Existing suite unaffected (M3)** — the global redirect is null-safe on
   `loading`, so every existing router-based screen test (which never emits a
   fresh-install settings state) stays green by construction; the full suite is
   re-run to confirm.

## Expected counts — registered now, restated on measurement

- **Tests: +18 to +28.** A gate + one write + one static welcome screen is
  thinner than Phase 07's four stateful surfaces and closer to Phase 08's +41.
  The coverage figure is the better check; I register the range and will
  reconcile.
- **ARB keys: +1 to +2** (M1: `onboardingFirstAlarmCta` + maybe one body line;
  `onboardingSkip` already ported), restated on measurement.
- **Coverage:** `lib` holds ≥ 97.8% (a small, fully-tested feature); `lib/core`
  **unchanged** (no core change — the predicate is already covered);
  `lib/data` **unchanged** (no mapper change). A *fall* in `lib` would be a
  finding, since every new line is a tested widget/gate.
- **Comment budget:** every new file meets 2 lines / 300 chars outright.
  **Zero baseline additions** — it stands at 113.
- **`grep -rn "Phase [0-9]" lib/` stays 0.** Doc comments name the layer.

## Acceptance criteria

- A fresh install opens on `/onboarding`; completing or skipping it lands on
  Home and never shows it again.
- An existing install (any alarm, or completed flag) **never** sees onboarding.
- The first-alarm CTA reaches `/alarms/new`; enabling that alarm triggers the
  **existing** permission prompt — verified on the simulator, taps landing.
- No permission is requested on app start or on the welcome screen.
- Full validation block green including `flutter analyze` zero infos and the
  comment budget.
- The plan's "no onboarding mockup → no Tier A claim" is honored: **no
  onboarding capture is compared against a mockup.** If a screen is added to
  `integration_test/capture_test.dart` at all, it is for a token/overflow
  record in `docs/visual/onboarding/`, explicitly **not** a Tier A comparison.

## Risks

- **Redirect loops / strands.** A gate that mis-reads the two signals could
  loop a user into onboarding or (worse) skip it. Mitigated by tests 1–3 and
  the empirical `?? true` check in the pre-review.
- **The `watch` race.** The provider graph may yield a default before settings
  load, flashing the wrong branch. Mitigated by test 2 and a loading-safe
  redirect (treat "not yet loaded" as "do not redirect" so a returning user is
  never bounced).
- **Scope creep into Phase 10.** The ported puzzle/strictness steps tempt a
  bigger flow. Held to welcome + CTA; named out of scope.
- **Over-claiming fidelity.** The real risk the task flags. Mitigated by the
  reference section above: no Tier A claim, no onboarding mockup comparison.

## Rollback

All additions are new files plus one controller method and one router
redirect. Reverting the redirect wiring restores the pre-phase behavior (Home
on launch) without touching any shipped screen.

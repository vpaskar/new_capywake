# Current phase

**Phase 09 — Onboarding: done, 2026-11-17. `Current phase: 10`.**

**1,513 tests**, analyze clean including infos, lib 97.84% / `lib/core`
99.61% / `lib/data` 88.95% / **`lib/features/onboarding` 100.00%**, **438 ARB
keys × 10 locales** (+1).

## What this phase actually found

### 1. The phase name promised a permission flow that was already built

"Onboarding — just-in-time permissions" — but Phase 07 already ships the
just-in-time permission request: `AlarmPermissionGate`, `AlarmPermissionPrompt`,
`permissionStateProvider`, the prompt firing at first alarm enable (confirmed on
device this phase, Save → the prompt). The legacy onboarding (`../capywake`,
read-only) asks for **no** permission — it is a three-step preferences flow
(welcome → puzzle → strictness) writing `hasCompletedOnboarding`.

What was actually missing: **`OnboardingStatus.needsOnboarding` was ported and
tested but wired to nothing, and `hasCompletedOnboarding` had no writer in
`lib/`.** A fresh install opened on an empty Home with no greeting. This phase
added the `/onboarding` route (outside the shell), a push-only redirect, the
welcome, and `completeOnboarding()`. Reporting "already done" was the output,
not a reason to pad.

### 2. A screen every test passed was broken on device (SR1 H1)

The CTA "Set your first alarm" bounced to **Home** on the iPhone 18 Pro while
the identical flow passed in the suite. The redirect had a *pull* branch
(`atOnboarding && !needed → Home`); `completeOnboarding()` fired the
`refreshListenable` mid-tap, re-ran the redirect while still on `/onboarding`,
and the pull-to-Home beat the CTA's `go(/alarms/new)`. **The fake async clock in
widget tests ordered `go` and the refresh the other way, so the buggy redirect
passed everything.** Fixed to push-only; pinned by a new test that **fails
against the buggy version** (verified). Phase 05's rule (the test was wrong
about the code) and Phase 06's (a guard whose test can't fail is on trust),
together. The device check is not optional.

### 3. There is no onboarding mockup

The five primary screens contain none. The `screens/alternative/onboarding_*`
files are **two** distinct boards re-handed under five names, at **887×1774 /
852×1846 device-bezel geometry, drawing the rejected 4-tab/Games nav** —
superseded by the primary mockups. **Tier A binds nothing.** Held to tokens, the
44 pt tap floor, RTL, large-text reflow, no-overpromise. Evidence:
`docs/visual/_evidence/onboarding_boards.md`. **Not added to the capture set** —
`compare.dart` would `exit(2)` on a screen with no block table.

### 4. SR2 — an error-state crash on the redirect hot path

The folded provider called `alarms.requireValue` after only an `isLoading`
check; an **errored** alarms stream would throw, on a provider read on every
navigation. Now yields a value only when both streams have data — loading and
error both resolve to "do not redirect".

### 5. Ported dartdoc describes a path that cannot occur here

`OnboardingStatus`'s ported dartdoc explains a grandfathering path for
"installed before onboarding existed". In this no-users rebuild at
`schemaVersion = 1` the `?? true` mapper branch is **unreachable** (`toJson`
always writes the key). Code correct; prose is the legacy's world. Recorded, not
rewritten (Phase 02 judged `lib/core/` prose justified). The real fresh-install
path: no row → `UserSettings.initial` → flag `false` → onboarding.

### 6. The `grep "Phase [0-9]" lib/ = 0` baseline is Dart-scoped

Run bare it returns **2** — an ARB description (`app_en.arb:17`, "the Phase 00
launch surface …") and its generated mirror, pre-existing accurate history. The
rule is about doc comments; `--include="*.dart"` excl. generated is **0**, and
Phase 09 added none.

## Predictions — all held

Tests **+20** against +18–28 ✅. ARB **+1** against +1–2 ✅. lib **97.84%**
against ≥97.8 ✅. core/data unchanged ✅. onboarding **100%**. Comment baseline
**+0** (113) ✅.

## Next session — Phase 10, Puzzle chooser and the ten existing puzzle types

**Still owed:** the sleep-boundary restoration — `package:health` and
`live_sleep_gateway.dart` did **not** land in 07, 08 or 09, each said so.
`sleep_boundary_test.dart` stays at `at most one`. **Owed by nobody:** the
nav-bar/meadow fact, `MeadowFooter` 2× grass (G19), `SceneHeader` flat top
(G18), Alarms' 3 / Add/Edit's 8 Tier A failures. The 9 ported puzzle/strictness
onboarding strings are **unused on purpose** (Phase 10's domain) — a widget test
asserts the welcome does not render them.

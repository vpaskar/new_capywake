# Phase 09 — post-review

Onboarding: a first-run welcome, a redirect gate, and the one write that closes
the loop. The permission ask was **reused** from Phase 07, not rebuilt.

## What shipped

- `lib/features/onboarding/onboarding_screen.dart` — a cozy welcome: wordmark
  over `SceneCrop.home`, "A calmer way to get up", the puzzle-explainer body, a
  primary "Set your first alarm" CTA → `/alarms/new`, and a "Skip setup"
  secondary. Asks for no permission.
- `lib/features/onboarding/onboarding_providers.dart` — `needsOnboardingProvider`
  folding settings + alarm count into `AsyncValue<bool>`, a value only when both
  streams have data.
- `lib/app/router.dart` — `/onboarding` outside the shell on the root navigator,
  a `routerProvider`, and a push-only redirect with a `refreshListenable`.
- `settings_controller.dart` — `completeOnboarding()`, the sole writer of
  `hasCompletedOnboarding`.
- One ARB key, `onboardingFirstAlarmCta`, in all 10 locales.

## Acceptance — met

- Fresh install opens on onboarding; completing or skipping lands on Home and
  never shows it again. ✓ (tests + device)
- An existing install (any alarm, or completed flag) never sees onboarding. ✓
- First-alarm CTA → `/alarms/new`; Save of that alarm → the **existing**
  permission prompt. ✓ **verified on device**, including the honest degrade copy.
- No permission on app start or on the welcome. ✓ (mutation-verified spy)
- Full validation green incl. `flutter analyze` zero infos and the comment
  budget. ✓
- No onboarding mockup → no Tier A claim, not added to the capture set. ✓

## There is no onboarding mockup — stated plainly

`reference/01_REFERENCES/screens/primary/` has five screens, none onboarding.
The `screens/alternative/onboarding_*` files are two distinct exploratory boards
(re-handed-off under five names) at **887×1774 / 852×1846 device-bezel geometry,
drawing the rejected 4-tab/Games nav** — superseded by the primary mockups.
**Tier A binds nothing.** Evidence: `docs/visual/_evidence/onboarding_boards.md`.
Held instead to tokens, the 44 pt tap floor, RTL, large-text reflow and the
no-overpromise rule.

## The central finding — a screen every test passed was broken on device

Self-review #1 H1. The CTA bounced to **Home** on the iPhone 18 Pro while the
identical flow passed in the suite. Root cause: the redirect had a *pull*
branch (`atOnboarding && !needed → Home`); `completeOnboarding()` fired the
`refreshListenable` mid-tap, re-ran the redirect while still on `/onboarding`,
and the pull-to-Home beat the CTA's own `go(/alarms/new)`. The widget test
could not reproduce it — the fake async clock ordered `go` and the refresh the
other way.

**Fix:** the redirect is push-only; leaving onboarding is the user's explicit
navigation. **Pinned by a new test** (`completing the flag while on onboarding
does not yank to Home`) that fails against the old pull-branch redirect and
passes against the fix — verified by reinstating the buggy version. Re-confirmed
on device: CTA now reaches Add Alarm, Save fires the prompt.

This is Phase 05's rule (the tool/test was wrong about the code) and Phase 06's
(a guard whose test cannot fail is a guard on trust), together, and it is why
the device check is not optional.

## What this phase owed, and what it did with each

- **The sleep-boundary / `package:health` restoration — did NOT land, stated
  explicitly** (as owed). Onboarding has no health touchpoint; pulling health
  in would be a second unrelated surface in one phase.
  `test/core/sleep/sleep_boundary_test.dart` stays at `at most one` importer
  with the negative `NSHealthShareUsageDescription` / `READ_SLEEP` invariant.
  Stats' "sleep not available yet" notice and the unused `sleepHistoryEmpty`
  string remain as Phase 08 left them. **Owed by nobody still: it has now passed
  through Phase 07, 08 and 09 unbuilt.**

## Findings about earlier phases (full-project review)

- **M1 — the phase name over-promised.** "Just-in-time permissions" was already
  built in Phase 07. Onboarding adds the first-run entry and the write, reuses
  the prompt. Reporting "already done" was the honest output.
- **L1 — ported `OnboardingStatus` dartdoc describes a grandfathering path that
  cannot occur** in a greenfield rebuild at `schemaVersion = 1` with no users
  (the `?? true` mapper branch is unreachable). Code correct; prose is the
  legacy's world. Recorded, not rewritten (Phase 02 judged `lib/core/` prose).
- **L2 — the baseline's `grep "Phase [0-9]" lib/` = 0 is scoped to Dart.** Run
  bare it is 2 (an ARB description + its generated mirror, pre-existing accurate
  history). The rule is about doc comments; `--include="*.dart"` excl. generated
  is 0, and Phase 09 added none.

## Predictions — registered, then measured

| Metric | Registered | Measured | Verdict |
|---|---|---|---|
| Tests | +18 to +28 | **+20** (1,493 → 1,513) | ✓ |
| ARB keys | +1 to +2 | **+1** (437 → 438) | ✓ |
| `lib` coverage | ≥ 97.8% | **97.84%** | ✓ |
| `lib/core` | unchanged | **99.61%** | ✓ |
| `lib/data` | unchanged | **88.95%** | ✓ |
| `lib/features/onboarding` | — | **100.00%** | ✓ |
| Comment baseline | +0 | **+0** (113) | ✓ |

Every prediction held. The +20 tests include the three mutation-proven guards
(completeOnboarding, the permission spy, the loading invariant) and the
device-found race test.

## Tally

Pre-review 12 (4H/5M/3L) + SR1 4 (1H/2M/1L) + SR2 2 (1M/1L) + full-project 3
(1M/2L) = **21 findings, all applied or recorded with a reason, none deferred.**

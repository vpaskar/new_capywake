# Phase 09 — self-review #1

Adversarial pass over this phase's own code, after it validated green.

**4 findings: 1 High, 2 Medium, 1 Low. All applied.**

---

## High

### H1 — The CTA bounced to Home on device, and every test passed through it

Found by running the app on the iPhone 18 Pro (iOS 27.0), not by a test.

**On device:** fresh install → onboarding shows → tap "Set your first alarm" →
landed on **Home**, not Add/Edit. **In the test suite:** the identical flow
(`onboarding_redirect_test.dart`, real `CapyWakeApp`, real router) asserted
`AlarmEditScreen findsOneWidget` and **passed**.

**Root cause.** `completeOnboarding()` writes the flag; the settings stream
emits; `_OnboardingRefresh.notifyListeners()` re-runs the redirect **while
still at `/onboarding`**. The first redirect had a *pull* branch:
`return atOnboarding ? Routes.home : null` for a not-needed user. So the
refresh fired mid-tap, saw `needsOnboarding == false` and location
`/onboarding`, and returned `Routes.home` — beating the CTA's own
`context.go(Routes.alarmNew)`. The user landed on Home.

The widget test could not reproduce it: under the fake async clock,
`go(/alarms/new)` and the refresh resolve in an order that happens to end on
Add/Edit. The real event loop ordered them the other way. **This is Phase 05's
rule exactly — the tool (test) was wrong about the code — and Phase 06's — a
guard whose test cannot fail is a guard on trust.**

**Applied.** The redirect is now **only a push**: it sends a genuine first run
*into* onboarding and never pulls anyone *out*. Leaving is the user's explicit
`go`, which the redirect must not override. The dropped safety (a completed
user deep-linking to `/onboarding`) is harmless — both of that screen's actions
leave it.

**The fix is not on trust.** A new test —
`completing the flag while on onboarding does not yank to Home` — completes the
flag while sitting on `/onboarding`, pumps to fire the refresh, and asserts the
user stays. Against the **old pull-branch redirect it fails** (verified by
reinstating the buggy version: the test goes red); against the fix it passes.
Re-verified on device: the CTA now lands on Add Alarm, and Save there fires the
**existing** permission prompt — the hand-off works end to end.

---

## Medium

### M1 — The permission-spy test tapped the whole screen, not the CTA

`onboarding_screen_test.dart`'s H2 spy originally did
`tester.tap(find.byType(OnboardingScreen).first)` — a tap on the Scaffold, not
the button, which exercises nothing. A spy that taps the wrong target proves
nothing about the CTA.

**Applied.** It now taps `find.text(onboardingFirstAlarmCta)`, asserts the stub
Add-alarm route is reached, and re-checks all three request counts are still 0.
Verified by mutation: a stray `requestNotification()` in the CTA makes this
specific test fail and nothing else.

### M2 — `_resolve` returned the first `hasValue`, which is stale after a write

The provider-test helper returned on the first resolved value. After
`completeOnboarding()`, the stream re-emits asynchronously, so the first
resolved read was the **pre-write** value and
`completing onboarding stops the need` failed with `true`.

**Applied.** `_resolve` now waits for the value to **stop changing** (three
stable reads) before returning, so a post-write re-emission is not missed. The
test passes, and the completeOnboarding mutation (no-op write) still fails it —
the guard holds.

---

## Low

### L1 — The redirect's doc comment grew past the comment budget three times

Each sharpening of the redirect's reasoning pushed its doc comment to 5 lines
(331 excess chars against the 2-line / 300-char budget). The budget exists
precisely to stop rationale creeping into code comments; the full reasoning
belongs in this doc and the plan.

**Applied.** The redirect comment is two lines naming the hazard
("only a push … pulling back to Home here would race and beat"); the why is
here. `grep -rn "Phase [0-9]" lib/` stays 0 in hand-written Dart (the two ARB
hits are a pre-existing Phase-00 description, not a code comment — see the
full-project review).

---

## Outcome

4 findings, all applied, none invalid.

The one that matters is **H1**: a screen that every automated check passed was
broken on the actual device, and only running it found the bounce. The fix is
now pinned by a test that fails without it. This is the phase's central finding
and the reason the device check is not optional.

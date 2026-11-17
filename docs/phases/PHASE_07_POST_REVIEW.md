# Phase 07 — post-review

Settings, the reliability checklist, the setup walkthrough, and the
`AlarmPermissionGate` wiring two phases had passed along.

## Predictions, measured

Registered in `PHASE_07_PLAN.md` §10 **before** implementation.

| | Registered | Measured | |
|---|---|---|---|
| New tests | 70 – 100 | **80** | ✅ |
| Total | 1,442 – 1,472 | **1,452** | ✅ |
| New ARB keys | 12 – 22 | **22** (405 → 427) | ✅ |
| `lib` coverage | 97.0 – 97.8 % | **97.80 %** | ✅ |
| `lib/core` | 99.49 %, **unchanged** | **99.61 %** | ❌ restated |
| `lib/data` | 88.5 – 89.5 % | **88.95 %** | ✅ |
| `lib/features/settings` | ≥ 90 % | **98.49 %** | ✅ |
| Files baselined for comments | **0** | **0** | ✅ |

**`lib/core` rose, and the prediction said it could not.** The reasoning was
that this phase adds no `lib/core` code, which was true — it adds no lines
there at all. What it adds is the **first caller** of
`ReliabilityChecklistService` and `ReliabilityCopyService`, ported in Phase 02
and exercised until now only by their own unit tests.
`lib/core/reliability/` is now **100.00 %** (174/174), which lifted the tree.

The honest generalisation: *a prediction about a tree's coverage has to
account for code elsewhere that starts calling it*, not only for code added
to it. Phase 05 and Phase 06 both restated a coverage prediction for the
adjacent reason — reviews adding tests the forecast could not foresee.

## Tier A

`04_SETTINGS.png`, captured on the iPhone 14 Pro at 393×852 pt, verified by
`tool/capture.sh`.

| Block | Ref | Actual | Delta | |
|---|---|---|---|---|
| header band lower edge | 59.9 | 60.0 | **+0.1** | ✅ |
| hero scene lower edge | 168.9 | 169.0 | **+0.1** | ✅ |
| group 1 card top | 187.4 | 184.7 | **−2.7** | ✅ (measured by hand; the tool reports `absent`) |
| group 1 card bottom | 297.8 | 302.3 | **+4.5** | ❌ |
| group 2 card top | 311.6 | 311.0 | **−0.6** | ✅ |

**The one failure is a rule conflict, not a layout error, and the arithmetic
is in `docs/visual/settings/README.md`:** the mockup's settings row is
**41.1 pt**, the tap-target floor is **44 pt**, and `CLAUDE.md` makes
reachability binding. Group 1 cannot be smaller than 28.2 + 44 × 2 = **116.2**
against the mockup's **110.4**. Shipped at 117.2, which is 1 pt of slack over
the floor, after cutting row padding to `CapySpacing.xs` and holding titles
and values to one line at the default scale.

**Blocks below Appearance are not claimed**, declared before the capture. The
shipped row set differs from the mockup by decision (below), so their
positions differ by consequence.

## What the mockup draws and the app does not

`CLAUDE.md`: *"Settings: show only implemented rows. Backup & Sync and Restore
Purchases are dropped — there is no backend and nothing to restore."*

| Mockup row | Shipped | Why |
|---|---|---|
| Backup & Sync "On (iCloud)" | ❌ | `CLAUDE.md`, by name. No backend |
| Restore Purchases | ❌ | `CLAUDE.md`, by name. No IAP |
| App Icon › | ❌ | No alternate-icon assets or plist entries. A chevron onto nothing |
| Daily Reminder ◉ | ❌ | No evening-reminder scheduler exists |
| Alarm Notifications ◉ | **replaced** | See below — pre-review **H2** |
| Sound, Snooze, Theme, About | ✅ | Real, and they persist |

Added, because `CLAUDE.md` puts them here: **Alarm reliability** and **Setup
walkthrough**, plus the motion-check kill switch.

### The toggle that would have silenced every alarm

The mockup's **Alarm Notifications** switch has only two possible meanings and
both are defects. If it maps to the OS permission, a switch cannot revoke one,
so "off" must be a local flag suppressing scheduling — a control inside
Settings that **stops every alarm from ringing**, with nothing on screen
saying so. If it maps to nothing, it is a dead control, which is worse than a
dead row because it moves.

Shipped as a **status row**: it reads the live `PermissionState`, says plainly
whether notifications are allowed, and its action **grants and never
revokes**. Turning alarms off stays in the OS, where the OS states the
consequence. `CLAUDE.md` classes locking a user out of silencing their alarm
as a High finding; this is the same rule one step earlier.

## What this phase found

### 1. The permanently-denied user got nothing at all

`AlarmPermissionGate.shouldRequestNotification` returns **false** for
`permanentlyDenied` — correctly, there is no prompt left to show. The wiring
then asked `shouldOpenSettings` **inside** that branch, so the route to the OS
was unreachable, and the one user who cannot be helped by a prompt received no
dialog, no route and no explanation after enabling their first alarm.

Found by a test asserting `openAppSettingsCount == 1` that measured zero.

### 2. Nine of ten gate tests passed with the gate deleted

Phase 06's rule, applied: remove the guard and see. Deleting
`isFirstEnableTransition` from `maybeRequest` failed **one** test.

"Disabling the only alarm does not ask" seeded a single alarm and turned it
off — so with the gate gone, *a different rule* ("no alarm is enabled")
suppressed the prompt, and the test passed without noticing. It now seeds two
alarms, leaving one enabled, so the transition check is the only thing between
the tap and a prompt. Re-mutated: **two** fail.

**Phase 06 found this shape with in-memory fakes hiding an async window. Here
it was one rule quietly covering for another.** Mutation was the only way
either was visible.

### 3. `compare.dart` invented a delta for a block it had not measured

It reported **"group 1 card top −18.7 TIER A FAIL"** for a card sitting
**−2.7** from its mark, on a screen whose hero matched to 0.1 pt.

`_hairlines` read **one column at x=360 pt** — text-free on Alarms, where
Phase 04 chose it, and **under the hero art** on Settings, where it returned
art minima and never saw the card. `_nearest` then searched **±40 pt** for
anything to match and claimed the hero's edge.

Now: three columns merged, paint rejected below L=150, search ±12 pt, and
`absent` past it — which still counts as a failure, because an unmeasured
block is not a passing block. Verified against all three prior captures before
keeping; no new failures, and false deltas collapsed.

**Phase 05's rule for the third consecutive phase, in the same tool Phase 04
fixed for the same reason.**

### 4. Three screens fail their own Tier A tables, and two phases reported only their passing blocks

The full-project review's H1, in full in
`PHASE_07_FULL_PROJECT_REVIEW.md`. In brief: running `compare.dart` across
every captured screen gives Home 6 failures, Alarms 5, Add/Edit 8, Settings 2.

**Home's are all `absent` and its worst measured delta is 1.4 pt** — the
layout is fine; the write-up was not. Phase 03's tracker row lists four
deltas, all of them from passing rows, out of fourteen blocks; its own tool
against its own committed capture reports eight failures at 36.2 pt worst.
Phase 04's row lists six passing numbers out of eleven.

Both tracker rows are corrected in place. **Alarms' and Add/Edit's real
failures are not fixed here** — another phase's screen is not this phase's to
change blind — but they are now written down with their numbers.

### 5. Nineteen more stale ported dartdocs, after Phase 06 fixed twelve

Counted rather than estimated: `grep -rn "Phase [0-9]" lib/` returned **20**
before this phase and **1** after, and the survivor is correct. Several named
phases that do not exist here at all — 29, 31, 32, 34, 37 — and two named
**Phase 09** for the reliability checklist, which is *this* phase.

`reliability_copy_service.dart` claimed its ARB keys were "added in Phase 06",
and Phase 06's own tracker row records **zero** new ARB keys.

### 6. `CLAUDE.md` documents a gate that has never existed

`tool/check_no_fake_stats.dart`, claimed at `CLAUDE.md:166` to enforce the
no-fake-numbers rule on Stats — the screen `CLAUDE.md` itself calls most
likely to lie. `tool/` holds eight scripts and none is it.

Phase 02 found exactly this with `tool/audit_art.dart`. The line now states
the rule as prose and names **Phase 08** as owing the gate; writing it here,
a phase early against an unbuilt screen, would be a gate nobody has run.

### 7. Three pushed routes had no `Scaffold`

Every tab screen inherits one from the shell. A route pushed on the root
navigator does not, and `AlarmEditScreen` — the only prior pushed route —
supplies its own. All three new screens therefore threw *No Material widget
found* on build: Settings could not open at all.

### 8. Four screens, four toggle sizes

`CapyToggle` was Home's 59.6 × 34.6 with no size parameter, used everywhere.
Measured per screen by per-row green anchor:

| | Track |
|---|---|
| Home | 59.6 × 34.6 |
| Alarms | **54.0 × 32.0** |
| Add/Edit | **48.0 × 28.2** |
| Settings | **44.3 × 25.0** |

`trackSize` is now **required**, so every call site states its own — the move
that made `bandHeight` required in Phase 04 and immediately exposed Stats
carrying Home's number. No site needed an unmeasured inheritance: the
Add/Edit toggle existed in its mockup and had simply never been measured.

**`tier_a_blocks.md`'s recorded Alarms toggle was wrong**: "302.0 → 339.9 at
30.5 pt tall", read from a row profile at **y=345 pt** — but the toggle starts
at **356.5**, so that profile crossed the pill's rounded cap, not its body.
Corrected in place to 54.0 × 32.0, with the rule: *a row profile at a single y
is a slice, not a bounding box, and on a rounded shape the slice is smaller.*

## Obligations

- **The sleep-boundary restoration is NOT discharged.** `package:health` and
  `live_sleep_gateway.dart` did not land — Settings has no sleep row and Stats
  is Phase 08. `test/core/sleep/sleep_boundary_test.dart` stays at `at most
  one` importer with the negative invariant. **Moved to Phase 08's row**,
  stated rather than dropped.
- **`AlarmEngine.ringNow` is still called by nothing in `lib/`.** Now
  user-visible for the first time: the motion-check kill switch is settable
  here and the motion layer that reads it does not exist.
- **Alarms and Add/Edit owe Tier A work** (finding 4), with numbers.
- **Phase 08 owes `tool/check_no_fake_stats.dart`** (finding 6).

## Not done, and not claimed

- **No control was exercised by hand on a device.** The evidence is 80 tests
  against the real provider graph plus a verified capture. The simulator was
  driven only by `tool/capture.sh`.
- **Android is untested. There is no emulator.**
- The ten-locale rendering is asserted for overflow in `ar` and `de` only;
  the other seven are gated for ARB completeness, not for layout.

## Findings

| Pass | Findings | H / M / L |
|---|---|---|
| Pre-review | 19 | 3 / 8 / 8 |
| Self-review #1 | 8 | 2 / 3 / 3 |
| Self-review #2 | 6 | 1 / 3 / 2 |
| Full-project | 5 | 2 / 2 / 1 |
| **Total** | **38** | **8 / 16 / 14** |

All applied. None invalid, none deferred.

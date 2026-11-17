# CapyWake (rebuild) — Phase Tracker

Single source of truth for phase sequencing. The `Current phase:` line below is
the pointer. The token is a zero-padded two-digit phase id matching a row in the
table, or the literal word `none`.

Convention inherited from `../capywake/ai-orchestration/PHASE_TRACKER.md`
(read-only reference). Advancing the pointer is part of each phase's completion.

Current phase: `13`

## Protocol per phase

Combines the handoff's **pre**-review with the legacy's **post**-reviews.
Both, not either.

1. Read `04_WORKSPACE_STATE/PROJECT_STATE.md` (handoff) and `memory/current-phase.md`.
2. Consult `../capywake` for relevant prior decisions. **Never modify it.**
3. Write `docs/phases/PHASE_XX_PLAN.md`: objective, reference screenshots,
   exact assets, asset-to-mockup mapping, dependencies, scope, exclusions,
   tests, acceptance criteria, risks, rollback.
4. Write `docs/phases/PHASE_XX_PRE_REVIEW.md` — adversarial, **before any
   code**. Classify High/Medium/Low. Apply all, or mark invalid with a reason.
5. Revise the plan.
6. Implement only that phase.
7. Run validation (below).
8. Phase self-review #1 → classify → apply all → re-validate.
9. Phase self-review #2 → classify → apply all → re-validate.
10. One full-project self-review → classify → apply all → re-validate.
11. Capture screenshots for any UI work; write `docs/visual/<screen>/`.
12. Write `docs/phases/PHASE_XX_POST_REVIEW.md`: discrepancies, Tier A deltas,
    Tier B substitutions, acceptance failures, resolutions.
13. Update tracker, `memory/current-phase.md`, `memory/progress.md`,
    `docs/sessions/next.md`.
14. Commit to `main`.

**A finding is applied or invalid. "Deferred", "out of scope" and "minor —
skipped" are not outcomes.** Low findings are fixed in the phase that raised
them.

**Steps 8–10 apply to documentation phases too.** Phase 00 skipped them on the
reasoning that a planning phase produces no code to review; the self-review it
should have had then found a High defect (it had banned reuse of 9,825 lines of
verified pure-Dart domain code and its 932 passing tests). Documents are the
deliverable of a planning phase, so reviewing them is reviewing the work.

## What is ported from `../capywake`

**If a file imports Flutter, it is not ported.** The sole exception is
`lib/core/theme.dart`, which imports Flutter *and* is not ported.

Ported: `lib/core/` minus `theme.dart` (62 files, 9,825 lines), `test/core/`
(48 files, 932 passing tests), `lib/l10n/` (383 keys × 10 locales),
`lib/data/` tables and mappers (at `schemaVersion = 1`, not the legacy's 6),
`tool/check_arb.dart`, `tool/check_coverage.dart`, `tool/generate_tones.dart`,
`assets/sounds/`.

Not ported: everything under `lib/features/`, `test/features/`, `lib/app/`,
and `lib/core/theme.dart`. File-level verdicts in `CAPYWAKE_REUSE_AUDIT.md`.

## Validation

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build --delete-conflicting-outputs    # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales complete
dart run tool/check_bundle_size.dart              # every bundled asset tree
dart run tool/check_no_fake_stats.dart                      # lib/features/
flutter test --coverage       # incl. the art audit, manifest + comment budget
dart run tool/check_coverage.dart --path lib                # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
dart run tool/check_coverage.dart --min 85 --path lib/data  # data  >= 85%
```

The `lib/data` gate was added in Phase 02 (self-review #2, G1): `lib/data` was
the repository's weakest tree at 85.08% and cleared the project gate only
because `lib/core`'s 2,526 lines at 99.41% dominated the average. Its figure is
depressed by 67 structurally uncoverable lines — Drift `Table` column getters,
which run at build time to generate `app_database.g.dart` and never at runtime
— so the hand-written data code is really **422/429 = 98.4%**. Do not "fix" the
8% on `app_database.dart` with a meaningless test, a `// coverage:ignore`, or a
lowered gate. See `PHASE_02_SELF_REVIEW_2.md` G2.

Generators run **before** the format check. A generator reporting "nothing to
do" is acceptable.

**There is no `tool/audit_art.dart`.** This block listed one until Phase 02's
self-review (F3) found the documented command failing with "Could not find
file". The art audit is `lib/design/art_audit.dart`, applied by
`tool/import_art.dart` and gated by `test/design/art_audit_test.dart` +
`art_manifest_test.dart`, so it runs inside `flutter test`.

**Phase 01 exception, now closed:** the `--path lib/core` coverage line was
skipped in Phase 01 because `lib/core/` was not ported yet and
`check_coverage.dart` does **not** pass trivially on an absent path — it
`exit(2)`s with "No coverage data matched". **Phase 02 turned it back on
(99.41% against the 95% gate) and it stays on.**

## Git

`main` is the only branch. No feature branches, no worktrees, no stashes.
Per-phase commit `feat: complete phase <id> - <name>`, then
`chore: record phase <id> commit hash`.

## Phases

| ID | Name | Status | Phase file | Commit | Completed | Notes |
|----|------|--------|------------|--------|-----------|-------|
| 00 | Discovery, legacy audit, architecture and navigation decision | done | `docs/phases/PHASE_00_PLAN.md` | `f49a882` | 2026-11-16 | Legacy audited read-only: 40/47 phases done, 137 Dart files, 99 test files, full phase ritual found. Root cause of the failed retrofit identified: the "capybara is vector CustomPaint, never a raster cutout" rule made the mockups unreachable. Nav conflict resolved from the primary mockups: **Home/Alarms/Stats tabs, Settings pushed from the gear**. Owner decisions: raster art, all three Stats segments, full rigor incl. 10 locales. Pre-review raised 12 findings (4H/5M/3L), all applied. **Re-opened and self-reviewed 2026-11-16** (see `PHASE_00_SELF_REVIEW.md`): 8 further findings (2H/3M/3L), all applied — the Highs being that Phase 00 had banned reuse of the legacy's 9,825-line pure-Dart domain and 932 passing tests, and had skipped its own post-implementation review. `CAPYWAKE_REUSE_AUDIT.md` added. |
| 01 | Foundation: tokens, type, art pipeline, shell, capture harness | done | `docs/phases/PHASE_01_PLAN.md` | `ebe89e4` | 2026-11-16 | Gate met: `tool/capture.sh` writes 3 verified PNGs at 1179x2556 (393x852pt) and **checks the artifact, not the exit code** — the pre-review proved the planned `flutter test` mechanism passes while writing nothing, the legacy's 40-phase failure but green. 14 pre-review findings (5H/6M/3L) + 8 self-review (7L/1M), all applied. Typeface **Baloo 2**, chosen on measurements; it does **not** cover Cyrillic/Arabic/Japanese (a `getmask` check wrongly said it did — only rendering shows tofu), so `ru`→Nunito, `ar`/`ja`→system. Art patch closed G1/G2/G3/G10; **G11** found (91% of ink at alpha 250–254) and fixed in-pipeline; **G9 withdrawn**. Tier A: header matches to **0.1pt**; 3 blocks still off ~~because the screens have no bodies~~ — **⟲ Phase 03 corrected this: only the nav-bar row had that cause. The two hero rows were a real `SceneHeader` defect** (the cream card drawn inside the art's `Stack`, shortening every hero band by 11.1pt, from reading the mockup's 292.3/303.4 edges as two positions rather than one edge plus a corner radius). 43 tests, lib coverage 97.92%, art 1818KB of 2182KB. |
| 02 | Domain and persistence — **port from `../capywake`** | done | `docs/phases/PHASE_02_PLAN.md` | `4376154` | 2026-11-16 | Ported 62 `lib/core/` files (9,825 lines) + 47 `test/core/` files + 4 `lib/data/` files at `schemaVersion = 1` + 4 `test/data/` files + 12 sound assets. **The `lib/core` ≥95% gate is back on at 99.41%** and the Phase 01 exception is closed. **Test identity closed exactly as pre-registered: 912 + 83 + 43 ported/existing** (the pre-review fixed all three before implementation; its own first draft estimated the data tests at 66 and measurement gave **83**). N came out 13 not 5, restated rather than passed. **1,051 tests**, analyze clean, project 97.14%. **Not 932 ported but 912** — `theme_test.dart` is 20 of the legacy's 932 and tests the unported `theme.dart`; its replacement `tokens_contrast_test.dart` then found **two real AA failures** in Phase 01's palette (accent/success/grass never clear 3:1 on light surfaces; error is 3.93:1 on surfaceAlt) — recorded as checked constraints, owner-reported, Tier A decision deferred to a UI phase. 7 tests failed after the raw copy, none a logic defect, none skipped: `assets/sounds/` was missing from the plan (would have shipped a catalogue of 12 absent files), 3 sleep-boundary tests asserted phase-07/08 infrastructure, and iOS/Android app labels still read "Capywake". 40 findings across 4 review passes, all applied, none invalid. Also fixed: `tool/audit_art.dart` was documented in `CLAUDE.md` **and this tracker** but does not exist; `check_bundle_size.dart` measured art only while the real asset payload had grown to 10.5 MB; `lib/data` had no gate at 85.08% |
| 03 | Home / Today | done | `docs/phases/PHASE_03_PLAN.md` | `b3b0574` | 2026-11-16 | **The first screen with a body, so the first real test of the fidelity contract — and it found a defect latent since Phase 01.** `SceneHeader` drew the cream card *inside* the hero art's `Stack`, reading the mockup's 292.3/303.4 edges as two positions when they are one edge plus a corner radius; every hero band was **11.1 pt short** and the first capture failed **13 of 14 blocks**. Phase 01 recorded those exact deltas and blamed "the screens have no bodies" — wrong in **three documents** (Phase 01 and 02 post-reviews, this tracker), all now corrected in place. After the fix the hero lower edge is **0.0 pt**. A second class of error: three rows of this phase's own block table were **glyph edges, not block boundaries** (a row-mean detector cannot tell text from a layout edge), and the tile size was *inferred* from two of them at 94 pt against a measured **74**. Rule now in `CLAUDE.md`. **`lib/data` 82.76% → 86.40% earned**: five providers were never read by any test and counted as covered by accident, so Phase 02's "85.08% is honest" was itself wrong. Also found: **`initializeDateFormatting` was never called in `lib/`** — 912 ported formatter tests passed while the app would throw on the first screen rendering a time; and `compare.dart` reported **4 of 13** documented blocks, now 14. **1,116 tests**, analyze clean, lib 97.38% / core 99.41% / data 86.40%, 395 ARB keys × 10 locales. Comment budget ported from `../protio` + `../gastrowerk` at the owner's request (2 lines/300 chars, 113 inherited files baselined, **0 Phase 03 files**). 27 findings across four passes, none deferred. Owner decision mid-phase: **do as in the mockups** — no token retuned. Tier A: hero **0.0**, CTA top/bottom **+0.9**, rail tiles **−1.4**, labels **+1.1**. **⟲ Phase 07 correction: those were the blocks that passed, and the row did not say so.** Run against this same capture, Phase 03's own `compare.dart` reported **8 of 14 blocks outside tolerance, worst 36.2 pt**, and `docs/visual/home/README.md` records only Phase 01's pre-fix deltas — the post-fix comparison this row refers to is not in that directory. Under Phase 07's fixed tool the honest figure is **6 blocks, all `absent` (the tool cannot see them), worst measured delta 1.4 pt** — so Home's layout is in good shape and the reporting was not. `compare.dart`'s own comment says a screen may not pick the blocks it already matches; nothing was watching the write-up |
| 04 | Alarms list and Add/Edit | done | `docs/phases/PHASE_04_PLAN.md` | `b03eb49` | 2026-11-16 | **The first screens that write, and the phase that found a design-system default standing in for a per-screen measurement — for the third time.** `SceneHeader.bandHeight` defaulted to **188.4**, which is Home's band; Alarms measures **148.6** and Add/Edit **112.1**, so both screens opened +39.8 pt out and every block below inherited it. Making it **required** surfaced two more callers, including **Stats, silently carrying Home's number**. `MeadowFooter.height` was the same shape (65.2 / 52.2 / 59.1) and its excess is why the fourth alarm card fell off the fold. **`compare.dart` could not see a card border at all**: a 1-px line moves a 393-pt row mean by under one unit, so four correctly-placed cards read `absent`; the first fix still missed the two **disabled** rows, whose 55%-opacity borders land near 236. **`lib/core` could not drive either screen** — `AlarmFormat.time` returns one string and both mockups need the digits and the AM/PM marker styled apart, so `ClockTimeParts`/`timeParts` was added and tested across ten locales; a proposed `periodLeads` field was **dropped on measurement** (no locale leads). `narrowWeekday`'s dartdoc sent the chips to the one-glyph formatter against a mockup that draws "Mon" — corrected in place. **`CapyNavBar` overflowed at 2x text on every screen**, found incidentally. Phase 03's **P4 is decided**: an edge is consumed by the block that claims it, with its limits stated — the table's *completeness* now matters, and two missing card-bottom rows were corrupting the row after them. **1,189 tests**, analyze clean, lib 97.54% / core 99.41% / data 86.40% (held), **399 ARB keys** (4 new; the plan said 0, the pre-review said >=3, measurement said 4). Tier A: Alarms hero **-0.2**, cards 1-3 **-0.0/-1.0/+0.2/+2.1/+3.6**, pitch 102.3 against 102.1; Add/Edit hero **0.0**, first card **+0.2**, then accumulating — **named as the weaker screen**. **⟲ Phase 07 correction: six passing numbers out of eleven blocks.** Alarms still fails card 3 bottom **+4.8**, card 4 top **+5.6** and the meadow **+10.0**, with card 4 bottom and the nav bar `absent`; Add/Edit fails 8. Both are real and **not fixed in Phase 07** — another phase's screen is not this phase's to change blind — but they are now written down with their numbers instead of omitted. 31 findings across four passes, 27 applied, **2 invalid with a test**, none deferred. **No control was exercised by hand**: `flutter build ios --simulator` fails with Xcode 255 and taps did not reach the simulator; `flutter drive` works, so all four captures are verified |
| 05 | Alarm engine and reliability | done | `docs/phases/PHASE_05_PLAN.md` | `aca9f34` | 2026-11-16 | **The phase that made a saved alarm actually reach the platform — nothing armed anything before it** (`AlarmScheduleCoordinator` existed, fully tested, and was never constructed in `lib/`). Three adapters behind the ported abstractions, each **split pure-mapper / thin-shell** because the pre-review's arithmetic showed the legacy's 750 adapter lines would take `lib/data` from 86.40% to under 70% against an 85% gate. It worked better than predicted: **`lib/data` rose to 88.95%**, and 87 tests landed against a registered 25–40 — **both restated rather than passed quietly**. **`initializeTimeZones()` was never called in `lib/`** — the whole schedule engine is built on `package:timezone` and every test loaded the database in its own `setUpAll`, so the suite could stay green forever while the app threw on the path that arms alarms: **Phase 03's `initializeDateFormatting` defect exactly, one layer down**. The plan said "reboot" and **nothing in it survived a reboot** (resume and timezone events do not fire when the app is not running) — an overpromise under this row's own heading, now stated per platform. Self-review found two defects in this phase's own code: `arm`'s idempotence key floored to *now* for a past-due plan, so it **never matched and re-armed on every sync**; and `Alarm.ringing` is a seeded `BehaviorSubject`, so one ring was reported twice. **Phase 04's Xcode 255 is diagnosed and was never ours**: `flutter_tools` runs `lipo -verify_arch arm64 x86_64` and Xcode 27.2's lipo refuses two architectures in one call — **a stock `flutter create` project fails identically**. Taps land on the **iOS 27.0** runtime but not 16.4, which is the rest of Phase 04's symptom; the 18 Pro is 402×874 so **Tier A capture stays on the 14 Pro**. On device: the app runs with all three plugins and **`PlatformNotificationService` really reached iOS UserNotifications** (device log: 1 category registered, pending queried). **The Save button was never exercised by hand and no arming was watched interactively — recorded, not claimed.** Android untested, no emulator. **1,279 tests**, analyze clean, lib 97.46% / core 99.49% / data 88.95%, **405 ARB keys** (6 new). Comment budget bit **all 13 new files**; all trimmed by hand, **none baselined** |
| 06 | Ringing and emergency stop | done | `docs/phases/PHASE_06_PLAN.md` | `30b316a` | 2026-11-16 | **The phase whose own tracker row named a defect the previous project shipped.** The legacy's `dismiss()` and `escape()` (`../capywake/.../ringing_controller.dart:339,500`) open with `if (session == null) return;` and then await twice before `_emit(null)` clears `_current`; the screen holds no busy flag and no test covers a double call — so **there is no dismiss-exactly-once guard anywhere in the legacy.** This phase built one: a per-alarm latch set synchronously before the first await, a terminal-status check that survives a restart, and ring idempotence. **A third duplicate-row path was found by this phase's own final-alarm test:** `AlarmScheduleService.targetForRing` returns the fire instant for a ring with no window left — its doc names "a snooze" — so matching on `scheduledAt` alone created **a second occurrence row on every snooze re-ring**, with `snoozeCount` back at 0, silently defeating the cap. **Self-review #1 found the escape confirmation threw instead of opening**: `RingingHost` sits in `MaterialApp.builder`, above the router's Navigator, so `showModalBottomSheet` had no Navigator — *in the app as wired, the emergency escape did not work*, while every standalone screen test passed because they supply their own `MaterialApp`. Also: `escapeStrictness` was read from `PuzzleSettings.defaults()`, discarding the user's settings. **Self-review #2 proved the guard's test passed for the wrong reason** — disabling `_claim` left all six "exactly once" tests green (in-memory fakes never open the window); with a blocking engine it now fails three. **The full-project review found 12 ported dartdoc references naming legacy phase numbers** — "settings UI (Phase 19)" where 19 is Release QA, "wake surface (Phase 18)" where 18 is Animation polish, "lifecycle layer (Phase 07)" where 07 is Settings — read past by five phases; all now name the layer, not a number. **`tool/capture.sh`'s DEBUG-banner detector was wrong**: `r>140,g<90,b<90` called painted brown (151,92,48) a banner, so the first screen whose art reaches the top-right corner failed; tightened on saturation (ribbon r-g ~177, art 63) and verified it still catches a synthetic banner. **No Tier A claim** — there is no primary mockup for this screen, only a ~333×467 px board panel; held to tokens, the tap-target floor and board order/presence, with 6 deviations named in `docs/visual/ringing/`. **405 ARB keys, zero new** — the ported bundle already carried the whole escape vocabulary. **1,372 tests** (registered 55–80 new, measured 93), analyze clean incl. infos, lib 97.63% (registered a *fall* to 95.5–97.3%, measured a **rise** — the two self-reviews' 18 tests outran the prediction), core 99.49% exact as registered, data 88.95% held. Comment budget bit all 9 new files; **0 baselined**, 10 inherited entries tightened. 36 findings across four passes, all applied, none deferred |
| 07 | Settings, reliability checklist, walkthrough | done | `docs/phases/PHASE_07_PLAN.md` | `9def5ab` | 2026-11-17 | **The phase where the mockup and the content-integrity rule disagreed, and the rule won.** `04_SETTINGS.png` draws Backup & Sync, Restore Purchases, App Icon and a Daily Reminder toggle; none has anything behind it, so none ships. Its **Alarm Notifications switch** ships as a **status row that grants and never revokes**: a switch there stops every alarm from ringing, from inside Settings, with nothing on screen saying so — the lock-out rule one step earlier. **The permanently-denied user got nothing at all**: `shouldRequestNotification` is false for that grant, and the wiring asked `shouldOpenSettings` *inside* that branch, so the route to the OS was unreachable for the one user a prompt cannot help. **Nine of ten gate tests passed with the gate deleted** — "disabling the only alarm does not ask" seeded one alarm, so *a different rule* suppressed the prompt and the test could not tell; seeded with two, mutation now fails **two**. **`compare.dart` invented a delta**: it read one column at x=360 (text-free on Alarms, **under the hero art** here), never saw the card edge, then searched ±40 pt and claimed the **hero's** edge — printing "−18.7 TIER A FAIL" for a card **−2.7** from its mark. Now three columns, paint rejected below L=150, search ±12, `absent` past it; verified against all three prior captures, no new failures, false deltas collapsed (Home 36.2→1.4). **Four screens, four toggle sizes** (59.6/54.0/48.0/44.3 wide): `CapyToggle.trackSize` is now required, and `tier_a_blocks.md`'s Alarms toggle was wrong — "30.5 pt tall" came from a row profile at y=345, but the pill starts at 356.5, so it measured the rounded cap. Three pushed routes had **no `Scaffold`**, so Settings could not open at all. **Tier A: header +0.1, hero +0.1, group 1 top −2.7, group 2 top −0.6; group 1 bottom +4.5 fails** — the mockup's row is **41.1 pt against a 44 pt tap floor**, so group 1 cannot be under 116.2 vs 110.4; declared as a rule conflict with the arithmetic, not as a near-miss. **1,452 tests** (registered 70–100 new, measured **80**), analyze clean incl. infos, lib 97.80% / core **99.61%** (registered *unchanged* — restated: this phase is the first **caller** of the ported reliability services, now 100%) / data 88.95% / features/settings 98.49%, **427 ARB keys** (22 new). Comment budget bit all 14 new files; **0 baselined**. 38 findings across four passes, all applied |
| 08 | Stats | done | `docs/phases/PHASE_08_PLAN.md` | `8b66bfb` | 2026-11-17 | **The screen `CLAUDE.md` calls most likely to lie, and the gate it had claimed since Phase 00.** `05_STATS.png` draws a filled screen — `7 h 32 m`, a 7-bar chart, `6 days`, `Best: 14 days`, `94%` — and every one of those is fabricated; the shipped default is empty. **`tool/check_no_fake_stats.dart` written, tested (16) and widened to all of `lib/features/` (38 files, already clean).** **Three mutations run separately, and the third is the finding: a planted numeric `?? 6` fallback PASSES the gate entirely** and is caught only by the widget test (neutered matcher → 4 of its own tests fail; a planted `?? '7 h 32 m'` string → gate catches it + 2 widget tests fail). A gate that exists is not the same as a rule that holds; `CLAUDE.md` now states the blind spots beside the rule. The gate also shipped with two defects of its own, caught by its own fixtures written before the screen: **it could not match a percentage** (a `\b` after `%` can never hold — `%` and the closing quote are both non-word) and it flagged every localized call taking a number. **The sleep boundary is NOT discharged and this is said explicitly** — no `package:health`, so `sleep_boundary_test.dart` stays at `at most one`; the cost is that `sleepHistoryEmpty` says *"Connect Health"* and **no Connect control exists anywhere in the app**, so new keys state the fact instead (Phase 07's dead-control defect in new clothes). **Stats' own band 111.5 (a fifth value) and meadow 79.9 (a sixth)**; the green-collapse method Phases 04/07 used reproduces Settings at 213.1 and Alarms at 252.4 but **produces nothing here** — Stats' cream is a scalloped cloud, so the boundary is not a line (arc asymptote instead, cross-checked at both edges). **Tier A: header +0.1, hero −0.1, track top −1.4, track bottom +3.5, meadow `absent` ❌** — 4 of 5 claimed pass, and the failure is named. The claimed set was cut 13 → 5 in pre-review after finding the plan had declared eight blocks its own empty default cannot render. **Self-review #2 H1: the block table named the *track* and measured the *pill***, so `compare.dart` compared unlike edges and printed `+4.4 TIER A FAIL` for a pill **0.2 pt** from its mark — Phase 05's rule for the fourth consecutive phase, third in this same tool, and a new variant. **The three failing meadows are ONE fact**: every tab's grass ends at 694.3, the pushed Settings route reaches 793.0, `CapyNavBar` takes 98.7 pt against the mockup's 79.9 — Phase 07 had recorded them as three screen-local defects. **1,493 tests** (+41 against a registered 70–100 — restated: a screen that deliberately renders nothing has less to assert), analyze clean incl. infos, lib 97.85% / core 99.61% / data 88.95% / **`lib/features/stats` 100.00%**, **437 ARB keys × 10 locales** (+10). 15 findings across four passes, all applied, none invalid. Also found: `StatTile.caption` was dead surface no caller passed (the one uncovered line), `MeadowFooter` paints ~2× the mockup's grass (G19), `SceneHeader` is flat-topped while five mockups draw clouds (G18) |
| 09 | Onboarding | done | `docs/phases/PHASE_09_PLAN.md` | `74496a0` | 2026-11-17 | **The phase whose name promised a permission flow that was already built, and whose one real defect no test could see.** "Just-in-time permissions" was shipped in **Phase 07** — the prompt fires at first alarm enable, confirmed on device this phase. The legacy onboarding (`../capywake`, read-only) asks for **no** permission: it is a three-step preferences flow (welcome → puzzle → strictness) that writes `hasCompletedOnboarding`. What was actually missing: **`OnboardingStatus.needsOnboarding` was ported and tested but wired to nothing, and `hasCompletedOnboarding` had no writer in `lib/`** — a fresh install opened on an empty Home with no greeting. This phase added the `/onboarding` route (outside the shell), a push-only redirect, the welcome, and `completeOnboarding()`. **There is NO onboarding mockup**: the five primary screens contain none, and the `screens/alternative/onboarding_*` files are two exploratory boards (re-handed under five names) at 887×1774/852×1846 device-bezel geometry drawing the rejected 4-tab/Games nav — superseded. **Tier A binds nothing**; held to tokens, the tap floor, RTL, large-text reflow and no-overpromise (`docs/visual/_evidence/onboarding_boards.md`, `docs/visual/onboarding/`). **The central finding (SR1 H1): the CTA bounced to Home on the iPhone 18 Pro while every test passed.** The redirect had a pull branch (`atOnboarding && !needed → Home`); `completeOnboarding()` fired the `refreshListenable` mid-tap and the pull beat the CTA's own `go(/alarms/new)` — the fake async clock in widget tests ordered them the other way, so the buggy redirect passed all tests. Fixed to push-only; **pinned by a new test that fails against the buggy version** (Phase 05's rule + Phase 06's, together). Re-confirmed on device: CTA → Add Alarm → Save → the existing prompt, with honest degrade copy. **SR2 found an error-state crash** on the hot path (`alarms.requireValue` would throw if the alarms stream errored) — the provider now yields a value only when both streams have data. **Sleep-boundary still NOT discharged** — no `package:health`, stated explicitly; now unbuilt across 07, 08 and 09. Full-project also found the ported `OnboardingStatus` dartdoc describes a grandfathering path that **cannot occur** in a no-users greenfield rebuild (the `?? true` mapper branch is unreachable; `toJson` always writes the key), and that the baseline's `grep "Phase [0-9]" lib/ = 0` is scoped to hand-written Dart (bare it is 2 — a pre-existing ARB description). **1,513 tests** (+20 against a registered +18–28), analyze clean incl. infos, lib 97.84% / core 99.61% / data 88.95% / **`lib/features/onboarding` 100.00%**, **438 ARB keys × 10 locales** (+1, as registered). Comment baseline **+0** (113). 21 findings across four passes, all applied, none deferred |
| 10 | Puzzle chooser and the ten existing puzzle types | done | `docs/phases/PHASE_10_PLAN.md` | `b916607` | 2026-11-17 | **The phase that wired settings persisted since Phase 02 but written by no UI — every alarm used `PuzzleSettings.defaults()` forever.** Three surfaces, owner-confirmed: the chooser (pushed from Settings → Preferences), the two onboarding steps (welcome became a 3-step flow), and the per-alarm Tap/Puzzle dismiss section. **The owner supplied mockups mid-phase** (`CapyWake_Puzzle_Chooser_Onboarding_Handoff`) — but they are 378×1161-class storyboard crops, not 851×1847 native geometry, so **Tier A binds nothing** (measured, the handoff README says so), as Phases 06/09. **Three domain conflicts the art carried, domain won each:** escape strictness is 2-value (`confirm`/`confirmAndHold`, no "off") not the mockup's 3-with-"Never" — rendering "Never" would imply a lockout the safety rule forbids (owner: keep domain, honest labels); "After 1 min" split back into escape + the separate tolerance field; six sample cards → ten real types, "Shake" dropped (not a `DismissMethod`). **The ARB estimate round-tripped the restate discipline both ways:** plan said "possibly zero", pre-review H1 corrected to +10–14, measurement settled at **+2** — nearly the whole vocabulary (chooser, onboarding, per-alarm) was already ported in 10 locales. **SR1 H1: the dismiss segment misrepresented a `holdToDismiss` alarm** — showed Tap selected while storing Hold (latent; no UI creates Hold today, but the enum, mapper and summary all carry it); now names an unrepresentable method read-only, pinned by a seeded test. **SR2 H1: the onboarding completion path swallowed a write failure**, stranding the user on a dead button with the ported `onboardingSaveError` unused — Phase 09's SR2 one layer over (write side); now wrapped, holds position, shows the error, pinned by a throwing-repo test. **Full-project: three playable-practice onboarding strings stay unused on purpose** (a playable demo is a games-phase concern) — stated outright, Phase 09's ambiguity lesson applied. **Device-verified on the iPhone 18 Pro (Phase 09's rule): the stepped onboarding CTA lands on Add Alarm, not Home — the redirect race does NOT recur.** **1,547 tests** (+34 against a registered +45–75 — restated: the puzzle domain was already fully tested), analyze clean incl. infos, lib 97.93% / core 99.61% / data 88.95% / features/puzzle 99.30% / features/onboarding 100%, **440 ARB keys** (+2). Comment baseline **+0** (113); 9 new files, all trimmed by hand. 15 findings across four passes, all applied, none deferred |
| 11 | Game foundation | done | `docs/phases/PHASE_11_PLAN.md` | `4d9750b` | 2026-11-17 | **What a "game" is — the contract the ten games (12-17) slot into, built with no specific game and no new visible surface.** The one design call, settled in the plan: **a game is not a fourth `DismissMethod`** (that would bump the Drift mapper and ripple through 1,547 tests for a product that does not exist) — it is a puzzle-parallel challenge surface in the same `RingingScreen.puzzleSlot`. `GameChallenge` (`lib/core/games/`, pure Dart): goal in steps, `isComplete`, `struggleCount`, `escapeVisibilityFor` reusing the **enum** `PuzzleEscapeVisibility` but **not** `PuzzleEasingState`'s wrong-answer arithmetic — a game has no "wrong answer", it has missed taps (pre-review H1). The widget contract (`game_ringing_view.dart`): `onProgress`/`onCompleted`, `reduceMotion` threaded from `MediaQuery.disableAnimations` via `GameRingingSlot`; **the escape stays owned by `RingingScreen` — a game has no seam to hide or gate it** (H2), proven by a test-only conformer mounted in the real screen whose escape is reachable regardless of game state. **The foundation stayed headless** (H3): no onboarding demo, no new route — "Do not implement future phases"; the three unused onboarding strings stay unused for a games phase. **Motion fallback is call-site-required** (H4) and **SR1 closed the hole: a motion game's fallback could itself require motion** — now asserted `!fallback.requiresMotion`, so a motion game with no *usable* non-motion path cannot be built (the a11y rule, for Phase 15's two motion games). SR1 also bounded the goal (`target > 0`, else the alarm dismisses with zero play). **SR2: the escape policy source was implicit** — a test now proves a game and a puzzle offer the escape identically against the user's `toleratedWrongAnswers`, so a Phase 12 game that diverges fails; plus a mutation check (suppress completion → dismiss test fails, not a guard on trust). `GameCatalogue` grew **4 → 10** (zero `playable`) with an explicit **`homeRail` subset of four** so Home does not regress to ten tiles (pre-review M2/M3); **ARB +6** game name keys (restated in the pre-review from the plan's +0 — the catalogue needs them, the demo surface does not), six tile gaps **G23-G28**. **Full-project: the pre-review's own L1 was wrong** — it called Home's "See All" games action a dangling control with "no destination"; `PHASE_03_PLAN.md:202` records it as deliberate (See All → the Stats Games segment, both tabs), still coherent at ten games. Corrected, no change. **Tier A binds nothing** — the game posters are bezel-wrapped storyboards, not native geometry (as 06/09/10). **Device-verified on the iPhone 18 Pro: Home draws exactly the four tiles, not the ten; tapping Step Quest shows the blocked/step-count sheet.** **1,572 tests** (+25 against a registered +18-30), analyze clean incl. infos, lib 97.95% / core 99.61% / `lib/core/games` 100% / data 88.95% / `lib/features/ringing` 98.53%, **446 ARB keys × 10 locales** (+6). Comment baseline **113 (+0)**; 3 new files, all trimmed by hand. 18 findings across four passes (13 pre + 3 SR1 + 2 SR2), all applied, none deferred |
| 12 | Touch games I — Catch the Capy, Memory Hideout | done | `docs/phases/PHASE_12_PLAN.md` | `8743847` | 2026-11-17 | **The first two real games, and the selection model Phase 11 left open — settled by the owner in session: games join the Puzzle dismissal (no `DismissMethod`, no schema bump), the rotation is the default, an alarm may carry its own pool (a specific game or a subset), Home tiles launch practice.** `PuzzleSettings`/`AlarmPuzzleOverride` gained `enabledGames` + `includePuzzles` in the existing JSON; `includePuzzles` (not an empty `enabledTypes`) keeps the ported never-empty invariant intact for `PuzzleRound` at 03:00. `WakeChallengeSelector` picks one challenge per ring, uniform and seeded, falling back to puzzles on an empty launchable pool; **both mappers restore puzzles when unknown ids empty the pool on read** (pre-review H5), and `resolveFor` never yields an empty pool on the ring path. `GameRegistry` == catalogue-playable, pinned. Both games static (no tween, no timer); the escape rises against the **alarm's resolved** tolerance (H6, proven with an override ≠ default). **SR1 H1: the games had no card and would have drawn dark text on the scrimmed hero** — green in every view test. **SR2 on device: Memory Hideout kept the answer on screen while guessing, and Ready jumped ~30 pt under the finger.** **Full-project H1: Settings had painted "Default snooze leng9 minutes" since Phase 07 — it is in that phase's own capture**; guard fails 10/10 on the old row. **H2: es/fr/it/ar translated "puzzle" as "game"** — 73 strings retranslated, per-locale guard (19 offenders in old es). Tier A binds nothing new; Home (worst 1.4) and Settings re-captured unchanged. Asset gaps G23, G29–G32 reported in session, then closed by owner art. **Then made dynamic at the owner's direction mid-phase**: Catch the Capy runs non-stop, faces its direction, bolts from missed taps, runs faster on harder settings (1300/1000/750 ms), over the package's decor; Memory Hideout became a shell game (1/2/3 swaps). Motion stops under reduce-motion or a screen reader; `CLAUDE.md`'s animation rule narrowed to the ringing chrome. **The owner then supplied the art G29–G32 asked for** — an 8-frame nightcap gallop (aligned on nose + foot baseline, loop seam 9 %), dust, paw prints, meadow, plain bush, tile (wrong variant: baked frame, cut inside it) — all through the audited pipeline, run frames lossy-colour/lossless-alpha to stay in budget. **1,767 tests** (+195), analyze clean incl. infos, lib 98.20% / core 99.67% / `lib/core/games` + `lib/features/games` 100% / data 89.17% / ringing 98.62%, **466 ARB keys × 10** (+21 −1; estimate +12–16 restated). Comment baseline 113 (+0). 33 findings across four passes, 31 applied, 2 invalid with reasons |
| 13 | Touch games II — Rhythm Rescue, Capy Rocket | pending | | | | |
| 14 | Authored games — Morning Sort, Find the Impostor | pending | | | | Content-bank ban lifted for these two (owner, 2026-11-15) |
| 15 | Motion games — Shake DJ, Tilt Maze | pending | | | | a11y fallback mandatory |
| 16 | Capy Step Quest | pending | | | | **Blocked** — needs a step-count permission; owner decision required |
| 17 | QR Treasure Hunt | pending | | | | **Blocked** — needs a camera dependency; owner decision required |
| 18 | Animation and visual polish | pending | | | | 5 WebP loops, reduce-motion, dark mode pass |
| 19 | Release QA | pending | | | | iOS + Android regression, bundle size, store readiness |

## Session log

- **2026-11-17** — Phase 11. Game foundation. **The shape the ten games (12-17)
  slot into, built with no specific game and no new visible surface.** The design
  call: **a game is not a fourth `DismissMethod`** (that would bump the Drift
  mapper for a product that does not exist) — it is a puzzle-parallel challenge in
  the same ringing slot. `GameChallenge` (pure Dart) reuses the escape-visibility
  **enum** but not `PuzzleEasingState`'s wrong-answer arithmetic — a game counts
  missed taps, not wrong answers (pre-review H1). **The escape stays owned by
  `RingingScreen`; a game can only signal prominence, never hide or gate it**
  (H2). **The foundation stayed headless** (H3) — no onboarding demo, no route;
  the three unused onboarding strings stay unused for a games phase. **SR1: a
  motion game's fallback could itself require motion** — now asserted against, so
  a motion game with no usable non-motion path cannot be built (Phase 15's rule).
  **SR2: a test now proves games and puzzles offer the escape identically against
  the user's tolerance** — a Phase 12 game that diverges fails. `GameCatalogue`
  grew 4 → 10 (zero playable) with a `homeRail` subset of four so Home does not
  regress; **ARB +6**, six tile gaps G23-G28. **Full-project found the pre-review's
  own L1 wrong** — Home's "See All" games action is not dangling; Phase 03 routed
  it to the Stats Games segment on purpose. **Tier A binds nothing** (bezel
  posters). **Device-verified: Home draws the four tiles, not the ten; Step Quest
  shows the blocked sheet.** 1,572 tests (+25), analyze clean, lib 97.95% / core
  99.61% / games 100% / data 88.95%, 446 ARB keys. 18 findings, all applied.

- **2026-11-17** — Phase 10. Puzzle chooser + onboarding puzzle/strictness steps
  + per-alarm dismiss method. **Wired the puzzle settings that had been persisted
  since Phase 02 but written by no UI** — every alarm used
  `PuzzleSettings.defaults()` forever. The owner supplied mockups mid-phase, but
  they are storyboard crops (378×1161), not 851×1847 native geometry, so **Tier A
  binds nothing** (as Phases 06/09). Three domain conflicts the art carried, the
  domain won each: escape strictness is 2-value with no "off" (the mockup's
  "Never" is not rendered — safety rule); "After 1 min" split into escape +
  tolerance; ten real types not six, no "Shake". **ARB came out +2, not the
  pre-review's registered +10–14** — nearly the whole vocabulary was already
  ported in 10 locales. SR1 found the dismiss segment misrepresented a
  `holdToDismiss` alarm (shown as Tap); SR2 found the onboarding completion path
  swallowed a write failure (Phase 09's SR2, write side) with
  `onboardingSaveError` unused — both fixed and pinned. **Device-verified on the
  iPhone 18 Pro: the stepped onboarding CTA lands on Add Alarm, not Home — the
  Phase 09 redirect race does not recur.** 1,547 tests (+34), analyze clean, lib
  97.93% / core 99.61% / data 88.95% / puzzle 99.30% / onboarding 100%, 440 ARB
  keys. 15 findings, all applied.

- **2026-11-17** — Phase 09. Onboarding. The phase name promised "just-in-time
  permissions" and found them **already built** (Phase 07): the prompt fires at
  first alarm enable, confirmed on device. What was missing was the first-run
  entry — `OnboardingStatus.needsOnboarding` was ported and tested but wired to
  nothing, and `hasCompletedOnboarding` had no writer. Added the `/onboarding`
  route, a push-only redirect, the welcome, `completeOnboarding()`, one ARB key.
  **No onboarding mockup exists** (the `alternative/onboarding_*` boards are
  superseded 4-tab explorations at device-bezel geometry) — no Tier A claim.
  **The central finding: the CTA bounced to Home on device while every test
  passed** — a redirect pull-branch raced the CTA's own navigation, and the fake
  async clock hid it; fixed to push-only and pinned by a test that fails against
  the buggy version. SR2 found an error-state crash on the redirect's hot path.
  Full-project found the ported predicate's dartdoc describes a grandfathering
  path impossible in a no-users rebuild, and that the `grep "Phase [0-9]"`
  baseline is Dart-scoped. **1,513 tests** (+20), analyze clean, lib 97.84% /
  core 99.61% / data 88.95% / onboarding 100%, 438 ARB keys. 21 findings, all
  applied.

- **2026-11-16** — Phase 02. Ported the domain: 62 `lib/core/` files, 47
  `test/core/` files, 4 `lib/data/` files at `schemaVersion = 1`, 4 `test/data/`
  files, 12 sound assets. **1,051 tests**, `lib/core` **99.41%** behind the
  re-enabled 95% gate. The pre-review registered every test count *before*
  implementing and its own first draft was 26% out on the data tests (estimated
  66, measured 83) — the discipline caught its author. Seven tests failed after
  the raw copy, none a logic defect: `assets/sounds/` was missing from the plan
  (the audit lists it; the plan paraphrased), three sleep-boundary tests asserted
  phase-07/08 infrastructure, and the iOS/Android app labels still read
  "Capywake". The dropped `theme_test.dart`'s replacement found **two real AA
  failures** in Phase 01's palette. Four gates were found green for the wrong
  reason: a documented `tool/audit_art.dart` that does not exist, an art-only
  bundle check while assets reached 10.5 MB, an ungated `lib/data` at 85.08%, and
  that 85.08% itself concealing 67 uncoverable Drift getters. 40 findings, all
  applied.

- **2026-11-16** — Phase 00. Handoff package read in full (7 docs, 11 phase
  briefs, workspace state). All five primary mockups inspected and measured:
  851×1847 px = **393×853 pt**, i.e. iPhone 14 Pro, which is available as a
  simulator — so screenshot comparison is exact. Palette sampled. `../capywake`
  audited read-only. Evidence saved to `docs/visual/_evidence/` that the Home
  mockup hero (nightcap, duck, nightstand clock) is **not**
  `today_integrated.png` (no cap, no duck, mug and books) — the two were
  generated separately, which is why the fidelity contract is two-tier. No app
  code written, by design.

- **2026-11-17** — Phase 12. Touch games I. **The first two real games plus the
  selection model** (owner, in session): games join the Puzzle dismissal, the
  rotation is the default, an alarm may carry its own pool, Home tiles launch
  practice. Then, on the owner's direction mid-phase, **both games made dynamic**
  (non-stop running capybara; shell-game shuffle) with motion stopped under
  reduce-motion or a screen reader. Full-project review found Settings painting
  "Default snooze leng9 minutes" since Phase 07 and four locales calling puzzles
  "games"; both fixed and guarded. Legs/dust/footsteps need frame art (G32).

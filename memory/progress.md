# Progress

Running narrative. Append a block per completed phase; never rewrite history.

---

## Phase 00 — Discovery, legacy audit, architecture and navigation decision

**Done 2026-11-16.** No app code, by design.

**Produced:** `CAPYWAKE_LEGACY_AUDIT.md`, `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md`,
`docs/phases/PHASE_00_PLAN.md`, `docs/phases/PHASE_00_PRE_REVIEW.md`,
`docs/phases/PHASE_01_PLAN.md` (draft), `CLAUDE.md`, the phase tracker, the
memory and session files, and `docs/visual/_evidence/`.

**Audited read-only:** `../capywake` — 40/47 phases done, 137 Dart files, 99
test files, 10 locales, coverage gates, a real phase ritual.

**Root cause of the failed retrofit:** the legacy's own rule that the capybara
must be vector `CustomPaint` and "never a raster cutout". Not inherited.

**Measured:** mockups are 851×1847 px = 393×853 pt = iPhone 14 Pro, available
here, so screenshot comparison is exact.

**Evidenced:** the Home mockup hero (nightcap, duck, nightstand clock) is not
`today_integrated.png` (no cap, no duck, mug and books). Separate generations,
hence the two-tier fidelity contract.

**Decided:** raster art · all three Stats segments · full rigor incl. 10
locales (owner). Navigation = Home/Alarms/Stats tabs + gear→Settings (from
4-of-5 mockup evidence).

**Pre-review:** 12 findings, 4H/5M/3L, all applied, none deferred. The Highs
moved the domain ahead of the first screen, made the capture harness a gating
deliverable, replaced "1:1" with a measurable contract, and hardened Stats
against fabricated numbers.

**Next:** Phase 01 — Foundation. Gated on `tool/capture.sh` producing a real
PNG of the shell at 393×852.

### Phase 00 addendum — reuse audit and self-review (same day)

Owner asked what could be reused from `../capywake`. Answer: far more than
Phase 00 allowed. Self-review found 8 findings (2H/3M/3L), all applied.

Verified by running the commands, not by reading docs: only `lib/core/theme.dart`
imports Flutter in all of `core/`; nothing in `core/` depends on it; 0 of 48
core test files import feature code; `flutter test test/core` → **932 passed**;
3 of 383 ARB keys are navigation-coupled.

**SR-1 (High)** — Phase 00's "no code copied, and none will be" was wrong, and
contradicted its own correctly-scoped "no copied *widget* code". Corrected to
a greppable rule: **if a file imports Flutter, it is not ported.**

**SR-2 (High)** — Phase 00 skipped its own post-implementation reviews, which
is how SR-1 shipped. Tracker now applies steps 8–10 to documentation phases.

Phase 02 changes from "build the domain" to "port and adapt the domain".
~45,000 lines of tested, translated, non-UI work is portable.

Added: `CAPYWAKE_REUSE_AUDIT.md`, `docs/phases/PHASE_00_SELF_REVIEW.md`,
`NEXT_SESSION_PROMPT.md`.

---

**Phases 01–03 added no entry here.** The tracker carried their detail and this
file was left at Phase 00 — found in Phase 04. Summarised below from the
tracker and post-reviews rather than left as a hole.

## Phase 01 — Foundation: tokens, type, art pipeline, shell, capture harness

`ebe89e4`. The gate: `tool/capture.sh` writes verified PNGs at 1179×2556 and
**checks the artifact, not the exit code** — the pre-review proved the planned
`flutter test` mechanism passes while writing nothing, which is the legacy's
40-phase failure, green throughout. Typeface **Baloo 2**, which does *not*
cover Cyrillic/Arabic/Japanese (a `getmask` check wrongly said it did — only
rendering shows tofu), so `ru`→Nunito, `ar`/`ja`→system. 43 tests.

## Phase 02 — Domain and persistence, ported from `../capywake`

`4376154`. 62 `lib/core/` files, 47 `test/core/` files, Drift at
`schemaVersion = 1`. **Test identity closed exactly as pre-registered.** Not
932 ported but **912** — `theme_test.dart` tests the unported `theme.dart`,
and its replacement `tokens_contrast_test.dart` then found two real AA
failures in the palette. 1,051 tests.

## Phase 03 — Home / Today

`b3b0574`. The first screen with a body, so the first real test of the
fidelity contract — and it found a defect latent since Phase 01.
`SceneHeader` drew the cream card *inside* the hero art's `Stack`, reading the
mockup's 292.3/303.4 edges as two positions when they are one edge plus a
corner radius. Every hero band was **11.1 pt short** and Phase 01 had recorded
those exact deltas and blamed "the screens have no bodies" — **wrong in three
documents**, all corrected in place. Also: three of Phase 03's own block rows
were **glyph edges**, and `initializeDateFormatting` was never called in
`lib/`. 1,116 tests.

## Phase 04 — Alarms list and Add/Edit alarm

The first screens that **write**. Four findings about earlier work:

1. **`SceneHeader.bandHeight` defaulted to Home's 188.4.** Alarms is 148.6,
   Add/Edit 112.1 — both opened +39.8 pt out. Making it **required** surfaced
   **Stats silently carrying Home's number** too. Third occurrence of a shared
   default standing in for a per-screen measurement.
2. **`compare.dart` could not see a card border** — a 1-px line moves a 393-pt
   row mean by under one unit, so four correctly-placed cards read `absent`;
   the first fix still missed the two **disabled** rows at 55% opacity.
3. **`lib/core` could not drive either screen** — `AlarmFormat.time` returns
   one string where both mockups style digits and marker apart. `timeParts`
   added; a proposed `periodLeads` field was **dropped on measurement**.
4. **`CapyNavBar` overflowed at 2× text on every screen**, found incidentally.

Phase 03's **P4 matcher decision** was made here, on screens that pass, with
its limits stated. **1,189 tests**, 399 ARB keys, lib 97.54% / core 99.41% /
data 86.40%. 31 findings across four passes, 27 applied, 2 invalid with a
test, none deferred.

**No control was exercised by hand**: `flutter build ios --simulator` fails
with Xcode 255 and taps did not reach the simulator. `flutter drive` works, so
all four captures are verified. Phase 05 owns the fix.

## Phase 05 — Alarm engine and reliability

**The phase that made a saved alarm actually reach the platform** — nothing
armed anything before it. `AlarmScheduleCoordinator` existed, fully tested, and
was never constructed in `lib/`.

1. **`initializeTimeZones()` was never called in `lib/`.** The whole schedule
   engine is built on `package:timezone`, and every test loaded the database in
   its own `setUpAll` — so the suite could stay green forever while the app
   threw on the path that arms alarms. **Phase 03's `initializeDateFormatting`
   defect, one layer down.**
2. The plan said "reboot" and **nothing in it survived a reboot** — an
   overpromise under its own heading, now stated per platform.
3. `arm`'s idempotence key floored to *now* for a past-due plan, so it never
   matched and **re-armed on every sync**.
4. **Phase 04's Xcode 255 was never ours**: `lipo -verify_arch arm64 x86_64`,
   which Xcode 27.2 refuses; a stock `flutter create` project fails identically.

Three adapters split pure-mapper / thin-shell on the pre-review's arithmetic.
**1,279 tests**, 405 ARB keys, lib 97.46% / core 99.49% / data **88.95%**
(registered 25–40 new tests, measured **87** — restated).

## Phase 06 — Ringing and emergency stop

**The phase whose own row named a defect the previous project shipped**: the
legacy has **no dismiss-exactly-once guard** anywhere.

1. **The emergency escape threw instead of opening.** `RingingHost` sits in
   `MaterialApp.builder`, above the router's Navigator, so `showModalBottomSheet`
   had no Navigator — *in the app as wired, the escape did not work*, while every
   standalone screen test passed.
2. **The guard's test passed for the wrong reason, proven by mutation.**
   Disabling `_claim` left all six "exactly once" tests green: with in-memory
   fakes the async window never opens.
3. A third duplicate-row path: `targetForRing` returns the fire instant for a
   ring with no window left, so matching on `scheduledAt` created **a second
   occurrence on every snooze re-ring**, silently defeating the cap.
4. **Twelve ported dartdocs named the wrong phases**, read past by five phases.
5. `tool/capture.sh`'s DEBUG-banner detector called painted brown a banner.

**No Tier A claim** — there is no primary mockup for ringing. **1,372 tests**
(registered 55–80 new, measured **93**), lib 97.63%.

## Phase 07 — Settings, reliability checklist, walkthrough

**The phase where the mockup and the content-integrity rule disagreed.**

1. **The mockup drew a switch that would silence every alarm.** Alarm
   Notifications ships as a **status row that grants and never revokes**;
   revoking stays in the OS, where the OS states the consequence.
2. **The permanently-denied user got nothing at all** — `shouldOpenSettings`
   was asked *inside* a branch that is false for exactly that grant.
3. **Nine of ten gate tests passed with the gate deleted.** "Disabling the only
   alarm" seeded one alarm, so a *different* rule suppressed the prompt.
   **Phase 06's lesson in a new costume: one rule covering for another.**
4. **`compare.dart` invented a delta** — one column at x=360, under the hero
   art here, then a ±40 pt search that claimed the hero's edge and printed
   "−18.7 FAIL" for a card −2.7 from its mark.
5. **Three screens fail their own Tier A tables, and two phases wrote down only
   their passing blocks.** Home's six failures are all `absent` (worst measured
   delta **1.4 pt** — the layout is fine, the reporting was not); Phase 03's row
   listed 4 of 14 blocks, Phase 04's 6 of 11. Both corrected in place.
6. **Nineteen more stale dartdocs** after Phase 06 fixed twelve — counted, 20
   before and 1 after.
7. **`tool/check_no_fake_stats.dart` has never existed**, though `CLAUDE.md`
   claimed it enforced the rule on the screen most likely to lie. *Phase 02's
   `audit_art.dart` finding, again.*
8. **Four screens, four toggle sizes.** `trackSize` now required.

**Tier A: one failure, and it is a rule conflict** — the mockup's row is
41.1 pt against a 44 pt tap floor, so group 1 cannot be under 116.2 vs 110.4.
Declared with the arithmetic. **1,452 tests** (registered 70–100, measured
**80**), 427 ARB keys, lib 97.80% / core **99.61%** (registered *unchanged* —
this phase is the first **caller** of the ported reliability services).
38 findings across four passes, all applied.

## Phase 08 — Stats (2026-11-17)

**The screen `CLAUDE.md` calls most likely to lie, and the gate it had claimed
since Phase 00.** `05_STATS.png` draws `7 h 32 m`, a 7-bar chart, `6 days`,
`Best: 14 days`, `94%` — all fabricated. The shipped default is empty.

1. **A gate that exists is not the same as a rule that holds.**
   `tool/check_no_fake_stats.dart` written, tested (16), widened to all of
   `lib/features/` (38 files, already clean). Three mutations run separately;
   the third is the finding: **a planted numeric `?? 6` fallback PASSES the
   gate entirely** and is caught only by the widget test. Writing the file
   Phase 07 found missing would have left `CLAUDE.md` making a *new* false
   claim. Blind spots now stated beside the rule and asserted in its test.
2. **The gate shipped with two defects of its own**, caught by fixtures
   written before the screen: **it could not match a percentage** (`\b` after
   `%` can never hold) and it flagged every localized call taking a number.
3. **The block table named the *track* and measured the *pill*.**
   `compare.dart` printed `+4.4 TIER A FAIL` for a pill **0.2 pt** from its
   mark. *The tool was right, the widget was right, the table between them was
   wrong.* Phase 05's rule, fourth consecutive phase, third in this same tool.
4. **Three failing meadows are ONE fact.** Every tab's grass ends at 694.3,
   the pushed Settings route reaches 793.0: `CapyNavBar` takes 98.7 pt against
   the mockup's 79.9. Phase 07 had recorded them as three screen-local
   defects.
5. **The plan declared eight blocks its own default cannot render.**
   Pre-review cut the claimed set 13 → 5; the eight keep their mockup values
   for the phase that builds the filled state.
6. **`sleepHistoryEmpty` says "Connect Health" and no Connect control exists**
   anywhere in the app — Phase 07's dead-control defect in new clothes.
7. **The green-collapse hero-edge method does not work on every screen.**
   It reproduces Settings (213.1 vs 212.9) and Alarms (252.4 vs 252.5) and
   produces **nothing** on Stats, whose cream is a scalloped cloud.
8. **The sleep boundary is NOT discharged**, and this is said explicitly for
   the second phase running.

**Tier A: header +0.1, hero −0.1, track top −1.4, track bottom +3.5, meadow
`absent` ❌** — 4 of 5 claimed pass and the failure is named. Band **111.5**
(fifth distinct value), meadow **79.9** (sixth). **1,493 tests** (registered
70–100, measured **+41** — restated: a screen that deliberately renders
nothing has less to assert), 437 ARB keys, lib 97.88% / core 99.61% /
**`lib/features/stats` 100.00%**. 15 findings across four passes, all applied,
none invalid.

---

## Phase 09 — Onboarding (2026-11-17)

**Done 2026-11-17.** The phase whose name promised a permission flow that was
already built, and whose one real defect no test could see.

**What was actually missing.** "Just-in-time permissions" was shipped in
**Phase 07** — the prompt fires at first alarm enable (confirmed on device:
Save → "Alarm notifications … Cancel / Allow", with honest degrade copy). The
legacy onboarding (`../capywake`, read-only) asks for **no** permission — it is
a three-step preferences flow (welcome → puzzle → strictness). What was missing
was the first-run entry: **`OnboardingStatus.needsOnboarding` was ported and
tested but wired to nothing, and `hasCompletedOnboarding` had no writer in
`lib/`** — a fresh install opened on an empty Home. Added: the `/onboarding`
route (outside the shell), a push-only redirect, the welcome, and
`completeOnboarding()`. One ARB key, `onboardingFirstAlarmCta`.

**No onboarding mockup.** The five primary screens contain none; the
`screens/alternative/onboarding_*` files are two exploratory boards re-handed
under five names at 887×1774 / 852×1846 device-bezel geometry drawing the
rejected 4-tab/Games nav — superseded. **Tier A binds nothing**; held to tokens,
the 44 pt tap floor, RTL, large-text reflow and no-overpromise
(`docs/visual/_evidence/onboarding_boards.md`). Not added to the capture set.

### What this phase found

1. **A screen every test passed was broken on device (SR1 H1).** The CTA
   bounced to **Home** on the iPhone 18 Pro. The redirect had a *pull* branch
   (`atOnboarding && !needed → Home`); `completeOnboarding()` fired the
   `refreshListenable` mid-tap and the pull beat the CTA's `go(/alarms/new)`.
   The fake async clock in widget tests ordered them the other way, so the buggy
   redirect **passed everything**. Fixed to push-only; pinned by a test that
   fails against the buggy version. Phase 05's rule + Phase 06's, together.
2. **SR2 — an error-state crash on the hot path.** `alarms.requireValue` after
   only an `isLoading` check would throw on an errored stream, on a provider
   read on every navigation. Now yields a value only when both streams have
   data.
3. **The phase name over-promised** (full-project M1): the permission flow was
   already built. Reporting "already done" was the honest output.
4. **Ported `OnboardingStatus` dartdoc describes a grandfathering path that
   cannot occur** in a no-users rebuild — the `?? true` mapper branch is
   unreachable (`toJson` always writes the key). Recorded, not rewritten.
5. **The `grep "Phase [0-9]" lib/ = 0` baseline is Dart-scoped** — bare it is 2
   (a pre-existing ARB description + its generated mirror).
6. **The sleep boundary is still NOT discharged** — no `package:health`, now
   unbuilt across 07, 08 and 09, stated explicitly.

**1,513 tests** (+20 against a registered +18–28), analyze clean incl. infos,
lib 97.84% / core 99.61% / data 88.95% / **`lib/features/onboarding` 100.00%**,
**438 ARB keys** (+1). Comment baseline **+0** (113). 21 findings across four
passes (12 pre-review, 4 SR1, 2 SR2, 3 full-project), all applied, none
deferred.

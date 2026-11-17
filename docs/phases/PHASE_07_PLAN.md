# Phase 07 — Settings, reliability checklist, walkthrough

Status: **plan** (revised after `PHASE_07_PRE_REVIEW.md`; revisions marked ⟲)

## Objective

Build the Settings screen against `04_SETTINGS.png` under the full fidelity
contract, plus the two screens `CLAUDE.md` places behind it — the **Reliability
Checklist** and the **Setup Walkthrough** — and wire `AlarmPermissionGate`,
which Phase 05 created and Phase 06 handed on.

This is the first phase since 03 with a real primary mockup **and** a
content-integrity rule that contradicts it. `04_SETTINGS.png` draws Backup &
Sync and Restore Purchases; `CLAUDE.md` drops both. That conflict is the
phase's central design decision and is resolved in §4.

## Reference

`reference/01_REFERENCES/screens/primary/04_SETTINGS.png`
851×1847 px @ 2.1653 px/pt = **393×853 pt** (iPhone 14 Pro).

## 1. Measurements — Tier A block table

Every number states the method that produced it, per `CLAUDE.md`. Absolute pt
from the top of the mockup, which draws a 44 pt status bar.

### 1.1 Blocks

| Block | Edge (pt) | Method |
|---|---|---|
| Header band lower edge | **103.9** | ⟲ L2: **inherited** from Home — the same `CapyHeader`. Cross-checked here (hero art's first green pixels at 104, saturation climbing from 103) but **not independently derived**: the art's top edge is a soft fade, so there is no edge to detect. |
| Hero art lower edge | **212.9** | Green-saturation count per row collapses 53→30 between 212.4 and 213.4; midpoint taken. Same rule Phase 04 applied to Alarms (67→58). Flat art → flat cream. |
| Group 1 (Alarms) card | **231.4 – 341.8** | **Left-card-edge presence trace** (new method, §1.3) |
| Group 2 (Appearance) card | **355.6 – 472.5** | same |
| Group 3 (Notifications) card | **486.3 – 598.5** | same |
| Group 4 (Account) card | **611.9 – 753.2** | same |
| Meadow footer top | **770.3** | Green-saturation run crosses 20 hits at 2-px sampling (Phase 04 used ≥40 at full sampling — same density) |

### 1.2 Inside each group

| Block | Edge (pt) | Method |
|---|---|---|
| G1 header band | 232.3 – 263.7 | `blue < 218` run at x=22.2 pt. Band cream is (249,229,207), card cream (254,244,229) — the blue channel separates them by 22 levels. **31.4 pt here** against the other three's 28.2. ⟲ M7: the hero art's soft lower edge overlapping it is an **explanation offered for the disagreement, not a measurement of G1**. 28.2 is taken; the capture settles whether the explanation held. |
| G1 row divider | 301.1 | Single-row full-width faint line (span 358 of 360 sampled columns) |
| G2 header band | 356.1 – 384.2 | `blue < 218`, **28.2 pt** |
| G2 row divider | 429.5 | full-span single row |
| G3 header band | 486.3 – 514.0 | `blue < 218`, **28.2 pt** |
| G3 row divider | 551.4 | full-span single row |
| G4 header band | 612.4 – 640.6 | `blue < 218`, **28.2 pt** |
| G4 row dividers | 677.5, 712.6 | full-span single rows |

### 1.3 The method that corrected my own first reading — record it

My first pass read isolated dark lines at **340.4 / 471.1 / 597.1 / 752.3 pt**
as each next group's **top** edge. Each is a ~1.5 pt dark line with flat page
cream on both sides, which looks exactly like a card edge.

They are the **previous** card's bottom drop-shadow. Taking them as tops would
have made every group ≈15 pt tall at the top, and every inter-group gap
**negative** (−1.4 pt) — which should have been the tell, and nearly wasn't.

What caught it: tracing the **left card edge row by row** — for each row, the
first x in 0…30 pt with L < 238. A row inside a card has a dark edge pixel at
x = 9.7 pt; a row in a gap has none anywhere in that span. The gap rows are
flat cream, so a line at 340.4 cannot be a card top. The corner radius is
visible in the same trace as an inward ramp 22.2 → 9.7 over ≈16 pt.

This is Phase 03's rule wearing new clothes: **the shadow is adjacent to a
textured region (the card it belongs to)**, so the detector alone could not
place it. It is also Phase 05's rule — the instrument was not wrong, my reading
of it was, and only a second, independent method could tell which.

### 1.4 Control and horizontal geometry

| | pt | Method |
|---|---|---|
| **Gutter** | **9.70** | `blue < 222` group-header band edge. Agreed to 0.00 pt across Appearance, Notifications and Account independently. Alarms reads 0.0 only because the hero art still covers its band — art, not layout. |
| **Card width** | **373.6** | 9.70 → 383.32, same measurement |
| Corner radius | ≈16 | left-edge ramp in the §1.3 trace |
| Toggle track | x 321.9 – 366.2 (**44.3** wide) | green anchor `g>r+15, g>b+30, g>90` |
| Toggle 1 (Alarm Notifications) | y 520.5 – 545.5 (**25.0** tall) | green count per row |
| Toggle 2 (Daily Reminder) | y 560.5 – 585.5 (**25.0** tall) | green count per row |
| Theme tiles | x 180.6–240.2 / 247.1–303.0 / 310.8–366.2 | saturation (max−min > 45) or dark (max < 170) column scan |
| Theme tile row | y 384.7 – 429.5 (**44.8** tall) | same |

### 1.5 Header region

| | pt | Method |
|---|---|---|
| Status-bar ink ends | 24.9 | dark-ink run — device, not drawn by us |
| Brand lockup bbox | 27.7 – 57.7 | `L < 100` bbox, includes the capy icon |
| "Settings" title bbox | 59.6 – 97.4 (h 37.9) | `L < 100` bbox, centre |
| Back chevron | x 23.1–35.1, y 55.9–76.7 (12.0 × 20.8) | `L < 120` bbox, left region only |

### 1.6 Derived — **inference, not measurement**

| | pt | From |
|---|---|---|
| **Hero band height** | **109.0** | 212.9 − 103.9 |
| Inter-group gap | **13.9 / 13.9 / 13.4** | 355.6−341.8, 486.3−472.5, 611.9−598.5 |
| G1 / G2 / G3 / G4 height | 110.4 / 116.9 / 112.2 / 141.3 | bottoms − tops |
| Row height, G1 (2 rows below band) | ≈39.1 | ⟲ L3: (341.8 − 263.7) / 2 — **a division, not a measurement** |
| Row height, G4 (3 rows below band) | ≈37.5 | ⟲ L3: (753.2 − 640.6) / 3 — same |
| `MeadowFooter.height` | **82.7** | ⟲ L1: 853 − 770.3, which **assumes the meadow runs to the exact bottom of the mockup**. Inference; the capture tests it. |

⟲ **L3: neither row height is used as a layout constant.** Phase 03's tile size
was 27 % wrong because a value inferred from other rows was shipped as if
measured. Rows size to their content; these two numbers are a cross-check on
the capture, nothing more.

**A fourth distinct hero band.** Home 188.4, Alarms 148.6, Add/Edit 112.1,
Settings **109.0**. `SceneHeader.bandHeight` is passed explicitly, as Phase 04
made mandatory. `MeadowFooter.height` is likewise a fifth distinct value.

## 2. Scope

### 2.1 Settings screen (`04_SETTINGS.png`)

Four grouped cards, each a header band plus rows, on a `SceneHeader` hero and
above a `MeadowFooter`. Pushed route — no tab bar, a back affordance in the
header, exactly as the mockup draws it.

### 2.2 Reliability Checklist — a pushed sub-route

Renders `ReliabilityChecklistService.build(...)` and
`ReliabilityCopyService.attentionSummary(...)`. Both already exist, are fully
ARB-backed and are at 99.49 % coverage; this phase writes **a renderer, not a
rule**. Actions: request notification, request exact alarm (Android), open OS
settings, acknowledge.

### 2.3 Setup Walkthrough — a pushed sub-route

`settingsOnboardingEntryLabel` / `…Description` already exist. Phase 09 owns
onboarding proper; this phase ships the **entry point and a replayable
summary**, not the first-run flow. See §5 for why that is not a dead row.

### 2.4 `AlarmPermissionGate` wiring — the inherited obligation

Wired on the **alarm-enable path**, which is where the gate's own doc says it
belongs: `isFirstEnableTransition(before:after:)` fires once, on the edge from
"nothing enabled" to "something enabled". Two call sites: the Alarms list
toggle (`_setEnabled`) and the Add/Edit save. The reason is shown before the OS
prompt. Never on app start.

## 3. Exclusions, each with its reason

| Not in this phase | Why |
|---|---|
| Puzzle **type chooser** | Phase 10. Seven of ten types have no renderer; `PuzzleView` throws on them. A chooser here could configure an alarm that cannot be solved. |
| Onboarding **flow** | Phase 09 |
| History screen | Lives in Stats (Phase 08) |
| App Icon variants | No alternate-icon infrastructure exists; see §4 |
| Dark-mode polish | Phase 18 |
| `package:health` / `LiveSleepGateway` | §6 |

## 4. Content integrity — where the mockup and `CLAUDE.md` disagree

`CLAUDE.md`: *"Settings: show only implemented rows. Backup & Sync and Restore
Purchases are dropped — there is no backend and nothing to restore."*

`04_SETTINGS.png` draws an **Account** group containing exactly those two rows,
plus About CapyWake. It also draws an **App Icon** row with a chevron.

**Resolution: the rule wins, and the deviation is named, not hidden.**

| Mockup row | Shipped? | Reason |
|---|---|---|
| Alarms → Sound | ✅ | `settingsDefaultSoundLabel`, `AlarmSound` catalogue exists |
| Alarms → Snooze | ✅ | `settingsDefaultSnoozeLabel`, `defaultSnoozeMinutes` persists |
| Appearance → Theme | ✅ | ⟲ L6: three tiles mapping to `ThemeModePreference`'s **system / light / dark**. The mockup's middle tile reads as a sunset, but there is no sunset theme and inventing one would be a fake row; the middle tile is **System** and its art must read as "follows your phone". ⟲ L5: if the tile art is absent from the asset package it is an **asset gap** — reported in the session and appended to `docs/visual/asset_gaps.md`, never substituted silently. |
| Appearance → App Icon | ❌ | No alternate-icon asset set, no platform plist entries, nothing to open. A chevron onto nothing is the dead tap `CLAUDE.md` forbids. |
| Notifications → Alarm Notifications | ⟲ **replaced** | Pre-review **H2**: a toggle that silently disarms every alarm is a safety defect. See §4.1. |
| Notifications → Daily Reminder | ❌ | No evening-reminder scheduler exists. |
| Account → Backup & Sync | ❌ | `CLAUDE.md`, explicitly. No backend. |
| Account → Restore Purchases | ❌ | `CLAUDE.md`, explicitly. No IAP. |
| Account → About CapyWake | ✅ | ⟲ L4: the version is read from the build, never hard-coded. **A literal "1.0.0" would be a fabricated value on a screen `CLAUDE.md` names as one that will try to lie**, and is forbidden here. |

**Rows the mockup does not draw but `CLAUDE.md` requires here:** Alarm
reliability, Setup walkthrough. Both are placed in a fifth group.

This is a **Tier A structural deviation and is declared as one**: the shipped
screen has a different row set from the mockup, so the group geometry below
Appearance cannot match and will not be claimed to. §8 states exactly which
blocks are therefore not comparable.

### 4.1 ⟲ The Notifications group, after pre-review H2

The mockup's "Alarm Notifications" toggle is the most dangerous control on the
screen. If it maps to the OS notification permission, turning it off stops
every alarm from ringing — silently, from a screen that gives no indication it
just disabled the product's one job. `CLAUDE.md` calls locking a user out of
their own alarm a High finding; this is the same defect one step earlier.

Shipped instead: a **status row**, not a switch. It reads the live
`PermissionState`, says plainly whether alarm notifications are allowed, and
its action opens the reliability checklist (or the OS settings when
permanently denied). It can grant, never revoke — revoking stays in the OS,
where the consequence is stated by the OS.

The group keeps its mockup position and header band. Its row is one row, not
two, and the deviation is in §8.

## 5. Why the walkthrough row is not a dead row

`CLAUDE.md` forbids a row that opens nothing, and Phase 09 owns onboarding.
The row therefore opens a **real screen that exists in this phase**: a
replayable summary of what the first run covers, built from
`OnboardingStatus` (`lib/core/onboarding/`), with a plain statement of what is
and is not yet configurable. It is honest and it is reachable; Phase 09
replaces its body with the real flow and keeps the route.

If that screen cannot be made genuinely useful in this phase, the row is cut
and the exclusion stated — **a cut row is an acceptable outcome, a dead row is
not.**

## 6. The sleep-boundary restoration — explicitly not discharged

`package:health` and `live_sleep_gateway.dart` **do not land in this phase.**
Settings has no sleep row in the mockup, and the Stats screen that consumes
sleep data is Phase 08.

So `test/core/sleep/sleep_boundary_test.dart` **stays at `at most one`
importer** and keeps the negative invariant for `NSHealthShareUsageDescription`
and `READ_SLEEP`. The obligation moves to Phase 08's tracker row, stated rather
than silently dropped (`PHASE_02_SELF_REVIEW_1.md` F5 is the origin).

## 7. Files

### New — `lib/features/settings/`
- `settings_screen.dart` (replaces the Phase 01 placeholder)
- `settings_group.dart` — the group card: header band + rows + dividers
- `settings_rows.dart` — value row, chevron row, status row, toggle row
- `theme_tile_row.dart` — the three-tile inline theme selector
- `sound_picker_sheet.dart`, `snooze_picker_sheet.dart`
- `about_sheet.dart`
- `reliability_checklist_screen.dart`
- `walkthrough_screen.dart`
- `settings_controller.dart` — persists through `CapyWakeRepository`

### New — `lib/design/`
- `settings_toggle.dart` ⟲ or a size parameter on `CapyToggle` — see §9

### Modified
- `lib/app/router.dart` — three sub-routes under `/settings`
- `lib/features/alarms/alarms_screen.dart`, `…/edit/alarm_edit_screen.dart` — gate
- `integration_test/capture_test.dart` — a `settings` case
- `tool/compare.dart` — the `settings` block table and its inset
- `docs/visual/tier_a_blocks.md` — §1 appended

### ARB
Most keys exist (35 `settings*` keys are already in all 10 locales). New keys
are expected for the checklist entry rows, the notification status row and the
About sheet. **Registered estimate: 12–22 new keys** (§10).

## 8. Tier A — what is claimed and what is not

**Claimed** (binding, ±4 pt):

| Block | Ref (pt) |
|---|---|
| Header band lower edge | 103.9 |
| Hero art lower edge | 212.9 |
| Group 1 card top / bottom | 231.4 / 341.8 |
| Group 2 card top | 355.6 |
| Meadow footer top | 770.3 |
| Gutter / card width | 9.70 / 373.6 |

**Not claimed, with the reason stated in `docs/visual/settings/`:**

- **Group 2 bottom and everything below it.** The App Icon row is cut, so
  Appearance is one row shorter than the mockup's; Notifications is one row
  instead of two; Account loses two of three rows; a fifth group is added that
  the mockup does not draw. Those positions are consequences of §4, not of
  layout error, and claiming them would be claiming a match that cannot exist.
- The screen is **scrollable**, so blocks below the fold depend on scroll
  offset; the capture is taken at offset 0.

## 9. ⟲ The toggle, after pre-review M1 — a third size for the same control

| Screen | Toggle | Method |
|---|---|---|
| Home (`CapyToggle`) | 59.6 × 34.6 | Phase 01 |
| Alarms | 54.0 × 22.6 green anchor (`tier_a_blocks.md` records 30.5 tall from a different measurement) | Phase 04 |
| **Settings** | **44.3 × 25.0** | §1.4 |

This is the `SceneHeader.bandHeight` pattern in a new component, and it is the
**fourth** time a shared default has stood in for a per-screen measurement.
`CapyToggle` is a hard-coded 59.6 × 34.6 with no size parameter.

⟲ **Decision (pre-review H1/M1): parameterise, do not fork.** `CapyToggle` takes
a **required `trackSize`**, which makes every existing call site state its own —
the same move that made `bandHeight` required and immediately exposed Stats
carrying Home's number. The tap target stays ≥44 pt regardless of track size
(`CapyToggle.minTapTarget`), so shrinking the track never shrinks the target.

⟲ **M1 — the cost, stated.** Eight call sites must each supply a number, and
two of them (Add/Edit's toggles, `alarm_form_rows.dart:114`) have no measured
value anywhere. Those pass `CapyToggle.homeTrackSize`, **named as an
inheritance, not a measurement**, and listed in the post-review as an open
measurement — the treatment Phase 04 gave Stats, which is how Stats' inherited
band was eventually found.

⟲ **H1 — the contradiction to settle.** `tier_a_blocks.md` records the Alarms
toggle as "30.5 pt tall"; this phase's green-anchor method reads **22.6** on the
same mockup. One is wrong. It is re-measured here and `tier_a_blocks.md`
corrected in place — a phase that notices a contradiction and leaves it is the
behaviour this project keeps finding.

## 10. Registered predictions — restate on measurement, never pass quietly

⟲ **M4: the test band is decomposed, so a miss is attributable to a component
rather than to a range wide enough to be right.**

| Component | Tests |
|---|---|
| Row types (value / chevron / status / toggle) | ~8 × 4 = 32 |
| Reliability checklist (platforms × states × actions) | ~12 |
| Permission gate, incl. the mutation test | ~10 |
| Row-set integrity (the §4 cuts, enforced) | ~8 |
| RTL + 2× text scale | ~6 |
| Ringing over a pushed Settings | ~6 |
| Sheets (sound, snooze, about) | ~10 |
| Controller / persistence | ~12 |
| **Sum** | **~96, band 70 – 100** |

| | Registered |
|---|---|
| New tests | **70 – 100** |
| Total tests | 1,442 – 1,472 (from 1,372) |
| New ARB keys | **12 – 22** (405 → 417–427) |
| `lib` coverage | 97.0 – 97.8 % (from 97.63 %) |
| `lib/core` | **99.49 %, unchanged** — this phase adds no `lib/core` code |
| `lib/data` | 88.5 – 89.5 % (from 88.95 %) |
| New `lib/features/settings` coverage | ≥ 90 % |
| Files hitting the comment budget | all new files; **0 baselined** |

A prediction made before the reviews cannot account for the reviews (Phase 06).
Any disagreement is restated with its reason.

## 11. Tests

- **Golden-free widget tests** per group, per row type, per sheet.
- **Row-set integrity**: a test asserting the shipped screen contains **no**
  Backup & Sync, Restore Purchases, App Icon or Daily Reminder row — the §4
  decision, enforced rather than remembered.
- **No dead taps**: every row with a chevron resolves to a route or sheet that
  opens. Asserted by walking the rows, not by a hand-written list.
- **Permission gate**: fires on the first enable transition, not on the second
  alarm, not on app start, not on disable.
- **Gate mutation test** (Phase 06's rule): disabling the gate must fail a
  test. If removing the call leaves the suite green, the test is on trust.
- **Reliability checklist**: per platform, per permission state, action kinds.
- **Reliability honesty**: no user-facing string in `lib/features/settings/`
  claims the alarm will ring; every reliability sentence comes from
  `ReliabilityCopyService`.
- ⟲ **M5 — Ringing over a pushed Settings** (Phase 06's sharpest edge): with
  Settings pushed on the **root** navigator, a ring must cover it **and the
  escape sheet must open**. Both halves: Phase 06's bug passed every test that
  checked only the first.
- ⟲ **L7 — pop order**: each sub-route pops to Settings; Settings pops to the
  tab it was opened from. Asserted, because `go_router` nesting is where this
  breaks silently.
- **RTL**: Arabic, direction-aware only.
- **2× text scale**: no overflow on any row.
- ⟲ **L8** — the capture is taken at **scroll offset 0**; the content exceeds
  the viewport, so blocks below the fold are offset-dependent (§8).
- ⟲ **M6** — the capture runs **before** the final review passes, not after, so
  a `compare.dart` / `inset.txt` gap surfaces with time to fix it.
- Tier A capture + `tool/compare.dart settings 04_SETTINGS`.

## 12. Validation

The block in `CLAUDE.md`, unchanged.

## 13. Risks

| Risk | Mitigation |
|---|---|
| The §4 cuts make the screen look unlike the mockup | Declared in §8 and in `docs/visual/settings/`; the rule is `CLAUDE.md`'s and the owner's |
| Making `CapyToggle.trackSize` required breaks call sites | That is the point — it did for `bandHeight`. Each site states its measurement. |
| The walkthrough screen is thin | §5: cut the row rather than ship a dead one |
| Permission prompt fires in tests | `FakePermissionService` is the default in the provider graph |

## 14. Rollback

Every change is additive except the `settings_screen.dart` placeholder and the
`CapyToggle` signature. `git revert` of the phase commit restores Phase 06.

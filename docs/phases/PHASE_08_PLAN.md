# Phase 08 — Stats

Build the Stats tab against `reference/01_REFERENCES/screens/primary/05_STATS.png`,
write the no-fake-numbers gate that `CLAUDE.md` has claimed since Phase 00, and
measure Stats' own hero band and meadow instead of carrying Home's.

> **Revised after `PHASE_08_PRE_REVIEW.md`** — 11 findings, all applied. The
> revisions are marked **[PR: Hn/Mn/Ln]** at the point they change the plan.
> The largest are the claimed-block set (13 → 5), the Sleep segment's copy, and
> the provider shape that keeps `HistorySummary.empty`'s zeros off the screen.

## Objective

Three deliverables, in dependency order:

1. **The gate first.** `tool/check_no_fake_stats.dart` exists before the screen
   does, so the screen is written under it rather than retro-fitted to it.
2. **The Stats screen**, whose default state is empty, reading `HistoryService`
   through a provider that does not exist yet.
3. **Stats' own Tier A constants** — hero band, meadow, card positions — and a
   `screenBlocks['stats']` entry so `compare.dart` will run at all.

## The mockup is a filled state and the default is empty

`05_STATS.png` draws a user with weeks of data: `7 h 32 m` average sleep,
`+18 min vs. last week`, a seven-bar chart labelled 7:20…7:34, a `6 days`
streak with `Best: 14 days`, an `8 h` goal at `Avg. 94%`, `10:28 PM` /
`7:00 AM` averages and `52 h 44 m` this week.

**Every one of those numbers is fabricated.** `CLAUDE.md` is explicit that on
this screen the empty state is the *default*, not a fallback, and that no
numeric literal may sit in a user-facing position in `lib/features/stats/`.
A fresh install has no occurrences and no sleep nights, so the screen a new
user sees is the empty one.

This forces a decision the other four screens did not face: **Tier A is
measured against a layout the default state does not render.** Resolved in
§"Tier A — which blocks are claimed" below.

## Scope

### In

- `tool/check_no_fake_stats.dart` + its test, mutation-verified.
- A `historySummaryProvider` folding `allOccurrencesStreamProvider`,
  `alarmsStreamProvider` and a clock into `HistoryService.summarise`.
- `statsClockProvider`, matching the three existing screen clock providers.
- `StatsScreen` body: segment switcher, the four card groups, empty state.
- A bar-chart primitive (none exists) and a stat-tile widget (none exists).
- Stats' measured constants with their mockup arithmetic.
- `screenBlocks['stats']` in `tool/compare.dart`.
- `docs/visual/tier_a_blocks.md` § Blocks — Stats; `docs/visual/stats/README.md`.
- A fresh capture — the committed `docs/visual/stats/actual.png` is **Phase
  03's** (`b3b0574`), a picture of the empty stub.

### Out, and said plainly

- **`package:health` and `live_sleep_gateway.dart` do not land in this phase.**
  See §"The sleep boundary" — this is a decision, not an omission.
- Alarms' three failing Tier A blocks and Add/Edit's eight. Recorded by Phase
  07 as owed by the screens that own them; this phase does not touch them.
- `AlarmEngine.ringNow` and the motion layer. No phase row.

## The sleep boundary — stated, not left ambiguous

**The health read path does not land in Phase 08.** `pubspec.yaml` has no
`health` dependency, `lib/data/providers.dart:80-85` records that
`sleepGatewayProvider` and `sleepSyncServiceProvider` do not exist, and
nothing in `lib/` imports a health plugin.

So `test/core/sleep/sleep_boundary_test.dart` **stays at `at most one`
importer** with its conditional `NSHealthShareUsageDescription` / `READ_SLEEP`
assertions. The restoration owed by `PHASE_02_SELF_REVIEW_1.md` F5 is **not
discharged here** and carries forward.

**Why not now.** Adding `package:health` means a platform permission flow, an
iOS entitlement, an Android manifest permission and a store-policy surface
(health data is a declarable category on both stores), none of which is this
phase's subject and all of which need their own pre-review. Pulling it in to
tick an owed item would be the drive-by change this process exists to prevent.

**What this costs the screen.** The mockup's Sleep segment is the one with the
richest art and the most numbers, and with no gateway the sleep cache is
permanently empty, so the Sleep segment renders its empty state always.

**[PR: H1] The existing `sleepHistoryEmpty` may not be used for it.** It reads
*"No sleep to show yet. **Connect Health** to see your nights here."* and
`grep -rn "sleepSettingsEntry\|sleepEnableAction" lib/features/` returns
nothing — there is no Connect control anywhere in the app. Shipping that
string to 10 locales tells every user to press something that does not exist:
Phase 07's dead-control defect, and `CLAUDE.md`'s overpromising rule.

A **new key** states the fact without the instruction; `sleepHistoryEmpty` is
left untouched for the phase that lands the gateway, rather than reworded in
10 locales and reworded back later. It stays in the ARB unused —
`check_arb.dart` checks cross-locale completeness, not usage — and is recorded
in the post-review as knowingly unused so it is not later found as a mystery.

## Copy — reuse `history*`, do not mint `stats*`

There are **zero** `stats*` ARB keys, 22 `history*` keys and 30 `sleep*` keys,
all present in 10 locales and all written in the project's voice. The nav tab
is `navStatsLabel = "Stats"` while the screen copy namespace is `history*`
with `historyTitle = "History"`.

**Decision: reuse the `history*` namespace for alarm statistics and `sleep*`
for sleep.** New keys are added only where the mockup needs copy that has no
existing key — the segment labels, the screen title, the sleep-segment
summary rows. Minting a parallel `stats*` set would duplicate 22 strings
across 10 locales for a rename nobody asked for.

The screen's visible title follows the mockup: **"Statistics"**, a new key.
`historyTitle` ("History") stays for the Alarms segment's own heading.

## Tier A — which blocks are claimed, declared before capture

Per `CLAUDE.md` and Phase 07's precedent, the blocks are declared **before**
the capture so the phase cannot pick the ones it passes.

### Measured from `05_STATS.png` — all thirteen

| Block | pt | Method | Claimed? |
|---|---|---|---|
| Header band lower edge | 103.9 | **Inherited** — same `CapyHeader` on all three tabs. Not independently derived | **yes** |
| Hero art lower edge | **215.4** | Cream-sheet top at the screen edges, arc asymptote: left flat 214.3 (x≥44), right flat 216.6 (x 348–358); mean. **Not** the green-collapse method — see below | **yes** |
| Segment track top | 249.4 | Orange-pill bounding box, hue 0.045–0.11 ∧ sat>0.55, verified at the pill's centre column (not a cap slice) | **yes** |
| Segment track bottom | 280.3 | same | **yes** |
| Card 1 top | 295.6 | Left-card-edge trace, x 10–26 pt, L<240 ∧ sat<0.35 (rejects the meadow's green) | **yes** |
| Card 1 bottom | 403.6 | same; crop-verified | no |
| Card 2 top | 413.3 | same; crop-verified | no |
| Card 2 bottom | 556.5 | same | no |
| Card 3 top | 565.7 | same | no |
| Card 3 bottom | 649.8 | same | no |
| Card 4 top | 659.5 | same | no |
| Card 4 bottom | 736.1 | same | no |
| Meadow footer bottom | 773.1 | Green hue 0.16–0.45 ∧ sat>0.25 ∧ L>60, **mode across 40 columns** (28/40 agree). The top is scalloped (744–764) and is *not* a block | **yes** |

### [PR: H4, M1] Why eight of the thirteen are not claimed

The first draft of this plan claimed all thirteen while also specifying a
default state that **cannot render eight of them**. The mockup's card 1 is
108.1 pt because it holds a 44 pt numeral and an illustration; card 2 is a
143.2 pt chart. An empty card holding a heading and an em dash is shorter, so
every card bottom — and therefore every subsequent card top — sits above the
mockup's mark **by construction**.

Claiming a block the phase has designed itself not to reach is declaring a
block in order to fail it. The five claimed are those the default state can
legitimately be held to: the two structural edges, the segment track (which
renders identically in every state), card 1's top (set by the gap under the
switcher, not by content), and the meadow (pinned to the screen bottom).

**The eight unclaimed keep their measured values in `tier_a_blocks.md`** with
the reason recorded, so the phase that builds the filled state inherits the
measurements instead of re-deriving them. This is a smaller claimed set than
Phase 07's, and the reason is written down rather than the set being quietly
trimmed — which is the Phase 07 H1 defect this is avoiding.

### Derived

| Quantity | Arithmetic |
|---|---|
| Hero band height | 215.4 − 103.9 = **111.5** — a fifth distinct value |
| Meadow height | 853 − 773.1 = **79.9** — a sixth distinct value |
| Card gaps | 9.7 / 9.2 / 9.7 — consistent, ≈ `CapySpacing.sm` + 1.7 |

### The green-collapse method does not work on this screen

Phase 04 and Phase 07 located the hero's lower edge by a per-row green-pixel
count that collapses sharply where art meets cream (Alarms 67→58, Settings
53→30). Re-implemented and **validated against both**: it reproduces Settings
at 213.1 (documented 212.9, Δ0.2) and Alarms at 252.4 (documented 252.5,
Δ0.1).

**On Stats it produces nothing.** The profile decays monotonically from 302 to
0 across 188→238 pt with no knee; the largest relative drop is 6→4 on the
noise tail at 227.4. The reason is visible in a crop: **Stats' cream shape is
a scalloped cloud with lobes, not a rounded rectangle**, so the boundary is
not a line and a row-count cannot find one.

This is the Phase 03 rule in a new form — *a boundary adjacent to a textured
region must be read off a crop* — and the arc-asymptote method above is the
replacement, cross-checked at both screen edges independently (214.3 vs 216.6,
2.3 pt apart).

### A structural mismatch this measurement exposes

`SceneHeader` draws the cream card as `BorderRadius.vertical(top: 28)`. The
mockup draws a cloud with lobes rising ~65 pt above the sheet's flat top, on
**all five screens**. The flat-top measurement is the right number for
`bandHeight`, and the cloud is Tier B illustration, but the mismatch is real
and belongs in `asset_gaps.md` rather than being silently absorbed.

### Intra-card geometry — not claimed either

The mockup's within-card rows — the `7 h 32 m` baseline, the chart's gridlines
and bars, the three bottom tiles' internal positions — are **not claimed**,
because the default state does not render them. That is 100% of the mockup's
intra-card geometry, named here so the omission is declared, not discovered.

## What the empty state renders

**[PR: H4] The cards do not collapse.** The default state renders all four
card envelopes with their headings and icons, value regions showing the empty
token:

- The segment switcher, always (three segments are navigable with no data).
- Each card present with its heading and icon, its value region showing the
  empty token rather than a number.
- One empty-state block under the cards carrying `historyEmptyTitle` /
  `historyEmptyBody`, which already exist and explain the dashes in words.

Collapsing to a single paragraph where the mockup draws four cards would be a
far larger Tier A deviation than four em dashes, and would leave the screen
unmeasurable. Keeping the envelopes also shows a new user what the app will
show them, which is the honest version of an empty state.

## The gate — `tool/check_no_fake_stats.dart`

### What it must catch

A numeric literal reaching a user-visible position in `lib/features/stats/`.

### What it can actually catch, and what it cannot

**Can:** a numeric literal passed to `Text(...)`, interpolated into a string
literal (`'$7'`, `'7 h'`), or passed as a named `value:`/`label:` argument to
a widget constructor; a hardcoded duration or percentage string
(`'7 h 32 m'`, `'94%'`).

**Cannot, and this is the one that would ship:**

- A number arriving through a provider default — `HistorySummary.empty` has
  `averageSnoozeCount: 0` and a gate cannot distinguish a legitimate zero from
  a fabricated one.
- A `??` fallback supplying a literal when real data is absent
  (`summary.typicalWakeMinutes ?? 450`). This is *exactly* the shape
  `CLAUDE.md` warns about, and a syntactic gate sees only an int in an
  expression.
- A number computed from a constant (`7 * 60 + 32`).
- A number in a widget the Stats screen imports from `lib/design/`.

**So the gate is backed by a second mechanism**: the `??`-fallback case is
covered by a test asserting the screen renders no digits at all when every
provider is empty. A gate that catches the easy case plus a test that catches
the shipping case; the pre-review will attack both.

### [PR: H3] Mutation requirement — three numbers, not one

Deleting a *script* makes its test fail to **run**, not fail an assertion.
That is a trivially passing mutation and proves nothing — the "guard on trust"
Phase 06 named. The meaningful mutations are:

1. **Plant a violation.** The gate's test runs it against fixture files with
   known violations and asserts a non-zero exit naming the offending line. A
   gate that returns "clean" for a planted `Text('7 h 32 m')` fails its test.
2. **Neuter the matcher** (make it return no hits) and record how many tests
   fail. If that is 1, the gate is protected by exactly its own test and
   nothing else — honest, and recorded as such.
3. **Plant a literal in the real screen** and confirm the *widget* test fails
   on its own, not because the script also flagged it. This is the mutation
   that protects shipping code.

All three numbers are reported separately. Phase 07's lesson was that one
aggregate "it failed" hides which rule did the work.

## [PR: M2, M3] The provider shape — three states, no borrowed zeros

`HistorySummary.empty` has `averageSnoozeCount: 0`, `occurrenceCount: 0` and
so on. Handing it to a tile renders **`0`** — a real digit in a value slot,
stating a measured average the user has never produced. **No gate in this
phase can see that**: there is no literal in the source.

So the provider does not hand widgets a `HistorySummary.empty` whose zeros are
indistinguishable from measured zeros. It exposes **three explicit states** the
widgets switch on:

| State | Condition | Renders |
|---|---|---|
| loading | the stream has not produced | card envelopes, no values, **no** empty-state copy — so the screen never flashes a false "nothing here" |
| empty | `occurrenceCount == 0` **within the requested window** | card envelopes with the empty token, plus the empty-state block |
| summarised | otherwise | the measured values |

A tile is given a value only when one exists; the type does not permit
handing it a number that is not there.

**Why `occurrenceCount == 0` and not `occurrences.isEmpty`:** a non-empty list
can be entirely `skipped` rows, which is a genuine summary with zero
wake-ups; and data may exist outside the window the user asked about. The
window the user picked is what the empty question is about.

## [PR: M4] The Games segment has no data and may not acquire any

Nothing records game results — no occurrence type, no table, no service. The
Phase 06 ringing puzzle records nothing scoreable, and `CLAUDE.md` forbids
"scores, streaks or personal bests on the puzzle".

The Games segment renders a **stated-empty** surface saying game activity is
not recorded — not a "coming soon" tease, not a fabricated count. This matches
Home's `comingSoon` precedent and respects the no-scores rule.

**Flagged for the owner, not resolved here:** the mockup's Games segment, if
ever filled, would likely show exactly the scores and streaks the safety rules
forbid. Recorded in the post-review as a `CLAUDE.md` tension.

## [PR: M5] The default window is 14, and the mockup's "Last 7 Days" is not matched

`HistoryService.defaultWindowDays` is 14; the mockup's selector reads **"Last
7 Days"**, a value the service does not name. The screen defaults to **14** and
renders `historyWindowLabel` with the window it actually queries.

**A declared deviation from the mockup's visible label, with its reason:** the
mockup's 7 is one of its fabricated numbers, and showing a label while
querying a different window would be precisely the lie this phase exists to
prevent. 7 is offered as a selectable window alongside 14 and 90, so the
mockup's state is reachable — the user chooses it, the app does not fake it.

## Files

### New

```
tool/check_no_fake_stats.dart
test/style/check_no_fake_stats_test.dart      [PR: L2] test/tool/ does not exist
lib/features/stats/stats_providers.dart
lib/features/stats/stats_segment_switcher.dart
lib/features/stats/stats_empty_state.dart
lib/features/stats/sleep_segment.dart
lib/features/stats/alarms_segment.dart
lib/features/stats/games_segment.dart
lib/features/stats/stat_tile.dart
lib/features/stats/duration_bar_chart.dart
test/features/stats/*            (one per widget + a providers test)
docs/visual/stats/README.md
```

### Modified

```
lib/features/stats/stats_screen.dart      body, measured constants
lib/l10n/app_*.arb                        × 10
tool/compare.dart                         screenBlocks['stats']
docs/visual/tier_a_blocks.md              § Blocks — Stats
docs/visual/asset_gaps.md                 the cloud/radius mismatch, art gaps
docs/visual/stats/actual.png              regenerated — current one is Phase 03's
```

## Registered expectations

Restated if measurement disagrees, with the reason, per Phase 07's precedent.

| Quantity | Baseline | Expected after |
|---|---|---|
| Tests | 1,452 | **+70 … +100** |
| ARB keys | 427 | **+10 … +18** (segment labels, title, sleep/goal rows) |
| `lib` coverage | 97.80% | **97.3 – 97.9%** |
| `lib/core` | 99.61% | **unchanged** — but this phase is the first *caller* of `HistoryService`, and Phase 07 saw exactly that raise core. A rise is plausible; it will be restated with the reason, not passed silently |
| `lib/data` | 88.95% | **unchanged or +0.3** (one new provider file touched) |
| `lib/features/stats` | n/a | **≥ 95%** |
| Comment-budget baseline | 113 files | **113** — zero new files baselined |
| Stale `Phase N` dartdocs in `lib/` | 1 | **0** — the survivor is `stats_screen.dart`'s, and this phase removes it |

## Tests

- `check_no_fake_stats` against fixtures: a clean file, a `Text(7)`, an
  interpolated literal, a hardcoded `'94%'`, and a `??` fallback **asserted as
  NOT caught**, so the gate's blind spot is documented in executable form.
- The gate's three mutation counts (H3).
- Provider: empty occurrences → the empty state; seeded occurrences → the
  summarised values; loading → neither; the clock is pinned.
- **[PR: H2]** Widget: every value-bearing slot — each `StatTile`'s value and
  each chart label — renders the empty token in the default state. **Not** "no
  digit anywhere in the tree": `historyWindowLabel` legitimately renders
  "Last 14 days", a digit describing the query rather than the data, and an
  over-broad assertion is one that gets weakened to nothing the first time it
  is inconvenient.
- Widget: each segment switches and keeps the card envelopes.
- Golden/semantics: RTL under `ar`, text scaling, `disableAnimations`.
- The art audit and manifest tests cover any new asset.

## Acceptance

1. The gate exists, is wired into validation, and its **three** mutation
   counts are named.
2. Every value-bearing slot renders the empty token in the default state —
   asserted, not asserted-by-eye.
3. `dart run tool/compare.dart stats 05_STATS` runs (it currently `exit(2)`s)
   against a **fresh** capture, and **every** claimed block is reported —
   those that fail named with their deltas, not only those that pass.
   **[PR: L1]** The post-review records the capture's mtime and `git log` line
   proving it was regenerated: the committed `actual.png` is Phase 03's
   (`b3b0574`), a picture of the empty stub, and `compare.dart` reads whatever
   is on disk without checking its age.
4. Stats' `bandHeight` and `MeadowFooter.height` are its own measured values.
5. The sleep-boundary decision is stated explicitly in the tracker and `next.md`.
6. Full validation block green, analyze clean including infos, 10 locales.

## Risks

| Risk | Mitigation |
|---|---|
| The empty default makes most of the mockup unmeasurable | Blocks declared above *before* capture; intra-card geometry explicitly not claimed |
| `sleepHistoryEmpty` promises a Connect control that does not exist | Pre-review decides; a reworded key is cheaper than a dead affordance |
| A chart primitive is new surface with no precedent | It renders nothing in the default state, so its first shipped state is the empty one |
| The gate gives false confidence | Blind spots enumerated above and asserted in tests |
| Four "—" cards read as broken | Pre-review decides the collapse rule |

## Rollback

Every change is additive except `stats_screen.dart` and the three doc files.
`git revert` of the phase commit restores the stub.

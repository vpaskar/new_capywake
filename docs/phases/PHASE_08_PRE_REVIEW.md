# Phase 08 — pre-review

Adversarial pass over `PHASE_08_PLAN.md`, **before any code**. Every finding is
applied or marked invalid with a one-line reason. "Deferred" is not an outcome.

**11 findings: 4 High, 5 Medium, 2 Low.**

---

## High

### H1 — The plan ships copy pointing at a control that does not exist

`sleepHistoryEmpty` reads, in all 10 locales:

> "No sleep to show yet. **Connect Health** to see your nights here."

The plan's §"The sleep boundary" decides `package:health` does not land, and
`grep -rn "sleepSettingsEntry\|sleepEnableAction" lib/features/` returns
**nothing** — Settings has no sleep row, no Connect button, no route to one.

So the Sleep segment would render, permanently and to every user, an
instruction to press something that is not in the app.

**This is Phase 07's finding #1 in a new place.** That phase rejected the
mockup's Alarm Notifications toggle because "mapped to nothing, it is a dead
control, worse than a dead row because it moves". A dead *instruction* is the
same defect: it tells the user the app can do something it cannot, which is
also the `CLAUDE.md` overpromising rule ("no implied … bypass", "never claim
more … than the OS clock app").

It is worse than a dead row in one respect: the user will go looking in
Settings, find nothing, and conclude the app is broken.

**Applied.** The Sleep segment's empty copy must not promise a Connect
affordance while none exists. Two options were weighed:

- Reword `sleepHistoryEmpty` in 10 locales. Rejected: the key is correct for
  the world where the gateway exists, and rewording it now means rewording it
  back later — churn across 10 locales in both directions.
- **Chosen:** add a new key for the pre-gateway state, and leave
  `sleepHistoryEmpty` untouched for the phase that lands the gateway. The new
  copy states the fact without an instruction: sleep is not available yet.

The new key is named for the condition, not the phase. `sleepHistoryEmpty`
stays in the ARB unused — `check_arb.dart` checks completeness across locales,
not usage, so an unused key is not a gate failure, and deleting a correct
string that a near-future phase needs would be the churn this finding avoids.
**Recorded in the post-review as a known-unused key**, so it is not discovered
later as a mystery.

### H2 — "No digit anywhere in the text tree" is the wrong assertion and will be false

The plan's acceptance criterion 2 and its test both say the default state
renders **no digit**. That cannot hold:

- The segment switcher renders no digits, fine.
- But the mockup's window selector reads **"Last 7 Days"**, and
  `historyWindowLabel` is `"{days, plural, =1{Last day} other{Last {days} days}}"`
  — a legitimate digit, in a user-facing position, that is *not* a fabricated
  statistic. It describes the query, not the data.
- Localized empty strings in other locales may contain digits for unrelated
  reasons.

A test that asserts "no digit" will either fail immediately or force the
window label out of the screen, which would be the test dictating the design.

**Applied.** The assertion is narrowed to what the rule actually protects:
**no digit inside a value-bearing position**. Concretely, the test walks the
rendered tree and asserts that every `Text` under a `StatTile`'s value slot,
and every chart label, is the empty token — rather than asserting over the
whole subtree. The window label sits outside those slots by construction.

This is a better test than the plan's: "no digits at all" is the kind of
over-broad assertion that gets weakened to nothing the first time it is
inconvenient, and a weakened guard is Phase 06's defect.

### H3 — The gate as specified cannot be mutation-tested meaningfully

The plan commits to "N tests fail when the gate is deleted". But the gate is a
**script**, not a runtime guard: deleting `tool/check_no_fake_stats.dart`
makes its test fail to *run*, not fail an assertion. That is a trivially
passing mutation and proves nothing — precisely the "guard on trust" Phase 06
named.

The meaningful mutation is the opposite direction: **plant a violation and
confirm the gate catches it.** And the Phase 07 sharpening applies — if the
gate is removed, which tests fail, and could a *different* rule be covering?

**Applied.** The mutation protocol is specified concretely:

1. The gate's own test runs it against **fixture files** carrying known
   violations, asserting a non-zero exit and the offending line. A gate that
   returns "clean" for a planted `Text('7 h 32 m')` fails its test.
2. Separately, **neuter the gate's detection** (make its matcher return no
   hits) and record how many tests fail. If that number is 1, the gate is
   protected by exactly its own test and nothing else — which is honest, and
   is what gets recorded.
3. The **widget** assertion from H2 is mutated independently by planting a
   literal in the real screen and confirming the widget test fails. This is
   the one that protects shipping code, and it must fail on its own, not
   because the script also flagged it.

Reporting all three numbers separately is the point: Phase 07's lesson was
that one aggregate "it failed" hides which rule did the work.

### H4 — Four card envelopes are claimed on a state that may not render four cards

The plan claims card 1–4 tops and bottoms as Tier A blocks, then says in
§"What the empty state renders" that the pre-review must decide whether the
cards "collapse to the empty block when every source is empty".

**These two cannot both be open.** If the cards collapse, eight of the thirteen
claimed blocks do not exist in the shipped default state and `compare.dart`
will report them `absent` — which Phase 07 established still counts as a
failure. The phase would then have declared blocks it designed itself not to
render.

**Applied, and the decision is made here rather than left to implementation:**
**the cards do not collapse.** The default state renders all four card
envelopes with their headings and icons, value regions showing the empty
token. Reasons:

- It keeps the screen's structure legible on first launch — the user sees what
  the app will show them, which is the honest version of an empty state.
- It keeps Tier A measurable, which is the whole fidelity contract.
- It avoids a first-launch screen that is one paragraph of text where the
  mockup is four cards — a far larger Tier A deviation than four "—" values.

The plan's own risk ("four — cards read as broken") is mitigated by the single
empty-state block beneath them carrying `historyEmptyTitle`/`historyEmptyBody`,
which explains the dashes in words.

**Consequence recorded:** card *bottoms* depend on content height. An empty
card is shorter than the mockup's filled card. **So card bottoms will fail
Tier A, by construction, and that is declared now rather than discovered at
capture.** See M1.

---

## Medium

### M1 — The plan claims blocks it has already reasoned itself out of passing

Following H4: card 1's mockup envelope is 295.6 → 403.6, **108.1 pt tall**,
because it holds a 44 pt numeral, a trend line and an illustration. An empty
card holding a heading and an em dash is perhaps 70 pt. Cards 2–4 are worse —
card 2 is a 143.2 pt chart.

Claiming "card 1 bottom 403.6" and then shipping a state that cannot reach it
is declaring a block in order to fail it.

**Applied.** The claimed set is revised to what the default state can
legitimately be held to:

| Claimed | Why |
|---|---|
| Header band lower edge | Structural, inherited |
| Hero art lower edge | Structural |
| Segment track top / bottom | Renders identically in every state |
| Card 1 top | The first card's top is set by the gap under the switcher, not by content |
| Meadow footer bottom | Structural, pinned to the screen bottom |

**Not claimed, with the reason stated in `tier_a_blocks.md`:** all four card
bottoms and cards 2–4 tops, because each depends on the preceding card's
content height, and the default state's content is deliberately not the
mockup's.

This is a smaller claimed set than Phase 07's and the reason is recorded
rather than the set being quietly trimmed. **The mockup's own values for the
unclaimed blocks are still written into `tier_a_blocks.md`** so the phase that
builds the filled state inherits the measurements instead of re-deriving them.

### M2 — `HistorySummary.empty` has `averageSnoozeCount: 0` and the gate will not see it

`HistorySummary.empty` is documented as "used while the data is loading". If
the screen binds a tile to `summary.averageSnoozeCount` and the summary is
`empty`, the tile renders **`0`** — a real digit, in a value slot, that is a
fabricated statistic (the user has not averaged zero snoozes; they have no
data at all).

The plan's gate cannot catch this: there is no literal in the source. H2's
widget test *would* catch it only if "empty token" is asserted rather than
"not a fabricated number".

**Applied.** The screen must distinguish **no data** from **a zero result**,
and it must do so in the type system rather than by convention: the provider
exposes an explicit empty case the widgets switch on, instead of handing
widgets a `HistorySummary.empty` whose zeros are indistinguishable from
measured zeros. A tile is given a value only when there is one.

This is the single most likely way this screen ships a lie, and it is a
provider-shape decision, which is why it belongs in the pre-review and not in
implementation.

### M3 — `occurrenceCount == 0` is not the same as "no data"

Following M2: what *is* the empty condition? Candidates:

- `occurrences.isEmpty` — but an occurrence list can be non-empty with every
  row `skipped`, giving a genuine summary with zero wake-ups.
- `summary.occurrenceCount == 0` — within the window; data may exist outside it.
- The stream still loading — `AsyncValue.loading`, which is neither.

Binding "show the empty state" to the wrong one produces a screen that flashes
empty then fills, or claims no data while 90 days sit in the database.

**Applied.** Three states are modelled explicitly — loading, empty, summarised
— and the empty condition is **`occurrenceCount == 0` within the requested
window**, which is what the user is asking about when they pick a window. The
loading state renders the card envelopes with no values and no empty-state
copy, so the screen does not flash a false "nothing here" before data arrives.

### M4 — The Games segment has no data source at all

The mockup draws three segments: Sleep, Alarms, Games. The plan lists
`games_segment.dart` in its file set but never says what it shows.

`lib/core/games/` exists, but nothing records game *results* — there is no
occurrence type, no table, no service producing a games summary. The ringing
puzzle (Phase 06) records nothing scoreable, and `CLAUDE.md` forbids "scores,
streaks or personal bests on the puzzle".

So the Games segment has no data and, by project rule, **may not acquire any**
of the kind the mockup implies.

**Applied.** The Games segment renders a stated-empty surface explaining that
game activity is not recorded — not a "coming soon" tease, and not a
fabricated count. This matches Home's `comingSoon` precedent (`CLAUDE.md`: "a
`comingSoon` card is marked and opens a 'not built yet' sheet, never a dead
tap") and respects the no-scores rule.

**Flagged as a `CLAUDE.md` tension for the owner, not resolved here:** the
mockup's Games segment, if ever filled, would likely show exactly the scores
and streaks the safety rules forbid. Recorded in the post-review.

### M5 — The plan does not say which window the screen defaults to

`HistoryService.defaultWindowDays = 14`, `extendedWindowDays = 90`, and the
mockup's selector reads **"Last 7 Days"** — a third value that the service
does not name.

Shipping 7 to match the mockup means a magic number the gate may flag;
shipping 14 means the screen does not match the mockup's visible label.

**Applied.** The screen defaults to `HistoryService.defaultWindowDays` (14)
and the selector renders `historyWindowLabel` with that value — so the control
is honest about what it queries. **This is a declared Tier B/structural
deviation from the mockup's "Last 7 Days" label**, recorded with its reason:
the mockup's 7 is one of the fabricated numbers, and matching a label while
querying a different window would be the lie the whole phase is about.

7 is offered as a selectable window alongside 14 and 90, so the mockup's state
is reachable — the user chooses it, the app does not fake it.

---

## Low

### L1 — `docs/visual/stats/actual.png` is Phase 03's and will silently pass

The file exists, is 1179×2556, and `git log` attributes it to `b3b0574`
(Phase 03). `capture.sh` verifies an artifact is "newer than the run", but
`compare.dart` reads whatever is on disk.

If the capture step is skipped or fails quietly, `compare.dart` will compare
**Phase 03's picture of an empty stub** against the mockup and report deltas
for a screen this phase never rendered.

**Applied.** The capture is run before the final review passes (as `next.md`
already requires), and the post-review records the capture's mtime and the
`git log` line proving it was regenerated, not inherited.

### L2 — The plan's file list includes a test directory that does not exist

`test/tool/` is listed for `check_no_fake_stats_test.dart`. No `test/tool/`
exists; gate tests live in `test/style/` (`comment_budget_test.dart`).

**Applied.** The gate's test goes in `test/style/`, matching the only
precedent for "a test that runs a tool", so `flutter test` picks it up where
the other gate lives rather than establishing a second convention.

---

## Invalid

None. Every finding above changes the plan.

---

## Outcome

11 findings, all applied. The three that change the phase most:

- **H1** — the Sleep segment would have shipped an instruction to press a
  control that does not exist, in 10 locales.
- **H4 + M1** — the plan declared thirteen Tier A blocks and had already
  decided on a default state that cannot render eight of them. The claimed set
  is now five, with the unclaimed eight recorded with the mockup's values and
  the reason.
- **M2** — `HistorySummary.empty`'s zeros are indistinguishable from measured
  zeros, and the gate cannot see them. The provider shape changes so a tile
  cannot be handed a number that does not exist.

The pattern across H1, M2 and M4 is one thing: **this screen's failure mode is
not a wrong layout, it is a confident statement about data the app does not
have.** Two of the three would have passed every gate in the validation block.

# Phase 03 — adversarial pre-review

Written **before any code**, against `PHASE_03_PLAN.md`. Per the tracker:
classify every finding High / Medium / Low; **apply all, or mark invalid with a
one-line reason.** "Deferred" and "out of scope" are not outcomes.

Method: the plan's load-bearing claims were **checked by running a command**,
not read back. Three of them were false. That is the point of the exercise —
Phase 02's pre-review caught its own author being 26% out on a count, and this
one caught its author asserting a tool does something it does not.

## Summary

| # | Severity | One line | Outcome |
|---|---|---|---|
| H1 | **High** | `compare.dart` reports 4 blocks; `tier_a_blocks.md` says it reports 13 | Applied |
| H2 | **High** | The plan's acceptance criterion 5 is unsatisfiable as written | Applied |
| H3 | **High** | G12 is not a gap — the asset exists; the plan's fallback would have omitted a capybara the mockup shows | Applied |
| H4 | **High** | "Empty state is the default" is asserted for Stats, never for Home | Applied |
| M1 | Medium | Game names as ARB keys: the plan reasons to the right answer and then states the wrong total | Applied |
| M2 | Medium | Two gutters measured, one constant proposed, no tolerance argument | Applied |
| M3 | Medium | The widget-test block assertion could stand in for the capture | Applied |
| M4 | Medium | No test renders Home at 320 pt or 430 pt — and none ever has | Applied |
| M5 | Medium | The tile-label box is specified as fixed-height without measuring `de` | Applied |
| M6 | Medium | `MeadowFooter` as `CustomPaint` needs an explicit reading against the banned rule | Applied |
| L1 | Low | `todayNoAlarmTitle` assumed to exist in a usable form, not read | Applied |
| L2 | Low | The plan says "no numeric literal on Home" but the gate only greps Stats | Applied |
| L3 | Low | G13's "no asset fits" rests on one measurement | Applied |

13 findings: 4 High, 6 Medium, 3 Low. **All applied. None invalid.**

---

## H1 — `compare.dart` reports 4 blocks, not 13

**High.** The plan's §3 and acceptance criterion 5 both rest on
`tool/compare.dart` reporting the full block vocabulary. It does not.

`docs/visual/tier_a_blocks.md` states:

> `tool/compare.dart` reports **every row below for every screen**. A screen's
> phase may **add** blocks; it may never remove one.

Measured:

```
$ grep -c "^  '" tool/compare.dart
4
```

`referenceBlocks` contains exactly four entries: header band lower edge, hero
scene lower edge, card top, nav bar top. The nine others — section label, CTA
top, CTA bottom, next section top, game rail top, rail label band, meadow
footer top, and the two device insets — **are not reported by any tool.**

This is the Phase 02 pattern exactly: *a gate that is green for the wrong
reason.* Phase 01 reported "3 blocks still off because the screens have no
bodies" — and those three are among the four it actually checks. The nine
unchecked rows have never been compared on any screen, and a Phase 03 that
closed the three visible failures would have reported Tier A as met while nine
documented blocks went unmeasured.

It also makes the handoff's framing wrong: the brief says "compare.dart
currently fails Tier A on three body blocks". Of the four blocks it checks,
three fail. The brief is accurate about the tool and silent about the gap
between the tool and its own specification.

**Applied.** `compare.dart` is extended to the full vocabulary from
`tier_a_blocks.md`, plus the five blocks Phase 03 measured (§3), before Home is
judged against it. The two device-inset rows (status bar, home indicator) are
excluded with a stated reason — they are drawn by iOS, not by us, and the
comparison is already normalised to the status-bar edge. **Net: 11 reported
blocks.** The discrepancy and its fix are recorded in the post-review, and
`tier_a_blocks.md` gains a line saying which rows the tool reports so the
document and the tool cannot drift apart again.

## H2 — acceptance criterion 5 is unsatisfiable as written

**High.** Criterion 5 asks that every block land within ±4 pt "the three
previously-failing body blocks included". Two problems.

First, it inherits H1: nine of the blocks are not reported, so "every block"
cannot be evaluated.

Second, and worse: **the game rail top at 605.0 pt and the meadow footer top at
709.3 pt are determined by content height, not by a layout constant.** If the
next-alarm card renders 2 pt taller than the mockup's, every block below it
shifts. The plan commits to ±4 pt on eleven stacked blocks whose positions
compound — a 1.5 pt error in each of three boxes above the rail puts the rail
out of tolerance without any single box being wrong.

A criterion that can fail for reasons no individual decision caused is a
criterion that will be argued with after the fact, which is what the fidelity
contract exists to prevent.

**Applied.** The acceptance criterion is restated in two parts:

- **5a.** Every reported block within ±4 pt of its reference. Binding.
- **5b.** Where a block is outside tolerance, the post-review states whether
  the cause is that block's own geometry or accumulated drift from the blocks
  above it, **with the measured per-block deltas**, and fixes the originating
  box rather than padding the symptom.

Compounding is addressed structurally: the body is laid out from the **measured
block positions**, not from a stack of paddings, so each block's position is
set independently and an error in one does not propagate. Explicitly:
spacing between blocks is derived from §3's edges, and the post-review reports
each block's delta separately.

## H3 — G12 is not an asset gap, and the plan's fallback would have cost a capybara

**High.** The plan registers G12 ("the header mascot is not bundled") and sets a
fallback: if no sleeping-pose cell exists, omit the mascot.

Checked. `assets/art/mascots/` holds 31 sliced cells and **two of them are the
mockup's header mascot almost exactly** — sleeping capybara, blue nightcap with
white bobble, `Zz`, yellow duck:

| Cell | Size | Reading |
|---|---|---|
| `collection_00.webp` | 282×271 | Nightcap, `Zz`, duck, lying on a cloud/pillow |
| `moments_12.webp` | — | Same pose, slightly different framing |

They are already **bundled** (`pubspec.yaml` declares `assets/art/mascots/`)
and already **audited** (`art_manifest_test.dart` ghost-checks the whole
directory by scan). What is missing is one line in `CapyArt`.

So G12 as written is wrong in its severity and would have had a real cost: the
fallback branch omits a capybara that `01_HOME.png` shows and that
`CLAUDE.md` names explicitly — *"As many capybaras per screen as the mockup
shows. `01_HOME.png` has six."* Omitting it drops the count to five while the
asset sits in the bundle.

This also reveals a structural point worth recording: **the mascots are bundled
and ghost-audited but not catalogued**, so `art_manifest_test.dart`'s
size-check (`requiredPixels`) never runs on them. A mascot too small for its box
would ship silently. That is the same shape as Phase 02's four wrong-reason
gates.

**Applied.**
- G12 is **withdrawn as a gap** and re-filed in `asset_gaps.md` as a resolved
  note — the asset exists; the plan was wrong, not the package. Withdrawn
  findings stay visible with their reasoning, as G9 did.
- `CapyArt` gains `mascot.sleeping` pointing at the chosen cell, with the
  choice recorded by crop comparison in `docs/visual/home/`.
- The plan's H2 fallback is deleted. The mascot ships.
- A test asserts **every bundled mascot is catalogued or explicitly listed as
  unused**, so the size gate cannot be dodged by omission. ⟲ Narrowed during
  application: the catalogue declares the cells Phase 03 uses; the new test
  asserts that a catalogued mascot meets its box, and that the directory scan
  and the catalogue do not disagree about a file that exists.

## H4 — "the empty state is the default" is asserted for Stats and assumed for Home

**High.** `CLAUDE.md`'s content-integrity section binds the empty-state rule to
Stats, and `check_no_fake_stats.dart` greps `lib/features/stats/`. Home gets
one line: the game rail reads from a typed catalogue.

But Home's next-alarm card is the **first thing a user sees on a fresh
install**, and on a fresh install there is no alarm. The mockup shows `7:00 AM
/ Mon – Fri`, which is demo data. Building the card to look like the mockup is
building a card that has an alarm in it.

The plan does say the empty state uses `todayNoAlarmTitle` — but it lists the
populated branch first in its test table and describes the empty state as a
case rather than as the default. That is exactly the wording that produced the
Stats rule in the first place.

**Applied.** Stated as a binding property of this phase, not a case:

- The next-alarm card renders the **no-alarm state by default**; populated is
  the branch taken when the repository yields an alarm.
- The **first** test in `home_screen_test.dart` asserts Home against an
  **empty** repository, before any populated test exists.
- The capture for `docs/visual/home/` is taken against a **seeded** repository
  so it is comparable to the mockup, and the capture record **states that it
  was seeded and with what** — per the architecture plan's rule that demo data
  lives in tests and goldens only, never in `lib/`.
- No alarm time, weekday set or count appears as a literal in
  `lib/features/home/`.

## M1 — the ARB total contradicts the reasoning that precedes it

**Medium.** §9 works through whether the four game names need ARB keys,
concludes correctly that they do (`CLAUDE.md`: no hardcoded user-facing
strings), writes "**7 + 4 = 11 new keys; 384 + 11 = 395**" — and §8's table and
acceptance criterion 2 still say 7 and 391, with a ⟲ line bolted on.

This is a countable term disagreeing with itself inside one document, which is
precisely what the Phase 02 lesson exists to prevent. A reader checking the
post-review against the plan would find two different expected totals.

**Applied.** The plan is corrected so §8, §9 and criterion 2 all read **11 new
keys, 395 total**, with no stale number left in place. Measured against
`app_en.arb` (384 keys), confirmed by `grep -c '^  "[a-z]'`.

## M2 — one gutter constant, two measurements, no tolerance argument

**Medium.** §3 measures the card hairline's leading edge at 12.5 pt and the
first game tile's at 10.2 pt, then proposes a single `CapySpacing.gutter = 11.0`
on the grounds that both round to ~11.

The reasoning is probably right but it is asserted. 12.5 and 10.2 differ by
2.3 pt, which is inside ±4 but is not nothing — and the plan does not say which
of the two the constant should favour, nor what happens to Tier A if the真 answer
is that the mockup genuinely insets cards further than rails.

**Applied.** Measured both edges again with the same detector and stated the
decision explicitly in the plan: the hairline is a **1 pt stroke drawn inside**
the card's box, so its detected leading edge sits ~1 pt inboard of the card's
actual edge — which accounts for most of the 2.3 pt. The tile has no stroke and
reads at its true edge. `gutter = 11.0` is taken from the **tile** measurement
(10.2, plus the detector's half-pixel bias), and the card uses the same gutter
with its stroke drawn inside. Both then land within 1.5 pt of the reference.
Recorded with the measurement, not as a rounding.

## M3 — the widget test could be read as satisfying the capture requirement

**Medium.** §10 has `home_screen_test.dart` assert "blocks fall within ±4 pt of
§3". A later session reading only the test table could conclude Tier A is
covered by `flutter test`.

It is not. A widget test measures a tree under a synthetic viewport with test
fonts and no device insets. The fidelity contract accepts a **capture of the
real app on the simulator**. `CLAUDE.md`: *"Do not claim a screen matches
without a recorded capture."*

**Applied.** Already noted in the plan's §10 ⟲ line; promoted to an explicit
statement in the plan and repeated in the acceptance criteria: the widget-test
assertion is a **cheap regression guard**, and criterion 5 is satisfied **only**
by `tool/capture.sh` + `tool/compare.dart`. Neither substitutes for the other,
and the post-review reports the capture's numbers, not the widget test's.

## M4 — no test has ever rendered any screen at 320 pt or 430 pt

**Medium.** The plan's risk table mitigates rail overflow with "tested at 320 /
393 / 430". Checked whether that practice exists:

```
$ grep -rn '320\|430' test/ --include='*.dart'
(no output)
```

`CAPYWAKE_NEW_ARCHITECTURE_PLAN.md` §1 names 320 pt and 430 pt as secondary
verification sizes and §8 mitigates the hero-crop risk with "checked at 3
widths every UI phase". **Phase 01 built three screens and checked one width.**
Home is the first screen with content that can overflow, so the practice either
starts here or the mitigation is fiction.

**Applied.** `home_screen_test.dart` renders Home at **320 × 568**, **393 ×
852** and **430 × 932** and asserts no overflow (`tester.takeException()` is
null and no `RenderFlex` overflow is recorded) and that the rail, card, CTA and
My Stats row are all present at each. This is a new practice; it is recorded in
the post-review as one so phases 04–08 inherit it rather than rediscovering the
gap.

## M5 — fixed-height tile label asserted without measuring the long locale

**Medium.** The risk table says the tile label box is "fixed-height, two lines,
tested in `de`". The mockup already wraps "Find the Impostor" to two lines in
English. German compounds are longer, and `ru` longer still.

Specifying a fixed two-line box before measuring the longest string is how a
label gets clipped in one locale and nobody notices for five phases.

**Applied.** The label box is **two lines with `TextOverflow.visible` inside a
fixed-height slot sized to two lines at the body scale**, and the test asserts
the four names render without clipping in `en`, `de` and `ru`. If a name does
not fit in two lines at the tile width in any of the ten locales, the finding
is reported in the post-review with the measured string rather than silently
ellipsised — `CLAUDE.md` forbids `TextOverflow.ellipsis` as a fitting device
(`flutter:accessibility-as-code`), and clipping a product name is a content
defect, not a layout detail.

## M6 — `MeadowFooter` as `CustomPaint` needs an explicit reading, not an aside

**Medium.** The plan says a drawn grass band "is **not** the legacy's banned
vector-capybara rule — that rule was about the *mascot*". True, and the
reasoning is sound. But this is the single decision most likely to be
misread by a later session as "Phase 03 reintroduced `CustomPaint`", given that
1,939 lines of `CustomPaint` are named in `CLAUDE.md` as the root cause of the
previous failure.

A decision this adjacent to a documented catastrophe deserves its reasoning in
the record, not in a table cell.

**Applied.** Stated in the plan and carried to the post-review:

> The banned rule was *"the capybara is vector `CustomPaint`, never a raster
> cutout"* — a rule about **how the mascot is drawn**, which made a painted
> storybook look unreachable. The meadow is not a mascot; it is a background
> band of flat colour with a wavy top edge, and **no supplied asset is the
> right shape for it** (G13). Drawing it is the alternative to tiling a 90 px
> tuft 4.4 times across 393 pt, which would read as a repeat. Every capybara on
> this screen is a raster cutout, which is the rule that matters.

If the owner later supplies a painted meadow band, it replaces the painter with
no layout change — the band's height is a measured constant either way.

## L1 — the empty-state ARB keys were assumed, not read

**Low.** The plan uses `todayNoAlarmTitle` / `todayNoAlarmBody` for the
empty state. Their existence was confirmed by `grep`; their **content** was
not. If `todayNoAlarmBody` says something phase-specific or refers to a control
Home does not have, the empty state ships wrong copy in ten locales.

**Applied.** Read both values in `app_en.arb` before use, confirm the copy fits
Home's empty state and the safety rules (calm, neutral, no overpromising), and
if it does not, add a Home-specific key rather than repurposing one. Recorded
either way.

## L2 — "no fabricated data on Home" has no gate

**Low.** Acceptance criterion 9 says no numeric literal in a user-facing
position on Home. `tool/check_no_fake_stats.dart` greps `lib/features/stats/`
only — criterion 9 is therefore an intention, not a check, and Home is the
screen whose mockup shows `7:00 AM` and `Mon – Fri`.

**Applied.** Checked whether `check_no_fake_stats.dart` exists yet (it is
scheduled with Stats in phase 08). Phase 03 does not build the Stats gate, but
it does not leave criterion 9 ungated either: the empty-state-first test (H4)
plus a grep-based assertion in `home_screen_test.dart` that
`lib/features/home/` contains no clock-shaped or weekday-shaped literal in a
`Text`. Narrow, cheap, and it fails loudly if a later session hardcodes the
mockup's demo values.

## L3 — G13 rests on a single measurement

**Low.** The "no asset fits the meadow" conclusion comes from one green-dominance
scan plus the decor file sizes. Both are good evidence but the scan sampled
every 8th pixel on every 10th row.

**Applied.** Re-measured at full row resolution across the footer band before
filing G13, and recorded the measurement in `asset_gaps.md` with the command,
per that file's standard ("every measurement here came from running a command
against the file"). If the band turns out to be tiled after all, G13 is
withdrawn like G9 — with its reasoning left visible.

---

## What this pre-review changes about the plan

| Change | From | To |
|---|---|---|
| Blocks compared | 4 (undisclosed) | 11, matching the documented vocabulary |
| Acceptance criterion 5 | one unsatisfiable clause | 5a binding + 5b drift attribution |
| G12 | an asset gap with an omit-the-mascot fallback | withdrawn; asset catalogued; six capybaras ship |
| Home empty state | a tested case | the default, tested first, capture declared seeded |
| ARB total | 7 / 391 in two places, 11 / 395 in a third | **11 / 395** everywhere |
| Widths tested | one | three — a new practice, recorded as one |
| Mascot size gate | never ran on mascots | runs |

The three findings that required running a command rather than re-reading the
plan (H1, H3, M4) are the three that changed the phase most. That is the same
result Phase 02 got, and it is worth keeping as the method: **check the claim
against the artifact, not against the document that made it.**

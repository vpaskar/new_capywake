# Current phase

**Phase 07 — Settings, reliability checklist, walkthrough: done, 2026-11-17.
`Current phase: 08`.**

**1,452 tests**, analyze clean including infos, lib 97.80% / `lib/core`
99.61% / `lib/data` 88.95% / `lib/features/settings` 98.49%, **427 ARB keys ×
10 locales** (22 new).

## What this phase actually found

### 1. The mockup drew a switch that would silence every alarm

`04_SETTINGS.png`'s **Alarm Notifications** toggle has two possible meanings
and both are defects. Mapped to the OS permission, a switch cannot revoke one,
so "off" must be a local flag suppressing scheduling — a control inside
Settings that stops every alarm from ringing, with nothing on screen saying
so. Mapped to nothing, it is a dead control, worse than a dead row because it
moves.

Shipped as a **status row that grants and never revokes**. Revoking stays in
the OS, where the OS states the consequence. Same safety rule as the
emergency escape, one step earlier.

### 2. The permanently-denied user got nothing at all

`shouldRequestNotification` is **false** for `permanentlyDenied` — correctly,
there is no prompt left. The wiring then asked `shouldOpenSettings` *inside*
that branch, so the route to the OS was unreachable: no dialog, no route, no
explanation, for the one user a prompt cannot help.

### 3. Nine of ten gate tests passed with the gate deleted

Phase 06's rule applied, and it bit. "Disabling the only alarm does not ask"
seeded **one** alarm; with the gate gone, *a different rule* ("no alarm is
enabled") suppressed the prompt, so the test passed without noticing. Seeded
with two, mutation now fails **two** tests.

**Phase 06 found this shape with in-memory fakes hiding an async window. Here
it was one rule covering for another.** Mutation was the only way to see
either.

### 4. `compare.dart` invented a delta for a block it had not measured

It printed **"group 1 card top −18.7 TIER A FAIL"** for a card sitting
**−2.7** from its mark, on a screen whose hero matched to 0.1 pt.

`_hairlines` read **one column at x=360 pt** — text-free on Alarms, where
Phase 04 chose it, **under the hero art** here. `_nearest` then searched
±40 pt and claimed the hero's edge. Now three columns, paint rejected below
L=150, search ±12, `absent` past it. Verified against all three prior
captures: no new failures, false deltas collapsed (Home 36.2 → 1.4).

**Phase 05's rule for the third consecutive phase, in the same tool Phase 04
fixed for the same reason.**

### 5. Three screens fail their own Tier A tables, and two phases wrote down only their passing blocks

Home 6 failures, Alarms 5, Add/Edit 8, Settings 2 — nobody had run
`compare.dart` across every screen since Phase 04.

**Home's failures are all `absent` and its worst measured delta is 1.4 pt** —
the layout is good, the reporting was not. Phase 03's tracker row lists four
deltas, all from passing rows, out of fourteen blocks; under its own tool and
its own committed capture it reports **eight failures at 36.2 pt**. Phase 04's
row lists six passing numbers out of eleven.

Both rows corrected in place. Alarms' and Add/Edit's real failures are
**recorded, not fixed** — another phase's screen is not this phase's to change
blind.

### 6. Nineteen more stale ported dartdocs, after Phase 06 fixed twelve

Counted: `grep -rn "Phase [0-9]" lib/` returned **20** before, **1** after,
and the survivor is correct. Several named phases that do not exist here at
all (29, 31, 32, 34, 37); two named **Phase 09** for the reliability
checklist, which is *this* phase. `reliability_copy_service.dart` claimed its
ARB keys were "added in Phase 06" — a phase whose own row records **zero**.

### 7. `CLAUDE.md` documents a gate that has never existed

`tool/check_no_fake_stats.dart`, claimed to enforce the no-fake-numbers rule
on the screen `CLAUDE.md` itself calls most likely to lie. **Phase 02 found
exactly this with `tool/audit_art.dart`.** Now stated as prose, with Phase 08
owing the gate.

### 8. Four screens, four toggle sizes

59.6 / 54.0 / 48.0 / 44.3 wide. `CapyToggle.trackSize` is now **required** —
the move that made `bandHeight` required in Phase 04. And
`tier_a_blocks.md`'s Alarms toggle was wrong: "30.5 pt tall" came from a row
profile at **y=345**, but the pill starts at **356.5**, so it measured the
rounded cap. *A row profile at a single y is a slice, not a bounding box.*

## Tier A — one failure, and it is a rule conflict

header **+0.1**, hero **+0.1**, group 1 top **−2.7**, group 2 top **−0.6**,
group 1 bottom **+4.5 ❌**.

**The mockup's settings row is 41.1 pt. The tap floor is 44.** `CLAUDE.md`
makes reachability binding, so group 1 cannot be under 28.2 + 44×2 = **116.2**
against the mockup's **110.4**. Shipped at 117.2 after cutting every removable
pt. Declared with the arithmetic, not reported as a near-miss.

## Predictions

Tests **80** against 70–100 ✅. ARB **22** against 12–22 ✅. `lib` **97.80%**
against 97.0–97.8 ✅. **`lib/core` restated**: registered *unchanged* at
99.49%, measured **99.61%** — this phase is the first **caller** of the
reliability services ported in Phase 02, now 100%. *A coverage prediction has
to account for code elsewhere that starts calling a tree, not only for lines
added to it.*

## Next session — Phase 08, Stats

`05_STATS.png`. The empty state is the **default**, not a fallback.
**Phase 08 owes three things:** the sleep-boundary restoration (health did not
land in 07), `tool/check_no_fake_stats.dart` (never existed), and Stats' own
hero band — it still carries Home's 188.4.

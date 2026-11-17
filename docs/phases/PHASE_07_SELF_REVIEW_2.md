# Phase 07 — self-review #2

Written after self-review #1's findings were applied and validation passed
again. This pass asks the question Phase 06 added to the rule set: **does each
guard's test fail when the guard is removed?** — and then measures the screen
against its mockup rather than reading the code.

**6 findings: 1 High, 3 Medium, 2 Low. All applied.**

---

## High

### H1 — The gate's tests passed for the wrong reason, and mutation proved it

Phase 06: *"a guard whose test cannot fail when the guard is removed is a
guard on trust. Mutate the thing and see."*

Deleting the `isFirstEnableTransition` check from
`AlarmPermissionPrompt.maybeRequest` left **nine of ten** tests green. Only
"enabling a second alarm does not ask again" failed.

The two that should have caught it did not:

- **"disabling the only alarm does not ask"** seeded one alarm and turned it
  off. With the gate gone, `shouldRequestNotification` still returned false —
  because **no alarm was enabled any more**. A different rule suppressed the
  prompt, and the test could not tell which.
- **"nothing is asked on app start"** never taps anything, so no transition is
  evaluated with or without the gate. It tests the absence of a call, not the
  gate.

**Applied.** The disable test now seeds **two** enabled alarms and turns one
off, so an alarm stays enabled and the transition check is the only thing
between the tap and a prompt. Re-mutated: **two** tests now fail.

The app-start test is kept as-is and **declared** as not a gate test — it
asserts a real property (no prompt on launch) that happens not to be the
gate's doing.

Recorded in the test file, because the next person to read it will otherwise
re-derive it.

---

## Medium

### M1 — The mockup's row is below the tap-target floor, and the first capture hid it

The first capture put group 1 at **165.2 pt** against the mockup's 110.4. Easy
to read as a layout bug; it is two things stacked.

Measured with `tester.getRect` rather than inferred:

| | pt |
|---|---|
| row with a wrapping value ("Your phone's alarm sound") | 80.0 |
| row after one-lining the value | 56.0 |
| row after one-lining the title | **44.0** |
| mockup's row | **41.1** |

So **44.0 is the floor, and the mockup is under it.** `CLAUDE.md` makes
reachability binding; 41.1 pt rows are not reachable. Group 1 cannot be
smaller than 28.2 + 44×2 = **116.2** against the mockup's 110.4.

**Applied.** Every removable pt was removed — `verticalPadding` is
`CapySpacing.xs`, the band is within 0.2 pt — and the residual **+4.5 pt** is
declared in `docs/visual/settings/README.md` as a rule conflict, with the
arithmetic, rather than reported as a near-miss.

### M2 — The tool reported a delta for a block it never measured

`compare.dart` printed **"group 1 card top 187.4 → 168.7, −18.7 TIER A FAIL"**.
The hero's lower edge is at 169.0 and matched to **0.1 pt**. A card cannot be
18.7 pt above its mark on a screen whose hero is exact.

It was not: `_nearest` searched ±40 pt, found group 1's own edge undetected,
and claimed the **hero's** edge instead. Measured independently by the
left-card-edge trace, group 1's top is **184.7 against 187.4 = −2.7**, inside
tolerance.

Two causes, both fixed:

1. `_hairlines` scanned **one column at x=360 pt** — clear on Alarms, under
   the hero art on Settings, where it returned art minima and never saw the
   card. Now three columns, merged, with L<150 rejected as paint.
2. `_nearest` reached ±40 pt. Now ±12; past that the honest answer is
   `absent`, which still counts as a failure.

**Checked against all three already-captured screens before keeping.** No new
failures; false deltas fell (Home 36.2→1.4 worst, Add/Edit 31.1→10.5).

**This is Phase 05's rule for the third time in three phases: when a tool
reports a failure, check whether the tool is wrong before believing it about
your code.** It is also Phase 04's own finding — "a boundary the tool cannot
see is reported as a layout failure it never measured" — recurring in the
same tool, one screen later.

### M3 — One-lining the title traded a tall row for a truncated one

The fix for M1 set `maxLines: 1, overflow: ellipsis` on the row **title**. The
capture then read **"Default snooz…"** — the row no longer says what it is.

A truncated title is worse than a tall row: the row's whole job is its name.

**Applied.** The value yields first (`Flexible`, ellipsis) and the title is
`TextOverflow.visible` with the body laid out as `Flexible(fit: loose)` so it
takes the width it needs. Re-captured: titles render in full, group geometry
unchanged.

---

## Low

### L1 — The scope test hung instead of failing
The test proving `permissionStateProvider` survives the real root scope closed
its database before disposing the container, leaving a Drift stream timer
pending; the run hung for 600 s rather than failing. **Applied:** dispose then
close, as `ringing_host_test.dart` already does. The test now passes in 4 s.

### L2 — `CLAUDE.md` documents a gate that does not exist
`CLAUDE.md:166` says no numeric literal may appear in `lib/features/stats/`
*"(`tool/check_no_fake_stats.dart` enforces it)"*. **There is no such file**,
and `tool/` holds eight scripts, none of them it.

Exactly what Phase 02 found with the documented `tool/audit_art.dart`, which
also did not exist — and the same shape as Phase 06's twelve stale dartdocs: a
document asserting something about the repository that the repository does not
support.

**Applied.** The line now states the rule as prose and names Phase 08 as owing
the gate. Not written here: Stats is Phase 08's screen, and a gate written a
phase early against an unbuilt screen is a gate nobody has tested.

---

## Outcome

6 findings, all applied, none invalid, none deferred.

The one worth carrying forward is **H1**: ten tests, a guard removed, and nine
stayed green. The guard was real and the tests were real, and still only one
of them was *about* the guard. Phase 06 learned this with in-memory fakes
hiding an async window; here it was a second rule quietly covering for the
first. **Mutation is the only way either was visible.**

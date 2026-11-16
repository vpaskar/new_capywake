# Current phase

**Phase 00 — Discovery, legacy audit, architecture and navigation decision:
done, 2026-11-16. `Current phase: 01`.**

## What Phase 00 established

No code, by design. The master prompt forbids implementation before the plan
has survived a critical review, and that is what this phase produced.

### The legacy is a real asset, not just a workflow example

`../capywake` is **40 of 47 phases done**: 137 Dart files, 99 test files, a
tested alarm core, 10 shipped locales, coverage gates at ≥85 % project and
≥95 % core, and a genuine phase ritual (2 phase self-reviews + 1 full-project
review per phase, every finding applied or marked invalid, never deferred).

Its alarm semantics are worth reproducing exactly: minutes-since-midnight time
storage, ISO weekday repeat sets, empty-set-means-one-time, no cached next-fire
time, the iOS 64-pending-notification cap, dismiss-exactly-once, the final
no-snooze alarm, and the stale-occurrence re-arm bug it fixed in its phase 34.

### Why the previous visual attempt failed

Found, quoted, and evidenced. `../capywake/CLAUDE.md` requires the capybara be
**drawn** — `CustomPaint`, "never a raster cutout" — and
`CAPYWAKE_REDESIGN_AUDIT.md` doubles down with "no raster cutouts from the
posters, which are flattened and won't theme". The result is 1,939 lines of
competent vector art that cannot resemble a painted storybook illustration.

The retrofit was not under-executed. It correctly executed an instruction that
made the goal unreachable. **That rule is not inherited.**

Two companion rules also dropped: "never more than one capybara per surface"
(`01_HOME.png` has six) and "never on the ringing surface" (every game poster
has one).

### The measurement that makes fidelity checkable

Mockups are **851×1847 px = 393×853 pt = iPhone 14 Pro**, which is available
as a simulator here. Captures and references share a viewport, so a diff means
something — the legacy never captured a single screenshot in 40 phases.

### The finding that shaped the contract

Verified against the files and saved to `docs/visual/_evidence/`: the Home
mockup's hero shows a capybara in a **blue nightcap holding a yellow duck with
an alarm clock on the nightstand**. The supplied `today_integrated.png` has
**no cap, no duck, and a mug and books** where the clock is. They are separate
generations.

So pixel-identity is impossible and promising it would produce a false "done".
Fidelity is therefore two-tier: **Tier A structural** (geometry, palette, type,
radii, control states, art placement — binding at ±4 pt, a real gate) and
**Tier B illustration** (nearest supplied asset, substitution logged by name,
never silently swapped, never newly generated).

### Decisions recorded

| Question | Decision | By |
|---|---|---|
| Art pipeline | **Raster.** Bundle the supplied PNGs, composite real widgets over them | Owner, 2026-11-16 |
| Stats data | **All three segments** — Sleep (Health, read-only), Alarms (wake events), Games (history) | Owner, 2026-11-16 |
| Process rigor | **Full, including all 10 locales** from day one | Owner, 2026-11-16 |
| Navigation | **Home · Alarms · Stats** tabs; Settings pushed from the gear | Phase 00, from 4-of-5 mockup evidence |

The navigation decision supersedes `CAPYWAKE_REDESIGN_AUDIT.md`'s "no
navigation change is needed", which was defensible against the older boards but
not against the primary mockups.

## The pre-review, and what it changed

12 findings — **4 High, 5 Medium, 3 Low. All 12 applied.** The four that
changed the shape of the build:

1. **HIGH-1** — "1:1" was unachievable against art that does not exist →
   replaced with the two-tier contract and a per-screen asset mapping written
   before each screen.
2. **HIGH-2** — the plan built Home before `Alarm` existed, which would force a
   rewrite in phase 04 — *the exact retrofit motion that failed last time*.
   Domain moved ahead of the first screen.
3. **HIGH-3** — nothing in the plan actually captured a screenshot, and the
   legacy's 40-phase silence proves that is not free. The capture harness is
   now Phase 01's gating deliverable, proven on the empty shell.
4. **HIGH-4** — the Stats mockup's numbers would leak into the widget tree.
   Empty state is now the **default** rather than the fallback, plus a
   `check_no_fake_stats.dart` gate and demo data confined to tests.

Mediums settled the Settings Account group (Backup & Sync and Restore
Purchases dropped — no backend, nothing to restore), the dead game cards (typed
catalogue with `comingSoon`/`blocked`), the unmeasured art budget (measure,
then set at +20 %), and the undecided typeface (chosen in Phase 01 against a
reference crop).

## Next session

Phase 01. Read `docs/phases/PHASE_01_PLAN.md`, revise it, write
`PHASE_01_PRE_REVIEW.md` **before any code**, then implement.

Phase 01 is not done until `tool/capture.sh` has produced a real PNG of the
shell at 393×852. If the harness cannot be made to work, that is a blocker to
surface there — not a surprise in phase 03.

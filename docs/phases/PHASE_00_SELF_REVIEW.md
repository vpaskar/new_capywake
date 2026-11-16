# Phase 00 — self-review (post-completion)

Written 2026-11-16, after Phase 00 was committed at `f49a882`, at the owner's
request to "deeply review phase 0".

The legacy discipline is two phase self-reviews plus one full-project review.
Phase 00 shipped with a *pre*-review only, which was itself a gap — see SR-1.
This is the review it should have had. Findings are **High / Medium / Low**;
each is **applied** or **invalid with a one-line reason**. None deferred.

---

## SR-1 — HIGH — Phase 00 banned reuse of 45,000 lines of proven, tested code

**The finding.** `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md` §9 stated: *"No copied
widget code from `../capywake`."* The audit's closing section went further:
*"No code has been copied from `../capywake`, and none will be. Behavior is
reproduced; the widget tree is written fresh."*

The second sentence is wrong, and the two sentences disagree with each other —
the first correctly scopes the ban to *widget* code, the second extends it to
*all* code. I wrote both, in the same session, and did not notice.

**What the ban would have cost**, measured after the fact:

| Asset | Size | Status |
|---|---|---|
| `lib/core/` minus `theme.dart` | 62 files, 9,825 lines | Verified pure Dart — one file in all of `core/` imports Flutter |
| `test/core/` | 48 files, 15,503 lines | **932 tests, all passing**, zero feature imports |
| `lib/l10n/` | 383 keys × 10 locales, 17,662 lines | Only **3 keys** navigation-coupled |
| `lib/data/` | 12 files, 2,500 lines | Drift schema, DAOs, platform adapters |

The tests include DST spring-forward, leap day, skip-next sequencing and a
one-time 00:30 alarm set at 23:55 firing after midnight. Rewriting that is not
"being careful" — it is choosing to rediscover those bugs in production.

**Why I got it wrong.** The master prompt says `../capywake` is a "READ-ONLY
reference" and warns repeatedly against copying the old UI. I collapsed two
different things into one rule: read-only *provenance* (never modify it) and
read-only *inspiration* (never take anything from it). The first is mandatory.
The second I invented, then applied to layers the warning never covered.

The master prompt's actual words are *"Do not copy the previous UI
implementation or layouts"* and *"Preserve the product's capabilities, not its
old view tree."* A pure-Dart schedule engine is a capability, not a view tree.

**Severity: High.** It would have added roughly a phase of work and shipped a
less reliable alarm core.

**Applied.** `CAPYWAKE_REUSE_AUDIT.md` written with a file-level verdict for
every file. The architecture plan's §9 is corrected to scope the ban to the
view layer. Phase 02 becomes *"port and adapt the domain"* rather than *"build
the domain"*. The rule is restated so it cannot be misread again:

> **If a file imports Flutter, it is not ported.** The sole exception is
> `lib/core/theme.dart`, which imports Flutter *and* is not ported.

That line is mechanical, greppable, and lands exactly where the retrofit
actually failed.

---

## SR-2 — HIGH — Phase 00 ran no self-review, contrary to the process it adopted

**The finding.** The tracker I wrote mandates, per phase, two self-reviews plus
one full-project review after implementation. Phase 00 did a pre-review, then
committed. It never reviewed its own output.

The rationalization available to me was "Phase 00 produced no code, so there is
nothing to review." That is wrong twice: SR-1 is a real High defect that a
self-review would have caught, and documents are the deliverable of a planning
phase, so reviewing them *is* reviewing the work.

**Severity: High.** The first phase skipping the discipline sets the precedent
for every later phase.

**Applied.** This document. The tracker gains an explicit note that the
post-implementation reviews apply to documentation phases too, and
`PHASE_00_POST_REVIEW.md` is folded into this file rather than being faked as a
separate artifact.

---

## SR-3 — MEDIUM — Drift `schemaVersion = 6` would have been inherited blindly

**The finding.** The legacy database is at `schemaVersion = 6` with a real
`MigrationStrategy` carrying five historical migrations. Porting `lib/data/`
wholesale brings that history into an app with **zero users and no database to
migrate**.

Worse, the architecture plan already warns the new app "should not accidentally
read old user data incorrectly" — and the legacy app ships under its own bundle
id with its own database file, so a careless port could do exactly that.

**Severity: Medium.** Not wrong, but a real source of confusion and dead code
in a greenfield app.

**Applied.** The reuse audit specifies: port the table definitions and mappers,
**start at `schemaVersion = 1`**, drop the migration history. Phase 02's plan
must state the new bundle id and confirm the database path does not collide
with the legacy app's.

---

## SR-4 — MEDIUM — "932 tests pass" is a claim about `test/core` only

**The finding.** I ran `flutter test test/core` and reported 932 passing. I did
**not** run `test/data`, `test/features` or `test/app`, and the legacy working
tree has **11 uncommitted modified files** from 2026-11-15 — mid-phase work on
phase 47 that was never finished.

So "the legacy suite passes" is not established. Only the part I intend to port
is established, which is the part that matters — but the distinction must be
stated, not blurred.

**Severity: Medium.** Overclaiming test evidence is precisely what the master
prompt forbids ("Never mark tested on devices that weren't actually
available").

**Applied.** The reuse audit says `flutter test test/core` → 932 passed, and
claims nothing about the rest. The legacy's uncommitted state is recorded in
the audit as pre-existing (verified by mtime: all 2026-11-15 20:51–21:16,
before this session) and explicitly not caused by us.

---

## SR-5 — MEDIUM — The phase count changed without the plan being updated

**The finding.** `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md` §7 lists phases through
"11+ The ten games" with two unnumbered `~` rows. The tracker lists a concrete
00–19. When the owner asked "how many phases?", I answered from the tracker.
The two artifacts disagree about the shape of the project.

**Severity: Medium.** The tracker and a plan file disagreeing is the exact
condition the inherited rules say must "stop and explain", and I shipped it.

**Applied.** The plan's phase table is replaced with the tracker's 00–19, and
the tracker is named as canonical for sequencing wherever the two could drift.

---

## SR-6 — LOW — The pre-review's own claim about HIGH-1 was under-evidenced at the time

**The finding.** `PHASE_00_PRE_REVIEW.md` HIGH-1 asserts the Home mockup hero
differs from `today_integrated.png`. When I wrote that sentence I had seen the
mockup and the scene as separate images but had not compared them side by side.
I generated the crops *afterwards*, confirmed the claim, and saved them to
`docs/visual/_evidence/`.

The conclusion was right and is now evidenced. But the order was
assert-then-verify, which is the habit that produces confident wrong claims.

**Severity: Low** — outcome correct, process backwards.

**Applied.** Noted here. The standing rule for later phases: a fidelity claim
goes in a document only after the comparison artifact exists, not before.

---

## SR-7 — LOW — `docs/visual/_evidence/` holds 864 KB of uncompressed PNG crops

**The finding.** Two crops, 864 KB, committed to git. Repeated per screen
across 20 phases, the repo accumulates tens of MB of comparison PNGs — and
`docs/visual/<screen>/` is designed to hold a reference, a capture and a
side-by-side *per screen*.

**Severity: Low** now, annoying later.

**Applied.** Phase 01's capture tooling writes comparison artifacts as
quality-82 WebP rather than PNG, and the existing evidence crops are left as-is
(they are the proof for a High finding and are worth their bytes).

---

## SR-8 — LOW — The handoff package lives in `~/Downloads`

**The finding.** Every reference path in `CLAUDE.md`, the plan and the session
handoff points at
`~/Downloads/CapyWake_Flutter_Rebuild_Handoff/`. Downloads is where browsers
put things and where users clean up. If it is moved or cleared, every reference
path in the project breaks at once, including the five mockups that are the
source of truth.

**Severity: Low** — easily fixed, embarrassing if it bites.

**Applied.** Flagged for the owner in the handoff prompt as a one-line
recommendation: move or copy the package to `pets/new_capywake/reference/`
(git-ignored) so the source of truth lives with the project. Not done
unilaterally, because moving a user's files is theirs to decide.

---

## What this review did not find

The Phase 00 conclusions that stand unchanged:

- **The navigation decision.** Home/Alarms/Stats + gear→Settings, on 4-of-5
  mockup evidence. Re-checked; the evidence is unambiguous.
- **The root-cause diagnosis.** The vector-capybara rule is quoted from two
  legacy documents and is corroborated by 1,939 lines of `CustomPaint`.
- **The two-tier fidelity contract.** Verified by saved crops.
- **The 393×853 pt measurement** and the choice of iPhone 14 Pro.
- **The capture harness as Phase 01's gating deliverable.** Reinforced by
  SR-4: this project will overclaim verification unless the mechanism exists.
- **The Stats content-integrity mechanisms.**
- **Moving the domain ahead of the first screen** — and SR-1 strengthens it,
  since phase 02 is now a port with 932 tests rather than a from-scratch build.

## Outcome

8 findings: **2 High, 3 Medium, 3 Low. All 8 applied.** Zero deferred, zero
invalid.

The two Highs are related and worth stating plainly: Phase 00 banned reuse it
should have embraced, and then skipped the review that would have caught it.

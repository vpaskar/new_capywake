# Phase 00 — Discovery, audit, architecture, navigation decision

## Status

done — 2026-11-16

## Goal

Establish the source of truth before any code exists: audit `../capywake`
read-only for product semantics and its phase/review ritual, inventory and
inspect the handoff package, resolve the navigation conflict the master prompt
flags, decide the open questions that change the shape of the build, and
produce a plan that has survived an adversarial review.

No implementation in this phase, by design.

## Must implement

- [x] Read the full handoff: master prompt, README, 7 docs, 11 phase briefs,
      workspace state.
- [x] Inspect all five primary mockups visually, not just by filename.
- [x] Measure mockup geometry and sample the palette.
- [x] Audit `../capywake` read-only: process artifacts, alarm domain,
      edge cases, dependency rationale, safety rules, test gates.
- [x] Identify why the previous visual attempt failed.
- [x] Resolve the navigation conflict with recorded evidence.
- [x] Inventory the asset package and decide what ships.
- [x] `CAPYWAKE_LEGACY_AUDIT.md`.
- [x] `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md`.
- [x] `docs/phases/PHASE_00_PRE_REVIEW.md` — adversarial, before any code.
- [x] Revise the plan against every finding.
- [x] Repo skeleton: `git init` on `main`, `.gitignore`, tracker, `CLAUDE.md`,
      memory and session files.

## Must not implement

- No Flutter project, no `pubspec.yaml`, no Dart code. Phase 01 owns that.
- No asset copying into a bundle. Phase 01 owns the import, audit and encode.
- No modification of `../capywake`, ever.

## Acceptance criteria

| Criterion | Result |
|---|---|
| Legacy process artifacts reported as **found**, not invented | 10 artifact types listed with real paths; 40/47 phases `done` |
| Root cause of the failed retrofit named with evidence | The vector-capybara rule, quoted from `CLAUDE.md` and `CAPYWAKE_REDESIGN_AUDIT.md` |
| Navigation conflict resolved and recorded | Home/Alarms/Stats + gear→Settings; 5-row evidence table in audit §6 |
| Open product questions decided by the owner | Raster art · all three Stats segments · full rigor incl. 10 locales |
| Plan survived an adversarial review | 12 findings (4H/5M/3L), all applied, none deferred |
| `../capywake` unmodified | Only read commands issued |

## Tests

Not applicable — no code. Verification was: every claim in the audit traces to
a file actually opened, and the HIGH-1 art claim is backed by saved crops in
`docs/visual/_evidence/`.

## Outcomes that changed the build

1. **The legacy is far more mature than the handoff assumes** — 137 Dart files,
   99 test files, a tested alarm core, 10 shipped locales. It is a behavior
   reference of real value, not just a workflow example.
2. **The retrofit failed for a documented reason**, not sloppiness: a
   self-imposed rule that the capybara must be vector `CustomPaint` and never a
   raster cutout. That rule is not inherited.
3. **Screenshot comparison can be exact.** Mockups are 851×1847 px = 393×853 pt
   = iPhone 14 Pro, which is available here.
4. **But pixel-identity is impossible**, because the mockup art and the supplied
   art are different generations — verified and evidenced. Hence the two-tier
   fidelity contract.
5. **The legacy never captured a single screenshot in 40 phases.** The capture
   harness is therefore a Phase 01 deliverable with its own DoD, not an
   assumption.

## Risks carried into Phase 01

- Capture harness may not work headlessly → it is Phase 01's gating deliverable.
- Art budget is unmeasured → Phase 01 measures, then sets the gate.
- Font is undecided → Phase 01 selects by comparison against a reference crop.

## Rollback

Documentation only. Reverting is deleting the files; nothing downstream
depends on them yet.

# CapyWake

A cozy, capybara-themed smart alarm for iOS and Android. Flutter, offline-first,
no backend.

This is a **greenfield rebuild**. The UI is reconstructed from scratch against
the illustrated mockups in `reference/`;
the alarm behavior reproduces semantics proven in the legacy `../capywake`,
which is a **read-only** reference and is never modified.

## Status

**Phase 00 done — no app code yet, by design.** Implementation begins at
Phase 01. See `ai-orchestration/PHASE_TRACKER.md`.

## Start here

1. `CLAUDE.md` — rules.
2. `docs/sessions/next.md` — what to do next.
3. `ai-orchestration/PHASE_TRACKER.md` — where we are.
4. `CAPYWAKE_LEGACY_AUDIT.md` — what the legacy project contains and why its
   visual attempt failed.
5. `CAPYWAKE_NEW_ARCHITECTURE_PLAN.md` — the plan, revised after its
   adversarial pre-review.

## Navigation

Three tabs — **Home · Alarms · Stats**. Settings is a pushed route from the
gear in the header. Decided in Phase 00 from the primary mockups; see the audit
§6 for the evidence.

## Fidelity contract

**Tier A — structural, binding.** Geometry, proportions, palette, type, radii,
control states and art placement match the reference within ±4 pt at 393×852
(iPhone 14 Pro, which is the mockups' exact viewport).

**Tier B — illustration, declared.** The mockups contain art that is not in the
asset package. The nearest supplied asset is used and the substitution is
logged by name. No new art is generated; no substitute is passed off as the
original.

A screen is done when its comparison is captured and its deviations are named
— not when it functions.

## Layout

```
lib/app/       bootstrap, router, theme, shell
lib/core/      pure Dart domain, no Flutter
lib/data/      Drift, repositories, platform adapters
lib/design/    tokens + shared illustrated components
lib/features/  one directory per feature
lib/l10n/      10 ARB files
docs/phases/   plan / pre-review / post-review per phase
docs/visual/   reference, capture and side-by-side per screen
```

## Development

Per phase: plan → adversarial pre-review → revised plan → implement → validate
→ two self-reviews → full-project review → post-review → commit. Every finding
is applied or marked invalid; none is deferred.

Validation and the full rule set are in `CLAUDE.md`.

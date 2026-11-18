# Current phase

**Phase 20 — Settings and Wake puzzle redesign: done, 2026-11-18, not yet
committed** (the owner-requests session's work shares the same files; the
owner picks the commit split). `Current phase: none`.

**2,629 tests**, analyze clean, lib 98.72% / `lib/core` 99.74% / `lib/data`
91.20%. Settings' Tier A reference is now `01_SETTINGS_REFINED.png`
(`docs/visual/tier_a_blocks.md`). Records: `docs/phases/PHASE_20_*`.

---

# Current phase

**Phase 19 — Release QA: done, 2026-11-18. `Current phase: none` — the phase
plan (00–19) is complete.** What remains is the owner's: the open questions,
the art requests, a real iPhone and a real Android phone, and every store
button.

**2,525 tests**, analyze clean, lib 98.71% / `lib/core` 99.74% / `lib/data`
91.28%, **590 ARB keys × 10 locales**. Comment baseline 113.

## What Phase 19 adds to the recipe

- **iOS background ring:** `test/platform/ios_platform_setup_test.dart` guards
  the plugin's setup; `integration_test/background_ring_probe_test.dart`
  (`--dart-define=CAPYWAKE_BACKGROUND_PROBE=true`) proves it on the simulator.
- **Zone:** `DeviceZone` (`lib/data/engine/`) — read the zone, never capture it.
  The coordinator reads `scheduleLocationProvider` at compute time and listens
  for a move; it must stay one instance across a zone change.
- **Practice sensors:** wrap in `OnScreenMotionSensor` / `OnScreenStepSensor`
  (the app lives in the background now). A ring keeps raw sensors.
- **Privacy copy:** promise only what both platforms do —
  `test/l10n/privacy_claims_test.dart`.
- **After the first public build, schema changes need migrations** (`CLAUDE.md`).
- **Icon:** `dart run tool/make_app_icon.dart <file>`.

## Open for the owner

`docs/sessions/OPEN_QUESTIONS.md` (Phase 19: ML Kit, iPhone-only, icon,
price/URLs, silent mode, Portuguese variant); `ART_REQUESTS.md` #17 (blocks a
public release); `docs/release/RELEASE_CHECKLIST.md` device matrix.

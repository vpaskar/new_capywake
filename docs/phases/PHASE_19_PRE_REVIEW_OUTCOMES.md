# Phase 19 — Pre-review outcomes

How each pre-review finding landed in code. One line each.

| Finding | Outcome |
|---|---|
| H1 practice sensors in background | `OnScreenMotionSensor` / `OnScreenStepSensor` in practice; ring keeps raw sensors; 2 tests, mutation-checked |
| H2 zone change mid-ring | Coordinator reads the zone at compute, listens for change; same instance across a change (tested, mutation-checked); platform `rescheduleAll` skips ringing ids |
| H3 probe can fail | Failed before F1 (46.8 s late), passed after (248 ms) — `docs/release/evidence/` |
| H4 icon source size | Tool refuses undersized sources; alarm clock 648 × 764 placed at 655 px (downscale) |
| H5 camera copy | Pictures only, ten locales; iOS purpose string kept (iOS uses Vision) |
| M1 alias names | Unknown name → fingerprint, tested |
| M2 API 26 | `TimeZone.getDefault().id` |
| M3 export flag | `RECEIVER_NOT_EXPORTED` on 33+; unregistered on cancel |
| M4 signing path | See post-review (throwaway keystore build) |
| M5 portrait on large screens | Recorded in the checklist |
| M6 migrations after release | `CLAUDE.md` + checklist |
| M7 store copy | `STORE_LISTING.md` rules block; "smart", "timer", "loud" dropped |
| M8 privacy follows artifacts | `PRIVACY.md` evidence table |
| M9 export compliance | `ITSAppUsesNonExemptEncryption = false` |
| M10 dev surfaces | None in `lib/` (grep recorded in post-review) |
| M11 capture diff | See post-review |
| L1 CupertinoIcons | Invalid: no Cupertino widget in `lib/` |
| L2 iPad orientation key | Removed |
| L3 themed icon | Requested (#17), not faked |
| L4 plan wording | Reworded |

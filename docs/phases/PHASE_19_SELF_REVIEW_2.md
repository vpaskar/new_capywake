# Phase 19 — Self-review #2 (unanchored)

A subagent given the diff, `CLAUDE.md` and the plugin sources — not my
conclusions. 15 findings; all applied.

| # | Sev | Finding | Applied |
|---|---|---|---|
| H1 | High | Listing: wake window "rises to full volume" — the plugin fades to the phone's volume | Listing + in-app `alarmWakeWindowExplanationStrict` (same claim), ten locales: "your phone's volume" |
| M1 | Med | `OnScreen*Sensor` built in `build` with identity equality: every rebuild re-subscribed the game, Step Quest reset its tally | Equal per inner sensor (`@immutable`); test |
| M2 | Med | Relay never started when subscribed while `inactive` (permission alert) | Starts on `inactive`; `onResume` too; test |
| M3 | Med | Relay swallowed the inner stream's done, so Step Quest's `onDone` fallback never fired | Done is forwarded; test |
| M4 | Med | iOS kill notice was the plugin's English "You killed the app…" in every locale | `setKillWarning` with two new ARB keys, ten locales, calm wording |
| M5 | Med | iPhone restart missing from the reliability copy | `reliabilityCautionTerminationIos` + listing, ten locales |
| M6 | Med | Privacy policy "collects nothing" contradicted its ML Kit note | Reworded |
| L1 | Low | Silent-mode copy said iOS mutes the ring; the plugin plays as media | "can't promise to ring through" — ten locales |
| L2 | Low | Production zone override and channel registration untested | `scheduleLocationFollowing` extracted + tested; wiring gate |
| L3 | Low | Android `TimeZone.getDefault()` may lag the broadcast | Emits the intent's `time-zone`; Dart trusts a known name; tests |
| L4 | Low | Travel with the app not running undocumented | Checklist row 8a; listing tells the user to open the app once |
| L5 | Low | Gradle: missing property threw an NPE-like error, warning on every build | Named-property error; warning only for release tasks |
| L6 | Low | Listing said Shake DJ / Tilt Maze ask permission | Fixed (listing, privacy) |
| L7 | Low | `CLAUDE.md` "this app has no users" vs "shipped builds have users" | Port table reworded |
| L8 | Low | The probe ran (and failed after 5 min) under `flutter test integration_test` | Skipped unless `CAPYWAKE_BACKGROUND_PROBE=true` |

# Phase 19 — Full-project review (release lens)

The whole app read as a release candidate, not only this phase's diff.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| P1 | High | **`ring_lifecycle_test` failed twice on the pre-review tree** ("the dismissal re-armed the alarm": nothing armed for tomorrow 2 s after a dismiss). Bisected on a `HEAD` copy: `HEAD`, `HEAD` + iOS native, + coordinator, + zone wiring, + shell, + all without the kill-notice call each passed; the post-review tree passed 3 of 3. Not reproduced in 9 runs since. | **Recorded as an unexplained intermittent failure** with the evidence; the release checklist makes re-arm after dismiss a blocking device row (13a) and `next.md` asks for repeated runs. Suspected race, not proven: the plugin's ringing set re-reporting the stopped id between `cancel()` and the resync, so `plansToArm` skips it and nothing triggers another sync |
| P2 | Medium | `app_pt.arb` mixes European (`telemóvel`, `ecrã`, `tu`) and Brazilian (`você`) Portuguese, roughly half each | Reported to the owner: the store listing's market (pt-BR or pt-PT) decides which; a full harmonization is a translation pass, not guessable |
| P3 | Low | `grep -rn "Phase [0-9]" lib` | 0 — clean |
| P4 | Low | Debug-only surfaces, `print`, `TODO` in `lib/` and native code | None |
| P5 | Low | Android release APK size 41.5 MB (arm64) — bundled ML Kit per ABI and three native plugins | Recorded in the post-review; the AAB lets Play split per ABI |

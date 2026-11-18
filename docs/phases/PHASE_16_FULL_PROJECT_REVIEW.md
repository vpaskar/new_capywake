# Phase 16 — Full-project review

The whole app, read for what Step Quest changed outside its own files.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| P1 | Medium | Could R1 (a second listener on a platform event channel cuts off the first) also hit the accelerometer, shared by Shake DJ, Tilt Maze, Step Quest and the post-dismiss motion check? | **Invalid** — read from `sensors_plus_platform_interface` 2.0.2: `accelerometerEventStream` caches its stream (`_accelerometerEvents ??=`), so all listeners share one. |
| P2 | Medium | The puzzle chooser lists one more game row; four chooser tests had only ever passed because their targets were inside the lazy list's first build, and two negative tests ("does not warn") were passing vacuously once rows moved below the fold. | **Applied.** Every chooser test scrolls to its target first (`scrollTo`); the negative test scrolls to the section that would hold the warning. |
| P3 | Low | The Home rail had no blocked tile left, so its blocked-tile tests (sheet copy, "Soon" badge, a11y label) would have lost their subject. | **Applied.** `GameRail(entries:)` (defaults to the catalogue); the tests pump a synthetic blocked entry, and a new test pins that every Home-rail game is playable. |
| P4 | Low | `CFBundleLocalizations` now declares ten languages, which also localises system text iOS draws for the app (alerts, the notification prompt). | **Invalid as a defect** — that is correct behaviour the app lacked; noted for Phase 19's store pass. |
| P5 | Low | The Android app had never built (`flutter_local_notifications` needs core-library desugaring). | **Applied** (found in implementation): desugaring enabled; `flutter build apk --debug` succeeds. Never run. |
| P6 | Low | `GameLaunch` gained a required `steps`; every host and test constructing it must pass one. | **Applied** — both hosts and the registry test; `flutter analyze` clean. |

Checked, no finding: no `Phase N` in `lib/` doc comments (0); comment baseline
113 (+0); no hardcoded user string; RTL mirrored; every game still fits 320 pt
and the 424 pt card budget; the clock guard runs for Step Quest on both phones.

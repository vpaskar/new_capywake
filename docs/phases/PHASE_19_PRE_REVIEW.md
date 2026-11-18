# Phase 19 — Pre-review (adversarial, before any code)

Read against `PHASE_19_PLAN.md`, the plugin sources in the pub cache, the
merged release manifest and the memory files. Every finding is applied in the
revised plan or marked invalid with a reason.

## High

**H1 — F1 changes what runs in the background, not only whether the alarm
does.** With `audio` the app stays alive whenever an alarm is armed. A
practice game left open keeps the accelerometer or pedometer streaming, and
the scanner's camera is already released off-resume (Phase 17) but the other
two sensors are not. *Apply:* audit every sensor subscription outside a ring;
anything live in practice stops when the app leaves `resumed` and restarts on
return. A ring keeps its sensors (the user may be walking with the phone
locked). Tested per sensor.

**H2 — A zone change must not silence a ring.** Memory: a write during a ring
once re-ran the schedule and `rescheduleAll` called `stopAll()`. The zone
refresh goes through the same refresh path, and if the coordinator *watches*
the location provider, a zone change rebuilds it — a path that path's guard
never saw. *Apply:* the coordinator reads the zone when it computes, it does
not rebuild on it; a test changes the zone mid-ring and asserts nothing was
stopped; `ring_lifecycle_test` runs on the simulator after the change
(`next.md`: manual device check after any `lib/data/engine/` change).

**H3 — The background probe must be able to fail.** "It rang" after the fix
proves nothing unless the same probe, before the fix, shows it does not.
*Apply:* one integration test arms a ring 45 s out and waits for the
plugin's ring stream; the app is sent home while it waits. Run on the
unchanged build first, record, then after.

**H4 — The interim icon must meet the art rules, or it is an unreported gap
with a nicer face.** A sticker at ~250 px upscaled to a 1024 icon is the
"too low-resolution" case `CLAUDE.md` says to report, not ship. *Apply:* the
tool refuses a source smaller than its placement at 1024 and names the file;
the chosen source and its decoded size go in the post-review; if nothing in the
package is large enough, the icon stays a declared placeholder and that is
said in session.

**H5 — F3's fix must be true on both platforms and say nothing new.** "The
picture never leaves your phone" is true (ML Kit sends no images — Google's
page lists identifiers and metrics only; iOS uses Vision, verified: no ML Kit
in `darwin/`). It must not become a reassurance the code cannot back: no
"nothing is sent" on Android anywhere. *Apply:* grep all ten locales for the
old sentence; a test asserts the camera rationale has no "nothing leaves"
claim in English; the iOS purpose string (iOS only, still true) stays.

## Medium

**M1 — The native zone name may be an alias the `timezone` database lacks.**
*Apply:* unknown name → resolver fallback, tested; the post-review records
which route the simulator took.

**M2 — Android `ZoneId` needs API 26; `minSdk` is the Flutter default.**
*Apply:* `java.util.TimeZone.getDefault().id`.

**M3 — `ACTION_TIMEZONE_CHANGED` on a context-registered receiver needs an
export flag on API 33+.** *Apply:* register with `RECEIVER_NOT_EXPORTED` on
33+ (system broadcasts still arrive); unregister on cancel; one handler per
channel, cached on the Dart side (memory: event channel).

**M4 — The signing fallback is untested if the release path never runs.**
*Apply:* a throwaway keystore in the scratchpad (not the owner's key, deleted
after) proves the `key.properties` path signs; the plan's exclusion is
narrowed to "no release key created".

**M5 — Portrait lock on Android 16 is ignored on large screens** and Play's
lint flags restrictive orientation. *Apply:* recorded in the checklist; phones
are the target.

**M6 — After the first release a schema change needs a real migration.**
`migration_origin_test` says a phase adding one deletes it deliberately; that
was safe with zero users only. *Apply:* `CLAUDE.md` and the checklist gain the
rule — from the first public build, every shipped schema version upgrades,
tested from a populated v1 database.

**M7 — Store copy can overpromise in ways the in-app gate never sees.**
*Apply:* the listing names only what ships (no sleep data — the Sleep segment
says "not available yet"), says the emergency escape exists, states the iOS
limits, uses no competitor names in keywords, and is checked against every
character limit.

**M8 — The privacy answers must follow the artifacts, not intentions.**
*Apply:* iOS "Data Not Collected" only after confirming no networking code in
the iOS build (no ML Kit, no analytics SDK); Android declares ML Kit's
diagnostics; both cite the evidence.

**M9 — `ITSAppUsesNonExemptEncryption` is unset**, so every upload asks the
export-compliance question. The iOS app does no networking and no
non-exempt crypto. *Apply:* `false` in `Info.plist`.

**M10 — Development-only surfaces in a release build.** *Apply:* grep `lib/`
for capture/test hooks and debug-only controls; record the result.

**M11 — The capture diff needs a method that cannot hide a change.**
*Apply:* pixel diff of every `actual.png`/`dark.png` against `HEAD`, count of
changed pixels per screen, every non-zero explained.

## Low

**L1 — F12 (`CupertinoIcons`).** *Invalid, pending the check:* the warning
comes from the framework's own Cupertino library being in the program; it
only draws in Cupertino nav bars, text fields and list tiles, none used in
`lib/`. The plan already checks this; confirmed in implementation.

**L2 — `UISupportedInterfaceOrientations~ipad`** becomes dead once iPad is
dropped. *Apply:* remove it.

**L3 — Android 13 themed (monochrome) icon.** *Apply:* not added — it needs a
one-colour glyph the package does not have; listed in G48 with the request.

**L4 — The plan's "No signing keys created" contradicts M4.** *Apply:* reworded.

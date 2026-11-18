# Phase 17 — Self-review #2 (unanchored)

A reviewer given the code and the project rules, not the author's reasoning
or self-review #1. It confirmed the safety rules hold (QR rings only when
ready; no scanner is built without a grant, so neither OS can show the
plugin's own prompt; the escape stays with `RingingScreen`; the camera starts
only on a tap). Ten findings; all ten applied, each with a test proven to
fail without the fix.

| # | Sev | Finding | Outcome |
|---|---|---|---|
| R1 | Medium | `RingingHost` keeps the app mounted under a ring. A practice or setup camera left on there kept the one camera session: the ring's scan failed (`AlreadyStarted`) and only the escape remained — and the hidden setup could save any code seen during the ring as the new checkpoint. | **Applied.** While a ringing session exists, practice renders neither the camera game nor setup, which releases the camera; a late code after that is never saved. Test with a live session stream. |
| R2 | Medium | On a cold start the ring could pick before readiness loaded (or on a value still refreshing), silently swapping a QR-only alarm for a puzzle. | **Applied.** If the pool has a camera game and readiness is loading or refreshing, the ring shows a held slot (escape visible, no plain Stop) for up to `RingingHost.readinessWait` (2 s), then picks. |
| R3 | Low | The pool sheet used `ref` after an `await`; a closed editor threw an uncaught `StateError`, as did a malformed row. | **Applied.** Providers read before any await; the read is guarded. |
| R4 | Low | Two wrong codes in view alternated the dedupe digest — ~8 struggles a second and a flood of announcements. | **Applied.** Every wrong code counts once per look (camera session); a new look clears the set. |
| R5 | Low | The H2 "loading is not ready" test overrode the provider itself and could not fail. | **Applied.** Removed; replaced by the host test above with a camera that never answers. |
| R6 | Low | "Codes seen with the camera off" could not fail: the fake only reached live views. | **Applied.** `FakeCodeScanner.showLate` delivers to the last view after it closed. It found a crash: a late code reached an unmounted setup and used `ref` — both receivers now check `mounted`. |
| R7 | Low | Unsalted FNV-1a stored with the exact length over-claimed: a low-entropy Wi-Fi QR could be brute-forced from a backup. | **Applied.** A random 128-bit salt per checkpoint, no length; the comment says "can only be guessed". (A keyed hash would need a dependency the phase did not list.) |
| R8 | Low | A failed save left `_saving` true forever and threw uncaught. | **Applied.** try/finally, a "Could not save" line, retry works. |
| R9 | Low | Dead ends: no Cancel on Change checkpoint; no way back after Not now; "unavailable" said the camera failed; `clearQrCheckpoint` unused. | **Applied.** Cancel when a checkpoint is kept, "Allow the camera" after Not now, honest no-camera copy; the unused method removed. |
| R10 | Low | The `path` comment in `pubspec.yaml` sat above `mobile_scanner`. | **Applied.** |

## Mutation checks

11 of 11 new guards fail without their code (ring gate, pending pick, wrong
set, late code in view and setup, unmounted guard, save failure, Cancel, way
back, new look, salt).

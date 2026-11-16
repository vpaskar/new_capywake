# Bundled alarm tone provenance

All twelve PCM WAV files in this directory are original synthesized sounds.
`tool/generate_tones.dart` reproduces them byte-for-byte without a download,
samples from third parties, or attribution requirements.

| Category | Bundled tones |
|---|---|
| Gentle | Chimes, Gentle, Soft Mallets, First Light, Glass Drops |
| Rhythmic | Morning, Wooden Knocks, Bamboo Pulse, Syncopated Marimba |
| Firm | Mechanical Bell, Station Signal, Three-Tone Beacon |

Rebuild from the repository root with `dart run tool/generate_tones.dart`.

## Why generated rather than downloaded

Phase 30's appendix researched sourcing these from CC0 libraries and reached a
clear ordering: **CC0 or self-generated, and nothing else.** The generated route
was taken because it removes the dependency entirely rather than managing it.

The reasoning, kept here so it is not re-derived later:

- **The stock "royalty-free" libraries are the trap, not the safe harbour.**
  Several of the obvious sources bar redistributing sounds inside applications,
  or bar the sound being the product's primary value. For a menu blip those
  clauses are comfortable. For a **selectable alarm tone — where the sound is
  arguably the feature being paid for** — they are ambiguous at best.
- **CC-BY costs more than it looks.** Attribution in a mobile app means an
  in-app credits surface, a route to it, and ARB keys in ten locales; crediting
  the hosting site does not substitute for crediting the author.
- **CC 4.0 has an unresolved question underneath a paid app.** §2(a)(5)(B)
  forbids applying Effective Technological Measures that restrict a recipient's
  exercise of the licensed rights. Whether App Store FairPlay wrapping qualifies
  — and whether it counts as *you* applying it — appears to be untested. A
  copyright waiver with no downstream conditions never raises the question.
- **User-upload sites clear at the file level, not the site level.** Even
  filtering a library to CC0 means trusting each individual uploader's tag.

Generating the tones sidesteps all four. There is no third party in the chain.

## Why WAV, and why they loop

`package:alarm` plays the file with `loopAudio` on, and it must stay on — an
alarm that plays once and stops is not an alarm. Two constraints follow:

- **No encoder padding.** MP3 and AAC encoders add delay at the head and padding
  at the tail, and decoders disagree about stripping it, which is audible as a
  click at every loop junction. Uncompressed PCM has none.
- **Digital silence at both edges.** Each tone begins and ends at exactly zero,
  so the seam falls inside a silent region. `_assertSilentEdges` in the
  generator fails the render if that ever stops being true.

The files are 16-bit / 44.1 kHz mono, 7–10 seconds, approximately 7.6 MiB
in total before store packaging.

There is a third reason for WAV specifically, checked against the plugin's
native sources rather than assumed:

- **Android reaches the file through `AssetManager.openFd`**
  (`AudioService.kt`, which rewrites `assets/…` to `flutter_assets/assets/…`).
  `openFd` only works on assets the build left **uncompressed**, and the
  Android build tools' default no-compress list is extension-based. `.wav` is
  on it. A tone shipped under an extension that is not would build fine, pass
  every gate here, and throw `FileNotFoundException` on the device.
- **iOS resolves the path through `registrar.lookupKey(forAsset:)`**
  (`AlarmRingManager.swift`), which is why the `assets/` prefix is load-bearing:
  without it the same string is read as a path inside the app's Documents
  directory, and the miss is an `os_log`, not an exception.

## Platform default

On Android, the default selection uses the Android default alarm URI. On iOS
it uses the bundled Chimes WAV in both preview and ringing and is labeled
CapyWake default.

## Adding a tone later

1. Add it to `tool/generate_tones.dart`, or source it under **CC0 only** and
   record the URL, author, licence and download date in the table above.
2. Add a `AlarmSound` entry to `lib/core/alarm_sound.dart` with a path under
   `assets/sounds/` — **the `assets/` prefix is load-bearing on iOS**, where
   anything else is read as a Documents-directory path and fails silently.
3. Add its display-name key to **all ten** ARB files.
4. `alarm_sound_test.dart` asserts the file exists on disk and is covered by a
   `pubspec.yaml` asset declaration, so a tone that is not bundled fails the
   suite rather than the alarm.

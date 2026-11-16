// Renders CapyWake's bundled alarm tones as 16-bit / 44.1 kHz mono WAV
// files under `assets/sounds/`.
//
// Run from the package root:
//
//     dart run tool/generate_tones.dart
//
// **Why generated rather than sourced.** CapyWake is a paid app, so a bundled
// tone has to be clearly licensed for commercial redistribution. The stock
// "royalty-free" sites are the trap here, not the safe harbour — several bar
// redistribution inside apps outright, and CC-BY would drag an attribution
// surface into ten locales. Generating the tones removes the question: the
// shipped artefact is a plain file with no third-party rights in it. See
// `assets/sounds/LICENSES.md` and the appendix of
// `ai-orchestration/phases/phase-30-engine-sound-vibration.md`.
//
// **Why WAV.** MP3/AAC encoders add delay at the head and padding at the tail,
// and decoders disagree about stripping it — which shows up as a click at every
// loop junction (`loopAudio` is on, and must stay on: an alarm that plays once
// is not an alarm). Uncompressed PCM has no encoder padding and decodes
// identically on both platforms. ~700 KB per tone is a fair price for that.
//
// **Why each tone starts and ends at true digital silence.** Same reason: the
// loop seam lands inside a silent region, so the repeat is inaudible rather
// than a thump. [_assertSilentEdges] enforces it at render time.
//
// This is a dev-time script. It is never imported from `lib/`, ships in no
// build, and adds no dependency — the shipped artefact is the `.wav`.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// CD-quality sample rate. Both platforms decode it natively.
const int sampleRate = 44100;

/// Peak amplitude after normalisation, in [0, 1].
///
/// Short of full scale so the platform's own volume ramp has headroom and no
/// sample rounds into a clip.
const double peakAmplitude = 0.85;

/// Length of the fade applied to the very start and end of every rendered
/// tone, as a safety net under the envelopes.
const Duration edgeFade = Duration(milliseconds: 40);

/// Where the rendered tones land, relative to the package root.
const String outputDirectory = 'assets/sounds';

/// One component of a struck tone.
///
/// Real bells are inharmonic — the partials are not integer multiples of the
/// fundamental, and the high ones die away first. Both properties are what
/// separate a bell from a beep, so both are modelled explicitly.
class Partial {
  const Partial(this.ratio, this.amplitude, this.decaySeconds);

  /// Frequency as a multiple of the strike's fundamental.
  final double ratio;

  /// Starting amplitude, relative within the strike.
  final double amplitude;

  /// Time constant of this partial's exponential decay, in seconds.
  final double decaySeconds;
}

/// A single note event inside a tone.
class Strike {
  const Strike({
    required this.atSeconds,
    required this.frequency,
    required this.partials,
    this.attackSeconds = 0.004,
    this.gain = 1,
  });

  /// When the strike begins, in seconds from the start of the file.
  final double atSeconds;

  /// Fundamental frequency in Hz.
  final double frequency;

  /// The partials that make up the strike's timbre.
  final List<Partial> partials;

  /// Onset ramp. A strike that starts at full amplitude clicks; a few
  /// milliseconds removes that without softening the attack audibly.
  final double attackSeconds;

  /// Relative loudness of this strike within the tone.
  final double gain;
}

/// Handbell-like partials: a hum below the prime, a minor tierce, a quint, and
/// a nominal an octave up, with the upper partials decaying fastest.
const List<Partial> bellPartials = [
  Partial(0.5, 0.30, 3.6),
  Partial(1, 1, 2.8),
  Partial(1.2, 0.45, 1.7),
  Partial(1.5, 0.28, 1.2),
  Partial(2, 0.34, 1.4),
  Partial(2.5, 0.14, 0.7),
  Partial(3.01, 0.09, 0.5),
  Partial(4.17, 0.05, 0.3),
];

/// Softer, more harmonic partials — closer to a wooden mallet than a bell.
/// Fewer inharmonic components, so it reads as warm rather than metallic.
const List<Partial> malletPartials = [
  Partial(1, 1, 1.9),
  Partial(2, 0.32, 1.1),
  Partial(3, 0.14, 0.6),
  Partial(4.02, 0.06, 0.35),
  Partial(5.4, 0.03, 0.2),
];

/// Nearly a pure tone with a touch of octave and fifth. Used for the slow
/// swell, where any inharmonicity would read as a mistake rather than a bell.
const List<Partial> swellPartials = [
  Partial(1, 1, 5),
  Partial(2, 0.18, 4),
  Partial(3, 0.06, 3),
];

void main(List<String> args) {
  final directory = Directory(outputDirectory);
  if (!directory.existsSync()) directory.createSync(recursive: true);

  final tones = <String, Float64List>{
    'chimes': _renderChimes(),
    'morning': _renderMorning(),
    'gentle': _renderGentle(),
    'soft_mallets': _renderPhrase(
      [392, 494, 587, 494],
      [0, 0.7, 1.6, 2.4],
      malletPartials,
      .65,
    ),
    'first_light': _renderPhrase(
      [330, 440, 660],
      [0, 1.2, 2.1],
      swellPartials,
      .44,
    ),
    'glass_drops': _renderPhrase(
      [740, 880, 660, 554],
      [0, 0.35, 1.15, 2.3],
      glassPartials,
      .64,
    ),
    'wooden_knocks': _renderPhrase(
      [370, 370, 510, 370, 510],
      [0, 0.19, 0.78, 1.52, 1.72],
      woodPartials,
      .79,
    ),
    'bamboo_pulse': _renderPhrase(
      [510, 390, 510, 730, 390],
      [0, 0.45, 0.82, 1.15, 2.34],
      woodPartials,
      .76,
    ),
    'syncopated_marimba': _renderPhrase(
      [523, 784, 659, 587, 784],
      [0, 0.28, 0.84, 1.41, 1.69],
      malletPartials,
      .74,
    ),
    'mechanical_bell': _renderPhrase(
      [810, 810, 810, 810],
      [0, 0.25, 0.5, 0.75],
      glassPartials,
      .84,
    ),
    'station_signal': _renderPhrase(
      [520, 620, 520, 620],
      [0, 0.26, 1.08, 1.34],
      signalPartials,
      .84,
    ),
    'three_tone_beacon': _renderPhrase(
      [480, 660, 920, 480, 660, 920],
      [0, 0.27, 0.54, 1.43, 1.7, 1.97],
      signalPartials,
      .85,
    ),
  };

  for (final entry in tones.entries) {
    final samples = entry.value;
    _assertSilentEdges(entry.key, samples);
    final file = File('$outputDirectory/${entry.key}.wav')
      ..writeAsBytesSync(_encodeWav(samples));
    final seconds = (samples.length / sampleRate).toStringAsFixed(1);
    final kilobytes = (file.lengthSync() / 1024).round();
    stdout.writeln('wrote ${file.path}  ${seconds}s  $kilobytes KB');
  }
}

/// "Chimes" — three descending bell strikes, spaced to leave the last one room
/// to ring out before the file loops.
Float64List _renderChimes() => _render(
  durationSeconds: 9,
  strikes: const [
    // E5, C5, G4 — a descending triad. Descending reads calmer than ascending,
    // which is the register the whole product is written in.
    Strike(atSeconds: 0.05, frequency: 659.25, partials: bellPartials),
    Strike(atSeconds: 2.4, frequency: 523.25, partials: bellPartials),
    Strike(atSeconds: 4.75, frequency: 392, partials: bellPartials, gain: 0.9),
  ],
);

/// "Morning" — a soft ascending mallet figure, brighter than [_renderChimes]
/// without being urgent.
Float64List _renderMorning() => _render(
  durationSeconds: 8,
  strikes: const [
    // C5, E5, G5, C6, then the fifth again an octave down to settle it.
    Strike(atSeconds: 0.05, frequency: 523.25, partials: malletPartials),
    Strike(atSeconds: 0.42, frequency: 659.25, partials: malletPartials),
    Strike(atSeconds: 0.79, frequency: 783.99, partials: malletPartials),
    Strike(
      atSeconds: 1.16,
      frequency: 1046.5,
      partials: malletPartials,
      gain: 0.85,
    ),
    Strike(atSeconds: 3.2, frequency: 523.25, partials: malletPartials),
    Strike(atSeconds: 3.57, frequency: 659.25, partials: malletPartials),
    Strike(atSeconds: 3.94, frequency: 783.99, partials: malletPartials),
    Strike(
      atSeconds: 4.31,
      frequency: 1046.5,
      partials: malletPartials,
      gain: 0.85,
    ),
  ],
);

/// "Gentle" — two low overlapping swells with a slow attack. Not struck: the
/// amplitude rises over most of a second, so it arrives rather than starts.
Float64List _renderGentle() => _render(
  durationSeconds: 10,
  peak: .43,
  strikes: const [
    // A3 and E4 — a bare fifth, low and unhurried.
    Strike(
      atSeconds: 0.05,
      frequency: 220,
      partials: swellPartials,
      attackSeconds: 0.9,
    ),
    Strike(
      atSeconds: 0.55,
      frequency: 329.63,
      partials: swellPartials,
      attackSeconds: 1.1,
      gain: 0.6,
    ),
    Strike(
      atSeconds: 4.8,
      frequency: 220,
      partials: swellPartials,
      attackSeconds: 0.9,
      gain: 0.85,
    ),
  ],
);

const glassPartials = [
  Partial(1, 1, 0.42),
  Partial(2.76, .37, .16),
  Partial(4.09, .22, .09),
];
const woodPartials = [
  Partial(1, 1, .075),
  Partial(1.78, .56, .038),
  Partial(3.61, .22, .02),
];
const signalPartials = [
  Partial(1, 1, .22),
  Partial(2, .29, .16),
  Partial(3, .16, .08),
];

Float64List _renderPhrase(
  List<double> notes,
  List<double> beats,
  List<Partial> timbre,
  double peak,
) => _render(
  durationSeconds: 7,
  peak: peak,
  strikes: [
    for (final start in [0.05, 3.25])
      for (var index = 0; index < notes.length; index++)
        Strike(
          atSeconds: start + beats[index],
          frequency: notes[index],
          partials: timbre,
          attackSeconds: identical(timbre, swellPartials) ? .25 : .004,
        ),
  ],
);

/// Sum [strikes] into a buffer, normalise to [peakAmplitude] and fade the
/// edges to true zero.
Float64List _render({
  required double durationSeconds,
  required List<Strike> strikes,
  double peak = peakAmplitude,
}) {
  final total = (durationSeconds * sampleRate).round();
  final buffer = Float64List(total);

  for (final strike in strikes) {
    final start = (strike.atSeconds * sampleRate).round();
    for (var i = start; i < total; i++) {
      final t = (i - start) / sampleRate;
      // Linear onset ramp, then the per-partial exponential decay below.
      final attack = t < strike.attackSeconds ? t / strike.attackSeconds : 1.0;
      var sample = 0.0;
      for (final partial in strike.partials) {
        sample +=
            partial.amplitude *
            math.exp(-t / partial.decaySeconds) *
            math.sin(2 * math.pi * strike.frequency * partial.ratio * t);
      }
      buffer[i] += strike.gain * attack * sample;
    }
  }

  _normalise(buffer, peak);
  _fadeEdges(buffer);
  return buffer;
}

/// Scale [buffer] so its loudest sample sits at [peakAmplitude].
void _normalise(Float64List buffer, double targetPeak) {
  var peak = 0.0;
  for (final sample in buffer) {
    final magnitude = sample.abs();
    if (magnitude > peak) peak = magnitude;
  }
  if (peak == 0) return;
  final scale = targetPeak / peak;
  for (var i = 0; i < buffer.length; i++) {
    buffer[i] *= scale;
  }
}

/// Ramp the first and last [edgeFade] to zero.
///
/// The envelopes already decay to near-silence; this guarantees the exact zero
/// the loop seam depends on, whatever the strikes do.
void _fadeEdges(Float64List buffer) {
  final fade = math.min(
    (edgeFade.inMilliseconds * sampleRate) ~/ 1000,
    buffer.length ~/ 2,
  );
  for (var i = 0; i < fade; i++) {
    final gain = i / fade;
    buffer[i] *= gain;
    buffer[buffer.length - 1 - i] *= gain;
  }
}

/// Fail the render if a tone would not loop cleanly.
///
/// A non-zero sample at either boundary is an audible click on every repeat,
/// and it is the kind of defect no gate in this repo can hear.
void _assertSilentEdges(String name, Float64List samples) {
  const quantum = 1 / 32768;
  if (samples.first.abs() >= quantum || samples.last.abs() >= quantum) {
    throw StateError(
      '$name does not start and end at digital silence — it would click at '
      'every loop junction (first=${samples.first}, last=${samples.last})',
    );
  }
}

/// Wrap [samples] in a canonical 44-byte RIFF/WAVE header as 16-bit mono PCM.
Uint8List _encodeWav(Float64List samples) {
  const bitsPerSample = 16;
  const channels = 1;
  final dataBytes = samples.length * 2;
  final bytes = ByteData(44 + dataBytes);

  void writeAscii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataBytes, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little) // PCM header size
    ..setUint16(20, 1, Endian.little) // format: uncompressed PCM
    ..setUint16(22, channels, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little)
    ..setUint16(32, channels * bitsPerSample ~/ 8, Endian.little)
    ..setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  bytes.setUint32(40, dataBytes, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    // Asymmetric scaling: 16-bit PCM runs -32768..32767, so scaling by 32767
    // keeps a full-scale negative sample from wrapping.
    bytes.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
  }

  return bytes.buffer.asUint8List();
}

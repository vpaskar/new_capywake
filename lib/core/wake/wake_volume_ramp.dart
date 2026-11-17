import 'package:capywake/core/wake/wake_window_service.dart';
import 'package:meta/meta.dart';

/// One point on a stepped volume curve: at [offset] after the ring starts,
/// play at [volume].
///
/// Deliberately a CapyWake type rather than the alarm plugin's own step class.
/// `lib/core/` stays plugin-free, so the curve can be computed and asserted
/// with no platform binding; the data-layer adapter translates each step into
/// the plugin's equivalent at the boundary.
@immutable
class VolumeRampStep {
  const VolumeRampStep({required this.offset, required this.volume})
    : assert(volume >= 0 && volume <= 1, 'volume must be in [0, 1].');

  /// How long after the ring begins this step applies. Never negative.
  final Duration offset;

  /// The volume to play at [offset], in `[0, 1]`.
  final double volume;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VolumeRampStep &&
        other.offset == offset &&
        other.volume == volume;
  }

  @override
  int get hashCode => Object.hash(offset, volume);

  @override
  String toString() => 'VolumeRampStep(offset: $offset, volume: $volume)';
}

/// Samples a [WakeRamp] into the stepped curve the platform alarm engine
/// arms with.
///
/// The legacy built [WakeRamp] — a start volume, an end volume and an easing
/// curve per wake mode — and nothing ever read it: the engine applied a fixed
/// five-second fade to every alarm in every mode. This is the piece that was
/// missing between the two.
///
/// The platform side takes a list of `(time, volume)` stops rather than a
/// function, so a continuous curve has to be sampled. [sampleCount] fixes that
/// resolution once, here, so every mode is sampled identically and the result
/// is deterministic enough to assert.
///
/// **Reliability honesty:** this is a volume curve on a clock. It does not
/// detect sleep, and nothing here should ever be described as if it did.
abstract final class WakeVolumeRamp {
  /// How many intervals the ramp is cut into. The emitted list therefore has
  /// `sampleCount + 1` steps, including both endpoints.
  ///
  /// Twelve is chosen rather than derived: it divides a 15-minute window into
  /// 75-second stops and a 30-minute one into 150-second stops, which is finer
  /// than the ear resolves a slow fade, while staying small enough that the
  /// whole curve crosses the platform channel as a short list.
  static const int sampleCount = 12;

  /// The ring-in applied when there is no wake window to ramp across.
  ///
  /// This is what every alarm got before the wake window reached the engine,
  /// and it stays the behaviour of every alarm without a window — which is
  /// most of them. Short enough not to read as a delay, long enough not to
  /// start as a bang.
  static const Duration ringFade = Duration(seconds: 5);

  /// Sample [ramp] across [duration] into a stepped curve.
  ///
  /// Returns an **empty** list when there is nothing to ramp — either the ramp
  /// is flat (Strict, or any mode with no window) or the window has no length.
  /// The caller reads the empty list as "use the ordinary [ringFade]" rather
  /// than as an error: a flat curve expressed as a staircase would be a
  /// pointless list of identical stops, and Strict deliberately does not fade
  /// in at all — someone who chose Strict asked to be woken, and starting them
  /// quiet would be the app overriding that.
  ///
  /// The first step is always at offset zero and the last always at exactly
  /// [duration], so the ramp reaches full volume at the target time rather
  /// than somewhere near it.
  static List<VolumeRampStep> stepsFor({
    required WakeRamp ramp,
    required Duration duration,
    int samples = sampleCount,
  }) {
    assert(samples > 0, 'samples must be positive.');
    if (!ramp.isFading) return const <VolumeRampStep>[];
    if (duration <= Duration.zero) return const <VolumeRampStep>[];
    final totalMicros = duration.inMicroseconds;
    return List<VolumeRampStep>.unmodifiable(<VolumeRampStep>[
      for (var i = 0; i <= samples; i++)
        VolumeRampStep(
          offset: Duration(microseconds: totalMicros * i ~/ samples),
          volume: ramp.volumeAt(i / samples),
        ),
    ]);
  }
}

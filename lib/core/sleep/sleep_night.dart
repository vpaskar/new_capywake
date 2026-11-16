import 'package:capywake/core/sleep/sleep_stage.dart';
import 'package:meta/meta.dart';

/// One night's recorded sleep, attributed to the morning it ended on.
///
/// A night is keyed by the **local** date the sleeper woke up, so the night of
/// the 14th→15th is the 15th's night and sits on the same History row as the
/// 15th's alarm.
///
/// **[totalAsleepMinutes] is the platform's figure, never a sum of
/// [stageMinutes].** Real stage coverage is partial and overlapping: a watch
/// may report 7h asleep while its deep/light/REM rows add to 6h20, or to 7h40
/// if two devices recorded the same hour. Summing stages would produce a total
/// that contradicts the user's own Health app, so the two are kept separate and
/// the breakdown is presented as a breakdown — not as an accounting of the
/// total.
@immutable
class SleepNight {
  SleepNight({
    required this.night,
    required this.asleepAt,
    required this.wokeAt,
    required this.totalAsleepMinutes,
    required this.timeInBedMinutes,
    required this.sourceName,
    Map<SleepStage, int> stageMinutes = const {},
  }) : stageMinutes = Map.unmodifiable(stageMinutes),
       assert(
         totalAsleepMinutes >= 0,
         'totalAsleepMinutes must be >= 0.',
       ),
       assert(timeInBedMinutes >= 0, 'timeInBedMinutes must be >= 0.'),
       assert(
         night.isUtc == false,
         'night is a LOCAL midnight date key, matching '
         'HistoryDailySummary.day.',
       );

  /// Local-midnight date of the morning the sleeper woke on.
  final DateTime night;

  /// First moment scored as asleep, UTC.
  final DateTime asleepAt;

  /// Last moment scored as asleep, UTC. The end of the recording, not
  /// necessarily when the alarm rang.
  final DateTime wokeAt;

  /// The platform's own asleep total. See the class doc on why this is not
  /// derived from [stageMinutes].
  final int totalAsleepMinutes;

  /// Asleep plus in-bed-awake, where the device reported it. Equal to
  /// [totalAsleepMinutes] when it did not.
  final int timeInBedMinutes;

  /// Per-stage minutes as reported. Partial by nature — a device that scores
  /// no phases contributes only `SleepStage.asleep`, and the map is then
  /// unsuitable for a breakdown ([hasPhaseBreakdown] is false).
  final Map<SleepStage, int> stageMinutes;

  /// The device or app that recorded the night, for attribution.
  final String sourceName;

  /// Whether the recording distinguishes deep / light / REM.
  ///
  /// False for a phone-only or basic-band night, where the UI shows duration
  /// alone rather than an empty stage section.
  bool get hasPhaseBreakdown =>
      stageMinutes.keys.any((s) => s.isPhase && (stageMinutes[s] ?? 0) > 0);

  /// Minutes for [stage], or zero when the device did not report it.
  int minutesFor(SleepStage stage) => stageMinutes[stage] ?? 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SleepNight) return false;
    if (other.stageMinutes.length != stageMinutes.length) return false;
    for (final entry in stageMinutes.entries) {
      if (other.stageMinutes[entry.key] != entry.value) return false;
    }
    return other.night == night &&
        other.asleepAt == asleepAt &&
        other.wokeAt == wokeAt &&
        other.totalAsleepMinutes == totalAsleepMinutes &&
        other.timeInBedMinutes == timeInBedMinutes &&
        other.sourceName == sourceName;
  }

  @override
  int get hashCode => Object.hash(
    night,
    asleepAt,
    wokeAt,
    totalAsleepMinutes,
    timeInBedMinutes,
    sourceName,
    Object.hashAllUnordered(
      stageMinutes.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  /// Deliberately carries no durations: a night is health content.
  @override
  String toString() => 'SleepNight(night: ${night.toIso8601String()})';
}

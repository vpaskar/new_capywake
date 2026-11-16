import 'package:capywake/core/sleep/sleep_stage.dart';
import 'package:meta/meta.dart';

/// One contiguous stretch of recorded sleep, as the health store reported it.
///
/// Times are **UTC**, matching `AlarmOccurrence`. A real night arrives as many
/// of these, often overlapping when two devices recorded it.
@immutable
class SleepSegment {
  SleepSegment({
    required this.start,
    required this.end,
    required this.stage,
    required this.sourceName,
  }) : assert(!end.isBefore(start), 'A segment cannot end before it starts.');

  /// Segment start, UTC.
  final DateTime start;

  /// Segment end, UTC.
  final DateTime end;

  final SleepStage stage;

  /// The app or device that recorded this, for attribution in the UI
  /// ("from Apple Watch"). Never logged, never sent anywhere.
  final String sourceName;

  /// Whole minutes, truncated. Sub-minute segments round to zero and are
  /// dropped by the aggregator rather than inflating a total.
  int get durationMinutes => end.difference(start).inMinutes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepSegment &&
        other.start == start &&
        other.end == end &&
        other.stage == stage &&
        other.sourceName == sourceName;
  }

  @override
  int get hashCode => Object.hash(start, end, stage, sourceName);

  /// Deliberately carries no times or duration: a segment is health content.
  @override
  String toString() => 'SleepSegment(${stage.name})';
}

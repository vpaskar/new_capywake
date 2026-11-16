import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:meta/meta.dart';

/// One ringing alarm, as the surface sees it. Pure value type.
@immutable
class RingingSession {
  const RingingSession({
    required this.alarm,
    required this.occurrence,
    required this.snoozeAvailable,
    required this.isFinalAlarm,
    required this.escapeVisibility,
  });

  final Alarm alarm;
  final AlarmOccurrence occurrence;

  /// Whether Snooze may be pressed: snooze enabled AND the cap not reached.
  final bool snoozeAvailable;

  /// The ring that took the occurrence to `alarm.maxSnoozes`. Not the
  /// negation of [snoozeAvailable] — see `SnoozeService.isFinalAlarm`.
  final bool isFinalAlarm;

  /// How prominently the escape is offered. On the session, not the round:
  /// a fresh round must not demote it mid-occurrence. Once raised, it stays.
  final PuzzleEscapeVisibility escapeVisibility;

  RingingSession copyWith({
    Alarm? alarm,
    AlarmOccurrence? occurrence,
    bool? snoozeAvailable,
    bool? isFinalAlarm,
    PuzzleEscapeVisibility? escapeVisibility,
  }) => RingingSession(
    alarm: alarm ?? this.alarm,
    occurrence: occurrence ?? this.occurrence,
    snoozeAvailable: snoozeAvailable ?? this.snoozeAvailable,
    isFinalAlarm: isFinalAlarm ?? this.isFinalAlarm,
    escapeVisibility: escapeVisibility ?? this.escapeVisibility,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RingingSession &&
        other.alarm == alarm &&
        other.occurrence == occurrence &&
        other.snoozeAvailable == snoozeAvailable &&
        other.isFinalAlarm == isFinalAlarm &&
        other.escapeVisibility == escapeVisibility;
  }

  @override
  int get hashCode => Object.hash(
    alarm,
    occurrence,
    snoozeAvailable,
    isFinalAlarm,
    escapeVisibility,
  );

  @override
  String toString() =>
      'RingingSession(${alarm.id}, ${occurrence.status.name}, '
      'snooze: $snoozeAvailable, final: $isFinalAlarm, '
      'escape: ${escapeVisibility.name})';
}

import 'package:meta/meta.dart';

/// A wall-clock time of day, stored as **minutes since local midnight**
/// (0..1439). The persistence layer keeps the same shape on
/// `Alarm.targetTimeMinutes`, so this value type just gives a typed wrapper
/// the schedule engine and tests can pass around without re-validating
/// bounds at every call site.
///
/// Pure-Dart, immutable, value-equal. No `TimeOfDay` from Flutter so the
/// `lib/core/` layer stays headless (and unit-testable without binding the
/// Flutter test environment).
@immutable
class LocalTimeOfDay implements Comparable<LocalTimeOfDay> {
  /// Build from explicit `hour`/`minute`. Both must be inside the wall-clock
  /// range; we throw eagerly so a bad input (e.g. minute = 75 from a typo)
  /// fails the closest test instead of producing nonsense schedules.
  const LocalTimeOfDay({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24, 'hour must be in [0, 24).'),
      assert(minute >= 0 && minute < 60, 'minute must be in [0, 60).');

  /// Build from minutes-since-local-midnight (0..1439). This matches the
  /// integer column shape the data layer stores on `Alarm.targetTimeMinutes`.
  factory LocalTimeOfDay.fromMinutes(int totalMinutes) {
    if (totalMinutes < 0 || totalMinutes >= 24 * 60) {
      throw ArgumentError.value(
        totalMinutes,
        'totalMinutes',
        'must be in [0, ${24 * 60}).',
      );
    }
    return LocalTimeOfDay(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
  }

  /// 0..23.
  final int hour;

  /// 0..59.
  final int minute;

  /// Total minutes since local midnight (0..1439). Inverse of
  /// the [LocalTimeOfDay.fromMinutes] constructor.
  int toMinutes() => hour * 60 + minute;

  @override
  int compareTo(LocalTimeOfDay other) =>
      toMinutes().compareTo(other.toMinutes());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTimeOfDay && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

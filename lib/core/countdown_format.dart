/// How long until the next alarm, as structure rather than as a string.
///
/// The Today card answers "when does it ring" with a day line ("Rings
/// tomorrow at 07:00"). The countdown answers the follow-up question a
/// half-asleep person actually has at 22:40 — *how long is that?* — and the
/// register is reassurance, not pressure.
///
/// Two rules the calculation exists to enforce, both from the design handoff:
///
/// - **Hours and minutes only, never seconds.** A ticking second counter on a
///   surface whose whole job is to be calm would be the opposite of calm, so
///   the value this returns cannot express one.
/// - **Nothing beyond a day.** An alarm next Monday is "Rings on Monday at
///   07:00" and nothing more; "Rings in 148 hours" is arithmetic, not an
///   answer. Past `CountdownFormat.maxCountdown` this returns `null` and the
///   card simply leaves the line out, because the day line above it already
///   says it better.
///
/// The UI maps the parts to ARB plurals rather than being handed a sentence,
/// so each locale expresses its own plural rules for hours and minutes.
library;

import 'package:meta/meta.dart';

/// Whole hours and minutes remaining, floored.
@immutable
final class CountdownParts {
  const CountdownParts({required this.hours, required this.minutes})
    : assert(hours >= 0, 'hours cannot be negative'),
      assert(
        minutes >= 0 && minutes < 60,
        'minutes is the remainder after hours, so it stays in 0..59',
      );

  final int hours;
  final int minutes;

  /// Whether the remaining time rounds down to nothing.
  ///
  /// The card says "under a minute" here rather than "in 0 minutes", which
  /// is both odd to read and, for the seconds the alarm is about to fire in,
  /// simply false.
  bool get isUnderAMinute => hours == 0 && minutes == 0;

  @override
  bool operator ==(Object other) =>
      other is CountdownParts &&
      other.hours == hours &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(hours, minutes);

  @override
  String toString() => 'CountdownParts(hours: $hours, minutes: $minutes)';
}

abstract final class CountdownFormat {
  /// The longest gap the countdown will describe. At or beyond this the day
  /// line carries the answer on its own.
  static const maxCountdown = Duration(hours: 24);

  /// The time between [now] and [target], or `null` when there is no useful
  /// countdown to show — [target] is [maxCountdown] or more away, or it has
  /// already passed.
  ///
  /// Both instants are compared as absolute moments, so a caller holding
  /// local wall-clock times and a caller holding UTC get the same answer.
  static CountdownParts? until({
    required DateTime now,
    required DateTime target,
  }) {
    final remaining = target.difference(now);
    if (remaining.isNegative) return null;
    if (remaining >= maxCountdown) return null;
    return CountdownParts(
      hours: remaining.inHours,
      minutes: remaining.inMinutes % Duration.minutesPerHour,
    );
  }
}

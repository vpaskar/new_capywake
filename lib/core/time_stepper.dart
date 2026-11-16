/// Pure stepping arithmetic for the alarm-edit time control.
///
/// The alarm-edit screen sets the time with two columns of step buttons —
/// hours, and five-minute increments — rather than a spinner wheel. The wheel
/// is the fiddliest control in the flow and real alarm times sit on
/// five-minute marks, so stepping is both easier to hit and closer to what
/// people actually want.
///
/// The arithmetic lives here, Flutter-free, because the interesting part is
/// the wrap: stepping past the end of the day has to come back round to the
/// start of it, and a control that silently clamps at 23:59 instead would
/// strand somebody trying to set an alarm for just after midnight.
///
/// Times are minutes-since-local-midnight in `[0, 1439]`, the same
/// representation the data and calc layers use everywhere else.
abstract final class TimeStepper {
  /// Minutes in a day. Every result is reduced modulo this.
  static const int minutesPerDay = 24 * 60;

  /// The granularity of the minute column.
  static const int stepMinutes = 5;

  /// Move [minutes] by [delta] whole hours, wrapping around midnight.
  ///
  /// The minute part is preserved — 07:23 an hour later is 08:23, not 08:00.
  /// Stepping down from 00:00 gives 23:00, and up from 23:00 gives 00:00.
  static int stepHours(int minutes, {required int delta}) {
    _assertInRange(minutes);
    return _wrap(minutes + delta * 60);
  }

  /// Move [minutes] to the next (or previous) five-minute mark, wrapping
  /// around midnight.
  ///
  /// This *snaps* rather than adding: from 07:23 a step up gives 07:25 and a
  /// step down gives 07:20. That is the whole point of the control — it exists
  /// to land on the marks alarms actually sit on, so a time that arrived from
  /// the platform picker at 07:23 is pulled onto the grid by the first tap
  /// instead of carrying the stray three minutes forever.
  ///
  /// From a value already on a mark it behaves as plain ±5. Stepping up from
  /// 23:55 gives 00:00; stepping down from 00:00 gives 23:55.
  static int stepFiveMinutes(int minutes, {required int delta}) {
    _assertInRange(minutes);
    if (delta == 0) return minutes;
    if (delta > 0) {
      // The next mark strictly after `minutes`, then repeat for further steps.
      final next = (minutes ~/ stepMinutes + 1) * stepMinutes;
      return stepFiveMinutes(_wrap(next), delta: delta - 1);
    }
    // The previous mark strictly before `minutes`. Integer division truncates
    // toward zero, so a value already on a mark needs the extra step back.
    final onMark = minutes % stepMinutes == 0;
    final previous = onMark
        ? minutes - stepMinutes
        : (minutes ~/ stepMinutes) * stepMinutes;
    return stepFiveMinutes(_wrap(previous), delta: delta + 1);
  }

  /// Reduce any integer into `[0, 1439]`, including negatives.
  ///
  /// Dart's `%` already returns a non-negative result for a positive divisor
  /// (`-5 % 1440 == 1435`), which is exactly the wrap wanted here — unlike
  /// `remainder`, which would keep the sign and send 00:00 minus five minutes
  /// to -5.
  static int _wrap(int value) => value % minutesPerDay;

  static void _assertInRange(int minutes) {
    assert(
      minutes >= 0 && minutes < minutesPerDay,
      'minutes must be in [0, $minutesPerDay).',
    );
  }
}

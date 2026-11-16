import 'package:intl/intl.dart' as intl;

/// Pure formatter for the Today card's day-part copy.
///
/// Handles the "today / tomorrow / weekday-name" cases the next-alarm card
/// uses to describe *when* the next alarm fires, without dragging widget
/// code into the formatting layer. All weekday names go through `intl` so
/// each locale (incl. Arabic / Japanese) renders its own.
abstract final class TodayDayPart {
  /// Day-part categories the [TodayDayPart.classify] result can be in.
  ///
  /// The UI maps each category to a localized string from `app_*.arb`:
  ///
  /// - [TodayDayCategory.today] → "today" (case used by the screen)
  /// - [TodayDayCategory.tomorrow] → "tomorrow"
  /// - [TodayDayCategory.weekday] → the locale's full weekday name from
  ///   `intl` (e.g. "Monday" / "понедельник" / "月曜日"), formatted via
  ///   [TodayDayPart.weekdayName].
  static TodayDayCategory classify({
    required DateTime scheduledLocal,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDay = DateTime(
      scheduledLocal.year,
      scheduledLocal.month,
      scheduledLocal.day,
    );
    final diffDays = scheduledDay.difference(today).inDays;
    if (diffDays <= 0) return TodayDayCategory.today;
    if (diffDays == 1) return TodayDayCategory.tomorrow;
    return TodayDayCategory.weekday;
  }

  /// Format the locale's full weekday name for the given local instant.
  /// Used when [classify] returns [TodayDayCategory.weekday].
  static String weekdayName({
    required DateTime scheduledLocal,
    required String localeName,
  }) {
    return intl.DateFormat.EEEE(localeName).format(scheduledLocal);
  }
}

/// Result of [TodayDayPart.classify]. The screen looks each value up in
/// `app_*.arb` so each locale phrases it naturally.
enum TodayDayCategory { today, tomorrow, weekday }

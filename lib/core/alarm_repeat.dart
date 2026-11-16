import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';

/// The one plain-language description of an alarm's repeat schedule.
///
/// Every surface that says when an alarm repeats — the Alarms list, the Today
/// card, the alarm form's note under the day toggles — reads it from here, so
/// the three cannot describe the same set of days three ways.
///
/// **It never prints the toggle row back at the user.** "M T W T F" is what
/// the seven day buttons already show; repeating it underneath as a summary
/// says nothing and reads as a code. A summary earns its line by being
/// *language*: "Weekdays", "Every day", "Mon, Wed, Fri".
///
/// Flutter-free apart from the generated localisations, which are a plain
/// value class — the same arrangement `ReliabilityCopyService` uses, and for
/// the same reason: the wording belongs with the rule that chooses it.
abstract final class AlarmRepeatSummary {
  /// Monday..Friday, as ISO weekday numbers.
  static const Set<int> workweek = {1, 2, 3, 4, 5};

  /// Saturday and Sunday, as ISO weekday numbers.
  static const Set<int> weekend = {6, 7};

  /// Describe [weekdays] in one short sentence.
  ///
  /// An empty set is a one-time alarm, and the copy says what that actually
  /// means — it rings once and then stays off — rather than the bare label
  /// "One-time", which left people wondering whether the alarm deleted itself.
  /// (It does not: CapyWake never removes a schedule for you.)
  static String format({
    required Set<int> weekdays,
    required AppLocalizations l10n,
  }) {
    if (weekdays.isEmpty) return l10n.alarmRepeatNever;
    if (weekdays.length == 7) return l10n.alarmRepeatEveryDay;
    if (_setEquals(weekdays, workweek)) return l10n.alarmRepeatWeekdays;
    if (_setEquals(weekdays, weekend)) return l10n.alarmRepeatWeekends;

    final sorted = weekdays.toList()..sort();
    return sorted
        .map(
          (d) => AlarmFormat.shortWeekday(
            weekday: d,
            localeName: l10n.localeName,
          ),
        )
        .join(l10n.alarmRepeatDaySeparator);
  }

  static bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}

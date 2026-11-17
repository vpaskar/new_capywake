import 'package:capywake/core/models/models.dart';
import 'package:intl/intl.dart' as intl;
import 'package:meta/meta.dart';

/// A clock time split into the digits and the AM/PM marker, for surfaces
/// that style the two differently. See `PHASE_04_PRE_REVIEW.md` H1.
@immutable
class ClockTimeParts {
  const ClockTimeParts({required this.time, required this.period});

  /// The digits with their separator — "7:00", "07:00", "٧:٠٠".
  final String time;

  /// The localized AM/PM marker, or `null` when the format shows none.
  final String? period;

  @override
  bool operator ==(Object other) =>
      other is ClockTimeParts && other.time == time && other.period == period;

  @override
  int get hashCode => Object.hash(time, period);
}

/// Pure-Dart formatters for alarm metadata.
///
/// Lives in `lib/core/` so it stays Flutter-free and is unit-testable
/// without `pumpWidget`. All formatting routes through `intl` so each locale
/// uses its own conventions for clock times and weekday names.
abstract final class AlarmFormat {
  /// Format minutes-since-midnight (0..1439) as a localized clock string.
  ///
  /// `system` follows the locale's default (e.g. "07:00" in `de`, "7:00 AM"
  /// in `en_US`). `h12` and `h24` force the explicit format regardless of
  /// the locale — used by users who want a particular clock style.
  static String time({
    required int minutes,
    required String localeName,
    required TimeFormatPreference format,
  }) {
    final base = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    final pattern = switch (format) {
      TimeFormatPreference.system => null,
      TimeFormatPreference.h12 => 'h:mm a',
      TimeFormatPreference.h24 => 'HH:mm',
    };
    final fmt = pattern == null
        ? intl.DateFormat.jm(localeName)
        : intl.DateFormat(pattern, localeName);
    return fmt.format(base);
  }

  /// [time], split. Each part is formatted by `intl` in its own right, never
  /// cut out of a combined string. `period` is null when none is shown.
  static ClockTimeParts timeParts({
    required int minutes,
    required String localeName,
    required TimeFormatPreference format,
  }) {
    final base = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    final twelveHour = switch (format) {
      TimeFormatPreference.h12 => true,
      TimeFormatPreference.h24 => false,
      TimeFormatPreference.system => _localeUsesTwelveHour(localeName),
    };
    final digits = intl.DateFormat(
      twelveHour ? 'h:mm' : 'HH:mm',
      localeName,
    ).format(base);
    return ClockTimeParts(
      time: digits,
      period: twelveHour ? intl.DateFormat('a', localeName).format(base) : null,
    );
  }

  /// The locale's AM and PM markers, read from `intl` rather than written
  /// out — `tr` is "ÖÖ"/"ÖS", `ar` "ص"/"م".
  static (String, String) periodLabels({required String localeName}) {
    final fmt = intl.DateFormat('a', localeName);
    return (
      fmt.format(DateTime(2000, 1, 1, 9)),
      fmt.format(DateTime(2000, 1, 1, 21)),
    );
  }

  /// Whether the locale's default clock is 12-hour. Asked of `intl` — there
  /// is no public flag, and a hardcoded list would drift from its data.
  static bool _localeUsesTwelveHour(String localeName) {
    final afternoon = DateTime(2000, 1, 1, 13);
    final marker = intl.DateFormat('a', localeName).format(afternoon);
    return intl.DateFormat.jm(localeName).format(afternoon).contains(marker);
  }

  /// Returns the locale's *abbreviated* weekday name for the given ISO
  /// weekday (Monday = 1 .. Sunday = 7) — "Mon" in English, "Mo" in German.
  ///
  /// Used wherever a weekday is read as a word: the plain-language repeat
  /// summary ("Mon, Wed, Fri"). This was once called
  /// `narrowWeekday`, which it never was — `DateFormat.E` is the abbreviated
  /// skeleton, and the name sent the seven repeat toggles looking for a
  /// single letter and getting three.
  static String shortWeekday({
    required int weekday,
    required String localeName,
  }) {
    _checkWeekday(weekday);
    final d = _isoSundayAnchor.add(Duration(days: weekday));
    return intl.DateFormat.E(localeName).format(d);
  }

  /// Returns the locale's *narrow* weekday name for the given ISO weekday
  /// (Monday = 1 .. Sunday = 7) — "M" in English, "月" in Japanese.
  ///
  /// Not used by the repeat-day chips: the mockup's pills read "Mon", so
  /// they take [shortWeekday]. See `PHASE_04_PRE_REVIEW.md` H2.
  static String narrowWeekday({
    required int weekday,
    required String localeName,
  }) {
    _checkWeekday(weekday);
    final d = _isoSundayAnchor.add(Duration(days: weekday));
    return intl.DateFormat('EEEEE', localeName).format(d);
  }

  static void _checkWeekday(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'Weekday must be in [1, 7].',
      );
    }
  }

  /// Anchor date whose weekday is Sunday — adding `weekday` days yields a
  /// date whose ISO weekday equals the requested ISO weekday (Mon=1..Sun=7).
  /// Local-zone construction is fine: only the `weekday` field is read.
  static final DateTime _isoSundayAnchor = DateTime(2024, 12, 29);
}

import 'package:capywake/core/models/models.dart';
import 'package:intl/intl.dart' as intl;

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

  /// Returns the locale's *abbreviated* weekday name for the given ISO
  /// weekday (Monday = 1 .. Sunday = 7) — "Mon" in English, "Mo" in German.
  ///
  /// Used wherever a weekday is read as a word: the plain-language repeat
  /// summary ("Mon, Wed, Fri"). Until Phase 29 this was called
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
  /// Used for the seven repeat-day toggles, which are a fixed square and have
  /// room for one glyph. Narrow names are deliberately ambiguous (English
  /// repeats "T" and "S"), which is fine for a row of seven in weekday order
  /// and is why the summary line beneath spells the days out.
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

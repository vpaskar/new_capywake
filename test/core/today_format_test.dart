import 'package:capywake/core/today_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart' as intl;

void main() {
  setUpAll(() async {
    // Pre-load locale symbol data for the locales the weekdayName tests
    // exercise. `intl.DateFormat.EEEE('xx')` requires this for non-en locales.
    await intl.initializeDateFormatting('ru');
    await intl.initializeDateFormatting('ja');
    await intl.initializeDateFormatting('ar');
  });

  group('TodayDayPart.classify', () {
    test('same calendar day returns today', () {
      expect(
        TodayDayPart.classify(
          scheduledLocal: DateTime(2026, 5, 21, 23, 30),
          now: DateTime(2026, 5, 21, 6),
        ),
        TodayDayCategory.today,
      );
    });

    test('next calendar day returns tomorrow', () {
      expect(
        TodayDayPart.classify(
          scheduledLocal: DateTime(2026, 5, 22, 7),
          now: DateTime(2026, 5, 21, 23, 55),
        ),
        TodayDayCategory.tomorrow,
      );
    });

    test('two or more days out returns weekday', () {
      expect(
        TodayDayPart.classify(
          scheduledLocal: DateTime(2026, 5, 25, 7),
          now: DateTime(2026, 5, 21, 6),
        ),
        TodayDayCategory.weekday,
      );
    });

    test('a moment earlier the same day still classifies as today', () {
      // Defensive: `diffDays <= 0` covers a not-yet-corrected stale stream.
      expect(
        TodayDayPart.classify(
          scheduledLocal: DateTime(2026, 5, 21),
          now: DateTime(2026, 5, 21, 23, 59),
        ),
        TodayDayCategory.today,
      );
    });

    test('crossing month boundary still resolves correctly', () {
      expect(
        TodayDayPart.classify(
          scheduledLocal: DateTime(2026, 6, 1, 7),
          now: DateTime(2026, 5, 31, 23, 30),
        ),
        TodayDayCategory.tomorrow,
      );
    });
  });

  group('TodayDayPart.weekdayName', () {
    test('English Monday', () {
      expect(
        TodayDayPart.weekdayName(
          scheduledLocal: DateTime(2026, 5, 25),
          localeName: 'en',
        ),
        'Monday',
      );
    });

    test('Russian uses native weekday names', () {
      // 2026-05-25 is a Monday — Russian "понедельник".
      final name = TodayDayPart.weekdayName(
        scheduledLocal: DateTime(2026, 5, 25),
        localeName: 'ru',
      );
      expect(name.toLowerCase(), 'понедельник');
    });

    test('Japanese uses native weekday names', () {
      final name = TodayDayPart.weekdayName(
        scheduledLocal: DateTime(2026, 5, 25),
        localeName: 'ja',
      );
      expect(name, '月曜日');
    });

    test('Arabic uses native weekday names', () {
      final name = TodayDayPart.weekdayName(
        scheduledLocal: DateTime(2026, 5, 25),
        localeName: 'ar',
      );
      // Arabic Monday — the exact glyph differs by data version, so just
      // assert the name is non-empty and not the English fallback.
      expect(name, isNotEmpty);
      expect(name, isNot(equals('Monday')));
    });
  });
}

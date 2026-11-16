import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('AlarmFormat.time', () {
    test('h24 forces a 24-hour clock regardless of locale', () {
      expect(
        AlarmFormat.time(
          minutes: 7 * 60,
          localeName: 'en_US',
          format: TimeFormatPreference.h24,
        ),
        '07:00',
      );
      expect(
        AlarmFormat.time(
          minutes: 13 * 60 + 5,
          localeName: 'ja',
          format: TimeFormatPreference.h24,
        ),
        '13:05',
      );
    });

    test('h12 forces a 12-hour clock regardless of locale', () {
      final morning = AlarmFormat.time(
        minutes: 7 * 60,
        localeName: 'en_US',
        format: TimeFormatPreference.h12,
      );
      expect(morning, contains('7:00'));
      final afternoon = AlarmFormat.time(
        minutes: 13 * 60 + 5,
        localeName: 'en_US',
        format: TimeFormatPreference.h12,
      );
      expect(afternoon, contains('1:05'));
    });

    test('system follows locale conventions', () {
      // de uses 24-h via DateFormat.jm.
      expect(
        AlarmFormat.time(
          minutes: 7 * 60,
          localeName: 'de',
          format: TimeFormatPreference.system,
        ),
        '07:00',
      );
    });

    test('handles midnight and one-minute-before-midnight', () {
      expect(
        AlarmFormat.time(
          minutes: 0,
          localeName: 'en_US',
          format: TimeFormatPreference.h24,
        ),
        '00:00',
      );
      expect(
        AlarmFormat.time(
          minutes: 24 * 60 - 1,
          localeName: 'en_US',
          format: TimeFormatPreference.h24,
        ),
        '23:59',
      );
    });
  });

  group('AlarmFormat.shortWeekday', () {
    test('returns an abbreviated weekday name for ISO weekdays 1..7', () {
      for (var d = 1; d <= 7; d++) {
        final name = AlarmFormat.shortWeekday(weekday: d, localeName: 'en_US');
        expect(name, isNotEmpty);
      }
    });

    test('maps ISO weekday numbers to the right days', () {
      // Monday = 1 .. Sunday = 7. A silent off-by-one here would print the
      // wrong day in every repeat summary in the app.
      expect(AlarmFormat.shortWeekday(weekday: 1, localeName: 'en_US'), 'Mon');
      expect(AlarmFormat.shortWeekday(weekday: 3, localeName: 'en_US'), 'Wed');
      expect(AlarmFormat.shortWeekday(weekday: 7, localeName: 'en_US'), 'Sun');
    });

    test('produces locale-specific names', () {
      final monEn = AlarmFormat.shortWeekday(weekday: 1, localeName: 'en_US');
      final monDe = AlarmFormat.shortWeekday(weekday: 1, localeName: 'de');
      final monJa = AlarmFormat.shortWeekday(weekday: 1, localeName: 'ja');
      // Monday -> "Mon" in en, "Mo" in de, "月" in ja.
      expect(monEn, isNot(equals(monDe)));
      expect(monJa, isNot(equals(monEn)));
    });

    test('rejects out-of-range weekdays', () {
      expect(
        () => AlarmFormat.shortWeekday(weekday: 0, localeName: 'en_US'),
        throwsArgumentError,
      );
      expect(
        () => AlarmFormat.shortWeekday(weekday: 8, localeName: 'en_US'),
        throwsArgumentError,
      );
    });
  });

  group('AlarmFormat.narrowWeekday', () {
    test('returns a single-glyph name in English', () {
      // The seven repeat toggles are a fixed square with room for one glyph.
      // English narrow names are ambiguous on purpose ("T" is both Tuesday
      // and Thursday); the summary line under the row is what disambiguates.
      expect(AlarmFormat.narrowWeekday(weekday: 1, localeName: 'en_US'), 'M');
      expect(AlarmFormat.narrowWeekday(weekday: 2, localeName: 'en_US'), 'T');
      expect(AlarmFormat.narrowWeekday(weekday: 4, localeName: 'en_US'), 'T');
      expect(AlarmFormat.narrowWeekday(weekday: 7, localeName: 'en_US'), 'S');
    });

    test('is shorter than the abbreviated name where the script allows', () {
      for (final locale in ['en_US', 'de', 'fr', 'ru']) {
        final narrow = AlarmFormat.narrowWeekday(
          weekday: 3,
          localeName: locale,
        );
        final short = AlarmFormat.shortWeekday(weekday: 3, localeName: locale);
        expect(narrow, isNotEmpty, reason: locale);
        expect(narrow.length, lessThanOrEqualTo(short.length), reason: locale);
      }
    });

    test('produces a name for every locale the app ships', () {
      for (final locale in [
        'en',
        'de',
        'ru',
        'es',
        'tr',
        'fr',
        'it',
        'pt',
        'ar',
        'ja',
      ]) {
        for (var d = 1; d <= 7; d++) {
          expect(
            AlarmFormat.narrowWeekday(weekday: d, localeName: locale),
            isNotEmpty,
            reason: '$locale weekday $d',
          );
        }
      }
    });

    test('rejects out-of-range weekdays', () {
      expect(
        () => AlarmFormat.narrowWeekday(weekday: 0, localeName: 'en_US'),
        throwsArgumentError,
      );
      expect(
        () => AlarmFormat.narrowWeekday(weekday: 8, localeName: 'en_US'),
        throwsArgumentError,
      );
    });
  });
}

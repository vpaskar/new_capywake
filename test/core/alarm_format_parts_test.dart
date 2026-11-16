import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _locales = ['en', 'de', 'ru', 'es', 'tr', 'fr', 'it', 'pt', 'ar', 'ja'];

void main() {
  setUpAll(initializeDateFormatting);

  group('AlarmFormat.timeParts', () {
    test('h12 splits the marker away from the digits in every locale', () {
      for (final locale in _locales) {
        final parts = AlarmFormat.timeParts(
          minutes: 7 * 60,
          localeName: locale,
          format: TimeFormatPreference.h12,
        );
        expect(parts.period, isNotNull, reason: locale);
        expect(parts.period, isNotEmpty, reason: locale);
        expect(parts.time, isNot(contains(parts.period)), reason: locale);
      }
    });

    test('h24 never produces a marker', () {
      for (final locale in _locales) {
        final parts = AlarmFormat.timeParts(
          minutes: 21 * 60 + 30,
          localeName: locale,
          format: TimeFormatPreference.h24,
        );
        expect(parts.period, isNull, reason: locale);
      }
    });

    test('the parts carry the same text time() renders, ignoring spacing', () {
      // `intl` uses a narrow no-break space (U+202F) in some locales.
      String squash(String s) =>
          s.replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();

      for (final locale in _locales) {
        for (final format in TimeFormatPreference.values) {
          final parts = AlarmFormat.timeParts(
            minutes: 21 * 60 + 30,
            localeName: locale,
            format: format,
          );
          final joined = parts.period == null
              ? parts.time
              : '${parts.time} ${parts.period}';
          expect(
            squash(joined),
            squash(
              AlarmFormat.time(
                minutes: 21 * 60 + 30,
                localeName: locale,
                format: format,
              ),
            ),
            reason: '$locale/$format',
          );
        }
      }
    });

    test('English h12 reads 7:00 AM and 9:30 PM', () {
      final morning = AlarmFormat.timeParts(
        minutes: 7 * 60,
        localeName: 'en',
        format: TimeFormatPreference.h12,
      );
      expect(morning.time, '7:00');
      expect(morning.period, 'AM');

      final evening = AlarmFormat.timeParts(
        minutes: 21 * 60 + 30,
        localeName: 'en',
        format: TimeFormatPreference.h12,
      );
      expect(evening.time, '9:30');
      expect(evening.period, 'PM');
    });

    test('a non-Latin marker is carried whole, not transliterated', () {
      final arabic = AlarmFormat.timeParts(
        minutes: 7 * 60,
        localeName: 'ar',
        format: TimeFormatPreference.h12,
      );
      expect(arabic.period, 'ص');

      final japanese = AlarmFormat.timeParts(
        minutes: 21 * 60,
        localeName: 'ja',
        format: TimeFormatPreference.h12,
      );
      expect(japanese.period, '午後');
    });

    test('system follows the locale, 12-hour for en and 24-hour for de', () {
      expect(
        AlarmFormat.timeParts(
          minutes: 7 * 60,
          localeName: 'en',
          format: TimeFormatPreference.system,
        ).period,
        isNotNull,
      );
      expect(
        AlarmFormat.timeParts(
          minutes: 7 * 60,
          localeName: 'de',
          format: TimeFormatPreference.system,
        ).period,
        isNull,
      );
    });

    test('midnight and noon land in the right half of the day', () {
      final midnight = AlarmFormat.timeParts(
        minutes: 0,
        localeName: 'en',
        format: TimeFormatPreference.h12,
      );
      expect(midnight.time, '12:00');
      expect(midnight.period, 'AM');

      final noon = AlarmFormat.timeParts(
        minutes: 12 * 60,
        localeName: 'en',
        format: TimeFormatPreference.h12,
      );
      expect(noon.time, '12:00');
      expect(noon.period, 'PM');
    });

    test('the last minute of the day is 11:59 PM', () {
      final parts = AlarmFormat.timeParts(
        minutes: 24 * 60 - 1,
        localeName: 'en',
        format: TimeFormatPreference.h12,
      );
      expect(parts.time, '11:59');
      expect(parts.period, 'PM');
    });

    test('value equality', () {
      const a = ClockTimeParts(time: '7:00', period: 'AM');
      const b = ClockTimeParts(time: '7:00', period: 'AM');
      const c = ClockTimeParts(time: '7:00', period: null);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}

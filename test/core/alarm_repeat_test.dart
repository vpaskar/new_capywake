import 'package:capywake/core/alarm_repeat.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<AppLocalizations> _l10n([Locale locale = const Locale('en')]) {
  return AppLocalizations.delegate.load(locale);
}

/// Every locale the app ships, so a summary cannot silently go empty in one.
const _shippedLocales = [
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
];

void main() {
  setUpAll(initializeDateFormatting);

  group('AlarmRepeatSummary.format', () {
    test('an empty set says what a one-time alarm actually does', () async {
      final l10n = await _l10n();
      expect(
        AlarmRepeatSummary.format(weekdays: const {}, l10n: l10n),
        'Once, then it stays off',
      );
    });

    test('all seven days', () async {
      final l10n = await _l10n();
      expect(
        AlarmRepeatSummary.format(
          weekdays: const {1, 2, 3, 4, 5, 6, 7},
          l10n: l10n,
        ),
        'Every day',
      );
    });

    test('the working week', () async {
      final l10n = await _l10n();
      expect(
        AlarmRepeatSummary.format(
          weekdays: AlarmRepeatSummary.workweek,
          l10n: l10n,
        ),
        'Weekdays',
      );
    });

    test('the weekend', () async {
      final l10n = await _l10n();
      expect(
        AlarmRepeatSummary.format(
          weekdays: AlarmRepeatSummary.weekend,
          l10n: l10n,
        ),
        'Weekends',
      );
    });

    test('a custom set spells the days out, in weekday order', () async {
      final l10n = await _l10n();
      expect(
        // Deliberately out of order on the way in: the summary sorts.
        AlarmRepeatSummary.format(weekdays: const {5, 1, 3}, l10n: l10n),
        'Mon, Wed, Fri',
      );
    });

    test('a single day is just that day', () async {
      final l10n = await _l10n();
      expect(
        AlarmRepeatSummary.format(weekdays: const {7}, l10n: l10n),
        'Sun',
      );
    });

    test('never prints the toggle row back as a summary', () async {
      // The whole point of this function. A custom set must read as language,
      // not as the seven single letters already shown above it on the form.
      final l10n = await _l10n();
      final summary = AlarmRepeatSummary.format(
        weekdays: const {1, 2, 3, 4, 5, 6},
        l10n: l10n,
      );
      expect(summary, isNot('M T W T F S'));
      expect(summary, contains('Mon'));
      expect(summary, contains(','));
    });

    test('a near-miss of the working week is not called "Weekdays"', () async {
      final l10n = await _l10n();
      expect(
        AlarmRepeatSummary.format(
          weekdays: const {1, 2, 3, 4},
          l10n: l10n,
        ),
        isNot('Weekdays'),
      );
      expect(
        AlarmRepeatSummary.format(
          weekdays: const {1, 2, 3, 4, 5, 6},
          l10n: l10n,
        ),
        isNot('Weekdays'),
      );
    });

    test('the named sets are translated, not day lists', () async {
      final de = await _l10n(const Locale('de'));
      expect(
        AlarmRepeatSummary.format(
          weekdays: AlarmRepeatSummary.workweek,
          l10n: de,
        ),
        'Werktags',
      );
      expect(
        AlarmRepeatSummary.format(weekdays: const {}, l10n: de),
        'Einmal, danach bleibt er aus',
      );
    });

    test("a custom set uses the locale's own day names", () async {
      final de = await _l10n(const Locale('de'));
      final summary = AlarmRepeatSummary.format(
        weekdays: const {1, 3},
        l10n: de,
      );
      expect(summary, 'Mo, Mi');
    });

    test('every shipped locale produces a non-empty summary for every '
        'branch', () async {
      const branches = <Set<int>>[
        {},
        {1, 2, 3, 4, 5, 6, 7},
        {1, 2, 3, 4, 5},
        {6, 7},
        {2, 4},
        {3},
      ];
      for (final name in _shippedLocales) {
        final l10n = await _l10n(Locale(name));
        for (final days in branches) {
          final summary = AlarmRepeatSummary.format(
            weekdays: days,
            l10n: l10n,
          );
          expect(summary.trim(), isNotEmpty, reason: '$name / $days');
        }
      }
    });
  });
}

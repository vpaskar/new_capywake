import 'package:capywake/app/bootstrap.dart';
import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nothing in `lib/` called `initializeDateFormatting`: the ported tests did
/// it themselves, so they passed while the app would throw. Asserts lib does.
void main() {
  group('bootstrap', () {
    testWidgets('leaves intl able to format a time in every locale', (
      tester,
    ) async {
      await bootstrap();

      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          () => AlarmFormat.time(
            minutes: 7 * 60,
            localeName: locale.languageCode,
            format: TimeFormatPreference.system,
          ),
          returnsNormally,
          reason:
              'DateFormat throws for ${locale.languageCode} — bootstrap() did '
              'not load its symbol data.',
        );
      }
    });

    testWidgets('leaves intl able to name a weekday in every locale', (
      tester,
    ) async {
      await bootstrap();

      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          () => AlarmFormat.shortWeekday(
            weekday: 1,
            localeName: locale.languageCode,
          ),
          returnsNormally,
          reason: 'Weekday naming throws for ${locale.languageCode}.',
        );
      }
    });

    testWidgets('is safe to call more than once', (tester) async {
      await bootstrap();
      await expectLater(bootstrap(), completes);
    });
  });
}

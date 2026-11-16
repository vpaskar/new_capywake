import 'package:capywake/core/alarm_dismiss_summary.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _l10n([Locale locale = const Locale('en')]) {
  return AppLocalizations.delegate.load(locale);
}

/// Every locale the app ships, so a label cannot silently go empty in one.
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
  group('AlarmDismissSummary', () {
    test('names each dismiss method in English', () async {
      final l10n = await _l10n();
      expect(
        AlarmDismissSummary.format(
          method: DismissMethod.normalButton,
          l10n: l10n,
        ),
        'Tap to stop',
      );
      expect(
        AlarmDismissSummary.format(
          method: DismissMethod.holdToDismiss,
          l10n: l10n,
        ),
        'Press and hold',
      );
      expect(
        AlarmDismissSummary.format(method: DismissMethod.puzzle, l10n: l10n),
        'Solve a puzzle',
      );
    });

    // The switch is exhaustive over the enum, so a method added later without
    // a label fails to compile rather than rendering blank. This guards the
    // other half: that every shipped locale actually translated all three.
    test('every method has non-empty copy in every shipped locale', () async {
      for (final tag in _shippedLocales) {
        final l10n = await _l10n(Locale(tag));
        for (final method in DismissMethod.values) {
          final label = AlarmDismissSummary.format(method: method, l10n: l10n);
          expect(
            label.trim(),
            isNotEmpty,
            reason: 'locale $tag has no label for $method',
          );
        }
      }
    });

    test('the three methods read differently within a locale', () async {
      for (final tag in _shippedLocales) {
        final l10n = await _l10n(Locale(tag));
        final labels = {
          for (final method in DismissMethod.values)
            AlarmDismissSummary.format(method: method, l10n: l10n),
        };
        expect(
          labels,
          hasLength(DismissMethod.values.length),
          reason: 'locale $tag reuses one label for two dismiss methods',
        );
      }
    });

    test(
      'reads natively in German rather than as the English string',
      () async {
        final de = await _l10n(const Locale('de'));
        final en = await _l10n();
        for (final method in DismissMethod.values) {
          expect(
            AlarmDismissSummary.format(method: method, l10n: de),
            isNot(AlarmDismissSummary.format(method: method, l10n: en)),
            reason: '$method was left untranslated in German',
          );
        }
      },
    );
  });
}

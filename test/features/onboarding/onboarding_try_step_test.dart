import 'dart:io';

import 'package:capywake/features/onboarding/steps/onboarding_try_step.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('renders the three spoken examples', (tester) async {
    await tester.pumpWidget(_wrap(const OnboardingTryStep()));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingTryStep)),
    );

    expect(find.text(l10n.onboardingArithmeticExample), findsOneWidget);
    expect(find.text(l10n.onboardingSequenceExample), findsOneWidget);
    expect(find.text(l10n.onboardingOperatorExample), findsOneWidget);
    expect(find.text(l10n.onboardingPuzzleTitle), findsOneWidget);
  });

  test('the try step is static — it imports no puzzle generator (L2)', () {
    final imports =
        File('lib/features/onboarding/steps/onboarding_try_step.dart')
            .readAsLinesSync()
            .where((l) => l.trimLeft().startsWith('import '))
            .join('\n');
    expect(
      imports.contains('puzzle_generator'),
      isFalse,
      reason: 'the practice step must not wire the game engine',
    );
    expect(imports.contains('puzzle_round'), isFalse);
  });
}

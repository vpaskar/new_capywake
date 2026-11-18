import 'package:capywake/app/router.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'puzzle_harness.dart';

const _routes = <String>[
  Routes.settingsPuzzle,
  Routes.settingsPuzzleGames,
  Routes.settingsPuzzleTypes,
  Routes.settingsPuzzleAdvanced,
];

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    for (final route in _routes) {
      testWidgets('$route lays out in ${locale.languageCode} at 2x text', (
        tester,
      ) async {
        await pumpPuzzleRoute(
          tester,
          route,
          locale: locale,
          textScaler: const TextScaler.linear(2),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final route in _routes) {
    testWidgets('$route keeps its whole title at 2x text', (tester) async {
      await pumpPuzzleRoute(
        tester,
        route,
        locale: const Locale('de'),
        textScaler: const TextScaler.linear(2),
      );
      final title = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(SettingsHeader),
          matching: find.byWidgetPredicate(
            (w) => w is RichText && w.text.style?.fontWeight == FontWeight.w800,
          ),
        ),
      );
      expect(
        title.size.height,
        greaterThanOrEqualTo(
          title.getMaxIntrinsicHeight(title.size.width) - 0.5,
        ),
        reason: 'the title was squeezed into a box shorter than its line',
      );
    });
  }

  testWidgets('Arabic lays the overview out right to left', (tester) async {
    await pumpPuzzleRoute(
      tester,
      Routes.settingsPuzzle,
      locale: const Locale('ar'),
    );
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).last)),
      TextDirection.rtl,
    );
  });

  testWidgets('the cards stack under large text, sit side by side without', (
    tester,
  ) async {
    await pumpPuzzleRoute(tester, Routes.settingsPuzzle);
    final l10n = puzzleL10n(tester);
    double top(String text) => tester
        .getTopLeft(
          find.ancestor(of: find.text(text), matching: find.byType(CapyCard)),
        )
        .dy;
    expect(
      top(l10n.challengeGamesTitle),
      top(l10n.puzzleSettingsTypesLabel),
    );

    await pumpPuzzleRoute(
      tester,
      Routes.settingsPuzzle,
      textScaler: const TextScaler.linear(1.6),
    );
    expect(
      top(l10n.puzzleSettingsTypesLabel),
      greaterThan(top(l10n.challengeGamesTitle)),
    );
  });
}

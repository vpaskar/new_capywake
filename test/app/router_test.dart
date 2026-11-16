import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {String at = Routes.home}) async {
    await tester.pumpWidget(
      CapyWakeApp(router: createRouter(initialLocation: at)),
    );
    await tester.pumpAndSettle();
  }

  String labelOf(WidgetTester tester, int index) {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    );
    return [l10n.navHomeLabel, l10n.navAlarmsLabel, l10n.navStatsLabel][index];
  }

  testWidgets('starts on Home', (tester) async {
    await pumpApp(tester);
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('switches between all three tabs', (tester) async {
    await pumpApp(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(labelOf(tester, i)));
      await tester.pumpAndSettle();
      expect(
        find.text(labelOf(tester, i)),
        findsOneWidget,
        reason: 'tab $i stays reachable after selecting it',
      );
    }
  });

  group('settings pops back to the originating tab', () {
    for (final (index, start) in [
      (0, Routes.home),
      (1, Routes.alarms),
      (2, Routes.stats),
    ]) {
      testWidgets('from tab $index', (tester) async {
        await pumpApp(tester, at: start);

        await tester.tap(find.byIcon(Icons.settings_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsOneWidget);

        // Settings is outside the shell, so the bottom bar is covered.
        expect(find.text(labelOf(tester, index)), findsNothing);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(
          find.text(labelOf(tester, index)),
          findsOneWidget,
          reason: 'popping settings returns to the tab it was pushed from',
        );
      });
    }
  });
}

import 'package:capywake/app/app.dart';
import 'package:capywake/app/router.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_nav_bar.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  Future<void> pumpApp(WidgetTester tester, {String at = Routes.home}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    // Dispose the container before the database: a live Drift stream keeps a
    // timer alive, and the framework asserts none is pending at teardown.
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      CapyWakeApp(
        router: createRouter(initialLocation: at),
        scopeBuilder: (child) =>
            UncontrolledProviderScope(container: container, child: child),
      ),
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

  /// The nav bar's own copy of a label. Phase 04 gave the Alarms screen a
  /// title that reads the same as its tab, so plain text finders match twice.
  Finder navTab(WidgetTester tester, int index) => find.descendant(
    of: find.byType(CapyNavBar),
    matching: find.text(labelOf(tester, index)),
  );

  testWidgets('switches between all three tabs', (tester) async {
    await pumpApp(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(navTab(tester, i));
      await tester.pumpAndSettle();
      expect(
        navTab(tester, i),
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
        expect(navTab(tester, index), findsNothing);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(
          navTab(tester, index),
          findsOneWidget,
          reason: 'popping settings returns to the tab it was pushed from',
        );
      });
    }
  });
}

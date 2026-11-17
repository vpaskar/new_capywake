import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/stats/stats_providers.dart';
import 'package:capywake/features/stats/stats_segment_switcher.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class StatsHarness {
  StatsHarness({required this.db, required this.container});

  final AppDatabase db;
  final ProviderContainer container;
}

/// Pump the Stats tab at the mockup's own geometry, 393x852 at 3x, against
/// the real router and provider graph with an in-memory database.
Future<StatsHarness> pumpStats(
  WidgetTester tester, {
  List<Alarm> alarms = const [],
  List<AlarmOccurrence> occurrences = const [],
  DateTime? now,
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final clock = now ?? DateTime(2026, 11, 17, 9, 41);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      statsClockProvider.overrideWithValue(() => clock),
    ],
  );
  addTearDown(container.dispose);

  final repository = container.read(capywakeRepositoryProvider);
  for (final alarm in alarms) {
    await repository.upsertAlarm(alarm);
  }
  for (final occurrence in occurrences) {
    await repository.upsertOccurrence(occurrence);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: createRouter(initialLocation: Routes.stats),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return StatsHarness(db: db, container: container);
}

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

/// Tap a segment by label, scoped to the switcher: "Alarms" is also a nav-bar
/// tab, so an unscoped `find.text` matches two widgets and cannot be tapped.
Future<void> tapSegment(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(StatsSegmentSwitcher),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

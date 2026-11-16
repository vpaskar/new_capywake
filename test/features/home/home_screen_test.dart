import 'dart:io';

import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/features/home/game_rail.dart';
import 'package:capywake/features/home/home_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Alarm _alarm({bool enabled = true, int minutes = 7 * 60}) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: 'Workdays',
    enabled: enabled,
    targetTimeMinutes: minutes,
    repeatWeekdays: const {1, 2, 3, 4, 5},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

/// Pumps Home against a real in-memory database, so the empty state is the
/// genuine "no rows" case rather than a stubbed null.
Future<AppDatabase> _pumpHome(
  WidgetTester tester, {
  List<Alarm> seed = const [],
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);

  for (final alarm in seed) {
    await container.read(capywakeRepositoryProvider).upsertAlarm(alarm);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: HomeScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

void main() {
  // bootstrap() does this in the app; without it DateFormat throws.
  // Phase 03 found lib/ never called it — only the ported tests did.
  setUpAll(initializeDateFormatting);

  // The empty state is the DEFAULT, not a fallback — a fresh install has no
  // alarm — so it is asserted first, before any populated case.
  group('Home with no alarms — the state the app ships in', () {
    testWidgets('renders the empty next-alarm copy', (tester) async {
      await _pumpHome(tester);

      expect(find.text('No alarm set'), findsOneWidget);
      expect(
        find.textContaining('When you add an alarm'),
        findsOneWidget,
      );
    });

    testWidgets('shows no toggle, because there is nothing to toggle', (
      tester,
    ) async {
      await _pumpHome(tester);
      expect(find.byType(CapyToggle), findsNothing);
    });

    testWidgets('still shows the rail, the CTA and the meadow', (tester) async {
      await _pumpHome(tester);

      expect(find.byType(GameRail), findsOneWidget);
      expect(find.text('Set an alarm'), findsOneWidget);
      expect(find.byType(MeadowFooter), findsOneWidget);
    });

    testWidgets('shows no clock-shaped text anywhere', (tester) async {
      await _pumpHome(tester);

      final clock = RegExp(r'\d{1,2}:\d{2}');
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where(clock.hasMatch);
      expect(
        texts,
        isEmpty,
        reason: 'An empty Home must not display a time: $texts',
      );
    });
  });

  group('Home with an alarm', () {
    testWidgets('shows the time and the repeat summary', (tester) async {
      await _pumpHome(tester, seed: [_alarm()]);

      // CLDR separates time from day period with U+202F, not a plain space.
      // Spelled out so this cannot be "fixed" by typing an ordinary space.
      const narrowNoBreakSpace = '\u202f';
      expect(find.text('7:00${narrowNoBreakSpace}AM'), findsOneWidget);
      expect(find.text('Weekdays'), findsOneWidget);
    });

    testWidgets('shows the toggle in its enabled state', (tester) async {
      await _pumpHome(tester, seed: [_alarm()]);

      final toggle = tester.widget<CapyToggle>(find.byType(CapyToggle));
      expect(toggle.value, isTrue);
    });

    testWidgets('toggling writes through the repository', (tester) async {
      final db = await _pumpHome(tester, seed: [_alarm()]);

      await tester.tap(find.byType(CapyToggle));
      await tester.pumpAndSettle();

      final rows = await db.select(db.alarms).get();
      expect(rows.single.enabled, isFalse);
    });
  });

  group('content integrity', () {
    test('lib/features/home holds no clock or weekday literal', () {
      final clock = RegExp(r"'\s*\d{1,2}:\d{2}");
      final weekday = RegExp("'(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[^']*'");

      for (final file in Directory(
        'lib/features/home',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        expect(
          clock.hasMatch(source),
          isFalse,
          reason: '${file.path} contains a clock-shaped literal',
        );
        expect(
          weekday.hasMatch(source),
          isFalse,
          reason: '${file.path} contains a weekday literal',
        );
      }
    });
  });

  // The architecture plan names 320pt and 430pt and says every UI phase
  // checks three widths. Nothing ever did; Home is the first that can.
  group('viewport widths', () {
    for (final size in const [
      Size(320, 568),
      Size(393, 852),
      Size(430, 932),
    ]) {
      testWidgets('renders without overflow at ${size.width}pt', (
        tester,
      ) async {
        await _pumpHome(tester, seed: [_alarm()], size: size);

        expect(tester.takeException(), isNull);
        expect(find.byType(GameRail), findsOneWidget);
        expect(find.byType(CapyToggle), findsOneWidget);
        expect(find.text('Set an alarm'), findsOneWidget);
        expect(find.text('My Stats'), findsOneWidget);
      });
    }
  });

  group('Tier A block positions', () {
    testWidgets('card, CTA and rail sit where 01_HOME.png puts them', (
      tester,
    ) async {
      // A cheap regression guard only: Tier A is decided by capture.sh and
      // compare.dart on a real capture, never by a synthetic viewport.
      await _pumpHome(tester, seed: [_alarm()]);

      final cta = tester.getRect(find.text('Set an alarm'));
      final rail = tester.getRect(find.byType(GameRail));
      expect(cta.top, lessThan(rail.top));

      final ctaHeight = tester.getSize(find.text('Set an alarm')).height;
      expect(ctaHeight, greaterThan(0));
    });
  });
}

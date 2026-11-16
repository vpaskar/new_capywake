import 'package:capywake/features/alarms/edit/weekday_chip_row.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<List<int>> _pump(
  WidgetTester tester, {
  Set<int> selected = const {},
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final taps = <int>[];
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: WeekdayChipRow(selected: selected, onToggle: taps.add),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('shows the abbreviated name, not a single letter', (
    tester,
  ) async {
    await _pump(tester);

    // `03_ADD_EDIT_ALARM.png` draws ~48pt pills reading "Mon", so these take
    // AlarmFormat.shortWeekday. narrowWeekday's doc claimed otherwise.
    for (final name in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });

  testWidgets('starts on Monday, the ISO order the model uses', (
    tester,
  ) async {
    await _pump(tester);

    final monday = tester.getTopLeft(find.text('Mon'));
    final sunday = tester.getTopLeft(find.text('Sun'));
    expect(monday.dx, lessThan(sunday.dx));
  });

  testWidgets('tapping a chip reports its ISO weekday', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Wed'));
    await tester.tap(find.text('Sun'));

    expect(taps, [3, 7]);
  });

  testWidgets('a selected chip is marked selected for screen readers', (
    tester,
  ) async {
    await _pump(tester, selected: const {1});

    final semantics = tester.getSemantics(find.text('Mon'));
    expect(semantics.flagsCollection.isSelected.name, 'isTrue');
  });

  testWidgets('an unselected chip is not marked selected', (tester) async {
    await _pump(tester, selected: const {1});

    final semantics = tester.getSemantics(find.text('Tue'));
    expect(semantics.flagsCollection.isSelected.name, 'isFalse');
  });

  testWidgets('German uses its own abbreviations', (tester) async {
    await _pump(tester, locale: const Locale('de'));
    expect(find.text('Mo'), findsOneWidget);
  });

  testWidgets('reflows at 2x text instead of clipping the names', (
    tester,
  ) async {
    await _pump(tester, textScaler: const TextScaler.linear(2));

    expect(tester.takeException(), isNull);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
  });

  testWidgets('the painted chip matches the mockup height', (tester) async {
    await _pump(tester);

    // Measured from what renders, not from the constant: Phase 03's card was
    // built at 167pt against a mockup's 65 because nobody checked.
    final painted = tester.getRect(
      find.ancestor(of: find.text('Mon'), matching: find.byType(Container)),
    );
    expect(
      painted.height,
      closeTo(WeekdayChipRow.chipHeight, 4),
      reason: 'Tier A binds the chip at the mockup height within +-4pt',
    );
  });

  testWidgets('every chip is reachable at 44pt', (tester) async {
    await _pump(tester);

    // The mockup paints 31.8pt. A half-asleep user still has to hit it, so
    // the tappable region is grown rather than the paint.
    final tappable = tester.getRect(
      find.ancestor(of: find.text('Mon'), matching: find.byType(InkWell)),
    );
    expect(tappable.height, greaterThanOrEqualTo(44));
  });
}

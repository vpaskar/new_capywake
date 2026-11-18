import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/dev/demo_data.dart';
import 'package:capywake/dev/dev_tools_button.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _pump(WidgetTester tester, {required bool enabled}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        devToolsEnabledProvider.overrideWithValue(enabled),
        devToolsClockProvider.overrideWithValue(
          () => DateTime(2026, 11, 18, 12),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: DevToolsButton())),
    ),
  );
  return db;
}

void main() {
  test('is on exactly in debug builds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(devToolsEnabledProvider), kDebugMode);
  });

  testWidgets('draws nothing when disabled', (tester) async {
    await _pump(tester, enabled: false);
    expect(find.text('Developer tools'), findsNothing);
  });

  testWidgets('adds and removes demo data from the sheet', (tester) async {
    final db = await _pump(tester, enabled: true);

    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Add demo data'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('Demo data added'), findsOneWidget);
    final added = await tester.runAsync(() => db.select(db.alarms).get());
    expect(added!.every((a) => a.id.startsWith(DemoData.idPrefix)), isTrue);
    expect(added, isNotEmpty);

    await tester.tap(find.text('Developer tools'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Remove demo data'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    final left = await tester.runAsync(() => db.select(db.alarms).get());
    expect(left, isEmpty);
  });
}

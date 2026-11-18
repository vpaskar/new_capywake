import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/features/alarms/edit/dismiss_method_section.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'alarm_edit_screen_test.dart' show pumpEdit, tapSave, tapVisible;

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
  tester.element(find.byType(DismissMethodSection)),
);

Finder _toggle(String label) =>
    find.byWidgetPredicate((w) => w is CapyToggle && w.semanticLabel == label);

Future<void> _customPuzzle(WidgetTester tester) async {
  final l10n = _l10n(tester);
  await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
  await tapVisible(tester, _toggle(l10n.alarmPuzzleUseDefaultsLabel));
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('the pool picker shows only for an alarm with its own settings', (
    tester,
  ) async {
    await pumpEdit(tester);
    final l10n = _l10n(tester);
    await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
    expect(find.text(l10n.alarmChallengePoolLabel), findsNothing);

    await tapVisible(tester, _toggle(l10n.alarmPuzzleUseDefaultsLabel));
    expect(find.text(l10n.alarmChallengePoolLabel), findsOneWidget);
  });

  testWidgets('an alarm can be set to one specific game', (tester) async {
    final harness = await pumpEdit(tester);
    await _customPuzzle(tester);

    await tapVisible(tester, _toggle('Memory Hideout'));
    await tapVisible(tester, _toggle('Puzzles'));
    await tapSave(tester);

    final stored = (await harness.repository.listAlarms()).single;
    expect(stored.puzzleOverride!.enabledGames, {'memory_hideout'});
    expect(stored.puzzleOverride!.includePuzzles, isFalse);
  });

  testWidgets('a subset of games keeps the puzzles', (tester) async {
    final harness = await pumpEdit(tester);
    await _customPuzzle(tester);

    await tapVisible(tester, _toggle('Catch the Capy'));
    await tapVisible(tester, _toggle('Memory Hideout'));
    await tapSave(tester);

    final stored = (await harness.repository.listAlarms()).single;
    expect(stored.puzzleOverride!.enabledGames, {
      'catch_the_capy',
      'memory_hideout',
    });
    expect(stored.puzzleOverride!.includePuzzles, isTrue);
  });

  testWidgets('a games-only summary claims no task count (H3)', (
    tester,
  ) async {
    await pumpEdit(tester);
    await _customPuzzle(tester);
    expect(find.text('Medium · 1 puzzle'), findsOneWidget);

    await tapVisible(tester, _toggle('Catch the Capy'));
    expect(find.text('Medium · 1 puzzle · Catch the Capy'), findsOneWidget);

    await tapVisible(tester, _toggle('Puzzles'));
    expect(find.text('Medium · Catch the Capy'), findsOneWidget);
  });

  testWidgets('following defaults again drops the alarm pool', (tester) async {
    final harness = await pumpEdit(tester);
    final l10n = _l10n(tester);
    await _customPuzzle(tester);
    await tapVisible(tester, _toggle('Catch the Capy'));
    await tapVisible(tester, _toggle(l10n.alarmPuzzleUseDefaultsLabel));
    await tapSave(tester);

    expect(
      (await harness.repository.listAlarms()).single.puzzleOverride,
      isNull,
    );
  });

  testWidgets('adding Step Quest to an alarm offers the step sensor', (
    tester,
  ) async {
    final steps = FakeStepSensor(current: DeviceAccess.needsPermission);
    final harness = await pumpEdit(tester, steps: steps);
    await _customPuzzle(tester);
    await tapVisible(tester, _toggle('Step Quest'));
    final sheet = find.byKey(const ValueKey('step-access-sheet'));
    expect(sheet, findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(steps.requestCount, 0);
    await tapSave(tester);
    expect(
      (await harness.repository.listAlarms())
          .single
          .puzzleOverride!
          .enabledGames,
      contains('step_quest'),
    );
  });
}

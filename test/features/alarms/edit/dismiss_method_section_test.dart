import 'package:capywake/core/models/models.dart';
import 'package:capywake/features/alarms/edit/dismiss_method_section.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'alarm_edit_screen_test.dart' show pumpEdit, tapSave, tapVisible;

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
  tester.element(find.byType(DismissMethodSection)),
);

Alarm _alarm({
  DismissMethod method = DismissMethod.normalButton,
}) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 420,
    repeatWeekdays: const {1, 2, 3},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: method,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('offers Tap and Puzzle, and no Shake', (tester) async {
    await pumpEdit(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.alarmDismissMethodNormal), findsOneWidget);
    expect(find.text(l10n.alarmDismissMethodPuzzle), findsOneWidget);
    // "Shake" is not a supported DismissMethod and must not appear.
    expect(find.textContaining('Shake'), findsNothing);
    expect(find.textContaining('shake'), findsNothing);
  });

  testWidgets('selecting Puzzle stores the puzzle dismiss method', (
    tester,
  ) async {
    final harness = await pumpEdit(tester);
    final l10n = _l10n(tester);

    await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
    await tapSave(tester);

    final stored = await harness.repository.listAlarms();
    expect(stored.single.dismissMethod, DismissMethod.puzzle);
  });

  testWidgets('a fresh puzzle alarm carries no override (follows defaults)', (
    tester,
  ) async {
    final harness = await pumpEdit(tester);
    final l10n = _l10n(tester);

    await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
    await tapSave(tester);

    final stored = await harness.repository.listAlarms();
    expect(stored.single.puzzleOverride, isNull);
    expect(stored.single.dismissChallengeDifficulty, isNull);
  });

  testWidgets('changing dismissal leaves every other field untouched (M4)', (
    tester,
  ) async {
    final original = _alarm();
    final harness = await pumpEdit(tester, seed: [original], alarmId: 'a1');
    final l10n = _l10n(tester);

    await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
    await tapSave(tester);

    final stored = (await harness.repository.listAlarms()).single;
    expect(stored.dismissMethod, DismissMethod.puzzle);
    // Nothing else moved.
    expect(stored.targetTimeMinutes, original.targetTimeMinutes);
    expect(stored.repeatWeekdays, original.repeatWeekdays);
    expect(stored.soundId, original.soundId);
    expect(stored.snoozeEnabled, original.snoozeEnabled);
    expect(stored.snoozeDurationMinutes, original.snoozeDurationMinutes);
    expect(stored.label, original.label);
  });

  testWidgets('switching Puzzle then back to Tap clears the puzzle config', (
    tester,
  ) async {
    final harness = await pumpEdit(tester);
    final l10n = _l10n(tester);

    await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
    await tapVisible(tester, find.text(l10n.alarmDismissMethodNormal));
    await tapSave(tester);

    final stored = (await harness.repository.listAlarms()).single;
    expect(stored.dismissMethod, DismissMethod.normalButton);
    expect(stored.puzzleOverride, isNull);
    expect(stored.dismissChallengeDifficulty, isNull);
  });

  testWidgets('the follow-defaults switch only shows while Puzzle is on', (
    tester,
  ) async {
    await pumpEdit(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.alarmPuzzleUseDefaultsLabel), findsNothing);
    await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
    expect(find.text(l10n.alarmPuzzleUseDefaultsLabel), findsOneWidget);
  });

  testWidgets('a holdToDismiss alarm is not misrepresented as Tap (SR1 H1)', (
    tester,
  ) async {
    final harness = await pumpEdit(
      tester,
      seed: [_alarm(method: DismissMethod.holdToDismiss)],
      alarmId: 'a1',
    );
    final l10n = _l10n(tester);

    // The two-segment control is not shown for a method it cannot represent;
    // instead the method is named read-only. Tap is not falsely selected.
    expect(find.text(l10n.alarmDismissMethodHold), findsOneWidget);

    // Saving without touching dismissal preserves holdToDismiss.
    await tapSave(tester);
    final stored = (await harness.repository.listAlarms()).single;
    expect(stored.dismissMethod, DismissMethod.holdToDismiss);
  });

  testWidgets('the summary row links to the puzzle chooser', (tester) async {
    await pumpEdit(tester);
    final l10n = _l10n(tester);

    await tapVisible(tester, find.text(l10n.alarmDismissMethodPuzzle));
    final link = find.descendant(
      of: find.byType(DismissMethodSection),
      matching: find.byIcon(Icons.extension_outlined),
    );
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byType(DismissMethodSection), findsNothing);
  });
}

import 'package:capywake/core/models/models.dart';
import 'package:capywake/features/alarms/edit/motion_check_card.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../games/_pump.dart';
import 'alarm_edit_screen_test.dart';

const _rule =
    'If the phone stays mostly still for the next 90 seconds, the alarm rings '
    'once more.';
const _limit =
    'If your phone pauses CapyWake in the background, the check stops quietly '
    'and no extra ring comes.';
const _globalOff =
    'The motion check is off in Settings, so nothing happens after you stop '
    'this alarm.';

Future<List<bool>> _card(
  WidgetTester tester, {
  required bool enabled,
  bool globallyEnabled = true,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final changes = <bool>[];
  await pumpInApp(
    tester,
    MotionCheckCard(
      enabled: enabled,
      globallyEnabled: globallyEnabled,
      onChanged: changes.add,
    ),
    locale: locale,
    textScale: textScale,
  );
  return changes;
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('off: the switch and what it can tell, nothing more', (
    tester,
  ) async {
    await _card(tester, enabled: false);
    expect(find.text('Motion check'), findsOneWidget);
    expect(find.textContaining('not that you are out of bed'), findsOneWidget);
    expect(find.text(_rule), findsNothing);
    expect(find.text(_limit), findsNothing);
  });

  testWidgets('on: the rule and its limit, honestly', (tester) async {
    await _card(tester, enabled: true);
    expect(find.text(_rule), findsOneWidget);
    expect(find.text(_limit), findsOneWidget);
    expect(find.text(_globalOff), findsNothing);
  });

  testWidgets('on but off in Settings: says nothing will happen', (
    tester,
  ) async {
    await _card(tester, enabled: true, globallyEnabled: false);
    expect(find.text(_globalOff), findsOneWidget);
  });

  testWidgets('the switch is named for a screen reader and reports', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = await _card(tester, enabled: false);
    expect(find.bySemanticsLabel('Check that the phone moves'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('motion-check-toggle')));
    expect(changes, [true]);
    handle.dispose();
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('fits at 2x text in ${locale.languageCode}', (tester) async {
      await _card(
        tester,
        enabled: true,
        globallyEnabled: false,
        locale: locale,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }

  group('in the form', () {
    testWidgets('sits after the dismiss card and saves with the alarm', (
      tester,
    ) async {
      final harness = await pumpEdit(tester);
      final toggle = find.byKey(const ValueKey('motion-check-toggle'));
      await tapVisible(tester, toggle);
      expect(find.text(_rule), findsOneWidget);
      await tapSave(tester);
      final stored = (await harness.repository.listAlarms()).single;
      expect(stored.motionConfirmationEnabled, isTrue);
    });

    testWidgets('an existing alarm opens with its own switch', (tester) async {
      await pumpEdit(
        tester,
        seed: [_withCheck()],
        alarmId: 'motion',
      );
      await tester.ensureVisible(find.byType(MotionCheckCard));
      await tester.pumpAndSettle();
      expect(find.text(_rule), findsOneWidget);
      expect(find.text(_globalOff), findsOneWidget, reason: 'default is off');
    });
  });
}

Alarm _withCheck() {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'motion',
    label: '',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 0,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 3,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    motionConfirmationEnabled: true,
    createdAt: t,
    updatedAt: t,
  );
}

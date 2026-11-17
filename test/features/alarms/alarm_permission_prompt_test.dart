import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/permissions/alarm_permission_gate.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../settings/settings_harness.dart';

Alarm _alarm({
  required String id,
  required bool enabled,
  int minutes = 420,
}) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: id,
    label: '',
    enabled: enabled,
    targetTimeMinutes: minutes,
    repeatWeekdays: const {},
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

const _denied = PermissionState(
  notification: PermissionGrant.denied,
  exactAlarm: PermissionGrant.denied,
);

// Mutation evidence: deleting `isFirstEnableTransition` from `maybeRequest`
// fails two tests below. See PHASE_07_POST_REVIEW.md for why it was one.
void main() {
  setUpAll(initializeDateFormatting);

  // The gate's own rules, before any widget is involved. These are what the
  // wiring has to honour; the widget tests below prove that it does.
  group('the gate decides, and these are its rules', () {
    test('fires only on the edge from nothing enabled to something', () {
      final off = [_alarm(id: 'a', enabled: false)];
      final on = [_alarm(id: 'a', enabled: true)];

      expect(
        AlarmPermissionGate.isFirstEnableTransition(before: off, after: on),
        isTrue,
      );
      expect(
        AlarmPermissionGate.isFirstEnableTransition(before: on, after: on),
        isFalse,
        reason: 'a second alarm must not re-prompt someone who answered',
      );
      expect(
        AlarmPermissionGate.isFirstEnableTransition(before: on, after: off),
        isFalse,
        reason: 'disabling is not a reason to ask for anything',
      );
      expect(
        AlarmPermissionGate.isFirstEnableTransition(before: [], after: []),
        isFalse,
        reason: 'app start, with no alarms, must never prompt',
      );
    });

    test('asks for exact alarm on Android only', () {
      final on = [_alarm(id: 'a', enabled: true)];
      expect(
        AlarmPermissionGate.shouldRequestExactAlarm(
          alarms: on,
          grant: PermissionGrant.denied,
          isAndroid: false,
        ),
        isFalse,
      );
      expect(
        AlarmPermissionGate.shouldRequestExactAlarm(
          alarms: on,
          grant: PermissionGrant.denied,
          isAndroid: true,
        ),
        isTrue,
      );
    });
  });

  group('enabling the first alarm prompts', () {
    testWidgets('the toggle that enables the first alarm asks once', (
      tester,
    ) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        alarms: [_alarm(id: 'a', enabled: false)],
        grants: _denied,
      );

      expect(harness.permissions.notificationRequestCount, 0);

      await tester.tap(find.byType(CapyToggle).first);
      await tester.pumpAndSettle();

      // The reason comes first: an unexplained OS sheet is denied by reflex.
      expect(find.byType(AlertDialog), findsOneWidget);
      final l10n = l10nOf(tester);
      expect(find.text(l10n.settingsNotificationAllowAction), findsOneWidget);

      await tester.tap(find.text(l10n.settingsNotificationAllowAction));
      await tester.pumpAndSettle();

      expect(harness.permissions.notificationRequestCount, 1);
    });

    testWidgets('declining the reason asks the OS nothing', (tester) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        alarms: [_alarm(id: 'a', enabled: false)],
        grants: _denied,
      );

      await tester.tap(find.byType(CapyToggle).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          MaterialLocalizations.of(
            tester.element(find.byType(AlertDialog)),
          ).cancelButtonLabel,
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.permissions.notificationRequestCount, 0);
    });

    testWidgets('enabling a second alarm does not ask again', (tester) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        alarms: [
          _alarm(id: 'a', enabled: true),
          _alarm(id: 'b', enabled: false, minutes: 480),
        ],
        grants: _denied,
      );

      await tester.tap(find.byType(CapyToggle).last);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.permissions.notificationRequestCount, 0);
    });

    testWidgets('disabling the only alarm does not ask', (tester) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        // Two alarms, so one stays enabled after the tap: with one, the
        // "no enabled alarm" rule would suppress the prompt regardless.
        alarms: [
          _alarm(id: 'a', enabled: true),
          _alarm(id: 'b', enabled: true, minutes: 480),
        ],
        grants: _denied,
      );

      await tester.tap(find.byType(CapyToggle).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.permissions.notificationRequestCount, 0);
    });

    testWidgets('nothing is asked on app start, however many alarms', (
      tester,
    ) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        alarms: [
          _alarm(id: 'a', enabled: true),
          _alarm(id: 'b', enabled: true, minutes: 480),
        ],
        grants: _denied,
      );

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.permissions.notificationRequestCount, 0);
    });

    testWidgets('an already-granted permission is not asked for again', (
      tester,
    ) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        alarms: [_alarm(id: 'a', enabled: false)],
      );

      await tester.tap(find.byType(CapyToggle).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.permissions.notificationRequestCount, 0);
    });

    testWidgets('a permanently-denied user is sent to the OS settings', (
      tester,
    ) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        alarms: [_alarm(id: 'a', enabled: false)],
        grants: const PermissionState(
          notification: PermissionGrant.permanentlyDenied,
          exactAlarm: PermissionGrant.granted,
        ),
      );

      await tester.tap(find.byType(CapyToggle).first);
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      // The action says where it goes: there is no prompt left to show, so
      // offering "Allow" would be a button that cannot do what it says.
      expect(find.text(l10n.settingsNotificationAllowAction), findsNothing);
      await tester.tap(find.text(l10n.reliabilityOpenSettingsAction));
      await tester.pumpAndSettle();

      expect(harness.permissions.openAppSettingsCount, 1);
      expect(
        harness.permissions.notificationRequestCount,
        0,
        reason: 'a permanently-denied permission cannot be re-prompted',
      );
    });

    testWidgets('the alarm is still saved when the prompt is declined', (
      tester,
    ) async {
      final harness = await pumpSettings(
        tester,
        at: Routes.alarms,
        alarms: [_alarm(id: 'a', enabled: false)],
        grants: _denied,
      );

      await tester.tap(find.byType(CapyToggle).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          MaterialLocalizations.of(
            tester.element(find.byType(AlertDialog)),
          ).cancelButtonLabel,
        ),
      );
      await tester.pumpAndSettle();

      final alarms = await harness.container
          .read(capywakeRepositoryProvider)
          .listAlarms();
      expect(
        alarms.single.enabled,
        isTrue,
        reason: 'refusing a permission must not undo the user edit',
      );
    });
  });
}

import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/permissions/alarm_permission_gate.dart';
import 'package:flutter_test/flutter_test.dart';

Alarm _alarm({required bool enabled, String id = 'a1'}) {
  final now = DateTime.utc(2026);
  return Alarm(
    id: id,
    label: '',
    enabled: enabled,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 0,
    soundId: 'default',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('hasEnabledAlarm', () {
    test('an empty list has none', () {
      expect(AlarmPermissionGate.hasEnabledAlarm(const []), isFalse);
    });

    test('alarms that all exist but are off have none', () {
      expect(
        AlarmPermissionGate.hasEnabledAlarm([
          _alarm(enabled: false),
          _alarm(id: 'a2', enabled: false),
        ]),
        isFalse,
      );
    });

    test('one enabled alarm is enough', () {
      expect(
        AlarmPermissionGate.hasEnabledAlarm([
          _alarm(enabled: false),
          _alarm(id: 'a2', enabled: true),
        ]),
        isTrue,
      );
    });
  });

  group('shouldRequestNotification', () {
    test('never prompts when nothing is enabled', () {
      expect(
        AlarmPermissionGate.shouldRequestNotification(
          alarms: [_alarm(enabled: false)],
          grant: PermissionGrant.unknown,
        ),
        isFalse,
      );
    });

    test('prompts on an enabled alarm when never asked', () {
      expect(
        AlarmPermissionGate.shouldRequestNotification(
          alarms: [_alarm(enabled: true)],
          grant: PermissionGrant.unknown,
        ),
        isTrue,
      );
    });

    test('prompts again after a soft denial', () {
      expect(
        AlarmPermissionGate.shouldRequestNotification(
          alarms: [_alarm(enabled: true)],
          grant: PermissionGrant.denied,
        ),
        isTrue,
      );
    });

    test('does not re-prompt once granted', () {
      expect(
        AlarmPermissionGate.shouldRequestNotification(
          alarms: [_alarm(enabled: true)],
          grant: PermissionGrant.granted,
        ),
        isFalse,
      );
    });

    test('does not prompt when the OS will show no dialog', () {
      expect(
        AlarmPermissionGate.shouldRequestNotification(
          alarms: [_alarm(enabled: true)],
          grant: PermissionGrant.permanentlyDenied,
        ),
        isFalse,
      );
    });
  });

  group('shouldRequestExactAlarm', () {
    test('never on iOS', () {
      expect(
        AlarmPermissionGate.shouldRequestExactAlarm(
          alarms: [_alarm(enabled: true)],
          grant: PermissionGrant.unknown,
          isAndroid: false,
        ),
        isFalse,
      );
    });

    test('on Android with an enabled alarm and no answer yet', () {
      expect(
        AlarmPermissionGate.shouldRequestExactAlarm(
          alarms: [_alarm(enabled: true)],
          grant: PermissionGrant.unknown,
          isAndroid: true,
        ),
        isTrue,
      );
    });

    test('not on Android while nothing is enabled', () {
      expect(
        AlarmPermissionGate.shouldRequestExactAlarm(
          alarms: [_alarm(enabled: false)],
          grant: PermissionGrant.unknown,
          isAndroid: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldOpenSettings', () {
    test('only when the OS will not ask again', () {
      expect(
        AlarmPermissionGate.shouldOpenSettings(
          PermissionGrant.permanentlyDenied,
        ),
        isTrue,
      );
      for (final grant in [
        PermissionGrant.unknown,
        PermissionGrant.denied,
        PermissionGrant.granted,
      ]) {
        expect(AlarmPermissionGate.shouldOpenSettings(grant), isFalse);
      }
    });
  });

  group('isFirstEnableTransition', () {
    test('is the edge from nothing enabled to something enabled', () {
      expect(
        AlarmPermissionGate.isFirstEnableTransition(
          before: [_alarm(enabled: false)],
          after: [_alarm(enabled: true)],
        ),
        isTrue,
      );
    });

    test('enabling a second alarm does not re-prompt', () {
      expect(
        AlarmPermissionGate.isFirstEnableTransition(
          before: [_alarm(enabled: true)],
          after: [
            _alarm(enabled: true),
            _alarm(id: 'a2', enabled: true),
          ],
        ),
        isFalse,
      );
    });

    test('turning the last alarm off is not a transition', () {
      expect(
        AlarmPermissionGate.isFirstEnableTransition(
          before: [_alarm(enabled: true)],
          after: [_alarm(enabled: false)],
        ),
        isFalse,
      );
    });

    test('an empty app that stays empty is not a transition', () {
      expect(
        AlarmPermissionGate.isFirstEnableTransition(
          before: const [],
          after: const [],
        ),
        isFalse,
      );
    });

    test('the very first alarm, created already enabled, prompts', () {
      expect(
        AlarmPermissionGate.isFirstEnableTransition(
          before: const [],
          after: [_alarm(enabled: true)],
        ),
        isTrue,
      );
    });
  });
}

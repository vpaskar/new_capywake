import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/engine/fake_notification_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Alarm _alarm({
  String id = 'a1',
  bool enabled = true,
  int minutes = 7 * 60,
  Set<int> repeat = const {1, 2, 3, 4, 5, 6, 7},
}) {
  final now = DateTime.utc(2026);
  return Alarm(
    id: id,
    label: '',
    enabled: enabled,
    targetTimeMinutes: minutes,
    repeatWeekdays: repeat,
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

({ProviderContainer container, CapyWakeRepository repo}) _harness({
  DateTime? now,
}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (now != null)
        engineNowProvider.overrideWith(
          (ref) =>
              () => now,
        ),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (
    container: container,
    repo: container.read(capywakeRepositoryProvider),
  );
}

/// Hold the coordinator open the way `AppShell` does. Without a subscriber
/// the provider is disposed immediately and arms nothing.
void _hold(ProviderContainer container) {
  final sub = container.listen(
    alarmScheduleCoordinatorProvider,
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(sub.close);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('defaults', () {
    test('the graph wires fakes, so no test reaches a real plugin', () {
      final h = _harness();
      expect(h.container.read(alarmEngineProvider), isA<FakeAlarmEngine>());
      expect(
        h.container.read(notificationServiceProvider),
        isA<FakeNotificationService>(),
      );
    });

    test('the default permission service answers without a device', () async {
      final h = _harness();
      final state = await h.container.read(permissionServiceProvider).read();
      expect(state.notification, PermissionGrant.granted);
    });

    test('the default location is UTC, never the host zone', () {
      final h = _harness();
      expect(h.container.read(scheduleLocationProvider), tz.UTC);
    });
  });

  group('arming', () {
    test('saving an enabled alarm arms it on the platform', () async {
      final h = _harness();
      _hold(h.container);
      final engine = h.container.read(alarmEngineProvider) as FakeAlarmEngine;

      await h.repo.upsertAlarm(_alarm());
      await _settle();

      expect(engine.armedSnapshot.keys, contains('a1'));
    });

    test('a disabled alarm is not armed', () async {
      final h = _harness();
      _hold(h.container);
      final engine = h.container.read(alarmEngineProvider) as FakeAlarmEngine;

      await h.repo.upsertAlarm(_alarm(enabled: false));
      await _settle();

      expect(engine.armedSnapshot, isEmpty);
    });

    test('disabling an armed alarm cancels it', () async {
      final h = _harness();
      _hold(h.container);
      final engine = h.container.read(alarmEngineProvider) as FakeAlarmEngine;

      await h.repo.upsertAlarm(_alarm());
      await _settle();
      expect(engine.armedSnapshot.keys, contains('a1'));

      await h.repo.upsertAlarm(_alarm(enabled: false));
      await _settle();
      expect(engine.armedSnapshot, isEmpty);
    });

    test('deleting an alarm cancels it', () async {
      final h = _harness();
      _hold(h.container);
      final engine = h.container.read(alarmEngineProvider) as FakeAlarmEngine;

      await h.repo.upsertAlarm(_alarm());
      await _settle();
      await h.repo.deleteAlarm('a1');
      await _settle();

      expect(engine.armedSnapshot, isEmpty);
    });

    test('several alarms each get armed', () async {
      final h = _harness();
      _hold(h.container);
      final engine = h.container.read(alarmEngineProvider) as FakeAlarmEngine;

      await h.repo.upsertAlarm(_alarm());
      await h.repo.upsertAlarm(_alarm(id: 'a2', minutes: 8 * 60));
      await _settle();

      expect(engine.armedSnapshot.keys, containsAll(['a1', 'a2']));
    });
  });

  group('lifetime', () {
    test('nothing is armed while no one holds the provider open', () async {
      final h = _harness();
      final engine = h.container.read(alarmEngineProvider) as FakeAlarmEngine;

      await h.repo.upsertAlarm(_alarm());
      await _settle();

      expect(
        engine.armedSnapshot,
        isEmpty,
        reason:
            'a provider with no subscriber is disposed and arms nothing — '
            'this is why AppShell watches it',
      );
    });

    test('a refresh re-arms from the database without a write', () async {
      final h = _harness();
      _hold(h.container);
      final engine = h.container.read(alarmEngineProvider) as FakeAlarmEngine;

      await h.repo.upsertAlarm(_alarm());
      await _settle();
      final armedOnce = engine.everArmedRingInstantsUtc.length;

      h.container.read(scheduleRefreshProvider.notifier).refresh();
      await _settle();

      expect(
        engine.everArmedRingInstantsUtc.length,
        greaterThan(armedOnce),
        reason: 'resume and timezone change re-sync without a row changing',
      );
    });

    test('a zone change re-arms in the new zone, same coordinator', () async {
      var zone = tz.getLocation('Europe/Berlin');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          scheduleLocationProvider.overrideWith((ref) => zone),
          engineNowProvider.overrideWith(
            (ref) =>
                () => DateTime.utc(2026, 11, 18, 12),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      _hold(container);
      final engine = container.read(alarmEngineProvider) as FakeAlarmEngine;
      final coordinator = container.read(alarmScheduleCoordinatorProvider);

      await container.read(capywakeRepositoryProvider).upsertAlarm(_alarm());
      await _settle();
      expect(engine.armedSnapshot['a1']!.scheduledUtc.hour, 6);

      zone = tz.getLocation('America/New_York');
      container.invalidate(scheduleLocationProvider);
      await _settle();

      expect(engine.armedSnapshot['a1']!.scheduledUtc.hour, 12);
      expect(
        container.read(alarmScheduleCoordinatorProvider),
        same(coordinator),
        reason: 'a rebuild on a zone change is a path the ring guard never saw',
      );
    });
  });

  group('reminder clock format', () {
    test('follows the saved preference', () async {
      final h = _harness();
      final sub = h.container.listen(notificationTimeFormatProvider, (_, _) {});
      addTearDown(sub.close);
      await _settle();
      expect(sub.read(), TimeFormatPreference.system);

      await h.repo.saveSettings(
        UserSettings.initial.copyWith(timeFormat: TimeFormatPreference.h24),
      );
      await _settle();
      expect(sub.read(), TimeFormatPreference.h24);
    });

    test('changing it rewrites the pending reminders', () async {
      final h = _harness();
      _hold(h.container);
      final notifications =
          h.container.read(notificationServiceProvider)
              as FakeNotificationService;
      await h.repo.upsertAlarm(_alarm());
      await _settle();
      final before = notifications.scheduleCallCount;

      await h.repo.saveSettings(
        UserSettings.initial.copyWith(timeFormat: TimeFormatPreference.h24),
      );
      await _settle();

      expect(notifications.scheduleCallCount, greaterThan(before));
    });
  });

  group('failure reporting', () {
    test('a healthy sync reports no failure', () async {
      final h = _harness();
      _hold(h.container);
      await h.repo.upsertAlarm(_alarm());
      await _settle();

      expect(
        h.container.read(alarmScheduleCoordinatorProvider).scheduleFailed,
        isFalse,
      );
    });

    test('an engine that refuses is reported, not swallowed', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final engine = FakeAlarmEngine()
        ..failNextReschedule = const AlarmEngineException('refused');
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          alarmEngineProvider.overrideWith((ref) => engine),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final sub = container.listen(
        alarmScheduleCoordinatorProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await container.read(capywakeRepositoryProvider).upsertAlarm(_alarm());
      await _settle();

      expect(
        container.read(alarmScheduleCoordinatorProvider).scheduleFailed,
        isTrue,
        reason: 'the UI must not present an alarm as set when arming failed',
      );
    });
  });
}

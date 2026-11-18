import 'dart:async';

import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/engine/alarm_schedule_coordinator.dart';
import 'package:capywake/core/engine/fake_alarm_engine.dart';
import 'package:capywake/core/engine/fake_notification_service.dart';
import 'package:capywake/core/engine/notification_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/fake_permission_service.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Provider graph for the alarm engine. Defaults are fakes, so no test reaches
/// a real alarm; production overrides them with the platform adapters.

/// The platform alarm scheduler. Defaults to [FakeAlarmEngine].
final alarmEngineProvider = Provider<AlarmEngine>((ref) {
  final engine = FakeAlarmEngine();
  ref.onDispose(engine.dispose);
  return engine;
}, dependencies: const []);

/// Pre-alarm reminders. Defaults to [FakeNotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = FakeNotificationService();
  ref.onDispose(service.dispose);
  return service;
}, dependencies: const []);

/// The OS permission flow. Defaults to a permissive fake.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return FakePermissionService(
    initial: const PermissionState(
      notification: PermissionGrant.granted,
      exactAlarm: PermissionGrant.granted,
    ),
  );
}, dependencies: const []);

/// The zone the schedule engine anchors to. UTC in tests.
final scheduleLocationProvider = Provider<tz.Location>((ref) {
  return tz.UTC;
}, dependencies: const []);

/// The wall clock the coordinator reads.
final engineNowProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
}, dependencies: const []);

/// Bumping this re-runs the schedule after a resume or timezone change, where
/// no row changed but what is armed may be wrong.
final scheduleRefreshProvider = NotifierProvider<ScheduleRefresh, int>(
  ScheduleRefresh.new,
);

/// Counter whose every increment triggers one re-sync.
class ScheduleRefresh extends Notifier<int> {
  @override
  int build() => 0;

  /// Request a re-sync from the current database state.
  void refresh() => state++;
}

/// The clock format soft-wake reminder bodies are written in.
final notificationTimeFormatProvider = Provider<TimeFormatPreference>(
  (ref) =>
      ref.watch(userSettingsStreamProvider).value?.timeFormat ??
      TimeFormatPreference.system,
);

/// Arms and re-syncs the platform scheduler on every database change. Watched
/// by `AppShell`: unwatched, it is disposed at once and arms nothing.
final alarmScheduleCoordinatorProvider = Provider<AlarmScheduleCoordinator>(
  (
    ref,
  ) {
    final coordinator = AlarmScheduleCoordinator(
      engine: ref.watch(alarmEngineProvider),
      notifications: ref.watch(notificationServiceProvider),
      location: ref.watch(scheduleLocationProvider),
      now: ref.watch(engineNowProvider),
    );

    void syncLatest() {
      final alarms = ref.read(alarmsStreamProvider).value;
      if (alarms == null) return;
      final finished = ref.read(finishedOccurrencesStreamProvider);
      final snoozed = ref.read(snoozedOccurrencesStreamProvider);
      // Arming before the occurrence streams answer can ring the phone in the
      // user's hand; an errored one is not waited for. See PHASE_05_PLAN.md.
      if (finished.isLoading || snoozed.isLoading) return;
      unawaited(
        coordinator.sync(
          alarms: alarms,
          finished: finished.value ?? const <AlarmOccurrence>[],
          snoozed: snoozed.value ?? const <AlarmOccurrence>[],
        ),
      );
    }

    Timer? pending;
    void resync() {
      pending?.cancel();
      pending = Timer(Duration.zero, syncLatest);
    }

    ref
      ..listen(scheduleRefreshProvider, (_, _) => resync())
      ..listen(notificationTimeFormatProvider, (_, _) => resync())
      ..onDispose(() {
        pending?.cancel();
        coordinator.dispose();
      })
      ..listen<AsyncValue<List<Alarm>>>(
        alarmsStreamProvider,
        (_, _) => resync(),
      )
      ..listen<AsyncValue<List<AlarmOccurrence>>>(
        finishedOccurrencesStreamProvider,
        (_, _) => resync(),
      )
      ..listen<AsyncValue<List<AlarmOccurrence>>>(
        snoozedOccurrencesStreamProvider,
        (_, _) => resync(),
      );

    resync();
    return coordinator;
  },
  dependencies: [
    alarmEngineProvider,
    notificationServiceProvider,
    scheduleLocationProvider,
    engineNowProvider,
  ],
);

/// Whether the last sync reached the platform. When it did not, the UI must
/// not call the alarm set.
final alarmScheduleFailureProvider = StreamProvider<bool>((ref) async* {
  final coordinator = ref.watch(alarmScheduleCoordinatorProvider);
  yield coordinator.scheduleFailed;
  yield* coordinator.scheduleFailures;
}, dependencies: [alarmScheduleCoordinatorProvider]);

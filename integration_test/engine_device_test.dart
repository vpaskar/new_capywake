import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/alarm_plan_mapper.dart';
import 'package:capywake/data/engine/local_location_resolver.dart';
import 'package:capywake/data/engine/platform_alarm_engine.dart';
import 'package:capywake/data/engine/platform_notification_service.dart';
import 'package:capywake/data/permissions/platform_permission_service.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Exercises the platform adapters against the real plugins on a real device.
///
/// The widget suite proves the wiring with fakes; only this proves the plugin
/// channels answer at all. Run with `flutter drive`, never `flutter test`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(tzdata.initializeTimeZones);

  Alarm alarmAt(DateTime when) {
    final now = DateTime.now().toUtc();
    return Alarm(
      id: 'device-test-alarm',
      label: 'Device test',
      enabled: true,
      targetTimeMinutes: when.hour * 60 + when.minute,
      repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      wakeMode: WakeMode.standard,
      wakeWindowStartMinutesBefore: 0,
      soundId: 'chimes',
      vibrationEnabled: true,
      snoozeEnabled: true,
      snoozeDurationMinutes: 9,
      maxSnoozes: 3,
      dismissMethod: DismissMethod.normalButton,
      dismissChallengeDifficulty: null,
      confirmationEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('the timezone database resolves a real local zone', (_) async {
    final location = LocalLocationResolver.resolve(DateTime.now());
    expect(location, isNotNull);
    tz.setLocalLocation(location!);
    expect(tz.local.name, location.name);
  });

  testWidgets('the alarm plugin arms and cancels a real alarm', (_) async {
    final location = LocalLocationResolver.resolve(DateTime.now()) ?? tz.UTC;
    final engine = PlatformAlarmEngine(
      title: (_) => 'Alarm',
      body: (_) => 'Device test',
      location: () => location,
    );
    await engine.initialize();

    final at = tz.TZDateTime.from(
      DateTime.now().add(const Duration(hours: 2)),
      location,
    );
    final alarm = alarmAt(at);
    final plan = AlarmOccurrencePlan(
      alarm: alarm,
      scheduled: at,
      softStart: null,
      location: location,
    );

    await engine.arm(plan);
    await engine.cancel(alarm.id);
    await engine.rescheduleAll([plan]);
    await engine.rescheduleAll(const []);
    await engine.dispose();
  });

  testWidgets('the notification plugin initialises and schedules', (_) async {
    final location = LocalLocationResolver.resolve(DateTime.now()) ?? tz.UTC;
    final notifications = PlatformNotificationService(
      channelName: () => 'Alarms',
      title: (_) => 'Wake window',
      body: (_) => 'Your wake window has started.',
      location: () => location,
    );
    await notifications.initialize();
    await notifications.scheduleAll(const []);
    await notifications.cancelAll();
    await notifications.dispose();
  });

  testWidgets('the permission service answers without prompting', (_) async {
    final state = await PlatformPermissionService().read();
    expect(state.notification, isNotNull);
    expect(state.exactAlarm, isNotNull);
  });

  testWidgets('saving an enabled alarm arms it through the real graph', (
    _,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final location = LocalLocationResolver.resolve(DateTime.now()) ?? tz.UTC;
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final repo = container.read(capywakeRepositoryProvider);
    expect(repo, isA<CapyWakeRepository>());

    final at = tz.TZDateTime.from(
      DateTime.now().add(const Duration(hours: 3)),
      location,
    );
    await repo.upsertAlarm(alarmAt(at));
    final saved = await repo.listAlarms();
    expect(saved, hasLength(1));
    expect(saved.single.enabled, isTrue);
    expect(
      AlarmPlanMapper.platformId(saved.single.id),
      greaterThan(0),
      reason: 'the plugin key must be a usable positive int on device',
    );
  });
}

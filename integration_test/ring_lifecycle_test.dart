import 'package:alarm/alarm.dart' as plugin;
import 'package:capywake/app/app.dart';
import 'package:capywake/app/bootstrap.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/engine/alarm_plan_mapper.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/engine/platform_engine_overrides.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// The real `package:alarm` on a simulator, which no fake engine can show.
/// Run by hand with `-d` and a simulator; uses and removes its own alarm.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a ring keeps ringing; stopping it arms tomorrow',
    (
      tester,
    ) async {
      await bootstrap();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final scope = await platformEngineScope(l10n: l10n, localeName: 'en');
      await tester.pumpWidget(CapyWakeApp(scopeBuilder: scope));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );
      final repository = container.read(capywakeRepositoryProvider);
      final platformId = AlarmPlanMapper.platformId(_alarmId);

      Future<void> wait(Duration d) async {
        await tester.runAsync(() => Future<void>.delayed(d));
        await tester.pump();
      }

      Future<bool> ringing() async =>
          (await tester.runAsync(() => plugin.Alarm.isRinging(platformId)))!;

      Future<DateTime?> armed() async => (await tester.runAsync(
        () => plugin.Alarm.getAlarm(platformId),
      ))?.dateTime;

      Future<void> dismiss() async {
        await tester.runAsync(
          () => container.read(ringingControllerProvider).dismiss(),
        );
        await wait(const Duration(seconds: 2));
      }

      try {
        final now = DateTime.now();
        final ringAt = DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute + (now.second > 40 ? 2 : 1),
        );
        final alarm = _alarm(ringAt.hour * 60 + ringAt.minute);
        await tester.runAsync(() => repository.upsertAlarm(alarm));
        while (DateTime.now().isBefore(ringAt)) {
          await wait(const Duration(milliseconds: 500));
        }
        await wait(const Duration(seconds: 3));
        expect(await ringing(), isTrue, reason: 'still ringing 3 s in');
        expect(find.byType(RingingScreen), findsOneWidget);

        await dismiss();
        expect(await ringing(), isFalse);
        final tomorrow = await armed();
        expect(tomorrow, isNotNull, reason: 'the dismissal re-armed the alarm');
        expect(tomorrow!.isAfter(DateTime.now()), isTrue);

        await tester.runAsync(
          () => container.read(alarmEngineProvider).ringNow(alarm),
        );
        await wait(const Duration(seconds: 3));
        expect(await ringing(), isTrue, reason: 'the re-ring keeps ringing');
        expect(find.byType(RingingScreen), findsOneWidget);
        final rows = (await tester.runAsync(
          () => repository.listOccurrencesForAlarm(_alarmId),
        ))!;
        expect(rows.single.isMotionReRing, isTrue);
        expect(rows.single.status, AlarmStatus.triggered);

        await dismiss();
        expect(await ringing(), isFalse);
        expect(await armed(), isNotNull);
      } finally {
        await tester.runAsync(() async {
          await repository.deleteAlarm(_alarmId);
          await plugin.Alarm.stop(platformId);
        });
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

const _alarmId = 'ring-lifecycle-probe';

Alarm _alarm(int minutes) {
  final t = DateTime.now().toUtc();
  return Alarm(
    id: _alarmId,
    label: 'Ring check',
    enabled: true,
    targetTimeMinutes: minutes,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 0,
    soundId: 'gentle',
    vibrationEnabled: false,
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

import 'dart:async';

import 'package:alarm/alarm.dart' as plugin;
import 'package:capywake/app/app.dart';
import 'package:capywake/app/bootstrap.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/engine/alarm_plan_mapper.dart';
import 'package:capywake/data/engine/platform_engine_overrides.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// By hand, `--dart-define=CAPYWAKE_BACKGROUND_PROBE=true`: send the app home
/// after `PROBE ARMED`. Passes only if the ring started on time in background.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'an armed alarm rings on time while the app is in the background',
    (tester) async {
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

      final rang = Completer<DateTime>();
      final subscription = plugin.Alarm.ringing.listen((set) {
        if (!rang.isCompleted && set.containsId(platformId)) {
          rang.complete(DateTime.now());
        }
      });

      try {
        final now = DateTime.now();
        final ringAt = DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute + 2,
        );
        await tester.runAsync(
          () =>
              repository.upsertAlarm(_alarm(ringAt.hour * 60 + ringAt.minute)),
        );
        debugPrint('PROBE ARMED ringAt=${ringAt.toIso8601String()}');

        final startedAt = (await tester.runAsync(
          () => rang.future.timeout(const Duration(minutes: 5)),
        ))!;
        final late = startedAt.difference(ringAt);
        debugPrint(
          'PROBE RANG startedAt=${startedAt.toIso8601String()} '
          'late=${late.inMilliseconds}ms',
        );
        expect(
          late.inSeconds,
          lessThan(10),
          reason: 'a ring that waited for the app to return was suspended',
        );
      } finally {
        await subscription.cancel();
        await tester.runAsync(() async {
          await repository.deleteAlarm(_alarmId);
          await plugin.Alarm.stop(platformId);
        });
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
    skip: !const bool.fromEnvironment('CAPYWAKE_BACKGROUND_PROBE'),
  );
}

const _alarmId = 'background-ring-probe';

Alarm _alarm(int minutes) {
  final t = DateTime.now().toUtc();
  return Alarm(
    id: _alarmId,
    label: 'Background check',
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
    createdAt: t,
    updatedAt: t,
  );
}

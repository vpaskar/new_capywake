import 'package:capywake/app/app.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/alarms/edit/alarm_edit_screen.dart';
import 'package:capywake/features/home/home_screen.dart';
import 'package:capywake/features/onboarding/onboarding_screen.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Alarm _alarm() {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: '',
    enabled: true,
    targetTimeMinutes: 420,
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

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<Alarm> alarms = const [],
  UserSettings? seed,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });

  final repo = container.read(capywakeRepositoryProvider);
  if (seed != null) await repo.saveSettings(seed);
  for (final alarm in alarms) {
    await repo.upsertAlarm(alarm);
  }

  await tester.pumpWidget(
    CapyWakeApp(
      showDebugBanner: false,
      scopeBuilder: (child) =>
          UncontrolledProviderScope(container: container, child: child),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('a fresh install lands on onboarding', (tester) async {
    await _pump(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('an install with an alarm never sees onboarding', (tester) async {
    await _pump(tester, alarms: [_alarm()]);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a completed install never sees onboarding', (tester) async {
    await _pump(
      tester,
      seed: UserSettings.initial.copyWith(hasCompletedOnboarding: true),
    );
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the first-alarm CTA leads to the Add alarm screen', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Set your first alarm'));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmEditScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('skipping completes onboarding and lands on Home', (
    tester,
  ) async {
    final container = await _pump(tester);

    await tester.tap(find.text('Skip setup'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);

    final saved = await container
        .read(capywakeRepositoryProvider)
        .getSettings();
    expect(saved.hasCompletedOnboarding, isTrue);
  });

  testWidgets('completing the flag while on onboarding does not yank to Home', (
    tester,
  ) async {
    // The device-found race: the flag flip fires the refresh mid-tap. A
    // redirect that pulled a not-needed user off onboarding would beat the CTA.
    final container = await _pump(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await container.read(settingsControllerProvider).completeOnboarding();
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}

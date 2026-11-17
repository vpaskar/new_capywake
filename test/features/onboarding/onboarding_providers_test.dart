import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/onboarding/onboarding_providers.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Alarm _alarm({bool enabled = true}) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: '',
    enabled: enabled,
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

Future<ProviderContainer> _container(AppDatabase db) async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Resolve the folded flag once both streams settle, waiting for the value to
/// stop changing so a post-write re-emission is not missed.
Future<bool?> _resolve(ProviderContainer container) async {
  final sub = container.listen(needsOnboardingProvider, (_, _) {});
  addTearDown(sub.close);

  bool? last;
  var stable = 0;
  for (var i = 0; i < 40 && stable < 3; i++) {
    await Future<void>.delayed(Duration.zero);
    final value = container.read(needsOnboardingProvider);
    if (!value.hasValue) {
      stable = 0;
      continue;
    }
    if (value.requireValue == last) {
      stable++;
    } else {
      last = value.requireValue;
      stable = 1;
    }
  }
  return last;
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a fresh install (no row, no alarm) needs onboarding', () async {
    final container = await _container(db);
    expect(await _resolve(container), isTrue);
  });

  test('is loading before the streams emit — never a value (H3)', () async {
    final container = await _container(db);
    final value = container.read(needsOnboardingProvider);
    expect(value.isLoading, isTrue);
    // The redirect relies on this: a value during loading would bounce a
    // returning user into onboarding on the cold-start frame.
    expect(value.hasValue, isFalse);
  });

  test('an install with an alarm never needs onboarding', () async {
    final container = await _container(db);
    await container.read(capywakeRepositoryProvider).upsertAlarm(_alarm());
    expect(await _resolve(container), isFalse);
  });

  test('a disabled alarm still counts as an existing install', () async {
    final container = await _container(db);
    await container
        .read(capywakeRepositoryProvider)
        .upsertAlarm(_alarm(enabled: false));
    expect(await _resolve(container), isFalse);
  });

  test('completing onboarding stops the need, even with no alarm', () async {
    final container = await _container(db);
    expect(await _resolve(container), isTrue);

    await container.read(settingsControllerProvider).completeOnboarding();
    expect(await _resolve(container), isFalse);
  });

  test('completeOnboarding persists the flag', () async {
    final container = await _container(db);
    await container.read(settingsControllerProvider).completeOnboarding();

    final saved = await container
        .read(capywakeRepositoryProvider)
        .getSettings();
    expect(saved.hasCompletedOnboarding, isTrue);
  });
}

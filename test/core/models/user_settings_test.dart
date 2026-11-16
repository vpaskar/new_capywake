import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserSettings', () {
    test('initial defaults match the architecture brief', () {
      const s = UserSettings.initial;
      expect(s.defaultWakeMode, WakeMode.standard);
      expect(s.defaultSoundId, '');
      expect(s.defaultSnoozeMinutes, 9);
      expect(s.timeFormat, TimeFormatPreference.system);
      expect(s.themeMode, ThemeModePreference.system);
      expect(
        s.reliabilityChecklistState,
        ReliabilityChecklistState.empty,
      );
    });

    test('value equality on identical fields', () {
      const a = UserSettings.initial;
      const b = UserSettings.initial;
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith targets a single field', () {
      const base = UserSettings.initial;
      final next = base.copyWith(defaultWakeMode: WakeMode.strict);
      expect(next.defaultWakeMode, WakeMode.strict);
      expect(next.defaultSoundId, base.defaultSoundId);
    });

    test('copyWith() with no arguments returns an equal value', () {
      // Exercises every `?? this.x` fallback branch in `copyWith`.
      const base = UserSettings.initial;
      expect(base.copyWith(), equals(base));
    });

    test('copyWith fans out across every field', () {
      const base = UserSettings.initial;
      final next = base.copyWith(
        defaultWakeMode: WakeMode.gentle,
        defaultSoundId: 'rain',
        defaultSnoozeMinutes: 5,
        timeFormat: TimeFormatPreference.h24,
        themeMode: ThemeModePreference.dark,
        reliabilityChecklistState: ReliabilityChecklistState.empty.copyWithItem(
          ReliabilityChecklistItem.notificationPermission,
          ChecklistItemState.ok,
        ),
      );
      expect(next.defaultWakeMode, WakeMode.gentle);
      expect(next.defaultSoundId, 'rain');
      expect(next.defaultSnoozeMinutes, 5);
      expect(next.timeFormat, TimeFormatPreference.h24);
      expect(next.themeMode, ThemeModePreference.dark);
      expect(
        next.reliabilityChecklistState.stateOf(
          ReliabilityChecklistItem.notificationPermission,
        ),
        ChecklistItemState.ok,
      );
      expect(base, isNot(equals(next)));
    });

    test('inequality with an unrelated type returns false', () {
      // Intentional cross-type compare to exercise the type check in `==`.
      // ignore: unrelated_type_equality_checks
      expect(UserSettings.initial == 1, isFalse);
    });
  });

  group('ReliabilityChecklistState', () {
    test('stateOf returns unknown for items never set', () {
      expect(
        ReliabilityChecklistState.empty.stateOf(
          ReliabilityChecklistItem.alarmVolume,
        ),
        ChecklistItemState.unknown,
      );
    });

    test('copyWithItem inserts and replaces predictably', () {
      final after = ReliabilityChecklistState.empty
          .copyWithItem(
            ReliabilityChecklistItem.notificationPermission,
            ChecklistItemState.actionRequired,
          )
          .copyWithItem(
            ReliabilityChecklistItem.notificationPermission,
            ChecklistItemState.ok,
          );
      expect(
        after.stateOf(ReliabilityChecklistItem.notificationPermission),
        ChecklistItemState.ok,
      );
    });

    test('value equality is order-independent', () {
      final a = ReliabilityChecklistState.empty
          .copyWithItem(
            ReliabilityChecklistItem.alarmVolume,
            ChecklistItemState.ok,
          )
          .copyWithItem(
            ReliabilityChecklistItem.batteryOptimization,
            ChecklistItemState.actionRequired,
          );
      final b = ReliabilityChecklistState.empty
          .copyWithItem(
            ReliabilityChecklistItem.batteryOptimization,
            ChecklistItemState.actionRequired,
          )
          .copyWithItem(
            ReliabilityChecklistItem.alarmVolume,
            ChecklistItemState.ok,
          );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different sizes are not equal; identical instance shortcut', () {
      final a = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.alarmVolume,
        ChecklistItemState.ok,
      );
      final b = a.copyWithItem(
        ReliabilityChecklistItem.batteryOptimization,
        ChecklistItemState.ok,
      );
      expect(a, isNot(equals(b)));
      expect(a == a, isTrue);
      // Intentional cross-type compare to exercise the type check in `==`.
      // ignore: unrelated_type_equality_checks
      expect(a == 'x', isFalse);
    });

    test('different value at the same key is not equal', () {
      final a = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.alarmVolume,
        ChecklistItemState.ok,
      );
      final b = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.alarmVolume,
        ChecklistItemState.actionRequired,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('UserSettings.motionConfirmationEnabled', () {
    test('the global motion check is off on a fresh install', () {
      expect(UserSettings.initial.motionConfirmationEnabled, isFalse);
    });

    test('copyWith carries it in both directions', () {
      final on = UserSettings.initial.copyWith(
        motionConfirmationEnabled: true,
      );
      expect(on.motionConfirmationEnabled, isTrue);
      expect(
        on.copyWith(motionConfirmationEnabled: false).motionConfirmationEnabled,
        isFalse,
      );
      expect(
        on.copyWith(defaultSnoozeMinutes: 5).motionConfirmationEnabled,
        isTrue,
      );
    });

    test('it participates in equality and hashing', () {
      const base = UserSettings.initial;
      final on = base.copyWith(motionConfirmationEnabled: true);
      expect(on, isNot(equals(base)));
      expect(on.hashCode, isNot(equals(base.hashCode)));
      expect(on, equals(base.copyWith(motionConfirmationEnabled: true)));
    });
  });
}

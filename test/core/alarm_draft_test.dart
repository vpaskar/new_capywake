import 'package:capywake/core/alarm_draft.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmDraft.create', () {
    test('seeds defaults from settings and the wake-mode descriptor', () {
      const settings = UserSettings(
        defaultWakeMode: WakeMode.gentle,
        defaultSoundId: 'morning',
        defaultSnoozeMinutes: 7,
        timeFormat: TimeFormatPreference.h24,
        themeMode: ThemeModePreference.dark,
        reliabilityChecklistState: ReliabilityChecklistState.empty,
      );
      final draft = AlarmDraft.create(
        id: 'id-1',
        settings: settings,
        now: DateTime.utc(2026, 5, 21, 8),
      );

      expect(draft.id, 'id-1');
      expect(draft.label, '');
      expect(draft.enabled, isTrue);
      expect(draft.targetTimeMinutes, 7 * 60);
      expect(draft.repeatWeekdays, isEmpty);
      expect(draft.wakeMode, WakeMode.gentle);
      expect(draft.soundId, 'morning');
      expect(draft.snoozeDurationMinutes, 7);
      expect(draft.dismissMethod, DismissMethod.normalButton);
      expect(draft.dismissChallengeDifficulty, isNull);
      expect(draft.createdAt.isUtc, isTrue);
    });

    test('local now is normalised to UTC', () {
      final localNow = DateTime(2026, 5, 21, 10);
      final draft = AlarmDraft.create(
        id: 'id-1',
        settings: UserSettings.initial,
        now: localNow,
      );
      expect(draft.createdAt.isUtc, isTrue);
      expect(draft.createdAt, localNow.toUtc());
    });
  });

  group('AlarmDraft.fromAlarm', () {
    test('round-trips an alarm via toAlarm', () {
      final t = DateTime.utc(2026, 5, 21, 8);
      final alarm = Alarm(
        id: 'a1',
        label: 'Yoga',
        enabled: true,
        targetTimeMinutes: 6 * 60 + 30,
        repeatWeekdays: const {1, 3, 5},
        wakeMode: WakeMode.standard,
        wakeWindowStartMinutesBefore: 15,
        soundId: 'gentle',
        vibrationEnabled: false,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        maxSnoozes: 3,
        dismissMethod: DismissMethod.puzzle,
        dismissChallengeDifficulty: DismissChallengeDifficulty.medium,
        confirmationEnabled: true,
        createdAt: t,
        updatedAt: t,
      );

      final draft = AlarmDraft.fromAlarm(alarm);
      final round = draft.toAlarm(now: t);

      expect(round, equals(alarm));
    });
  });

  group('AlarmDraft.toggleWeekday', () {
    test('adds a missing weekday and removes a present one', () {
      final draft = AlarmDraft.create(
        id: 'id',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      );
      final added = draft.toggleWeekday(2);
      expect(added.repeatWeekdays, {2});
      final removed = added.toggleWeekday(2);
      expect(removed.repeatWeekdays, isEmpty);
    });

    test('rejects out-of-range weekdays', () {
      final draft = AlarmDraft.create(
        id: 'id',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      );
      expect(() => draft.toggleWeekday(0), throwsArgumentError);
      expect(() => draft.toggleWeekday(8), throwsArgumentError);
    });
  });

  group('AlarmDraft.withWakeMode', () {
    test('reseeds confirmation + maxSnoozes from the new mode descriptor', () {
      final draft = AlarmDraft.create(
        id: 'id',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      ).copyWith(confirmationEnabled: true, maxSnoozes: 99);

      final gentle = draft.withWakeMode(WakeMode.gentle);
      expect(gentle.wakeMode, WakeMode.gentle);
      expect(
        gentle.confirmationEnabled,
        WakeMode.gentle.descriptor.confirmationRequired,
      );
      expect(
        gentle.maxSnoozes,
        WakeMode.gentle.descriptor.defaultMaxSnoozes,
      );
    });
  });

  group('AlarmDraft.withDismissMethod', () {
    test('a fresh puzzle alarm follows the app-wide settings', () {
      final draft = AlarmDraft.create(
        id: 'id',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      );
      final challenge = draft.withDismissMethod(DismissMethod.puzzle);
      expect(challenge.dismissMethod, DismissMethod.puzzle);
      // Since Phase 19 nothing is seeded: null means "follow my defaults",
      // which keeps tracking the Settings screen as the user changes it.
      expect(challenge.dismissChallengeDifficulty, isNull);
      expect(challenge.puzzleOverride, isNull);
      expect(challenge.followsDefaultPuzzleSettings, isTrue);
    });

    test(
      'preserves an existing difficulty when switching to the puzzle',
      () {
        final draft = AlarmDraft.create(
          id: 'id',
          settings: UserSettings.initial,
          now: DateTime.utc(2026, 5, 21),
        ).copyWith(dismissChallengeDifficulty: DismissChallengeDifficulty.hard);
        final challenge = draft.withDismissMethod(DismissMethod.puzzle);
        expect(
          challenge.dismissChallengeDifficulty,
          DismissChallengeDifficulty.hard,
        );
      },
    );

    test('clears the whole puzzle configuration when leaving the puzzle', () {
      final draft =
          AlarmDraft.create(
                id: 'id',
                settings: UserSettings.initial,
                now: DateTime.utc(2026, 5, 21),
              )
              .withDismissMethod(DismissMethod.puzzle)
              .withPuzzleCustomisation(
                enabled: true,
                defaults: PuzzleSettings.defaults(),
              );
      expect(draft.puzzleOverride, isNotNull);
      expect(draft.dismissChallengeDifficulty, isNotNull);

      final back = draft.withDismissMethod(DismissMethod.holdToDismiss);
      expect(back.dismissChallengeDifficulty, isNull);
      expect(back.puzzleOverride, isNull);
    });
  });

  group('AlarmDraft.copyWith', () {
    test(
      'clearMaxSnoozes / clearDismissChallengeDifficulty drop the field',
      () {
        final draft =
            AlarmDraft.create(
                  id: 'id',
                  settings: UserSettings.initial,
                  now: DateTime.utc(2026, 5, 21),
                )
                .copyWith(
                  maxSnoozes: 4,
                  dismissChallengeDifficulty: DismissChallengeDifficulty.easy,
                )
                .copyWith(
                  clearMaxSnoozes: true,
                  clearDismissChallengeDifficulty: true,
                );
        expect(draft.maxSnoozes, isNull);
        expect(draft.dismissChallengeDifficulty, isNull);
      },
    );
  });

  group('AlarmDraft.validate', () {
    AlarmDraft fresh() => AlarmDraft.create(
      id: 'id',
      settings: UserSettings.initial,
      now: DateTime.utc(2026, 5, 21),
    );

    test('a freshly seeded draft validates', () {
      expect(fresh().validate().isValid, isTrue);
    });

    test('flags an out-of-range time', () {
      final tooLow = fresh().copyWith(targetTimeMinutes: -1).validate();
      final tooHigh = fresh().copyWith(targetTimeMinutes: 24 * 60).validate();
      expect(tooLow.has(AlarmDraftError.invalidTime), isTrue);
      expect(tooHigh.has(AlarmDraftError.invalidTime), isTrue);
    });

    test('flags a label longer than the cap', () {
      final draft = fresh().copyWith(
        label: 'x' * (AlarmDraft.maxLabelLength + 1),
      );
      expect(draft.validate().has(AlarmDraftError.labelTooLong), isTrue);
    });

    test('flags out-of-range weekdays', () {
      final draft = fresh().copyWith(repeatWeekdays: const {0, 8});
      expect(
        draft.validate().has(AlarmDraftError.invalidRepeatWeekdays),
        isTrue,
      );
    });

    test('flags snooze-duration out of bounds when snooze is on', () {
      final low = fresh().copyWith(
        snoozeEnabled: true,
        snoozeDurationMinutes: 0,
      );
      final high = fresh().copyWith(
        snoozeEnabled: true,
        snoozeDurationMinutes: AlarmDraft.maxSnoozeMinutes + 1,
      );
      expect(
        low.validate().has(AlarmDraftError.snoozeDurationOutOfRange),
        isTrue,
      );
      expect(
        high.validate().has(AlarmDraftError.snoozeDurationOutOfRange),
        isTrue,
      );
    });

    test('does not flag snooze duration when snooze is off', () {
      final draft = fresh().copyWith(
        snoozeEnabled: false,
        snoozeDurationMinutes: 0,
      );
      expect(draft.validate().isValid, isTrue);
    });

    test('a puzzle alarm without its own difficulty is valid', () {
      // Since Phase 19 a null difficulty means "follow the app-wide puzzle
      // settings", so it is a complete configuration rather than a gap.
      final draft = fresh().copyWith(dismissMethod: DismissMethod.puzzle);
      expect(draft.dismissChallengeDifficulty, isNull);
      expect(draft.validate().isValid, isTrue);
    });
  });

  group('AlarmDraft.toAlarm', () {
    test('throws StateError on an invalid draft', () {
      final draft = AlarmDraft.create(
        id: 'id',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      ).copyWith(targetTimeMinutes: -1);
      expect(
        () => draft.toAlarm(now: DateTime.utc(2026, 5, 21)),
        throwsStateError,
      );
    });

    test('uses the supplied `now` (UTC) as updatedAt', () {
      final draft = AlarmDraft.create(
        id: 'id',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      );
      final later = DateTime.utc(2026, 5, 22, 9, 30);
      final alarm = draft.toAlarm(now: later);
      expect(alarm.updatedAt, later);
      expect(alarm.updatedAt.isUtc, isTrue);
    });
  });

  group('AlarmDraft equality', () {
    test('value-equal regardless of weekday set order', () {
      final base = AlarmDraft.create(
        id: 'id',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      );
      final a = base.copyWith(repeatWeekdays: const {1, 3, 5});
      final b = base.copyWith(repeatWeekdays: const {5, 3, 1});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('AlarmDraftValidation', () {
    test('isValid reflects errors list', () {
      const empty = AlarmDraftValidation([]);
      const some = AlarmDraftValidation([AlarmDraftError.labelTooLong]);
      expect(empty.isValid, isTrue);
      expect(some.isValid, isFalse);
      expect(some.has(AlarmDraftError.labelTooLong), isTrue);
      expect(some.has(AlarmDraftError.invalidTime), isFalse);
    });

    test('value-equal across instances with the same errors', () {
      const a = AlarmDraftValidation([AlarmDraftError.invalidTime]);
      const b = AlarmDraftValidation([AlarmDraftError.invalidTime]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('not equal to a different type', () {
      const a = AlarmDraftValidation([AlarmDraftError.invalidTime]);
      // Deliberately comparing against a String to exercise the
      // `other is! AlarmDraftValidation` guard in operator ==.
      // ignore: unrelated_type_equality_checks
      expect(a == 'not a validation', isFalse);
    });

    test('not equal when the error lists differ in length', () {
      const a = AlarmDraftValidation([AlarmDraftError.invalidTime]);
      const b = AlarmDraftValidation([
        AlarmDraftError.invalidTime,
        AlarmDraftError.labelTooLong,
      ]);
      expect(a == b, isFalse);
    });

    test('not equal when same-length lists hold different errors', () {
      const a = AlarmDraftValidation([AlarmDraftError.invalidTime]);
      const b = AlarmDraftValidation([AlarmDraftError.labelTooLong]);
      expect(a == b, isFalse);
    });
  });

  group('AlarmDraft.motionConfirmationEnabled', () {
    test('a new draft starts with the check off', () async {
      // Off even when the global switch is on: that switch is a kill switch,
      // not a default, and it is ungated — seeding from it would hand a Free
      // user a fresh draft the Pro gate refuses to save.
      for (final settings in [
        UserSettings.initial,
        UserSettings.initial.copyWith(motionConfirmationEnabled: true),
      ]) {
        final draft = AlarmDraft.create(
          id: 'a1',
          settings: settings,
          now: DateTime.utc(2026, 5, 21),
        );
        expect(draft.motionConfirmationEnabled, isFalse);
      }
    });

    test('round-trips through fromAlarm and toAlarm', () {
      final draft = AlarmDraft.create(
        id: 'a1',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      ).copyWith(motionConfirmationEnabled: true);

      final alarm = draft.toAlarm(now: DateTime.utc(2026, 5, 21, 9));
      expect(alarm.motionConfirmationEnabled, isTrue);
      expect(
        AlarmDraft.fromAlarm(alarm).motionConfirmationEnabled,
        isTrue,
      );
    });

    test('switching wake mode leaves the user choice alone', () {
      // Unlike the confirmation flag, this is not a mode default — picking
      // Gentle must not quietly switch somebody sensor off or on.
      final draft = AlarmDraft.create(
        id: 'a1',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      ).copyWith(motionConfirmationEnabled: true);

      expect(
        draft.withWakeMode(WakeMode.gentle).motionConfirmationEnabled,
        isTrue,
      );
      expect(
        draft.withWakeMode(WakeMode.strict).motionConfirmationEnabled,
        isTrue,
      );
    });

    test('it participates in equality, hashing and the gate preview', () {
      final base = AlarmDraft.create(
        id: 'a1',
        settings: UserSettings.initial,
        now: DateTime.utc(2026, 5, 21),
      );
      final on = base.copyWith(motionConfirmationEnabled: true);
      expect(on, isNot(equals(base)));
      expect(on.hashCode, isNot(equals(base.hashCode)));
      expect(on, equals(base.copyWith(motionConfirmationEnabled: true)));
    });
  });
}

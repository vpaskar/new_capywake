import 'dart:convert';

import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/database/mappers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmMapper', () {
    test('toCompanion + fromRow round-trips a fully-populated alarm', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final t = DateTime.utc(2026, 5, 21, 8);
      final alarm = Alarm(
        id: 'a1',
        label: 'Workdays',
        enabled: true,
        targetTimeMinutes: 7 * 60,
        repeatWeekdays: const {2, 4, 6},
        wakeMode: WakeMode.gentle,
        wakeWindowStartMinutesBefore: 15,
        soundId: 'rain',
        vibrationEnabled: false,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        maxSnoozes: null,
        dismissMethod: DismissMethod.puzzle,
        dismissChallengeDifficulty: DismissChallengeDifficulty.hard,
        confirmationEnabled: true,
        motionConfirmationEnabled: true,
        createdAt: t,
        updatedAt: t,
      );

      await db.into(db.alarms).insert(AlarmMapper.toCompanion(alarm));
      final row = await db.select(db.alarms).getSingle();
      final restored = AlarmMapper.fromRow(row);
      expect(restored, equals(alarm));
    });

    test('fromRow rejects unknown WakeMode value', () {
      final row = AlarmRow(
        id: 'a1',
        label: '',
        enabled: true,
        targetTimeMinutes: 0,
        repeatWeekdaysCsv: '',
        wakeMode: 'imaginary',
        wakeWindowStartMinutesBefore: 0,
        soundId: '',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        dismissMethod: 'normalButton',
        confirmationEnabled: false,
        motionConfirmationEnabled: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(() => AlarmMapper.fromRow(row), throwsFormatException);
    });

    test('fromRow rejects unknown DismissMethod value', () {
      final row = AlarmRow(
        id: 'a1',
        label: '',
        enabled: true,
        targetTimeMinutes: 0,
        repeatWeekdaysCsv: '',
        wakeMode: 'standard',
        wakeWindowStartMinutesBefore: 0,
        soundId: '',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        dismissMethod: 'voiceCommand',
        confirmationEnabled: false,
        motionConfirmationEnabled: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(() => AlarmMapper.fromRow(row), throwsFormatException);
    });

    test(
      'fromRow rejects unknown DismissChallengeDifficulty value',
      () {
        final row = AlarmRow(
          id: 'a1',
          label: '',
          enabled: true,
          targetTimeMinutes: 0,
          repeatWeekdaysCsv: '',
          wakeMode: 'standard',
          wakeWindowStartMinutesBefore: 0,
          soundId: '',
          vibrationEnabled: true,
          snoozeEnabled: true,
          snoozeDurationMinutes: 9,
          dismissMethod: 'mathChallenge',
          dismissChallengeDifficulty: 'impossible',
          confirmationEnabled: false,
          motionConfirmationEnabled: false,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        expect(() => AlarmMapper.fromRow(row), throwsFormatException);
      },
    );

    test('fromRow reads the legacy mathChallenge value as the puzzle', () {
      // Pre-pivot builds wrote 'mathChallenge' for the math-only dismiss
      // challenge. The generated wake puzzle replaced that mechanism
      // wholesale, so an alarm configured for it wants the puzzle — reading
      // the old string preserves the user's intent without a migration.
      final row = AlarmRow(
        id: 'a1',
        label: '',
        enabled: true,
        targetTimeMinutes: 0,
        repeatWeekdaysCsv: '',
        wakeMode: 'standard',
        wakeWindowStartMinutesBefore: 0,
        soundId: '',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        dismissMethod: 'mathChallenge',
        dismissChallengeDifficulty: 'medium',
        confirmationEnabled: false,
        motionConfirmationEnabled: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final alarm = AlarmMapper.fromRow(row);
      expect(alarm.dismissMethod, DismissMethod.puzzle);
      expect(
        alarm.dismissChallengeDifficulty,
        DismissChallengeDifficulty.medium,
      );
      // New rows write the current name.
      expect(
        AlarmMapper.toCompanion(alarm).dismissMethod.value,
        'puzzle',
      );
    });

    test('fromRow rejects malformed weekday CSV (out-of-range)', () {
      final row = AlarmRow(
        id: 'a1',
        label: '',
        enabled: true,
        targetTimeMinutes: 0,
        repeatWeekdaysCsv: '1,2,9',
        wakeMode: 'standard',
        wakeWindowStartMinutesBefore: 0,
        soundId: '',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        dismissMethod: 'normalButton',
        confirmationEnabled: false,
        motionConfirmationEnabled: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(() => AlarmMapper.fromRow(row), throwsFormatException);
    });

    test('weekday CSV tolerates whitespace and a trailing comma', () {
      final row = AlarmRow(
        id: 'a1',
        label: '',
        enabled: true,
        targetTimeMinutes: 0,
        repeatWeekdaysCsv: ' 1 , 2 ,3,',
        wakeMode: 'standard',
        wakeWindowStartMinutesBefore: 0,
        soundId: '',
        vibrationEnabled: true,
        snoozeEnabled: true,
        snoozeDurationMinutes: 9,
        dismissMethod: 'normalButton',
        confirmationEnabled: false,
        motionConfirmationEnabled: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(AlarmMapper.fromRow(row).repeatWeekdays, {1, 2, 3});
    });
  });

  group('AlarmOccurrenceMapper', () {
    test('toCompanion + fromRow round-trips every field', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      // Need a parent alarm row for the FK.
      await db
          .into(db.alarms)
          .insert(
            AlarmsCompanion.insert(
              id: 'a1',
              targetTimeMinutes: 0,
              wakeMode: 'standard',
              dismissMethod: 'normalButton',
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          );

      final occ = AlarmOccurrence(
        id: 'o1',
        alarmId: 'a1',
        scheduledAt: DateTime.utc(2026, 5, 22, 7),
        softStartAt: DateTime.utc(2026, 5, 22, 6, 45),
        status: AlarmStatus.snoozed,
        triggeredAt: DateTime.utc(2026, 5, 22, 7),
        dismissedAt: DateTime.utc(2026, 5, 22, 7, 5),
        snoozeCount: 2,
        note: 'Snoozed twice',
      );
      await db
          .into(db.alarmOccurrences)
          .insert(AlarmOccurrenceMapper.toCompanion(occ));
      final row = await db.select(db.alarmOccurrences).getSingle();
      expect(AlarmOccurrenceMapper.fromRow(row), equals(occ));
    });

    test('fromRow rejects unknown AlarmStatus', () {
      final row = AlarmOccurrenceRow(
        id: 'o1',
        alarmId: 'a1',
        scheduledAt: DateTime.utc(2026),
        status: 'pending',
        snoozeCount: 0,
        note: '',
        isMotionReRing: false,
      );
      expect(
        () => AlarmOccurrenceMapper.fromRow(row),
        throwsFormatException,
      );
    });
  });

  group('UserSettingsMapper', () {
    test('toJson + fromJson is symmetric for the initial settings', () {
      const s = UserSettings.initial;
      final json = UserSettingsMapper.toJson(s);
      expect(UserSettingsMapper.fromJson(json), equals(s));
    });

    test('toJson + fromJson is symmetric for fully-populated settings', () {
      final s = UserSettings.initial.copyWith(
        defaultWakeMode: WakeMode.gentle,
        defaultSoundId: 'rain',
        defaultSnoozeMinutes: 7,
        timeFormat: TimeFormatPreference.h24,
        themeMode: ThemeModePreference.dark,
        reliabilityChecklistState: ReliabilityChecklistState.empty
            .copyWithItem(
              ReliabilityChecklistItem.notificationPermission,
              ChecklistItemState.ok,
            )
            .copyWithItem(
              ReliabilityChecklistItem.exactAlarmPermission,
              ChecklistItemState.actionRequired,
            )
            .copyWithItem(
              ReliabilityChecklistItem.alarmVolume,
              ChecklistItemState.unknown,
            ),
      );
      final json = UserSettingsMapper.toJson(s);
      expect(UserSettingsMapper.fromJson(json), equals(s));
    });

    test('fromJson tolerates missing keys and falls back to initial', () {
      // The empty object is a stand-in for "an older row that pre-dates
      // a field" — an addition must not require a schema migration.
      final s = UserSettingsMapper.fromJson('{}');
      // Every field falls back to the initial value except the onboarding
      // flag, which reads the row's mere existence as evidence that this
      // install predates first-run setup. See the next test.
      expect(
        s,
        equals(UserSettings.initial.copyWith(hasCompletedOnboarding: true)),
      );
    });

    test('fromJson grandfathers a row written before onboarding existed', () {
      // A stored settings row with no `hasCompletedOnboarding` key can only
      // have been written by a build that had no onboarding to complete. The
      // person behind it has been using CapyWake for a while and must not be
      // dropped into first-run setup by an update.
      final upgraded = UserSettingsMapper.fromJson(
        jsonEncode({'defaultSnoozeMinutes': 7}),
      );
      expect(upgraded.hasCompletedOnboarding, isTrue);
      expect(upgraded.defaultSnoozeMinutes, 7);

      // A genuinely fresh install never reaches that branch — it has no row
      // at all, so the repository hands back `UserSettings.initial`.
      expect(UserSettings.initial.hasCompletedOnboarding, isFalse);
    });

    test('fromJson honours a stored false rather than grandfathering it', () {
      // Once the key is written, it means what it says. Somebody who opened
      // Settings mid-flow and came back must still see the rest of setup.
      final s = UserSettingsMapper.fromJson(
        jsonEncode({'hasCompletedOnboarding': false}),
      );
      expect(s.hasCompletedOnboarding, isFalse);
    });

    test('toJson/fromJson round-trips the onboarding flag both ways', () {
      for (final completed in [true, false]) {
        final source = UserSettings.initial.copyWith(
          hasCompletedOnboarding: completed,
        );
        final reread = UserSettingsMapper.fromJson(
          UserSettingsMapper.toJson(source),
        );
        expect(reread.hasCompletedOnboarding, completed);
        expect(reread, equals(source));
      }
    });

    test('fromJson tolerates an unknown enum value (skips it)', () {
      final raw = jsonEncode({
        'defaultWakeMode': 'imaginary', // unknown -> falls back to standard
        'reliabilityChecklistState': {
          'notificationPermission': 'ok',
          'unknownItem': 'ok', // dropped
          'alarmVolume': 'glow', // dropped
        },
      });
      final s = UserSettingsMapper.fromJson(raw);
      expect(s.defaultWakeMode, WakeMode.standard);
      expect(
        s.reliabilityChecklistState.stateOf(
          ReliabilityChecklistItem.notificationPermission,
        ),
        ChecklistItemState.ok,
      );
      expect(
        s.reliabilityChecklistState.stateOf(
          ReliabilityChecklistItem.alarmVolume,
        ),
        ChecklistItemState.unknown,
      );
    });
  });

  group('ProStatusMapper', () {
    test('toJson + fromJson is symmetric', () {
      final s = ProStatus(
        isPro: true,
        purchaseSource: ProPurchaseSource.restore,
        updatedAt: DateTime.utc(2026, 5, 21, 8),
      );
      expect(ProStatusMapper.fromJson(ProStatusMapper.toJson(s)), equals(s));
    });

    test('fromJson tolerates missing keys / unknown source', () {
      final raw = jsonEncode({
        'isPro': true,
        'purchaseSource': 'imaginary',
      });
      final s = ProStatusMapper.fromJson(raw);
      expect(s.isPro, isTrue);
      expect(s.purchaseSource, ProPurchaseSource.none);
      expect(s.updatedAt, ProStatus.initial.updatedAt);
    });
  });
}

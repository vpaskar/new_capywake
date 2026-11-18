import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

Alarm _alarm({
  String id = 'a1',
  Set<int>? repeatWeekdays,
  WakeMode wakeMode = WakeMode.standard,
  DismissMethod dismissMethod = DismissMethod.normalButton,
  DismissChallengeDifficulty? dismissChallengeDifficulty,
  int? maxSnoozes = 5,
  int targetTimeMinutes = 7 * 60,
  String label = 'Workdays',
  bool confirmationEnabled = false,
  AlarmPuzzleOverride? puzzleOverride,
}) {
  return Alarm(
    id: id,
    label: label,
    enabled: true,
    targetTimeMinutes: targetTimeMinutes,
    repeatWeekdays: repeatWeekdays ?? {1, 2, 3, 4, 5},
    wakeMode: wakeMode,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'sand',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: maxSnoozes,
    dismissMethod: dismissMethod,
    dismissChallengeDifficulty: dismissChallengeDifficulty,
    puzzleOverride: puzzleOverride,
    confirmationEnabled: confirmationEnabled,
    createdAt: DateTime.utc(2026, 5, 21, 8),
    updatedAt: DateTime.utc(2026, 5, 21, 8),
  );
}

void main() {
  group('Alarm', () {
    test('two alarms with the same field values are value-equal', () {
      final a = _alarm();
      final b = _alarm();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('repeatWeekdays equality is order-independent', () {
      // {1,2,3,4,5} should equal a freshly-built {5,4,3,2,1}.
      final a = _alarm(repeatWeekdays: {1, 2, 3, 4, 5});
      final b = _alarm(repeatWeekdays: {5, 4, 3, 2, 1});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('changing any field breaks equality', () {
      final base = _alarm();
      expect(base, isNot(equals(_alarm(label: 'Different'))));
      expect(base, isNot(equals(_alarm(targetTimeMinutes: 8 * 60))));
      expect(base, isNot(equals(_alarm(repeatWeekdays: {1}))));
      expect(base, isNot(equals(_alarm(wakeMode: WakeMode.gentle))));
      expect(
        base,
        isNot(equals(_alarm(dismissMethod: DismissMethod.holdToDismiss))),
      );
      expect(
        base,
        isNot(equals(_alarm(maxSnoozes: null))),
      );
    });

    test('identical instance shortcut returns true', () {
      final a = _alarm();
      expect(a == a, isTrue);
    });

    test('inequality with a different runtime type', () {
      // Intentional cross-type compare to exercise the type check in `==`.
      // ignore: unrelated_type_equality_checks
      expect(_alarm() == 'not-an-alarm', isFalse);
    });

    test('copyWith replaces only specified fields', () {
      final base = _alarm();
      final copy = base.copyWith(label: 'Yoga', enabled: false);
      expect(copy.label, 'Yoga');
      expect(copy.enabled, isFalse);
      expect(copy.id, base.id);
      expect(copy.targetTimeMinutes, base.targetTimeMinutes);
      expect(copy.repeatWeekdays, base.repeatWeekdays);
    });

    test('copyWith with no arguments is value-equal to the original', () {
      final base = _alarm();
      expect(base.copyWith(), equals(base));
    });

    test(
      'copyWith(clearDismissChallengeDifficulty: true) clears the field',
      () {
        final base = _alarm(
          dismissMethod: DismissMethod.puzzle,
          dismissChallengeDifficulty: DismissChallengeDifficulty.medium,
        );
        // Switch to a non-challenge method and clear the difficulty.
        final cleared = base.copyWith(
          dismissMethod: DismissMethod.normalButton,
          clearDismissChallengeDifficulty: true,
        );
        expect(cleared.dismissChallengeDifficulty, isNull);
        expect(cleared.dismissMethod, DismissMethod.normalButton);
      },
    );

    test('copyWith(clearMaxSnoozes: true) clears the cap', () {
      final base = _alarm();
      final cleared = base.copyWith(clearMaxSnoozes: true);
      expect(cleared.maxSnoozes, isNull);
    });

    test('copyWith updates every field', () {
      final base = _alarm();
      final created = DateTime.utc(2024);
      final updated = DateTime.utc(2025);
      final next = base.copyWith(
        id: 'b1',
        label: 'X',
        enabled: false,
        targetTimeMinutes: 600,
        repeatWeekdays: {7},
        wakeMode: WakeMode.strict,
        wakeWindowStartMinutesBefore: 0,
        soundId: 'rain',
        vibrationEnabled: false,
        snoozeEnabled: false,
        snoozeDurationMinutes: 1,
        maxSnoozes: 1,
        dismissMethod: DismissMethod.puzzle,
        dismissChallengeDifficulty: DismissChallengeDifficulty.hard,
        confirmationEnabled: true,
        createdAt: created,
        updatedAt: updated,
      );
      expect(next.id, 'b1');
      expect(next.label, 'X');
      expect(next.enabled, isFalse);
      expect(next.targetTimeMinutes, 600);
      expect(next.repeatWeekdays, {7});
      expect(next.wakeMode, WakeMode.strict);
      expect(next.wakeWindowStartMinutesBefore, 0);
      expect(next.soundId, 'rain');
      expect(next.vibrationEnabled, isFalse);
      expect(next.snoozeEnabled, isFalse);
      expect(next.snoozeDurationMinutes, 1);
      expect(next.maxSnoozes, 1);
      expect(next.dismissMethod, DismissMethod.puzzle);
      expect(
        next.dismissChallengeDifficulty,
        DismissChallengeDifficulty.hard,
      );
      expect(next.confirmationEnabled, isTrue);
      expect(next.createdAt, created);
      expect(next.updatedAt, updated);
    });

    test('rejects challenge difficulty for non-challenge dismiss methods', () {
      expect(
        () => _alarm(
          dismissChallengeDifficulty: DismissChallengeDifficulty.easy,
        ),
        throwsArgumentError,
      );
    });

    test('accepts midnight (0) and the last minute (1439) as targets', () {
      expect(_alarm(targetTimeMinutes: 0), isNotNull);
      expect(_alarm(targetTimeMinutes: 1439), isNotNull);
    });
  });

  group('Alarm.resolvePuzzleSettings', () {
    PuzzleSettings defaults() => PuzzleSettings(
      enabledTypes: const {PuzzleType.arithmetic, PuzzleType.sequenceNext},
      taskCount: 2,
      toleratedWrongAnswers: 4,
    );

    test('an un-customised alarm follows every default', () {
      final alarm = _alarm(dismissMethod: DismissMethod.puzzle);
      expect(alarm.puzzleOverride, isNull);
      expect(alarm.dismissChallengeDifficulty, isNull);
      expect(alarm.dismissMethod, DismissMethod.puzzle);
      expect(alarm.resolvePuzzleSettings(defaults()), defaults());
    });

    test('the stored difficulty wins over the default', () {
      final alarm = _alarm(
        dismissMethod: DismissMethod.puzzle,
        dismissChallengeDifficulty: DismissChallengeDifficulty.hard,
      );
      final resolved = alarm.resolvePuzzleSettings(defaults());
      expect(resolved.difficulty, PuzzleDifficulty.hard);
      // Everything else still tracks the defaults.
      expect(resolved.enabledTypes, defaults().enabledTypes);
      expect(resolved.taskCount, defaults().taskCount);
    });

    test('an override wins field by field', () {
      final alarm = _alarm(
        dismissMethod: DismissMethod.puzzle,
        puzzleOverride: AlarmPuzzleOverride(
          enabledTypes: const {PuzzleType.shapeRotation},
          taskCount: 5,
        ),
      );
      final resolved = alarm.resolvePuzzleSettings(defaults());
      expect(resolved.enabledTypes, {PuzzleType.shapeRotation});
      expect(resolved.taskCount, 5);
      expect(resolved.toleratedWrongAnswers, defaults().toleratedWrongAnswers);
      expect(resolved.escapeStrictness, defaults().escapeStrictness);
    });

    test('an un-overridden field moves with the defaults', () {
      final alarm = _alarm(
        dismissMethod: DismissMethod.puzzle,
        puzzleOverride: AlarmPuzzleOverride(taskCount: 5),
      );
      expect(
        alarm.resolvePuzzleSettings(defaults()).toleratedWrongAnswers,
        4,
      );
      expect(
        alarm
            .resolvePuzzleSettings(
              defaults().copyWith(toleratedWrongAnswers: 8),
            )
            .toleratedWrongAnswers,
        8,
      );
    });

    test('resolves to a configuration that is always solvable + escapable', () {
      final alarm = _alarm(
        dismissMethod: DismissMethod.puzzle,
        puzzleOverride: AlarmPuzzleOverride(
          enabledTypes: const {PuzzleType.gridPatternRecall},
          taskCount: PuzzleSettings.maxTaskCount,
          toleratedWrongAnswers: PuzzleSettings.maxToleratedWrongAnswers,
          escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
        ),
      );
      final resolved = alarm.resolvePuzzleSettings(defaults());
      expect(resolved.enabledTypes, isNotEmpty);
      expect(
        PuzzleEscapeStrictness.values,
        contains(resolved.escapeStrictness),
      );
    });
  });

  group('Alarm.puzzleOverride', () {
    test('is rejected on a non-puzzle dismiss method', () {
      expect(
        () => _alarm(
          puzzleOverride: AlarmPuzzleOverride(taskCount: 2),
        ),
        throwsArgumentError,
      );
    });

    test('clearPuzzleOverride drops it', () {
      final alarm = _alarm(
        dismissMethod: DismissMethod.puzzle,
        puzzleOverride: AlarmPuzzleOverride(taskCount: 2),
      );
      expect(alarm.copyWith(clearPuzzleOverride: true).puzzleOverride, isNull);
    });

    test('participates in equality and hashCode', () {
      final base = _alarm(dismissMethod: DismissMethod.puzzle);
      final withOverride = base.copyWith(
        puzzleOverride: AlarmPuzzleOverride(taskCount: 2),
      );
      expect(base == withOverride, isFalse);
      expect(
        withOverride,
        base.copyWith(puzzleOverride: AlarmPuzzleOverride(taskCount: 2)),
      );
      expect(
        withOverride.hashCode,
        base
            .copyWith(puzzleOverride: AlarmPuzzleOverride(taskCount: 2))
            .hashCode,
      );
    });
  });

  group('Alarm.artId', () {
    test('defaults to following the list position', () {
      expect(_alarm().artId, isNull);
    });

    test('copyWith sets, keeps and clears it', () {
      final none = _alarm().copyWith(artId: Alarm.noArtId);
      expect(none.artId, Alarm.noArtId);
      expect(none.copyWith(label: 'Yoga').artId, Alarm.noArtId);
      expect(none.copyWith(clearArtId: true).artId, isNull);
    });

    test('it participates in equality and hashing', () {
      final base = _alarm();
      final walk = base.copyWith(artId: 'thumb.walk');
      expect(walk, isNot(equals(base)));
      expect(walk.hashCode, isNot(equals(base.hashCode)));
      expect(walk, equals(base.copyWith(artId: 'thumb.walk')));
    });
  });

  group('Alarm.motionConfirmationEnabled', () {
    test('defaults to off so an alarm never gains a sensor by accident', () {
      expect(_alarm().motionConfirmationEnabled, isFalse);
    });

    test('copyWith carries it in both directions', () {
      final on = _alarm().copyWith(motionConfirmationEnabled: true);
      expect(on.motionConfirmationEnabled, isTrue);
      expect(
        on.copyWith(motionConfirmationEnabled: false).motionConfirmationEnabled,
        isFalse,
      );
    });

    test('copyWith leaves it alone when not named', () {
      final on = _alarm().copyWith(motionConfirmationEnabled: true);
      expect(on.copyWith(label: 'Yoga').motionConfirmationEnabled, isTrue);
    });

    test('it participates in equality and hashing', () {
      final base = _alarm();
      final on = base.copyWith(motionConfirmationEnabled: true);
      expect(on, isNot(equals(base)));
      expect(on.hashCode, isNot(equals(base.hashCode)));
      expect(on, equals(base.copyWith(motionConfirmationEnabled: true)));
      expect(
        on.hashCode,
        equals(base.copyWith(motionConfirmationEnabled: true).hashCode),
      );
    });

    test('it is independent of confirmationEnabled', () {
      // Sibling, not modifier: the two flags move on their own so the motion
      // check never depends on having picked a particular wake mode.
      final motionOnly = _alarm().copyWith(motionConfirmationEnabled: true);
      expect(motionOnly.confirmationEnabled, isFalse);
      final tapOnly = _alarm(confirmationEnabled: true);
      expect(tapOnly.motionConfirmationEnabled, isFalse);
    });
  });
}

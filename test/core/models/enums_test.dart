import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WakeMode', () {
    test('exposes the three MVP modes only (Phase 00 scope cut: 5 → 3)', () {
      expect(WakeMode.values, [
        WakeMode.gentle,
        WakeMode.standard,
        WakeMode.strict,
      ]);
    });

    test('Gentle keeps a long wake window and unlimited snoozes', () {
      final d = WakeMode.gentle.descriptor;
      expect(d.defaultWakeWindowStartMinutesBefore, 15);
      expect(d.defaultMaxSnoozes, isNull);
      expect(d.confirmationRequired, isFalse);
    });

    test('Standard rings at the target with a small snooze cap', () {
      final d = WakeMode.standard.descriptor;
      expect(d.defaultWakeWindowStartMinutesBefore, 0);
      expect(d.defaultMaxSnoozes, 5);
      expect(d.confirmationRequired, isFalse);
    });

    test('Strict short snoozes, capped, with confirmation', () {
      final d = WakeMode.strict.descriptor;
      expect(d.defaultSnoozeDurationMinutes, 5);
      expect(d.defaultMaxSnoozes, 2);
      expect(d.confirmationRequired, isTrue);
    });
  });

  group('WakeModeDescriptor', () {
    test('value-equal on identical fields', () {
      const a = WakeModeDescriptor(
        defaultWakeWindowStartMinutesBefore: 10,
        defaultSnoozeDurationMinutes: 9,
        defaultMaxSnoozes: 3,
        confirmationRequired: false,
      );
      const b = WakeModeDescriptor(
        defaultWakeWindowStartMinutesBefore: 10,
        defaultSnoozeDurationMinutes: 9,
        defaultMaxSnoozes: 3,
        confirmationRequired: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == a, isTrue);
    });

    test('inequality fans out across each field and unrelated types', () {
      const base = WakeModeDescriptor(
        defaultWakeWindowStartMinutesBefore: 10,
        defaultSnoozeDurationMinutes: 9,
        defaultMaxSnoozes: 3,
        confirmationRequired: false,
      );
      const diffs = [
        WakeModeDescriptor(
          defaultWakeWindowStartMinutesBefore: 11, // <-
          defaultSnoozeDurationMinutes: 9,
          defaultMaxSnoozes: 3,
          confirmationRequired: false,
        ),
        WakeModeDescriptor(
          defaultWakeWindowStartMinutesBefore: 10,
          defaultSnoozeDurationMinutes: 7, // <-
          defaultMaxSnoozes: 3,
          confirmationRequired: false,
        ),
        WakeModeDescriptor(
          defaultWakeWindowStartMinutesBefore: 10,
          defaultSnoozeDurationMinutes: 9,
          defaultMaxSnoozes: 99, // <-
          confirmationRequired: false,
        ),
        WakeModeDescriptor(
          defaultWakeWindowStartMinutesBefore: 10,
          defaultSnoozeDurationMinutes: 9,
          defaultMaxSnoozes: 3,
          confirmationRequired: true, // <-
        ),
      ];
      for (final d in diffs) {
        expect(base, isNot(equals(d)));
      }
      // Intentional cross-type compare to exercise the type check in `==`.
      // ignore: unrelated_type_equality_checks
      expect(base == 42, isFalse);
    });
  });

  group('DismissMethod', () {
    test('only the MVP dismiss methods are present', () {
      expect(DismissMethod.values, [
        DismissMethod.normalButton,
        DismissMethod.holdToDismiss,
        DismissMethod.puzzle,
      ]);
    });
  });

  group('DismissChallengeDifficulty', () {
    test('exposes easy/medium/hard', () {
      expect(DismissChallengeDifficulty.values, [
        DismissChallengeDifficulty.easy,
        DismissChallengeDifficulty.medium,
        DismissChallengeDifficulty.hard,
      ]);
    });

    test('maps onto the puzzle engine scale', () {
      // The one point the persisted per-alarm setting and the engine's own
      // scale meet — kept separate so the engine can evolve without a schema
      // migration.
      expect(
        DismissChallengeDifficulty.easy.toPuzzleDifficulty(),
        PuzzleDifficulty.easy,
      );
      expect(
        DismissChallengeDifficulty.medium.toPuzzleDifficulty(),
        PuzzleDifficulty.medium,
      );
      expect(
        DismissChallengeDifficulty.hard.toPuzzleDifficulty(),
        PuzzleDifficulty.hard,
      );
    });

    test('maps back from the engine scale to the persisted one', () {
      expect(
        DismissChallengeDifficulty.fromPuzzleDifficulty(PuzzleDifficulty.easy),
        DismissChallengeDifficulty.easy,
      );
      expect(
        DismissChallengeDifficulty.fromPuzzleDifficulty(
          PuzzleDifficulty.medium,
        ),
        DismissChallengeDifficulty.medium,
      );
      expect(
        DismissChallengeDifficulty.fromPuzzleDifficulty(PuzzleDifficulty.hard),
        DismissChallengeDifficulty.hard,
      );
    });

    test('the two directions round-trip for every value', () {
      // The bridge is only safe to rely on if it is lossless in both
      // directions — the alarm form converts one way, the ringing surface the
      // other, and a mismatch would silently change someone's difficulty.
      for (final stored in DismissChallengeDifficulty.values) {
        expect(
          DismissChallengeDifficulty.fromPuzzleDifficulty(
            stored.toPuzzleDifficulty(),
          ),
          stored,
        );
      }
      for (final engine in PuzzleDifficulty.values) {
        expect(
          DismissChallengeDifficulty.fromPuzzleDifficulty(
            engine,
          ).toPuzzleDifficulty(),
          engine,
        );
      }
    });
  });

  group('AlarmStatus', () {
    test('lists every state used by the lifecycle service', () {
      expect(AlarmStatus.values, [
        AlarmStatus.scheduled,
        AlarmStatus.triggered,
        AlarmStatus.snoozed,
        AlarmStatus.dismissed,
        AlarmStatus.skipped,
        AlarmStatus.escaped,
        AlarmStatus.missed,
      ]);
    });

    test('isTerminal names exactly the four states a morning ends in', () {
      expect(
        AlarmStatus.values.where((s) => s.isTerminal).toSet(),
        {
          AlarmStatus.dismissed,
          AlarmStatus.skipped,
          AlarmStatus.escaped,
          AlarmStatus.missed,
        },
      );
    });

    test('the live states are not terminal', () {
      // `triggered` matters most: an alarm that is ringing right now must not
      // have its morning retired out from under it.
      expect(AlarmStatus.scheduled.isTerminal, isFalse);
      expect(AlarmStatus.triggered.isTerminal, isFalse);
      expect(AlarmStatus.snoozed.isTerminal, isFalse);
    });
  });

  group('TimeFormatPreference & ThemeModePreference', () {
    test('three values each, system-default first', () {
      expect(TimeFormatPreference.values.first, TimeFormatPreference.system);
      expect(ThemeModePreference.values.first, ThemeModePreference.system);
      expect(TimeFormatPreference.values.length, 3);
      expect(ThemeModePreference.values.length, 3);
    });
  });
}

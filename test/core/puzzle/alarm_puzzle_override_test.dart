import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleSettings _defaults() => PuzzleSettings(
  enabledTypes: const {PuzzleType.arithmetic, PuzzleType.sequenceNext},
  taskCount: 2,
  toleratedWrongAnswers: 4,
);

void main() {
  group('AlarmPuzzleOverride construction', () {
    test('an empty override is the "follows the defaults" shape', () {
      final override = AlarmPuzzleOverride();
      expect(override.isEmpty, isTrue);
      expect(override.enabledTypes, isNull);
      expect(override.taskCount, isNull);
      expect(override.toleratedWrongAnswers, isNull);
      expect(override.escapeStrictness, isNull);
    });

    test('any set field makes the override non-empty', () {
      expect(AlarmPuzzleOverride(taskCount: 2).isEmpty, isFalse);
      expect(
        AlarmPuzzleOverride(
          enabledTypes: const {PuzzleType.arithmetic},
        ).isEmpty,
        isFalse,
      );
      expect(
        AlarmPuzzleOverride(toleratedWrongAnswers: 0).isEmpty,
        isFalse,
      );
      expect(
        AlarmPuzzleOverride(
          escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
        ).isEmpty,
        isFalse,
      );
    });

    test('rejects an explicitly empty enabled-type set', () {
      // A per-alarm override must not be a way around the rule that the
      // app-wide settings enforce.
      expect(
        () => AlarmPuzzleOverride(enabledTypes: const <PuzzleType>{}),
        throwsArgumentError,
      );
    });

    test('rejects out-of-range counts, same bounds as the defaults', () {
      expect(
        () => AlarmPuzzleOverride(
          taskCount: PuzzleSettings.minTaskCount - 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => AlarmPuzzleOverride(
          taskCount: PuzzleSettings.maxTaskCount + 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => AlarmPuzzleOverride(
          toleratedWrongAnswers: PuzzleSettings.minToleratedWrongAnswers - 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => AlarmPuzzleOverride(
          toleratedWrongAnswers: PuzzleSettings.maxToleratedWrongAnswers + 1,
        ),
        throwsArgumentError,
      );
    });

    test('accepts the bounds themselves', () {
      expect(
        AlarmPuzzleOverride(
          taskCount: PuzzleSettings.maxTaskCount,
          toleratedWrongAnswers: PuzzleSettings.minToleratedWrongAnswers,
        ).taskCount,
        PuzzleSettings.maxTaskCount,
      );
    });

    test('copies the enabled set so later mutation cannot reach in', () {
      final source = {PuzzleType.arithmetic};
      final override = AlarmPuzzleOverride(enabledTypes: source);
      source.add(PuzzleType.shapeRotation);
      expect(override.enabledTypes, {PuzzleType.arithmetic});
    });

    test('the stored set is unmodifiable', () {
      final override = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.arithmetic},
      );
      expect(
        () => override.enabledTypes!.add(PuzzleType.sequenceNext),
        throwsUnsupportedError,
      );
    });
  });

  group('AlarmPuzzleOverride.from', () {
    test('pins every field to the given settings', () {
      final settings = PuzzleSettings(
        enabledTypes: const {PuzzleType.digitRecall},
        taskCount: 4,
        difficulty: PuzzleDifficulty.hard,
        toleratedWrongAnswers: 1,
        escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
      );
      final override = AlarmPuzzleOverride.from(settings);
      expect(override.isEmpty, isFalse);
      expect(override.enabledTypes, {PuzzleType.digitRecall});
      expect(override.taskCount, 4);
      expect(override.toleratedWrongAnswers, 1);
      expect(
        override.escapeStrictness,
        PuzzleEscapeStrictness.confirmAndHold,
      );
    });

    test('resolves back to the settings it was taken from', () {
      final settings = PuzzleSettings(
        enabledTypes: const {PuzzleType.spotTheChange},
        taskCount: 3,
        toleratedWrongAnswers: 5,
      );
      final resolved = AlarmPuzzleOverride.resolveFor(
        defaults: PuzzleSettings.defaults(),
        override: AlarmPuzzleOverride.from(settings),
        difficulty: DismissChallengeDifficulty.fromPuzzleDifficulty(
          settings.difficulty,
        ),
      );
      expect(resolved, settings);
    });
  });

  group('AlarmPuzzleOverride.resolveFor', () {
    test('a null override follows every default', () {
      final defaults = _defaults();
      expect(
        AlarmPuzzleOverride.resolveFor(defaults: defaults),
        defaults,
      );
    });

    test('an empty override follows every default', () {
      final defaults = _defaults();
      expect(
        AlarmPuzzleOverride.resolveFor(
          defaults: defaults,
          override: AlarmPuzzleOverride(),
        ),
        defaults,
      );
    });

    test('each field is overridden independently of the others', () {
      final defaults = _defaults();

      final types = AlarmPuzzleOverride.resolveFor(
        defaults: defaults,
        override: AlarmPuzzleOverride(
          enabledTypes: const {PuzzleType.shapeRotation},
        ),
      );
      expect(types.enabledTypes, {PuzzleType.shapeRotation});
      expect(types.taskCount, defaults.taskCount);
      expect(types.difficulty, defaults.difficulty);
      expect(types.toleratedWrongAnswers, defaults.toleratedWrongAnswers);
      expect(types.escapeStrictness, defaults.escapeStrictness);

      final tasks = AlarmPuzzleOverride.resolveFor(
        defaults: defaults,
        override: AlarmPuzzleOverride(taskCount: 5),
      );
      expect(tasks.taskCount, 5);
      expect(tasks.enabledTypes, defaults.enabledTypes);

      final tolerance = AlarmPuzzleOverride.resolveFor(
        defaults: defaults,
        override: AlarmPuzzleOverride(toleratedWrongAnswers: 0),
      );
      expect(tolerance.toleratedWrongAnswers, 0);
      expect(tolerance.taskCount, defaults.taskCount);

      final escape = AlarmPuzzleOverride.resolveFor(
        defaults: defaults,
        override: AlarmPuzzleOverride(
          escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
        ),
      );
      expect(escape.escapeStrictness, PuzzleEscapeStrictness.confirmAndHold);
      expect(escape.toleratedWrongAnswers, defaults.toleratedWrongAnswers);
    });

    test('difficulty comes from the alarm column, not the override', () {
      final defaults = _defaults();
      expect(
        AlarmPuzzleOverride.resolveFor(
          defaults: defaults,
          difficulty: DismissChallengeDifficulty.easy,
        ).difficulty,
        PuzzleDifficulty.easy,
      );
      // Null difficulty follows the default, exactly like every other field.
      expect(
        AlarmPuzzleOverride.resolveFor(defaults: defaults).difficulty,
        defaults.difficulty,
      );
    });

    test('an un-overridden field tracks the defaults as they change', () {
      final override = AlarmPuzzleOverride(taskCount: 4);
      final before = AlarmPuzzleOverride.resolveFor(
        defaults: _defaults(),
        override: override,
      );
      final after = AlarmPuzzleOverride.resolveFor(
        defaults: _defaults().copyWith(
          escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
        ),
        override: override,
      );
      expect(before.escapeStrictness, PuzzleEscapeStrictness.confirm);
      expect(after.escapeStrictness, PuzzleEscapeStrictness.confirmAndHold);
      // The overridden field is unmoved by the change.
      expect(after.taskCount, 4);
    });

    test('no override can produce an unsolvable or inescapable alarm', () {
      // Whatever an override says, the resolved settings still hold every
      // invariant: a non-empty type set, and an escape strictness with no
      // "off" value to select.
      for (final override in <AlarmPuzzleOverride?>[
        null,
        AlarmPuzzleOverride(),
        AlarmPuzzleOverride(enabledTypes: const {PuzzleType.gridPatternRecall}),
        AlarmPuzzleOverride(taskCount: PuzzleSettings.maxTaskCount),
        AlarmPuzzleOverride(
          toleratedWrongAnswers: PuzzleSettings.maxToleratedWrongAnswers,
        ),
        for (final s in PuzzleEscapeStrictness.values)
          AlarmPuzzleOverride(escapeStrictness: s),
      ]) {
        final resolved = AlarmPuzzleOverride.resolveFor(
          defaults: _defaults(),
          override: override,
        );
        expect(resolved.enabledTypes, isNotEmpty);
        expect(
          PuzzleEscapeStrictness.values,
          contains(resolved.escapeStrictness),
        );
      }
    });
  });

  group('AlarmPuzzleOverride value semantics', () {
    test('copyWith replaces only the given fields', () {
      final override = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.arithmetic},
        taskCount: 2,
        toleratedWrongAnswers: 1,
        escapeStrictness: PuzzleEscapeStrictness.confirm,
      );
      final next = override.copyWith(taskCount: 3);
      expect(next.taskCount, 3);
      expect(next.enabledTypes, {PuzzleType.arithmetic});
      expect(next.toleratedWrongAnswers, 1);
      expect(next.escapeStrictness, PuzzleEscapeStrictness.confirm);
    });

    test('equal overrides compare equal regardless of set order', () {
      final a = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.arithmetic, PuzzleType.sequenceNext},
        taskCount: 2,
      );
      final b = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.sequenceNext, PuzzleType.arithmetic},
        taskCount: 2,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, same(a));
    });

    test('each field participates in equality', () {
      final base = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.arithmetic},
        taskCount: 2,
        toleratedWrongAnswers: 1,
        escapeStrictness: PuzzleEscapeStrictness.confirm,
      );
      expect(
        base == base.copyWith(enabledTypes: const {PuzzleType.sequenceNext}),
        isFalse,
      );
      expect(base == base.copyWith(taskCount: 3), isFalse);
      expect(base == base.copyWith(toleratedWrongAnswers: 2), isFalse);
      expect(
        base ==
            base.copyWith(
              escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
            ),
        isFalse,
      );
      // ignore: unrelated_type_equality_checks — proves the type guard.
      expect(base == 'not an override', isFalse);
    });

    test('a null enabled set is distinguished from a populated one', () {
      final none = AlarmPuzzleOverride(taskCount: 2);
      final some = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.arithmetic},
        taskCount: 2,
      );
      expect(none == some, isFalse);
      expect(some == none, isFalse);
      expect(none, AlarmPuzzleOverride(taskCount: 2));
    });

    test('toString is diagnostic without dumping the whole set', () {
      final override = AlarmPuzzleOverride(
        enabledTypes: const {PuzzleType.arithmetic, PuzzleType.sequenceNext},
        taskCount: 2,
        toleratedWrongAnswers: 1,
        escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
      );
      expect(
        override.toString(),
        'AlarmPuzzleOverride(types: 2, tasks: 2, tolerated: 1, '
        'escape: confirmAndHold, games: null, puzzles: null)',
      );
      expect(
        AlarmPuzzleOverride().toString(),
        'AlarmPuzzleOverride(types: null, tasks: null, tolerated: null, '
        'escape: null, games: null, puzzles: null)',
      );
    });

    test('AlarmPuzzleOverride.none is the shared empty instance', () {
      expect(AlarmPuzzleOverride.none.isEmpty, isTrue);
      expect(AlarmPuzzleOverride.none, AlarmPuzzleOverride());
    });
  });

  group('AlarmPuzzleOverride.resolveFor', () {
    test('keeps the default enabled types', () {
      final resolved = AlarmPuzzleOverride.resolveFor(
        defaults: PuzzleSettings.defaults(),
      );
      expect(resolved.enabledTypes, PuzzleSettings.defaults().enabledTypes);
    });

    test('keeps every type selected in an override', () {
      final resolved = AlarmPuzzleOverride.resolveFor(
        defaults: PuzzleSettings.defaults(),
        override: AlarmPuzzleOverride(
          enabledTypes: const {PuzzleType.sequenceNext, PuzzleType.arithmetic},
        ),
      );
      expect(resolved.enabledTypes, {
        PuzzleType.sequenceNext,
        PuzzleType.arithmetic,
      });
    });

    test('leaves every other field alone', () {
      final resolved = AlarmPuzzleOverride.resolveFor(
        defaults: PuzzleSettings.defaults(),
        override: AlarmPuzzleOverride(
          taskCount: 4,
          toleratedWrongAnswers: 1,
          escapeStrictness: PuzzleEscapeStrictness.confirmAndHold,
        ),
      );
      expect(resolved.taskCount, 4);
      expect(resolved.toleratedWrongAnswers, 1);
      expect(
        resolved.escapeStrictness,
        PuzzleEscapeStrictness.confirmAndHold,
      );
    });

    test('uses the app defaults when no override is set', () {
      final defaults = PuzzleSettings.defaults();
      expect(
        AlarmPuzzleOverride.resolveFor(defaults: defaults).enabledTypes,
        defaults.enabledTypes,
      );
    });
  });
}

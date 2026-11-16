import 'package:capywake/core/puzzle/puzzle_selector.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleTypeSelector — never the same type twice in a row', () {
    test('a long run over every type never repeats back to back', () {
      final enabled = PuzzleType.values.toSet();
      final history = <PuzzleType>[];
      for (var seed = 0; seed < 500; seed++) {
        final next = PuzzleTypeSelector.next(
          enabled: enabled,
          recent: history,
          seed: seed,
        );
        if (history.isNotEmpty) {
          expect(
            next,
            isNot(history.last),
            reason: 'repeated ${next.name} at seed $seed',
          );
        }
        history.add(next);
      }
    });

    test('a two-type set simply alternates', () {
      final enabled = {PuzzleType.arithmetic, PuzzleType.sequenceNext};
      final history = <PuzzleType>[];
      for (var seed = 0; seed < 40; seed++) {
        history.add(
          PuzzleTypeSelector.next(
            enabled: enabled,
            recent: history,
            seed: seed,
          ),
        );
      }
      for (var i = 1; i < history.length; i++) {
        expect(history[i], isNot(history[i - 1]));
      }
    });

    test('a single enabled type is served every time', () {
      final enabled = {PuzzleType.arithmetic};
      final history = <PuzzleType>[];
      for (var seed = 0; seed < 20; seed++) {
        final next = PuzzleTypeSelector.next(
          enabled: enabled,
          recent: history,
          seed: seed,
        );
        expect(next, PuzzleType.arithmetic);
        history.add(next);
      }
    });

    test('all but one type disabled degrades to the single-type case', () {
      final next = PuzzleTypeSelector.next(
        enabled: {PuzzleType.gridPatternRecall},
        recent: const [PuzzleType.gridPatternRecall],
        seed: 7,
      );
      expect(next, PuzzleType.gridPatternRecall);
    });
  });

  group('PuzzleTypeSelector — no starvation', () {
    test('every enabled type is served within one pass over the set', () {
      final enabled = PuzzleType.values.toSet();
      final history = <PuzzleType>[];
      for (var seed = 0; seed < enabled.length; seed++) {
        history.add(
          PuzzleTypeSelector.next(
            enabled: enabled,
            recent: history,
            seed: seed,
          ),
        );
      }
      expect(history.toSet(), enabled);
    });

    test('a never-served type outranks every served one', () {
      final next = PuzzleTypeSelector.next(
        enabled: {
          PuzzleType.arithmetic,
          PuzzleType.sequenceNext,
          PuzzleType.shapeRotation,
        },
        recent: const [
          PuzzleType.shapeRotation,
          PuzzleType.sequenceNext,
          PuzzleType.arithmetic,
          PuzzleType.sequenceNext,
        ],
        seed: 3,
      );
      // arithmetic was served longer ago than sequenceNext, and shapeRotation
      // longer ago still — but shapeRotation is not excluded, so the
      // least-recently-served candidate wins.
      expect(next, PuzzleType.shapeRotation);
    });

    test('types absent from history are preferred over any served type', () {
      final next = PuzzleTypeSelector.next(
        enabled: {PuzzleType.arithmetic, PuzzleType.oddOneOutNumeric},
        recent: const [PuzzleType.arithmetic],
        seed: 1,
      );
      expect(next, PuzzleType.oddOneOutNumeric);
    });

    test('history entries for now-disabled types are ignored', () {
      final next = PuzzleTypeSelector.next(
        enabled: {PuzzleType.arithmetic, PuzzleType.compareValues},
        recent: const [PuzzleType.spotTheChange, PuzzleType.compareValues],
        seed: 5,
      );
      expect(next, PuzzleType.arithmetic);
    });
  });

  group('PuzzleTypeSelector — determinism and guards', () {
    test('the same seed and history always give the same type', () {
      for (var seed = 0; seed < 50; seed++) {
        final first = PuzzleTypeSelector.next(
          enabled: PuzzleType.values.toSet(),
          recent: const [],
          seed: seed,
        );
        final second = PuzzleTypeSelector.next(
          enabled: PuzzleType.values.toSet(),
          recent: const [],
          seed: seed,
        );
        expect(first, second);
      }
    });

    test('the result does not depend on the enabled set insertion order', () {
      final forwards = <PuzzleType>{...PuzzleType.values};
      final backwards = <PuzzleType>{...PuzzleType.values.reversed};
      for (var seed = 0; seed < 50; seed++) {
        expect(
          PuzzleTypeSelector.next(
            enabled: forwards,
            recent: const [PuzzleType.arithmetic],
            seed: seed,
          ),
          PuzzleTypeSelector.next(
            enabled: backwards,
            recent: const [PuzzleType.arithmetic],
            seed: seed,
          ),
        );
      }
    });

    test('an empty enabled set is rejected rather than silently handled', () {
      expect(
        () => PuzzleTypeSelector.next(
          enabled: const <PuzzleType>{},
          recent: const [],
          seed: 0,
        ),
        throwsArgumentError,
      );
    });

    test('an empty history is fine', () {
      expect(
        PuzzleTypeSelector.next(
          enabled: {PuzzleType.arithmetic, PuzzleType.digitRecall},
          recent: const [],
          seed: 0,
        ),
        isA<PuzzleType>(),
      );
    });

    test('selection spreads across the enabled set rather than fixating', () {
      final enabled = {
        PuzzleType.arithmetic,
        PuzzleType.sequenceNext,
        PuzzleType.compareValues,
        PuzzleType.digitRecall,
      };
      final counts = <PuzzleType, int>{};
      final history = <PuzzleType>[];
      for (var seed = 0; seed < 400; seed++) {
        final next = PuzzleTypeSelector.next(
          enabled: enabled,
          recent: history,
          seed: seed,
        );
        counts[next] = (counts[next] ?? 0) + 1;
        history.add(next);
      }
      expect(counts.keys.toSet(), enabled);
      for (final count in counts.values) {
        expect(count, greaterThan(400 ~/ (enabled.length * 2)));
      }
    });
  });
}

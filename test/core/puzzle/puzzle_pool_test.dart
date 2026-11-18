import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleSettings _s({
  Set<PuzzleType> types = const {PuzzleType.arithmetic},
  Set<String> games = const {},
  bool puzzles = true,
}) => PuzzleSettings(
  enabledTypes: types,
  enabledGames: games,
  includePuzzles: puzzles,
);

void main() {
  group('PuzzleSettings wake pool', () {
    test('defaults: puzzles in, no games', () {
      final d = PuzzleSettings.defaults();
      expect(d.includePuzzles, isTrue);
      expect(d.enabledGames, isEmpty);
    });

    test('puzzles excluded with no game is refused', () {
      expect(() => _s(puzzles: false), throwsArgumentError);
      expect(
        () => _s(
          games: {'catch_the_capy'},
        ).copyWith(includePuzzles: false, enabledGames: {}),
        throwsArgumentError,
      );
    });

    test('a games-only pool is allowed', () {
      final s = _s(games: {'catch_the_capy'}, puzzles: false);
      expect(s.includePuzzles, isFalse);
      expect(s.enabledTypes, isNotEmpty);
    });

    test('an unknown game id is refused', () {
      expect(() => _s(games: {'not_a_game'}), throwsArgumentError);
    });

    test('the game set cannot be mutated after construction', () {
      final s = _s(games: {'catch_the_capy'});
      expect(
        () => s.enabledGames.add('memory_hideout'),
        throwsUnsupportedError,
      );
    });

    test('equality and hash cover the pool', () {
      expect(
        _s(games: {'catch_the_capy', 'memory_hideout'}),
        _s(games: {'memory_hideout', 'catch_the_capy'}),
      );
      expect(
        _s(games: {'catch_the_capy'}).hashCode,
        _s(games: {'catch_the_capy'}).hashCode,
      );
      expect(_s(games: {'catch_the_capy'}), isNot(_s()));
      expect(
        _s(games: {'catch_the_capy'}),
        isNot(_s(games: {'catch_the_capy'}, puzzles: false)),
      );
    });

    test('copyWith keeps the pool unless told otherwise', () {
      final s = _s(games: {'memory_hideout'}, puzzles: false);
      final copy = s.copyWith(taskCount: 2);
      expect(copy.enabledGames, {'memory_hideout'});
      expect(copy.includePuzzles, isFalse);
    });

    group('isVisualOnly reads the whole pool', () {
      const visual = {PuzzleType.shapeRotation};

      test('visual types and no games are flagged', () {
        expect(_s(types: visual).isVisualOnly, isTrue);
      });

      test('a solvable game clears the flag', () {
        expect(
          _s(types: visual, games: {'catch_the_capy'}).isVisualOnly,
          isFalse,
        );
      });

      test('solvable types do not count once puzzles are excluded', () {
        final s = PuzzleSettings(
          enabledTypes: const {PuzzleType.arithmetic},
          enabledGames: const {'catch_the_capy'},
          includePuzzles: false,
        );
        expect(s.isVisualOnly, isFalse);
        expect(
          PuzzleSettings(
            enabledTypes: const {PuzzleType.arithmetic},
            enabledGames: const {'step_quest'},
            includePuzzles: false,
          ).isVisualOnly,
          isTrue,
          reason: 'step_quest is not screen-reader solvable',
        );
      });
    });
  });

  group('AlarmPuzzleOverride wake pool', () {
    test('puzzles off needs this override to name a game', () {
      expect(
        () => AlarmPuzzleOverride(includePuzzles: false),
        throwsArgumentError,
      );
      expect(
        () =>
            AlarmPuzzleOverride(includePuzzles: false, enabledGames: const {}),
        throwsArgumentError,
      );
      expect(
        AlarmPuzzleOverride(
          includePuzzles: false,
          enabledGames: const {'memory_hideout'},
        ).includePuzzles,
        isFalse,
      );
    });

    test('an unknown game id is refused', () {
      expect(
        () => AlarmPuzzleOverride(enabledGames: const {'nope'}),
        throwsArgumentError,
      );
    });

    test('from() pins the pool too', () {
      final o = AlarmPuzzleOverride.from(
        _s(games: {'catch_the_capy'}, puzzles: false),
      );
      expect(o.enabledGames, {'catch_the_capy'});
      expect(o.includePuzzles, isFalse);
    });

    test('a pool field alone makes the override non-empty', () {
      expect(AlarmPuzzleOverride(enabledGames: const {}).isEmpty, isFalse);
      expect(AlarmPuzzleOverride(includePuzzles: true).isEmpty, isFalse);
      expect(AlarmPuzzleOverride().isEmpty, isTrue);
    });

    test('resolveFor layers the pool over the defaults', () {
      final resolved = AlarmPuzzleOverride.resolveFor(
        defaults: _s(),
        override: AlarmPuzzleOverride(
          enabledGames: const {'memory_hideout'},
          includePuzzles: false,
        ),
      );
      expect(resolved.enabledGames, {'memory_hideout'});
      expect(resolved.includePuzzles, isFalse);
    });

    test('resolveFor follows the default pool when not overridden', () {
      final resolved = AlarmPuzzleOverride.resolveFor(
        defaults: _s(games: {'catch_the_capy'}, puzzles: false),
        override: AlarmPuzzleOverride(taskCount: 2),
      );
      expect(resolved.enabledGames, {'catch_the_capy'});
      expect(resolved.includePuzzles, isFalse);
    });

    test('resolveFor never yields an empty pool on the ringing path', () {
      final resolved = AlarmPuzzleOverride.resolveFor(
        defaults: _s(games: {'catch_the_capy'}, puzzles: false),
        override: AlarmPuzzleOverride(enabledGames: const {}),
      );
      expect(resolved.enabledGames, isEmpty);
      expect(resolved.includePuzzles, isTrue);
    });

    test('copyWith, equality and hash cover the pool', () {
      final o = AlarmPuzzleOverride(enabledGames: const {'catch_the_capy'});
      expect(o.copyWith(taskCount: 2).enabledGames, {'catch_the_capy'});
      expect(
        o.copyWith(includePuzzles: true).includePuzzles,
        isTrue,
      );
      expect(o, AlarmPuzzleOverride(enabledGames: const {'catch_the_capy'}));
      expect(
        o.hashCode,
        AlarmPuzzleOverride(enabledGames: const {'catch_the_capy'}).hashCode,
      );
      expect(
        o,
        isNot(AlarmPuzzleOverride(enabledGames: const {'memory_hideout'})),
      );
      expect(
        AlarmPuzzleOverride(includePuzzles: true),
        isNot(AlarmPuzzleOverride()),
      );
    });
  });
}

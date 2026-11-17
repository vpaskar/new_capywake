import 'package:capywake/core/games/wake_challenge.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleSettings _settings({
  Set<String> games = const {},
  bool puzzles = true,
}) => PuzzleSettings(
  enabledTypes: const {PuzzleType.arithmetic},
  enabledGames: games,
  includePuzzles: puzzles,
);

bool _all(String _) => true;

void main() {
  group('WakeChallengeSelector.poolFor', () {
    test('defaults hold only the puzzles', () {
      expect(
        WakeChallengeSelector.poolFor(
          PuzzleSettings.defaults(),
          isLaunchable: _all,
        ),
        [const PuzzleWakeChallenge()],
      );
    });

    test('puzzles first, then games in catalogue order', () {
      final pool = WakeChallengeSelector.poolFor(
        _settings(games: {'memory_hideout', 'catch_the_capy'}),
        isLaunchable: _all,
      );
      expect(pool, [
        const PuzzleWakeChallenge(),
        const GameWakeChallenge('catch_the_capy'),
        const GameWakeChallenge('memory_hideout'),
      ]);
    });

    test('a game this build cannot launch is left out', () {
      final pool = WakeChallengeSelector.poolFor(
        _settings(games: {'catch_the_capy', 'shake_dj'}),
        isLaunchable: (id) => id == 'catch_the_capy',
      );
      expect(pool, [
        const PuzzleWakeChallenge(),
        const GameWakeChallenge('catch_the_capy'),
      ]);
    });
  });

  group('WakeChallengeSelector.pick', () {
    test('a single game with puzzles excluded is always that game', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(
          WakeChallengeSelector.pick(
            settings: _settings(games: {'memory_hideout'}, puzzles: false),
            seed: seed,
            isLaunchable: _all,
          ),
          const GameWakeChallenge('memory_hideout'),
        );
      }
    });

    test('an empty launchable pool falls back to the puzzles', () {
      expect(
        WakeChallengeSelector.pick(
          settings: _settings(games: {'catch_the_capy'}, puzzles: false),
          seed: 7,
          isLaunchable: (_) => false,
        ),
        const PuzzleWakeChallenge(),
      );
    });

    test('the same seed picks the same challenge', () {
      final settings = _settings(games: {'catch_the_capy', 'memory_hideout'});
      for (var seed = 0; seed < 20; seed++) {
        expect(
          WakeChallengeSelector.pick(
            settings: settings,
            seed: seed,
            isLaunchable: _all,
          ),
          WakeChallengeSelector.pick(
            settings: settings,
            seed: seed,
            isLaunchable: _all,
          ),
        );
      }
    });

    test('every member of the pool is drawn, roughly uniformly', () {
      final settings = _settings(games: {'catch_the_capy', 'memory_hideout'});
      final counts = <WakeChallenge, int>{};
      for (var seed = 0; seed < 3000; seed++) {
        final pick = WakeChallengeSelector.pick(
          settings: settings,
          seed: seed,
          isLaunchable: _all,
        );
        counts[pick] = (counts[pick] ?? 0) + 1;
      }
      expect(counts, hasLength(3));
      for (final count in counts.values) {
        expect(count, inInclusiveRange(800, 1200));
      }
    });
  });

  group('value semantics', () {
    test('challenges compare by kind and id', () {
      expect(const PuzzleWakeChallenge(), const PuzzleWakeChallenge());
      expect(
        const PuzzleWakeChallenge().hashCode,
        const PuzzleWakeChallenge().hashCode,
      );
      expect(
        const GameWakeChallenge('a'),
        isNot(const GameWakeChallenge('b')),
      );
      expect(
        const GameWakeChallenge('a').hashCode,
        const GameWakeChallenge('a').hashCode,
      );
      expect(const GameWakeChallenge('a'), isNot(const PuzzleWakeChallenge()));
    });
  });
}

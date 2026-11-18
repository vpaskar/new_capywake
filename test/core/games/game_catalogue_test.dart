import 'package:capywake/core/games/game_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCatalogue', () {
    test('all ten games are playable', () {
      expect(
        GameCatalogue.playable.map((e) => e.id),
        [
          'step_quest',
          'qr_treasure_hunt',
          'shake_dj',
          'catch_the_capy',
          'find_the_impostor',
          'memory_hideout',
          'tilt_maze',
          'morning_sort',
          'rhythm_rescue',
          'capy_rocket',
        ],
        reason:
            'A game is playable only once its view is registered. Another '
            'playable entry means a game was marked available before it '
            'exists.',
      );
    });

    test(
      'every playable game is screen-reader solvable but the camera one',
      () {
        for (final entry in GameCatalogue.playable) {
          expect(
            entry.screenReaderSolvable,
            !entry.usesCamera,
            reason: '${entry.id}: a camera cannot be aimed by ear',
          );
        }
      },
    );

    test('only QR Treasure Hunt uses the camera', () {
      expect(
        GameCatalogue.entries.where((e) => e.usesCamera).map((e) => e.id),
        ['qr_treasure_hunt'],
      );
    });

    test('byId finds an entry and returns null for an unknown id', () {
      expect(
        GameCatalogue.byId('memory_hideout')?.nameKey,
        'gameMemoryHideout',
      );
      expect(GameCatalogue.byId('not_a_game'), isNull);
    });

    test('ids lists every entry in catalogue order', () {
      expect(GameCatalogue.ids, GameCatalogue.entries.map((e) => e.id));
    });

    test('lists all ten games', () {
      expect(GameCatalogue.entries.map((e) => e.id), [
        'step_quest',
        'qr_treasure_hunt',
        'shake_dj',
        'catch_the_capy',
        'find_the_impostor',
        'memory_hideout',
        'tilt_maze',
        'morning_sort',
        'rhythm_rescue',
        'capy_rocket',
      ]);
    });

    test('the Home rail is the four 01_HOME.png draws, in that order', () {
      expect(GameCatalogue.homeRail.map((e) => e.id), [
        'step_quest',
        'shake_dj',
        'catch_the_capy',
        'find_the_impostor',
      ]);
    });

    test('every Home-rail entry is in the full catalogue', () {
      for (final entry in GameCatalogue.homeRail) {
        expect(GameCatalogue.entries, contains(entry), reason: entry.id);
      }
    });

    test('ids are unique', () {
      final ids = GameCatalogue.entries.map((e) => e.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every entry carries a name key and a tile asset id', () {
      for (final entry in GameCatalogue.entries) {
        expect(entry.nameKey, isNotEmpty, reason: entry.id);
        expect(entry.tileAssetId, isNotEmpty, reason: entry.id);
      }
    });

    test('Step Quest is playable, solvable by ear, and counts steps', () {
      final entry = GameCatalogue.byId('step_quest')!;
      expect(entry.availability, GameAvailability.playable);
      expect(entry.screenReaderSolvable, isTrue);
      expect(entry.countsSteps, isTrue);
    });

    test('only Step Quest counts steps', () {
      expect(
        GameCatalogue.entries.where((e) => e.countsSteps).map((e) => e.id),
        ['step_quest'],
      );
    });

    test('no game is blocked any more', () {
      expect(
        GameCatalogue.entries.where(
          (e) => e.availability == GameAvailability.blocked,
        ),
        isEmpty,
      );
    });

    test('isPlayable agrees with availability', () {
      for (final entry in GameCatalogue.entries) {
        expect(
          entry.isPlayable,
          entry.availability == GameAvailability.playable,
          reason: entry.id,
        );
      }
    });
  });
}

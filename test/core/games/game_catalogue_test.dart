import 'package:capywake/core/games/game_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCatalogue', () {
    test('ships with zero playable games', () {
      expect(
        GameCatalogue.playable,
        isEmpty,
        reason:
            'No game is built until its phase (12-17). A playable entry here '
            'means a game was marked available before it exists.',
      );
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

    test('Step Quest is blocked on step counting', () {
      final entry = GameCatalogue.entries.firstWhere(
        (e) => e.id == 'step_quest',
      );
      expect(entry.availability, GameAvailability.blocked);
      expect(entry.blockedReason, GameBlockedReason.stepCount);
    });

    test('QR Treasure Hunt is blocked on the camera', () {
      final entry = GameCatalogue.entries.firstWhere(
        (e) => e.id == 'qr_treasure_hunt',
      );
      expect(entry.availability, GameAvailability.blocked);
      expect(entry.blockedReason, GameBlockedReason.camera);
    });

    test('only Step Quest and QR Treasure Hunt are blocked', () {
      final blocked = GameCatalogue.entries
          .where((e) => e.availability == GameAvailability.blocked)
          .map((e) => e.id);
      expect(blocked, unorderedEquals(['step_quest', 'qr_treasure_hunt']));
    });

    test('a blocked entry carries a reason and others do not', () {
      for (final entry in GameCatalogue.entries) {
        expect(
          entry.blockedReason != null,
          entry.availability == GameAvailability.blocked,
          reason: entry.id,
        );
      }
    });

    test('constructing a blocked entry without a reason throws', () {
      expect(
        () => GameEntry(
          id: 'x',
          nameKey: 'x',
          tileAssetId: 'x',
          availability: GameAvailability.blocked,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructing a non-blocked entry with a reason throws', () {
      expect(
        () => GameEntry(
          id: 'x',
          nameKey: 'x',
          tileAssetId: 'x',
          availability: GameAvailability.comingSoon,
          blockedReason: GameBlockedReason.camera,
        ),
        throwsA(isA<AssertionError>()),
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

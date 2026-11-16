import 'package:capywake/core/games/game_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCatalogue', () {
    test('ships with zero playable games', () {
      expect(
        GameCatalogue.playable,
        isEmpty,
        reason:
            'The rail ships with no playable game until phase 11. A playable '
            'entry here means a game was marked available before it exists.',
      );
    });

    test('has the four entries 01_HOME.png shows, in that order', () {
      expect(
        GameCatalogue.entries.map((e) => e.id),
        ['step_quest', 'shake_dj', 'catch_the_capy', 'find_the_impostor'],
      );
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

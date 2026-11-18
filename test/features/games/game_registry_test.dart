import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/features/games/capy_rocket_view.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_registry.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/features/games/rhythm_rescue_view.dart';
import 'package:flutter_test/flutter_test.dart';

GameLaunch _launch() => GameLaunch(
  seed: 1,
  difficulty: PuzzleDifficulty.medium,
  onProgress: (_) {},
  onCompleted: () {},
  reduceMotion: true,
);

void main() {
  test('registered views are exactly the playable catalogue entries', () {
    expect(
      GameRegistry.builders.keys.toSet(),
      GameCatalogue.playable.map((e) => e.id).toSet(),
      reason:
          'Flip a catalogue entry and register its view together; one '
          'without the other strands a ringing alarm or hides a built game.',
    );
  });

  test('every registered id is a catalogue id', () {
    for (final id in GameRegistry.builders.keys) {
      expect(GameCatalogue.byId(id), isNotNull, reason: id);
    }
  });

  test('builds the right view and threads the launch', () {
    final catchView = GameRegistry.build('catch_the_capy', _launch());
    expect(catchView, isA<CatchTheCapyView>());
    expect(catchView!.reduceMotion, isTrue);
    expect(
      GameRegistry.build('memory_hideout', _launch()),
      isA<MemoryHideoutView>(),
    );
    expect(
      GameRegistry.build('rhythm_rescue', _launch()),
      isA<RhythmRescueView>(),
    );
    expect(
      GameRegistry.build('capy_rocket', _launch()),
      isA<CapyRocketView>(),
    );
  });

  test('a non-playable or unknown id cannot launch', () {
    expect(GameRegistry.isLaunchable('shake_dj'), isFalse);
    expect(GameRegistry.isLaunchable('nope'), isFalse);
    expect(GameRegistry.build('shake_dj', _launch()), isNull);
  });
}

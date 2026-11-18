import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/features/games/capy_rocket_view.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_registry.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/features/games/rhythm_rescue_view.dart';
import 'package:capywake/features/games/shake_dj_view.dart';
import 'package:capywake/features/games/step_quest_view.dart';
import 'package:capywake/features/games/tilt_maze_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

final _motion = FakeMotionSensor();
final _steps = FakeStepSensor();

GameLaunch _launch() => GameLaunch(
  seed: 1,
  difficulty: PuzzleDifficulty.medium,
  onProgress: (_) {},
  onCompleted: () {},
  reduceMotion: true,
  motion: _motion,
  steps: _steps,
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
    final shake = GameRegistry.build('shake_dj', _launch());
    expect(shake, isA<ShakeDjView>());
    expect((shake! as ShakeDjView).motion, same(_motion));
    final tilt = GameRegistry.build('tilt_maze', _launch());
    expect(tilt, isA<TiltMazeView>());
    expect((tilt! as TiltMazeView).motion, same(_motion));
    final walk = GameRegistry.build('step_quest', _launch());
    expect(walk, isA<StepQuestView>());
    expect((walk! as StepQuestView).motion, same(_motion));
    expect((walk as StepQuestView).steps, same(_steps));
  });

  test('a non-playable or unknown id cannot launch', () {
    expect(GameRegistry.isLaunchable('qr_treasure_hunt'), isFalse);
    expect(GameRegistry.isLaunchable('nope'), isFalse);
    expect(GameRegistry.build('qr_treasure_hunt', _launch()), isNull);
  });

  for (final id in GameRegistry.builders.keys) {
    testWidgets('$id fits a 320 pt phone in the ringing slot', (tester) async {
      await pumpInApp(
        tester,
        ringingSlotWidth(GameRegistry.build(id, _launch())!),
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull, reason: id);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

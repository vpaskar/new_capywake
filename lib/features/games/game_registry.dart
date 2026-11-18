import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/features/games/capy_rocket_view.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/find_the_impostor_view.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/features/games/morning_sort_view.dart';
import 'package:capywake/features/games/qr_treasure_hunt_view.dart';
import 'package:capywake/features/games/rhythm_rescue_view.dart';
import 'package:capywake/features/games/shake_dj_view.dart';
import 'package:capywake/features/games/step_quest_view.dart';
import 'package:capywake/features/games/tilt_maze_view.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:flutter/widgets.dart';

typedef GameViewBuilder =
    GameRingingView Function(GameLaunch launch, {Key? key});

/// Catalogue id → view. A game arrives by adding a line here and flipping its
/// catalogue entry; a test pins the two lists equal.
abstract final class GameRegistry {
  static const Map<String, GameViewBuilder> builders = {
    'catch_the_capy': CatchTheCapyView.fromLaunch,
    'memory_hideout': MemoryHideoutView.fromLaunch,
    'rhythm_rescue': RhythmRescueView.fromLaunch,
    'capy_rocket': CapyRocketView.fromLaunch,
    'find_the_impostor': FindTheImpostorView.fromLaunch,
    'morning_sort': MorningSortView.fromLaunch,
    'shake_dj': ShakeDjView.fromLaunch,
    'tilt_maze': TiltMazeView.fromLaunch,
    'step_quest': StepQuestView.fromLaunch,
    'qr_treasure_hunt': QrTreasureHuntView.fromLaunch,
  };

  static bool isLaunchable(String gameId) =>
      builders.containsKey(gameId) &&
      (GameCatalogue.byId(gameId)?.isPlayable ?? false);

  /// The view for [gameId], or `null` when this build cannot launch it.
  static GameRingingView? build(String gameId, GameLaunch launch, {Key? key}) =>
      isLaunchable(gameId) ? builders[gameId]!(launch, key: key) : null;
}

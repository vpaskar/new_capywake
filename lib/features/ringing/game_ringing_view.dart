import 'package:capywake/core/games/game_challenge.dart';
import 'package:flutter/material.dart';

/// The contract a wake-up game view implements to sit in the ringing slot. A
/// game reports progress and completion; the escape stays with `RingingScreen`.
abstract class GameRingingView extends StatefulWidget {
  const GameRingingView({
    required this.onProgress,
    required this.onCompleted,
    required this.reduceMotion,
    super.key,
  });

  /// Called whenever the game's [GameChallenge] changes, so the host can raise
  /// the escape to prominent when struggle passes the user's tolerance.
  final ValueChanged<GameChallenge> onProgress;

  /// Called once the goal is reached: the host dismisses the alarm.
  final VoidCallback onCompleted;

  /// Honor `MediaQuery.disableAnimations`, read once by the host. A game must
  /// not animate when this is set.
  final bool reduceMotion;
}

/// The single seam that reads `MediaQuery.disableAnimations` and hands it to a
/// game view, so a game cannot be built without the flag.
class GameRingingSlot extends StatelessWidget {
  const GameRingingSlot({required this.builder, super.key});

  final Widget Function({required bool reduceMotion}) builder;

  @override
  Widget build(BuildContext context) =>
      builder(reduceMotion: MediaQuery.disableAnimationsOf(context));
}

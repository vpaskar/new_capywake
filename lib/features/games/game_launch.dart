import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:flutter/foundation.dart';

/// Everything a host hands a game view: the ring's seed, the resolved
/// difficulty, and the contract's callbacks.
@immutable
class GameLaunch {
  const GameLaunch({
    required this.seed,
    required this.difficulty,
    required this.onProgress,
    required this.onCompleted,
    required this.reduceMotion,
    required this.motion,
    required this.steps,
    required this.scanner,
    this.qrCheckpoint,
  });

  final int seed;
  final PuzzleDifficulty difficulty;
  final ValueChanged<GameChallenge> onProgress;
  final VoidCallback onCompleted;
  final bool reduceMotion;

  /// Read by the motion games only; touch games never listen.
  final MotionSensor motion;

  /// Read by Step Quest only, and only once access is ready.
  final StepSensor steps;

  /// Read by QR Treasure Hunt only, and only once the user taps to scan.
  final CodeScanner scanner;
  final QrCheckpoint? qrCheckpoint;
}

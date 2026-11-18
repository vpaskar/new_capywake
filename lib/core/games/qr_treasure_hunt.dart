import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:meta/meta.dart';

enum QrHuntOutcome { wrongCode, cameraFailed }

/// QR Treasure Hunt: scan the checkpoint's code. Each other code in view, or
/// a camera that will not start, is a struggle once per look.
@immutable
class QrHuntRound {
  const QrHuntRound._({
    required this.found,
    required this.struggles,
    required this.lastOutcome,
    required this.wrongThisLook,
  });

  factory QrHuntRound.start() => const QrHuntRound._(
    found: false,
    struggles: 0,
    lastOutcome: null,
    wrongThisLook: {},
  );

  final bool found;
  final int struggles;
  final QrHuntOutcome? lastOutcome;

  /// Wrong codes already counted since the camera last turned on.
  final Set<String> wrongThisLook;

  bool get isComplete => found;

  GameChallenge get challenge => GameChallenge.touch(
    target: 1,
    completed: found ? 1 : 0,
    struggleCount: struggles,
  );

  QrHuntRound scan(String code, QrCheckpoint? checkpoint) {
    if (found) return this;
    if (checkpoint != null && checkpoint.matches(code)) {
      return QrHuntRound._(
        found: true,
        struggles: struggles,
        lastOutcome: null,
        wrongThisLook: const {},
      );
    }
    if (wrongThisLook.contains(code)) return this;
    return QrHuntRound._(
      found: false,
      struggles: struggles + 1,
      lastOutcome: QrHuntOutcome.wrongCode,
      wrongThisLook: {...wrongThisLook, code},
    );
  }

  /// The camera was turned on again: codes seen before may count again.
  QrHuntRound newLook() => found || wrongThisLook.isEmpty
      ? this
      : QrHuntRound._(
          found: false,
          struggles: struggles,
          lastOutcome: lastOutcome,
          wrongThisLook: const {},
        );

  QrHuntRound cameraFailed() => found
      ? this
      : QrHuntRound._(
          found: false,
          struggles: struggles + 1,
          lastOutcome: QrHuntOutcome.cameraFailed,
          wrongThisLook: const {},
        );
}

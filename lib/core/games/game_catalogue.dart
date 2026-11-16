import 'package:meta/meta.dart';

/// Whether a wake-up game can be played yet. A game arrives by flipping this,
/// not by editing the view. Zero entries are `playable` until phase 11.
enum GameAvailability {
  /// Built and reachable.
  playable,

  /// Not built yet. Tapping opens a sheet saying so.
  comingSoon,

  /// Needs a platform capability CapyWake does not ask for. Carries a
  /// [GameEntry.blockedReason] the sheet shows.
  blocked,
}

/// One entry in the wake-up game rail. [nameKey] is an l10n key, never a
/// display string — a hardcoded literal cannot localize into 10 locales.
@immutable
class GameEntry {
  const GameEntry({
    required this.id,
    required this.nameKey,
    required this.tileAssetId,
    required this.availability,
    this.blockedReason,
  }) : assert(
         (availability == GameAvailability.blocked) == (blockedReason != null),
         'A blocked game carries a reason; a non-blocked game carries none.',
       );

  final String id;
  final String nameKey;
  final String tileAssetId;
  final GameAvailability availability;

  /// Why the game is unavailable, for [GameAvailability.blocked] only.
  final GameBlockedReason? blockedReason;

  bool get isPlayable => availability == GameAvailability.playable;
}

/// Why a game is blocked. Unblocking one is an owner decision, not a phase's.
enum GameBlockedReason {
  /// Adds ACTIVITY_RECOGNITION on Android 10+ and Motion & Fitness on iOS.
  stepCount,

  /// A camera dependency the app does not have.
  camera,
}

/// The wake-up games, in `01_HOME.png`'s order. Step Quest is first and
/// blocked, so that state shows on a primary screen — intended, not a defect.
abstract final class GameCatalogue {
  static const entries = <GameEntry>[
    GameEntry(
      id: 'step_quest',
      nameKey: 'gameStepQuest',
      tileAssetId: 'tile.stepQuest',
      availability: GameAvailability.blocked,
      blockedReason: GameBlockedReason.stepCount,
    ),
    GameEntry(
      id: 'shake_dj',
      nameKey: 'gameShakeDj',
      tileAssetId: 'tile.shakeDj',
      availability: GameAvailability.comingSoon,
    ),
    GameEntry(
      id: 'catch_the_capy',
      nameKey: 'gameCatchTheCapy',
      tileAssetId: 'tile.catchTheCapy',
      availability: GameAvailability.comingSoon,
    ),
    GameEntry(
      id: 'find_the_impostor',
      nameKey: 'gameFindTheImpostor',
      tileAssetId: 'tile.findTheImpostor',
      availability: GameAvailability.comingSoon,
    ),
  ];

  static Iterable<GameEntry> get playable => entries.where((e) => e.isPlayable);
}

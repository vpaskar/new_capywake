import 'package:meta/meta.dart';

/// Whether a wake-up game can be played yet. A game arrives by flipping this
/// and registering its view, never by editing the alarm flow.
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
    required this.screenReaderSolvable,
    this.blockedReason,
    this.winPoseAssetId,
  }) : assert(
         (availability == GameAvailability.blocked) == (blockedReason != null),
         'A blocked game carries a reason; a non-blocked game carries none.',
       );

  final String id;
  final String nameKey;
  final String tileAssetId;
  final GameAvailability availability;

  /// Whether a screen-reader user can finish the game without sight.
  final bool screenReaderSolvable;

  /// Why the game is unavailable, for [GameAvailability.blocked] only.
  final GameBlockedReason? blockedReason;

  /// The game's own win pose; `null` shows the shared win animation.
  final String? winPoseAssetId;

  bool get isPlayable => availability == GameAvailability.playable;
}

/// Why a game is blocked. Unblocking one is an owner decision, not a phase's.
enum GameBlockedReason {
  /// Adds ACTIVITY_RECOGNITION on Android 10+ and Motion & Fitness on iOS.
  stepCount,

  /// A camera dependency the app does not have.
  camera,
}

/// The ten wake-up games, in the owner's poster order. [homeRail] is the four
/// `01_HOME.png` draws; [entries] is the full list a See-All would show.
abstract final class GameCatalogue {
  static const _stepQuest = GameEntry(
    id: 'step_quest',
    nameKey: 'gameStepQuest',
    tileAssetId: 'tile.stepQuest',
    winPoseAssetId: 'pose.stepQuest',
    availability: GameAvailability.blocked,
    screenReaderSolvable: false,
    blockedReason: GameBlockedReason.stepCount,
  );

  static const _qrTreasureHunt = GameEntry(
    id: 'qr_treasure_hunt',
    nameKey: 'gameQrTreasureHunt',
    tileAssetId: 'tile.qrTreasureHunt',
    winPoseAssetId: 'pose.qrTreasureHunt',
    availability: GameAvailability.blocked,
    screenReaderSolvable: false,
    blockedReason: GameBlockedReason.camera,
  );

  static const _shakeDj = GameEntry(
    id: 'shake_dj',
    nameKey: 'gameShakeDj',
    tileAssetId: 'tile.shakeDj',
    winPoseAssetId: 'pose.shakeDj',
    availability: GameAvailability.comingSoon,
    screenReaderSolvable: false,
  );

  static const _catchTheCapy = GameEntry(
    id: 'catch_the_capy',
    nameKey: 'gameCatchTheCapy',
    tileAssetId: 'tile.catchTheCapy',
    winPoseAssetId: 'pose.catchTheCapy',
    availability: GameAvailability.playable,
    screenReaderSolvable: true,
  );

  static const _findTheImpostor = GameEntry(
    id: 'find_the_impostor',
    nameKey: 'gameFindTheImpostor',
    tileAssetId: 'tile.findTheImpostor',
    winPoseAssetId: 'pose.findTheImpostor',
    availability: GameAvailability.comingSoon,
    screenReaderSolvable: false,
  );

  static const _memoryHideout = GameEntry(
    id: 'memory_hideout',
    nameKey: 'gameMemoryHideout',
    tileAssetId: 'tile.memoryHideout',
    winPoseAssetId: 'pose.memoryHideout',
    availability: GameAvailability.playable,
    screenReaderSolvable: true,
  );

  static const _tiltMaze = GameEntry(
    id: 'tilt_maze',
    nameKey: 'gameTiltMaze',
    tileAssetId: 'tile.tiltMaze',
    winPoseAssetId: 'pose.tiltMaze',
    availability: GameAvailability.comingSoon,
    screenReaderSolvable: false,
  );

  static const _morningSort = GameEntry(
    id: 'morning_sort',
    nameKey: 'gameMorningSort',
    tileAssetId: 'tile.morningSort',
    winPoseAssetId: 'pose.morningSort',
    availability: GameAvailability.comingSoon,
    screenReaderSolvable: false,
  );

  static const _rhythmRescue = GameEntry(
    id: 'rhythm_rescue',
    nameKey: 'gameRhythmRescue',
    tileAssetId: 'tile.rhythmRescue',
    winPoseAssetId: 'pose.rhythmRescue',
    availability: GameAvailability.playable,
    screenReaderSolvable: true,
  );

  static const _capyRocket = GameEntry(
    id: 'capy_rocket',
    nameKey: 'gameCapyRocket',
    tileAssetId: 'tile.capyRocket',
    winPoseAssetId: 'pose.capyRocket',
    availability: GameAvailability.playable,
    screenReaderSolvable: true,
  );

  static const entries = <GameEntry>[
    _stepQuest,
    _qrTreasureHunt,
    _shakeDj,
    _catchTheCapy,
    _findTheImpostor,
    _memoryHideout,
    _tiltMaze,
    _morningSort,
    _rhythmRescue,
    _capyRocket,
  ];

  /// Step Quest is first and blocked, so that state shows on a primary screen.
  static const homeRail = <GameEntry>[
    _stepQuest,
    _shakeDj,
    _catchTheCapy,
    _findTheImpostor,
  ];

  static Iterable<GameEntry> get playable => entries.where((e) => e.isPlayable);

  static Iterable<String> get ids => entries.map((e) => e.id);

  /// The entry for [id], or `null` when this build does not know it.
  static GameEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }
}

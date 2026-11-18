import 'package:capywake/core/models/alarm.dart';
import 'package:meta/meta.dart';

/// Where an asset is used, which sets the pixels it must carry.
enum ArtUse {
  /// Full-bleed header illustration behind the cream card.
  scene(renderBoxPt: 393),

  /// A game rail tile.
  tile(renderBoxPt: 120),

  /// An empty-state or hero mascot.
  mascotLarge(renderBoxPt: 96),

  /// A mascot in a list row or beside a label.
  mascotSmall(renderBoxPt: 44),

  /// Alarm-row art panel, 124 pt wide on `02_ALARMS.png`.
  thumbnail(renderBoxPt: 124),

  /// An icon inside a control.
  icon(renderBoxPt: 44),

  /// Grass, bushes, flowers in the footer band.
  decor(renderBoxPt: 48),

  /// The CapyWake lettering in the header.
  wordmark(renderBoxPt: 175),

  /// An animated loop.
  animation(renderBoxPt: 120),

  /// A frame of the running capybara a game asks you to tap.
  gameRunner(renderBoxPt: 96),

  /// The dust puff trailing a running capybara.
  gameDust(renderBoxPt: 48),

  /// A paw print left behind on the meadow.
  gamePaw(renderBoxPt: 24),

  /// A Memory Hideout bush.
  gameBush(renderBoxPt: 96),

  /// A game field's painted backdrop.
  gameScene(renderBoxPt: 360),

  /// A full-width strip: the meadow footer, the cream sheet's cloud edge.
  band(renderBoxPt: 393),

  /// A Settings theme tile.
  themeTile(renderBoxPt: 57),

  /// A 3:2 scene covering a theme tile, so scaled to its 44.8 pt height.
  themeScene(renderBoxPt: 68),

  /// A puzzle type's painted icon.
  puzzleIcon(renderBoxPt: 32),

  /// An illustration inside the content, not a header band.
  hero(renderBoxPt: 240),

  /// A game's still win pose.
  winPose(renderBoxPt: 100),

  /// A Capy on a game card: the impostor grid, the Morning Sort bag.
  gameCapy(renderBoxPt: 72);

  const ArtUse({required this.renderBoxPt});

  /// Largest on-screen box this kind of art is drawn into.
  final double renderBoxPt;
}

@immutable
class ArtAsset {
  const ArtAsset(this.id, this.path, this.use);

  final String id;
  final String path;
  final ArtUse use;

  /// Pixels this asset must carry to stay sharp at 3×.
  int get requiredPixels => (use.renderBoxPt * 3).ceil();
}

/// Every bundled asset, by id. `tool/import_art.dart` writes the files and
/// `art_manifest_test.dart` asserts this catalogue and the bundle agree.
abstract final class CapyArt {
  static const scenes = <ArtAsset>[
    ArtAsset('scene.home', 'assets/art/scenes/today.webp', ArtUse.scene),
    ArtAsset('scene.alarms', 'assets/art/scenes/alarms.webp', ArtUse.scene),
    ArtAsset('scene.stats', 'assets/art/scenes/history.webp', ArtUse.scene),
    ArtAsset('scene.settings', 'assets/art/scenes/settings.webp', ArtUse.scene),
  ];

  static const tiles = <ArtAsset>[
    ArtAsset('tile.stepQuest', 'assets/art/tiles/step_quest.webp', ArtUse.tile),
    ArtAsset('tile.shakeDj', 'assets/art/tiles/shake_dj.webp', ArtUse.tile),
    ArtAsset(
      'tile.catchTheCapy',
      'assets/art/tiles/catch_the_capy.webp',
      ArtUse.tile,
    ),
    ArtAsset(
      'tile.findTheImpostor',
      'assets/art/tiles/find_the_impostor.webp',
      ArtUse.tile,
    ),
    ArtAsset(
      'tile.memoryHideout',
      'assets/art/tiles/memory_hideout.webp',
      ArtUse.tile,
    ),
    ArtAsset('tile.tiltMaze', 'assets/art/tiles/tilt_maze.webp', ArtUse.tile),
    ArtAsset(
      'tile.morningSort',
      'assets/art/tiles/morning_sort.webp',
      ArtUse.tile,
    ),
    ArtAsset(
      'tile.rhythmRescue',
      'assets/art/tiles/rhythm_rescue.webp',
      ArtUse.tile,
    ),
    ArtAsset(
      'tile.capyRocket',
      'assets/art/tiles/capy_rocket.webp',
      ArtUse.tile,
    ),
    ArtAsset(
      'tile.qrTreasureHunt',
      'assets/art/tiles/qr_treasure_hunt.webp',
      ArtUse.tile,
    ),
  ];

  /// The shared win celebration, eight frames on one canvas and baseline.
  static final winFrames = List<ArtAsset>.unmodifiable([
    for (var i = 0; i < 8; i++)
      ArtAsset(
        'animation.win.$i',
        'assets/art/animations/win_0$i.webp',
        ArtUse.animation,
      ),
  ]);

  static const winPoses = <ArtAsset>[
    ArtAsset(
      'pose.stepQuest',
      'assets/art/animations/pose_step_quest.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.qrTreasureHunt',
      'assets/art/animations/pose_qr_treasure_hunt.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.shakeDj',
      'assets/art/animations/pose_shake_dj.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.catchTheCapy',
      'assets/art/animations/pose_catch_the_capy.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.findTheImpostor',
      'assets/art/animations/pose_find_the_impostor.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.memoryHideout',
      'assets/art/animations/pose_memory_hideout.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.tiltMaze',
      'assets/art/animations/pose_tilt_maze.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.morningSort',
      'assets/art/animations/pose_morning_sort.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.rhythmRescue',
      'assets/art/animations/pose_rhythm_rescue.webp',
      ArtUse.winPose,
    ),
    ArtAsset(
      'pose.capyRocket',
      'assets/art/animations/pose_capy_rocket.webp',
      ArtUse.winPose,
    ),
  ];

  static const meadowFooter = ArtAsset(
    'decor.meadowFooter',
    'assets/art/decor/meadow_footer.webp',
    ArtUse.band,
  );

  static const cloudEdge = ArtAsset(
    'decor.cloudEdge',
    'assets/art/decor/cloud_edge.webp',
    ArtUse.band,
  );

  static const themeSystem = ArtAsset(
    'theme.system',
    'assets/art/themes/system.webp',
    ArtUse.themeTile,
  );
  static const themeLight = ArtAsset(
    'theme.light',
    'assets/art/themes/light.webp',
    ArtUse.themeScene,
  );
  static const themeDark = ArtAsset(
    'theme.dark',
    'assets/art/themes/dark.webp',
    ArtUse.themeScene,
  );

  static const welcomeScene = ArtAsset(
    'scene.welcome',
    'assets/art/scenes/welcome.webp',
    ArtUse.scene,
  );

  static const puzzleHero = ArtAsset(
    'hero.puzzle',
    'assets/art/scenes/puzzle_hero.webp',
    ArtUse.hero,
  );

  /// One per puzzle type, keyed by the type's file-name stem.
  static final puzzleIcons = List<ArtAsset>.unmodifiable([
    for (final stem in const [
      'arithmetic',
      'sequence_next',
      'missing_operator',
      'compare_values',
      'odd_one_out',
      'digit_recall',
      'digit_recall_reversed',
      'grid_pattern',
      'spot_the_change',
      'shape_rotation',
    ])
      ArtAsset(
        'icon.puzzle.$stem',
        'assets/art/icons/puzzle_$stem.webp',
        ArtUse.puzzleIcon,
      ),
  ]);

  /// The eight run-cycle frames, in order, sharing one canvas and baseline.
  static final runFrames = List<ArtAsset>.unmodifiable([
    for (var i = 0; i < 8; i++)
      ArtAsset(
        'game.run.$i',
        'assets/art/games/run_0$i.webp',
        ArtUse.gameRunner,
      ),
  ]);

  /// The dust puff's four stages: appear, grow, full, fade.
  static final dustFrames = List<ArtAsset>.unmodifiable([
    for (var i = 0; i < 4; i++)
      ArtAsset(
        'game.dust.$i',
        'assets/art/games/dust_0$i.webp',
        ArtUse.gameDust,
      ),
  ]);

  static const games = <ArtAsset>[
    ArtAsset('game.paw', 'assets/art/games/paw.webp', ArtUse.gamePaw),
    ArtAsset('game.meadow', 'assets/art/games/meadow.webp', ArtUse.gameScene),
    ArtAsset('game.sky', 'assets/art/games/sky.webp', ArtUse.gameScene),
    ArtAsset('game.bush', 'assets/art/games/plain_bush.webp', ArtUse.gameBush),
    ArtAsset(
      'game.memoryCapy',
      'assets/art/mascots/moments_14.webp',
      ArtUse.mascotLarge,
    ),
  ];

  /// Bundled poses on game cards, keyed `game.capy.<CapyPose name>`.
  static final gameCapys = List<ArtAsset>.unmodifiable([
    for (final (pose, file) in const [
      ('asleepNightcap', 'moments_13'),
      ('curledAsleep', 'moments_00'),
      ('underBlanket', 'moments_01'),
      ('onCushion', 'moments_07'),
      ('hiking', 'collection_02'),
      ('jogging', 'collection_10'),
      ('liftingWeights', 'moments_03'),
      ('holdingClock', 'collection_11'),
      ('cheering', 'collection_03'),
      ('partying', 'collection_09'),
      ('superhero', 'moments_12'),
      ('blushing', 'moments_09'),
      ('holdingMug', 'collection_07'),
      ('reading', 'moments_06'),
      ('listening', 'collection_06'),
      ('detective', 'collection_05'),
    ])
      ArtAsset(
        'game.capy.$pose',
        'assets/art/mascots/$file.webp',
        ArtUse.gameCapy,
      ),
  ]);

  /// A cutout for empty states: a painted panel shows its hard edge on cream.
  static ArtAsset get emptyStateMascot => byId('game.capy.asleepNightcap');

  /// The sleeping capybara beside the wordmark on `01_HOME.png`. The choice
  /// is recorded against the mockup crop in `docs/visual/home/`.
  static const mascots = <ArtAsset>[
    ArtAsset(
      'mascot.sleeping',
      'assets/art/mascots/collection_00.webp',
      ArtUse.mascotSmall,
    ),
  ];

  /// Alarm-row art for `02_ALARMS.png`'s four rows, painted panels supplied
  /// under-resolution (gap G15).
  static const thumbnails = <ArtAsset>[
    ArtAsset(
      'thumb.sleeping',
      'assets/art/thumbnails/sleeping.webp',
      ArtUse.thumbnail,
    ),
    ArtAsset(
      'thumb.workout',
      'assets/art/thumbnails/workout.webp',
      ArtUse.thumbnail,
    ),
    ArtAsset('thumb.walk', 'assets/art/thumbnails/walk.webp', ArtUse.thumbnail),
    ArtAsset(
      'thumb.music',
      'assets/art/thumbnails/music.webp',
      ArtUse.thumbnail,
    ),
  ];

  /// Row art by position, not by label — the choice must not vary by
  /// language.
  static ArtAsset thumbnailForIndex(int index) =>
      thumbnails[index % thumbnails.length];

  /// The art an alarm row draws, or `null` for the plain placeholder. An id
  /// whose asset has since left the package falls back to the list position.
  static ArtAsset? alarmThumbnail({
    required String? artId,
    required int index,
  }) {
    if (artId == Alarm.noArtId) return null;
    for (final thumbnail in thumbnails) {
      if (thumbnail.id == artId) return thumbnail;
    }
    return thumbnailForIndex(index);
  }

  static const wordmark = ArtAsset(
    'wordmark',
    'assets/art/wordmark.webp',
    ArtUse.wordmark,
  );

  /// Animated WebP loops; frame 0 is the still shown when motion is off.
  static const celebrationLoop = ArtAsset(
    'loop.celebration',
    'assets/art/animations/loop_celebration.webp',
    ArtUse.animation,
  );

  static List<ArtAsset> get all => [
    ...scenes,
    ...tiles,
    ...runFrames,
    ...dustFrames,
    ...games,
    ...gameCapys,
    ...mascots,
    ...thumbnails,
    ...winFrames,
    ...winPoses,
    celebrationLoop,
    ...puzzleIcons,
    meadowFooter,
    cloudEdge,
    themeSystem,
    themeLight,
    themeDark,
    welcomeScene,
    puzzleHero,
    wordmark,
  ];

  static ArtAsset byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => throw ArgumentError(id));
}

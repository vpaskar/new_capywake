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
  gameScene(renderBoxPt: 360);

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
  ];

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
    ArtAsset('game.bush', 'assets/art/games/plain_bush.webp', ArtUse.gameBush),
    ArtAsset(
      'game.memoryCapy',
      'assets/art/mascots/moments_14.webp',
      ArtUse.mascotLarge,
    ),
  ];

  /// The sleeping capybara beside the wordmark on `01_HOME.png`. The choice
  /// is recorded against the mockup crop in `docs/visual/home/`.
  static const mascots = <ArtAsset>[
    ArtAsset(
      'mascot.sleeping',
      'assets/art/mascots/collection_00.webp',
      ArtUse.mascotSmall,
    ),
  ];

  /// Alarm-row art for `02_ALARMS.png`'s four rows. Cutouts standing in for
  /// painted panels, under-resolution: gaps G14/G15 in `asset_gaps.md`.
  static const thumbnails = <ArtAsset>[
    ArtAsset(
      'thumb.sleeping',
      'assets/art/mascots/moments_01.webp',
      ArtUse.thumbnail,
    ),
    ArtAsset(
      'thumb.workout',
      'assets/art/mascots/moments_03.webp',
      ArtUse.thumbnail,
    ),
    ArtAsset(
      'thumb.walk',
      'assets/art/mascots/collection_02.webp',
      ArtUse.thumbnail,
    ),
    ArtAsset(
      'thumb.music',
      'assets/art/mascots/collection_06.webp',
      ArtUse.thumbnail,
    ),
  ];

  /// Row art by position, not by label — the choice must not vary by
  /// language.
  static ArtAsset thumbnailForIndex(int index) =>
      thumbnails[index % thumbnails.length];

  static const wordmark = ArtAsset(
    'wordmark',
    'assets/art/wordmark.webp',
    ArtUse.wordmark,
  );

  static List<ArtAsset> get all => [
    ...scenes,
    ...tiles,
    ...runFrames,
    ...dustFrames,
    ...games,
    ...mascots,
    ...thumbnails,
    wordmark,
  ];

  static ArtAsset byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => throw ArgumentError(id));
}

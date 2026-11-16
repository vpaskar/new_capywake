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

  /// An icon inside a control.
  icon(renderBoxPt: 44),

  /// Grass, bushes, flowers in the footer band.
  decor(renderBoxPt: 48),

  /// The CapyWake lettering in the header.
  wordmark(renderBoxPt: 175),

  /// An animated loop.
  animation(renderBoxPt: 120);

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
  ];

  static const wordmark = ArtAsset(
    'wordmark',
    'assets/art/wordmark.webp',
    ArtUse.wordmark,
  );

  static List<ArtAsset> get all => [...scenes, ...tiles, wordmark];
}

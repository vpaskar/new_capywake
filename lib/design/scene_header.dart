import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// How a scene is cropped into the header band.
///
/// The supplied scenes are 3:2; the band measures 2.086:1 (393 x 188.4 pt), so
/// cover keeps full width and drops ~28% of the height. Each scene names the
/// alignment that keeps its subject whole — `today` aligns to the top so the
/// capybara's nightcap and the `Zz` stay in frame.
@immutable
class SceneCrop {
  const SceneCrop(this.asset, {this.alignment = Alignment.center});

  final String asset;
  final Alignment alignment;

  static const home = SceneCrop(
    'assets/art/scenes/today.webp',
    alignment: Alignment.topCenter,
  );
  static const alarms = SceneCrop('assets/art/scenes/alarms.webp');
  static const stats = SceneCrop('assets/art/scenes/history.webp');
  static const settings = SceneCrop('assets/art/scenes/settings.webp');
}

/// Hero art with the cream card overlapping its lower edge.
///
/// Every primary screen opens with one, so the five compositions cannot drift
/// apart. Art sits behind content and never under a control.
class SceneHeader extends StatelessWidget {
  const SceneHeader({
    required this.scene,
    required this.child,
    this.bandHeight = 188.4,
    this.overlap = 11.1,
    this.header,
    super.key,
  });

  final SceneCrop scene;

  /// Content of the cream card that overlaps the art.
  final Widget child;

  /// Art band height in logical pixels, measured from `01_HOME.png`.
  final double bandHeight;

  /// How far the card rides up over the art's lower edge.
  final double overlap;

  /// Row drawn above the art — the wordmark and the settings gear.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        Stack(
          children: [
            SizedBox(
              height: bandHeight,
              width: double.infinity,
              child: ExcludeSemantics(
                child: ColorFiltered(
                  colorFilter: dark
                      ? const ColorFilter.mode(
                          CapyColors.artScrim,
                          BlendMode.srcOver,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: Image.asset(
                    scene.asset,
                    fit: BoxFit.cover,
                    alignment: scene.alignment,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: bandHeight - overlap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(CapyRadius.xl),
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          ),
        ),
      ],
    );
  }
}

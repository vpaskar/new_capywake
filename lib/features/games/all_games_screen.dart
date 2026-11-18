import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/home/game_rail.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Home's See All: every wake-up game, each tile behaving as on the rail.
class AllGamesScreen extends StatelessWidget {
  const AllGamesScreen({super.key});

  /// **Not a measurement** — no mockup draws this screen. Matches the
  /// other pushed sub-routes.
  static const _heroBandHeight = 84.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.home,
        bandHeight: _heroBandHeight,
        header: SettingsHeader(title: l10n.homeGamesHeading),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: CapySpacing.gutterWide,
                  vertical: CapySpacing.xl,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        ((constraints.maxWidth + CapySpacing.md) /
                                (GameRail.tileSize + CapySpacing.md))
                            .floor()
                            .clamp(1, GameCatalogue.entries.length);
                    final cellWidth =
                        (constraints.maxWidth -
                            CapySpacing.md * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: CapySpacing.md,
                      runSpacing: CapySpacing.lg,
                      children: [
                        for (final entry in GameCatalogue.entries)
                          SizedBox(
                            width: cellWidth,
                            child: Center(child: GameTile(entry: entry)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const MeadowFooter(),
          ],
        ),
      ),
    );
  }
}

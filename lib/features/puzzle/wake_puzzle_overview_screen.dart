import 'package:capywake/app/router.dart';
import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_controls.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:capywake/features/puzzle/puzzle_settings_controller.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/features/settings/settings_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The wake-puzzle summary, against `02_WAKE_PUZZLE_REFINED.png`: two
/// navigation cards and the current values, each opening its own screen.
class WakePuzzleOverviewScreen extends ConsumerWidget {
  const WakePuzzleOverviewScreen({super.key});

  /// A short hero: the full one belongs to Settings.
  static const heroBandHeight = 80.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.settings,
        bandHeight: heroBandHeight,
        header: SettingsHeader(
          title: l10n.settingsPuzzleHeading,
          height: SettingsHeader.compactHeight,
        ),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final settings = watchPuzzleSettings(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CapySpacing.gutterNarrow,
              CapySpacing.xl,
              CapySpacing.gutterNarrow,
              CapySpacing.lg,
            ),
            children: [
              Text(
                l10n.settingsPuzzleEntryDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: inkSoft),
              ),
              const SizedBox(height: CapySpacing.md),
              _NavigationCards(settings: settings),
              if (settings.includePuzzles && settings.isVisualOnly) ...[
                const SizedBox(height: CapySpacing.sm),
                const VisualOnlyNotice(),
              ],
              const SizedBox(height: CapySpacing.sm),
              Text(
                l10n.challengePoolHelp,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
              ),
              const SizedBox(height: CapySpacing.lg),
              _HowItWorks(settings: settings),
            ],
          ),
        ),
        const MeadowFooter(height: SettingsScreen.meadowHeight),
      ],
    );
  }
}

/// Games and Puzzle types side by side, stacked when the pair cannot hold
/// its labels (German, or large text).
class _NavigationCards extends StatelessWidget {
  const _NavigationCards({required this.settings});

  final PuzzleSettings settings;

  static const minCardWidth = 160.0;
  static const maxSideBySideTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playable = GameCatalogue.playable.map((g) => g.id).toSet();
    final games = _NavigationCard(
      icon: Icons.sports_esports_outlined,
      title: l10n.challengeGamesTitle,
      value: l10n.challengeSelectedCount(
        settings.enabledGames.where(playable.contains).length,
        playable.length,
      ),
      onTap: () => context.push(Routes.settingsPuzzleGames),
    );
    final types = _NavigationCard(
      icon: Icons.grid_view_outlined,
      title: l10n.puzzleSettingsTypesLabel,
      value: settings.includePuzzles
          ? l10n.challengeSelectedCount(
              settings.enabledTypes.length,
              PuzzleType.values.length,
            )
          : l10n.puzzleOff,
      onTap: () => context.push(Routes.settingsPuzzleTypes),
    );
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fits =
            constraints.maxWidth >= minCardWidth * 2 + CapySpacing.sm &&
            scale <= maxSideBySideTextScale;
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              games,
              const SizedBox(height: CapySpacing.sm),
              types,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: games),
              const SizedBox(width: CapySpacing.sm),
              Expanded(child: types),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Semantics(
      button: true,
      label: '$title, $value',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CapyCard(
          onTap: onTap,
          padding: const EdgeInsetsDirectional.fromSTEB(
            CapySpacing.sm,
            CapySpacing.md,
            CapySpacing.xs,
            CapySpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: CapyIconSize.md,
                color: CapyColors.accentDeep,
              ),
              const SizedBox(width: CapySpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: CapyIconSize.sm,
                color: inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.settings});

  final PuzzleSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void openAdvanced() => context.push(Routes.settingsPuzzleAdvanced);

    return SettingsGroup(
      icon: Icons.tune_rounded,
      title: l10n.puzzleHowItWorks,
      rows: [
        SettingsChevronRow(
          icon: Icons.bar_chart_rounded,
          title: l10n.alarmDismissDifficultyLabel,
          subtitle: puzzleDifficultyLabel(settings.difficulty, l10n),
          onTap: openAdvanced,
        ),
        SettingsChevronRow(
          icon: Icons.layers_outlined,
          title: l10n.puzzleSettingsTaskCountLabel,
          subtitle: l10n.puzzleSettingsTaskCountValue(settings.taskCount),
          onTap: openAdvanced,
        ),
        SettingsChevronRow(
          icon: Icons.back_hand_outlined,
          title: l10n.puzzleSettingsEscapeLabel,
          subtitle: puzzleEscapeLabel(settings.escapeStrictness, l10n),
          onTap: openAdvanced,
        ),
        SettingsChevronRow(
          icon: Icons.schedule_rounded,
          title: l10n.puzzleSettingsToleranceLabel,
          subtitle: toleranceValueLabel(settings.toleratedWrongAnswers, l10n),
          onTap: openAdvanced,
        ),
      ],
    );
  }
}

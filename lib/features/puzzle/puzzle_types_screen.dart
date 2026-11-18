import 'package:capywake/app/router.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/pool_switch_row.dart';
import 'package:capywake/features/puzzle/puzzle_controls.dart';
import 'package:capywake/features/puzzle/puzzle_settings_controller.dart';
import 'package:capywake/features/puzzle/puzzle_subpage.dart';
import 'package:capywake/features/puzzle/puzzle_type_grid.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Every puzzle type, grouped as the domain groups them, against
/// `04_PUZZLE_TYPES_SELECTION.png`. Also holds whether puzzles are in the pool.
class PuzzleTypesScreen extends ConsumerWidget {
  const PuzzleTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = watchPuzzleSettings(ref);
    final controller = ref.read(puzzleSettingsControllerProvider);
    final puzzlesLocked =
        settings.includePuzzles && !hasPlayableGame(settings.enabledGames);

    return PuzzleSubpage(
      title: l10n.puzzleSettingsTypesLabel,
      glyph: const PuzzleHeaderGlyph(Icons.grid_view_outlined),
      children: [
        PuzzleHelpText(l10n.puzzleTypesHelp),
        const SizedBox(height: CapySpacing.md),
        CapyCard(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CapySpacing.md,
            vertical: CapySpacing.xs,
          ),
          child: PoolSwitchRow(
            leading: const Icon(Icons.extension_rounded),
            title: l10n.challengePuzzlesLabel,
            value: settings.includePuzzles,
            locked: puzzlesLocked,
            onChanged: (on) => controller.setPuzzlesIncluded(included: on),
            unlockLabel: l10n.challengeGamesTitle,
            onUnlock: () => context.push(Routes.settingsPuzzleGames),
          ),
        ),
        if (settings.isVisualOnly) ...[
          const SizedBox(height: CapySpacing.md),
          const VisualOnlyNotice(),
        ],
        const SizedBox(height: CapySpacing.sm),
        PuzzleTypeGrid(
          enabledTypes: settings.enabledTypes,
          onTypeToggled: controller.setTypeEnabled,
        ),
      ],
    );
  }
}

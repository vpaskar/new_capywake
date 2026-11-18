import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_controls.dart';
import 'package:capywake/features/puzzle/puzzle_settings_controller.dart';
import 'package:capywake/features/puzzle/puzzle_subpage.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Difficulty, puzzles to solve and the two Stop-without-solving settings,
/// against `05_WAKE_PUZZLE_ADVANCED.png`. Autosaves like every setting.
class WakePuzzleAdvancedScreen extends ConsumerWidget {
  const WakePuzzleAdvancedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = watchPuzzleSettings(ref);
    final controller = ref.read(puzzleSettingsControllerProvider);

    return PuzzleSubpage(
      title: l10n.puzzleHowItWorks,
      children: [
        PuzzleSectionLabel(l10n.alarmDismissDifficultyLabel),
        DifficultySelector(
          difficulty: settings.difficulty,
          onChanged: controller.setDifficulty,
        ),
        PuzzleSectionLabel(l10n.puzzleSettingsTaskCountLabel),
        TaskCountSelector(
          count: settings.taskCount,
          onChanged: controller.setTaskCount,
        ),
        const SizedBox(height: CapySpacing.xs),
        _Caption(l10n.puzzleSettingsTaskCountPuzzlesOnly),
        PuzzleSectionLabel(l10n.puzzleSettingsEscapeLabel),
        EscapeStrictnessSelector(
          strictness: settings.escapeStrictness,
          onChanged: controller.setEscapeStrictness,
        ),
        const SizedBox(height: CapySpacing.xs),
        _Caption(l10n.puzzleSettingsEscapeExplanation),
        PuzzleSectionLabel(l10n.puzzleSettingsToleranceLabel),
        ToleranceStepper(
          tolerated: settings.toleratedWrongAnswers,
          onChanged: controller.setToleratedWrongAnswers,
        ),
        const SizedBox(height: CapySpacing.lg),
        PuzzleNote(
          icon: Icons.info_outline_rounded,
          body: l10n.puzzleSettingsToleranceExplanation,
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
      ),
    );
  }
}

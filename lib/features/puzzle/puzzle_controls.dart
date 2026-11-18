import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/design/capy_segmented.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DifficultySelector extends StatelessWidget {
  const DifficultySelector({
    required this.difficulty,
    required this.onChanged,
    super.key,
  });

  final PuzzleDifficulty difficulty;
  final ValueChanged<PuzzleDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CapySegmented<PuzzleDifficulty>(
      segments: [
        for (final d in PuzzleDifficulty.values)
          CapySegment(value: d, label: puzzleDifficultyLabel(d, l10n)),
      ],
      selected: difficulty,
      onChanged: onChanged,
    );
  }
}

class TaskCountSelector extends StatelessWidget {
  const TaskCountSelector({
    required this.count,
    required this.onChanged,
    super.key,
  });

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    return CapySegmented<int>(
      segments: [
        for (
          var n = PuzzleSettings.minTaskCount;
          n <= PuzzleSettings.maxTaskCount;
          n++
        )
          CapySegment(
            value: n,
            label: numbers.format(n),
            semanticLabel: l10n.puzzleSettingsTaskCountValue(n),
          ),
      ],
      selected: count,
      onChanged: onChanged,
    );
  }
}

/// Two values: the escape is always reachable, this only sets how deliberate.
class EscapeStrictnessSelector extends StatelessWidget {
  const EscapeStrictnessSelector({
    required this.strictness,
    required this.onChanged,
    super.key,
  });

  final PuzzleEscapeStrictness strictness;
  final ValueChanged<PuzzleEscapeStrictness> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CapySegmented<PuzzleEscapeStrictness>(
      segments: [
        for (final s in PuzzleEscapeStrictness.values)
          CapySegment(value: s, label: puzzleEscapeLabel(s, l10n)),
      ],
      selected: strictness,
      onChanged: onChanged,
    );
  }
}

/// The shown value is `tolerated + 1`, the wrong answer at which Stop without
/// solving starts standing out.
String toleranceValueLabel(int tolerated, AppLocalizations l10n) =>
    l10n.puzzleSettingsToleranceValue(tolerated + 1);

class ToleranceStepper extends StatelessWidget {
  const ToleranceStepper({
    required this.tolerated,
    required this.onChanged,
    super.key,
  });

  final int tolerated;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final canDecrease = tolerated > PuzzleSettings.minToleratedWrongAnswers;
    final canIncrease = tolerated < PuzzleSettings.maxToleratedWrongAnswers;
    final valueText = toleranceValueLabel(tolerated, l10n);

    return Semantics(
      container: true,
      label: l10n.puzzleSettingsToleranceLabel,
      value: valueText,
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: l10n.puzzleSettingsToleranceSooner,
            onPressed: canDecrease ? () => onChanged(tolerated - 1) : null,
          ),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: dark ? CapyColors.darkInk : CapyColors.cocoa,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: l10n.puzzleSettingsToleranceLater,
            onPressed: canIncrease ? () => onChanged(tolerated + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(
        width: CapyToggle.minTapTarget,
        height: CapyToggle.minTapTarget,
      ),
      style: IconButton.styleFrom(
        backgroundColor: CapyColors.successDeep,
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

/// Every enabled type needs sight: a screen-reader user would otherwise leave
/// themselves an unsolvable morning.
class VisualOnlyNotice extends StatelessWidget {
  const VisualOnlyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PuzzleNote(
      icon: Icons.visibility_outlined,
      title: l10n.puzzleSettingsVisualOnlyTitle,
      body: l10n.puzzleSettingsVisualOnlyBody,
    );
  }
}

/// A tinted callout with an icon, e.g. the tolerance explanation on `05`.
class PuzzleNote extends StatelessWidget {
  const PuzzleNote({
    required this.icon,
    required this.body,
    this.title,
    super.key,
  });

  final IconData icon;
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(CapySpacing.md),
      decoration: BoxDecoration(
        color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(CapyRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: CapyIconSize.md,
              color: CapyColors.accentDeep,
            ),
          ),
          const SizedBox(width: CapySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: dark ? CapyColors.darkInk : CapyColors.cocoa,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: CapySpacing.xs),
                ],
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: dark ? CapyColors.darkInk : CapyColors.cocoa,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

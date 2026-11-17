import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:capywake/features/puzzle/puzzle_type_grid.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The five wake-puzzle controls, shared by the chooser and the per-alarm
/// override. Per-field callbacks; the escape control has no "off" value.
class PuzzleSettingsFields extends StatelessWidget {
  const PuzzleSettingsFields({
    required this.settings,
    required this.onTypeToggled,
    required this.onTaskCountChanged,
    required this.onDifficultyChanged,
    required this.onToleratedWrongAnswersChanged,
    required this.onEscapeStrictnessChanged,
    super.key,
  });

  final PuzzleSettings settings;
  final void Function(PuzzleType type, {required bool enabled}) onTypeToggled;
  final ValueChanged<int> onTaskCountChanged;
  final ValueChanged<PuzzleDifficulty> onDifficultyChanged;
  final ValueChanged<int> onToleratedWrongAnswersChanged;
  final ValueChanged<PuzzleEscapeStrictness> onEscapeStrictnessChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(text: l10n.puzzleSettingsTypesLabel),
        const SizedBox(height: CapySpacing.xs),
        _Caption(text: l10n.puzzleRotationHelp),
        const SizedBox(height: CapySpacing.sm),
        if (settings.isVisualOnly)
          _VisualOnlyNotice(
            title: l10n.puzzleSettingsVisualOnlyTitle,
            body: l10n.puzzleSettingsVisualOnlyBody,
          ),
        PuzzleTypeGrid(
          enabledTypes: settings.enabledTypes,
          onTypeToggled: onTypeToggled,
        ),
        const _FieldDivider(),
        _FieldLabel(text: l10n.alarmDismissDifficultyLabel),
        const SizedBox(height: CapySpacing.sm),
        _DifficultySelector(
          difficulty: settings.difficulty,
          onChanged: onDifficultyChanged,
        ),
        const SizedBox(height: CapySpacing.lg),
        _FieldLabel(text: l10n.puzzleSettingsTaskCountLabel),
        const SizedBox(height: CapySpacing.sm),
        _TaskCountSelector(
          count: settings.taskCount,
          onChanged: onTaskCountChanged,
        ),
        const _FieldDivider(),
        _FieldLabel(text: l10n.puzzleSettingsEscapeLabel),
        const SizedBox(height: CapySpacing.sm),
        _Caption(text: l10n.puzzleSettingsEscapeExplanation),
        const SizedBox(height: CapySpacing.sm),
        _EscapeStrictnessSelector(
          strictness: settings.escapeStrictness,
          onChanged: onEscapeStrictnessChanged,
        ),
        const SizedBox(height: CapySpacing.lg),
        _FieldLabel(text: l10n.puzzleSettingsToleranceLabel),
        const SizedBox(height: CapySpacing.sm),
        _ToleranceStepper(
          tolerated: settings.toleratedWrongAnswers,
          onChanged: onToleratedWrongAnswersChanged,
        ),
        const SizedBox(height: CapySpacing.sm),
        _Caption(text: l10n.puzzleSettingsToleranceExplanation),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: dark ? CapyColors.darkInk : CapyColors.cocoa,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: CapySpacing.xxl);
}

/// A warning shown when every enabled type needs sight — a screen-reader user
/// would otherwise leave themselves an unsolvable morning.
class _VisualOnlyNotice extends StatelessWidget {
  const _VisualOnlyNotice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: CapySpacing.md),
      padding: const EdgeInsets.all(CapySpacing.md),
      decoration: BoxDecoration(
        color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(CapyRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: CapyIconSize.md,
            color: CapyColors.accentDeep,
          ),
          const SizedBox(width: CapySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: dark ? CapyColors.darkInk : CapyColors.cocoa,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: CapySpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
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

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    required this.difficulty,
    required this.onChanged,
  });

  final PuzzleDifficulty difficulty;
  final ValueChanged<PuzzleDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<PuzzleDifficulty>(
      segments: [
        for (final d in PuzzleDifficulty.values)
          ButtonSegment<PuzzleDifficulty>(
            value: d,
            label: Text(puzzleDifficultyLabel(d, l10n)),
          ),
      ],
      selected: {difficulty},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// How many puzzles have to be solved. A segmented control: glanceable, and
/// impossible to type nonsense into.
class _TaskCountSelector extends StatelessWidget {
  const _TaskCountSelector({required this.count, required this.onChanged});

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    return SegmentedButton<int>(
      segments: [
        for (
          var n = PuzzleSettings.minTaskCount;
          n <= PuzzleSettings.maxTaskCount;
          n++
        )
          ButtonSegment<int>(
            value: n,
            label: Text(numbers.format(n)),
            tooltip: l10n.puzzleSettingsTaskCountValue(n),
          ),
      ],
      selected: {count},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// The escape-strictness control. Two values — the escape is always reachable;
/// this only sets how deliberate reaching it has to be.
class _EscapeStrictnessSelector extends StatelessWidget {
  const _EscapeStrictnessSelector({
    required this.strictness,
    required this.onChanged,
  });

  final PuzzleEscapeStrictness strictness;
  final ValueChanged<PuzzleEscapeStrictness> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<PuzzleEscapeStrictness>(
      segments: [
        for (final s in PuzzleEscapeStrictness.values)
          ButtonSegment<PuzzleEscapeStrictness>(
            value: s,
            label: Text(puzzleEscapeLabel(s, l10n)),
          ),
      ],
      selected: {strictness},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// When "Stop without solving" starts standing out. The shown value is
/// `tolerated + 1` — the wrong answer at which it happens.
class _ToleranceStepper extends StatelessWidget {
  const _ToleranceStepper({required this.tolerated, required this.onChanged});

  final int tolerated;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canDecrease = tolerated > PuzzleSettings.minToleratedWrongAnswers;
    final canIncrease = tolerated < PuzzleSettings.maxToleratedWrongAnswers;
    final valueText = l10n.puzzleSettingsToleranceValue(tolerated + 1);

    return Semantics(
      container: true,
      label: l10n.puzzleSettingsToleranceLabel,
      value: valueText,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: l10n.puzzleSettingsToleranceSooner,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            onPressed: canDecrease ? () => onChanged(tolerated - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: l10n.puzzleSettingsToleranceLater,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            onPressed: canIncrease ? () => onChanged(tolerated + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

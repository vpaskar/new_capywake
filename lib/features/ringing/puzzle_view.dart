import 'package:capywake/core/puzzle/puzzle.dart';
import 'package:capywake/core/puzzle/puzzle_content.dart';
import 'package:capywake/core/puzzle/puzzle_round.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/core/puzzle/puzzle_validator.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The wake puzzle on the ringing surface. Draws the three default types;
/// `RingingHost.renderableTypes` keeps the rest out. Nothing animates.
class PuzzleView extends StatefulWidget {
  const PuzzleView({
    required this.round,
    required this.onRoundChanged,
    required this.onSolved,
    super.key,
  });

  final PuzzleRound round;
  final ValueChanged<PuzzleRound> onRoundChanged;
  final VoidCallback onSolved;

  @override
  State<PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<PuzzleView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit(PuzzleResponse response) {
    final next = widget.round.submit(response);
    _input.clear();
    widget.onRoundChanged(next);
    if (next.isSolved) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final puzzle = widget.round.puzzle;

    return CapyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _instruction(l10n, puzzle),
            style: CapyType.section.copyWith(color: ink),
          ),
          if (widget.round.showsProgress) ...[
            const SizedBox(height: CapySpacing.xs),
            Text(
              l10n.puzzleProgress(
                widget.round.taskNumber,
                widget.round.taskCount,
              ),
              style: CapyType.caption.copyWith(color: inkSoft),
            ),
          ],
          const SizedBox(height: CapySpacing.md),
          _Prompt(puzzle: puzzle, ink: ink),
          const SizedBox(height: CapySpacing.md),
          _answerField(l10n, puzzle, ink, inkSoft),
          if (_feedback(l10n) case final message?) ...[
            const SizedBox(height: CapySpacing.sm),
            Text(message, style: CapyType.label.copyWith(color: inkSoft)),
          ],
        ],
      ),
    );
  }

  Widget _answerField(
    AppLocalizations l10n,
    Puzzle puzzle,
    Color ink,
    Color inkSoft,
  ) {
    final content = puzzle.content;
    if (content is MissingOperatorContent) {
      return Wrap(
        spacing: CapySpacing.sm,
        runSpacing: CapySpacing.sm,
        children: [
          for (var i = 0; i < content.options.length; i++)
            _OptionChip(
              label: _operatorGlyph(content.options[i]),
              semanticLabel: _operatorWord(l10n, content.options[i]),
              onTap: () => _submit(PuzzleOptionResponse(i)),
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: CapyType.title.copyWith(color: ink),
            decoration: InputDecoration(
              labelText: l10n.puzzleAnswerLabel,
              labelStyle: CapyType.label.copyWith(color: inkSoft),
            ),
            onSubmitted: (v) => _submit(PuzzleTextResponse(v)),
          ),
        ),
        const SizedBox(width: CapySpacing.sm),
        TextButton(
          onPressed: () => _submit(PuzzleTextResponse(_input.text)),
          child: Text(l10n.puzzleSubmitAction),
        ),
      ],
    );
  }

  /// What to say about the last answer, or `null` after a correct one — the
  /// next puzzle is the acknowledgement, and a cheer would be a taunt's twin.
  String? _feedback(AppLocalizations l10n) =>
      switch (widget.round.lastOutcome) {
        PuzzleAnswerOutcome.incorrect => l10n.puzzleFeedbackIncorrect,
        PuzzleAnswerOutcome.empty => l10n.puzzleFeedbackEmpty,
        PuzzleAnswerOutcome.unparseable => l10n.puzzleFeedbackUnparseable,
        PuzzleAnswerOutcome.correct || null => null,
      };

  /// Explicit per type, never a wildcard: a fallback caption cannot be right
  /// for a type it did not expect, and would mislabel the puzzle.
  String _instruction(AppLocalizations l10n, Puzzle puzzle) =>
      switch (puzzle.type) {
        PuzzleType.arithmetic => l10n.puzzleInstructionArithmetic,
        PuzzleType.sequenceNext => l10n.puzzleInstructionSequenceNext,
        PuzzleType.missingOperator => l10n.puzzleInstructionMissingOperator,
        PuzzleType.compareValues ||
        PuzzleType.oddOneOutNumeric ||
        PuzzleType.digitRecall ||
        PuzzleType.digitRecallReversed ||
        PuzzleType.gridPatternRecall ||
        PuzzleType.spotTheChange ||
        PuzzleType.shapeRotation => throw UnsupportedError(
          '${puzzle.type.name} has no renderer; see '
          'RingingHost.renderableTypes.',
        ),
      };
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.puzzle, required this.ink});

  final Puzzle puzzle;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final content = puzzle.content;
    final text = switch (content) {
      ArithmeticContent() =>
        '${content.left} ${_operatorGlyph(content.operation)} '
            '${content.right} = ?',
      SequenceNextContent() => '${content.shown.join(', ')}, ?',
      MissingOperatorContent() =>
        '${content.left} ? ${content.right} = ${content.result}',
      _ => '',
    };

    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: CapyType.title.copyWith(color: ink),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  /// Past the 44 pt floor: tapped by someone half asleep.
  static const size = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final surface = dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(CapyRadius.sm),
              ),
              child: Center(
                child: Text(
                  label,
                  style: CapyType.title.copyWith(color: ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _operatorGlyph(ArithmeticOperator op) => switch (op) {
  ArithmeticOperator.add => '+',
  ArithmeticOperator.subtract => '−',
  ArithmeticOperator.multiply => '×',
  ArithmeticOperator.divide => '÷',
};

String _operatorWord(AppLocalizations l10n, ArithmeticOperator op) =>
    switch (op) {
      ArithmeticOperator.add => l10n.puzzleOperatorAdd,
      ArithmeticOperator.subtract => l10n.puzzleOperatorSubtract,
      ArithmeticOperator.multiply => l10n.puzzleOperatorMultiply,
      ArithmeticOperator.divide => l10n.puzzleOperatorDivide,
    };

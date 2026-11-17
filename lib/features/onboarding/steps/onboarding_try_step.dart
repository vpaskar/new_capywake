import 'package:capywake/design/art.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The "try a puzzle" onboarding step: a static preview of three spoken
/// examples — not the game engine, no `puzzle_generator` import, no scoring.
class OnboardingTryStep extends StatelessWidget {
  const OnboardingTryStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _PuzzleHero(dark: dark)),
        const SizedBox(height: CapySpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.onboardingPuzzleTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: CapySpacing.md),
        Text(
          l10n.onboardingPuzzleBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: inkSoft),
        ),
        const SizedBox(height: CapySpacing.xl),
        _ExampleCard(text: l10n.onboardingArithmeticExample),
        const SizedBox(height: CapySpacing.sm),
        _ExampleCard(text: l10n.onboardingSequenceExample),
        const SizedBox(height: CapySpacing.sm),
        _ExampleCard(text: l10n.onboardingOperatorExample),
        const SizedBox(height: CapySpacing.lg),
        Text(
          l10n.onboardingPuzzleAdjustNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
        ),
      ],
    );
  }
}

class _PuzzleHero extends StatelessWidget {
  const _PuzzleHero({required this.dark});

  final bool dark;

  static const height = 150.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CapyRadius.lg),
        child: ColorFiltered(
          colorFilter: dark
              ? const ColorFilter.mode(CapyColors.artScrim, BlendMode.srcOver)
              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
          child: Image.asset(CapyArt.puzzleHero.path, height: height),
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(CapySpacing.md),
      decoration: BoxDecoration(
        color: dark ? CapyColors.darkSurface : CapyColors.surface,
        borderRadius: BorderRadius.circular(CapyRadius.md),
        border: Border.all(
          color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: CapyIconSize.md,
            color: CapyColors.accentDeep,
          ),
          const SizedBox(width: CapySpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: dark ? CapyColors.darkInk : CapyColors.cocoa,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

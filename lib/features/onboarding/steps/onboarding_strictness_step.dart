import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The strictness onboarding step. Two options only — no "Never": the escape
/// is always reachable, so a "Never" card would be an overpromise in reverse.
class OnboardingStrictnessStep extends StatelessWidget {
  const OnboardingStrictnessStep({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final PuzzleEscapeStrictness selected;
  final ValueChanged<PuzzleEscapeStrictness> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.onboardingStrictnessTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: CapySpacing.md),
        Text(
          l10n.onboardingStrictnessBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: inkSoft),
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          l10n.puzzleSettingsEscapeExplanation,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
        ),
        const SizedBox(height: CapySpacing.xl),
        for (final s in PuzzleEscapeStrictness.values) ...[
          _StrictnessCard(
            label: puzzleEscapeLabel(s, l10n),
            selected: s == selected,
            onTap: () => onChanged(s),
          ),
          const SizedBox(height: CapySpacing.sm),
        ],
        const SizedBox(height: CapySpacing.sm),
        Text(
          l10n.onboardingStrictnessDefaultsNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
        ),
      ],
    );
  }
}

class _StrictnessCard extends StatelessWidget {
  const _StrictnessCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final border = selected
        ? CapyColors.accentDeep
        : (dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: dark ? CapyColors.darkSurface : CapyColors.surface,
          borderRadius: BorderRadius.circular(CapyRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(CapyRadius.lg),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(CapySpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CapyRadius.lg),
                border: Border.all(color: border, width: selected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? CapyColors.accentDeep
                        : (dark
                              ? CapyColors.darkInkSoft
                              : CapyColors.cocoaSoft),
                  ),
                  const SizedBox(width: CapySpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

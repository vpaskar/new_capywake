import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/hold_to_act_button.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Confirm the escape at the configured deliberateness; both paths end in a
/// reachable control. Never `useRootNavigator: true` — it is not an ancestor.
Future<bool?> showEscapeSheet({
  required BuildContext context,
  required PuzzleEscapeStrictness strictness,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => _EscapeSheet(strictness: strictness),
);

class _EscapeSheet extends StatelessWidget {
  const _EscapeSheet({required this.strictness});

  final PuzzleEscapeStrictness strictness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final surface = dark ? CapyColors.darkSurface : CapyColors.surface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CapySpacing.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(CapyRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(CapySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.puzzleEscapeConfirmTitle,
                  style: CapyType.title.copyWith(color: ink),
                ),
                const SizedBox(height: CapySpacing.sm),
                Text(
                  l10n.puzzleEscapeConfirmBody,
                  style: CapyType.body.copyWith(color: inkSoft),
                ),
                const SizedBox(height: CapySpacing.lg),
                switch (strictness) {
                  PuzzleEscapeStrictness.confirm => CapyButton(
                    label: l10n.puzzleEscapeConfirmAction,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  PuzzleEscapeStrictness.confirmAndHold => HoldToActButton(
                    label: l10n.puzzleEscapeConfirmAction,
                    onCompleted: () => Navigator.of(context).pop(true),
                  ),
                },
                const SizedBox(height: CapySpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.puzzleEscapeCancelAction,
                    style: CapyType.label.copyWith(color: inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

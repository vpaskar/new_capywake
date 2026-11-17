import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_labels.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The two-column grid of selectable types. The last enabled type's toggle is
/// disabled, so the empty set `PuzzleSettings` throws on is never reached.
class PuzzleTypeGrid extends StatelessWidget {
  const PuzzleTypeGrid({
    required this.enabledTypes,
    required this.onTypeToggled,
    super.key,
  });

  final Set<PuzzleType> enabledTypes;

  /// Never called for the last remaining enabled type — that card's toggle is
  /// disabled and announced as such.
  final void Function(PuzzleType type, {required bool enabled}) onTypeToggled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spoken = PuzzleType.values.where((t) => t.isScreenReaderSolvable);
    final visual = PuzzleType.values.where((t) => !t.isScreenReaderSolvable);
    final isLastEnabled = enabledTypes.length == 1 ? enabledTypes.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeading(text: l10n.puzzleSettingsGroupSpoken),
        _Grid(
          types: spoken.toList(),
          enabledTypes: enabledTypes,
          lockedType: isLastEnabled,
          onTypeToggled: onTypeToggled,
        ),
        const SizedBox(height: CapySpacing.lg),
        _GroupHeading(text: l10n.puzzleSettingsGroupVisual),
        _Grid(
          types: visual.toList(),
          enabledTypes: enabledTypes,
          lockedType: isLastEnabled,
          onTypeToggled: onTypeToggled,
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          l10n.puzzleSettingsTypesFloorNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? CapyColors.darkInkSoft
                : CapyColors.cocoaSoft,
          ),
        ),
      ],
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: CapySpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.types,
    required this.enabledTypes,
    required this.lockedType,
    required this.onTypeToggled,
  });

  final List<PuzzleType> types;
  final Set<PuzzleType> enabledTypes;
  final PuzzleType? lockedType;
  final void Function(PuzzleType type, {required bool enabled}) onTypeToggled;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: CapySpacing.sm,
      crossAxisSpacing: CapySpacing.sm,
      childAspectRatio: 2.4,
      children: [
        for (final type in types)
          _TypeCard(
            type: type,
            selected: enabledTypes.contains(type),
            locked: type == lockedType,
            onToggled: (enabled) => onTypeToggled(type, enabled: enabled),
          ),
      ],
    );
  }
}

/// One selectable type card: icon, localized name, and a selection indicator.
class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.locked,
    required this.onToggled,
  });

  final PuzzleType type;
  final bool selected;

  /// The last remaining enabled type: selected, but its toggle is disabled so
  /// the enabled set can never be emptied.
  final bool locked;
  final ValueChanged<bool> onToggled;

  static const double _minHeight = 56;
  static const double iconSize = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final surface = dark ? CapyColors.darkSurface : CapyColors.surface;
    final border = selected
        ? CapyColors.accentDeep
        : (dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt);

    return Semantics(
      button: !locked,
      toggled: selected,
      enabled: !locked,
      label: locked
          ? '${puzzleTypeLabel(type, l10n)}. '
                '${l10n.puzzleSettingsTypesFloorNote}'
          : '${puzzleTypeLabel(type, l10n)}. '
                '${puzzleAccessibilityLabel(type, l10n)}',
      child: ExcludeSemantics(
        child: Material(
          color: surface,
          borderRadius: BorderRadius.circular(CapyRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(CapyRadius.md),
            onTap: locked ? null : () => onToggled(!selected),
            child: Container(
              constraints: const BoxConstraints(minHeight: _minHeight),
              padding: const EdgeInsets.all(CapySpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CapyRadius.md),
                border: Border.all(color: border, width: selected ? 2 : 1),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(CapyRadius.sm),
                    child: Image.asset(
                      puzzleTypeArt(type).path,
                      width: iconSize,
                      height: iconSize,
                    ),
                  ),
                  const SizedBox(width: CapySpacing.sm),
                  Expanded(
                    child: Text(
                      puzzleTypeLabel(type, l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: CapySpacing.xs),
                  _SelectionDot(selected: selected, locked: locked),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected, required this.locked});

  final bool selected;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (selected) {
      return Icon(
        locked ? Icons.lock_rounded : Icons.check_circle_rounded,
        size: CapyIconSize.md,
        color: CapyColors.accentDeep,
      );
    }
    return Icon(
      Icons.radio_button_unchecked_rounded,
      size: CapyIconSize.md,
      color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
    );
  }
}

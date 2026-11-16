import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// A section label with an optional trailing action. The action's affordance
/// is its word and chevron, so colour is not a lone state channel (F1).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An action needs both a label and a callback.',
       );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? CapyColors.darkInk
        : CapyColors.cocoa;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: CapyType.title.copyWith(color: ink),
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: CapyColors.accentDeep,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: CapySpacing.sm,
              ),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: CapyType.label.copyWith(
                    color: CapyColors.accentDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: CapyIconSize.sm,
                  color: CapyColors.accentDeep,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

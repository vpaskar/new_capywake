import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The form's header: circled back button and centred title. The mockup has
/// no gear — a pushed route offers no second way out.
class AlarmEditHeader extends StatelessWidget {
  const AlarmEditHeader({required this.title, this.onDelete, super.key});

  final String title;
  final VoidCallback? onDelete;

  static const height = 59.9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CapySpacing.md,
          ),
          child: Row(
            children: [
              _CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: l10n.alarmBackAction,
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: CapyType.title.copyWith(color: ink),
                  ),
                ),
              ),
              if (onDelete == null)
                const SizedBox(width: _CircleButton.size)
              else
                _CircleButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: l10n.alarmDeleteAction,
                  onPressed: onDelete!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: tooltip,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: dark ? CapyColors.darkSurface : CapyColors.surface,
            shape: CircleBorder(
              side: BorderSide(
                color: dark ? CapyColors.darkSurfaceAlt : CapyColors.surfaceAlt,
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  icon,
                  size: CapyIconSize.sm,
                  color: dark ? CapyColors.darkInk : CapyColors.cocoa,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// One wake-pool member and its switch. The last member left on is [locked]:
/// its switch is disabled, and the reason is shown and announced.
class PoolSwitchRow extends StatelessWidget {
  const PoolSwitchRow({
    required this.leading,
    required this.title,
    required this.value,
    required this.locked,
    required this.onChanged,
    this.onTry,
    this.unlockLabel,
    this.onUnlock,
    super.key,
  });

  final Widget leading;
  final String title;
  final bool value;
  final bool locked;
  final ValueChanged<bool> onChanged;

  /// Opens practice; `null` hides the action.
  final VoidCallback? onTry;

  /// While [locked]: opens the screen holding the other pool members.
  final String? unlockLabel;
  final VoidCallback? onUnlock;

  /// Past this text scale "Try it" moves under the title: inline, German
  /// overflows a 393 pt row at 2x.
  static const maxInlineTryTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final reason = l10n.challengePoolFloorReason;
    final tryInline =
        MediaQuery.textScalerOf(context).scale(1) <= maxInlineTryTextScale;
    final tryButton = onTry == null
        ? null
        : TextButton(
            onPressed: onTry,
            style: TextButton.styleFrom(
              foregroundColor: ink,
              minimumSize: const Size(
                CapyToggle.minTapTarget,
                CapyToggle.minTapTarget,
              ),
            ),
            child: Text(
              l10n.gameTryAction,
              semanticsLabel: '${l10n.gameTryAction}, $title',
            ),
          );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: CapyToggle.minTapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CapySpacing.xs),
        child: Row(
          children: [
            ExcludeSemantics(
              child: IconTheme(
                data: IconThemeData(size: CapyIconSize.md, color: inkSoft),
                child: leading,
              ),
            ),
            const SizedBox(width: CapySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (locked)
                    ExcludeSemantics(
                      child: Text(
                        reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: inkSoft,
                        ),
                      ),
                    ),
                  if (locked && onUnlock != null && unlockLabel != null)
                    TextButton(
                      onPressed: onUnlock,
                      style: TextButton.styleFrom(
                        foregroundColor: CapyColors.accentDeep,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(
                          CapyToggle.minTapTarget,
                          CapyToggle.minTapTarget,
                        ),
                      ),
                      child: Text(unlockLabel!),
                    ),
                  if (tryButton != null && !tryInline) tryButton,
                ],
              ),
            ),
            if (tryButton != null && tryInline) tryButton,
            CapyToggle(
              value: value,
              onChanged: locked ? null : onChanged,
              semanticLabel: locked ? '$title. $reason' : title,
              trackSize: CapyToggle.alarmEditTrack,
            ),
          ],
        ),
      ),
    );
  }
}

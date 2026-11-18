import 'package:capywake/core/motion/motion_check_service.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/alarms/edit/alarm_form_rows.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// This alarm's post-dismiss motion check: the switch, what it can and cannot
/// tell, and — when on — the rule and whether Settings has it off.
class MotionCheckCard extends StatelessWidget {
  const MotionCheckCard({
    required this.enabled,
    required this.globallyEnabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
  final bool globallyEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    Widget note(String text) => Padding(
      padding: const EdgeInsetsDirectional.only(top: CapySpacing.sm),
      child: Text(text, style: CapyType.caption.copyWith(color: inkSoft)),
    );

    return CapyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AlarmFormRowHeader(
            icon: Icons.directions_walk_rounded,
            title: l10n.alarmMotionCheckSectionLabel,
            trailing: CapyToggle(
              key: const ValueKey('motion-check-toggle'),
              value: enabled,
              onChanged: onChanged,
              semanticLabel: l10n.alarmMotionCheckLabel,
              trackSize: CapyToggle.alarmEditTrack,
            ),
          ),
          note(l10n.alarmMotionCheckDescription),
          if (enabled) ...[
            note(
              l10n.alarmMotionCheckWindowNote(
                MotionCheckService.defaultWindow.inSeconds,
              ),
            ),
            note(l10n.alarmMotionCheckLimitNote),
            if (!globallyEnabled) note(l10n.alarmMotionCheckGlobalOffNote),
          ],
        ],
      ),
    );
  }
}

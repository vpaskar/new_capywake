import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';

/// The icon-and-title line every card on `03_ADD_EDIT_ALARM.png` opens with,
/// optionally with a value and a chevron on the trailing side.
class AlarmFormRowHeader extends StatelessWidget {
  const AlarmFormRowHeader({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final bold = MediaQuery.boldTextOf(context);

    final row = Row(
      children: [
        Icon(icon, size: CapyIconSize.md, color: ink),
        const SizedBox(width: CapySpacing.md),
        Expanded(
          child: Text(
            title,
            style: CapyType.section.copyWith(
              color: ink,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
        if (value != null)
          Flexible(
            child: Text(
              value!,
              textAlign: TextAlign.end,
              style: CapyType.body.copyWith(color: inkSoft),
            ),
          ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            size: CapyIconSize.md,
            color: inkSoft,
          ),
        if (trailing != null) ...[
          const SizedBox(width: CapySpacing.sm),
          trailing!,
        ],
      ],
    );

    if (onTap == null) {
      return ExcludeSemantics(excluding: false, child: row);
    }

    return Semantics(
      button: true,
      label: title,
      value: value,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CapyRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CapyToggle.minTapTarget,
            ),
            child: row,
          ),
        ),
      ),
    );
  }
}

/// A row whose trailing control is a toggle, like Snooze.
class AlarmFormToggleRow extends StatelessWidget {
  const AlarmFormToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    required this.semanticLabel,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final String semanticLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AlarmFormRowHeader(
      icon: icon,
      title: title,
      value: value,
      trailing: CapyToggle(
        value: enabled,
        onChanged: onChanged,
        semanticLabel: semanticLabel,
        trackSize: CapyToggle.alarmEditTrack,
      ),
    );
  }
}

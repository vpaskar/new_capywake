import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Whether [access] leaves something to ask the user for.
bool deviceAccessCanImprove(DeviceAccess access) =>
    access == DeviceAccess.needsPermission ||
    access == DeviceAccess.permanentlyDenied;

/// The words a [DeviceAccessPrompt] shows for one capability.
@immutable
class DeviceAccessCopy {
  const DeviceAccessCopy({
    required this.title,
    required this.body,
    required this.deniedBody,
    required this.allow,
  });

  DeviceAccessCopy.steps(AppLocalizations l10n, String game)
    : this(
        title: l10n.stepAccessTitle,
        body: l10n.stepAccessBody(game),
        deniedBody: l10n.stepAccessDeniedBody,
        allow: l10n.stepAccessAllow,
      );

  DeviceAccessCopy.camera(AppLocalizations l10n, String game)
    : this(
        title: l10n.cameraAccessTitle,
        body: l10n.cameraAccessBody(game),
        deniedBody: l10n.cameraAccessDeniedBody,
        allow: l10n.cameraAccessAllow,
      );

  final String title;
  final String body;
  final String deniedBody;
  final String allow;
}

/// Why CapyWake would like a capability, shown before the OS prompt and never
/// while an alarm rings. [onResolved] gets the access after an answer.
class DeviceAccessPrompt extends StatefulWidget {
  const DeviceAccessPrompt({
    required this.permission,
    required this.access,
    required this.copy,
    required this.onResolved,
    required this.onNotNow,
    this.onSettingsOpened,
    super.key,
  });

  final DevicePermission permission;
  final DeviceAccess access;
  final DeviceAccessCopy copy;
  final ValueChanged<DeviceAccess> onResolved;
  final VoidCallback onNotNow;
  final VoidCallback? onSettingsOpened;

  @override
  State<DeviceAccessPrompt> createState() => _DeviceAccessPromptState();
}

class _DeviceAccessPromptState extends State<DeviceAccessPrompt> {
  bool _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);
    final access = await widget.permission.requestAccess();
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onResolved(access);
  }

  /// Settings opens at once; the host re-reads access when the app resumes.
  Future<void> _openSettings() async {
    await widget.permission.openSettings();
    if (mounted) widget.onSettingsOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final denied = widget.access == DeviceAccess.permanentlyDenied;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.copy.title,
          style: CapyType.section.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          denied ? widget.copy.deniedBody : widget.copy.body,
          style: CapyType.body.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.lg),
        CapyButton(
          label: denied
              ? l10n.reliabilityOpenSettingsAction
              : widget.copy.allow,
          onPressed: _busy ? null : (denied ? _openSettings : _allow),
        ),
        const SizedBox(height: CapySpacing.xs),
        TextButton(
          onPressed: widget.onNotNow,
          style: TextButton.styleFrom(foregroundColor: ink),
          child: Text(l10n.permissionNotNowAction),
        ),
      ],
    );
  }
}

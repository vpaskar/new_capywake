import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Whether [access] leaves something to ask the user for.
bool stepAccessCanImprove(StepAccess access) =>
    access == StepAccess.needsPermission ||
    access == StepAccess.permanentlyDenied;

/// Why CapyWake would like the step sensor, shown before the OS prompt and
/// never while an alarm rings. [onResolved] gets the access after an answer.
class StepAccessPrompt extends StatefulWidget {
  const StepAccessPrompt({
    required this.sensor,
    required this.access,
    required this.gameName,
    required this.onResolved,
    required this.onNotNow,
    this.onSettingsOpened,
    super.key,
  });

  final StepSensor sensor;
  final StepAccess access;
  final String gameName;
  final ValueChanged<StepAccess> onResolved;
  final VoidCallback onNotNow;
  final VoidCallback? onSettingsOpened;

  @override
  State<StepAccessPrompt> createState() => _StepAccessPromptState();
}

class _StepAccessPromptState extends State<StepAccessPrompt> {
  bool _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);
    final access = await widget.sensor.requestAccess();
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onResolved(access);
  }

  /// Settings opens at once; the host re-reads access when the app resumes.
  Future<void> _openSettings() async {
    await widget.sensor.openSettings();
    if (mounted) widget.onSettingsOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final denied = widget.access == StepAccess.permanentlyDenied;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.stepAccessTitle,
          style: CapyType.section.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          denied
              ? l10n.stepAccessDeniedBody
              : l10n.stepAccessBody(widget.gameName),
          style: CapyType.body.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.lg),
        CapyButton(
          label: denied
              ? l10n.reliabilityOpenSettingsAction
              : l10n.stepAccessAllow,
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

/// Offers the step sensor after a game that counts steps is switched on in a
/// wake pool. Shows nothing for other games, or when there is nothing to ask.
Future<void> offerStepAccess(
  BuildContext context, {
  required StepSensor sensor,
  required String gameId,
  required bool enabled,
}) async {
  final entry = GameCatalogue.byId(gameId);
  if (!enabled || entry == null || !entry.countsSteps) return;
  final name = gameName(AppLocalizations.of(context), entry);
  final access = await sensor.access();
  if (!context.mounted || !stepAccessCanImprove(access)) return;
  final dark = Theme.of(context).brightness == Brightness.dark;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: dark ? CapyColors.darkSurface : CapyColors.surface,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CapySpacing.xl,
          0,
          CapySpacing.xl,
          CapySpacing.lg,
        ),
        child: StepAccessPrompt(
          key: const ValueKey('step-access-sheet'),
          sensor: sensor,
          access: access,
          gameName: name,
          onResolved: (_) => Navigator.of(sheet).pop(),
          onNotNow: () => Navigator.of(sheet).pop(),
          onSettingsOpened: () => Navigator.of(sheet).pop(),
        ),
      ),
    ),
  );
}

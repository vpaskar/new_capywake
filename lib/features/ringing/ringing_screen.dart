import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/hold_to_act_button.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/ringing/escape_sheet.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// The surface a ringing alarm shows. Nothing animates, and the board's
/// locked Dismiss is not shipped — the escape is reachable. See PHASE_06_PLAN.
class RingingScreen extends StatelessWidget {
  const RingingScreen({
    required this.session,
    required this.onDismiss,
    required this.onSnooze,
    required this.onEscape,
    this.escapeStrictness = PuzzleEscapeStrictness.confirm,
    this.puzzleSlot,
    super.key,
  });

  final RingingSession session;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;
  final VoidCallback onEscape;

  /// Resolved by the caller: re-resolving here would drop the user's
  /// app-wide settings and silently fall back to the defaults.
  final PuzzleEscapeStrictness escapeStrictness;

  /// The puzzle, or `null` when the alarm can be stopped directly.
  final Widget? puzzleSlot;

  Alarm get _alarm => session.alarm;

  bool get _puzzleGated => puzzleSlot != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final surface = dark ? CapyColors.darkSurface : CapyColors.surface;

    return Scaffold(
      backgroundColor: surface,
      // No SafeArea around the hero: the art bleeds to the top edge as the
      // mockups do. Its own content is inset by the status-bar height.
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _Hero(session: session, ink: ink, inkSoft: inkSoft),
                // Overlapping the art, as the board draws it — which is
                // what keeps the whole surface on one screen.
                if (puzzleSlot != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CapySpacing.lg,
                        ),
                        child: puzzleSlot,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: _Actions(
              session: session,
              l10n: l10n,
              puzzleGated: _puzzleGated,
              dismissMethod: _alarm.dismissMethod,
              onDismiss: onDismiss,
              onSnooze: onSnooze,
              onEscape: () => _confirmEscape(context),
              inkSoft: inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEscape(BuildContext context) async {
    final confirmed = await showEscapeSheet(
      context: context,
      strictness: escapeStrictness,
    );
    if (confirmed ?? false) onEscape();
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.session,
    required this.ink,
    required this.inkSoft,
  });

  final RingingSession session;
  final Color ink;
  final Color inkSoft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parts = AlarmFormat.timeParts(
      minutes: session.alarm.targetTimeMinutes,
      localeName: l10n.localeName,
      format: TimeFormatPreference.system,
    );

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The scene is 3:2 and the band taller, so `cover` would zoom past
          // the capybara's face. Fitted to width, surface behind the rest.
          const ColoredBox(color: CapyColors.surface),
          Align(
            alignment: Alignment.topCenter,
            child: Stack(
              children: [
                Image.asset(
                  SceneCrop.alarms.asset,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
                const Positioned.fill(
                  child: ColoredBox(color: CapyColors.artScrim),
                ),
              ],
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CapySpacing.lg,
                vertical: CapySpacing.lg,
              ),
              child: Column(
                children: [
                  if (session.alarm.label.isNotEmpty)
                    Text(
                      session.alarm.label,
                      textAlign: TextAlign.center,
                      style: CapyType.section.copyWith(color: Colors.white),
                    ),
                  const SizedBox(height: CapySpacing.xs),
                  _Clock(parts: parts),
                  if (session.isFinalAlarm) ...[
                    const SizedBox(height: CapySpacing.sm),
                    Text(
                      l10n.ringingFinalAlarmNote,
                      textAlign: TextAlign.center,
                      style: CapyType.body.copyWith(color: Colors.white),
                    ),
                  ],
                  if (session.occurrence.snoozeCount > 0) ...[
                    const SizedBox(height: CapySpacing.xs),
                    Text(
                      l10n.ringingSnoozedCount(session.occurrence.snoozeCount),
                      textAlign: TextAlign.center,
                      style: CapyType.label.copyWith(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Digits and AM/PM styled apart — what `AlarmFormat.timeParts` is for.
class _Clock extends StatelessWidget {
  const _Clock({required this.parts});

  final ClockTimeParts parts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.ringingAlarmTimeHeading,
      value: parts.period == null
          ? parts.time
          : '${parts.time} ${parts.period}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            parts.time,
            style: CapyType.display.copyWith(color: Colors.white),
          ),
          if (parts.period != null) ...[
            const SizedBox(width: CapySpacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: CapySpacing.sm),
              child: Text(
                parts.period!,
                style: CapyType.section.copyWith(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.session,
    required this.l10n,
    required this.puzzleGated,
    required this.dismissMethod,
    required this.onDismiss,
    required this.onSnooze,
    required this.onEscape,
    required this.inkSoft,
  });

  final RingingSession session;
  final AppLocalizations l10n;
  final bool puzzleGated;
  final DismissMethod dismissMethod;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;
  final VoidCallback onEscape;
  final Color inkSoft;

  @override
  Widget build(BuildContext context) {
    final prominent =
        session.escapeVisibility == PuzzleEscapeVisibility.prominent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CapySpacing.lg,
        CapySpacing.md,
        CapySpacing.lg,
        CapySpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session.snoozeAvailable) ...[
            CapyButton(
              label: l10n.alarmSnoozeLabel,
              onPressed: onSnooze,
            ),
            const SizedBox(height: CapySpacing.md),
          ],
          if (!puzzleGated) _dismissControl(),
          if (puzzleGated || prominent) ...[
            if (!puzzleGated) const SizedBox(height: CapySpacing.md),
            _EscapeControl(
              label: l10n.puzzleEscapeAction,
              prominent: prominent,
              onPressed: onEscape,
              inkSoft: inkSoft,
            ),
          ],
        ],
      ),
    );
  }

  Widget _dismissControl() => switch (dismissMethod) {
    DismissMethod.holdToDismiss => HoldToActButton(
      label: l10n.ringingHoldToDismissAction,
      onCompleted: onDismiss,
    ),
    DismissMethod.normalButton || DismissMethod.puzzle => CapyButton(
      label: l10n.ringingDismissAction,
      onPressed: onDismiss,
    ),
  };
}

/// The emergency escape: present whenever a puzzle stands between the user
/// and silence, raised by `escapeVisibilityFor`. Neither state hides it.
class _EscapeControl extends StatelessWidget {
  const _EscapeControl({
    required this.label,
    required this.prominent,
    required this.onPressed,
    required this.inkSoft,
  });

  final String label;
  final bool prominent;
  final VoidCallback onPressed;
  final Color inkSoft;

  @override
  Widget build(BuildContext context) {
    if (prominent) {
      return CapyButton(label: label, onPressed: onPressed);
    }
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: CapyButton.height,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: CapyType.label.copyWith(
                  color: inkSoft,
                  decoration: TextDecoration.underline,
                  decorationColor: inkSoft,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

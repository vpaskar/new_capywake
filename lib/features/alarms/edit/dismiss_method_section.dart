import 'package:capywake/app/router.dart';
import 'package:capywake/core/alarm_dismiss_summary.dart';
import 'package:capywake/core/models/dismiss_method.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/alarms/edit/alarm_form_rows.dart';
import 'package:capywake/features/games/challenge_pool_picker.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The per-alarm dismiss-method control: Tap or Puzzle only (no "Shake"). While
/// Puzzle is on, a switch follows defaults or this alarm's own settings.
class DismissMethodSection extends StatelessWidget {
  const DismissMethodSection({
    required this.method,
    required this.hasOverride,
    required this.summary,
    required this.onMethodChanged,
    required this.onFollowDefaultsChanged,
    required this.includePuzzles,
    required this.enabledGames,
    required this.onPuzzlesChanged,
    required this.onGameChanged,
    super.key,
  });

  final DismissMethod method;

  /// Whether this alarm carries its own puzzle settings (an override) rather
  /// than following the app-wide defaults.
  final bool hasOverride;

  /// The effective puzzle configuration, as a short line (e.g. "Medium, 2").
  final String summary;

  final ValueChanged<DismissMethod> onMethodChanged;
  final void Function({required bool follow}) onFollowDefaultsChanged;

  /// This alarm's resolved wake pool, editable only while it has an override.
  final bool includePuzzles;
  final Set<String> enabledGames;
  final ValueChanged<bool> onPuzzlesChanged;
  final void Function(String gameId, {required bool enabled}) onGameChanged;

  /// Whether the two-segment Tap/Puzzle control can show this method.
  static bool _representable(DismissMethod method) =>
      method == DismissMethod.normalButton || method == DismissMethod.puzzle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPuzzle = method == DismissMethod.puzzle;

    return CapyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AlarmFormRowHeader(
            icon: Icons.sports_esports_outlined,
            title: l10n.alarmDismissMethodLabel,
          ),
          const SizedBox(height: CapySpacing.md),
          if (_representable(method))
            _MethodSelector(method: method, onChanged: onMethodChanged)
          else
            // A method the two-segment control cannot show (holdToDismiss):
            // name it read-only rather than claim it is Tap.
            Text(
              AlarmDismissSummary.format(method: method, l10n: l10n),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          if (isPuzzle) ...[
            const SizedBox(height: CapySpacing.md),
            AlarmFormToggleRow(
              icon: Icons.settings_suggest_outlined,
              title: l10n.alarmPuzzleUseDefaultsLabel,
              value: hasOverride
                  ? l10n.alarmPuzzleCustomDescription
                  : l10n.alarmPuzzleUseDefaultsDescription,
              enabled: !hasOverride,
              semanticLabel: l10n.alarmPuzzleUseDefaultsLabel,
              onChanged: (follow) => onFollowDefaultsChanged(follow: follow),
            ),
            const SizedBox(height: CapySpacing.sm),
            _SummaryRow(summary: summary),
            if (hasOverride) ...[
              const SizedBox(height: CapySpacing.md),
              Text(
                l10n.alarmChallengePoolLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: CapySpacing.xs),
              ChallengePoolPicker(
                includePuzzles: includePuzzles,
                enabledGames: enabledGames,
                onPuzzlesChanged: onPuzzlesChanged,
                onGameChanged: onGameChanged,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.method, required this.onChanged});

  final DismissMethod method;
  final ValueChanged<DismissMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SegmentedButton<DismissMethod>(
      segments: [
        ButtonSegment<DismissMethod>(
          value: DismissMethod.normalButton,
          label: Text(l10n.alarmDismissMethodNormal),
          icon: const Icon(Icons.touch_app_outlined),
        ),
        ButtonSegment<DismissMethod>(
          value: DismissMethod.puzzle,
          label: Text(l10n.alarmDismissMethodPuzzle),
          icon: const Icon(Icons.extension_rounded),
        ),
      ],
      selected: {method},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Semantics(
      button: true,
      label: '${l10n.settingsPuzzleHeading}, $summary',
      onTap: () => context.push(Routes.settingsPuzzle),
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(CapyRadius.md),
          onTap: () => context.push(Routes.settingsPuzzle),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CapyToggle.minTapTarget,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.extension_outlined,
                  size: CapyIconSize.md,
                  color: inkSoft,
                ),
                const SizedBox(width: CapySpacing.sm),
                Expanded(
                  child: Text(
                    summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: inkSoft,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: CapyIconSize.md,
                  color: inkSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

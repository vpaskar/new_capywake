import 'package:capywake/app/router.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_group.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/features/settings/settings_rows.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A replayable account of what the app sets up. Not a placeholder for the
/// unbuilt first-run flow: every section and both chevrons lead somewhere.
class WalkthroughScreen extends StatelessWidget {
  const WalkthroughScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.settings,
        bandHeight: _heroBandHeight,
        header: SettingsHeader(title: l10n.walkthroughTitle),
        child: const _Body(),
      ),
    );
  }

  /// **Not a measurement** — this screen has no mockup. Matches the
  /// checklist's so the two pushed sub-routes open alike.
  static const _heroBandHeight = 84.0;
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final inkSoft = theme.brightness == Brightness.dark
        ? CapyColors.darkInkSoft
        : CapyColors.cocoaSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CapySpacing.gutterNarrow,
              CapySpacing.lg,
              CapySpacing.gutterNarrow,
              CapySpacing.lg,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CapySpacing.sm,
                  vertical: CapySpacing.sm,
                ),
                child: Text(
                  l10n.walkthroughIntro,
                  style: theme.textTheme.bodyLarge?.copyWith(color: inkSoft),
                ),
              ),
              const SizedBox(height: CapySpacing.sm),
              SettingsGroup(
                icon: Icons.alarm_rounded,
                title: l10n.walkthroughAlarmsTitle,
                rows: [
                  SettingsChevronRow(
                    icon: Icons.add_alarm_rounded,
                    title: l10n.alarmAddAction,
                    subtitle: l10n.walkthroughAlarmsBody,
                    // Pop this route and Settings before switching branch:
                    // `go` alone leaves both over the tab it selected.
                    onTap: () {
                      final router = GoRouter.of(context);
                      while (router.canPop()) {
                        router.pop();
                      }
                      router.go(Routes.alarms);
                    },
                  ),
                ],
              ),
              const SizedBox(height: SettingsGroup.gap),
              SettingsGroup(
                icon: Icons.tune_rounded,
                title: l10n.walkthroughDefaultsTitle,
                rows: [
                  _ProseRow(
                    icon: Icons.music_note_rounded,
                    title: l10n.settingsDefaultsHeading,
                    body: l10n.walkthroughDefaultsBody,
                  ),
                ],
              ),
              const SizedBox(height: SettingsGroup.gap),
              SettingsGroup(
                icon: Icons.verified_outlined,
                title: l10n.walkthroughReliabilityTitle,
                rows: [
                  SettingsChevronRow(
                    icon: Icons.checklist_rounded,
                    title: l10n.settingsReliabilityEntryLabel,
                    subtitle: l10n.walkthroughReliabilityBody,
                    onTap: () => context.push(Routes.settingsReliability),
                  ),
                ],
              ),
            ],
          ),
        ),
        const MeadowFooter(height: 52.2),
      ],
    );
  }
}

/// A walkthrough row that explains rather than navigates — no chevron, so
/// nothing suggests a tap that does nothing.
class _ProseRow extends StatelessWidget {
  const _ProseRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SettingsRowMetrics.horizontalPadding,
        vertical: SettingsRowMetrics.verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: CapyIconSize.md, color: inkSoft),
          ),
          const SizedBox(width: CapySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

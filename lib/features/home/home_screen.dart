import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/next_alarm.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/section_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/home/game_rail.dart';
import 'package:capywake/features/home/next_alarm_card.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reads "now" for the next-alarm calculation. A provider so tests can pin
/// the clock instead of a `DateTime.now()` buried inside a `build`.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Home / Today, against `01_HOME.png`. Blocks are measured and positioned
/// independently, so one box's error does not shift every box below it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsStreamProvider).value ?? const <Alarm>[];
    final finished =
        ref.watch(finishedOccurrencesStreamProvider).value ??
        const <AlarmOccurrence>[];
    final settings = ref.watch(userSettingsStreamProvider).value;

    final next = NextAlarmService.computeNext(
      alarms: alarms,
      now: ref.read(homeClockProvider)(),
      finishedOccurrences: finished,
    );

    return SceneHeader(
      scene: SceneCrop.home,
      header: const CapyHeader(),
      child: _Body(next: next, settings: settings ?? UserSettings.initial),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.next, required this.settings});

  final NextAlarmInfo? next;
  final UserSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: _cardTopGap),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: CapySpacing.gutter,
                  ),
                  child: NextAlarmCard(
                    next: next,
                    settings: settings,
                    onToggle: (enabled) => _onToggle(ref, enabled),
                  ),
                ),
                const SizedBox(height: _cardToCtaGap),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: CapySpacing.gutter,
                  ),
                  child: CapyButton(
                    label: l10n.todayCreateAlarmAction,
                    icon: Icons.add_circle,
                    onPressed: () => context.go(Routes.alarms),
                  ),
                ),
                const SizedBox(height: _ctaToSectionGap),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: CapySpacing.gutter,
                  ),
                  child: SectionHeader(
                    title: l10n.homeGamesHeading,
                    actionLabel: l10n.homeGamesSeeAll,
                    onAction: () => context.go(Routes.stats),
                  ),
                ),
                const SizedBox(height: _sectionToRailGap),
                const GameRail(),
                const SizedBox(height: _railToStatsGap),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: CapySpacing.gutter,
                  ),
                  child: _MyStatsRow(onTap: () => context.go(Routes.stats)),
                ),
                const SizedBox(height: CapySpacing.sm),
              ],
            ),
          ),
        ),
        // Pinned: a meadow that scrolls away leaves the nav on bare cream.
        const MeadowFooter(),
      ],
    );
  }

  void _onToggle(WidgetRef ref, bool enabled) {
    final info = next;
    if (info == null) return;
    ref
        .read(capywakeRepositoryProvider)
        .upsertAlarm(info.alarm.copyWith(enabled: enabled));
  }

  /// Gaps between mockup edges, from the status bar. See `tier_a_blocks.md`.

  static const _cardTopGap = 27.7;
  static const _cardToCtaGap = 15.3;
  static const _ctaToSectionGap = 43.0;

  /// Section header top 454.8, tile art top 485.7, less the header row.
  static const double _sectionToRailGap = CapySpacing.sm;

  /// Labels end 593.9, My Stats card top 617.0.
  static const _railToStatsGap = 23.1;
}

class _MyStatsRow extends StatelessWidget {
  const _MyStatsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? CapyColors.darkInk
        : CapyColors.cocoa;

    return Semantics(
      button: true,
      label: l10n.homeMyStats,
      child: ExcludeSemantics(
        child: CapyCard(
          onTap: onTap,
          child: Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: CapyColors.accentDeep,
                size: CapyIconSize.md,
              ),
              const SizedBox(width: CapySpacing.md),
              Expanded(
                child: Text(
                  l10n.homeMyStats,
                  style: CapyType.title.copyWith(color: ink),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ink,
                size: CapyIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

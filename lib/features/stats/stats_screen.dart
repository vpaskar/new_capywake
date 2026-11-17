import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/stats/alarms_segment.dart';
import 'package:capywake/features/stats/sleep_segment.dart';
import 'package:capywake/features/stats/stats_notice.dart';
import 'package:capywake/features/stats/stats_providers.dart';
import 'package:capywake/features/stats/stats_segment_switcher.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistics, against `05_STATS.png`. The mockup draws a filled screen; the
/// default here is empty. `docs/visual/stats/README.md` says what that costs.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  /// 215.4 - 103.9 on the mockup. Home 188.4, Alarms 148.6, Add/Edit 112.1,
  /// Settings 109.0 — a fifth distinct value.
  static const heroBandHeight = 111.5;

  /// 853 - 773.1: the meadow's flat lower edge, the mode across 40 columns.
  static const meadowHeight = 79.9;

  /// 295.6 - 280.3 on the mockup: switcher bottom to the first card's top.
  static const switcherToCardGap = 15.3;

  /// Zero: the mockup's title straddles the cloud lobe 6.7 pt above the
  /// cream's flat top, which a flat-topped `SceneHeader` cannot reach.
  static const titleTopGap = 0.0;

  /// Zero, the whole budget left before the mockup's track top.
  static const titleToSwitcherGap = 0.0;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsSegment _segment = StatsSegment.sleep;

  @override
  Widget build(BuildContext context) {
    return SceneHeader(
      scene: SceneCrop.stats,
      bandHeight: StatsScreen.heroBandHeight,
      header: const CapyHeader(),
      child: _Body(
        segment: _segment,
        onSegmentSelected: (segment) => setState(() => _segment = segment),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.segment, required this.onSegmentSelected});

  final StatsSegment segment;
  final ValueChanged<StatsSegment> onSegmentSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CapySpacing.gutter,
              StatsScreen.titleTopGap,
              CapySpacing.gutter,
              CapySpacing.lg,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.statsTitle,
                  textAlign: TextAlign.center,
                  style: CapyType.title.copyWith(color: ink),
                ),
              ),
              const SizedBox(height: StatsScreen.titleToSwitcherGap),
              StatsSegmentSwitcher(
                selected: segment,
                onSelected: onSegmentSelected,
              ),
              const SizedBox(height: StatsScreen.switcherToCardGap),
              switch (segment) {
                StatsSegment.sleep => const SleepSegment(),
                StatsSegment.alarms => AlarmsSegment(
                  state: ref.watch(statsAlarmsStateProvider),
                ),
                StatsSegment.games => StatsNotice(
                  title: l10n.statsGamesNotRecordedTitle,
                  body: l10n.statsGamesNotRecordedBody,
                ),
              },
            ],
          ),
        ),
        const MeadowFooter(height: StatsScreen.meadowHeight),
      ],
    );
  }
}

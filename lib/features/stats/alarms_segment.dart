import 'package:capywake/core/history/history_service.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/stats/stat_tile.dart';
import 'package:capywake/features/stats/stats_notice.dart';
import 'package:capywake/features/stats/stats_providers.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Wake-up statistics, or their absence. The card envelopes stay in every
/// state, so Tier A has something to measure on a fresh install.
class AlarmsSegment extends StatelessWidget {
  const AlarmsSegment({required this.state, super.key});

  final StatsAlarmsState state;

  static const cardGap = 9.7;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = switch (state) {
      StatsAlarmsReady(:final summary) => summary,
      _ => null,
    };

    String? count(int? Function(HistorySummary s) read) {
      final s = summary;
      return s == null ? null : read(s)?.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CapyCard(
          child: StatTile(
            icon: Icons.wb_sunny_rounded,
            label: l10n.historyOnTimeLabel,
            value: count((s) => s.onTimeCount),
          ),
        ),
        const SizedBox(height: cardGap),
        CapyCard(
          child: StatTile(
            icon: Icons.snooze_rounded,
            label: l10n.historyLateLabel,
            value: count((s) => s.lateCount),
          ),
        ),
        const SizedBox(height: cardGap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CapyCard(
                  child: StatTile(
                    icon: Icons.skip_next_rounded,
                    label: l10n.historySkippedLabel,
                    value: count((s) => s.skippedCount),
                  ),
                ),
              ),
              const SizedBox(width: cardGap),
              Expanded(
                child: CapyCard(
                  child: StatTile(
                    icon: Icons.notifications_off_rounded,
                    label: l10n.historyMissedLabel,
                    value: count((s) => s.missedCount),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: cardGap),
        CapyCard(
          child: StatTile(
            icon: Icons.bar_chart_rounded,
            label: l10n.historyAverageSnoozeLabel,
            value: summary == null
                ? null
                : l10n.historyAverageSnoozeValue(
                    summary.averageSnoozeCount.round(),
                  ),
          ),
        ),
        if (state is StatsAlarmsEmpty)
          StatsNotice(
            title: l10n.historyEmptyTitle,
            body: l10n.historyEmptyBody,
          ),
      ],
    );
  }
}

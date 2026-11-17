import 'package:capywake/core/history/history_service.dart';
import 'package:capywake/data/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads "now" for the history window. Pinned in tests, as on the other tabs.
final statsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The mockup's "Last 7 Days" is a fabricated figure, so 7 is offered and
/// the service default is what loads.
const statsWindowChoices = <int>[
  7,
  HistoryService.defaultWindowDays,
  HistoryService.extendedWindowDays,
];

final statsWindowProvider = NotifierProvider<StatsWindow, int>(StatsWindow.new);

class StatsWindow extends Notifier<int> {
  @override
  int build() => HistoryService.defaultWindowDays;

  void select(int days) {
    if (statsWindowChoices.contains(days)) state = days;
  }
}

/// What the Alarms segment may draw. Absence is a case, not a summary full of
/// zeros: `HistorySummary.empty` would render a measured-looking `0`.
@immutable
sealed class StatsAlarmsState {
  const StatsAlarmsState();
}

/// Envelopes, no values, no empty copy — so the screen never flashes
/// "nothing here" before data arrives.
class StatsAlarmsLoading extends StatsAlarmsState {
  const StatsAlarmsLoading();
}

/// No occurrence inside the chosen window. The default on a fresh install.
class StatsAlarmsEmpty extends StatsAlarmsState {
  const StatsAlarmsEmpty(this.windowDays);

  final int windowDays;
}

class StatsAlarmsReady extends StatsAlarmsState {
  const StatsAlarmsReady(this.summary);

  final HistorySummary summary;
}

/// Empty is `occurrenceCount == 0` within the window, not an empty list:
/// only-skipped rows are a real summary.
final statsAlarmsStateProvider = Provider<StatsAlarmsState>((ref) {
  final occurrences = ref.watch(allOccurrencesStreamProvider);
  final alarms = ref.watch(alarmsStreamProvider);
  final windowDays = ref.watch(statsWindowProvider);

  final rows = occurrences.value;
  final alarmRows = alarms.value;
  if (rows == null || alarmRows == null) return const StatsAlarmsLoading();

  final summary = HistoryService.summarise(
    occurrences: rows,
    alarms: alarmRows,
    now: ref.watch(statsClockProvider)(),
    windowDays: windowDays,
  );

  return summary.occurrenceCount == 0
      ? StatsAlarmsEmpty(windowDays)
      : StatsAlarmsReady(summary);
});

// No sleep provider: without a health gateway it would have one reachable
// value, and the segment a branch no test could reach.

import 'package:capywake/core/models/models.dart';
import 'package:meta/meta.dart';

/// Pure-Dart aggregator for the History tab.
///
/// `HistoryService.summarise` reads a list of [AlarmOccurrence]s and the
/// parent [Alarm]s, applies a fixed look-back window (default 14 days), and
/// returns a [HistorySummary] that the screen renders calmly. Everything
/// here is honest, non-judgmental, and Flutter-free — no widget code, no
/// guilt language, no fake "sleep stage" inferences.
///
/// **Counting rules**
///
/// - `dismissed`, `missed`, `skipped`, `escaped`, `snoozed`, `triggered`
///   counts are straight tallies of the corresponding [AlarmStatus] values
///   among occurrences whose `scheduledAt` (UTC) falls inside the window.
/// - `escaped` — the alarm was stopped with the wake puzzle's emergency
///   escape — is counted and shown as its own plain outcome. It is neither
///   folded into `dismissed` (which would overstate the morning) nor treated
///   as a failure, and it deliberately feeds **no** insight: the escape exists
///   for mornings when someone is ill or has to take a call, and inventing a
///   pattern out of it would be exactly the judgement this screen refuses to
///   make.
/// - "On time" means a terminal-`dismissed` occurrence with `snoozeCount == 0`.
///   It is the kindest neutral measure available without lying about
///   sleep-stage data we do not have.
/// - "Late" means a terminal-`dismissed` occurrence with `snoozeCount > 0`.
///   It is calmly named — never "you snoozed too much".
/// - The "average snooze count" is computed across **dismissed-only**
///   occurrences, since `triggered`/`snoozed` are mid-flight states whose
///   snooze count would skew the average toward "currently still snoozing".
/// - Per-day summaries are bucketed in the local timezone of the input
///   `now` (calendar-day granularity); the input occurrences keep their UTC
///   times, but the bucket key is the local date of `scheduledAt.toLocal()`
///   so a 23:00 alarm and a 07:00 alarm sit on the same day from the
///   user's point of view.
///
/// **Insight rules** (see `_buildInsights`): each insight is computed from
/// the same window, never from a moving "I haven't seen you in a while"
/// observation. Strings are templates — the UI renders them through ARB
/// keys, so the service emits structural [HistoryInsight]s with arguments
/// rather than raw English text.
abstract final class HistoryService {
  /// Default look-back window for the History screen, in days.
  static const int defaultWindowDays = 14;

  /// Look-back window for the extended history summary.
  static const int extendedWindowDays = 90;

  /// Minimum number of dismissed-with-snooze occurrences needed before the
  /// "you usually dismiss after one snooze" insight fires. Keeps the
  /// History screen honest on a brand-new install.
  static const int minOccurrencesForAverageInsight = 3;

  /// Minimum number of skipped occurrences on the same weekday before the
  /// "you often skip on Mondays" insight fires. Two skips in a fortnight is
  /// a coincidence; three is a pattern worth surfacing calmly.
  static const int minSkipsForWeekdayInsight = 3;

  /// Minimum number of strict-mode dismissals (snooze-count == 0) before
  /// the "Strict mode helped on N mornings" insight fires.
  static const int minStrictHelpedDismissals = 2;

  /// Compute a [HistorySummary] from the given occurrences.
  ///
  /// [occurrences] are filtered to those whose `scheduledAt` falls inside
  /// `[now - windowDays, now]` (UTC inclusive). The window is honoured
  /// strictly — anything older is dropped.
  static HistorySummary summarise({
    required List<AlarmOccurrence> occurrences,
    required List<Alarm> alarms,
    required DateTime now,
    int windowDays = defaultWindowDays,
  }) {
    assert(windowDays > 0, 'windowDays must be > 0.');
    final nowUtc = now.toUtc();
    final windowStartUtc = nowUtc.subtract(Duration(days: windowDays));
    final inWindow = occurrences
        .where((o) {
          final scheduledUtc = o.scheduledAt.toUtc();
          return !scheduledUtc.isBefore(windowStartUtc) &&
              !scheduledUtc.isAfter(nowUtc);
        })
        .toList(growable: false);

    final alarmById = <String, Alarm>{
      for (final a in alarms) a.id: a,
    };

    final triggered = _countWhere(inWindow, AlarmStatus.triggered);
    final snoozed = _countWhere(inWindow, AlarmStatus.snoozed);
    final dismissed = _countWhere(inWindow, AlarmStatus.dismissed);
    final skipped = _countWhere(inWindow, AlarmStatus.skipped);
    final escaped = _countWhere(inWindow, AlarmStatus.escaped);
    final missed = _countWhere(inWindow, AlarmStatus.missed);

    final dismissedRows = inWindow
        .where((o) => o.status == AlarmStatus.dismissed)
        .toList(growable: false);
    final onTime = dismissedRows.where((o) => o.snoozeCount == 0).length;
    final late = dismissedRows.length - onTime;
    final averageSnoozeCount = dismissedRows.isEmpty
        ? 0.0
        : dismissedRows
                  .map((o) => o.snoozeCount)
                  .fold<int>(0, (a, b) => a + b) /
              dismissedRows.length;

    final dailies = _bucketByLocalDate(inWindow);

    final insights = _buildInsights(
      window: inWindow,
      dismissedRows: dismissedRows,
      averageSnoozeCount: averageSnoozeCount,
      alarmById: alarmById,
    );

    return HistorySummary(
      windowDays: windowDays,
      occurrenceCount: inWindow.length,
      triggeredCount: triggered,
      snoozedCount: snoozed,
      dismissedCount: dismissed,
      skippedCount: skipped,
      escapedCount: escaped,
      missedCount: missed,
      onTimeCount: onTime,
      onTimeDayCount: _distinctLocalDays(
        dismissedRows.where((o) => o.snoozeCount == 0),
      ),
      lateCount: late,
      averageSnoozeCount: averageSnoozeCount,
      typicalWakeMinutes: _typicalWakeMinutes(dismissedRows),
      daily: dailies,
      insights: insights,
    );
  }

  /// How many distinct local calendar days [rows] fall on.
  ///
  /// Separate from a plain count because a figure labelled "days" has to
  /// count days: someone with a 06:30 and a 07:00 alarm on the same morning
  /// got up once, not twice, and reading it back to them as two days would
  /// be a small lie in a section whose whole job is being plain.
  static int _distinctLocalDays(Iterable<AlarmOccurrence> rows) {
    final days = <DateTime>{};
    for (final o in rows) {
      final local = o.scheduledAt.toLocal();
      days.add(DateTime(local.year, local.month, local.day));
    }
    return days.length;
  }

  /// The user's usual getting-up time, as local minutes-since-midnight, or
  /// `null` when nothing in the window was dismissed.
  ///
  /// The **median** of the dismissal times, not the mean: one 03:00 airport
  /// alarm should not drag a fortnight of 07:00 mornings down to 06:40. On an
  /// even count it takes the lower of the two middle values rather than
  /// averaging them, which keeps the result a time that actually happened.
  ///
  /// Honest limitation: times are compared as minutes-since-local-midnight,
  /// so a set that straddles midnight (a 23:50 alarm and a 00:10 one) has no
  /// meaningful middle and this returns whichever value sits in the middle of
  /// the sorted day. That is a night-shift edge this figure does not claim to
  /// serve — it is labelled "usual wake", and it is one plain number rather
  /// than an inference about sleep.
  static int? _typicalWakeMinutes(List<AlarmOccurrence> dismissedRows) {
    final minutes = <int>[];
    for (final o in dismissedRows) {
      final at = o.dismissedAt;
      if (at == null) continue;
      final local = at.toLocal();
      minutes.add(local.hour * 60 + local.minute);
    }
    if (minutes.isEmpty) return null;
    minutes.sort();
    return minutes[(minutes.length - 1) ~/ 2];
  }

  /// How the user usually stops their alarm, as one calm classification.
  ///
  /// Feeds the single plain sentence under "Your mornings". It is a
  /// description, never a verdict: there is no "good" bucket and no "bad"
  /// one, which is why the thresholds are coarse — a figure that flips
  /// between sentences at 0.99 and 1.01 snoozes would read as a score.
  static MorningsHabit habitFor(double averageSnoozeCount) {
    if (averageSnoozeCount < 0.5) return MorningsHabit.firstAlarm;
    if (averageSnoozeCount < 1.5) return MorningsHabit.oneSnooze;
    return MorningsHabit.severalSnoozes;
  }

  static int _countWhere(List<AlarmOccurrence> rows, AlarmStatus status) {
    var n = 0;
    for (final o in rows) {
      if (o.status == status) n++;
    }
    return n;
  }

  static List<HistoryDailySummary> _bucketByLocalDate(
    List<AlarmOccurrence> rows,
  ) {
    final buckets = <DateTime, _DailyAccumulator>{};
    for (final o in rows) {
      final local = o.scheduledAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      buckets.putIfAbsent(day, _DailyAccumulator.new).add(o);
    }
    final keys = buckets.keys.toList()..sort();
    return [
      for (final day in keys) buckets[day]!.toSummary(day),
    ];
  }

  static List<HistoryInsight> _buildInsights({
    required List<AlarmOccurrence> window,
    required List<AlarmOccurrence> dismissedRows,
    required double averageSnoozeCount,
    required Map<String, Alarm> alarmById,
  }) {
    final insights = <HistoryInsight>[];

    // Average-snooze insight — only when we have enough dismissed
    // occurrences to actually claim a pattern.
    if (dismissedRows.length >= minOccurrencesForAverageInsight) {
      final rounded = averageSnoozeCount.round();
      insights.add(
        HistoryInsight(
          kind: HistoryInsightKind.averageSnooze,
          intArg: rounded,
        ),
      );
    }

    // Weekday-skip insight — find the ISO weekday with the most skips,
    // require at least `minSkipsForWeekdayInsight` skips on it.
    final skipsByWeekday = <int, int>{};
    for (final o in window) {
      if (o.status != AlarmStatus.skipped) continue;
      final iso = o.scheduledAt.toLocal().weekday; // Mon=1..Sun=7
      skipsByWeekday[iso] = (skipsByWeekday[iso] ?? 0) + 1;
    }
    if (skipsByWeekday.isNotEmpty) {
      final sorted = skipsByWeekday.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.compareTo(a.value);
          if (byCount != 0) return byCount;
          return a.key.compareTo(b.key); // stable: earliest ISO weekday first
        });
      final top = sorted.first;
      if (top.value >= minSkipsForWeekdayInsight) {
        insights.add(
          HistoryInsight(
            kind: HistoryInsightKind.frequentlySkippedWeekday,
            intArg: top.key,
          ),
        );
      }
    }

    // Strict-mode-helped insight — count dismissed occurrences whose parent
    // alarm is in Strict mode and where the user did not snooze.
    var strictHelped = 0;
    for (final o in dismissedRows) {
      if (o.snoozeCount > 0) continue;
      final alarm = alarmById[o.alarmId];
      if (alarm == null) continue;
      if (alarm.wakeMode == WakeMode.strict) strictHelped++;
    }
    if (strictHelped >= minStrictHelpedDismissals) {
      insights.add(
        HistoryInsight(
          kind: HistoryInsightKind.strictModeHelped,
          intArg: strictHelped,
        ),
      );
    }

    return insights;
  }
}

class _DailyAccumulator {
  int triggered = 0;
  int snoozed = 0;
  int dismissed = 0;
  int onTime = 0;
  int late = 0;
  int skipped = 0;
  int escaped = 0;
  int missed = 0;
  int totalSnoozes = 0;

  /// Minutes-since-local-midnight of the first alarm this day was set for,
  /// and of the last time one was actually stopped. Both are recorded facts
  /// read straight off the occurrence — nothing here is inferred or averaged.
  int? alarmMinutes;
  int? dismissMinutes;

  static int _localMinutes(DateTime instant) {
    final local = instant.toLocal();
    return local.hour * 60 + local.minute;
  }

  void add(AlarmOccurrence o) {
    switch (o.status) {
      case AlarmStatus.scheduled:
        // Pre-fire — does not count toward history.
        break;
      case AlarmStatus.triggered:
        triggered++;
      case AlarmStatus.snoozed:
        snoozed++;
      case AlarmStatus.dismissed:
        dismissed++;
        if (o.snoozeCount == 0) {
          onTime++;
        } else {
          late++;
        }
      case AlarmStatus.skipped:
        skipped++;
      case AlarmStatus.escaped:
        escaped++;
      case AlarmStatus.missed:
        missed++;
    }
    totalSnoozes += o.snoozeCount;

    // A morning that has not happened yet has no alarm time to look back on,
    // so a still-scheduled row contributes no time.
    if (o.status == AlarmStatus.scheduled) return;

    // The earliest alarm of the day, and the latest moment one was stopped.
    // Earliest for the alarm because that is where the morning started;
    // latest for the dismissal because that is when the user was finally up.
    final scheduled = _localMinutes(o.scheduledAt);
    if (alarmMinutes == null || scheduled < alarmMinutes!) {
      alarmMinutes = scheduled;
    }
    if (o.dismissedAt case final at?) {
      final stopped = _localMinutes(at);
      if (dismissMinutes == null || stopped > dismissMinutes!) {
        dismissMinutes = stopped;
      }
    }
  }

  HistoryDailySummary toSummary(DateTime day) {
    return HistoryDailySummary(
      day: day,
      triggeredCount: triggered,
      snoozedCount: snoozed,
      dismissedCount: dismissed,
      onTimeCount: onTime,
      lateCount: late,
      skippedCount: skipped,
      escapedCount: escaped,
      missedCount: missed,
      totalSnoozes: totalSnoozes,
      alarmMinutes: alarmMinutes,
      dismissMinutes: dismissMinutes,
    );
  }
}

/// A single day's worth of aggregated history — used by the screen to
/// render a small per-day breakdown.
@immutable
class HistoryDailySummary {
  const HistoryDailySummary({
    required this.day,
    required this.triggeredCount,
    required this.snoozedCount,
    required this.dismissedCount,
    required this.onTimeCount,
    required this.lateCount,
    required this.skippedCount,
    required this.escapedCount,
    required this.missedCount,
    required this.totalSnoozes,
    this.alarmMinutes,
    this.dismissMinutes,
  });

  /// Local-midnight date this bucket represents.
  final DateTime day;

  final int triggeredCount;
  final int snoozedCount;
  final int dismissedCount;

  /// Dismissed occurrences on this day with zero snoozes.
  final int onTimeCount;

  /// Dismissed occurrences on this day with at least one snooze.
  final int lateCount;
  final int skippedCount;

  /// Occurrences stopped with the wake puzzle's emergency escape.
  final int escapedCount;
  final int missedCount;

  /// Sum of `snoozeCount` across every occurrence that fell on this day.
  final int totalSnoozes;

  /// The earliest alarm this day was set for, as minutes since local
  /// midnight. `null` when nothing on this day has fired yet.
  ///
  /// Recorded, not inferred: it is read off the occurrence's own
  /// `scheduledAt`, which is fixed for the life of the row.
  final int? alarmMinutes;

  /// The latest moment an alarm was actually stopped on this day, as minutes
  /// since local midnight. `null` when nothing was stopped — a morning that
  /// was skipped, missed, or is still ringing has no dismissal to show.
  final int? dismissMinutes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryDailySummary &&
        other.day == day &&
        other.alarmMinutes == alarmMinutes &&
        other.dismissMinutes == dismissMinutes &&
        other.triggeredCount == triggeredCount &&
        other.snoozedCount == snoozedCount &&
        other.dismissedCount == dismissedCount &&
        other.onTimeCount == onTimeCount &&
        other.lateCount == lateCount &&
        other.skippedCount == skippedCount &&
        other.escapedCount == escapedCount &&
        other.missedCount == missedCount &&
        other.totalSnoozes == totalSnoozes;
  }

  @override
  int get hashCode => Object.hash(
    day,
    alarmMinutes,
    dismissMinutes,
    triggeredCount,
    snoozedCount,
    dismissedCount,
    onTimeCount,
    lateCount,
    skippedCount,
    escapedCount,
    missedCount,
    totalSnoozes,
  );
}

/// Aggregated history result returned by [HistoryService.summarise].
///
/// Calm and structural — the UI layer turns this into ARB-localised copy.
@immutable
class HistorySummary {
  const HistorySummary({
    required this.windowDays,
    required this.occurrenceCount,
    required this.triggeredCount,
    required this.snoozedCount,
    required this.dismissedCount,
    required this.skippedCount,
    required this.escapedCount,
    required this.missedCount,
    required this.onTimeCount,
    required this.lateCount,
    required this.averageSnoozeCount,
    required this.daily,
    required this.insights,
    this.onTimeDayCount = 0,
    this.typicalWakeMinutes,
  });

  /// The empty summary used while the data is loading.
  static const HistorySummary empty = HistorySummary(
    windowDays: HistoryService.defaultWindowDays,
    occurrenceCount: 0,
    triggeredCount: 0,
    snoozedCount: 0,
    dismissedCount: 0,
    skippedCount: 0,
    escapedCount: 0,
    missedCount: 0,
    onTimeCount: 0,
    lateCount: 0,
    averageSnoozeCount: 0,
    daily: [],
    insights: [],
  );

  /// Look-back window used to compute the summary, in days.
  final int windowDays;

  /// How many occurrences fell inside the window.
  final int occurrenceCount;

  final int triggeredCount;
  final int snoozedCount;
  final int dismissedCount;
  final int skippedCount;

  /// Occurrences stopped with the wake puzzle's emergency escape. Its own
  /// plain outcome — never folded into [dismissedCount], never a failure.
  final int escapedCount;
  final int missedCount;

  /// Dismissed occurrences with zero snoozes.
  final int onTimeCount;

  /// How many distinct local calendar days had an on-time dismissal.
  ///
  /// [onTimeCount] counts occurrences; this counts mornings. Two alarms on
  /// one morning are one day, which is what a figure labelled "days up on
  /// time" has to mean.
  final int onTimeDayCount;

  /// Dismissed occurrences where the user snoozed at least once.
  final int lateCount;

  /// Average `snoozeCount` across dismissed occurrences (0 when there are
  /// no dismissed occurrences in the window).
  final double averageSnoozeCount;

  /// The usual getting-up time as local minutes-since-midnight, or `null`
  /// when nothing in the window was dismissed. See
  /// `HistoryService._typicalWakeMinutes` for why it is a median.
  final int? typicalWakeMinutes;

  /// Per-day summaries, sorted oldest first.
  final List<HistoryDailySummary> daily;

  /// Calm, neutral insight strings the UI renders. Empty list = nothing
  /// to say (the kindest default; we never invent insights).
  final List<HistoryInsight> insights;

  /// Whether the window is empty — convenience for the UI.
  bool get isEmpty => occurrenceCount == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistorySummary &&
        other.windowDays == windowDays &&
        other.occurrenceCount == occurrenceCount &&
        other.triggeredCount == triggeredCount &&
        other.snoozedCount == snoozedCount &&
        other.dismissedCount == dismissedCount &&
        other.skippedCount == skippedCount &&
        other.escapedCount == escapedCount &&
        other.missedCount == missedCount &&
        other.onTimeCount == onTimeCount &&
        other.onTimeDayCount == onTimeDayCount &&
        other.lateCount == lateCount &&
        other.averageSnoozeCount == averageSnoozeCount &&
        other.typicalWakeMinutes == typicalWakeMinutes &&
        _listEquals(other.daily, daily) &&
        _listEquals(other.insights, insights);
  }

  @override
  int get hashCode => Object.hashAll([
    windowDays,
    occurrenceCount,
    triggeredCount,
    snoozedCount,
    dismissedCount,
    skippedCount,
    escapedCount,
    missedCount,
    onTimeCount,
    onTimeDayCount,
    lateCount,
    averageSnoozeCount,
    typicalWakeMinutes,
    Object.hashAll(daily),
    Object.hashAll(insights),
  ]);
}

/// How the user usually stops their alarm — the classification behind the one
/// plain sentence under "Your mornings" in Settings.
///
/// Three buckets, no ranking. Snoozing is a way of waking up, not a failure to
/// wake up, and the copy each of these maps to says so.
enum MorningsHabit {
  /// Usually up on the first alarm.
  firstAlarm,

  /// Usually up after a single snooze.
  oneSnooze,

  /// Usually up after a few snoozes.
  severalSnoozes,
}

/// Kind tag for a [HistoryInsight]. The UI maps this to an ARB key. New
/// kinds should land here so the gate (and the locales) can grow together.
enum HistoryInsightKind {
  /// "You usually dismiss after about N snoozes." — `intArg` = rounded
  /// average snooze count.
  averageSnooze,

  /// "You often skip Monday alarms." — `intArg` = ISO weekday (1..7).
  frequentlySkippedWeekday,

  /// "Strict mode helped on N mornings." — `intArg` = strict-mode
  /// dismissals with zero snoozes in the window.
  strictModeHelped,
}

/// A single calm, neutral insight produced by the service.
@immutable
class HistoryInsight {
  const HistoryInsight({
    required this.kind,
    required this.intArg,
  });

  /// What kind of insight this is — UI maps to localised copy.
  final HistoryInsightKind kind;

  /// Single integer argument used by the localised template (e.g. snooze
  /// count, ISO weekday). Always non-negative.
  final int intArg;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryInsight &&
        other.kind == kind &&
        other.intArg == intArg;
  }

  @override
  int get hashCode => Object.hash(kind, intArg);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

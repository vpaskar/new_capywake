import 'package:capywake/core/sleep/sleep_night.dart';
import 'package:capywake/core/sleep/sleep_segment.dart';
import 'package:capywake/core/sleep/sleep_stage.dart';

/// Pure aggregator: raw health-store segments → one [SleepNight] per morning.
///
/// Flutter-free and deterministic, so every edge case below is a unit test.
///
/// **Night attribution.** A night belongs to the local date the sleeper *woke
/// on*, so 23:40→07:10 is the 15th's night, not the 14th's. This matches how
/// `HistoryService` buckets occurrences by the local date of `scheduledAt`, so
/// a night and the alarm that ended it land on the same History row.
///
/// **Overlap.** Two devices recording the same hour (a watch and a phone) must
/// not produce fourteen hours of sleep. Asleep time is therefore measured as
/// the **union of covered instants**, not the sum of segment durations. The
/// per-stage breakdown is summed per stage after merging that stage's own
/// overlaps, which is why stage minutes may still not add up to the total —
/// see [SleepNight.totalAsleepMinutes].
///
/// **Gaps.** Waking at 03:00 for twenty minutes leaves a hole. The hole is
/// excluded from asleep time but does not split the night: a night is one row
/// per morning, and a short waking mid-night is normal sleep, not two nights.
///
/// **Night splitting.** A genuinely separate sleep — an afternoon nap, or a
/// night either side of a long awake stretch — is split off when the gap
/// between asleep segments reaches [nightSplitGap]. Without this, a nap at
/// 14:00 would be welded onto the following night and report a 20-hour sleep.
abstract final class SleepAggregator {
  /// A gap at or beyond this length starts a new night.
  ///
  /// Three hours: long enough to keep an ordinary 03:00 waking (minutes, or
  /// an hour of insomnia) inside one night, short enough that an afternoon nap
  /// never merges with the night that follows it.
  static const Duration nightSplitGap = Duration(hours: 3);

  /// Aggregate [segments] into nights, oldest first.
  ///
  /// Input order does not matter. Sub-minute and zero-length segments are
  /// dropped. Returns an empty list for empty input — a user with no wearable
  /// is the normal case, not an error.
  static List<SleepNight> aggregate(List<SleepSegment> segments) {
    final usable = segments.where((s) => s.end.isAfter(s.start)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    if (usable.isEmpty) return const [];

    final groups = _splitIntoNights(usable);

    final nights = <SleepNight>[];
    for (final group in groups) {
      final night = _buildNight(group);
      if (night != null) nights.add(night);
    }
    nights.sort((a, b) => a.night.compareTo(b.night));
    return List.unmodifiable(nights);
  }

  /// Group chronologically, breaking when asleep coverage pauses for
  /// [nightSplitGap] or more.
  ///
  /// Only asleep segments drive the split: a long in-bed-awake stretch while
  /// reading in bed should not cut the night in two.
  static List<List<SleepSegment>> _splitIntoNights(
    List<SleepSegment> sorted,
  ) {
    final groups = <List<SleepSegment>>[];
    var current = <SleepSegment>[];

    // End of the last asleep stretch, and end of the last stretch of *any*
    // kind. The gap is measured from whichever is later: an in-bed or awake
    // row bridging two sleeps is evidence the sleeper never left bed, so a
    // disturbed night stays one night even when the sleeps are hours apart.
    DateTime? lastAsleepEnd;
    DateTime? lastCoveredEnd;

    void extend(DateTime candidate, {required bool asleep}) {
      final asleepEnd = lastAsleepEnd;
      if (asleep && (asleepEnd == null || candidate.isAfter(asleepEnd))) {
        lastAsleepEnd = candidate;
      }
      final coveredEnd = lastCoveredEnd;
      if (coveredEnd == null || candidate.isAfter(coveredEnd)) {
        lastCoveredEnd = candidate;
      }
    }

    for (final segment in sorted) {
      final asleep = segment.stage.isAsleep;

      if (current.isEmpty) {
        current.add(segment);
        extend(segment.end, asleep: asleep);
        continue;
      }

      final asleepEnd = lastAsleepEnd;
      final coveredEnd = lastCoveredEnd;
      if (asleep && asleepEnd != null) {
        final anchor = coveredEnd != null && coveredEnd.isAfter(asleepEnd)
            ? coveredEnd
            : asleepEnd;
        final gap = segment.start.difference(anchor);
        if (gap >= nightSplitGap) {
          groups.add(current);
          current = <SleepSegment>[segment];
          lastAsleepEnd = segment.end;
          lastCoveredEnd = segment.end;
          continue;
        }
      }

      current.add(segment);
      extend(segment.end, asleep: asleep);
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  /// Build one night, or null when the group holds no asleep time at all
  /// (an in-bed-only recording is not a night of sleep).
  static SleepNight? _buildNight(List<SleepSegment> group) {
    final asleep = group.where((s) => s.stage.isAsleep).toList();
    if (asleep.isEmpty) return null;

    final asleepIntervals = _merge(asleep);
    if (asleepIntervals.isEmpty) return null;

    final asleepAt = asleepIntervals.first.start;
    final wokeAt = asleepIntervals.last.end;
    final totalAsleepMinutes = _totalMinutes(asleepIntervals);
    if (totalAsleepMinutes <= 0) return null;

    // In-bed spans the whole recording where the device reported in-bed or
    // awake rows; with none, it equals asleep time rather than inventing
    // bedtime we were not told about.
    final inBedIntervals = _merge(group);
    final timeInBedMinutes = group.any((s) => !s.stage.isAsleep)
        ? _totalMinutes(inBedIntervals)
        : totalAsleepMinutes;

    final stageMinutes = <SleepStage, int>{};
    for (final stage in SleepStage.values) {
      final forStage = group.where((s) => s.stage == stage).toList();
      if (forStage.isEmpty) continue;
      final minutes = _totalMinutes(_merge(forStage));
      if (minutes > 0) stageMinutes[stage] = minutes;
    }

    final local = wokeAt.toLocal();

    return SleepNight(
      night: DateTime(local.year, local.month, local.day),
      asleepAt: asleepAt,
      wokeAt: wokeAt,
      totalAsleepMinutes: totalAsleepMinutes,
      timeInBedMinutes: timeInBedMinutes < totalAsleepMinutes
          ? totalAsleepMinutes
          : timeInBedMinutes,
      stageMinutes: stageMinutes,
      sourceName: _dominantSource(asleep),
    );
  }

  /// Merge overlapping and touching intervals, so a doubly-recorded hour is
  /// counted once. Input need not be sorted.
  static List<DateTimeRange> _merge(List<SleepSegment> segments) {
    final sorted = segments.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final merged = <DateTimeRange>[];
    for (final segment in sorted) {
      if (merged.isEmpty) {
        merged.add(DateTimeRange(segment.start, segment.end));
        continue;
      }
      final last = merged.last;
      if (!segment.start.isAfter(last.end)) {
        if (segment.end.isAfter(last.end)) {
          merged[merged.length - 1] = DateTimeRange(last.start, segment.end);
        }
      } else {
        merged.add(DateTimeRange(segment.start, segment.end));
      }
    }
    return merged;
  }

  static int _totalMinutes(List<DateTimeRange> ranges) {
    var seconds = 0;
    for (final range in ranges) {
      seconds += range.end.difference(range.start).inSeconds;
    }
    return seconds ~/ 60;
  }

  /// The source covering the most asleep time, so attribution names the device
  /// that actually recorded the night when a phone contributed a stray row.
  static String _dominantSource(List<SleepSegment> asleep) {
    final bySource = <String, int>{};
    for (final segment in asleep) {
      bySource.update(
        segment.sourceName,
        (v) => v + segment.durationMinutes,
        ifAbsent: () => segment.durationMinutes,
      );
    }
    final ranked = bySource.entries.toList()
      ..sort((a, b) {
        final byMinutes = b.value.compareTo(a.value);
        return byMinutes != 0 ? byMinutes : a.key.compareTo(b.key);
      });
    return ranked.first.key;
  }
}

/// Minimal half-open interval. Local to the aggregator so `lib/core/` stays
/// Flutter-free — Flutter's own `DateTimeRange` lives in the widgets layer.
class DateTimeRange {
  const DateTimeRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

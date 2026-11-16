import 'package:capywake/core/sleep/sleep.dart';
import 'package:flutter_test/flutter_test.dart';

/// A UTC instant from local wall-clock parts, so a test reads as the night it
/// describes while the segments stay UTC like the gateway produces them.
DateTime _local(
  int year,
  int month,
  int day, [
  int hour = 0,
  int minute = 0,
]) => DateTime(year, month, day, hour, minute).toUtc();

SleepSegment _seg(
  DateTime start,
  DateTime end, {
  SleepStage stage = SleepStage.asleep,
  String source = 'Watch',
}) => SleepSegment(
  start: start,
  end: end,
  stage: stage,
  sourceName: source,
);

void main() {
  group('SleepAggregator.aggregate', () {
    test('an empty input produces no nights', () {
      expect(SleepAggregator.aggregate(const []), isEmpty);
    });

    test('a zero-length segment is dropped rather than counted', () {
      final at = _local(2026, 3, 10, 2);
      expect(SleepAggregator.aggregate([_seg(at, at)]), isEmpty);
    });

    test('an in-bed-only recording is not a night of sleep', () {
      final nights = SleepAggregator.aggregate([
        _seg(
          _local(2026, 3, 9, 23),
          _local(2026, 3, 10, 7),
          stage: SleepStage.inBed,
        ),
      ]);
      expect(nights, isEmpty);
    });

    test('a simple night is attributed to the morning it ends on', () {
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23, 40), _local(2026, 3, 10, 7, 10)),
      ]);

      expect(nights, hasLength(1));
      final night = nights.single;
      // Crossed midnight: the night of the 9th→10th belongs to the 10th.
      expect(night.night, DateTime(2026, 3, 10));
      expect(night.totalAsleepMinutes, 450);
      expect(night.asleepAt, _local(2026, 3, 9, 23, 40));
      expect(night.wokeAt, _local(2026, 3, 10, 7, 10));
      expect(night.sourceName, 'Watch');
    });

    test('input order does not matter', () {
      final later = _seg(_local(2026, 3, 10, 3), _local(2026, 3, 10, 7));
      final earlier = _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 3));

      final fromReversed = SleepAggregator.aggregate([later, earlier]);
      final fromOrdered = SleepAggregator.aggregate([earlier, later]);

      expect(fromReversed, hasLength(1));
      expect(
        fromReversed.single.totalAsleepMinutes,
        fromOrdered.single.totalAsleepMinutes,
      );
      expect(fromReversed.single.totalAsleepMinutes, 480);
    });

    test('two devices recording the same hour do not double-count it', () {
      // A watch and a phone both report 23:00→07:00. Summing durations would
      // claim sixteen hours; the union is eight.
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
        _seg(
          _local(2026, 3, 9, 23),
          _local(2026, 3, 10, 7),
          source: 'Phone',
        ),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.totalAsleepMinutes, 480);
    });

    test('partially overlapping segments merge into their union', () {
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 3)),
        _seg(_local(2026, 3, 10, 2), _local(2026, 3, 10, 6)),
      ]);

      expect(nights.single.totalAsleepMinutes, 420);
    });

    test('a short waking leaves a gap but does not split the night', () {
      // Woke at 03:00 for twenty minutes: 4h + 3h40m asleep, one night.
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 3)),
        _seg(
          _local(2026, 3, 10, 3),
          _local(2026, 3, 10, 3, 20),
          stage: SleepStage.awake,
        ),
        _seg(_local(2026, 3, 10, 3, 20), _local(2026, 3, 10, 7)),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.totalAsleepMinutes, 460);
      // The gap is excluded from asleep time but counted as time in bed.
      expect(nights.single.timeInBedMinutes, 480);
    });

    test('an afternoon nap is a separate night from the following night', () {
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 10, 14), _local(2026, 3, 10, 15)),
        _seg(_local(2026, 3, 10, 23), _local(2026, 3, 11, 7)),
      ]);

      expect(nights, hasLength(2));
      expect(nights.first.night, DateTime(2026, 3, 10));
      expect(nights.first.totalAsleepMinutes, 60);
      expect(nights.last.night, DateTime(2026, 3, 11));
      expect(nights.last.totalAsleepMinutes, 480);
    });

    test('a gap shorter than the split threshold stays one night', () {
      final gap = SleepAggregator.nightSplitGap - const Duration(minutes: 1);
      final firstEnd = _local(2026, 3, 10, 1);
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23), firstEnd),
        _seg(firstEnd.add(gap), firstEnd.add(gap + const Duration(hours: 2))),
      ]);

      expect(nights, hasLength(1));
    });

    test('a gap at exactly the split threshold starts a new night', () {
      final firstEnd = _local(2026, 3, 10, 1);
      final secondStart = firstEnd.add(SleepAggregator.nightSplitGap);
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23), firstEnd),
        _seg(secondStart, secondStart.add(const Duration(hours: 2))),
      ]);

      expect(nights, hasLength(2));
    });

    test('a long in-bed-awake stretch does not split the night', () {
      // Reading in bed for four hours between two sleeps: only asleep
      // coverage drives the split, so this stays one night.
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 21), _local(2026, 3, 9, 22)),
        _seg(
          _local(2026, 3, 9, 22),
          _local(2026, 3, 10, 2),
          stage: SleepStage.inBed,
        ),
        _seg(_local(2026, 3, 10, 2), _local(2026, 3, 10, 7)),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.totalAsleepMinutes, 360);
    });

    test('nights come back oldest first', () {
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 12, 23), _local(2026, 3, 13, 7)),
        _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
        _seg(_local(2026, 3, 10, 23), _local(2026, 3, 11, 7)),
      ]);

      expect(
        nights.map((n) => n.night),
        [DateTime(2026, 3, 10), DateTime(2026, 3, 11), DateTime(2026, 3, 13)],
      );
    });

    group('stage breakdown', () {
      test('stages are summed per stage and kept separate from the total', () {
        // Deliberately inconsistent, as real data is: the asleep row says 8h
        // while the phases add to 7h. The total must follow the platform.
        final nights = SleepAggregator.aggregate([
          _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
          _seg(
            _local(2026, 3, 9, 23),
            _local(2026, 3, 10, 1),
            stage: SleepStage.deep,
          ),
          _seg(
            _local(2026, 3, 10, 1),
            _local(2026, 3, 10, 5),
            stage: SleepStage.light,
          ),
          _seg(
            _local(2026, 3, 10, 5),
            _local(2026, 3, 10, 6),
            stage: SleepStage.rem,
          ),
        ]);

        final night = nights.single;
        expect(night.totalAsleepMinutes, 480);
        expect(night.minutesFor(SleepStage.deep), 120);
        expect(night.minutesFor(SleepStage.light), 240);
        expect(night.minutesFor(SleepStage.rem), 60);
        // 120 + 240 + 60 = 420, not the 480 total. Both are reported as-is.
        expect(night.hasPhaseBreakdown, isTrue);
      });

      test('a recording with no phases reports no breakdown', () {
        final nights = SleepAggregator.aggregate([
          _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
        ]);

        expect(nights.single.hasPhaseBreakdown, isFalse);
        expect(nights.single.minutesFor(SleepStage.deep), 0);
      });

      test('an unknown stage is kept so a total is never silently short', () {
        final nights = SleepAggregator.aggregate([
          _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
          _seg(
            _local(2026, 3, 10, 1),
            _local(2026, 3, 10, 2),
            stage: SleepStage.unknown,
          ),
        ]);

        expect(nights.single.minutesFor(SleepStage.unknown), 60);
        // unknown is not a phase, so it does not create a breakdown.
        expect(nights.single.hasPhaseBreakdown, isFalse);
      });
    });

    group('source attribution', () {
      test('the device covering the most asleep time wins', () {
        final nights = SleepAggregator.aggregate([
          _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
          _seg(
            _local(2026, 3, 10, 6, 30),
            _local(2026, 3, 10, 7),
            source: 'Phone',
          ),
        ]);

        expect(nights.single.sourceName, 'Watch');
      });

      test('a tie is broken by name, so attribution is deterministic', () {
        final nights = SleepAggregator.aggregate([
          _seg(
            _local(2026, 3, 9, 23),
            _local(2026, 3, 10, 3),
            source: 'Zeta',
          ),
          _seg(
            _local(2026, 3, 10, 3),
            _local(2026, 3, 10, 7),
            source: 'Alpha',
          ),
        ]);

        expect(nights.single.sourceName, 'Alpha');
      });
    });

    group('timezone and DST', () {
      test('spring-forward keeps real elapsed time, not wall-clock time', () {
        // Elapsed time is measured in UTC, so a skipped local hour cannot
        // inflate or deflate the night. 23:00 + 7h is 7h of sleep whatever
        // the local clock did in between.
        final start = _local(2026, 3, 28, 23);
        final nights = SleepAggregator.aggregate([
          _seg(start, start.add(const Duration(hours: 7))),
        ]);

        expect(nights.single.totalAsleepMinutes, 420);
      });

      test('fall-back keeps real elapsed time too', () {
        final start = _local(2026, 10, 24, 23);
        final nights = SleepAggregator.aggregate([
          _seg(start, start.add(const Duration(hours: 9))),
        ]);

        expect(nights.single.totalAsleepMinutes, 540);
      });

      test('a night is keyed by the local date of waking', () {
        final nights = SleepAggregator.aggregate([
          _seg(_local(2026, 2, 28, 23), _local(2026, 3, 1, 7)),
        ]);

        final night = nights.single;
        final localWake = night.wokeAt.toLocal();
        expect(
          night.night,
          DateTime(localWake.year, localWake.month, localWake.day),
        );
      });

      test('a leap day is handled like any other date', () {
        final nights = SleepAggregator.aggregate([
          _seg(_local(2028, 2, 28, 23), _local(2028, 2, 29, 7)),
        ]);

        expect(nights.single.night, DateTime(2028, 2, 29));
        expect(nights.single.totalAsleepMinutes, 480);
      });
    });

    test('time in bed is never reported below time asleep', () {
      // An awake row that sits entirely inside the asleep span would make the
      // naive union smaller than the asleep total; the result is clamped.
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
        _seg(
          _local(2026, 3, 10, 1),
          _local(2026, 3, 10, 2),
          stage: SleepStage.awake,
        ),
      ]);

      final night = nights.single;
      expect(
        night.timeInBedMinutes,
        greaterThanOrEqualTo(
          night.totalAsleepMinutes,
        ),
      );
    });

    test('the returned list is unmodifiable', () {
      final nights = SleepAggregator.aggregate([
        _seg(_local(2026, 3, 9, 23), _local(2026, 3, 10, 7)),
      ]);

      expect(() => nights.add(nights.first), throwsUnsupportedError);
    });
  });
}

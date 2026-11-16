import 'package:capywake/core/time_stepper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Readability helper: 07:23 as minutes-since-midnight.
int at(int hour, int minute) => hour * 60 + minute;

void main() {
  group('TimeStepper.stepHours', () {
    test('adds and subtracts a whole hour, keeping the minutes', () {
      expect(TimeStepper.stepHours(at(7, 23), delta: 1), at(8, 23));
      expect(TimeStepper.stepHours(at(7, 23), delta: -1), at(6, 23));
    });

    test('wraps forward past midnight', () {
      expect(TimeStepper.stepHours(at(23, 0), delta: 1), at(0, 0));
      expect(TimeStepper.stepHours(at(23, 45), delta: 1), at(0, 45));
    });

    test('wraps backward past midnight', () {
      // The phase's stated boundary case: 00:00 an hour earlier is 23:00,
      // not a control stuck at the bottom of the day.
      expect(TimeStepper.stepHours(at(0, 0), delta: -1), at(23, 0));
      expect(TimeStepper.stepHours(at(0, 30), delta: -1), at(23, 30));
    });

    test('handles multi-hour steps in both directions', () {
      expect(TimeStepper.stepHours(at(1, 0), delta: -3), at(22, 0));
      expect(TimeStepper.stepHours(at(22, 0), delta: 5), at(3, 0));
    });

    test('a delta of zero is the identity', () {
      expect(TimeStepper.stepHours(at(7, 23), delta: 0), at(7, 23));
    });

    test('twenty-four steps return to the same time', () {
      expect(TimeStepper.stepHours(at(6, 15), delta: 24), at(6, 15));
      expect(TimeStepper.stepHours(at(6, 15), delta: -24), at(6, 15));
    });

    test('every minute of the day round-trips up then down', () {
      for (var m = 0; m < TimeStepper.minutesPerDay; m++) {
        final there = TimeStepper.stepHours(m, delta: 1);
        expect(TimeStepper.stepHours(there, delta: -1), m, reason: 'from $m');
      }
    });
  });

  group('TimeStepper.stepFiveMinutes', () {
    test('moves by five from a value already on a mark', () {
      expect(TimeStepper.stepFiveMinutes(at(7, 20), delta: 1), at(7, 25));
      expect(TimeStepper.stepFiveMinutes(at(7, 20), delta: -1), at(7, 15));
    });

    test('snaps an off-grid value onto the nearest mark in the direction '
        'travelled', () {
      // This is the behaviour that makes the control worth having: a time
      // that arrived from the platform picker at 07:23 is pulled onto the
      // five-minute grid by the first tap rather than carrying the stray
      // three minutes for the rest of its life.
      expect(TimeStepper.stepFiveMinutes(at(7, 23), delta: 1), at(7, 25));
      expect(TimeStepper.stepFiveMinutes(at(7, 23), delta: -1), at(7, 20));
      expect(TimeStepper.stepFiveMinutes(at(7, 21), delta: -1), at(7, 20));
      expect(TimeStepper.stepFiveMinutes(at(7, 24), delta: 1), at(7, 25));
    });

    test('crosses the hour boundary', () {
      expect(TimeStepper.stepFiveMinutes(at(7, 55), delta: 1), at(8, 0));
      expect(TimeStepper.stepFiveMinutes(at(8, 0), delta: -1), at(7, 55));
    });

    test('wraps forward past midnight', () {
      // The phase's stated boundary case.
      expect(TimeStepper.stepFiveMinutes(at(23, 55), delta: 1), at(0, 0));
      expect(TimeStepper.stepFiveMinutes(at(23, 58), delta: 1), at(0, 0));
    });

    test('wraps backward past midnight', () {
      expect(TimeStepper.stepFiveMinutes(at(0, 0), delta: -1), at(23, 55));
      expect(TimeStepper.stepFiveMinutes(at(0, 3), delta: -1), at(0, 0));
    });

    test('handles multi-step deltas', () {
      expect(TimeStepper.stepFiveMinutes(at(6, 0), delta: 3), at(6, 15));
      expect(TimeStepper.stepFiveMinutes(at(6, 0), delta: -3), at(5, 45));
      expect(TimeStepper.stepFiveMinutes(at(23, 50), delta: 3), at(0, 5));
      expect(TimeStepper.stepFiveMinutes(at(0, 5), delta: -3), at(23, 50));
    });

    test('a delta of zero is the identity, on or off the grid', () {
      expect(TimeStepper.stepFiveMinutes(at(7, 20), delta: 0), at(7, 20));
      expect(TimeStepper.stepFiveMinutes(at(7, 23), delta: 0), at(7, 23));
    });

    test('a full day of steps returns to the same mark', () {
      const stepsPerDay = TimeStepper.minutesPerDay ~/ TimeStepper.stepMinutes;
      expect(
        TimeStepper.stepFiveMinutes(at(6, 30), delta: stepsPerDay),
        at(6, 30),
      );
      expect(
        TimeStepper.stepFiveMinutes(at(6, 30), delta: -stepsPerDay),
        at(6, 30),
      );
    });

    test('always lands on a five-minute mark, from anywhere in the day', () {
      for (var m = 0; m < TimeStepper.minutesPerDay; m++) {
        final up = TimeStepper.stepFiveMinutes(m, delta: 1);
        final down = TimeStepper.stepFiveMinutes(m, delta: -1);
        expect(up % TimeStepper.stepMinutes, 0, reason: 'up from $m');
        expect(down % TimeStepper.stepMinutes, 0, reason: 'down from $m');
        expect(up, inInclusiveRange(0, TimeStepper.minutesPerDay - 1));
        expect(down, inInclusiveRange(0, TimeStepper.minutesPerDay - 1));
      }
    });

    test('on-grid values round-trip up then down', () {
      for (var m = 0; m < TimeStepper.minutesPerDay; m += 5) {
        final there = TimeStepper.stepFiveMinutes(m, delta: 1);
        expect(
          TimeStepper.stepFiveMinutes(there, delta: -1),
          m,
          reason: 'from $m',
        );
      }
    });
  });
}

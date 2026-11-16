import 'package:capywake/core/motion/motion_check_service.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:flutter_test/flutter_test.dart';

/// A reading whose magnitude sits [deviation] m/s² away from gravity.
MotionSample _sampleOff(double deviation) =>
    MotionSample(x: 0, y: 0, z: MotionCheckService.standardGravity + deviation);

void main() {
  group('MotionCheckService defaults', () {
    test('ships the documented window, bucket and thresholds', () {
      final service = MotionCheckService();
      expect(service.window, const Duration(seconds: 90));
      expect(service.bucket, const Duration(seconds: 1));
      expect(service.movementEpsilon, 1.5);
      expect(service.requiredMovingFraction, 0.5);
    });

    test('divides the shipped window into one bucket per second', () {
      expect(MotionCheckService().bucketCount, 90);
    });

    test('requires a majority of buckets to have moved', () {
      expect(MotionCheckService().requiredMovingBuckets, 45);
    });

    test('rounds a fractional bucket count up', () {
      final service = MotionCheckService(
        window: const Duration(milliseconds: 2500),
      );
      expect(service.bucketCount, 3);
      expect(service.requiredMovingBuckets, 2);
    });

    test('never requires fewer than one moving bucket', () {
      final service = MotionCheckService(
        window: const Duration(seconds: 1),
        requiredMovingFraction: 0.01,
      );
      expect(service.requiredMovingBuckets, 1);
    });

    test('rejects a window, bucket or threshold that cannot work', () {
      expect(
        () => MotionCheckService(window: Duration.zero),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MotionCheckService(bucket: Duration.zero),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MotionCheckService(
          window: const Duration(seconds: 1),
          bucket: const Duration(seconds: 2),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MotionCheckService(movementEpsilon: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MotionCheckService(requiredMovingFraction: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MotionCheckService(requiredMovingFraction: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('MotionCheckService.isMovingSample', () {
    final service = MotionCheckService();

    test('a phone resting at gravity is not moving', () {
      expect(
        service.isMovingSample(
          const MotionSample(
            x: 0,
            y: 0,
            z: MotionCheckService.standardGravity,
          ),
        ),
        isFalse,
      );
    });

    test('ordinary sensor noise is not moving', () {
      expect(service.isMovingSample(_sampleOff(0.05)), isFalse);
      expect(service.isMovingSample(_sampleOff(-0.05)), isFalse);
    });

    test('a reading exactly at the epsilon is not moving', () {
      // Strictly greater, so the threshold itself stays on the quiet side.
      expect(service.isMovingSample(_sampleOff(1.5)), isFalse);
    });

    test('deviation in either direction counts', () {
      expect(service.isMovingSample(_sampleOff(3)), isTrue);
      expect(service.isMovingSample(_sampleOff(-3)), isTrue);
    });

    test('free fall counts as movement', () {
      expect(
        service.isMovingSample(const MotionSample(x: 0, y: 0, z: 0)),
        isTrue,
      );
    });

    test('a narrower epsilon catches smaller movements', () {
      final sensitive = MotionCheckService(movementEpsilon: 0.1);
      expect(sensitive.isMovingSample(_sampleOff(0.2)), isTrue);
    });
  });

  group('MotionCheckService.bucketIndexFor', () {
    final service = MotionCheckService();

    test('maps elapsed time to whole-second buckets', () {
      expect(service.bucketIndexFor(Duration.zero), 0);
      expect(service.bucketIndexFor(const Duration(milliseconds: 999)), 0);
      expect(service.bucketIndexFor(const Duration(seconds: 1)), 1);
      expect(service.bucketIndexFor(const Duration(seconds: 89)), 89);
    });

    test('drops readings from outside the window', () {
      expect(service.bucketIndexFor(const Duration(seconds: 90)), isNull);
      expect(service.bucketIndexFor(const Duration(seconds: 200)), isNull);
      expect(service.bucketIndexFor(const Duration(seconds: -1)), isNull);
    });
  });

  group('MotionCheckService.sawEnoughMotion', () {
    final service = MotionCheckService();

    test('a shake is not enough', () {
      // One second of violent movement marks exactly one bucket. Duration is
      // the anti-cheat, so this must fail.
      expect(service.sawEnoughMotion(1), isFalse);
    });

    test('short bursts short of the majority are not enough', () {
      expect(service.sawEnoughMotion(44), isFalse);
    });

    test('the majority passes, and so does anything above it', () {
      expect(service.sawEnoughMotion(45), isTrue);
      expect(service.sawEnoughMotion(90), isTrue);
    });

    test('nothing at all is never enough', () {
      expect(service.sawEnoughMotion(0), isFalse);
    });
  });

  group('MotionCheckService.isWindowComplete', () {
    final service = MotionCheckService();

    test('is false before the window ends', () {
      expect(service.isWindowComplete(Duration.zero), isFalse);
      expect(
        service.isWindowComplete(
          const Duration(seconds: 89, milliseconds: 999),
        ),
        isFalse,
      );
    });

    test('is true at and after the window end', () {
      expect(service.isWindowComplete(const Duration(seconds: 90)), isTrue);
      expect(service.isWindowComplete(const Duration(seconds: 300)), isTrue);
    });
  });

  group('a whole window, sample by sample', () {
    /// Replays [samples] paced one per bucket and reports how the check would
    /// have resolved — the same arithmetic `RingingController` performs, with
    /// none of its plumbing.
    ({bool passed, bool completed}) replay(
      MotionCheckService service,
      List<MotionSample> samples,
    ) {
      final moving = <int>{};
      for (var i = 0; i < samples.length; i++) {
        final elapsed = service.bucket * i;
        if (service.isMovingSample(samples[i])) {
          final bucket = service.bucketIndexFor(elapsed);
          if (bucket != null) moving.add(bucket);
        }
        if (service.sawEnoughMotion(moving.length)) {
          return (passed: true, completed: false);
        }
        if (service.isWindowComplete(elapsed)) {
          return (passed: false, completed: true);
        }
      }
      return (passed: false, completed: false);
    }

    test('a phone left untouched runs the window out', () {
      final service = MotionCheckService();
      final result = replay(
        service,
        List.filled(91, _sampleOff(0)),
      );
      expect(result.passed, isFalse);
      expect(result.completed, isTrue);
    });

    test('a phone carried around resolves before the window ends', () {
      final service = MotionCheckService();
      final result = replay(
        service,
        List.filled(91, _sampleOff(4)),
      );
      expect(result.passed, isTrue);
      expect(result.completed, isFalse);
    });

    test('a single hard shake does not resolve it', () {
      final service = MotionCheckService();
      final samples = List.filled(91, _sampleOff(0))..[3] = _sampleOff(30);
      final result = replay(service, samples);
      expect(result.passed, isFalse);
      expect(result.completed, isTrue);
    });

    test('movement in fewer than half the seconds does not resolve it', () {
      final service = MotionCheckService();
      final samples = <MotionSample>[
        for (var i = 0; i < 91; i++)
          i.isEven && i < 80 ? _sampleOff(4) : _sampleOff(0),
      ];
      final result = replay(service, samples);
      expect(result.passed, isFalse);
      expect(result.completed, isTrue);
    });
  });
}

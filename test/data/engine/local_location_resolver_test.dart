import 'package:capywake/data/engine/local_location_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('fingerprintOfLocation', () {
    test('probes four instants across the year', () {
      final berlin = tz.getLocation('Europe/Berlin');
      final print = LocalLocationResolver.fingerprintOfLocation(
        berlin,
        DateTime(2026),
      );
      expect(print, hasLength(LocalLocationResolver.probeMonthOffsets.length));
    });

    test('a DST zone does not report one constant offset', () {
      final berlin = tz.getLocation('Europe/Berlin');
      final print = LocalLocationResolver.fingerprintOfLocation(
        berlin,
        DateTime(2026),
      );
      expect(print.toSet().length, greaterThan(1));
    });

    test('a fixed-offset zone reports the same offset throughout', () {
      final print = LocalLocationResolver.fingerprintOfLocation(
        tz.UTC,
        DateTime(2026),
      );
      expect(print.toSet(), {0});
    });

    test('zones sharing a summer offset still differ across the year', () {
      final reference = DateTime(2026);
      final berlin = LocalLocationResolver.fingerprintOfLocation(
        tz.getLocation('Europe/Berlin'),
        reference,
      );
      final moscow = LocalLocationResolver.fingerprintOfLocation(
        tz.getLocation('Europe/Moscow'),
        reference,
      );
      expect(berlin, isNot(moscow));
    });
  });

  group('candidatesFor', () {
    test('ranks a preferred zone ahead of its equals', () {
      final names = LocalLocationResolver.candidatesFor(DateTime(2026));
      expect(names, isNotEmpty);
      final best = names.first;
      final others = names.skip(1);
      for (final other in others) {
        final bestRank = LocalLocationResolver.preferredZones.indexOf(best);
        final otherRank = LocalLocationResolver.preferredZones.indexOf(other);
        if (bestRank == -1 && otherRank != -1) {
          fail('$best ranked ahead of preferred $other');
        }
      }
    });

    test('is deterministic', () {
      final reference = DateTime(2026, 6, 15, 9, 30);
      expect(
        LocalLocationResolver.candidatesFor(reference),
        LocalLocationResolver.candidatesFor(reference),
      );
    });

    test('every candidate really reproduces the device offsets', () {
      final reference = DateTime(2026, 6, 15);
      final target = LocalLocationResolver.fingerprintOf(reference);
      for (final name in LocalLocationResolver.candidatesFor(reference)) {
        expect(
          LocalLocationResolver.fingerprintOfLocation(
            tz.timeZoneDatabase.locations[name]!,
            reference,
          ),
          target,
          reason: '$name was offered but does not match',
        );
      }
    });
  });

  group('resolve', () {
    test('finds a zone for this machine', () {
      expect(LocalLocationResolver.resolve(DateTime(2026)), isNotNull);
    });

    test('the resolved zone matches the device offsets', () {
      final reference = DateTime(2026, 1, 15);
      final location = LocalLocationResolver.resolve(reference);
      expect(
        LocalLocationResolver.fingerprintOfLocation(location!, reference),
        LocalLocationResolver.fingerprintOf(reference),
      );
    });

    test('is stable across calls', () {
      final reference = DateTime(2026, 1, 15);
      expect(
        LocalLocationResolver.resolve(reference)?.name,
        LocalLocationResolver.resolve(reference)?.name,
      );
    });
  });

  group('month shifting', () {
    test('does not overflow a short month', () {
      final print = LocalLocationResolver.fingerprintOfLocation(
        tz.UTC,
        DateTime(2026, 1, 31),
      );
      expect(print, hasLength(4));
    });

    test('crosses a year boundary cleanly', () {
      final print = LocalLocationResolver.fingerprintOfLocation(
        tz.UTC,
        DateTime(2026, 11, 20),
      );
      expect(print, hasLength(4));
    });
  });
}

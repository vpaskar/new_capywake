import 'dart:async';

import 'package:capywake/data/engine/device_zone.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/engine/local_location_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);
  tearDown(() => tz.setLocalLocation(tz.UTC));

  late String? name;
  late StreamController<Object?> changes;
  late DeviceZone zone;

  setUp(() {
    name = 'America/New_York';
    changes = StreamController<Object?>.broadcast();
    zone = DeviceZone(readName: () async => name, changes: changes.stream);
  });
  tearDown(() async {
    await zone.dispose();
    await changes.close();
  });

  test('takes the platform name when the database knows it', () async {
    await zone.start();
    expect(zone.current.name, 'America/New_York');
    expect(tz.local.name, 'America/New_York');
  });

  test('an unknown name falls back to the offset fingerprint', () async {
    name = 'Mars/Olympus_Mons';
    await zone.start();
    expect(zone.current, LocalLocationResolver.resolve(DateTime.now()));
  });

  test('a failing channel falls back too', () async {
    zone = DeviceZone(
      readName: () => Future.error(StateError('no channel')),
      changes: changes.stream,
    );
    await zone.start();
    expect(zone.current, LocalLocationResolver.resolve(DateTime.now()));
  });

  test('refresh reports and publishes only a real move', () async {
    await zone.start();
    final seen = <String>[];
    zone.updates.listen((l) => seen.add(l.name));

    expect(await zone.refresh(), isFalse);
    name = 'Asia/Tokyo';
    expect(await zone.refresh(), isTrue);
    await pumpEventQueue();

    expect(seen, ['Asia/Tokyo']);
    expect(zone.current.name, 'Asia/Tokyo');
    expect(tz.local.name, 'Asia/Tokyo');
  });

  test("the platform's change notice re-reads the zone", () async {
    await zone.start();
    final moved = zone.updates.first;
    name = 'Europe/Berlin';
    changes.add('Europe/Berlin');
    expect((await moved).name, 'Europe/Berlin');
  });

  test('an error on the notice stream is not fatal', () async {
    await zone.start();
    changes.addError(StateError('channel gone'));
    await pumpEventQueue();
    name = 'Europe/Berlin';
    changes.add(null);
    expect((await zone.updates.first).name, 'Europe/Berlin');
  });

  test(
    'a notice naming the new zone wins over a stale platform read',
    () async {
      await zone.start();
      final moved = zone.updates.first;
      changes.add('Asia/Tokyo');
      expect((await moved).name, 'Asia/Tokyo');
    },
  );

  test('an unknown name in the notice falls back to a fresh read', () async {
    await zone.start();
    final moved = zone.updates.first;
    name = 'Europe/Berlin';
    changes.add('Not/AZone');
    expect((await moved).name, 'Europe/Berlin');
  });

  test('the schedule location follows the zone in production wiring', () async {
    await zone.start();
    final container = ProviderContainer(
      overrides: [scheduleLocationFollowing(zone)],
    );
    addTearDown(container.dispose);
    final seen = <String>[];
    container.listen(
      scheduleLocationProvider,
      (_, next) => seen.add(next.name),
      fireImmediately: true,
    );

    name = 'Asia/Tokyo';
    await zone.refresh();
    await pumpEventQueue();

    expect(seen, ['America/New_York', 'Asia/Tokyo']);
  });
}

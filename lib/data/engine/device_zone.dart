import 'dart:async';

import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/engine/local_location_resolver.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:timezone/timezone.dart' as tz;

/// The zone alarms are scheduled in: the device's IANA name when the platform
/// gives one the database knows, else the offset fingerprint, else UTC.
class DeviceZone {
  DeviceZone({
    required Future<String?> Function() readName,
    required Stream<Object?> changes,
    DateTime Function() now = DateTime.now,
  }) : _readName = readName,
       _changes = changes,
       _now = now;

  // Dart cannot pass a private named initializing formal.
  // ignore_for_file: prefer_initializing_formals

  final Future<String?> Function() _readName;
  final Stream<Object?> _changes;
  final DateTime Function() _now;
  final _updates = StreamController<tz.Location>.broadcast();
  StreamSubscription<Object?>? _subscription;
  tz.Location _current = tz.UTC;

  tz.Location get current => _current;

  /// Emits the new zone after every change [refresh] finds.
  Stream<tz.Location> get updates => _updates.stream;

  /// Resolves the zone once and follows the platform's change notice.
  Future<void> start() async {
    _current = await _resolve();
    tz.setLocalLocation(_current);
    _subscription ??= _changes.listen(
      (name) => unawaited(refresh(reported: name is String ? name : null)),
      onError: (Object _) {},
    );
  }

  /// Re-reads the zone, trusting a [reported] name the database knows; true
  /// when it moved.
  Future<bool> refresh({String? reported}) async {
    final known = reported == null
        ? null
        : tz.timeZoneDatabase.locations[reported];
    final next = known ?? await _resolve();
    if (next.name == _current.name) return false;
    _current = next;
    tz.setLocalLocation(next);
    _updates.add(next);
    return true;
  }

  Future<tz.Location> _resolve() async {
    String? name;
    try {
      name = await _readName();
    } on Object {
      name = null;
    }
    final named = name == null ? null : tz.timeZoneDatabase.locations[name];
    return named ?? LocalLocationResolver.resolve(_now()) ?? tz.UTC;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _updates.close();
  }
}

/// `scheduleLocationProvider` following [zone]: rebuilt on every move, so the
/// schedule re-runs in the new zone.
Override scheduleLocationFollowing(DeviceZone zone) =>
    scheduleLocationProvider.overrideWith((ref) {
      final moved = zone.updates.listen((_) => ref.invalidateSelf());
      ref.onDispose(moved.cancel);
      return zone.current;
    });

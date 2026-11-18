import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('the zone channel is registered on both platforms', () {
    expect(
      _read('ios/Runner/AppDelegate.swift'),
      contains('TimeZoneChannel.register(with: registrar)'),
    );
    expect(
      _read(
        'android/app/src/main/kotlin/com/capywake/capywake/MainActivity.kt',
      ),
      contains('TimeZoneChannel(applicationContext)'),
    );
  });

  test('production follows the device zone and localizes the kill notice', () {
    final scope = _read('lib/data/engine/platform_engine_overrides.dart');
    expect(scope, contains('scheduleLocationFollowing(zone)'));
    expect(scope, contains('PlatformZoneChannel.changes'));
    expect(scope, contains('l10n.alarmKillWarningTitle'));
    expect(scope, contains('l10n.alarmKillWarningBody'));
  });
}

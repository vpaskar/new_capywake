import 'dart:io';

import 'package:capywake/core/motion/fake_motion_sensor.dart';
import 'package:capywake/core/motion/motion_sensor.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/motion/platform_motion_sensor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const method = MethodChannel('dev.fluttercommunity.plus/sensors/method');
  const accelerometer = EventChannel(
    'dev.fluttercommunity.plus/sensors/accelerometer',
  );

  test('maps the plugin accelerometer at the game sampling rate', () async {
    final periods = <Object?>[];
    messenger
      ..setMockMethodCallHandler(method, (call) async {
        periods.add(call.arguments);
        return null;
      })
      ..setMockStreamHandler(
        accelerometer,
        MockStreamHandler.inline(
          onListen: (_, sink) => sink.success(<double>[1.5, -2, 9.5, 0]),
        ),
      );
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(method, null)
        ..setMockStreamHandler(accelerometer, null);
    });

    final sensor = PlatformMotionSensor();
    expect(
      await sensor.samples.first,
      const MotionSample(x: 1.5, y: -2, z: 9.5),
    );
    expect(periods, [PlatformMotionSensor.samplingPeriod.inMicroseconds]);
    expect(PlatformMotionSensor.samplingPeriod.inMilliseconds, 20);
    await sensor.dispose();
  });

  test('tests get a silent fake; production swaps in the platform', () {
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);
    expect(defaults.read(motionSensorProvider), isA<FakeMotionSensor>());

    final production = ProviderContainer(overrides: [platformMotionOverride()]);
    addTearDown(production.dispose);
    expect(production.read(motionSensorProvider), isA<PlatformMotionSensor>());
  });

  test('the production scope applies the platform sensor (M4)', () {
    expect(
      File(
        'lib/data/engine/platform_engine_overrides.dart',
      ).readAsStringSync(),
      contains('platformMotionOverride()'),
    );
  });

  test('only the platform adapter imports sensors_plus', () {
    final importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('package:sensors_plus/'))
        .map((f) => f.path)
        .toList();
    expect(importers, ['lib/data/motion/platform_motion_sensor.dart']);
  });

  test('iOS declares why it reads motion, or the plugin crashes', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>NSMotionUsageDescription</key>'));
    expect(
      RegExp(
        r'<key>NSMotionUsageDescription</key>\s*<string>[^<]{20,}</string>',
      ).hasMatch(plist),
      isTrue,
    );
  });
}

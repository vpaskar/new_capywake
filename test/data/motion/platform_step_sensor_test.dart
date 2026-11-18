import 'dart:io';

import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/motion/platform_step_sensor.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
const _activityRecognition = 19;
const _denied = 0;
const _granted = 1;
const _permanentlyDenied = 4;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <String>[];

  void native(Map<String, Object?> answers) {
    messenger.setMockMethodCallHandler(PlatformStepSensor.methods, (
      call,
    ) async {
      calls.add(call.method);
      final answer = answers[call.method];
      if (answer is Exception) throw answer;
      return answer;
    });
  }

  void android({required List<int> statuses}) {
    var next = 0;
    messenger.setMockMethodCallHandler(_permissions, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'checkPermissionStatus':
          expect(call.arguments, _activityRecognition);
          return statuses[next.clamp(0, statuses.length - 1)];
        case 'requestPermissions':
          next++;
          return {_activityRecognition: statuses[next]};
        case 'openAppSettings':
          return true;
      }
      return null;
    });
  }

  setUp(calls.clear);
  tearDown(() {
    messenger
      ..setMockMethodCallHandler(PlatformStepSensor.methods, null)
      ..setMockMethodCallHandler(_permissions, null)
      ..setMockStreamHandler(PlatformStepSensor.events, null);
  });

  final ios = PlatformStepSensor(platform: TargetPlatform.iOS);
  final droid = PlatformStepSensor(platform: TargetPlatform.android);

  group('iOS', () {
    test('no pedometer is unavailable, and nothing else is asked', () async {
      native({'isAvailable': false});
      expect(await ios.access(), StepAccess.unavailable);
      expect(calls, ['isAvailable']);
    });

    test('reads CoreMotion authorization', () async {
      native({'isAvailable': true, 'authorization': 'authorized'});
      expect(await ios.access(), StepAccess.ready);
    });

    test('a request shows the prompt and reads the answer', () async {
      var auth = 'notDetermined';
      messenger.setMockMethodCallHandler(PlatformStepSensor.methods, (
        call,
      ) async {
        calls.add(call.method);
        return switch (call.method) {
          'isAvailable' => true,
          'requestAuthorization' => auth = 'authorized',
          _ => auth,
        };
      });
      expect(await ios.requestAccess(), StepAccess.ready);
      expect(calls, contains('requestAuthorization'));
    });

    test('a request never prompts when there is nothing to ask', () async {
      native({'isAvailable': true, 'authorization': 'denied'});
      expect(await ios.requestAccess(), StepAccess.permanentlyDenied);
      expect(calls, isNot(contains('requestAuthorization')));
    });
  });

  group('Android', () {
    test('a step sensor with the permission is ready', () async {
      native({'isAvailable': true});
      android(statuses: [_granted]);
      expect(await droid.access(), StepAccess.ready);
    });

    test('asks for ACTIVITY_RECOGNITION and reads the result', () async {
      native({'isAvailable': true});
      android(statuses: [_denied, _granted]);
      expect(await droid.access(), StepAccess.needsPermission);
      expect(await droid.requestAccess(), StepAccess.ready);
      expect(calls, contains('requestPermissions'));
    });

    test('a permanent refusal is reported, not re-asked', () async {
      native({'isAvailable': true});
      android(statuses: [_permanentlyDenied]);
      expect(await droid.requestAccess(), StepAccess.permanentlyDenied);
      expect(calls, isNot(contains('requestPermissions')));
    });

    test('opens Settings through the permission plugin', () async {
      android(statuses: [_granted]);
      expect(await droid.openSettings(), isTrue);
    });
  });

  group('a channel that fails is unavailable, never a throw', () {
    test('no handler at all (MissingPluginException)', () async {
      expect(await ios.access(), StepAccess.unavailable);
      expect(await ios.requestAccess(), StepAccess.unavailable);
      expect(await ios.openSettings(), isFalse);
    });

    test('a platform error', () async {
      native({'isAvailable': PlatformException(code: 'boom')});
      expect(await droid.access(), StepAccess.unavailable);
      messenger.setMockMethodCallHandler(
        _permissions,
        (_) async => throw PlatformException(code: 'boom'),
      );
      expect(await droid.openSettings(), isFalse);
    });
  });

  test('listeners share one native subscription (review #1)', () async {
    var listens = 0;
    var cancels = 0;
    MockStreamHandlerEventSink? native;
    messenger.setMockStreamHandler(
      PlatformStepSensor.events,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          listens++;
          native = sink;
        },
        onCancel: (_) => cancels++,
      ),
    );
    final sensor = PlatformStepSensor(platform: TargetPlatform.iOS);
    final first = <int>[];
    final second = <int>[];
    final a = sensor.steps.listen(first.add);
    final b = sensor.steps.listen(second.add);
    await Future<void>.delayed(Duration.zero);
    await a.cancel();
    native!.success(2);
    await Future<void>.delayed(Duration.zero);
    expect([listens, cancels], [1, 0]);
    expect(first, isEmpty);
    expect(second, [2]);
    await b.cancel();
    expect(cancels, 1);
  });

  test('a request announces that access may have changed', () async {
    native({'isAvailable': true, 'authorization': 'notDetermined'});
    final sensor = PlatformStepSensor(platform: TargetPlatform.iOS);
    final changed = sensor.accessChanges.first;
    await sensor.requestAccess();
    await changed;
    await sensor.dispose();
  });

  test('streams positive step batches from the event channel', () async {
    messenger.setMockStreamHandler(
      PlatformStepSensor.events,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          sink
            ..success(1)
            ..success(0)
            ..success(3.0)
            ..endOfStream();
        },
      ),
    );
    expect(await ios.steps.toList(), [1, 3]);
  });

  test('tests get an unavailable fake; production swaps in the platform', () {
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);
    final fake = defaults.read(stepSensorProvider);
    expect(fake, isA<FakeStepSensor>());
    expect((fake as FakeStepSensor).current, StepAccess.unavailable);

    final production = ProviderContainer(overrides: [platformStepOverride()]);
    addTearDown(production.dispose);
    expect(production.read(stepSensorProvider), isA<PlatformStepSensor>());
    expect(
      File(
        'lib/data/engine/platform_engine_overrides.dart',
      ).readAsStringSync(),
      contains('platformStepOverride()'),
    );
  });

  test('Android declares ACTIVITY_RECOGNITION; iOS names step counting', () {
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android.permission.ACTIVITY_RECOGNITION'),
    );
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(
        r'<key>NSMotionUsageDescription</key>\s*<string>[^<]*Step Quest[^<]*'
        'count steps[^<]*</string>',
      ).hasMatch(plist),
      isTrue,
    );
  });

  test('the native channels use the names the Dart side listens on', () {
    final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final kotlin = File(
      'android/app/src/main/kotlin/com/capywake/capywake/'
      'StepCounterChannel.kt',
    ).readAsStringSync();
    for (final source in [swift, kotlin]) {
      expect(source, contains('"${PlatformStepSensor.methods.name}"'));
      expect(source, contains('"${PlatformStepSensor.events.name}"'));
      expect(source, contains('"isAvailable"'));
    }
    expect(swift, contains('"authorization"'));
    expect(swift, contains('"requestAuthorization"'));
  });

  test('the motion prompt reads in every app language, and iOS knows them', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    for (final locale in AppLocalizations.supportedLocales) {
      final code = locale.languageCode;
      final strings = File('ios/Runner/$code.lproj/InfoPlist.strings');
      expect(strings.existsSync(), isTrue, reason: code);
      expect(
        RegExp(
          r'^NSMotionUsageDescription = "[^"]{40,}";$',
          multiLine: true,
        ).hasMatch(strings.readAsStringSync()),
        isTrue,
        reason: code,
      );
      expect(plist, contains('<string>$code</string>'), reason: code);
      expect(project, contains('path = $code.lproj/InfoPlist.strings'));
    }
  });
}

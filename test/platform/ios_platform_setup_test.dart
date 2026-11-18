import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final String _plist = File('ios/Runner/Info.plist').readAsStringSync();
final String _delegate = File(
  'ios/Runner/AppDelegate.swift',
).readAsStringSync();
final String _project = File(
  'ios/Runner.xcodeproj/project.pbxproj',
).readAsStringSync();

List<String> _arrayFor(String key) {
  final match = RegExp(
    '<key>$key</key>\\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(_plist);
  if (match == null) return const [];
  return RegExp(
    '<string>(.*?)</string>',
  ).allMatches(match.group(1)!).map((m) => m.group(1)!).toList();
}

String? _valueFor(String key) => RegExp(
  '<key>$key</key>\\s*<(string>(.*?)</string|true|false)',
  dotAll: true,
).firstMatch(_plist)?.group(1);

void main() {
  group('the alarm can ring with the app in the background', () {
    test('audio and fetch background modes are declared', () {
      expect(_arrayFor('UIBackgroundModes'), containsAll(['audio', 'fetch']));
    });

    test("the plugin's refresh task is permitted and registered", () {
      expect(
        _arrayFor('BGTaskSchedulerPermittedIdentifiers'),
        contains('com.gdelataillade.fetch'),
      );
      expect(_delegate, contains('SwiftAlarmPlugin.registerBackgroundTasks()'));
      expect(_delegate, contains('import alarm'));
    });

    test('the notification centre delegate is set before launch returns', () {
      final launch = _delegate.substring(
        _delegate.indexOf('didFinishLaunchingWithOptions'),
        _delegate.indexOf('return super.application'),
      );
      expect(launch, contains('UNUserNotificationCenter.current().delegate'));
      expect(launch, contains('registerBackgroundTasks'));
    });
  });

  group('store-facing settings', () {
    test('iPhone only, portrait only', () {
      final families = RegExp(
        'TARGETED_DEVICE_FAMILY = ([^;]+);',
      ).allMatches(_project).map((m) => m.group(1)).toSet();
      expect(families, {'1'});
      expect(_arrayFor('UISupportedInterfaceOrientations'), [
        'UIInterfaceOrientationPortrait',
      ]);
      expect(_plist, isNot(contains('UISupportedInterfaceOrientations~ipad')));
    });

    test('names the app and answers export compliance', () {
      expect(_valueFor('CFBundleDisplayName'), 'string>CapyWake</string');
      expect(_valueFor('CFBundleName'), 'string>CapyWake</string');
      expect(_valueFor('ITSAppUsesNonExemptEncryption'), 'false');
    });

    test('the launch screen is the app background in light and dark', () {
      final storyboard = File(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ).readAsStringSync();
      expect(
        storyboard,
        contains('<color key="backgroundColor" name="LaunchBackground"/>'),
      );
      final colours = File(
        'ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json',
      ).readAsStringSync().replaceAll(RegExp(r'\s'), '');
      expect(colours, contains('"blue":"0xE7","green":"0xF3","red":"0xFE"'));
      expect(colours, contains('"value":"dark"'));
      expect(colours, contains('"blue":"0x0E","green":"0x13","red":"0x1B"'));
    });

    test('the version comes from pubspec', () {
      expect(
        _valueFor('CFBundleShortVersionString'),
        r'string>$(FLUTTER_BUILD_NAME)</string',
      );
      expect(
        _valueFor('CFBundleVersion'),
        r'string>$(FLUTTER_BUILD_NUMBER)</string',
      );
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        RegExp(r'^version: (\S+)$', multiLine: true).firstMatch(pubspec)![1],
        matches(RegExp(r'^\d+\.\d+\.\d+\+\d+$')),
      );
    });
  });
}

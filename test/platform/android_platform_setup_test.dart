import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final String _manifest = File(
  'android/app/src/main/AndroidManifest.xml',
).readAsStringSync();
final String _gradle = File('android/app/build.gradle.kts').readAsStringSync();
const _res = 'android/app/src/main/res';

String _colour(String file, String name) {
  final xml = File('$_res/$file').readAsStringSync();
  return RegExp(
    '<color name="$name">(#[0-9A-F]{6})</color>',
  ).firstMatch(xml)![1]!;
}

void main() {
  test('the two unused plugin permissions are stripped from the merge', () {
    for (final permission in [
      'READ_EXTERNAL_STORAGE',
      'ACCESS_NOTIFICATION_POLICY',
    ]) {
      expect(
        _manifest,
        contains(
          '<uses-permission android:name="android.permission.$permission" '
          'tools:node="remove" />',
        ),
      );
    }
    expect(
      _manifest,
      contains('xmlns:tools="http://schemas.android.com/tools"'),
    );
  });

  test('the activity is portrait', () {
    expect(_manifest, contains('android:screenOrientation="portrait"'));
  });

  test('release builds sign with key.properties when it exists', () {
    expect(_gradle, contains('rootProject.file("key.properties")'));
    expect(_gradle, contains('signingConfigs.getByName("release")'));
    expect(File('android/key.properties.example').existsSync(), isTrue);
    expect(_gradle, isNot(contains('TODO')));
  });

  test('the launch window is the app background in light and dark', () {
    expect(_colour('values/colors.xml', 'launch_background'), '#FEF3E7');
    expect(_colour('values-night/colors.xml', 'launch_background'), '#1B130E');
    for (final dir in ['drawable', 'drawable-v21']) {
      expect(
        File('$_res/$dir/launch_background.xml').readAsStringSync(),
        contains('@color/launch_background'),
      );
    }
    for (final dir in ['values-v31', 'values-night-v31']) {
      expect(
        File('$_res/$dir/styles.xml').readAsStringSync(),
        contains(
          '<item name="android:windowSplashScreenBackground">@color/launch_background</item>',
        ),
      );
    }
  });
}

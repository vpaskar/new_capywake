import 'dart:io';

import 'package:capywake/app/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The About row shows a version, so it has to be a fact: this reads the
  // pubspec and fails when the constant drifts from it.
  test('AppVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    final declared = line.split(':')[1].trim().split('+').first;

    expect(AppVersion.value, declared);
  });
}

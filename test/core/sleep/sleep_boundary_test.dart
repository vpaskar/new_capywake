// Guard tests for the two structural promises Phase 35 makes.
//
// Both are checkable from source, so they are checked rather than trusted to
// review: a future session that breaks either one fails here instead of
// shipping an app that quietly overpromises or quietly exports health data.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `.dart` file under [dir].
List<File> _dartFiles(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

void main() {
  group('package:health containment', () {
    test('at most one file in lib/ imports the health plugin', () {
      final importers = _dartFiles('lib')
          .where(
            (f) => f.readAsStringSync().contains('package:health/health.dart'),
          )
          .map((f) => f.path)
          .toList();

      // The gateway abstraction exists so the plugin cannot spread. The plugin
      // is not a dependency yet, so the set is legitimately empty; the
      // invariant is that it never holds anything but the gateway.
      expect(importers.length, lessThanOrEqualTo(1));
      for (final importer in importers) {
        expect(importer, endsWith('lib/data/sleep/live_sleep_gateway.dart'));
      }
    });
  });

  group('sleep data never reaches alarm scheduling', () {
    // The reliability-honesty boundary in code form. HealthKit describes the
    // night that already happened; the alarm is armed hours ahead. Any import
    // of the sleep layer into a scheduling layer would be the first step to a
    // claim no phone can support, so the import itself is what is forbidden.
    const schedulingDirs = [
      'lib/core/schedule',
      'lib/core/wake',
      'lib/core/engine',
      'lib/core/lifecycle',
      'lib/data/engine',
    ];

    test('no scheduling layer imports the sleep layer', () {
      final offenders = <String>[];
      for (final dir in schedulingDirs) {
        for (final file in _dartFiles(dir)) {
          final source = file.readAsStringSync();
          final importsSleep =
              source.contains('core/sleep/') || source.contains('data/sleep/');
          if (importsSleep) offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'A scheduling layer imported the sleep layer. Sleep data must '
            'never influence when an alarm fires — see the '
            'reliability-honesty boundary in CLAUDE.md.',
      );
    });

    test('the alarm schedule engine does not mention a sleep type', () {
      // Belt and braces: even a transitively-reachable SleepNight must not
      // appear in a scheduling signature.
      final offenders = <String>[];
      for (final dir in schedulingDirs) {
        for (final file in _dartFiles(dir)) {
          final source = file.readAsStringSync();
          for (final symbol in const [
            'SleepNight',
            'SleepSegment',
            'SleepStage',
            'SleepGateway',
            'SleepSyncService',
          ]) {
            if (source.contains(symbol)) {
              offenders.add('${file.path}: $symbol');
            }
          }
        }
      }

      expect(offenders, isEmpty);
    });
  });

  group('platform manifests never ask to write sleep', () {
    // The write side is asserted now and forever: a declared write key would
    // mean CapyWake asked for access it must never have, and that must fail
    // the moment it appears rather than when someone next reads the manifest.
    //
    // The *read* side cannot be asserted yet — the sleep platform path lands
    // with `package:health`, and asserting the presence of a key this phase is
    // not allowed to add would only be satisfiable by adding it. The phase
    // that adds the dependency restores the positive half.
    test('iOS never asks to update health data', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(
        plist,
        isNot(contains('<key>NSHealthUpdateUsageDescription</key>')),
      );
    });

    test('Android never requests WRITE_SLEEP', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(
        manifest,
        isNot(contains('android.permission.health.WRITE_SLEEP')),
      );
    });

    test('a declared sleep read permission is paired with its rationale', () {
      // Conditional rather than absolute: if READ_SLEEP is ever declared,
      // Health Connect needs somewhere to send the user for the rationale, and
      // iOS raises on the request without a usage string. Holds vacuously
      // until the read path exists, and binds the moment it does.
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      if (manifest.contains('android.permission.health.READ_SLEEP')) {
        expect(
          manifest,
          contains('androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE'),
        );
        expect(plist, contains('<key>NSHealthShareUsageDescription</key>'));
      }
    });
  });

  group('the sleep gateway is read-only', () {
    test('the abstraction declares no write method', () {
      final source = File(
        'lib/core/sleep/sleep_gateway.dart',
      ).readAsStringSync();

      // Making the write impossible at the type level is stronger than a rule
      // in a document: adding an export path means widening this interface,
      // which is a visible change in review.
      for (final forbidden in const [
        'writeSegments',
        'writeSleep',
        'write(',
        'save(',
        'export(',
      ]) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: 'SleepGateway must stay read-only; found "$forbidden".',
        );
      }
    });

    test('no gateway implementation calls a health write API', () {
      // Scans every sleep implementation rather than one named file, so the
      // guard holds before the live gateway exists and still covers it — and
      // any sibling added later — once it does.
      for (final file in [
        ..._dartFiles('lib/data/sleep'),
        ..._dartFiles('lib/core/sleep'),
      ]) {
        final source = file.readAsStringSync();
        for (final forbidden in const [
          'writeHealthData',
          'writeWorkoutData',
          'writeMeal',
          'writeBloodPressure',
          'writeBloodOxygen',
          'writeMenstruationFlow',
          'writeInsulinDelivery',
        ]) {
          expect(
            source.contains(forbidden),
            isFalse,
            reason:
                'CapyWake measures no sleep and must write none; '
                'found "$forbidden" in ${file.path}.',
          );
        }
      }
    });
  });
}

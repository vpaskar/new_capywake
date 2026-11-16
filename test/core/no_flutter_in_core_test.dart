import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/core/` is the headless domain. The legacy's retrofit failed in the view
/// layer, and porting its domain was only safe because nothing in `core/` has
/// an opinion about how anything is drawn. These two tests are what keeps that
/// true without relying on anyone remembering it.
void main() {
  List<File> dartFiles(String dir) {
    final root = Directory(dir);
    if (!root.existsSync()) return const [];
    return root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  test('no file in lib/core imports Flutter', () {
    final files = dartFiles('lib/core');
    expect(
      files,
      isNotEmpty,
      reason: 'lib/core is missing, so this guard would pass vacuously.',
    );

    final offenders = files
        .where((f) => f.readAsStringSync().contains("import 'package:flutter/"))
        .map((f) => f.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'lib/core must stay headless and fully testable without a widget '
          'tree. A Flutter import here is the first step back to the '
          'view-layer coupling this rebuild exists to undo.',
    );
  });

  test('test/core uses Flutter only to construct a Locale', () {
    final files = dartFiles('test/core');
    expect(files, isNotEmpty);

    final offenders = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      final flutterImports = RegExp(
        r"import 'package:flutter/([a-z_]+)\.dart'",
      ).allMatches(source).map((m) => m.group(1)).toList();
      if (flutterImports.isEmpty) continue;

      // Only widgets.dart, and only for Locale: a localised formatter's test
      // has to build a Locale because the production API takes an
      // AppLocalizations, which is itself generated Flutter code. Anything
      // wider would make the lib/core guard above meaningless by letting the
      // coupling live one directory away.
      for (final library in flutterImports) {
        if (library != 'widgets') {
          offenders.add('${file.path}: imports package:flutter/$library.dart');
        }
      }
      if (!source.contains('Locale')) {
        offenders.add('${file.path}: imports Flutter but never uses Locale');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'test/core may import package:flutter/widgets.dart for Locale and '
          'nothing else.',
    );
  });
}

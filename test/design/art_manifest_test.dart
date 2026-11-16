import 'dart:io';

import 'package:capywake/design/art.dart';
import 'package:capywake/design/art_audit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yaml/yaml.dart';

void main() {
  group('bundled art', () {
    test('every catalogue entry exists on disk', () {
      for (final asset in CapyArt.all) {
        expect(
          File(asset.path).existsSync(),
          isTrue,
          reason:
              '${asset.id} is catalogued but ${asset.path} is missing. '
              'Run: dart run tool/import_art.dart',
        );
      }
    });

    test('every catalogue entry carries the pixels its box needs', () {
      for (final asset in CapyArt.all) {
        final decoded = img.decodeImage(File(asset.path).readAsBytesSync());
        expect(decoded, isNotNull, reason: '${asset.path} is unreadable');
        expect(
          decoded!.width,
          greaterThanOrEqualTo(asset.requiredPixels),
          reason:
              '${asset.id} is ${decoded.width}px wide but its '
              '${asset.use.renderBoxPt}pt box needs ${asset.requiredPixels}px '
              'at 3x',
        );
      }
    });

    test('no bundled cutout carries ghost pixels', () {
      final cutouts = [
        CapyArt.wordmark,
        ...Directory('assets/art/mascots')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.webp'))
            .map((f) => ArtAsset(f.path, f.path, ArtUse.mascotLarge)),
      ];

      for (final asset in cutouts) {
        final decoded = img.decodeImage(File(asset.path).readAsBytesSync())!;
        final result = auditImage(decoded);
        expect(
          result.ghostPixels,
          0,
          reason:
              '${asset.path} has ${result.ghostPixels} ghost pixels. '
              'The import pipeline should have cleared them.',
        );
      }
    });

    test('every bundled file is declared in pubspec', () {
      final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
      final declared = ((pubspec['flutter'] as Map)['assets'] as List)
          .cast<String>();

      for (final asset in CapyArt.all) {
        final covered = declared.any(
          (d) =>
              d == asset.path || (d.endsWith('/') && asset.path.startsWith(d)),
        );
        expect(
          covered,
          isTrue,
          reason: '${asset.path} is not covered by a pubspec asset entry',
        );
      }
    });

    test('mascots were sliced into individual poses', () {
      final mascots = Directory('assets/art/mascots')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.webp'))
          .toList();

      expect(mascots, hasLength(31));

      for (final file in mascots) {
        final decoded = img.decodeImage(file.readAsBytesSync())!;
        expect(
          decoded.width / decoded.height,
          lessThan(1.9),
          reason: '${file.path} is wide enough to hold two merged poses',
        );
      }
    });
  });
}

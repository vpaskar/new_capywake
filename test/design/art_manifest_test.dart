import 'dart:io';

import 'package:capywake/design/art.dart';
import 'package:capywake/design/art_audit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yaml/yaml.dart';

/// Assets below the pixels their box needs, by measured width (gap G15).
/// Recorded by name so the gate still protects everything else.
const knownUnderResolution = <String, int>{
  'thumb.sleeping': 288,
  'thumb.workout': 288,
  'thumb.walk': 230,
  'thumb.music': 260,
};

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
        if (knownUnderResolution.containsKey(asset.id)) continue;
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

    test('the known-short assets are exactly as short as recorded', () {
      for (final entry in knownUnderResolution.entries) {
        final asset = CapyArt.byId(entry.key);
        final decoded = img.decodeImage(File(asset.path).readAsBytesSync())!;
        expect(
          decoded.width,
          entry.value,
          reason:
              '${asset.id} is now ${decoded.width}px, recorded as '
              '${entry.value}px. Replacing the art closes gap G15 — update '
              'or remove this entry; never widen it to fit worse art.',
        );
        expect(decoded.width, lessThan(asset.requiredPixels));
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

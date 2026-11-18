import 'dart:io';
import 'dart:math' as math;

import 'package:capywake/design/art.dart';
import 'package:capywake/design/art_audit.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yaml/yaml.dart';

/// Assets below the pixels their box needs, by measured width (G18, G34).
/// Recorded by name so the gate still protects everything else.
const knownUnderResolution = <String, int>{
  'decor.cloudEdge': 1177,
  'pose.catchTheCapy': 219,
  'pose.memoryHideout': 242,
  'pose.rhythmRescue': 213,
  'pose.capyRocket': 217,
  'pose.shakeDj': 213,
  'pose.tiltMaze': 246,
  'pose.stepQuest': 217,
  'pose.qrTreasureHunt': 205,
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

    test('no bundled sticker lost its outline to masking', () {
      final stickers = [
        ...CapyArt.mascots,
        ...CapyArt.gameCapys,
        ...CapyArt.winPoses,
        ...CapyArt.winFrames,
      ];
      for (final asset in stickers) {
        final decoded = img.decodeImage(File(asset.path).readAsBytesSync())!;
        expect(decoded.numChannels, 4, reason: '${asset.path} has no alpha');
        expect(
          outlineCoverage(decoded),
          greaterThanOrEqualTo(minOutlineCoverage),
          reason:
              '${asset.path} has a light silhouette edge: its dark outline '
              'was probably removed with the background.',
        );
      }
    });

    test("the cloud edge's geometry matches SceneHeader's constants", () {
      final edge = img.decodeImage(
        File(CapyArt.cloudEdge.path).readAsBytesSync(),
      )!;
      expect(edge.width / edge.height, SceneHeader.cloudAspectRatio);
      final flatRow = (edge.height * SceneHeader.cloudLobeShare).round();
      for (final y in [flatRow - 1, flatRow]) {
        final opaque = [
          for (var x = 0; x < edge.width; x++) edge.getPixel(x, y).a == 255,
        ];
        expect(opaque.every((o) => o), y == flatRow, reason: 'row $y');
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

  group('supplied game art', () {
    test('the Memory Hideout tile shows no frame at any clip the app uses', () {
      final tile = img.decodeImage(
        File(CapyArt.byId('tile.memoryHideout').path).readAsBytesSync(),
      )!;
      // The tightest clip: the chooser's 40 pt tile at an 8 pt radius cuts
      // this far into each corner along the diagonal.
      final cut = (tile.width * (8 / 40) * (1 - math.sqrt1_2)).floor();
      for (final (x, y) in [
        (cut, cut),
        (tile.width - 1 - cut, cut),
        (cut, tile.height - 1 - cut),
        (tile.width - 1 - cut, tile.height - 1 - cut),
      ]) {
        final p = tile.getPixel(x, y);
        expect(p.r + p.g + p.b, greaterThan(300), reason: 'dark at ($x, $y)');
      }
    });

    test('run frames share one canvas and a foot baseline', () {
      final sizes = <(int, int)>{};
      for (final frame in CapyArt.runFrames) {
        final decoded = img.decodeImage(File(frame.path).readAsBytesSync())!;
        sizes.add((decoded.width, decoded.height));
        final ink = auditImage(decoded).trimRect!;
        expect(ink.bottom, decoded.height - 1, reason: '${frame.id} floats');
        expect(ink.right, decoded.width - 1, reason: '${frame.id} nose moved');
      }
      expect(sizes, hasLength(1));
    });

    test('dust frames share one canvas', () {
      final sizes = {
        for (final f in CapyArt.dustFrames)
          () {
            final d = img.decodeImage(File(f.path).readAsBytesSync())!;
            return (d.width, d.height);
          }(),
      };
      expect(sizes, hasLength(1));
    });
  });
}

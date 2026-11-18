import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _iosSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _res = 'android/app/src/main/res';

/// `flutter create`'s icon is white; ours sits on `AppColors.cream`.
bool _onCream(img.Image icon) {
  final corner = icon.getPixel(0, 0);
  return corner.r == 0xFE && corner.g == 0xF3 && corner.b == 0xE7;
}

img.Image _decode(String path) => img.decodePng(File(path).readAsBytesSync())!;

void main() {
  final contents =
      jsonDecode(File('$_iosSet/Contents.json').readAsStringSync())
          as Map<String, dynamic>;
  final images = (contents['images'] as List).cast<Map<String, dynamic>>();

  test('every iOS icon the set names exists at its pixel size', () {
    expect(images, isNotEmpty);
    for (final entry in images) {
      final side = double.parse((entry['size'] as String).split('x').first);
      final scale = int.parse((entry['scale'] as String).replaceAll('x', ''));
      final icon = _decode('$_iosSet/${entry['filename']}');
      expect(
        icon.width,
        (side * scale).round(),
        reason: '${entry['filename']}',
      );
      expect(icon.height, icon.width);
    }
    expect(images.map((e) => e['idiom']).toSet(), {'iphone', 'ios-marketing'});
  });

  test('the store icon is opaque and is not the Flutter logo', () {
    final icon = _decode('$_iosSet/Icon-App-1024x1024@1x.png');
    expect(icon.numChannels, 3, reason: 'App Store rejects alpha');
    expect(_onCream(icon), isTrue);
    expect(_onCream(_decode('$_res/mipmap-xxxhdpi/ic_launcher.png')), isTrue);
  });

  test('Android has a legacy and an adaptive icon at every density', () {
    const densities = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    for (final MapEntry(key: density, value: factor) in densities.entries) {
      final legacy = _decode('$_res/mipmap-$density/ic_launcher.png');
      expect(legacy.width, (48 * factor).round(), reason: density);
      final fg = _decode('$_res/mipmap-$density/ic_launcher_foreground.png');
      expect(fg.width, (108 * factor).round(), reason: density);
    }
    final adaptive = File(
      '$_res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
    expect(adaptive, contains('@color/ic_launcher_background'));
  });

  test('the adaptive foreground stays inside the 66 dp safe circle', () {
    final fg = _decode('$_res/mipmap-xxxhdpi/ic_launcher_foreground.png');
    final centre = (fg.width - 1) / 2;
    final safeRadius = fg.width * 33 / 108;
    var reach = 0.0;
    for (final p in fg) {
      if (p.a > 8) {
        reach = math.max(
          reach,
          math.sqrt(math.pow(p.x - centre, 2) + math.pow(p.y - centre, 2)),
        );
      }
    }
    expect(reach, greaterThan(safeRadius * 0.8), reason: 'not lost in space');
    expect(reach, lessThanOrEqualTo(safeRadius));
  });
}

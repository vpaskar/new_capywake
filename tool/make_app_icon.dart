// Every iOS and Android launcher icon from one supplied file, on cream.
// Usage: dart run tool/make_app_icon.dart [reference/02_ASSETS/<file>.png]

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const defaultSource =
    'reference/02_ASSETS/source_png/cute_golden_twin_bell_alarm_clock.png';

/// `AppColors.cream`, the field every icon sits on.
final cream = img.ColorRgb8(0xFE, 0xF3, 0xE7);

/// Art box as a share of the square icon's side.
const iosArtShare = 0.64;

/// Android adaptive foreground: 108 dp canvas whose safe circle is 66 dp.
const adaptiveCanvasDp = 108;
const adaptiveSafeRadiusDp = 33;

const iosSizes = <(String, int, double)>[
  ('20x20', 2, 40),
  ('20x20', 3, 60),
  ('29x29', 2, 58),
  ('29x29', 3, 87),
  ('40x40', 2, 80),
  ('40x40', 3, 120),
  ('60x60', 2, 120),
  ('60x60', 3, 180),
];

const androidDensities = <String, double>{
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

const _iosSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _androidRes = 'android/app/src/main/res';

/// Places supplied art and draws nothing; refuses a source it would upscale.
void main(List<String> args) {
  final sourcePath = args.isEmpty ? defaultSource : args.single;
  final decoded = img.decodePng(File(sourcePath).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('FAIL: $sourcePath is not a PNG.');
    exit(2);
  }
  final art = trimToOpaque(decoded.convert(numChannels: 4));
  final needed = (1024 * iosArtShare).round();
  final longest = math.max(art.width, art.height);
  if (longest < needed) {
    stderr.writeln(
      'FAIL: $sourcePath art is ${art.width}x${art.height}; the store icon '
      'needs $needed px on its long side. Supply a larger file.',
    );
    exit(2);
  }

  final master = squareIcon(art, 1024, iosArtShare);
  _writePng('$_iosSet/Icon-App-1024x1024@1x.png', master);
  final images = <Map<String, String>>[];
  for (final (size, scale, px) in iosSizes) {
    final name = 'Icon-App-$size@${scale}x.png';
    _writePng('$_iosSet/$name', _resize(master, px.round()));
    images.add({
      'size': size,
      'idiom': 'iphone',
      'filename': name,
      'scale': '${scale}x',
    });
  }
  images.add({
    'size': '1024x1024',
    'idiom': 'ios-marketing',
    'filename': 'Icon-App-1024x1024@1x.png',
    'scale': '1x',
  });
  for (final stale in Directory(_iosSet).listSync().whereType<File>()) {
    final name = stale.uri.pathSegments.last;
    if (name.endsWith('.png') && !images.any((i) => i['filename'] == name)) {
      stale.deleteSync();
    }
  }
  File('$_iosSet/Contents.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({
      'images': images,
      'info': {'version': 1, 'author': 'xcode'},
    })}\n',
  );

  final adaptiveShare = adaptiveArtShare(art);
  for (final MapEntry(key: density, value: factor)
      in androidDensities.entries) {
    final dir = '$_androidRes/mipmap-$density';
    _writePng('$dir/ic_launcher.png', _resize(master, (48 * factor).round()));
    _writePng(
      '$dir/ic_launcher_foreground.png',
      foreground(art, (adaptiveCanvasDp * factor).round(), adaptiveShare),
    );
  }
  Directory('$_androidRes/mipmap-anydpi-v26').createSync(recursive: true);
  File('$_androidRes/mipmap-anydpi-v26/ic_launcher.xml').writeAsStringSync(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background" />\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
    '</adaptive-icon>\n',
  );
  File('$_androidRes/values/ic_launcher_background.xml').writeAsStringSync(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources>\n'
    '    <color name="ic_launcher_background">#FEF3E7</color>\n'
    '</resources>\n',
  );
  stdout.writeln(
    'Wrote icons from $sourcePath (art ${art.width}x${art.height}, '
    'adaptive share ${adaptiveShare.toStringAsFixed(3)}).',
  );
}

/// [source] cropped to the bounding box of its non-transparent pixels.
img.Image trimToOpaque(img.Image source) {
  var left = source.width;
  var top = source.height;
  var right = -1;
  var bottom = -1;
  for (final p in source) {
    if (p.a > 8) {
      left = math.min(left, p.x);
      top = math.min(top, p.y);
      right = math.max(right, p.x);
      bottom = math.max(bottom, p.y);
    }
  }
  if (right < 0) return source;
  return img.copyCrop(
    source,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}

/// An opaque square of [side] px: [art] centred on cream, long side at [share].
img.Image squareIcon(img.Image art, int side, double share) {
  final canvas = img.Image(width: side, height: side)..clear(cream);
  return _centre(canvas, art, side * share);
}

/// A transparent adaptive foreground of [side] px with [art] at [share].
img.Image foreground(img.Image art, int side, double share) {
  final canvas = img.Image(width: side, height: side, numChannels: 4)
    ..clear(img.ColorRgba8(0, 0, 0, 0));
  return _centre(canvas, art, side * share);
}

/// The largest share whose every opaque pixel stays inside the safe circle.
double adaptiveArtShare(img.Image art) {
  final cx = (art.width - 1) / 2;
  final cy = (art.height - 1) / 2;
  var reach = 0.0;
  for (final p in art) {
    if (p.a > 8) {
      reach = math.max(
        reach,
        math.sqrt(math.pow(p.x - cx, 2) + math.pow(p.y - cy, 2)),
      );
    }
  }
  final longest = math.max(art.width, art.height);
  const safeShare = 2 * adaptiveSafeRadiusDp / adaptiveCanvasDp;
  return safeShare * longest / (2 * reach) * 0.96;
}

img.Image _centre(img.Image canvas, img.Image art, double box) {
  final scale = box / math.max(art.width, art.height);
  final placed = img.copyResize(
    art,
    width: math.max(1, (art.width * scale).round()),
    height: math.max(1, (art.height * scale).round()),
    interpolation: img.Interpolation.average,
  );
  return img.compositeImage(
    canvas,
    placed,
    dstX: (canvas.width - placed.width) ~/ 2,
    dstY: (canvas.height - placed.height) ~/ 2,
  );
}

img.Image _resize(img.Image master, int side) => img.copyResize(
  master,
  width: side,
  height: side,
  interpolation: img.Interpolation.average,
);

void _writePng(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
}

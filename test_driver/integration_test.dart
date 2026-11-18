import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

import '../integration_test/capture_names.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      for (final entry in (data ?? {}).entries) {
        // The framework adds its own `screenshots` key holding every PNG's
        // bytes. Writing it produced a 24 MB docs/visual/screenshots/
        // inset.txt, 18.8 MB of which reached the Phase 03 commit.
        if (entry.value is! num) continue;
        final out = File('docs/visual/${entry.key}/inset.txt');
        await out.parent.create(recursive: true);
        await out.writeAsString('${entry.value}');
      }
    },
    onScreenshot: (name, bytes, [args]) async {
      final (screen, file) = name.endsWith(darkCaptureSuffix)
          ? (
              name.substring(0, name.length - darkCaptureSuffix.length),
              'dark.png',
            )
          : (name, 'actual.png');
      final out = File('docs/visual/$screen/$file');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes);
      stdout.writeln('WROTE ${out.path} (${bytes.length} bytes)');
      return true;
    },
  );
}

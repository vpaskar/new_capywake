import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      for (final entry in (data ?? {}).entries) {
        final out = File('docs/visual/${entry.key}/inset.txt');
        await out.parent.create(recursive: true);
        await out.writeAsString('${entry.value}');
      }
    },
    onScreenshot: (name, bytes, [args]) async {
      final out = File('docs/visual/$name/actual.png');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes);
      stdout.writeln('WROTE ${out.path} (${bytes.length} bytes)');
      return true;
    },
  );
}

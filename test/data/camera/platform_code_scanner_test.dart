import 'package:capywake/data/camera/platform_code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _scanner = MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
const _events = EventChannel('dev.steenbakker.mobile_scanner/scanner/event');
const _orientation = EventChannel(
  'dev.steenbakker.mobile_scanner/scanner/deviceOrientation',
);

void main() {
  testWidgets('a camera it may not use is reported once (H3)', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    final methods = <String>[];
    messenger
      ..setMockMethodCallHandler(_scanner, (call) async {
        methods.add(call.method);
        if (call.method == 'start') {
          throw PlatformException(code: 'MobileScannerPermissionDenied');
        }
        return null;
      })
      ..setMockStreamHandler(
        _events,
        MockStreamHandler.inline(onListen: (_, _) {}),
      )
      ..setMockStreamHandler(
        _orientation,
        MockStreamHandler.inline(onListen: (_, _) {}),
      );
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(_scanner, null)
        ..setMockStreamHandler(_events, null)
        ..setMockStreamHandler(_orientation, null);
    });

    var failures = 0;
    final codes = <String>[];
    final scanner = PlatformCodeScanner();
    Widget app(double height) => MaterialApp(
      home: SizedBox(
        height: height,
        child: scanner.build(onCode: codes.add, onFailed: () => failures++),
      ),
    );
    await tester.pumpWidget(app(200));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (final height in [210.0, 220.0, 230.0]) {
      await tester.pumpWidget(app(height));
      await tester.pump();
    }
    expect(methods, contains('state'));
    expect(failures, 1);
    expect(codes, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

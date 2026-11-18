import 'dart:io';

import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/features/games/game_outcome_line.dart';
import 'package:capywake/features/games/qr_treasure_hunt_view.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '_pump.dart';

final Finder _scan = find.byKey(const ValueKey('qr-hunt-scan'));
final Finder _camera = find.byKey(const ValueKey('qr-hunt-camera'));
final Finder _capy = find.byKey(const ValueKey('qr-hunt-capy'));

final _checkpoint = QrCheckpoint.of(
  'MIRROR',
  savedAt: DateTime.utc(2026, 11, 18),
);

typedef _Calls = ({List<GameChallenge> progress, List<int> completed});

Future<_Calls> _pump(
  WidgetTester tester, {
  FakeCodeScanner? scanner,
  QrCheckpoint? checkpoint,
  bool noCheckpoint = false,
  bool reduceMotion = true,
  bool accessibleNavigation = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  bool inRingingSlot = false,
  Size size = const Size(393, 852),
}) async {
  final progress = <GameChallenge>[];
  final completed = <int>[];
  final view = QrTreasureHuntView(
    scanner: scanner ?? FakeCodeScanner(),
    checkpoint: noCheckpoint ? null : (checkpoint ?? _checkpoint),
    onProgress: progress.add,
    onCompleted: () => completed.add(1),
    reduceMotion: reduceMotion,
  );
  await pumpInApp(
    tester,
    inRingingSlot ? ringingSlotWidth(view) : view,
    accessibleNavigation: accessibleNavigation,
    textScale: textScale,
    brightness: brightness,
    locale: locale,
    size: size,
  );
  return (progress: progress, completed: completed);
}

String? _outcome(WidgetTester tester) =>
    tester.widget<GameOutcomeLine>(find.byType(GameOutcomeLine)).text;

Future<void> _startCamera(WidgetTester tester) async {
  await tester.tap(_scan);
  await tester.pump();
}

void main() {
  testWidgets('shows the goal and the button, with no camera yet (H1)', (
    tester,
  ) async {
    final scanner = FakeCodeScanner();
    await _pump(tester, scanner: scanner);
    expect(
      find.text('Scan your checkpoint.'),
      findsOneWidget,
    );
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    expect(_camera, findsNothing);
    expect(scanner.starts, 0, reason: 'a ring never opens the camera itself');
    expect(_outcome(tester), isNull);
  });

  testWidgets('the scan button is a game control, not a twin of Snooze', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.descendant(
        of: find.byType(QrTreasureHuntView),
        matching: find.byType(CapyButton),
      ),
      findsNothing,
    );
    expect(tester.getSize(_scan).height, greaterThanOrEqualTo(44));
  });

  testWidgets('a tap opens the camera; another tap closes it', (
    tester,
  ) async {
    final scanner = FakeCodeScanner();
    await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    expect(scanner.isLive, isTrue);
    expect(find.text('Stop camera'), findsOneWidget);
    await _startCamera(tester);
    expect(scanner.isLive, isFalse);
    expect(find.text('Scan QR'), findsOneWidget);
  });

  testWidgets('the checkpoint wins once, and the camera closes', (
    tester,
  ) async {
    final scanner = FakeCodeScanner();
    final calls = await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    scanner
      ..show('MIRROR')
      ..show('MIRROR');
    await tester.pump();
    expect(calls.completed, [1]);
    expect(calls.progress, hasLength(1));
    expect(calls.progress.single.isComplete, isTrue);
    expect(scanner.isLive, isFalse);
    expect(find.text('1 / 1'), findsOneWidget);
    await tester.tap(_scan);
    await tester.pump();
    expect(scanner.isLive, isFalse, reason: 'nothing to scan after a win');
  });

  testWidgets('a wrong code is one struggle while it is held (M1)', (
    tester,
  ) async {
    final scanner = FakeCodeScanner();
    final calls = await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    for (var frame = 0; frame < 10; frame++) {
      scanner.show('COFFEE');
    }
    await tester.pump();
    expect(calls.progress, hasLength(1));
    expect(calls.progress.single.struggleCount, 1);
    expect(_outcome(tester), 'Not your checkpoint. Keep looking.');
    expect(scanner.isLive, isTrue, reason: 'keep looking');
    scanner.show('MIRROR');
    await tester.pump();
    expect(calls.completed, [1]);
  });

  testWidgets('a camera that will not start is a struggle; retry works '
      '(H3)', (tester) async {
    final scanner = FakeCodeScanner();
    final calls = await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    scanner.fail();
    await tester.pump();
    expect(scanner.isLive, isFalse);
    expect(calls.progress.single.struggleCount, 1);
    expect(_outcome(tester), 'The camera did not start.');
    await _startCamera(tester);
    scanner.fail();
    await tester.pump();
    expect(calls.progress.last.struggleCount, 2);
    await _startCamera(tester);
    scanner.show('MIRROR');
    await tester.pump();
    expect(calls.completed, [1]);
  });

  testWidgets('a code that arrives after Stop is ignored (R6)', (
    tester,
  ) async {
    final scanner = FakeCodeScanner();
    final calls = await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    await _startCamera(tester);
    scanner.showLate('MIRROR');
    await tester.pump();
    expect(calls.progress, isEmpty);
    expect(calls.completed, isEmpty);
  });

  testWidgets('a code after the view is gone does nothing', (tester) async {
    final scanner = FakeCodeScanner();
    final calls = await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    await tester.pumpWidget(const SizedBox());
    scanner.showLate('MIRROR');
    expect(tester.takeException(), isNull);
    expect(calls.completed, isEmpty);
  });

  testWidgets('a new look counts a code seen before again', (tester) async {
    final scanner = FakeCodeScanner();
    final calls = await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    scanner.show('COFFEE');
    await tester.pump();
    await _startCamera(tester);
    await _startCamera(tester);
    scanner.show('COFFEE');
    await tester.pump();
    expect(calls.progress.last.struggleCount, 2);
  });

  testWidgets('leaving the app turns the camera off (H1)', (tester) async {
    final scanner = FakeCodeScanner();
    await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(scanner.isLive, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(scanner.isLive, isFalse, reason: 'it never reopens on its own');
  });

  testWidgets('disposing closes the camera', (tester) async {
    final scanner = FakeCodeScanner();
    await _pump(tester, scanner: scanner);
    await _startCamera(tester);
    await tester.pumpWidget(const SizedBox());
    expect(scanner.isLive, isFalse);
  });

  testWidgets('without a checkpoint it says so and nothing wins', (
    tester,
  ) async {
    final scanner = FakeCodeScanner();
    final calls = await _pump(tester, scanner: scanner, noCheckpoint: true);
    expect(_outcome(tester), 'No checkpoint set yet.');
    await _startCamera(tester);
    scanner.show('MIRROR');
    await tester.pump();
    expect(calls.completed, isEmpty);
  });

  testWidgets('a screen reader can reach and press the scan button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final scanner = FakeCodeScanner();
    await _pump(tester, scanner: scanner, accessibleNavigation: true);
    tester.semantics.tap(find.semantics.byLabel('Scan QR'));
    await tester.pump();
    expect(scanner.isLive, isTrue);
    expect(find.bySemanticsLabel('Stop camera'), findsOneWidget);
    handle.dispose();
  });

  group('moving', () {
    testWidgets('the brackets pulse, then rest so frames settle', (
      tester,
    ) async {
      await _pump(tester, reduceMotion: false);
      expect(tester.hasRunningAnimations, isFalse, reason: 'resting');
      await tester.pump(QrTreasureHuntView.pulseRest);
      await tester.pump(QrTreasureHuntView.pulse * 0.5);
      expect(tester.hasRunningAnimations, isTrue, reason: 'pulses again');
      final transforms = tester.widgetList<Transform>(
        find.ancestor(
          of: find.byKey(const ValueKey('qr-hunt-brackets')),
          matching: find.byType(Transform),
        ),
      );
      expect(
        transforms.any((t) => t.transform.getMaxScaleOnAxis() > 1.01),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('nothing moves under reduce-motion or a screen reader', (
      tester,
    ) async {
      for (final (reduce, reader) in [(true, false), (false, true)]) {
        await _pump(
          tester,
          reduceMotion: reduce,
          accessibleNavigation: reader,
        );
        await tester.pump(QrTreasureHuntView.pulse);
        expect(tester.hasRunningAnimations, isFalse);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the pulse stops while the camera runs', (tester) async {
      await _pump(tester, reduceMotion: false);
      await _startCamera(tester);
      await tester.pump(QrTreasureHuntView.pulse * 2);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Capy is drawn no larger than its pixels allow', (
    tester,
  ) async {
    await _pump(tester);
    final file = img.decodeWebP(
      File(CapyArt.byId('game.capy.detective').path).readAsBytesSync(),
    )!;
    expect(
      tester.getSize(_capy).width * 3,
      lessThanOrEqualTo(file.width + 1),
    );
  });

  testWidgets('fits a 320 pt phone', (tester) async {
    await _pump(tester, inRingingSlot: true, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the card stays within 424 pt in ${locale.languageCode}', (
      tester,
    ) async {
      final scanner = FakeCodeScanner();
      await _pump(
        tester,
        scanner: scanner,
        locale: locale,
        inRingingSlot: true,
      );
      final before = tester.getSize(find.byType(GameOutcomeLine)).height;
      await _startCamera(tester);
      scanner.show('COFFEE');
      await tester.pump();
      expect(tester.getSize(find.byType(GameOutcomeLine)).height, before);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CapyCard)).height,
        lessThanOrEqualTo(424),
      );
    });
  }

  for (final locale in const [Locale('en'), Locale('de'), Locale('ru')]) {
    testWidgets('at 2x text every line fits (${locale.languageCode})', (
      tester,
    ) async {
      final scanner = FakeCodeScanner();
      await _pump(
        tester,
        scanner: scanner,
        locale: locale,
        inRingingSlot: true,
        textScale: 2,
      );
      final before = tester.getSize(find.byType(GameOutcomeLine)).height;
      await _startCamera(tester);
      scanner.fail();
      await tester.pump();
      expect(tester.getSize(find.byType(GameOutcomeLine)).height, before);
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('renders in $brightness, right-to-left, no overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        brightness: brightness,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

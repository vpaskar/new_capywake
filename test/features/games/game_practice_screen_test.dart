import 'dart:async';

import 'package:capywake/core/camera/fake_camera_access.dart';
import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/motion/fake_step_sensor.dart';
import 'package:capywake/core/motion/step_sensor.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/camera/code_scanner.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/features/games/catch_the_capy_view.dart';
import 'package:capywake/features/games/device_access_prompt.dart';
import 'package:capywake/features/games/game_practice_screen.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/features/games/memory_hideout_view.dart';
import 'package:capywake/features/games/qr_treasure_hunt_view.dart';
import 'package:capywake/features/games/step_quest_view.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  String gameId, {
  StepSensor? steps,
  FakeCameraAccess? camera,
  FakeCodeScanner? scanner,
  Stream<RingingSession?>? ringing,
  CapyWakeRepository Function(AppDatabase db)? repository,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  var seed = 0;
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      practiceSeedProvider.overrideWithValue(() => seed++),
      if (steps != null) stepSensorProvider.overrideWithValue(steps),
      if (camera != null) cameraAccessProvider.overrideWithValue(camera),
      if (scanner != null) codeScannerProvider.overrideWithValue(scanner),
      if (ringing != null) ringingSessionProvider.overrideWith((_) => ringing),
      if (repository != null)
        capywakeRepositoryProvider.overrideWith((_) => repository(db)),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GamePracticeScreen(gameId: gameId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _catchAll(WidgetTester tester) async {
  final target = find.byKey(const ValueKey('catch-the-capy-target'));
  while (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('plays Catch the Capy with the practice note', (tester) async {
    await _pump(tester, 'catch_the_capy');
    expect(find.text('Catch the Capy'), findsWidgets);
    expect(
      find.text('Practice here. Nothing you do changes an alarm.'),
      findsOneWidget,
    );
    expect(find.byType(CatchTheCapyView), findsOneWidget);
  });

  testWidgets('finishing shows Practice done and Play again restarts', (
    tester,
  ) async {
    await _pump(tester, 'catch_the_capy');
    await _catchAll(tester);

    expect(find.text('Practice done'), findsOneWidget);
    expect(find.byType(GameWinCelebration), findsOneWidget);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
  });

  testWidgets('uses the user difficulty and writes nothing', (tester) async {
    final container = await _pump(tester, 'catch_the_capy');
    final repo = container.read(capywakeRepositoryProvider);
    final before = await repo.getPuzzleSettings();

    await _catchAll(tester);

    expect(await repo.getPuzzleSettings(), before);
    expect(before, PuzzleSettings.defaults());
  });

  testWidgets('Memory Hideout is practisable too', (tester) async {
    await _pump(tester, 'memory_hideout');
    expect(find.byType(MemoryHideoutView), findsOneWidget);
  });

  testWidgets('an unknown id never crashes (L2)', (tester) async {
    await _pump(tester, 'not_a_game');
    expect(tester.takeException(), isNull);
    expect(find.text('Not built yet'), findsOneWidget);
  });

  testWidgets('practice waits for the saved difficulty before starting', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        practiceSeedProvider.overrideWithValue(() => 1),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await container
        .read(capywakeRepositoryProvider)
        .savePuzzleSettings(
          PuzzleSettings.defaults().copyWith(difficulty: PuzzleDifficulty.hard),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GamePracticeScreen(gameId: 'catch_the_capy'),
        ),
      ),
    );
    expect(find.text('0 / 5'), findsNothing, reason: 'no medium fallback');
    await tester.pumpAndSettle();
    expect(find.text('0 / 7'), findsOneWidget);
  });

  group('Step Quest practice offers the step sensor', () {
    final card = find.byKey(const ValueKey('step-access-card'));

    testWidgets('asks first, then counts with the sensor', (tester) async {
      final steps = FakeStepSensor(
        current: DeviceAccess.needsPermission,
        afterRequest: DeviceAccess.ready,
      );
      await _pump(tester, 'step_quest', steps: steps);
      expect(card, findsOneWidget);
      expect(find.byType(StepQuestView), findsOneWidget);
      expect(steps.requestCount, 0, reason: 'the reason is shown first');
      expect(steps.listenCount, 0);

      await tester.tap(find.text('Allow step counting'));
      await tester.pumpAndSettle();
      expect(steps.requestCount, 1);
      expect(card, findsNothing);
      expect(steps.hasListener, isTrue);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('step-quest-source')))
            .data,
        'Counted by your step sensor',
      );
    });

    testWidgets('Not now hides it and asks nothing', (tester) async {
      final steps = FakeStepSensor(current: DeviceAccess.needsPermission);
      await _pump(tester, 'step_quest', steps: steps);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(steps.requestCount, 0);
    });

    testWidgets('a refusal points to Settings, and a return re-reads', (
      tester,
    ) async {
      final steps = FakeStepSensor(current: DeviceAccess.permanentlyDenied);
      await _pump(tester, 'step_quest', steps: steps);
      expect(
        find.textContaining('Step counting is off for CapyWake'),
        findsOneWidget,
      );
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(steps.settingsCount, 1);
      expect(steps.requestCount, 0, reason: 'iOS never asks twice');
      expect(card, findsOneWidget, reason: 'nothing changed yet');

      steps.current = DeviceAccess.ready;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(steps.hasListener, isTrue);
    });

    for (final access in [DeviceAccess.ready, DeviceAccess.unavailable]) {
      testWidgets('shows nothing when access is ${access.name}', (
        tester,
      ) async {
        await _pump(
          tester,
          'step_quest',
          steps: FakeStepSensor(current: access),
        );
        expect(card, findsNothing);
      });
    }

    testWidgets('other games never offer it', (tester) async {
      final steps = FakeStepSensor(current: DeviceAccess.needsPermission);
      await _pump(tester, 'shake_dj', steps: steps);
      expect(card, findsNothing);
      expect(find.byType(DeviceAccessPrompt), findsNothing);
    });
  });

  group('QR Treasure Hunt practice sets the checkpoint first', () {
    final prompt = find.byKey(const ValueKey('camera-access-prompt'));
    final setupCamera = find.byKey(const ValueKey('qr-setup-camera'));

    testWidgets('reason, then the camera prompt, then one scan saves it', (
      tester,
    ) async {
      final camera = FakeCameraAccess(
        current: DeviceAccess.needsPermission,
        afterRequest: DeviceAccess.ready,
      );
      final scanner = FakeCodeScanner();
      final c = await _pump(
        tester,
        'qr_treasure_hunt',
        camera: camera,
        scanner: scanner,
      );
      expect(find.text('Your morning checkpoint'), findsOneWidget);
      expect(find.byType(QrTreasureHuntView), findsNothing);
      expect(prompt, findsOneWidget);
      expect(camera.requestCount, 0, reason: 'the reason is shown first');
      expect(scanner.starts, 0);

      await tester.tap(find.text('Allow the camera'));
      await tester.pumpAndSettle();
      expect(camera.requestCount, 1);
      expect(prompt, findsNothing);

      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      expect(setupCamera, findsOneWidget);
      scanner.show('MIRROR');
      await tester.pumpAndSettle();
      final saved = await c.read(capywakeRepositoryProvider).getQrCheckpoint();
      expect(saved!.matches('MIRROR'), isTrue);
      expect(find.text('Checkpoint saved.'), findsOneWidget);
      expect(find.byType(QrTreasureHuntView), findsOneWidget);
      expect(scanner.isLive, isFalse);
    });

    testWidgets('Not now explains alarms skip the game', (tester) async {
      final camera = FakeCameraAccess(current: DeviceAccess.needsPermission);
      await _pump(tester, 'qr_treasure_hunt', camera: camera);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Alarms skip QR Treasure Hunt'),
        findsOneWidget,
      );
      expect(camera.requestCount, 0);
    });

    testWidgets('a refusal points to Settings; a return re-reads it', (
      tester,
    ) async {
      final camera = FakeCameraAccess(current: DeviceAccess.permanentlyDenied);
      await _pump(tester, 'qr_treasure_hunt', camera: camera);
      expect(find.textContaining('camera is off for CapyWake'), findsOne);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(camera.settingsCount, 1);
      camera.current = DeviceAccess.ready;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Scan a code'), findsOneWidget);
    });

    testWidgets('no camera says so and offers no scan', (tester) async {
      await _pump(tester, 'qr_treasure_hunt', camera: FakeCameraAccess());
      expect(
        find.textContaining('no camera CapyWake can use'),
        findsOneWidget,
      );
      expect(find.text('Scan a code'), findsNothing);
    });

    testWidgets('a failing camera says so and can be retried', (tester) async {
      final scanner = FakeCodeScanner();
      await _pump(
        tester,
        'qr_treasure_hunt',
        camera: FakeCameraAccess(current: DeviceAccess.ready),
        scanner: scanner,
      );
      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      scanner.fail();
      await tester.pump();
      expect(find.text('The camera did not start.'), findsOneWidget);
      expect(setupCamera, findsNothing);
      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      expect(setupCamera, findsOneWidget);
      await tester.tap(find.text('Stop camera'));
      await tester.pump();
      expect(scanner.isLive, isFalse);
    });

    testWidgets('leaving the app stops the setup camera', (tester) async {
      final scanner = FakeCodeScanner();
      await _pump(
        tester,
        'qr_treasure_hunt',
        camera: FakeCameraAccess(current: DeviceAccess.ready),
        scanner: scanner,
      );
      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(scanner.isLive, isFalse, reason: 'it never reopens on its own');
    });

    testWidgets('a kept checkpoint without the camera asks first (SR1)', (
      tester,
    ) async {
      final camera = FakeCameraAccess(
        current: DeviceAccess.needsPermission,
        afterRequest: DeviceAccess.ready,
      );
      final scanner = FakeCodeScanner();
      final c = await _pump(
        tester,
        'qr_treasure_hunt',
        camera: camera,
        scanner: scanner,
      );
      await c
          .read(capywakeRepositoryProvider)
          .saveQrCheckpoint(
            QrCheckpoint.of('MIRROR', savedAt: DateTime.utc(2026)),
          );
      await tester.pumpAndSettle();
      expect(find.byType(QrTreasureHuntView), findsNothing);
      expect(prompt, findsOneWidget);
      await tester.tap(find.text('Allow the camera'));
      await tester.pumpAndSettle();
      expect(find.byType(QrTreasureHuntView), findsOneWidget);
      expect(scanner.starts, 0);
    });

    testWidgets('with a checkpoint it plays; Change checkpoint sets anew', (
      tester,
    ) async {
      final scanner = FakeCodeScanner();
      final camera = FakeCameraAccess(current: DeviceAccess.ready);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await CapyWakeRepository(db).saveQrCheckpoint(
        QrCheckpoint.of('MIRROR', savedAt: DateTime.utc(2026)),
      );
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cameraAccessProvider.overrideWithValue(camera),
          codeScannerProvider.overrideWithValue(scanner),
        ],
      );
      addTearDown(c.dispose);
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GamePracticeScreen(gameId: 'qr_treasure_hunt'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrTreasureHuntView), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('qr-hunt-scan')));
      await tester.pump();
      scanner.show('MIRROR');
      await tester.pumpAndSettle();
      expect(find.byType(GameWinPanel), findsOneWidget);

      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Change checkpoint'));
      await tester.tap(find.text('Change checkpoint'));
      await tester.pumpAndSettle();
      expect(find.text('Scan a code'), findsOneWidget);
    });

    testWidgets('an alarm ringing above releases the camera (R1)', (
      tester,
    ) async {
      final scanner = FakeCodeScanner();
      final ringing = StreamController<RingingSession?>.broadcast();
      addTearDown(ringing.close);
      final c = await _pump(
        tester,
        'qr_treasure_hunt',
        camera: FakeCameraAccess(current: DeviceAccess.ready),
        scanner: scanner,
        ringing: ringing.stream,
      );
      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      expect(scanner.isLive, isTrue);
      ringing.add(_session());
      await tester.pump();
      await tester.pump();
      expect(scanner.isLive, isFalse);
      scanner.showLate('SOMETHING-ELSE');
      await tester.pumpAndSettle();
      expect(
        await c.read(capywakeRepositoryProvider).getQrCheckpoint(),
        isNull,
        reason: 'a code seen during a ring is never a new checkpoint',
      );
    });

    testWidgets('a late code after Stop is never saved (R6)', (tester) async {
      final scanner = FakeCodeScanner();
      final c = await _pump(
        tester,
        'qr_treasure_hunt',
        camera: FakeCameraAccess(current: DeviceAccess.ready),
        scanner: scanner,
      );
      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      await tester.tap(find.text('Stop camera'));
      await tester.pump();
      scanner.showLate('LATE');
      await tester.pumpAndSettle();
      expect(
        await c.read(capywakeRepositoryProvider).getQrCheckpoint(),
        isNull,
      );
    });

    testWidgets('a failed save says so and can be retried (R8)', (
      tester,
    ) async {
      final scanner = FakeCodeScanner();
      await _pump(
        tester,
        'qr_treasure_hunt',
        camera: FakeCameraAccess(current: DeviceAccess.ready),
        scanner: scanner,
        repository: _FailingRepository.new,
      );
      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      scanner.show('MIRROR');
      await tester.pumpAndSettle();
      expect(find.text('Could not save the checkpoint. Try again.'), findsOne);
      await tester.tap(find.text('Scan a code'));
      await tester.pump();
      expect(scanner.isLive, isTrue, reason: 'not stuck');
    });

    testWidgets('Not now can be taken back (R9)', (tester) async {
      final camera = FakeCameraAccess(current: DeviceAccess.needsPermission);
      await _pump(tester, 'qr_treasure_hunt', camera: camera);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow the camera'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('camera-access-prompt')), findsOne);
    });

    testWidgets('changing the checkpoint can be cancelled (R9)', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        'qr_treasure_hunt',
        camera: FakeCameraAccess(current: DeviceAccess.ready),
      );
      expect(find.text('Cancel'), findsNothing, reason: 'nothing to keep');
      await c
          .read(capywakeRepositoryProvider)
          .saveQrCheckpoint(QrCheckpoint.of('A', savedAt: DateTime.utc(2026)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Change checkpoint'));
      await tester.tap(find.text('Change checkpoint'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(QrTreasureHuntView), findsOneWidget);
    });
  });
}

class _FailingRepository extends CapyWakeRepository {
  _FailingRepository(super.db);

  @override
  Future<void> saveQrCheckpoint(QrCheckpoint checkpoint, {DateTime? now}) =>
      Future.error(Exception('disk full'));
}

RingingSession _session() {
  final t = DateTime.utc(2026, 5, 21, 5);
  return RingingSession(
    alarm: Alarm(
      id: 'a1',
      label: '',
      enabled: true,
      targetTimeMinutes: 7 * 60,
      repeatWeekdays: const {},
      wakeMode: WakeMode.standard,
      wakeWindowStartMinutesBefore: 0,
      soundId: 'gentle',
      vibrationEnabled: true,
      snoozeEnabled: true,
      snoozeDurationMinutes: 9,
      maxSnoozes: 5,
      dismissMethod: DismissMethod.puzzle,
      dismissChallengeDifficulty: null,
      confirmationEnabled: false,
      createdAt: t,
      updatedAt: t,
    ),
    occurrence: AlarmOccurrence(
      id: 'o1',
      alarmId: 'a1',
      scheduledAt: t,
      softStartAt: null,
      status: AlarmStatus.triggered,
      triggeredAt: t,
      dismissedAt: null,
      snoozeCount: 0,
      note: '',
    ),
    snoozeAvailable: false,
    isFinalAlarm: false,
    escapeVisibility: PuzzleEscapeVisibility.available,
  );
}

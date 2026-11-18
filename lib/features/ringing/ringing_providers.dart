import 'package:capywake/core/lifecycle/alarm_status_service.dart';
import 'package:capywake/core/lifecycle/snooze_service.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/ringing/ringing_controller.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// The live ringing controller. Alive only while watched — an unwatched
/// provider is disposed and listens to no `ringingStream`.
final ringingControllerProvider = Provider<RingingController>(
  (ref) {
    final controller = RingingController(
      engine: ref.watch(alarmEngineProvider),
      repository: ref.watch(capywakeRepositoryProvider),
      statusService: const AlarmStatusService(),
      snoozeService: const SnoozeService(),
      readPuzzleSettings: () =>
          ref.read(puzzleSettingsStreamProvider).value ??
          PuzzleSettings.defaults(),
      readLocation: () => ref.read(scheduleLocationProvider),
      uuid: _uuid.v4,
      now: ref.watch(engineNowProvider),
      motionSensor: ref.watch(motionSensorProvider),
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
  dependencies: [
    alarmEngineProvider,
    capywakeRepositoryProvider,
    puzzleSettingsStreamProvider,
    scheduleLocationProvider,
    engineNowProvider,
    motionSensorProvider,
  ],
);

/// The live session, or `null` when nothing is ringing.
final ringingSessionProvider = StreamProvider<RingingSession?>((ref) {
  final controller = ref.watch(ringingControllerProvider);
  return controller.sessionStream;
}, dependencies: [ringingControllerProvider]);

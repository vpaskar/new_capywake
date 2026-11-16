import 'dart:async';

import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/lifecycle/alarm_status_service.dart';
import 'package:capywake/core/lifecycle/snooze_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:timezone/timezone.dart' as tz;

/// Drives the ringing surface. Transitions are serialized per alarm id by
/// [_inFlight], then re-checked against terminal status — see PHASE_06_PLAN.
class RingingController {
  // Dart cannot pass a private named initializing formal (`this._engine`).
  // ignore_for_file: prefer_initializing_formals
  RingingController({
    required AlarmEngine engine,
    required CapyWakeRepository repository,
    required AlarmStatusService statusService,
    required SnoozeService snoozeService,
    required PuzzleSettings Function() readPuzzleSettings,
    required tz.Location Function() readLocation,
    required String Function() uuid,
    required DateTime Function() now,
  }) : _engine = engine,
       _repository = repository,
       _readPuzzleSettings = readPuzzleSettings,
       _readLocation = readLocation,
       _uuid = uuid,
       _now = now,
       _status = statusService,
       _snooze = snoozeService {
    _ringingSubscription = engine.ringingStream.listen(_onRinging);
  }

  final AlarmEngine _engine;
  final CapyWakeRepository _repository;
  final AlarmStatusService _status;
  final SnoozeService _snooze;
  final PuzzleSettings Function() _readPuzzleSettings;
  final tz.Location Function() _readLocation;
  final String Function() _uuid;
  final DateTime Function() _now;

  StreamSubscription<RingingAlarm>? _ringingSubscription;
  final _sessionController = StreamController<RingingSession?>.broadcast();

  /// Alarm ids with a transition in flight.
  final _inFlight = <String>{};

  /// Occurrences whose escape is raised to prominent. Keyed by occurrence,
  /// not held on the session, which is null between a snooze and its re-ring.
  final _prominentEscapes = <String>{};

  RingingSession? _current;

  /// The live session, or `null` when nothing is ringing.
  RingingSession? get currentSession => _current;

  /// Broadcast stream of the live session. Emits `null` when a ring ends.
  Stream<RingingSession?> get sessionStream => _sessionController.stream;

  Future<void> _onRinging(RingingAlarm event) async {
    if (!_claim(event.alarmId)) return;
    try {
      final alarm = await _repository.getAlarm(event.alarmId);
      // Deleted while the platform alarm was still armed. Bail honestly; the
      // coordinator cancels it on the next sync.
      if (alarm == null) return;

      final existing = await _findOccurrence(
        alarm: alarm,
        firedAt: event.firedAt,
      );
      if (existing != null && existing.status.isTerminal) return;
      if (existing != null && existing.status == AlarmStatus.triggered) {
        _emit(_sessionFor(alarm: alarm, occurrence: existing));
        return;
      }

      final occurrence =
          existing ?? _newOccurrence(alarm: alarm, firedAt: event.firedAt);
      final triggered = _status.trigger(
        occurrence: occurrence,
        now: event.firedAt,
      );
      await _repository.upsertOccurrence(triggered);
      _emit(_sessionFor(alarm: alarm, occurrence: triggered));
    } finally {
      _release(event.alarmId);
    }
  }

  /// Stop the alarm. Terminal.
  Future<void> dismiss() => _terminate(_status.dismiss);

  /// Stop the alarm without solving the puzzle. Recorded as
  /// [AlarmStatus.escaped], not a dismiss, and asks nothing further.
  Future<void> escape() => _terminate(_status.escape);

  Future<void> _terminate(
    AlarmOccurrence Function({
      required AlarmOccurrence occurrence,
      required DateTime now,
    })
    transition,
  ) async {
    final session = _current;
    if (session == null) return;
    if (!_claim(session.alarm.id)) return;
    try {
      // Re-read after the claim: another path may have terminated it.
      final live = _current;
      if (live == null || live.alarm.id != session.alarm.id) return;
      if (live.occurrence.status.isTerminal) return;

      final next = transition(occurrence: live.occurrence, now: _now());
      await _engine.cancel(live.alarm.id);
      await _repository.upsertOccurrence(_withSnoozeNote(next));
      _prominentEscapes.remove(live.occurrence.id);
      _emit(null);
    } finally {
      _release(session.alarm.id);
    }
  }

  /// Snooze the alarm. No-op when the alarm forbids it or the cap is reached.
  Future<void> snooze() async {
    final session = _current;
    if (session == null) return;
    if (!_claim(session.alarm.id)) return;
    try {
      final live = _current;
      if (live == null || live.alarm.id != session.alarm.id) return;
      if (live.occurrence.status.isTerminal) return;

      final result = _snooze.snooze(
        alarm: live.alarm,
        occurrence: live.occurrence,
        now: _now(),
      );
      final outcome = result.outcome;
      if (outcome == null) return;

      final snoozed = _status.snooze(
        occurrence: live.occurrence,
        newSnoozeCount: outcome.snoozeCount,
        nextRingAt: outcome.nextRingAt,
      );
      await _engine.cancel(live.alarm.id);
      await _repository.upsertOccurrence(_withSnoozeNote(snoozed));
      _emit(null);
    } finally {
      _release(session.alarm.id);
    }
  }

  /// Raise the escape to prominent for the rest of this occurrence — held
  /// here, not on the round, which a snooze re-ring regenerates.
  void raiseEscapeVisibility() {
    final session = _current;
    if (session == null) return;
    _prominentEscapes.add(session.occurrence.id);
    if (session.escapeVisibility == PuzzleEscapeVisibility.prominent) return;
    _emit(
      session.copyWith(escapeVisibility: PuzzleEscapeVisibility.prominent),
    );
  }

  bool _claim(String alarmId) => _inFlight.add(alarmId);

  void _release(String alarmId) => _inFlight.remove(alarmId);

  RingingSession _sessionFor({
    required Alarm alarm,
    required AlarmOccurrence occurrence,
  }) {
    final settings = alarm.resolvePuzzleSettings(_readPuzzleSettings());
    final keptProminent = _prominentEscapes.contains(occurrence.id);
    return RingingSession(
      alarm: alarm,
      occurrence: occurrence,
      snoozeAvailable: _snooze.canSnooze(alarm: alarm, occurrence: occurrence),
      isFinalAlarm: _snooze.isFinalAlarm(alarm: alarm, occurrence: occurrence),
      escapeVisibility: keptProminent
          ? PuzzleEscapeVisibility.prominent
          : settings.escapeVisibilityFor(
              PuzzleEasingState.start(settings.difficulty),
            ),
    );
  }

  /// Two keys: a snooze re-ring resolves to a target the morning's row was
  /// never stored under, so a snoozed row matches on its pending ring first.
  Future<AlarmOccurrence?> _findOccurrence({
    required Alarm alarm,
    required DateTime firedAt,
  }) async {
    final target = _targetFor(alarm: alarm, firedAt: firedAt);
    final fired = firedAt.toUtc();
    final rows = await _repository.listOccurrencesForAlarm(alarm.id);

    for (final row in rows) {
      if (row.status != AlarmStatus.snoozed) continue;
      if (!row.nextRingAt.isAfter(fired)) return row;
    }
    for (final row in rows) {
      if (row.scheduledAt.toUtc().isAtSameMomentAs(target)) return row;
    }
    return null;
  }

  AlarmOccurrence _newOccurrence({
    required Alarm alarm,
    required DateTime firedAt,
  }) => AlarmOccurrence(
    id: _uuid(),
    alarmId: alarm.id,
    scheduledAt: _targetFor(alarm: alarm, firedAt: firedAt),
    softStartAt: null,
    status: AlarmStatus.scheduled,
    triggeredAt: null,
    dismissedAt: null,
    snoozeCount: 0,
    note: '',
  );

  DateTime _targetFor({required Alarm alarm, required DateTime firedAt}) {
    final location = _readLocation();
    return AlarmScheduleService.targetForRing(
      alarm: alarm,
      firedAt: tz.TZDateTime.from(firedAt, location),
      location: location,
    ).toUtc();
  }

  /// Locale-free stored shape; the UI re-pluralises at render time.
  AlarmOccurrence _withSnoozeNote(AlarmOccurrence occurrence) {
    if (occurrence.snoozeCount == 0) return occurrence;
    final note = 'snoozed:${occurrence.snoozeCount}';
    if (note == occurrence.note) return occurrence;
    return occurrence.copyWith(note: note);
  }

  void _emit(RingingSession? session) {
    _current = session;
    if (!_sessionController.isClosed) _sessionController.add(session);
  }

  Future<void> dispose() async {
    await _ringingSubscription?.cancel();
    _ringingSubscription = null;
    if (!_sessionController.isClosed) await _sessionController.close();
  }
}

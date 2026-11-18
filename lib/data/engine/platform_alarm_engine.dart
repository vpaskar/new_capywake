import 'dart:async';

import 'package:alarm/alarm.dart' as plugin;
import 'package:alarm/utils/alarm_set.dart' as plugin_set;
import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:capywake/data/engine/alarm_plan_mapper.dart';
import 'package:timezone/timezone.dart' as tz;

/// `package:alarm` behind [AlarmEngine]; decisions are in [AlarmPlanMapper].
/// A refusal is raised, not swallowed. No iOS alarm survives termination.
class PlatformAlarmEngine implements AlarmEngine {
  // Dart cannot pass a private named initializing formal (`this._title`).
  // ignore_for_file: prefer_initializing_formals
  PlatformAlarmEngine({
    required String Function(Alarm alarm) title,
    required String Function(Alarm alarm) body,
    required tz.Location Function() location,
    DateTime Function()? now,
  }) : _title = title,
       _body = body,
       _location = location,
       _now = now ?? DateTime.now;

  final String Function(Alarm alarm) _title;
  final String Function(Alarm alarm) _body;
  final tz.Location Function() _location;
  final DateTime Function() _now;

  final _ringing = StreamController<RingingAlarm>.broadcast();
  StreamSubscription<plugin_set.AlarmSet>? _pluginRinging;
  final _armed = <String, DateTime>{};
  final _reportedRinging = <String>{};
  var _disposed = false;

  /// Start the plugin and forward its ring events.
  Future<void> initialize() async {
    await plugin.Alarm.init();
    _pluginRinging ??= plugin.Alarm.ringing.listen(_onRinging);
  }

  /// Localizes the notice the plugin posts when the app is force-quit with an
  /// alarm armed; its English default blames the user.
  Future<void> setKillWarning({required String title, required String body}) =>
      plugin.Alarm.setWarningNotificationOnKill(title, body);

  /// `Alarm.ringing` is a seeded `BehaviorSubject`, so a late subscriber
  /// replays the current set — reporting one ring twice without this.
  void _onRinging(plugin_set.AlarmSet set) {
    if (_disposed) return;
    final current = <String>{};
    for (final settings in set.alarms) {
      final alarmId = AlarmPlanMapper.alarmIdFromPayload(settings.payload);
      if (alarmId == null) continue;
      current.add(alarmId);
      if (_reportedRinging.contains(alarmId)) continue;
      _ringing.add(RingingAlarm(alarmId: alarmId, firedAt: _now().toUtc()));
    }
    _reportedRinging
      ..clear()
      ..addAll(current);
  }

  @override
  Future<void> arm(AlarmOccurrencePlan plan) async {
    final alarm = plan.alarm;
    final at = AlarmPlanMapper.armKeyFor(plan);
    if (_armed[alarm.id] == at) return;
    try {
      await plugin.Alarm.set(
        alarmSettings: AlarmPlanMapper.settingsFor(
          plan,
          title: _title(alarm),
          body: _body(alarm),
          now: _now(),
        ),
      );
      _armed[alarm.id] = at;
    } on Object catch (error) {
      _armed.remove(alarm.id);
      throw AlarmPlanMapper.engineException('arm', error);
    }
  }

  @override
  Future<void> ringNow(Alarm alarm) async {
    try {
      await plugin.Alarm.set(
        alarmSettings: AlarmPlanMapper.settingsFor(
          AlarmPlanMapper.immediatePlan(
            alarm: alarm,
            now: _now(),
            location: _location(),
          ),
          title: _title(alarm),
          body: _body(alarm),
          now: _now(),
        ),
      );
    } on Object catch (error) {
      throw AlarmPlanMapper.engineException('ringNow', error);
    }
  }

  @override
  Future<void> cancel(String alarmId) async {
    try {
      await plugin.Alarm.stop(AlarmPlanMapper.platformId(alarmId));
      _armed.remove(alarmId);
      _reportedRinging.remove(alarmId);
    } on Object catch (error) {
      throw AlarmPlanMapper.engineException('cancel', error);
    }
  }

  /// Leaves a ringing alarm alone: a ring's own write re-runs the schedule,
  /// and stopping everything here silenced every alarm as it started.
  @override
  Future<void> rescheduleAll(List<AlarmOccurrencePlan> plans) async {
    final ringing = {..._reportedRinging};
    try {
      final stored = await plugin.Alarm.getAlarms();
      for (final id in AlarmPlanMapper.platformIdsToStop(
        stored: [for (final a in stored) (id: a.id, payload: a.payload)],
        ringing: ringing,
      )) {
        await plugin.Alarm.stop(id);
      }
    } on Object catch (error) {
      throw AlarmPlanMapper.engineException('rescheduleAll', error);
    }
    _armed.removeWhere((id, _) => !ringing.contains(id));
    for (final plan in AlarmPlanMapper.plansToArm(plans, ringing: ringing)) {
      await arm(plan);
    }
  }

  @override
  Stream<RingingAlarm> get ringingStream => _ringing.stream;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _pluginRinging?.cancel();
    _pluginRinging = null;
    await _ringing.close();
  }
}

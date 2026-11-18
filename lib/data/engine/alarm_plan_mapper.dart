import 'package:alarm/alarm.dart' as plugin;
import 'package:capywake/core/alarm_sound.dart';
import 'package:capywake/core/engine/alarm_engine.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/schedule/alarm_schedule_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Every decision about what an [AlarmOccurrencePlan] becomes on the platform,
/// split from the plugin shell so the decisions are testable without a device.
abstract final class AlarmPlanMapper {
  /// Lower bound the plugin accepts for a fade. A zero-length fade is a fixed
  /// volume, not a ramp.
  static const minimumFade = Duration(seconds: 1);

  /// The plugin's `int` key for a UUID. Stable across restarts, or a reboot
  /// would cancel the wrong alarm. FNV-1a masked to 31 bits to stay positive.
  static int platformId(String alarmId) {
    const prime = 0x01000193;
    const offset = 0x811C9DC5;
    var hash = offset;
    for (final code in alarmId.codeUnits) {
      hash = ((hash ^ (code & 0xFF)) * prime) & 0xFFFFFFFF;
      hash = ((hash ^ ((code >> 8) & 0xFF)) * prime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  /// The audio asset for [alarm], or `null` for the device default.
  static String? audioPathFor(Alarm alarm) =>
      AlarmSoundCatalog.resolve(alarm.soundId).assetPath;

  /// Volume for [plan]: a wake window fades across its ramp, anything else is
  /// fixed. Never enforces system volume over the user's own setting.
  static plugin.VolumeSettings volumeFor(AlarmOccurrencePlan plan) {
    final ramp = plan.rampWindow;
    if (ramp < minimumFade) return const plugin.VolumeSettings.fixed();
    return plugin.VolumeSettings.fade(fadeDuration: ramp);
  }

  /// The complete plugin settings for [plan]. [title] and [body] arrive
  /// already localized; no user-facing copy is composed here.
  static plugin.AlarmSettings settingsFor(
    AlarmOccurrencePlan plan, {
    required String title,
    required String body,
    required DateTime now,
  }) {
    final alarm = plan.alarm;
    return plugin.AlarmSettings(
      id: platformId(alarm.id),
      dateTime: ringAtFor(plan, now: now),
      volumeSettings: volumeFor(plan),
      notificationSettings: plugin.NotificationSettings(
        title: title,
        body: body,
      ),
      assetAudioPath: audioPathFor(alarm),
      vibrate: alarm.vibrationEnabled,
      payload: alarm.id,
    );
  }

  /// When to start ringing [plan], floored to [now]: Android fires a past
  /// `setAlarmClock` trigger immediately, so a started window is joined late.
  static DateTime ringAtFor(AlarmOccurrencePlan plan, {required DateTime now}) {
    final ringAt = plan.ringAtUtc;
    return ringAt.isBefore(now.toUtc()) ? now.toUtc() : ringAt;
  }

  /// A plan that rings [alarm] now. Carries no soft start whatever the wake
  /// mode — fading an immediate ring in would answer it with near-silence.
  static AlarmOccurrencePlan immediatePlan({
    required Alarm alarm,
    required DateTime now,
    required tz.Location location,
  }) {
    final at = tz.TZDateTime.from(now, location);
    return AlarmOccurrencePlan(
      alarm: alarm,
      scheduled: at,
      softStart: null,
      location: location,
    );
  }

  /// The key arming idempotence is judged on: the plan's own instant, never
  /// the floored ring time, which moves on every call for a past-due plan.
  static DateTime armKeyFor(AlarmOccurrencePlan plan) => plan.ringAtUtc;

  /// A plugin failure as the domain's exception. Diagnostic and English-only;
  /// user-facing copy comes from `ReliabilityCopyService`.
  static AlarmEngineException engineException(
    String operation,
    Object cause,
  ) => AlarmEngineException('$operation failed', cause: cause);

  /// The domain id a ring event carries, or null if this app did not arm it.
  /// Read from the payload: [platformId] is a hash and has no inverse.
  static String? alarmIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    return payload;
  }

  /// Every stored platform alarm except the ones ringing right now.
  static List<int> platformIdsToStop({
    required List<({int id, String? payload})> stored,
    required Set<String> ringing,
  }) => [
    for (final alarm in stored)
      if (!ringing.contains(alarmIdFromPayload(alarm.payload))) alarm.id,
  ];

  /// A ringing alarm keeps its slot until it is stopped; the resync that
  /// stopping triggers arms its next plan.
  static List<AlarmOccurrencePlan> plansToArm(
    List<AlarmOccurrencePlan> plans, {
    required Set<String> ringing,
  }) => [
    for (final plan in plans)
      if (!ringing.contains(plan.alarm.id)) plan,
  ];
}

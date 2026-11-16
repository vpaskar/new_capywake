import 'package:capywake/core/engine/notification_service.dart';
import 'package:capywake/data/engine/notification_mapper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as plugin;
import 'package:timezone/timezone.dart' as tz;

/// `flutter_local_notifications` behind [NotificationService]: pre-alarm
/// reminders only, never the ring. Decisions are in [NotificationMapper].
class PlatformNotificationService implements NotificationService {
  // Dart cannot pass a private named initializing formal (`this._title`).
  // ignore_for_file: prefer_initializing_formals
  PlatformNotificationService({
    required String Function() channelName,
    required String Function(PendingNotification) title,
    required String Function(PendingNotification) body,
    required tz.Location Function() location,
    DateTime Function()? now,
    plugin.FlutterLocalNotificationsPlugin? pluginOverride,
  }) : _channelName = channelName,
       _title = title,
       _body = body,
       _location = location,
       _now = now ?? DateTime.now,
       _plugin = pluginOverride ?? plugin.FlutterLocalNotificationsPlugin();

  final String Function() _channelName;
  final String Function(PendingNotification) _title;
  final String Function(PendingNotification) _body;
  final tz.Location Function() _location;
  final DateTime Function() _now;
  final plugin.FlutterLocalNotificationsPlugin _plugin;

  /// Initialise the plugin. Permission is requested just-in-time instead,
  /// when the user first enables an alarm.
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const plugin.InitializationSettings(
        android: plugin.AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: plugin.DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<void> scheduleAll(List<PendingNotification> notifications) async {
    await _plugin.cancelAll();
    final location = _location();
    final details = NotificationMapper.detailsFor(channelName: _channelName());
    for (final n in NotificationMapper.upcoming(notifications, _now())) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: NotificationMapper.scheduledAt(n, location),
        notificationDetails: details,
        androidScheduleMode: NotificationMapper.scheduleMode,
        title: _title(n),
        body: _body(n),
        payload: n.alarmId,
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> dispose() async {}
}

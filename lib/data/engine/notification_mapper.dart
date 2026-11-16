import 'package:capywake/core/engine/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as plugin;
import 'package:timezone/timezone.dart' as tz;

/// Every decision in the notification adapter, kept out of the plugin shell.
abstract final class NotificationMapper {
  /// The Android channel these reminders post to.
  static const channelId = 'capywake_prealarm';

  /// Inexact on purpose: a reminder is a nudge, not the ring, and must not
  /// spend the exact-alarm budget the ring needs.
  static const plugin.AndroidScheduleMode scheduleMode =
      plugin.AndroidScheduleMode.inexactAllowWhileIdle;

  /// When [notification] should appear, in [location].
  static tz.TZDateTime scheduledAt(
    PendingNotification notification,
    tz.Location location,
  ) => tz.TZDateTime.from(notification.scheduledUtc, location);

  /// Whether [notification] is still ahead of [now]. A stale one fires at
  /// once on some platforms, which is worse than not firing.
  static bool isStillUpcoming(
    PendingNotification notification,
    DateTime now,
  ) => notification.scheduledUtc.isAfter(now.toUtc());

  /// The entries from [notifications] that should actually be scheduled.
  static List<PendingNotification> upcoming(
    List<PendingNotification> notifications,
    DateTime now,
  ) => [
    for (final n in notifications)
      if (isStillUpcoming(n, now)) n,
  ];

  /// Platform details. Low importance and silent: a nudge must not imitate
  /// the alarm it cannot be, least of all when it arrives alone.
  static plugin.NotificationDetails detailsFor({required String channelName}) {
    return plugin.NotificationDetails(
      android: plugin.AndroidNotificationDetails(
        channelId,
        channelName,
        importance: plugin.Importance.low,
        priority: plugin.Priority.low,
      ),
      iOS: const plugin.DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
    );
  }
}

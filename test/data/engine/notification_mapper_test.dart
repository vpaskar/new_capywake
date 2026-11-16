import 'package:capywake/core/engine/notification_service.dart';
import 'package:capywake/data/engine/notification_mapper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as plugin;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

PendingNotification _pending({
  required DateTime at,
  int id = 1,
  String alarmId = 'a1',
}) => PendingNotification(
  id: id,
  alarmId: alarmId,
  kind: NotificationKind.softWakeStart,
  scheduledUtc: at,
  payloadAlarmTimeUtc: at.add(const Duration(minutes: 15)),
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('scheduleMode', () {
    test('a reminder is inexact on purpose', () {
      expect(
        NotificationMapper.scheduleMode,
        plugin.AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });

    test('never claims an exact-alarm slot the ring needs', () {
      expect(
        NotificationMapper.scheduleMode,
        isNot(plugin.AndroidScheduleMode.alarmClock),
      );
      expect(
        NotificationMapper.scheduleMode,
        isNot(plugin.AndroidScheduleMode.exact),
      );
    });
  });

  group('isStillUpcoming', () {
    final now = DateTime.utc(2026, 3, 2, 6);

    test('a future reminder is upcoming', () {
      expect(
        NotificationMapper.isStillUpcoming(
          _pending(at: now.add(const Duration(minutes: 1))),
          now,
        ),
        isTrue,
      );
    });

    test('a past reminder is not', () {
      expect(
        NotificationMapper.isStillUpcoming(
          _pending(at: now.subtract(const Duration(minutes: 1))),
          now,
        ),
        isFalse,
      );
    });

    test('one due exactly now is not, so it cannot fire late and loud', () {
      expect(
        NotificationMapper.isStillUpcoming(_pending(at: now), now),
        isFalse,
      );
    });
  });

  group('upcoming', () {
    final now = DateTime.utc(2026, 3, 2, 6);

    test('drops the stale entries and keeps the rest in order', () {
      final result = NotificationMapper.upcoming([
        _pending(at: now.subtract(const Duration(hours: 1))),
        _pending(id: 2, at: now.add(const Duration(hours: 1))),
        _pending(id: 3, at: now.add(const Duration(hours: 2))),
      ], now);
      expect(result.map((n) => n.id), [2, 3]);
    });

    test('an all-stale queue schedules nothing', () {
      final result = NotificationMapper.upcoming([
        _pending(at: now.subtract(const Duration(hours: 1))),
      ], now);
      expect(result, isEmpty);
    });

    test('an empty queue is empty', () {
      expect(NotificationMapper.upcoming(const [], now), isEmpty);
    });
  });

  group('scheduledAt', () {
    test('converts into the given location', () {
      final berlin = tz.getLocation('Europe/Berlin');
      final at = DateTime.utc(2026, 7, 1, 5);
      final result = NotificationMapper.scheduledAt(_pending(at: at), berlin);
      expect(result.location, berlin);
      expect(result.toUtc(), at);
      expect(result.hour, 7);
    });
  });

  group('detailsFor', () {
    test('is quiet on both platforms — it is a nudge, not an alarm', () {
      final details = NotificationMapper.detailsFor(channelName: 'Alarms');
      expect(details.android!.importance, plugin.Importance.low);
      expect(details.android!.priority, plugin.Priority.low);
      expect(details.iOS!.presentSound, isFalse);
    });

    test('carries the channel name it is given', () {
      final details = NotificationMapper.detailsFor(channelName: 'Wecker');
      expect(details.android!.channelName, 'Wecker');
      expect(details.android!.channelId, NotificationMapper.channelId);
    });
  });
}

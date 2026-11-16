import 'package:capywake/core/alarm_format.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/engine/local_location_resolver.dart';
import 'package:capywake/data/engine/platform_alarm_engine.dart';
import 'package:capywake/data/engine/platform_notification_service.dart';
import 'package:capywake/data/permissions/platform_permission_service.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// The `ProviderScope` swapping the fake engine providers for the real ones.
/// Production only: plugin init must stay out of the `bootstrap()` tests run.
Future<Widget Function(Widget)> platformEngineScope({
  required AppLocalizations l10n,
  required String localeName,
  TimeFormatPreference timeFormat = TimeFormatPreference.system,
  DateTime Function() now = DateTime.now,
}) async {
  final location = LocalLocationResolver.resolve(now()) ?? tz.UTC;
  tz.setLocalLocation(location);

  final engine = PlatformAlarmEngine(
    title: (_) => l10n.alarmRingNotificationTitle,
    body: (alarm) => l10n.alarmRingNotificationBody(
      alarm.label.isEmpty ? l10n.alarmRingNotificationTitle : alarm.label,
    ),
    location: () => location,
    now: now,
  );
  await engine.initialize();

  final notifications = PlatformNotificationService(
    channelName: () => l10n.notificationChannelName,
    title: (_) => l10n.notificationSoftWakeTitle,
    body: (n) => l10n.notificationSoftWakeBody(
      _formatClock(n.payloadAlarmTimeUtc, location, localeName, timeFormat),
    ),
    location: () => location,
    now: now,
  );
  await notifications.initialize();

  return (Widget child) => ProviderScope(
    overrides: [
      alarmEngineProvider.overrideWith((ref) {
        ref.onDispose(engine.dispose);
        return engine;
      }),
      notificationServiceProvider.overrideWith((ref) {
        ref.onDispose(notifications.dispose);
        return notifications;
      }),
      permissionServiceProvider.overrideWith(
        (ref) => PlatformPermissionService(),
      ),
      scheduleLocationProvider.overrideWith((ref) => location),
      engineNowProvider.overrideWith((ref) => now),
    ],
    child: child,
  );
}

/// Clock time for a notification body, through `AlarmFormat` like every other
/// time: a hand-rolled `HH:mm` reads wrong in half of the ten locales.
String _formatClock(
  DateTime utc,
  tz.Location location,
  String localeName,
  TimeFormatPreference format,
) {
  final local = tz.TZDateTime.from(utc, location);
  return AlarmFormat.time(
    minutes: local.hour * 60 + local.minute,
    localeName: localeName,
    format: format,
  );
}

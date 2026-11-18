import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';

/// Debug-only sample data, so Stats and the alarm list can be seen filled.
/// Every row's id starts with [idPrefix]; [remove] deletes only those.
abstract final class DemoData {
  static const idPrefix = 'demo-';
  static const historyDays = 14;

  static List<Alarm> alarms(DateTime now) {
    final stamp = now.toUtc();
    Alarm alarm(
      String id,
      int minutes,
      Set<int> repeat, {
      required bool enabled,
      String label = '',
      String? artId,
      DismissMethod dismiss = DismissMethod.normalButton,
    }) => Alarm(
      id: '$idPrefix$id',
      label: label,
      enabled: enabled,
      targetTimeMinutes: minutes,
      repeatWeekdays: repeat,
      wakeMode: WakeMode.standard,
      wakeWindowStartMinutesBefore: 0,
      soundId: '',
      vibrationEnabled: true,
      snoozeEnabled: true,
      snoozeDurationMinutes: 9,
      maxSnoozes: 3,
      dismissMethod: dismiss,
      dismissChallengeDifficulty: null,
      confirmationEnabled: false,
      artId: artId,
      createdAt: stamp,
      updatedAt: stamp,
    );

    return [
      alarm('workdays', 6 * 60 + 30, {1, 2, 3, 4, 5}, enabled: true),
      alarm(
        'gym',
        7 * 60,
        {2, 4},
        enabled: true,
        label: 'Gym',
        artId: 'thumb.workout',
        dismiss: DismissMethod.puzzle,
      ),
      alarm(
        'weekend',
        9 * 60,
        {6, 7},
        enabled: false,
        artId: Alarm.noArtId,
      ),
    ];
  }

  /// Finished occurrences over the last [historyDays], every status the
  /// history summary counts, so each Stats tile has something to show.
  static List<AlarmOccurrence> history(List<Alarm> alarms, DateTime now) {
    const pattern = [
      (AlarmStatus.dismissed, 0),
      (AlarmStatus.dismissed, 1),
      (AlarmStatus.dismissed, 0),
      (AlarmStatus.skipped, 0),
      (AlarmStatus.dismissed, 2),
      (AlarmStatus.escaped, 0),
      (AlarmStatus.missed, 0),
    ];
    final today = DateTime(now.year, now.month, now.day);
    final rows = <AlarmOccurrence>[];

    for (var day = 1; day <= historyDays; day++) {
      final date = today.subtract(Duration(days: day));
      for (final alarm in alarms) {
        if (alarm.repeatWeekdays.isNotEmpty &&
            !alarm.repeatWeekdays.contains(date.weekday)) {
          continue;
        }
        final (status, snoozes) = pattern[(day + rows.length) % pattern.length];
        final scheduled = date.add(Duration(minutes: alarm.targetTimeMinutes));
        final rang = status != AlarmStatus.skipped;
        final finishedAfter = Duration(
          minutes: snoozes * alarm.snoozeDurationMinutes + 1,
        );
        rows.add(
          AlarmOccurrence(
            id: '$idPrefix${alarm.id}-$day',
            alarmId: alarm.id,
            scheduledAt: scheduled.toUtc(),
            softStartAt: scheduled.toUtc(),
            status: status,
            triggeredAt: rang ? scheduled.toUtc() : null,
            dismissedAt: status == AlarmStatus.dismissed
                ? scheduled.add(finishedAfter).toUtc()
                : null,
            snoozeCount: snoozes,
            note: '',
          ),
        );
      }
    }
    return rows;
  }

  static Future<void> add(CapyWakeRepository repository, DateTime now) async {
    final demoAlarms = alarms(now);
    for (final alarm in demoAlarms) {
      await repository.upsertAlarm(alarm);
    }
    for (final occurrence in history(demoAlarms, now)) {
      await repository.upsertOccurrence(occurrence);
    }
  }

  /// Deleting an alarm cascades to its occurrences.
  static Future<void> remove(CapyWakeRepository repository) async {
    for (final alarm in await repository.listAlarms()) {
      if (alarm.id.startsWith(idPrefix)) {
        await repository.deleteAlarm(alarm.id);
      }
    }
  }
}

import 'package:capywake/core/history/history_service.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/database/mappers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/dev/demo_data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 18, 12);

  late AppDatabase db;
  late CapyWakeRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CapyWakeRepository(db);
  });
  tearDown(() => db.close());

  test('history is finished, in the past, and covers every outcome', () {
    final rows = DemoData.history(DemoData.alarms(now), now);

    expect(rows, isNotEmpty);
    expect(rows.every((o) => o.status.isTerminal), isTrue);
    expect(rows.every((o) => o.scheduledAt.isBefore(now.toUtc())), isTrue);
    expect(
      rows.map((o) => o.status).toSet(),
      containsAll(<AlarmStatus>{
        AlarmStatus.dismissed,
        AlarmStatus.skipped,
        AlarmStatus.escaped,
        AlarmStatus.missed,
      }),
    );
    expect(rows.any((o) => o.snoozeCount > 0), isTrue);
    expect(rows.map((o) => o.id).toSet(), hasLength(rows.length));
  });

  test('added data fills the Stats summary', () async {
    await DemoData.add(repository, now);

    final summary = HistoryService.summarise(
      occurrences: await db
          .select(db.alarmOccurrences)
          .get()
          .then(
            (r) => r.map(AlarmOccurrenceMapper.fromRow).toList(),
          ),
      alarms: await repository.listAlarms(),
      now: now,
    );
    expect(summary.occurrenceCount, greaterThan(0));
  });

  test("remove deletes only demo rows, never the user's own", () async {
    final own = DemoData.alarms(now).first.copyWith(id: 'mine');
    await repository.upsertAlarm(own);
    await DemoData.add(repository, now);
    await DemoData.add(repository, now);

    await DemoData.remove(repository);

    expect((await repository.listAlarms()).map((a) => a.id), ['mine']);
    expect(await db.select(db.alarmOccurrences).get(), isEmpty);
  });
}

import 'package:capywake/data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a fresh database is the only supported origin', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Asserting `schemaVersion == 1` alone would be the wrong guard: the phase
    // that legitimately adds migration v2 would just bump the number, and the
    // reason v1 was chosen would leave the codebase with nothing in its place.
    // CapyWake shipped no earlier schema, so there is no version to upgrade
    // from. A phase that adds a real migration deletes this test deliberately.
    //
    // `onUpgrade` is never null — drift substitutes a default closure that
    // throws when a database declares no upgrade path — so the guard is that
    // attempting an upgrade fails rather than that the field is absent.
    expect(db.schemaVersion, 1);
    await expectLater(
      db.migration.onUpgrade(drift.Migrator(db), 1, 2),
      throwsA(anything),
      reason:
          'The legacy app had six schema versions. CapyWake is greenfield with '
          'zero users, so it does not inherit migrations for data nobody has, '
          'and no upgrade from any earlier version is supported.',
    );
  });

  test('the created schema holds exactly the mapped columns', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    Future<Set<String>> columnsOf(String table) async {
      final rows = await db
          .customSelect(
            'SELECT name FROM pragma_table_info(?)',
            variables: [
              drift.Variable<String>(table),
            ],
          )
          .get();
      return rows.map((r) => r.read<String>('name')).toSet();
    }

    // The legacy dropped these two at v3 → v4 by rebuilding each table, so
    // they survive only in its migration history and not in its table classes.
    // Starting fresh at v1 with createAll() would silently resurrect either one
    // if it were still declared, and the mappers never read them — a column
    // nothing reads is exactly the unbacked claim that drop removed.
    expect(
      await columnsOf('alarms'),
      isNot(contains('final_alarm_minutes_after')),
    );
    expect(await columnsOf('alarm_occurrences'), isNot(contains('final_at')));

    expect(await columnsOf('alarms'), {
      'id',
      'label',
      'enabled',
      'target_time_minutes',
      'repeat_weekdays_csv',
      'wake_mode',
      'wake_window_start_minutes_before',
      'sound_id',
      'vibration_enabled',
      'snooze_enabled',
      'snooze_duration_minutes',
      'max_snoozes',
      'dismiss_method',
      'dismiss_challenge_difficulty',
      'puzzle_override_json',
      'confirmation_enabled',
      'motion_confirmation_enabled',
      'art_id',
      'created_at',
      'updated_at',
    });

    expect(await columnsOf('alarm_occurrences'), {
      'id',
      'alarm_id',
      'scheduled_at',
      'soft_start_at',
      'status',
      'triggered_at',
      'dismissed_at',
      'snoozed_until',
      'snooze_count',
      'note',
      'is_motion_re_ring',
    });

    expect(await columnsOf('singletons'), {
      'singleton_key',
      'value_json',
      'updated_at',
    });

    expect(await columnsOf('sleep_nights'), {
      'night',
      'asleep_at',
      'woke_at',
      'total_asleep_minutes',
      'time_in_bed_minutes',
      'asleep_minutes',
      'deep_minutes',
      'light_minutes',
      'rem_minutes',
      'awake_minutes',
      'in_bed_minutes',
      'unknown_minutes',
      'source_name',
      'synced_at',
    });
  });
}

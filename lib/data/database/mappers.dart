import 'dart:convert';

import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/core/puzzle/puzzle_type.dart';
import 'package:capywake/core/sleep/sleep.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:drift/drift.dart';

/// Maps between core models and Drift rows.
///
/// The data layer is the only place enum values get serialised as strings
/// and weekday sets get joined to CSV — the core models stay clean Dart.
abstract final class AlarmMapper {
  /// Drift row → core model. Throws if the row holds an unknown enum value
  /// (we'd rather fail loudly in tests than render a half-broken alarm at
  /// 03:00).
  static Alarm fromRow(AlarmRow row) {
    return Alarm(
      id: row.id,
      label: row.label,
      enabled: row.enabled,
      targetTimeMinutes: row.targetTimeMinutes,
      repeatWeekdays: _parseWeekdays(row.repeatWeekdaysCsv),
      wakeMode: _parseWakeMode(row.wakeMode),
      wakeWindowStartMinutesBefore: row.wakeWindowStartMinutesBefore,
      soundId: row.soundId,
      vibrationEnabled: row.vibrationEnabled,
      snoozeEnabled: row.snoozeEnabled,
      snoozeDurationMinutes: row.snoozeDurationMinutes,
      maxSnoozes: row.maxSnoozes,
      dismissMethod: _parseDismissMethod(row.dismissMethod),
      dismissChallengeDifficulty: row.dismissChallengeDifficulty == null
          ? null
          : _parseDismissChallengeDifficulty(row.dismissChallengeDifficulty!),
      puzzleOverride: row.puzzleOverrideJson == null
          ? null
          : AlarmPuzzleOverrideMapper.fromJson(row.puzzleOverrideJson!),
      confirmationEnabled: row.confirmationEnabled,
      motionConfirmationEnabled: row.motionConfirmationEnabled,
      // Drift's default `DateTimeColumn` stores instants as integers and
      // rebuilds them as *local* `DateTime`s on read. Normalising to UTC
      // here keeps the round-trip value-equal across timezones (and matches
      // the model's "all stored times are UTC" contract).
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }

  /// Core model → companion ready for `into(...).insertOnConflictUpdate`.
  static AlarmsCompanion toCompanion(Alarm alarm) {
    return AlarmsCompanion(
      id: Value(alarm.id),
      label: Value(alarm.label),
      enabled: Value(alarm.enabled),
      targetTimeMinutes: Value(alarm.targetTimeMinutes),
      repeatWeekdaysCsv: Value(_encodeWeekdays(alarm.repeatWeekdays)),
      wakeMode: Value(alarm.wakeMode.name),
      wakeWindowStartMinutesBefore: Value(alarm.wakeWindowStartMinutesBefore),
      soundId: Value(alarm.soundId),
      vibrationEnabled: Value(alarm.vibrationEnabled),
      snoozeEnabled: Value(alarm.snoozeEnabled),
      snoozeDurationMinutes: Value(alarm.snoozeDurationMinutes),
      maxSnoozes: Value(alarm.maxSnoozes),
      dismissMethod: Value(alarm.dismissMethod.name),
      dismissChallengeDifficulty: Value(alarm.dismissChallengeDifficulty?.name),
      puzzleOverrideJson: Value(
        alarm.puzzleOverride == null
            ? null
            : AlarmPuzzleOverrideMapper.toJson(alarm.puzzleOverride!),
      ),
      confirmationEnabled: Value(alarm.confirmationEnabled),
      motionConfirmationEnabled: Value(alarm.motionConfirmationEnabled),
      createdAt: Value(alarm.createdAt),
      updatedAt: Value(alarm.updatedAt),
    );
  }

  static Set<int> _parseWeekdays(String csv) {
    if (csv.isEmpty) return <int>{};
    final out = <int>{};
    for (final part in csv.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final n = int.parse(trimmed);
      if (n < 1 || n > 7) {
        throw FormatException('Invalid weekday in CSV: $csv');
      }
      out.add(n);
    }
    return out;
  }

  static String _encodeWeekdays(Set<int> days) {
    if (days.isEmpty) return '';
    final sorted = days.toList()..sort();
    return sorted.join(',');
  }

  static WakeMode _parseWakeMode(String name) {
    return WakeMode.values.firstWhere(
      (v) => v.name == name,
      orElse: () => throw FormatException('Unknown WakeMode: $name'),
    );
  }

  /// Legacy stored value for what is now [DismissMethod.puzzle].
  ///
  /// Pre-pivot builds wrote `'mathChallenge'` for the math-only dismiss
  /// challenge. The generated wake puzzle replaced that mechanism entirely, so
  /// an alarm configured for it wants the puzzle — reading the old string as
  /// [DismissMethod.puzzle] preserves the user's intent ("make me solve
  /// something") without a schema migration. New rows always write `'puzzle'`.
  static const String _legacyPuzzleDismissMethod = 'mathChallenge';

  static DismissMethod _parseDismissMethod(String name) {
    if (name == _legacyPuzzleDismissMethod) return DismissMethod.puzzle;
    return DismissMethod.values.firstWhere(
      (v) => v.name == name,
      orElse: () => throw FormatException('Unknown DismissMethod: $name'),
    );
  }

  static DismissChallengeDifficulty _parseDismissChallengeDifficulty(
    String name,
  ) {
    return DismissChallengeDifficulty.values.firstWhere(
      (v) => v.name == name,
      orElse: () => throw FormatException(
        'Unknown DismissChallengeDifficulty: $name',
      ),
    );
  }
}

abstract final class AlarmOccurrenceMapper {
  static AlarmOccurrence fromRow(AlarmOccurrenceRow row) {
    return AlarmOccurrence(
      id: row.id,
      alarmId: row.alarmId,
      // Same UTC-normalisation rationale as `AlarmMapper.fromRow`.
      scheduledAt: row.scheduledAt.toUtc(),
      softStartAt: row.softStartAt?.toUtc(),
      status: _parseStatus(row.status),
      triggeredAt: row.triggeredAt?.toUtc(),
      dismissedAt: row.dismissedAt?.toUtc(),
      snoozeCount: row.snoozeCount,
      note: row.note,
      snoozedUntil: row.snoozedUntil?.toUtc(),
      isMotionReRing: row.isMotionReRing,
    );
  }

  static AlarmOccurrencesCompanion toCompanion(AlarmOccurrence occ) {
    return AlarmOccurrencesCompanion(
      id: Value(occ.id),
      alarmId: Value(occ.alarmId),
      scheduledAt: Value(occ.scheduledAt),
      softStartAt: Value(occ.softStartAt),
      status: Value(occ.status.name),
      triggeredAt: Value(occ.triggeredAt),
      dismissedAt: Value(occ.dismissedAt),
      snoozeCount: Value(occ.snoozeCount),
      note: Value(occ.note),
      snoozedUntil: Value(occ.snoozedUntil),
      isMotionReRing: Value(occ.isMotionReRing),
    );
  }

  static AlarmStatus _parseStatus(String name) {
    return AlarmStatus.values.firstWhere(
      (v) => v.name == name,
      orElse: () => throw FormatException('Unknown AlarmStatus: $name'),
    );
  }
}

/// Maps `UserSettings` ↔ JSON for the singletons table.
///
/// Hand-rolled JSON (rather than a code-generated serializer) because the
/// shape is tiny and we want to keep `lib/core` Flutter-free + free of
/// codegen dependencies. `fromJson` is tolerant of missing keys (returns
/// defaults from `UserSettings.initial`) so a future field addition does
/// not require a schema migration.
abstract final class UserSettingsMapper {
  static String toJson(UserSettings s) {
    return jsonEncode({
      'defaultWakeMode': s.defaultWakeMode.name,
      'defaultSoundId': s.defaultSoundId,
      'defaultSnoozeMinutes': s.defaultSnoozeMinutes,
      'timeFormat': s.timeFormat.name,
      'themeMode': s.themeMode.name,
      'reliabilityChecklistState': s.reliabilityChecklistState.items.map(
        (k, v) => MapEntry(k.name, v.name),
      ),
      'motionConfirmationEnabled': s.motionConfirmationEnabled,
      'hasCompletedOnboarding': s.hasCompletedOnboarding,
    });
  }

  static UserSettings fromJson(String raw) {
    const initial = UserSettings.initial;
    final map = jsonDecode(raw) as Map<String, dynamic>;

    final wakeMode = _parseEnumOr(
      WakeMode.values,
      map['defaultWakeMode'],
      initial.defaultWakeMode,
    );
    final timeFormat = _parseEnumOr(
      TimeFormatPreference.values,
      map['timeFormat'],
      initial.timeFormat,
    );
    final themeMode = _parseEnumOr(
      ThemeModePreference.values,
      map['themeMode'],
      initial.themeMode,
    );

    final checklistRaw =
        map['reliabilityChecklistState'] as Map<String, dynamic>? ?? {};
    final items = <ReliabilityChecklistItem, ChecklistItemState>{};
    for (final entry in checklistRaw.entries) {
      final item = _parseEnumOrNull(
        ReliabilityChecklistItem.values,
        entry.key,
      );
      final state = _parseEnumOrNull(
        ChecklistItemState.values,
        entry.value,
      );
      if (item != null && state != null) {
        items[item] = state;
      }
    }

    return UserSettings(
      defaultWakeMode: wakeMode,
      defaultSoundId:
          (map['defaultSoundId'] as String?) ?? initial.defaultSoundId,
      defaultSnoozeMinutes:
          (map['defaultSnoozeMinutes'] as int?) ?? initial.defaultSnoozeMinutes,
      timeFormat: timeFormat,
      themeMode: themeMode,
      reliabilityChecklistState: ReliabilityChecklistState(items: items),
      motionConfirmationEnabled:
          (map['motionConfirmationEnabled'] as bool?) ??
          initial.motionConfirmationEnabled,
      // Absent means this row was written by a build that predates onboarding
      // — so the person on the other side of it has been using CapyWake for a
      // while and must not be dropped into first-run setup by an update. A
      // genuinely fresh install has no settings row at all, so it never
      // reaches this branch and keeps the `false` from `UserSettings.initial`.
      hasCompletedOnboarding: (map['hasCompletedOnboarding'] as bool?) ?? true,
    );
  }
}

abstract final class ProStatusMapper {
  static String toJson(ProStatus s) {
    return jsonEncode({
      'isPro': s.isPro,
      'purchaseSource': s.purchaseSource.name,
      'updatedAt': s.updatedAt.toUtc().toIso8601String(),
    });
  }

  static ProStatus fromJson(String raw) {
    final initial = ProStatus.initial;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final source = _parseEnumOr(
      ProPurchaseSource.values,
      map['purchaseSource'],
      initial.purchaseSource,
    );
    final updatedAtRaw = map['updatedAt'] as String?;
    final updatedAt = updatedAtRaw == null
        ? initial.updatedAt
        : DateTime.parse(updatedAtRaw).toUtc();
    return ProStatus(
      isPro: (map['isPro'] as bool?) ?? initial.isPro,
      purchaseSource: source,
      updatedAt: updatedAt,
    );
  }
}

/// Maps the app-wide `PuzzleSettings` ↔ JSON for the singletons table.
///
/// Tolerant on read, and deliberately so: a stored type name this build does
/// not recognise (a type retired in a later version, a hand-edited database)
/// is dropped rather than thrown on, and if dropping leaves nothing the whole
/// set falls back to the defaults. The alternative is an exception on the path
/// that decides how somebody's alarm behaves at 03:00.
abstract final class PuzzleSettingsMapper {
  static String toJson(PuzzleSettings s) {
    return jsonEncode({
      'enabledTypes': s.enabledTypes.map((t) => t.name).toList(),
      'taskCount': s.taskCount,
      'difficulty': s.difficulty.name,
      'toleratedWrongAnswers': s.toleratedWrongAnswers,
      'escapeStrictness': s.escapeStrictness.name,
      'enabledGames': s.enabledGames.toList(),
      'includePuzzles': s.includePuzzles,
    });
  }

  static PuzzleSettings fromJson(String raw) {
    final defaults = PuzzleSettings.defaults();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final types = _parsePuzzleTypes(map['enabledTypes']);
    final games = _parseGameIds(map['enabledGames']) ?? const <String>{};
    return PuzzleSettings(
      enabledTypes: types ?? defaults.enabledTypes,
      taskCount:
          _parseBoundedIntOrNull(
            map['taskCount'],
            min: PuzzleSettings.minTaskCount,
            max: PuzzleSettings.maxTaskCount,
          ) ??
          defaults.taskCount,
      difficulty: _parseEnumOr(
        PuzzleDifficulty.values,
        map['difficulty'],
        defaults.difficulty,
      ),
      toleratedWrongAnswers:
          _parseBoundedIntOrNull(
            map['toleratedWrongAnswers'],
            min: PuzzleSettings.minToleratedWrongAnswers,
            max: PuzzleSettings.maxToleratedWrongAnswers,
          ) ??
          defaults.toleratedWrongAnswers,
      escapeStrictness: _parseEnumOr(
        PuzzleEscapeStrictness.values,
        map['escapeStrictness'],
        defaults.escapeStrictness,
      ),
      enabledGames: games,
      includePuzzles: games.isEmpty || map['includePuzzles'] != false,
    );
  }
}

/// Maps an `AlarmPuzzleOverride` ↔ the alarm row's JSON column.
///
/// Only the fields the user actually overrode are written, so a round-trip
/// preserves "follows the default" as an absent key rather than a frozen copy
/// of whatever the default happened to be at the time.
abstract final class AlarmPuzzleOverrideMapper {
  static String toJson(AlarmPuzzleOverride o) {
    return jsonEncode(<String, Object?>{
      if (o.enabledTypes != null)
        'enabledTypes': o.enabledTypes!.map((t) => t.name).toList(),
      if (o.taskCount != null) 'taskCount': o.taskCount,
      if (o.toleratedWrongAnswers != null)
        'toleratedWrongAnswers': o.toleratedWrongAnswers,
      if (o.escapeStrictness != null)
        'escapeStrictness': o.escapeStrictness!.name,
      if (o.enabledGames != null) 'enabledGames': o.enabledGames!.toList(),
      if (o.includePuzzles != null) 'includePuzzles': o.includePuzzles,
    });
  }

  static AlarmPuzzleOverride fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final games = _parseGameIds(map['enabledGames']);
    final includePuzzles = map['includePuzzles'];
    return AlarmPuzzleOverride(
      enabledTypes: _parsePuzzleTypes(map['enabledTypes']),
      taskCount: _parseBoundedIntOrNull(
        map['taskCount'],
        min: PuzzleSettings.minTaskCount,
        max: PuzzleSettings.maxTaskCount,
      ),
      toleratedWrongAnswers: _parseBoundedIntOrNull(
        map['toleratedWrongAnswers'],
        min: PuzzleSettings.minToleratedWrongAnswers,
        max: PuzzleSettings.maxToleratedWrongAnswers,
      ),
      escapeStrictness: _parseEnumOrNull(
        PuzzleEscapeStrictness.values,
        map['escapeStrictness'],
      ),
      enabledGames: games,
      includePuzzles:
          includePuzzles is! bool ||
              (!includePuzzles && (games?.isEmpty ?? true))
          ? null
          : includePuzzles,
    );
  }
}

/// Reads a stored puzzle-type list, dropping names this build does not know.
///
/// Returns `null` when the key is absent, is not a list, or survives filtering
/// with nothing left — all three mean "we have no usable set here", and the
/// caller decides whether that is the app defaults or an un-overridden field.
/// Never returns an empty set, because `PuzzleSettings` rightly refuses one.
Set<PuzzleType>? _parsePuzzleTypes(Object? raw) {
  if (raw is! List) return null;
  final out = <PuzzleType>{};
  for (final entry in raw) {
    final type = _parseEnumOrNull(PuzzleType.values, entry);
    if (type != null) out.add(type);
  }
  return out.isEmpty ? null : out;
}

/// Reads stored game ids, dropping ids this build does not know. Unlike puzzle
/// types an empty list is a real choice ("no games"); `null` means absent.
Set<String>? _parseGameIds(Object? raw) {
  if (raw is! List) return null;
  return {
    for (final id in raw)
      if (id is String && GameCatalogue.byId(id) != null) id,
  };
}

/// Reads a stored integer, or `null` when it is missing or out of range.
///
/// Out-of-range is treated exactly like missing rather than clamped: a value
/// outside the bounds did not come from the UI, so honouring it — even
/// squeezed into range — would be inventing an intent the user never had.
int? _parseBoundedIntOrNull(Object? raw, {required int min, required int max}) {
  if (raw is! int || raw < min || raw > max) return null;
  return raw;
}

/// Maps a cached sleep night ↔ its Drift row.
///
/// Stage minutes are stored one column per stage rather than as a JSON blob,
/// so a night can be read back without parsing and a stage the device never
/// reported stays NULL — distinguishable from a reported zero.
abstract final class SleepNightMapper {
  static SleepNight fromRow(SleepNightRow row) {
    final stages = <SleepStage, int>{};
    void put(SleepStage stage, int? minutes) {
      if (minutes != null && minutes > 0) stages[stage] = minutes;
    }

    put(SleepStage.asleep, row.asleepMinutes);
    put(SleepStage.deep, row.deepMinutes);
    put(SleepStage.light, row.lightMinutes);
    put(SleepStage.rem, row.remMinutes);
    put(SleepStage.awake, row.awakeMinutes);
    put(SleepStage.inBed, row.inBedMinutes);
    put(SleepStage.unknown, row.unknownMinutes);

    return SleepNight(
      night: row.night,
      asleepAt: row.asleepAt.toUtc(),
      wokeAt: row.wokeAt.toUtc(),
      totalAsleepMinutes: row.totalAsleepMinutes,
      timeInBedMinutes: row.timeInBedMinutes,
      sourceName: row.sourceName,
      stageMinutes: stages,
    );
  }

  static SleepNightsCompanion toCompanion(SleepNight night, {DateTime? now}) {
    Value<int?> minutes(SleepStage stage) {
      final value = night.stageMinutes[stage];
      return value == null ? const Value(null) : Value(value);
    }

    return SleepNightsCompanion(
      night: Value(night.night),
      asleepAt: Value(night.asleepAt.toUtc()),
      wokeAt: Value(night.wokeAt.toUtc()),
      totalAsleepMinutes: Value(night.totalAsleepMinutes),
      timeInBedMinutes: Value(night.timeInBedMinutes),
      asleepMinutes: minutes(SleepStage.asleep),
      deepMinutes: minutes(SleepStage.deep),
      lightMinutes: minutes(SleepStage.light),
      remMinutes: minutes(SleepStage.rem),
      awakeMinutes: minutes(SleepStage.awake),
      inBedMinutes: minutes(SleepStage.inBed),
      unknownMinutes: minutes(SleepStage.unknown),
      sourceName: Value(night.sourceName),
      syncedAt: Value((now ?? DateTime.now()).toUtc()),
    );
  }
}

/// Maps `SleepSyncState` ↔ JSON for the singletons table.
///
/// Tolerant on read, like [PuzzleSettingsMapper]: an unrecognised error name
/// reads back as "no error" rather than throwing, since a stale category must
/// never be the reason a settings screen fails to open.
abstract final class SleepSyncStateMapper {
  static String toJson(SleepSyncState s) {
    return jsonEncode({
      'enabled': s.enabled,
      'lastSyncedAt': s.lastSyncedAt?.toUtc().toIso8601String(),
      'lastError': s.lastError?.name,
    });
  }

  static SleepSyncState fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final syncedRaw = map['lastSyncedAt'] as String?;
    return SleepSyncState(
      enabled: (map['enabled'] as bool?) ?? false,
      lastSyncedAt: syncedRaw == null
          ? null
          : DateTime.tryParse(syncedRaw)?.toUtc(),
      lastError: _parseEnumOrNull(SleepSyncError.values, map['lastError']),
    );
  }
}

T _parseEnumOr<T extends Enum>(List<T> values, Object? raw, T fallback) {
  return _parseEnumOrNull(values, raw) ?? fallback;
}

T? _parseEnumOrNull<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! String) return null;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

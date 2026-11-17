import 'package:capywake/core/models/theme_mode_preference.dart';
import 'package:capywake/core/models/time_format.dart';
import 'package:capywake/core/models/wake_mode.dart';
import 'package:meta/meta.dart';

/// Tri-state for a reliability-checklist item.
///
/// `unknown` is the honest default — we have not yet checked, or the
/// platform does not let us check. `ok` and `actionRequired` are the
/// meaningful end states surfaced on the reliability checklist screen.
enum ChecklistItemState { unknown, ok, actionRequired }

/// Stable identifier for a reliability-checklist item.
///
/// Persisted as the [name] string. Listed here so the checklist surface
/// iterates them instead of keeping its own list.
enum ReliabilityChecklistItem {
  /// OS notification permission (both platforms).
  notificationPermission,

  /// Android: `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` granted.
  exactAlarmPermission,

  /// Android: app exempt from OEM battery optimisation
  /// (dontkillmyapp.com is the real failure mode here).
  batteryOptimization,

  /// Sound + media volume audible for an alarm.
  alarmVolume,

  /// Do Not Disturb / silent-mode posture (we do **not** bypass it; the
  /// checklist tells the user honestly).
  doNotDisturbPosture,
}

/// Snapshot of the reliability checklist's state.
///
/// Stored in the settings singleton so the Today / reliability screens render
/// without re-querying every plugin. The checklist surface writes it back.
@immutable
class ReliabilityChecklistState {
  const ReliabilityChecklistState({required this.items});

  /// Empty / "we have not checked yet" snapshot — the honest initial state.
  static const empty = ReliabilityChecklistState(items: {});

  /// One state per checklist item. Missing items are treated as
  /// `ChecklistItemState.unknown` by the consumer.
  final Map<ReliabilityChecklistItem, ChecklistItemState> items;

  ChecklistItemState stateOf(ReliabilityChecklistItem item) =>
      items[item] ?? ChecklistItemState.unknown;

  ReliabilityChecklistState copyWithItem(
    ReliabilityChecklistItem item,
    ChecklistItemState state,
  ) {
    final next = Map<ReliabilityChecklistItem, ChecklistItemState>.from(items);
    next[item] = state;
    return ReliabilityChecklistState(items: next);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReliabilityChecklistState) return false;
    if (other.items.length != items.length) return false;
    for (final entry in items.entries) {
      if (other.items[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    items.entries.map((e) => Object.hash(e.key, e.value)),
  );
}

/// User-wide preferences. There is exactly one row in the database — the
/// settings singleton.
@immutable
class UserSettings {
  const UserSettings({
    required this.defaultWakeMode,
    required this.defaultSoundId,
    required this.defaultSnoozeMinutes,
    required this.timeFormat,
    required this.themeMode,
    required this.reliabilityChecklistState,
    this.motionConfirmationEnabled = false,
    this.hasCompletedOnboarding = false,
  });

  /// Sensible defaults for a fresh install: Standard wake mode, no chosen
  /// sound yet, 9-minute snooze (the iOS default users recognise), follow
  /// system clock + theme, empty reliability checklist, the post-dismiss
  /// motion check off, and first-run setup not yet seen.
  static const initial = UserSettings(
    defaultWakeMode: WakeMode.standard,
    defaultSoundId: '',
    defaultSnoozeMinutes: 9,
    timeFormat: TimeFormatPreference.system,
    themeMode: ThemeModePreference.system,
    reliabilityChecklistState: ReliabilityChecklistState.empty,
  );

  /// Default wake mode for newly-created alarms.
  final WakeMode defaultWakeMode;

  /// Default sound id for newly-created alarms. Empty string = unset.
  final String defaultSoundId;

  /// Default snooze interval (minutes) for newly-created alarms.
  final int defaultSnoozeMinutes;

  /// Clock display preference.
  final TimeFormatPreference timeFormat;

  /// Theme preference.
  final ThemeModePreference themeMode;

  /// Cached reliability checklist snapshot.
  final ReliabilityChecklistState reliabilityChecklistState;

  /// The global switch for the post-dismiss "still up?" motion check.
  ///
  /// A kill switch, and it wins: with this off the check does not run for any
  /// alarm, whatever that alarm's own `motionConfirmationEnabled` says. Off by
  /// default, so nobody meets a sensor they did not ask for.
  final bool motionConfirmationEnabled;

  /// Whether the first-run setup has been seen through — either completed or
  /// deliberately skipped.
  ///
  /// Skipping counts. The flag records "this person has been offered setup",
  /// not "this person configured something", because re-showing a flow
  /// somebody already declined is the definition of nagging. The flow stays
  /// replayable from Settings for anyone who changes their mind.
  final bool hasCompletedOnboarding;

  UserSettings copyWith({
    WakeMode? defaultWakeMode,
    String? defaultSoundId,
    int? defaultSnoozeMinutes,
    TimeFormatPreference? timeFormat,
    ThemeModePreference? themeMode,
    ReliabilityChecklistState? reliabilityChecklistState,
    bool? motionConfirmationEnabled,
    bool? hasCompletedOnboarding,
  }) {
    return UserSettings(
      defaultWakeMode: defaultWakeMode ?? this.defaultWakeMode,
      defaultSoundId: defaultSoundId ?? this.defaultSoundId,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      timeFormat: timeFormat ?? this.timeFormat,
      themeMode: themeMode ?? this.themeMode,
      reliabilityChecklistState:
          reliabilityChecklistState ?? this.reliabilityChecklistState,
      motionConfirmationEnabled:
          motionConfirmationEnabled ?? this.motionConfirmationEnabled,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.defaultWakeMode == defaultWakeMode &&
        other.defaultSoundId == defaultSoundId &&
        other.defaultSnoozeMinutes == defaultSnoozeMinutes &&
        other.timeFormat == timeFormat &&
        other.themeMode == themeMode &&
        other.reliabilityChecklistState == reliabilityChecklistState &&
        other.motionConfirmationEnabled == motionConfirmationEnabled &&
        other.hasCompletedOnboarding == hasCompletedOnboarding;
  }

  @override
  int get hashCode => Object.hash(
    defaultWakeMode,
    defaultSoundId,
    defaultSnoozeMinutes,
    timeFormat,
    themeMode,
    reliabilityChecklistState,
    motionConfirmationEnabled,
    hasCompletedOnboarding,
  );
}

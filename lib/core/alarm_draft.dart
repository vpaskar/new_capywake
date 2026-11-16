import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/alarm_puzzle_override.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:meta/meta.dart';

/// Validation problems an [AlarmDraft] can surface.
///
/// Stable enum (persisted to nothing — only displayed) so the UI can map each
/// reason to a localized message via ARB without colliding with copy in the
/// model itself. Calm, plain wording lives in `lib/l10n`.
enum AlarmDraftError {
  /// `targetTimeMinutes` is outside `[0, 1440)`.
  invalidTime,

  /// `label.length` exceeds [AlarmDraft.maxLabelLength].
  labelTooLong,

  /// One or more values in `repeatWeekdays` are outside `[1, 7]`.
  invalidRepeatWeekdays,

  /// `snoozeEnabled` is true but `snoozeDurationMinutes` is outside the
  /// allowed bounds.
  snoozeDurationOutOfRange,
}

/// A simple, validated, immutable result of running [AlarmDraft.validate].
@immutable
class AlarmDraftValidation {
  const AlarmDraftValidation(this.errors);

  /// All validation errors, in a stable, predictable order.
  final List<AlarmDraftError> errors;

  /// Whether the draft can produce an [Alarm] (no errors).
  bool get isValid => errors.isEmpty;

  bool has(AlarmDraftError error) => errors.contains(error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AlarmDraftValidation) return false;
    if (other.errors.length != errors.length) return false;
    for (var i = 0; i < errors.length; i++) {
      if (other.errors[i] != errors[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(errors);
}

/// Pure form ↔ model mediator for the alarm create/edit flow.
///
/// The widget layer holds an [AlarmDraft], mutates it via [copyWith] in
/// response to user input, and asks [validate] before saving. [toAlarm]
/// produces the immutable [Alarm] from a valid draft.
///
/// [AlarmDraft] lives in `lib/core/` so it stays Flutter-free and the
/// validation rules can be unit-tested directly without a widget pump.
@immutable
class AlarmDraft {
  const AlarmDraft({
    required this.id,
    required this.label,
    required this.enabled,
    required this.targetTimeMinutes,
    required this.repeatWeekdays,
    required this.wakeMode,
    required this.wakeWindowStartMinutesBefore,
    required this.soundId,
    required this.vibrationEnabled,
    required this.snoozeEnabled,
    required this.snoozeDurationMinutes,
    required this.maxSnoozes,
    required this.dismissMethod,
    required this.dismissChallengeDifficulty,
    required this.confirmationEnabled,
    required this.createdAt,
    this.puzzleOverride,
    this.motionConfirmationEnabled = false,
  });

  /// Build a fresh draft for the create flow.
  ///
  /// Defaults follow `UserSettings` (the user's chosen defaults) and the
  /// chosen [WakeMode]'s descriptor — not hard-coded numbers — so editing
  /// "Default snooze" in Settings actually shows up in new alarms.
  factory AlarmDraft.create({
    required String id,
    required UserSettings settings,
    required DateTime now,
    int targetTimeMinutes = 7 * 60,
  }) {
    final mode = settings.defaultWakeMode;
    final descriptor = mode.descriptor;
    return AlarmDraft(
      id: id,
      label: '',
      enabled: true,
      targetTimeMinutes: targetTimeMinutes,
      repeatWeekdays: const <int>{},
      wakeMode: mode,
      wakeWindowStartMinutesBefore:
          descriptor.defaultWakeWindowStartMinutesBefore,
      soundId: settings.defaultSoundId,
      vibrationEnabled: true,
      snoozeEnabled: true,
      snoozeDurationMinutes: settings.defaultSnoozeMinutes,
      maxSnoozes: descriptor.defaultMaxSnoozes,
      dismissMethod: DismissMethod.normalButton,
      dismissChallengeDifficulty: null,
      confirmationEnabled: descriptor.confirmationRequired,
      // The global switch controls whether a per-alarm check can run.
      createdAt: now.toUtc(),
    );
  }

  /// Hydrate a draft for the edit flow from an existing alarm.
  factory AlarmDraft.fromAlarm(Alarm alarm) {
    return AlarmDraft(
      id: alarm.id,
      label: alarm.label,
      enabled: alarm.enabled,
      targetTimeMinutes: alarm.targetTimeMinutes,
      repeatWeekdays: alarm.repeatWeekdays,
      wakeMode: alarm.wakeMode,
      wakeWindowStartMinutesBefore: alarm.wakeWindowStartMinutesBefore,
      soundId: alarm.soundId,
      vibrationEnabled: alarm.vibrationEnabled,
      snoozeEnabled: alarm.snoozeEnabled,
      snoozeDurationMinutes: alarm.snoozeDurationMinutes,
      maxSnoozes: alarm.maxSnoozes,
      dismissMethod: alarm.dismissMethod,
      dismissChallengeDifficulty: alarm.dismissChallengeDifficulty,
      puzzleOverride: alarm.puzzleOverride,
      confirmationEnabled: alarm.confirmationEnabled,
      motionConfirmationEnabled: alarm.motionConfirmationEnabled,
      createdAt: alarm.createdAt,
    );
  }

  /// Maximum allowed label length. Calm, sensible — long enough for
  /// "Tuesday yoga with Marie" yet not enough for malicious bloat.
  static const int maxLabelLength = 60;

  /// Inclusive lower bound on snooze duration when snooze is enabled.
  static const int minSnoozeMinutes = 1;

  /// Inclusive upper bound on snooze duration when snooze is enabled.
  static const int maxSnoozeMinutes = 30;

  final String id;
  final String label;
  final bool enabled;
  final int targetTimeMinutes;
  final Set<int> repeatWeekdays;
  final WakeMode wakeMode;
  final int wakeWindowStartMinutesBefore;
  final String soundId;
  final bool vibrationEnabled;
  final bool snoozeEnabled;
  final int snoozeDurationMinutes;
  final int? maxSnoozes;
  final DismissMethod dismissMethod;

  /// The puzzle difficulty for this alarm, or `null` to follow the app-wide
  /// puzzle settings. See [Alarm.dismissChallengeDifficulty].
  final DismissChallengeDifficulty? dismissChallengeDifficulty;

  /// This alarm's departures from the app-wide puzzle settings, or `null` when
  /// it follows them. See [Alarm.puzzleOverride].
  final AlarmPuzzleOverride? puzzleOverride;

  final bool confirmationEnabled;

  /// Whether this alarm asks for the post-dismiss motion check. See
  /// [Alarm.motionConfirmationEnabled].
  final bool motionConfirmationEnabled;

  final DateTime createdAt;

  /// Returns a copy with the given fields replaced.
  ///
  /// `clearDismissChallengeDifficulty` and `clearMaxSnoozes` follow the same
  /// "user passed null on purpose" idiom as `Alarm.copyWith`.
  AlarmDraft copyWith({
    String? id,
    String? label,
    bool? enabled,
    int? targetTimeMinutes,
    Set<int>? repeatWeekdays,
    WakeMode? wakeMode,
    int? wakeWindowStartMinutesBefore,
    String? soundId,
    bool? vibrationEnabled,
    bool? snoozeEnabled,
    int? snoozeDurationMinutes,
    int? maxSnoozes,
    bool clearMaxSnoozes = false,
    DismissMethod? dismissMethod,
    DismissChallengeDifficulty? dismissChallengeDifficulty,
    bool clearDismissChallengeDifficulty = false,
    AlarmPuzzleOverride? puzzleOverride,
    bool clearPuzzleOverride = false,
    bool? confirmationEnabled,
    bool? motionConfirmationEnabled,
    DateTime? createdAt,
  }) {
    return AlarmDraft(
      id: id ?? this.id,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      targetTimeMinutes: targetTimeMinutes ?? this.targetTimeMinutes,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      wakeMode: wakeMode ?? this.wakeMode,
      wakeWindowStartMinutesBefore:
          wakeWindowStartMinutesBefore ?? this.wakeWindowStartMinutesBefore,
      soundId: soundId ?? this.soundId,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeDurationMinutes:
          snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      maxSnoozes: clearMaxSnoozes ? null : (maxSnoozes ?? this.maxSnoozes),
      dismissMethod: dismissMethod ?? this.dismissMethod,
      dismissChallengeDifficulty: clearDismissChallengeDifficulty
          ? null
          : (dismissChallengeDifficulty ?? this.dismissChallengeDifficulty),
      puzzleOverride: clearPuzzleOverride
          ? null
          : (puzzleOverride ?? this.puzzleOverride),
      confirmationEnabled: confirmationEnabled ?? this.confirmationEnabled,
      motionConfirmationEnabled:
          motionConfirmationEnabled ?? this.motionConfirmationEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether this alarm simply follows the app-wide puzzle settings.
  ///
  /// The form's "use my defaults" switch reads this, so the switch and the
  /// stored shape can never disagree.
  bool get followsDefaultPuzzleSettings =>
      puzzleOverride == null && dismissChallengeDifficulty == null;

  /// The puzzle configuration this draft would wake someone with. Delegates to
  /// the same resolution [Alarm.resolvePuzzleSettings] uses, so the form
  /// previews exactly what the ringing surface will do.
  PuzzleSettings resolvePuzzleSettings(PuzzleSettings defaults) {
    return AlarmPuzzleOverride.resolveFor(
      defaults: defaults,
      override: puzzleOverride,
      difficulty: dismissChallengeDifficulty,
    );
  }

  /// Switch this alarm between following the app-wide puzzle settings and
  /// carrying its own copy of them.
  ///
  /// Turning customisation **on** pins every field to what the alarm is doing
  /// right now, so nothing changes under the user at the moment they take
  /// control. Turning it **off** drops the override entirely, and the alarm
  /// starts tracking the defaults again.
  AlarmDraft withPuzzleCustomisation({
    required bool enabled,
    required PuzzleSettings defaults,
  }) {
    if (!enabled) {
      return copyWith(
        clearPuzzleOverride: true,
        clearDismissChallengeDifficulty: true,
      );
    }
    final resolved = resolvePuzzleSettings(defaults);
    return copyWith(
      puzzleOverride: AlarmPuzzleOverride.from(resolved),
      dismissChallengeDifficulty:
          DismissChallengeDifficulty.fromPuzzleDifficulty(resolved.difficulty),
    );
  }

  /// Toggle the given ISO weekday (1=Mon..7=Sun) in [repeatWeekdays] —
  /// removes it if present, adds it otherwise. Out-of-range values throw
  /// (callers should never attempt this — guarded by the UI's fixed
  /// 7-button row).
  AlarmDraft toggleWeekday(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'Weekday must be in [1, 7].',
      );
    }
    final next = Set<int>.from(repeatWeekdays);
    if (!next.remove(weekday)) {
      next.add(weekday);
    }
    return copyWith(repeatWeekdays: next);
  }

  /// Switch the wake mode and reseed the mode-controlled defaults from the
  /// new mode's descriptor. Without this, switching mode in the form would
  /// leave a Strict-mode confirmation flag on a Gentle alarm — surprising
  /// for the user and exactly the kind of footgun the descriptor exists to
  /// avoid.
  AlarmDraft withWakeMode(WakeMode mode) {
    final d = mode.descriptor;
    return AlarmDraft(
      id: id,
      label: label,
      enabled: enabled,
      targetTimeMinutes: targetTimeMinutes,
      repeatWeekdays: repeatWeekdays,
      wakeMode: mode,
      wakeWindowStartMinutesBefore: d.defaultWakeWindowStartMinutesBefore,
      soundId: soundId,
      vibrationEnabled: vibrationEnabled,
      snoozeEnabled: snoozeEnabled,
      snoozeDurationMinutes: snoozeDurationMinutes,
      maxSnoozes: d.defaultMaxSnoozes,
      dismissMethod: dismissMethod,
      dismissChallengeDifficulty: dismissChallengeDifficulty,
      confirmationEnabled: d.confirmationRequired,
      // Not mode-controlled: the motion check is a sibling of the tap
      // confirmation, not a mode default, so switching mode leaves the user's
      // own choice alone.
      motionConfirmationEnabled: motionConfirmationEnabled,
      createdAt: createdAt,
    );
  }

  /// Switch the dismiss method, dropping the per-alarm puzzle configuration
  /// when the new method is not the puzzle. Mirrors [Alarm]'s invariant.
  ///
  /// Choosing the puzzle seeds nothing: a fresh puzzle alarm follows the
  /// app-wide settings, which is both the calmer default and the one that
  /// keeps tracking the user's Settings screen as they change their mind.
  AlarmDraft withDismissMethod(DismissMethod method) {
    if (method == DismissMethod.puzzle) {
      return copyWith(dismissMethod: method);
    }
    return copyWith(
      dismissMethod: method,
      clearDismissChallengeDifficulty: true,
      clearPuzzleOverride: true,
    );
  }

  /// Validate the draft. Returns an empty [AlarmDraftValidation.errors] list
  /// when the draft is ready to save.
  AlarmDraftValidation validate() {
    final errors = <AlarmDraftError>[];

    if (targetTimeMinutes < 0 || targetTimeMinutes >= 24 * 60) {
      errors.add(AlarmDraftError.invalidTime);
    }
    if (label.length > maxLabelLength) {
      errors.add(AlarmDraftError.labelTooLong);
    }
    if (repeatWeekdays.any((d) => d < 1 || d > 7)) {
      errors.add(AlarmDraftError.invalidRepeatWeekdays);
    }
    if (snoozeEnabled &&
        (snoozeDurationMinutes < minSnoozeMinutes ||
            snoozeDurationMinutes > maxSnoozeMinutes)) {
      errors.add(AlarmDraftError.snoozeDurationOutOfRange);
    }

    return AlarmDraftValidation(errors);
  }

  /// Materialise the draft into an [Alarm] with the given `now` as the
  /// `updatedAt` stamp. Throws [StateError] if the draft is invalid — the
  /// UI must check [validate] first; this fail-loud guard prevents a
  /// misuse from silently writing a corrupt row.
  Alarm toAlarm({required DateTime now}) {
    final result = validate();
    if (!result.isValid) {
      throw StateError(
        'AlarmDraft.toAlarm called on an invalid draft: '
        '${result.errors.join(", ")}',
      );
    }
    return Alarm(
      id: id,
      label: label,
      enabled: enabled,
      targetTimeMinutes: targetTimeMinutes,
      repeatWeekdays: repeatWeekdays,
      wakeMode: wakeMode,
      wakeWindowStartMinutesBefore: wakeWindowStartMinutesBefore,
      soundId: soundId,
      vibrationEnabled: vibrationEnabled,
      snoozeEnabled: snoozeEnabled,
      snoozeDurationMinutes: snoozeDurationMinutes,
      maxSnoozes: maxSnoozes,
      dismissMethod: dismissMethod,
      dismissChallengeDifficulty: dismissChallengeDifficulty,
      puzzleOverride: puzzleOverride,
      confirmationEnabled: confirmationEnabled,
      motionConfirmationEnabled: motionConfirmationEnabled,
      createdAt: createdAt,
      updatedAt: now.toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmDraft &&
        other.id == id &&
        other.label == label &&
        other.enabled == enabled &&
        other.targetTimeMinutes == targetTimeMinutes &&
        _setEquals(other.repeatWeekdays, repeatWeekdays) &&
        other.wakeMode == wakeMode &&
        other.wakeWindowStartMinutesBefore == wakeWindowStartMinutesBefore &&
        other.soundId == soundId &&
        other.vibrationEnabled == vibrationEnabled &&
        other.snoozeEnabled == snoozeEnabled &&
        other.snoozeDurationMinutes == snoozeDurationMinutes &&
        other.maxSnoozes == maxSnoozes &&
        other.dismissMethod == dismissMethod &&
        other.dismissChallengeDifficulty == dismissChallengeDifficulty &&
        other.puzzleOverride == puzzleOverride &&
        other.confirmationEnabled == confirmationEnabled &&
        other.motionConfirmationEnabled == motionConfirmationEnabled &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    label,
    enabled,
    targetTimeMinutes,
    Object.hashAllUnordered(repeatWeekdays),
    wakeMode,
    wakeWindowStartMinutesBefore,
    soundId,
    vibrationEnabled,
    snoozeEnabled,
    snoozeDurationMinutes,
    maxSnoozes,
    dismissMethod,
    dismissChallengeDifficulty,
    puzzleOverride,
    confirmationEnabled,
    motionConfirmationEnabled,
    createdAt,
  ]);
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final v in a) {
    if (!b.contains(v)) return false;
  }
  return true;
}

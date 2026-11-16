import 'package:meta/meta.dart';

/// The three MVP wake modes (Phase 00 scope cut: 5 → 3).
///
/// Each value carries a small descriptor — its escalation profile, default
/// snooze rules, and whether the "still up?" confirmation is required — so the
/// schedule and ringing layers can read mode behaviour from the model rather
/// than scatter mode-specific `if`s across the codebase.
///
/// Persisted as the [name] string; never as the index (so reordering values is
/// a non-breaking change).
enum WakeMode {
  /// Soft, gradual wake. Long wake window, gentle escalation, generous
  /// snoozes. The default mode for the friendly daily case.
  gentle(
    descriptor: WakeModeDescriptor(
      defaultWakeWindowStartMinutesBefore: 15,
      defaultSnoozeDurationMinutes: 9,
      defaultMaxSnoozes: null,
      confirmationRequired: false,
    ),
  ),

  /// Single ring at the target time, predictable snoozes. The conventional
  /// alarm-clock behaviour.
  standard(
    descriptor: WakeModeDescriptor(
      defaultWakeWindowStartMinutesBefore: 0,
      defaultSnoozeDurationMinutes: 9,
      defaultMaxSnoozes: 5,
      confirmationRequired: false,
    ),
  ),

  /// Strict mode: short or shrinking snoozes, capped, with a "still up?"
  /// confirmation after dismiss so a sleepy tap does not lie. Pairs naturally
  /// with the wake puzzle.
  strict(
    descriptor: WakeModeDescriptor(
      defaultWakeWindowStartMinutesBefore: 0,
      defaultSnoozeDurationMinutes: 5,
      defaultMaxSnoozes: 2,
      confirmationRequired: true,
    ),
  );

  const WakeMode({required this.descriptor});

  /// Defaults + behaviour flags for this mode.
  final WakeModeDescriptor descriptor;
}

/// Defaults and behaviour flags carried by a [WakeMode].
///
/// Pure data — used by Phase 03's alarm form to seed sensible defaults and by
/// the schedule/ringing layers to decide mode-specific behaviour without
/// branching on the enum value directly.
@immutable
class WakeModeDescriptor {
  const WakeModeDescriptor({
    required this.defaultWakeWindowStartMinutesBefore,
    required this.defaultSnoozeDurationMinutes,
    required this.defaultMaxSnoozes,
    required this.confirmationRequired,
  });

  /// How many minutes before the target the wake window starts. `0` means
  /// the alarm rings exactly at the target time with no soft-start.
  final int defaultWakeWindowStartMinutesBefore;

  /// Default snooze interval in minutes.
  final int defaultSnoozeDurationMinutes;

  /// Default cap on snoozes; `null` means unlimited.
  ///
  /// This is what "the final alarm" means in CapyWake: the ring that takes
  /// the occurrence to the cap is the last one, and it is offered without a
  /// Snooze button. There is no separate clock-anchored final ring — see
  /// `SnoozeService`.
  final int? defaultMaxSnoozes;

  /// Whether a "still up?" confirmation is required after dismiss in this
  /// mode, so a sleepy tap does not lie about being up.
  final bool confirmationRequired;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WakeModeDescriptor &&
        other.defaultWakeWindowStartMinutesBefore ==
            defaultWakeWindowStartMinutesBefore &&
        other.defaultSnoozeDurationMinutes == defaultSnoozeDurationMinutes &&
        other.defaultMaxSnoozes == defaultMaxSnoozes &&
        other.confirmationRequired == confirmationRequired;
  }

  @override
  int get hashCode => Object.hash(
    defaultWakeWindowStartMinutesBefore,
    defaultSnoozeDurationMinutes,
    defaultMaxSnoozes,
    confirmationRequired,
  );
}

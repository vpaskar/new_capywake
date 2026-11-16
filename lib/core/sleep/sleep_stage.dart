/// Platform-neutral sleep vocabulary.
///
/// CapyWake measures no sleep of its own. These stages name what a *wearable*
/// already recorded and the platform health store handed over; the adapter in
/// `lib/data/sleep/` maps HealthKit / Health Connect types onto them.
///
/// Stage data is read and displayed. It never reaches alarm scheduling — the
/// health store describes a night already past, while an alarm is armed hours
/// ahead, so stage-based wake timing is a claim no phone can support.
library;

/// One stage of a recorded night.
enum SleepStage {
  /// Asleep, stage unspecified by the recording device. The common case for a
  /// phone-only or basic-band recording.
  asleep,

  deep,

  light,

  rem,

  /// Awake during the recorded window — a 03:00 waking, not the final rising.
  awake,

  /// In bed but not scored as asleep. HealthKit-only; Health Connect splits
  /// this into its own awake-in-bed / out-of-bed types.
  inBed,

  /// The device reported a stage CapyWake does not model. Kept rather than
  /// dropped so a night's total is never silently short.
  unknown;

  /// Whether this stage counts as time actually asleep.
  ///
  /// [awake], [inBed] and [unknown] do not. Used for the stage breakdown
  /// only — a night's asleep total comes from the platform, never from
  /// summing these (see `SleepNight.totalAsleepMinutes`).
  bool get isAsleep => switch (this) {
    SleepStage.asleep ||
    SleepStage.deep ||
    SleepStage.light ||
    SleepStage.rem => true,
    SleepStage.awake || SleepStage.inBed || SleepStage.unknown => false,
  };

  /// Whether this stage is a specific sleep phase rather than an
  /// undifferentiated "asleep".
  ///
  /// A device reporting only [asleep] has no breakdown worth showing, so the
  /// UI uses this to decide whether a stage section appears at all.
  bool get isPhase => switch (this) {
    SleepStage.deep || SleepStage.light || SleepStage.rem => true,
    SleepStage.asleep ||
    SleepStage.awake ||
    SleepStage.inBed ||
    SleepStage.unknown => false,
  };
}

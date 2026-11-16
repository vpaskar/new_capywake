/// Which shape a sleep duration should be rendered in.
///
/// The service picks the shape; the UI supplies the localised template, so
/// `lib/core/` stays Flutter- and ARB-free while the decision stays testable.
enum SleepDurationShape {
  /// Under one hour — render with the pluralized minutes-only string.
  minutesOnly,

  /// An hour or more — render with the "{hours}h {minutes}m" string.
  hoursAndMinutes,
}

/// A duration split into the parts the ARB templates take.
class SleepDurationParts {
  const SleepDurationParts({
    required this.shape,
    required this.hours,
    required this.minutes,
  });

  final SleepDurationShape shape;

  /// Whole hours. Zero when [shape] is [SleepDurationShape.minutesOnly].
  final int hours;

  /// Remaining minutes after [hours], or the whole duration in the
  /// minutes-only shape.
  final int minutes;
}

/// Pure splitting of a sleep duration for display.
abstract final class SleepFormat {
  /// Split [totalMinutes] into display parts.
  ///
  /// A negative input is clamped to zero: a negative night is not a thing the
  /// UI should ever have to render, and throwing here would take down History
  /// over a bad cache row.
  static SleepDurationParts split(int totalMinutes) {
    final safe = totalMinutes < 0 ? 0 : totalMinutes;
    if (safe < 60) {
      return SleepDurationParts(
        shape: SleepDurationShape.minutesOnly,
        hours: 0,
        minutes: safe,
      );
    }
    return SleepDurationParts(
      shape: SleepDurationShape.hoursAndMinutes,
      hours: safe ~/ 60,
      minutes: safe % 60,
    );
  }
}

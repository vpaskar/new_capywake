import 'package:capywake/core/models/models.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';

/// The one plain-language name for how an alarm is stopped.
///
/// Three surfaces say it — the alarm form's picker, the Alarms row, and the
/// Today card — and before Phase 37 the mapping lived privately inside the
/// form. A row that wants the same words either imports a private enum or
/// writes the `switch` again, and the second copy is where "Solve a puzzle"
/// and "Wake puzzle" start being two names for one thing.
///
/// Flutter-free apart from the generated localisations, matching
/// `AlarmRepeatSummary` and for the same reason: the wording belongs with the
/// rule that chooses it.
abstract final class AlarmDismissSummary {
  /// How this alarm is stopped, as a short label.
  static String format({
    required DismissMethod method,
    required AppLocalizations l10n,
  }) => switch (method) {
    DismissMethod.normalButton => l10n.alarmDismissMethodNormal,
    DismissMethod.holdToDismiss => l10n.alarmDismissMethodHold,
    DismissMethod.puzzle => l10n.alarmDismissMethodPuzzle,
  };
}

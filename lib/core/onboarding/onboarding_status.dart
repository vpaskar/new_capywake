/// Decides whether an install should be shown the first-run setup.
///
/// A pure predicate rather than a bare `!settings.hasCompletedOnboarding`,
/// because "is this a first run?" is answered by two independent signals and
/// getting it wrong in either direction is a real defect:
///
/// - Saying **yes** to somebody who already uses CapyWake drops them into
///   setup after an update, which is both alarming and, briefly, a screen
///   between them and their alarms.
/// - Saying **no** to a genuinely new install leaves them on an empty Today
///   screen with ten puzzle types they have never heard of, which is the
///   problem this flow exists to solve.
///
/// The flag alone cannot answer it. A person who installed CapyWake before
/// onboarding existed has no flag, and the stored-settings reader grandfathers
/// that case — but only if they ever wrote a settings row. Somebody who set an
/// alarm and never opened Settings has no row to grandfather, so the second
/// signal carries them: **if there are alarms, this is not a first run.**
///
/// The redirect being impossible while alarms exist also has a safety
/// consequence worth stating: the first-run redirect replaces the navigation
/// shell, which is what listens for a ringing alarm. Because the redirect can
/// only fire on an install with **zero** alarms, it can never be the reason a
/// ringing alarm has no surface to be stopped from. The Settings replay keeps
/// the shell alive underneath instead (it is pushed, not navigated to), so
/// that path is covered too.
abstract final class OnboardingStatus {
  /// Whether first-run setup should be shown.
  ///
  /// [hasCompletedFlag] is `UserSettings.hasCompletedOnboarding`;
  /// [hasExistingAlarms] is whether the install has any alarm at all,
  /// enabled or not.
  static bool needsOnboarding({
    required bool hasCompletedFlag,
    required bool hasExistingAlarms,
  }) => !hasCompletedFlag && !hasExistingAlarms;
}

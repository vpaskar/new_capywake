/// Theme preference for the user. Maps 1:1 to Flutter's `ThemeMode` at the UI
/// boundary; kept as a pure-Dart enum so `lib/core` stays Flutter-free.
///
/// Stored as [name].
enum ThemeModePreference {
  system,
  light,
  dark,
}

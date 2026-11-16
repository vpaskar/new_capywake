/// Clock display preference for the user.
///
/// `system` follows the OS locale's preference (resolved at the UI boundary
/// via `intl`); `h12` and `h24` are explicit overrides for users who want a
/// specific format regardless of the device setting. Stored as [name].
enum TimeFormatPreference {
  system,
  h12,
  h24,
}

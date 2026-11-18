/// The shipped version, mirroring `pubspec.yaml`; a test parses the pubspec
/// and fails on drift.
abstract final class AppVersion {
  static const value = '1.0.0';
}

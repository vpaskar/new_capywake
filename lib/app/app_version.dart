/// The shipped version, mirroring `pubspec.yaml`; a test parses the pubspec
/// and fails on drift. The mockup draws "v1.0.0"; the real version is 0.1.0.
abstract final class AppVersion {
  static const value = '0.1.0';
}

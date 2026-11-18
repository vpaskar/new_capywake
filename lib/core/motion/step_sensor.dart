import 'package:capywake/core/permissions/device_access.dart';

/// The OS step sensor (Android step detector or counter, iOS pedometer). It
/// counts steps, never who got up.
abstract class StepSensor implements DevicePermission {
  /// New steps since listening began. Listen only once [access] is ready.
  Stream<int> get steps;
}

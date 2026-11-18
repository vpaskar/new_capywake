import 'package:capywake/core/permissions/device_access.dart';

/// The camera, for scanning a checkpoint code. Only `lib/data/` talks to it.
abstract class CameraAccess implements DevicePermission {}

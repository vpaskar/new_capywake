import 'package:flutter/services.dart';

/// The device's IANA zone over CapyWake's own channel (`MainActivity.kt`,
/// `AppDelegate.swift`): the name now, and a notice whenever it changes.
abstract final class PlatformZoneChannel {
  static const methods = MethodChannel('capywake/timezone');
  static const events = EventChannel('capywake/timezone/events');

  /// One platform listener for the app's lifetime: a second one replaces the
  /// first on the native side.
  static final Stream<Object?> changes = events
      .receiveBroadcastStream()
      .handleError((Object _) {});

  static Future<String?> name() async {
    try {
      return await methods.invokeMethod<String>('name');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

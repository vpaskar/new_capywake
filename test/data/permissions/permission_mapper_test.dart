import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/data/permissions/permission_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart' as plugin;

void main() {
  group('grantOf', () {
    test('granted is granted', () {
      expect(
        PermissionMapper.grantOf(plugin.PermissionStatus.granted),
        PermissionGrant.granted,
      );
    });

    test('limited and provisional still deliver, so they are granted', () {
      expect(
        PermissionMapper.grantOf(plugin.PermissionStatus.limited),
        PermissionGrant.granted,
      );
      expect(
        PermissionMapper.grantOf(plugin.PermissionStatus.provisional),
        PermissionGrant.granted,
      );
    });

    test('denied can be asked again', () {
      expect(
        PermissionMapper.grantOf(plugin.PermissionStatus.denied),
        PermissionGrant.denied,
      );
    });

    test('restricted reads as permanently denied, not denied', () {
      expect(
        PermissionMapper.grantOf(plugin.PermissionStatus.restricted),
        PermissionGrant.permanentlyDenied,
      );
    });

    test('permanentlyDenied is permanently denied', () {
      expect(
        PermissionMapper.grantOf(plugin.PermissionStatus.permanentlyDenied),
        PermissionGrant.permanentlyDenied,
      );
    });

    test('every plugin status maps to something', () {
      for (final status in plugin.PermissionStatus.values) {
        expect(PermissionMapper.grantOf(status), isA<PermissionGrant>());
      }
    });
  });

  group('exactAlarmGrant', () {
    test('iOS has no such permission, so it is granted', () {
      expect(
        PermissionMapper.exactAlarmGrant(
          isAndroid: false,
          androidStatus: null,
        ),
        PermissionGrant.granted,
      );
    });

    test('iOS ignores any status handed to it', () {
      expect(
        PermissionMapper.exactAlarmGrant(
          isAndroid: false,
          androidStatus: plugin.PermissionStatus.denied,
        ),
        PermissionGrant.granted,
      );
    });

    test('Android with no answer yet is unknown, not granted', () {
      expect(
        PermissionMapper.exactAlarmGrant(isAndroid: true, androidStatus: null),
        PermissionGrant.unknown,
      );
    });

    test('Android maps its real status', () {
      expect(
        PermissionMapper.exactAlarmGrant(
          isAndroid: true,
          androidStatus: plugin.PermissionStatus.denied,
        ),
        PermissionGrant.denied,
      );
    });
  });

  group('canAskAgain', () {
    test('unknown and denied may be asked', () {
      expect(PermissionMapper.canAskAgain(PermissionGrant.unknown), isTrue);
      expect(PermissionMapper.canAskAgain(PermissionGrant.denied), isTrue);
    });

    test('granted and permanentlyDenied may not', () {
      expect(PermissionMapper.canAskAgain(PermissionGrant.granted), isFalse);
      expect(
        PermissionMapper.canAskAgain(PermissionGrant.permanentlyDenied),
        isFalse,
      );
    });
  });

  group('canRing', () {
    test('iOS is judged on notifications alone', () {
      const state = PermissionState(
        notification: PermissionGrant.granted,
        exactAlarm: PermissionGrant.unknown,
      );
      expect(PermissionMapper.canRing(state, isAndroid: false), isTrue);
    });

    test('Android also needs the exact-alarm grant', () {
      const state = PermissionState(
        notification: PermissionGrant.granted,
        exactAlarm: PermissionGrant.denied,
      );
      expect(PermissionMapper.canRing(state, isAndroid: true), isFalse);
    });

    test('no notification permission means it cannot ring on either', () {
      const state = PermissionState(
        notification: PermissionGrant.denied,
        exactAlarm: PermissionGrant.granted,
      );
      expect(PermissionMapper.canRing(state, isAndroid: false), isFalse);
      expect(PermissionMapper.canRing(state, isAndroid: true), isFalse);
    });

    test('both granted on Android can ring', () {
      const state = PermissionState(
        notification: PermissionGrant.granted,
        exactAlarm: PermissionGrant.granted,
      );
      expect(PermissionMapper.canRing(state, isAndroid: true), isTrue);
    });
  });
}

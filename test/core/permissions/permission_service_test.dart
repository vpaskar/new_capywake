import 'package:capywake/core/permissions/fake_permission_service.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionState', () {
    test('initial is all unknown', () {
      const initial = PermissionState.initial;
      expect(initial.notification, PermissionGrant.unknown);
      expect(initial.exactAlarm, PermissionGrant.unknown);
    });

    test('allGranted only when both are granted', () {
      const both = PermissionState(
        notification: PermissionGrant.granted,
        exactAlarm: PermissionGrant.granted,
      );
      expect(both.allGranted, isTrue);

      const onlyNotification = PermissionState(
        notification: PermissionGrant.granted,
        exactAlarm: PermissionGrant.denied,
      );
      expect(onlyNotification.allGranted, isFalse);
    });

    test('copyWith overrides only the named fields', () {
      const initial = PermissionState(
        notification: PermissionGrant.unknown,
        exactAlarm: PermissionGrant.granted,
      );
      final updated = initial.copyWith(notification: PermissionGrant.denied);
      expect(updated.notification, PermissionGrant.denied);
      expect(updated.exactAlarm, PermissionGrant.granted);

      // No-arg copyWith returns equivalent values.
      expect(initial.copyWith(), initial);
    });

    test('equality + hashCode + toString', () {
      const a = PermissionState(
        notification: PermissionGrant.granted,
        exactAlarm: PermissionGrant.granted,
      );
      const b = PermissionState(
        notification: PermissionGrant.granted,
        exactAlarm: PermissionGrant.granted,
      );
      const c = PermissionState(
        notification: PermissionGrant.denied,
        exactAlarm: PermissionGrant.granted,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.toString(), contains('granted'));
      // Identity branch.
      expect(a == a, isTrue);
    });
  });

  group('FakePermissionService', () {
    test('defaults to PermissionState.initial', () async {
      final svc = FakePermissionService();
      expect(await svc.read(), PermissionState.initial);
    });

    test('honours the constructor-supplied initial state', () async {
      final svc = FakePermissionService(
        initial: const PermissionState(
          notification: PermissionGrant.granted,
          exactAlarm: PermissionGrant.granted,
        ),
      );
      expect((await svc.read()).allGranted, isTrue);
    });

    test('requestNotification with a queued result updates state', () async {
      final svc = FakePermissionService()
        ..notificationRequestResult = PermissionGrant.granted;

      final result = await svc.requestNotification();

      expect(result, PermissionGrant.granted);
      expect(svc.notificationRequestCount, 1);
      expect(svc.notificationRequestResult, isNull);
      expect((await svc.read()).notification, PermissionGrant.granted);
    });

    test(
      'requestNotification without a queued result returns the current grant',
      () async {
        final svc = FakePermissionService(
          initial: const PermissionState(
            notification: PermissionGrant.denied,
            exactAlarm: PermissionGrant.unknown,
          ),
        );
        final result = await svc.requestNotification();
        expect(result, PermissionGrant.denied);
        expect(svc.notificationRequestCount, 1);
      },
    );

    test('requestExactAlarm with a queued result updates state', () async {
      final svc = FakePermissionService()
        ..exactAlarmRequestResult = PermissionGrant.permanentlyDenied;

      final result = await svc.requestExactAlarm();

      expect(result, PermissionGrant.permanentlyDenied);
      expect(svc.exactAlarmRequestCount, 1);
      expect((await svc.read()).exactAlarm, PermissionGrant.permanentlyDenied);
    });

    test(
      'requestExactAlarm without a queued result returns the current grant',
      () async {
        final svc = FakePermissionService(
          initial: const PermissionState(
            notification: PermissionGrant.granted,
            exactAlarm: PermissionGrant.granted,
          ),
        );
        final result = await svc.requestExactAlarm();
        expect(result, PermissionGrant.granted);
      },
    );

    test('state is mutable for tests simulating user toggles', () async {
      final svc = FakePermissionService()
        ..state = const PermissionState(
          notification: PermissionGrant.permanentlyDenied,
          exactAlarm: PermissionGrant.granted,
        );
      final read = await svc.read();
      expect(read.notification, PermissionGrant.permanentlyDenied);
      expect(read.exactAlarm, PermissionGrant.granted);
    });
  });
}

import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_checklist_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _l10n([Locale locale = const Locale('en')]) {
  return AppLocalizations.delegate.load(locale);
}

PermissionState _perm({
  PermissionGrant notification = PermissionGrant.granted,
  PermissionGrant exactAlarm = PermissionGrant.granted,
}) {
  return PermissionState(notification: notification, exactAlarm: exactAlarm);
}

ReliabilityChecklistEntry _entry(
  List<ReliabilityChecklistEntry> entries,
  ReliabilityChecklistItem item,
) {
  return entries.firstWhere((e) => e.item == item);
}

void main() {
  group('ReliabilityChecklistService.build', () {
    test('returns rows in the fixed display order', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty,
      );
      expect(
        entries.map((e) => e.item).toList(),
        ReliabilityChecklistService.order,
      );
    });

    test('omits the Android-only rows on iOS', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.ios,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty,
      );
      expect(entries.map((e) => e.item).toList(), <ReliabilityChecklistItem>[
        ReliabilityChecklistItem.notificationPermission,
        ReliabilityChecklistItem.alarmVolume,
        ReliabilityChecklistItem.doNotDisturbPosture,
      ]);
    });

    test('every row on every platform is actionable or informative', () async {
      final l10n = await _l10n();
      for (final platform in ReliabilityPlatform.values) {
        final entries = ReliabilityChecklistService.build(
          l10n: l10n,
          platform: platform,
          permissions: _perm(),
          acknowledged: ReliabilityChecklistState.empty,
        );
        expect(entries, isNotEmpty, reason: '$platform produced no rows');
        for (final entry in entries) {
          expect(
            ReliabilityChecklistService.appliesTo(entry.item, platform),
            isTrue,
            reason: '${entry.item} should not be shown on $platform',
          );
          expect(entry.title, isNotEmpty);
          expect(entry.body, isNotEmpty);
        }
      }
    });
  });

  group('ReliabilityChecklistService.appliesTo / visibleOrder', () {
    test('exact-alarm and battery rows are Android-only', () {
      for (final item in <ReliabilityChecklistItem>[
        ReliabilityChecklistItem.exactAlarmPermission,
        ReliabilityChecklistItem.batteryOptimization,
      ]) {
        expect(
          ReliabilityChecklistService.appliesTo(
            item,
            ReliabilityPlatform.android,
          ),
          isTrue,
        );
        expect(
          ReliabilityChecklistService.appliesTo(item, ReliabilityPlatform.ios),
          isFalse,
        );
      }
    });

    test('notification, volume and DND rows apply everywhere', () {
      for (final item in <ReliabilityChecklistItem>[
        ReliabilityChecklistItem.notificationPermission,
        ReliabilityChecklistItem.alarmVolume,
        ReliabilityChecklistItem.doNotDisturbPosture,
      ]) {
        for (final platform in ReliabilityPlatform.values) {
          expect(
            ReliabilityChecklistService.appliesTo(item, platform),
            isTrue,
            reason: '$item on $platform',
          );
        }
      }
    });

    test('visibleOrder keeps the display order and drops nothing on '
        'Android', () {
      expect(
        ReliabilityChecklistService.visibleOrder(ReliabilityPlatform.android),
        ReliabilityChecklistService.order,
      );
    });

    test('visibleOrder is a subsequence of order on every platform', () {
      for (final platform in ReliabilityPlatform.values) {
        final visible = ReliabilityChecklistService.visibleOrder(platform);
        final indices = visible
            .map(ReliabilityChecklistService.order.indexOf)
            .toList();
        expect(indices, everyElement(greaterThanOrEqualTo(0)));
        expect(
          indices,
          orderedEquals(<int>[...indices]..sort()),
          reason: '$platform reorders the checklist',
        );
      }
    });
  });

  group('Notification row', () {
    test('granted → ok, no action', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.notificationPermission,
      );
      expect(row.state, ChecklistEntryState.ok);
      expect(row.action, isNull);
      expect(row.body, l10n.reliabilityChecklistNotificationOkBody);
    });

    test('denied → needsAttention with request action', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(notification: PermissionGrant.denied),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.notificationPermission,
      );
      expect(row.state, ChecklistEntryState.needsAttention);
      expect(
        row.action?.kind,
        ReliabilityChecklistActionKind.requestNotification,
      );
      expect(row.action?.label, l10n.reliabilityRequestNotificationAction);
    });

    test(
      'permanentlyDenied → needsAttention with openSettings action',
      () async {
        final l10n = await _l10n();
        final entries = ReliabilityChecklistService.build(
          l10n: l10n,
          platform: ReliabilityPlatform.android,
          permissions: _perm(notification: PermissionGrant.permanentlyDenied),
          acknowledged: ReliabilityChecklistState.empty,
        );
        final row = _entry(
          entries,
          ReliabilityChecklistItem.notificationPermission,
        );
        expect(row.state, ChecklistEntryState.needsAttention);
        expect(row.action?.kind, ReliabilityChecklistActionKind.openSettings);
        expect(row.action?.label, l10n.reliabilityOpenSettingsAction);
      },
    );

    test('unknown → unknown with request action', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(notification: PermissionGrant.unknown),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.notificationPermission,
      );
      expect(row.state, ChecklistEntryState.unknown);
      expect(
        row.action?.kind,
        ReliabilityChecklistActionKind.requestNotification,
      );
    });
  });

  group('Exact-alarm row', () {
    test('android granted → ok with no action', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.exactAlarmPermission,
      );
      expect(row.state, ChecklistEntryState.ok);
      expect(row.action, isNull);
    });

    test('android denied → needsAttention with request action', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(exactAlarm: PermissionGrant.denied),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.exactAlarmPermission,
      );
      expect(row.state, ChecklistEntryState.needsAttention);
      expect(
        row.action?.kind,
        ReliabilityChecklistActionKind.requestExactAlarm,
      );
    });

    test('android permanentlyDenied → openSettings action', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(exactAlarm: PermissionGrant.permanentlyDenied),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.exactAlarmPermission,
      );
      expect(row.state, ChecklistEntryState.needsAttention);
      expect(row.action?.kind, ReliabilityChecklistActionKind.openSettings);
    });

    test('ios → row omitted entirely, even when denied', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.ios,
        permissions: _perm(exactAlarm: PermissionGrant.denied),
        acknowledged: ReliabilityChecklistState.empty,
      );
      expect(
        entries.map((e) => e.item),
        isNot(contains(ReliabilityChecklistItem.exactAlarmPermission)),
      );
    });
  });

  group('Battery row', () {
    test('android unknown → needsAttention with acknowledge action', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.batteryOptimization,
      );
      expect(row.state, ChecklistEntryState.unknown);
      expect(row.action?.kind, ReliabilityChecklistActionKind.acknowledge);
      expect(row.action?.label, l10n.reliabilityChecklistAcknowledgeAction);
    });

    test('android acknowledged ok → ok with acknowledged label', () async {
      final l10n = await _l10n();
      final acknowledged = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.batteryOptimization,
        ChecklistItemState.ok,
      );
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: acknowledged,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.batteryOptimization,
      );
      expect(row.state, ChecklistEntryState.ok);
      expect(row.action?.label, l10n.reliabilityChecklistAcknowledgedAction);
    });

    test('android actionRequired → needsAttention', () async {
      final l10n = await _l10n();
      final acknowledged = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.batteryOptimization,
        ChecklistItemState.actionRequired,
      );
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: acknowledged,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.batteryOptimization,
      );
      expect(row.state, ChecklistEntryState.needsAttention);
    });

    test('ios → row omitted entirely, even when acknowledged', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.ios,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty.copyWithItem(
          ReliabilityChecklistItem.batteryOptimization,
          ChecklistItemState.ok,
        ),
      );
      expect(
        entries.map((e) => e.item),
        isNot(contains(ReliabilityChecklistItem.batteryOptimization)),
      );
    });
  });

  group('Volume row', () {
    test(
      'unknown → unknown with acknowledge action (both platforms)',
      () async {
        final l10n = await _l10n();
        for (final platform in ReliabilityPlatform.values) {
          final entries = ReliabilityChecklistService.build(
            l10n: l10n,
            platform: platform,
            permissions: _perm(),
            acknowledged: ReliabilityChecklistState.empty,
          );
          final row = _entry(
            entries,
            ReliabilityChecklistItem.alarmVolume,
          );
          expect(row.state, ChecklistEntryState.unknown);
          expect(row.action?.kind, ReliabilityChecklistActionKind.acknowledge);
        }
      },
    );

    test('acknowledged ok → ok with acknowledged label', () async {
      final l10n = await _l10n();
      final acknowledged = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.alarmVolume,
        ChecklistItemState.ok,
      );
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: acknowledged,
      );
      final row = _entry(entries, ReliabilityChecklistItem.alarmVolume);
      expect(row.state, ChecklistEntryState.ok);
      expect(row.action?.label, l10n.reliabilityChecklistAcknowledgedAction);
    });
  });

  group('DND row', () {
    test('android body uses the android-specific copy', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.doNotDisturbPosture,
      );
      expect(row.body, l10n.reliabilityChecklistDndAndroidBody);
    });

    test('ios body uses the silent-mode caution copy', () async {
      final l10n = await _l10n();
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.ios,
        permissions: _perm(),
        acknowledged: ReliabilityChecklistState.empty,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.doNotDisturbPosture,
      );
      expect(row.body, l10n.reliabilityCautionSilentModeIos);
    });

    test('actionRequired → needsAttention', () async {
      final l10n = await _l10n();
      final acknowledged = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.doNotDisturbPosture,
        ChecklistItemState.actionRequired,
      );
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: acknowledged,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.doNotDisturbPosture,
      );
      expect(row.state, ChecklistEntryState.needsAttention);
    });

    test('acknowledged ok → ok with the acknowledged label', () async {
      final l10n = await _l10n();
      final acknowledged = ReliabilityChecklistState.empty.copyWithItem(
        ReliabilityChecklistItem.doNotDisturbPosture,
        ChecklistItemState.ok,
      );
      final entries = ReliabilityChecklistService.build(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
        permissions: _perm(),
        acknowledged: acknowledged,
      );
      final row = _entry(
        entries,
        ReliabilityChecklistItem.doNotDisturbPosture,
      );
      expect(row.state, ChecklistEntryState.ok);
      expect(row.action?.label, l10n.reliabilityChecklistAcknowledgedAction);
    });
  });

  group('Value-type equality', () {
    test('ReliabilityChecklistEntry equality is structural', () {
      const a = ReliabilityChecklistEntry(
        item: ReliabilityChecklistItem.alarmVolume,
        state: ChecklistEntryState.ok,
        title: 't',
        body: 'b',
        action: null,
      );
      const b = ReliabilityChecklistEntry(
        item: ReliabilityChecklistItem.alarmVolume,
        state: ChecklistEntryState.ok,
        title: 't',
        body: 'b',
        action: null,
      );
      const c = ReliabilityChecklistEntry(
        item: ReliabilityChecklistItem.alarmVolume,
        state: ChecklistEntryState.needsAttention,
        title: 't',
        body: 'b',
        action: null,
      );
      // Differs only in body — exercises the later-field comparison in ==.
      const differsByBody = ReliabilityChecklistEntry(
        item: ReliabilityChecklistItem.alarmVolume,
        state: ChecklistEntryState.ok,
        title: 't',
        body: 'different',
        action: null,
      );
      // Differs only in action — exercises the last-field comparison in ==.
      const differsByAction = ReliabilityChecklistEntry(
        item: ReliabilityChecklistItem.alarmVolume,
        state: ChecklistEntryState.ok,
        title: 't',
        body: 'b',
        action: ReliabilityChecklistAction(
          kind: ReliabilityChecklistActionKind.acknowledge,
          label: 'OK',
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == differsByBody, isFalse);
      expect(a == differsByAction, isFalse);
      expect(identical(a, a), isTrue);
    });

    test('ReliabilityChecklistAction equality is structural', () {
      const a = ReliabilityChecklistAction(
        kind: ReliabilityChecklistActionKind.acknowledge,
        label: 'OK',
      );
      const b = ReliabilityChecklistAction(
        kind: ReliabilityChecklistActionKind.acknowledge,
        label: 'OK',
      );
      const c = ReliabilityChecklistAction(
        kind: ReliabilityChecklistActionKind.openSettings,
        label: 'OK',
      );
      // Same kind, different label — exercises the label comparison in ==.
      const differsByLabel = ReliabilityChecklistAction(
        kind: ReliabilityChecklistActionKind.acknowledge,
        label: 'Different',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == differsByLabel, isFalse);
    });
  });
}

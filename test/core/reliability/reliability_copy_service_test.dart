import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _l10n([Locale locale = const Locale('en')]) {
  return AppLocalizations.delegate.load(locale);
}

void main() {
  group('ReliabilityPlatform.fromHost', () {
    test('android wins when isAndroid', () {
      expect(
        ReliabilityPlatform.fromHost(isAndroid: true, isIOS: false),
        ReliabilityPlatform.android,
      );
    });

    test('ios when isIOS', () {
      expect(
        ReliabilityPlatform.fromHost(isAndroid: false, isIOS: true),
        ReliabilityPlatform.ios,
      );
    });

    test('falls back to ios for unknown hosts (conservative)', () {
      // Desktop / web — platform we have not certified.
      expect(
        ReliabilityPlatform.fromHost(isAndroid: false, isIOS: false),
        ReliabilityPlatform.ios,
      );
    });
  });

  group('ReliabilityCopyService', () {
    test('summary picks the Android string on Android', () async {
      final l10n = await _l10n();
      final svc = ReliabilityCopyService(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
      );
      expect(svc.summary(), l10n.reliabilitySummaryAndroid);
    });

    test('summary picks the iOS string on iOS', () async {
      final l10n = await _l10n();
      final svc = ReliabilityCopyService(
        l10n: l10n,
        platform: ReliabilityPlatform.ios,
      );
      expect(svc.summary(), l10n.reliabilitySummaryIos);
    });

    test('cautions on Android contain the battery-optimisation kind', () async {
      final l10n = await _l10n();
      final svc = ReliabilityCopyService(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
      );
      final cautions = svc.cautions();
      expect(cautions, hasLength(1));
      expect(
        cautions.single.kind,
        ReliabilityCautionKind.batteryOptimization,
      );
      expect(cautions.single.text, l10n.reliabilityCautionBatteryOptimization);
    });

    test('cautions on iOS list termination, silent, schedule-cap', () async {
      final l10n = await _l10n();
      final svc = ReliabilityCopyService(
        l10n: l10n,
        platform: ReliabilityPlatform.ios,
      );
      final kinds = svc.cautions().map((c) => c.kind).toList();
      expect(kinds, [
        ReliabilityCautionKind.terminationIos,
        ReliabilityCautionKind.silentModeIos,
        ReliabilityCautionKind.scheduleCapIos,
      ]);
    });

    test(
      'permissionDeniedCopy returns the notification copy when denied',
      () async {
        final l10n = await _l10n();
        final svc = ReliabilityCopyService(
          l10n: l10n,
          platform: ReliabilityPlatform.android,
        );
        final copy = svc.permissionDeniedCopy(
          const PermissionState(
            notification: PermissionGrant.denied,
            exactAlarm: PermissionGrant.granted,
          ),
        );
        expect(copy, l10n.reliabilityPermissionNotificationDenied);
      },
    );

    test(
      'permissionDeniedCopy treats permanentlyDenied like denied for '
      'notifications',
      () async {
        final l10n = await _l10n();
        final svc = ReliabilityCopyService(
          l10n: l10n,
          platform: ReliabilityPlatform.ios,
        );
        final copy = svc.permissionDeniedCopy(
          const PermissionState(
            notification: PermissionGrant.permanentlyDenied,
            exactAlarm: PermissionGrant.granted,
          ),
        );
        expect(copy, l10n.reliabilityPermissionNotificationDenied);
      },
    );

    test(
      'permissionDeniedCopy returns the exact-alarm copy on Android when only '
      'exact-alarm is denied',
      () async {
        final l10n = await _l10n();
        final svc = ReliabilityCopyService(
          l10n: l10n,
          platform: ReliabilityPlatform.android,
        );
        final copy = svc.permissionDeniedCopy(
          const PermissionState(
            notification: PermissionGrant.granted,
            exactAlarm: PermissionGrant.denied,
          ),
        );
        expect(copy, l10n.reliabilityPermissionExactAlarmDenied);
      },
    );

    test(
      'permissionDeniedCopy never surfaces exact-alarm copy on iOS',
      () async {
        final l10n = await _l10n();
        final svc = ReliabilityCopyService(
          l10n: l10n,
          platform: ReliabilityPlatform.ios,
        );
        final copy = svc.permissionDeniedCopy(
          const PermissionState(
            notification: PermissionGrant.granted,
            exactAlarm: PermissionGrant.denied,
          ),
        );
        expect(copy, isNull);
      },
    );

    test('permissionDeniedCopy returns null when both are granted', () async {
      final l10n = await _l10n();
      final svc = ReliabilityCopyService(
        l10n: l10n,
        platform: ReliabilityPlatform.android,
      );
      final copy = svc.permissionDeniedCopy(
        const PermissionState(
          notification: PermissionGrant.granted,
          exactAlarm: PermissionGrant.granted,
        ),
      );
      expect(copy, isNull);
    });
  });

  group('ReliabilityCaution', () {
    test('equality + hashCode + toString', () {
      const a = ReliabilityCaution(
        kind: ReliabilityCautionKind.batteryOptimization,
        text: 'x',
      );
      const b = ReliabilityCaution(
        kind: ReliabilityCautionKind.batteryOptimization,
        text: 'x',
      );
      const c = ReliabilityCaution(
        kind: ReliabilityCautionKind.terminationIos,
        text: 'x',
      );
      // Same kind, different text — exercises the text comparison in ==.
      const differsByText = ReliabilityCaution(
        kind: ReliabilityCautionKind.batteryOptimization,
        text: 'y',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a == differsByText, isFalse);
      expect(a.toString(), contains('batteryOptimization'));
      expect(a == a, isTrue);
    });
  });

  group('ReliabilityCopyService.attentionSummary', () {
    test('reports the all-clear when nothing needs attention', () async {
      final copy = ReliabilityCopyService(
        l10n: await _l10n(),
        platform: ReliabilityPlatform.android,
      );
      final summary = copy.attentionSummary(needsAttentionCount: 0);
      expect(summary.needsAttention, isFalse);
      expect(summary.title, 'Nothing needs attention');
      expect(summary.body, contains('this phone'));
    });

    test('the all-clear never promises the alarm will ring', () async {
      // The most prominent claim on the screen, and the one most able to
      // overpromise. It may say the list looks right; it may not say the
      // alarm is guaranteed, because no checklist can guarantee that.
      final copy = ReliabilityCopyService(
        l10n: await _l10n(),
        platform: ReliabilityPlatform.ios,
      );
      final body = copy.attentionSummary(needsAttentionCount: 0).body;
      for (final forbidden in [
        'never oversleep',
        'guarantee',
        'always ring',
        'will ring',
      ]) {
        expect(body.toLowerCase(), isNot(contains(forbidden)));
      }
    });

    test(
      'falls back to the all-clear when a count arrives with no body',
      () async {
        final copy = ReliabilityCopyService(
          l10n: await _l10n(),
          platform: ReliabilityPlatform.android,
        );
        final summary = copy.attentionSummary(needsAttentionCount: 3);
        expect(summary.needsAttention, isFalse);
      },
    );

    test('one open item names it and says the rest is fine', () async {
      final copy = ReliabilityCopyService(
        l10n: await _l10n(),
        platform: ReliabilityPlatform.android,
      );
      final summary = copy.attentionSummary(
        needsAttentionCount: 1,
        firstAttentionBody: 'Battery optimization may stop CapyWake.',
      );
      expect(summary.needsAttention, isTrue);
      expect(summary.title, 'One thing needs attention');
      expect(summary.body, startsWith('Battery optimization'));
      expect(summary.body, contains('Everything else on this list is fine.'));
    });

    test('two or more open items drop the "everything else" clause', () async {
      // With two problems open, "everything else is fine" is simply false.
      final copy = ReliabilityCopyService(
        l10n: await _l10n(),
        platform: ReliabilityPlatform.android,
      );
      final summary = copy.attentionSummary(
        needsAttentionCount: 2,
        firstAttentionBody: 'Battery optimization may stop CapyWake.',
      );
      expect(summary.title, '2 things need attention');
      expect(
        summary.body,
        isNot(contains('Everything else on this list is fine.')),
      );
    });

    test('a negative count is treated as nothing open', () async {
      final copy = ReliabilityCopyService(
        l10n: await _l10n(),
        platform: ReliabilityPlatform.android,
      );
      final summary = copy.attentionSummary(
        needsAttentionCount: -1,
        firstAttentionBody: 'ignored',
      );
      expect(summary.needsAttention, isFalse);
    });

    test('is localised', () async {
      final copy = ReliabilityCopyService(
        l10n: await _l10n(const Locale('de')),
        platform: ReliabilityPlatform.android,
      );
      expect(
        copy.attentionSummary(needsAttentionCount: 0).title,
        'Nichts braucht Aufmerksamkeit',
      );
      expect(
        copy
            .attentionSummary(
              needsAttentionCount: 1,
              firstAttentionBody: 'Etwas.',
            )
            .title,
        'Eine Sache braucht Aufmerksamkeit',
      );
    });

    test('ReliabilityAttentionSummary has value semantics', () {
      const a = ReliabilityAttentionSummary(
        title: 't',
        body: 'b',
        needsAttention: true,
      );
      const same = ReliabilityAttentionSummary(
        title: 't',
        body: 'b',
        needsAttention: true,
      );
      const differentTitle = ReliabilityAttentionSummary(
        title: 'other',
        body: 'b',
        needsAttention: true,
      );
      const differentBody = ReliabilityAttentionSummary(
        title: 't',
        body: 'other',
        needsAttention: true,
      );
      const differentFlag = ReliabilityAttentionSummary(
        title: 't',
        body: 'b',
        needsAttention: false,
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(differentTitle));
      expect(a, isNot(differentBody));
      expect(a, isNot(differentFlag));
      expect(a.toString(), contains('needsAttention: true'));
    });
  });
}

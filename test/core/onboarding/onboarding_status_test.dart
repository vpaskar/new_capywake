import 'package:capywake/core/onboarding/onboarding_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingStatus.needsOnboarding', () {
    test('a fresh install — no flag, no alarms — needs setup', () {
      expect(
        OnboardingStatus.needsOnboarding(
          hasCompletedFlag: false,
          hasExistingAlarms: false,
        ),
        isTrue,
      );
    });

    test('a completed install never needs setup again', () {
      for (final hasAlarms in [true, false]) {
        expect(
          OnboardingStatus.needsOnboarding(
            hasCompletedFlag: true,
            hasExistingAlarms: hasAlarms,
          ),
          isFalse,
          reason: 'hasExistingAlarms=$hasAlarms',
        );
      }
    });

    test('existing alarms rescue an upgrade that never wrote a flag', () {
      // The case the flag alone cannot answer: somebody who installed
      // CapyWake before onboarding existed, set an alarm, and never opened
      // Settings — so there is no stored row to grandfather. Their alarms are
      // the evidence, and dropping them into first-run setup after an update
      // would put a setup screen between them and their morning.
      expect(
        OnboardingStatus.needsOnboarding(
          hasCompletedFlag: false,
          hasExistingAlarms: true,
        ),
        isFalse,
      );
    });

    test('setup can only be demanded of an install with zero alarms', () {
      // Stated as its own test because it is load-bearing beyond tidiness:
      // the first-run redirect replaces the navigation shell, and the shell
      // is what listens for a ringing alarm. This predicate returning `false`
      // whenever an alarm exists is the reason that replacement can never
      // hide a ringing alarm.
      final demandsSetup = [
        for (final flag in [true, false])
          for (final alarms in [true, false])
            if (OnboardingStatus.needsOnboarding(
              hasCompletedFlag: flag,
              hasExistingAlarms: alarms,
            ))
              alarms,
      ];
      expect(demandsSetup, everyElement(isFalse));
    });
  });
}

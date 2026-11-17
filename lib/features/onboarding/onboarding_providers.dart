import 'package:capywake/core/onboarding/onboarding_status.dart';
import 'package:capywake/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this launch is a genuine first run. A value only when both streams
/// have data, so the redirect never fires on an unresolved or failed read.
final needsOnboardingProvider = Provider<AsyncValue<bool>>((ref) {
  final settings = ref.watch(userSettingsStreamProvider);
  final alarms = ref.watch(alarmsStreamProvider);
  if (!settings.hasValue || !alarms.hasValue) {
    return const AsyncValue<bool>.loading();
  }
  return AsyncData(
    OnboardingStatus.needsOnboarding(
      hasCompletedFlag: settings.requireValue.hasCompletedOnboarding,
      hasExistingAlarms: alarms.requireValue.isNotEmpty,
    ),
  );
});

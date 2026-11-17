import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which platform's reliability story the surfaces tell. Explicit, so a test
/// fixes it and the suite behaves the same on every machine.
final reliabilityPlatformProvider = Provider<ReliabilityPlatform>((ref) {
  return ReliabilityPlatform.fromHost(
    isAndroid: defaultTargetPlatform == TargetPlatform.android,
    isIOS: defaultTargetPlatform == TargetPlatform.iOS,
  );
}, dependencies: const []);

/// The live OS permission snapshot. A notifier, not a future: granting
/// pushes a new value, so the row behind the OS dialog changes.
final permissionStateProvider =
    AsyncNotifierProvider<PermissionStateNotifier, PermissionState>(
      PermissionStateNotifier.new,
      // `permissionServiceProvider` is scoped — the platform overrides swap
      // the fake for the real service at bootstrap.
      dependencies: [permissionServiceProvider],
    );

class PermissionStateNotifier extends AsyncNotifier<PermissionState> {
  @override
  Future<PermissionState> build() =>
      ref.watch(permissionServiceProvider).read();

  /// Ask the OS for notification permission and publish the result.
  Future<void> requestNotification() async {
    final service = ref.read(permissionServiceProvider);
    await service.requestNotification();
    state = AsyncData(await service.read());
  }

  /// Ask for Android's exact-alarm permission. A no-op elsewhere.
  Future<void> requestExactAlarm() async {
    final service = ref.read(permissionServiceProvider);
    await service.requestExactAlarm();
    state = AsyncData(await service.read());
  }

  /// Send the user to the OS settings page, then re-read on return.
  Future<void> openSettings() async {
    final service = ref.read(permissionServiceProvider);
    await service.openAppSettings();
    state = AsyncData(await service.read());
  }

  /// Re-read without changing anything — used when the app resumes.
  Future<void> refresh() async {
    state = AsyncData(await ref.read(permissionServiceProvider).read());
  }
}

/// Writes to the user-settings singleton. Every mutation re-reads first, so
/// a write cannot drop a field another surface set in the meantime.
class SettingsController {
  const SettingsController(this._ref);

  final Ref _ref;

  Future<void> setDefaultSound(String soundId) =>
      _update((s) => s.copyWith(defaultSoundId: soundId));

  Future<void> setDefaultSnoozeMinutes(int minutes) =>
      _update((s) => s.copyWith(defaultSnoozeMinutes: minutes));

  Future<void> setThemeMode(ThemeModePreference mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setTimeFormat(TimeFormatPreference format) =>
      _update((s) => s.copyWith(timeFormat: format));

  Future<void> setMotionConfirmationEnabled({required bool enabled}) =>
      _update((s) => s.copyWith(motionConfirmationEnabled: enabled));

  /// Close the first-run flow. The only writer of this flag; without it the
  /// onboarding redirect could never stop firing.
  Future<void> completeOnboarding() =>
      _update((s) => s.copyWith(hasCompletedOnboarding: true));

  /// Record that the user judged a checklist item for themselves.
  Future<void> acknowledgeChecklistItem(
    ReliabilityChecklistItem item, {
    required bool acknowledged,
  }) {
    return _update(
      (s) => s.copyWith(
        reliabilityChecklistState: s.reliabilityChecklistState.copyWithItem(
          item,
          acknowledged
              ? ChecklistItemState.ok
              : ChecklistItemState.actionRequired,
        ),
      ),
    );
  }

  Future<void> _update(UserSettings Function(UserSettings) change) async {
    final repository = _ref.read(capywakeRepositoryProvider);
    final current = await repository.getSettings();
    await repository.saveSettings(change(current));
  }
}

final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);

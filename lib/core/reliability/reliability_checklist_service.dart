import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:meta/meta.dart';

/// Pure aggregator that turns the reliability inputs (per-platform
/// posture, OS permissions, and the user-acknowledged checklist state)
/// into a stable, ordered list of [ReliabilityChecklistEntry]s the UI
/// renders.
///
/// The service is **the only place** in the codebase that decides which
/// checklist items apply per platform, in what order, and what state
/// each one is in. The screen consumes the output directly — no
/// per-item branching in widgets.
///
/// Reliability honesty (CLAUDE.md): every string surfaced here flows
/// through [ReliabilityCopyService] / `AppLocalizations`.
///
/// Items that do not apply to the current platform are **omitted**, not
/// rendered as inert "not applicable" rows: a checklist is a list of
/// things the user can act on, and padding it with rows that exist only
/// on the other OS is noise that makes the actionable rows harder to
/// find. This costs no honesty — the platform's real limits are stated
/// by the rows that *do* apply (e.g. the iOS silent-mode caution on the
/// Do Not Disturb row) and by [ReliabilityCopyService]'s posture copy,
/// not by an empty Android row.
abstract final class ReliabilityChecklistService {
  /// The fixed display order for checklist items. The screen renders
  /// applicable items in this order, so the layout is deterministic
  /// within a platform.
  ///
  /// Not every item applies on every platform — see [appliesTo]. Use
  /// [visibleOrder] for the items actually rendered on a platform.
  static const order = <ReliabilityChecklistItem>[
    ReliabilityChecklistItem.notificationPermission,
    ReliabilityChecklistItem.exactAlarmPermission,
    ReliabilityChecklistItem.batteryOptimization,
    ReliabilityChecklistItem.alarmVolume,
    ReliabilityChecklistItem.doNotDisturbPosture,
  ];

  /// Whether [item] applies to [platform] at all.
  ///
  /// The exact-alarm permission and OEM battery-optimisation opt-out are
  /// Android concepts; iOS has no equivalent setting for the user to
  /// change, so those rows are not shown there.
  static bool appliesTo(
    ReliabilityChecklistItem item,
    ReliabilityPlatform platform,
  ) {
    switch (item) {
      case ReliabilityChecklistItem.exactAlarmPermission:
      case ReliabilityChecklistItem.batteryOptimization:
        return platform == ReliabilityPlatform.android;
      case ReliabilityChecklistItem.notificationPermission:
      case ReliabilityChecklistItem.alarmVolume:
      case ReliabilityChecklistItem.doNotDisturbPosture:
        return true;
    }
  }

  /// The items rendered on [platform], in display order.
  static List<ReliabilityChecklistItem> visibleOrder(
    ReliabilityPlatform platform,
  ) {
    return order
        .where((item) => appliesTo(item, platform))
        .toList(growable: false);
  }

  /// Build the checklist for the current input snapshot.
  ///
  /// - [l10n] is the localised string bundle.
  /// - [platform] decides which items are relevant.
  /// - [permissions] is the live OS permission snapshot (drives the
  ///   notification + exact-alarm rows).
  /// - [acknowledged] is the user-acknowledged state from
  ///   [UserSettings.reliabilityChecklistState] — used to mark
  ///   user-judged items (volume / DND posture) as `ok` once the user
  ///   has confirmed they checked them.
  static List<ReliabilityChecklistEntry> build({
    required AppLocalizations l10n,
    required ReliabilityPlatform platform,
    required PermissionState permissions,
    required ReliabilityChecklistState acknowledged,
  }) {
    return visibleOrder(platform)
        .map(
          (item) => _entryFor(
            item: item,
            l10n: l10n,
            platform: platform,
            permissions: permissions,
            acknowledged: acknowledged,
          ),
        )
        .toList(growable: false);
  }

  static ReliabilityChecklistEntry _entryFor({
    required ReliabilityChecklistItem item,
    required AppLocalizations l10n,
    required ReliabilityPlatform platform,
    required PermissionState permissions,
    required ReliabilityChecklistState acknowledged,
  }) {
    switch (item) {
      case ReliabilityChecklistItem.notificationPermission:
        return _notificationEntry(l10n, permissions);
      case ReliabilityChecklistItem.exactAlarmPermission:
        return _exactAlarmEntry(l10n, permissions);
      case ReliabilityChecklistItem.batteryOptimization:
        return _batteryEntry(l10n, acknowledged);
      case ReliabilityChecklistItem.alarmVolume:
        return _volumeEntry(l10n, acknowledged);
      case ReliabilityChecklistItem.doNotDisturbPosture:
        return _dndEntry(l10n, platform, acknowledged);
    }
  }

  static ReliabilityChecklistEntry _notificationEntry(
    AppLocalizations l10n,
    PermissionState permissions,
  ) {
    final grant = permissions.notification;
    final state = _stateFromPermission(grant);
    final action = _permissionAction(
      grant: grant,
      requestLabel: l10n.reliabilityRequestNotificationAction,
      openSettingsLabel: l10n.reliabilityOpenSettingsAction,
      requestKind: ReliabilityChecklistActionKind.requestNotification,
    );
    return ReliabilityChecklistEntry(
      item: ReliabilityChecklistItem.notificationPermission,
      state: state,
      title: l10n.reliabilityChecklistNotificationTitle,
      body: state == ChecklistEntryState.ok
          ? l10n.reliabilityChecklistNotificationOkBody
          : l10n.reliabilityPermissionNotificationDenied,
      action: action,
    );
  }

  static ReliabilityChecklistEntry _exactAlarmEntry(
    AppLocalizations l10n,
    PermissionState permissions,
  ) {
    final grant = permissions.exactAlarm;
    final state = _stateFromPermission(grant);
    final action = _permissionAction(
      grant: grant,
      requestLabel: l10n.reliabilityRequestExactAlarmAction,
      openSettingsLabel: l10n.reliabilityOpenSettingsAction,
      requestKind: ReliabilityChecklistActionKind.requestExactAlarm,
    );
    return ReliabilityChecklistEntry(
      item: ReliabilityChecklistItem.exactAlarmPermission,
      state: state,
      title: l10n.reliabilityChecklistExactAlarmTitle,
      body: state == ChecklistEntryState.ok
          ? l10n.reliabilityChecklistExactAlarmOkBody
          : l10n.reliabilityPermissionExactAlarmDenied,
      action: action,
    );
  }

  static ReliabilityChecklistEntry _batteryEntry(
    AppLocalizations l10n,
    ReliabilityChecklistState acknowledged,
  ) {
    final state = _stateFromAcknowledged(
      acknowledged.stateOf(ReliabilityChecklistItem.batteryOptimization),
    );
    return ReliabilityChecklistEntry(
      item: ReliabilityChecklistItem.batteryOptimization,
      state: state,
      title: l10n.reliabilityChecklistBatteryTitle,
      body: l10n.reliabilityCautionBatteryOptimization,
      action: ReliabilityChecklistAction(
        kind: ReliabilityChecklistActionKind.acknowledge,
        label: state == ChecklistEntryState.ok
            ? l10n.reliabilityChecklistAcknowledgedAction
            : l10n.reliabilityChecklistAcknowledgeAction,
      ),
    );
  }

  static ReliabilityChecklistEntry _volumeEntry(
    AppLocalizations l10n,
    ReliabilityChecklistState acknowledged,
  ) {
    final state = _stateFromAcknowledged(
      acknowledged.stateOf(ReliabilityChecklistItem.alarmVolume),
    );
    return ReliabilityChecklistEntry(
      item: ReliabilityChecklistItem.alarmVolume,
      state: state,
      title: l10n.reliabilityChecklistVolumeTitle,
      body: l10n.reliabilityChecklistVolumeBody,
      action: ReliabilityChecklistAction(
        kind: ReliabilityChecklistActionKind.acknowledge,
        label: state == ChecklistEntryState.ok
            ? l10n.reliabilityChecklistAcknowledgedAction
            : l10n.reliabilityChecklistAcknowledgeAction,
      ),
    );
  }

  static ReliabilityChecklistEntry _dndEntry(
    AppLocalizations l10n,
    ReliabilityPlatform platform,
    ReliabilityChecklistState acknowledged,
  ) {
    final state = _stateFromAcknowledged(
      acknowledged.stateOf(ReliabilityChecklistItem.doNotDisturbPosture),
    );
    final body = platform == ReliabilityPlatform.ios
        ? l10n.reliabilityCautionSilentModeIos
        : l10n.reliabilityChecklistDndAndroidBody;
    return ReliabilityChecklistEntry(
      item: ReliabilityChecklistItem.doNotDisturbPosture,
      state: state,
      title: l10n.reliabilityChecklistDndTitle,
      body: body,
      action: ReliabilityChecklistAction(
        kind: ReliabilityChecklistActionKind.acknowledge,
        label: state == ChecklistEntryState.ok
            ? l10n.reliabilityChecklistAcknowledgedAction
            : l10n.reliabilityChecklistAcknowledgeAction,
      ),
    );
  }

  static ChecklistEntryState _stateFromPermission(PermissionGrant grant) {
    switch (grant) {
      case PermissionGrant.granted:
        return ChecklistEntryState.ok;
      case PermissionGrant.denied:
      case PermissionGrant.permanentlyDenied:
        return ChecklistEntryState.needsAttention;
      case PermissionGrant.unknown:
        return ChecklistEntryState.unknown;
    }
  }

  static ChecklistEntryState _stateFromAcknowledged(ChecklistItemState s) {
    switch (s) {
      case ChecklistItemState.ok:
        return ChecklistEntryState.ok;
      case ChecklistItemState.actionRequired:
        return ChecklistEntryState.needsAttention;
      case ChecklistItemState.unknown:
        return ChecklistEntryState.unknown;
    }
  }

  static ReliabilityChecklistAction? _permissionAction({
    required PermissionGrant grant,
    required String requestLabel,
    required String openSettingsLabel,
    required ReliabilityChecklistActionKind requestKind,
  }) {
    switch (grant) {
      case PermissionGrant.granted:
        return null;
      case PermissionGrant.denied:
      case PermissionGrant.unknown:
        return ReliabilityChecklistAction(
          kind: requestKind,
          label: requestLabel,
        );
      case PermissionGrant.permanentlyDenied:
        return ReliabilityChecklistAction(
          kind: ReliabilityChecklistActionKind.openSettings,
          label: openSettingsLabel,
        );
    }
  }
}

/// One row on the reliability checklist screen.
@immutable
class ReliabilityChecklistEntry {
  const ReliabilityChecklistEntry({
    required this.item,
    required this.state,
    required this.title,
    required this.body,
    required this.action,
  });

  /// Stable identifier for this checklist row.
  final ReliabilityChecklistItem item;

  /// Current state — ok / needs-attention / unknown.
  final ChecklistEntryState state;

  /// Localised title (one short line).
  final String title;

  /// Localised body — calm, plain, honest.
  final String body;

  /// Optional action affordance. `null` means there is nothing the user
  /// can do here right now (e.g. an already-granted permission).
  final ReliabilityChecklistAction? action;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReliabilityChecklistEntry &&
        other.item == item &&
        other.state == state &&
        other.title == title &&
        other.body == body &&
        other.action == action;
  }

  @override
  int get hashCode => Object.hash(item, state, title, body, action);
}

/// State of a single checklist row.
enum ChecklistEntryState {
  /// All good — no action needed.
  ok,

  /// User-actionable — the row needs attention to make alarms reliable.
  needsAttention,

  /// We have not yet checked or the platform did not surface the state.
  ///
  /// Note there is deliberately no `notApplicable` state: rows that do
  /// not apply to the current platform are omitted by
  /// [ReliabilityChecklistService.visibleOrder] rather than rendered as
  /// inert badges.
  unknown,
}

/// Affordance the user can tap on a checklist row.
@immutable
class ReliabilityChecklistAction {
  const ReliabilityChecklistAction({required this.kind, required this.label});

  /// What this action does.
  final ReliabilityChecklistActionKind kind;

  /// Localised label.
  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReliabilityChecklistAction &&
        other.kind == kind &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(kind, label);
}

/// Closed set of checklist actions.
enum ReliabilityChecklistActionKind {
  /// Trigger the OS notification permission prompt.
  requestNotification,

  /// Trigger the OS exact-alarm permission flow (Android only).
  requestExactAlarm,

  /// Open the device Settings app (used for `permanentlyDenied`).
  openSettings,

  /// Mark a user-judged row (volume, DND) as `ok` for now.
  acknowledge,
}

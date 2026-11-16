import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:meta/meta.dart';

/// The single, app-wide source of every reliability/caution string.
///
/// **Hard rule (CLAUDE.md → "Reliability-honesty boundary"):** every
/// piece of user-facing copy that talks about "will this alarm actually
/// ring" — banners, checklist items, permission prompts, settings copy
/// — comes from this service. A widget or feature that hand-rolls its
/// own reliability sentence is a **High** finding.
///
/// The service does two jobs:
///
/// 1. Pick the right per-platform sentence (Android = strong with the
///    OEM-battery-optimisation caveat; iOS = reliable while the app is
///    open or backgrounded; AlarmKit = future improvement). The
///    [ReliabilityPlatform] enum is the dial we turn — *not* the host
///    OS, so tests run identically on every machine.
/// 2. Look up the localised ARB string for that per-platform sentence
///    via [AppLocalizations]. The English text is the canonical source;
///    the other nine locales mirror the same calm, honest meaning.
///
/// What this service NEVER does:
///
/// - Promise "you will never oversleep" or claim parity between iOS
///   and Android.
/// - Imply the app bypasses silent mode / Do Not Disturb.
/// - Use fear / shame language. Copy is calm, neutral, practical.
///
/// The ARB keys it consumes (added in Phase 06):
///
/// - `reliabilitySummaryAndroid` — Android baseline summary.
/// - `reliabilitySummaryIos` — iOS baseline summary.
/// - `reliabilityCautionBatteryOptimization` — OEM kill caveat
///   (Android only).
/// - `reliabilityCautionTerminationIos` — termination caveat
///   (iOS only).
/// - `reliabilityCautionSilentModeIos` — silent-mode / DND caveat
///   (iOS only).
/// - `reliabilityCautionScheduleCapIos` — 64-pending-notifications
///   caveat (iOS only).
/// - `reliabilityPermissionNotificationDenied` — calm prompt when
///   notification permission is denied.
/// - `reliabilityPermissionExactAlarmDenied` — calm prompt when
///   exact-alarm permission is denied (Android only).
class ReliabilityCopyService {
  /// Build a copy service for [platform], reading strings from [l10n].
  const ReliabilityCopyService({required this.l10n, required this.platform});

  /// The bundle to read localised strings from.
  final AppLocalizations l10n;

  /// Which platform's truth to render. Set explicitly by callers (tests
  /// pass a fixed value; the running app passes the result of
  /// [ReliabilityPlatform.fromHost]).
  final ReliabilityPlatform platform;

  /// One-line summary of how reliable alarms are on this platform.
  /// Calm, plain, honest, never overpromising.
  String summary() {
    switch (platform) {
      case ReliabilityPlatform.android:
        return l10n.reliabilitySummaryAndroid;
      case ReliabilityPlatform.ios:
        return l10n.reliabilitySummaryIos;
    }
  }

  /// The list of caution lines that apply on this platform — each one a
  /// short, plain sentence the reliability checklist screen renders as
  /// its own row. Returned in a stable, documentation-ordered sequence
  /// so screenshots and tests are deterministic.
  List<ReliabilityCaution> cautions() {
    switch (platform) {
      case ReliabilityPlatform.android:
        return <ReliabilityCaution>[
          ReliabilityCaution(
            kind: ReliabilityCautionKind.batteryOptimization,
            text: l10n.reliabilityCautionBatteryOptimization,
          ),
        ];
      case ReliabilityPlatform.ios:
        return <ReliabilityCaution>[
          ReliabilityCaution(
            kind: ReliabilityCautionKind.terminationIos,
            text: l10n.reliabilityCautionTerminationIos,
          ),
          ReliabilityCaution(
            kind: ReliabilityCautionKind.silentModeIos,
            text: l10n.reliabilityCautionSilentModeIos,
          ),
          ReliabilityCaution(
            kind: ReliabilityCautionKind.scheduleCapIos,
            text: l10n.reliabilityCautionScheduleCapIos,
          ),
        ];
    }
  }

  /// The heading card that leads the reliability checklist.
  ///
  /// [needsAttentionCount] is how many checks are currently not right, and
  /// [firstAttentionBody] is the already-localised body of the first of them
  /// (from `ReliabilityChecklistService`), so the card names the actual
  /// problem instead of sending the user hunting down the list for it.
  ///
  /// It lives here, with every other reliability sentence, because this is the
  /// most prominent claim on the screen and the one most able to overpromise.
  /// Note what it does *not* say when everything is fine: the all-clear talks
  /// about how the list looks on this phone, never about whether the alarm
  /// will ring — no checklist can promise that, least of all on iOS.
  ReliabilityAttentionSummary attentionSummary({
    required int needsAttentionCount,
    String? firstAttentionBody,
  }) {
    if (needsAttentionCount <= 0 || firstAttentionBody == null) {
      return ReliabilityAttentionSummary(
        title: l10n.reliabilityAttentionNoneTitle,
        body: l10n.reliabilityAttentionNoneBody,
        needsAttention: false,
      );
    }
    // "Everything else is fine" is only true when this is the sole problem.
    // With two or more open items it would be a plain lie, so it is dropped
    // and the count in the title carries the weight instead.
    final body = needsAttentionCount == 1
        ? '$firstAttentionBody '
              '${l10n.reliabilityAttentionEverythingElseFine}'
        : firstAttentionBody;
    return ReliabilityAttentionSummary(
      title: l10n.reliabilityAttentionTitle(needsAttentionCount),
      body: body,
      needsAttention: true,
    );
  }

  /// Calm, honest copy for a denied OS permission. Returns `null` when
  /// every relevant permission is granted (or when it is not relevant on
  /// this platform — e.g. exact-alarm on iOS).
  String? permissionDeniedCopy(PermissionState state) {
    if (state.notification == PermissionGrant.denied ||
        state.notification == PermissionGrant.permanentlyDenied) {
      return l10n.reliabilityPermissionNotificationDenied;
    }
    if (platform == ReliabilityPlatform.android &&
        (state.exactAlarm == PermissionGrant.denied ||
            state.exactAlarm == PermissionGrant.permanentlyDenied)) {
      return l10n.reliabilityPermissionExactAlarmDenied;
    }
    return null;
  }
}

/// Which platform's reliability story to tell. Explicit so tests are
/// host-OS-independent.
enum ReliabilityPlatform {
  /// Android (strong; surface OEM battery optimisation).
  android,

  /// iOS (reliable while the app is alive; honest about
  /// termination, silent-mode, and the 64-cap).
  ios;

  /// Map from `Platform.isAndroid` / `Platform.isIOS` at the data layer
  /// to the right enum value. Anything else (desktop / web / a future
  /// platform we have not certified) falls back to [ios] — the more
  /// conservative story — to make sure we never overpromise.
  static ReliabilityPlatform fromHost({
    required bool isAndroid,
    required bool isIOS,
  }) {
    if (isAndroid) return ReliabilityPlatform.android;
    if (isIOS) return ReliabilityPlatform.ios;
    return ReliabilityPlatform.ios;
  }
}

/// The heading card's copy, from
/// [ReliabilityCopyService.attentionSummary].
@immutable
class ReliabilityAttentionSummary {
  const ReliabilityAttentionSummary({
    required this.title,
    required this.body,
    required this.needsAttention,
  });

  final String title;
  final String body;

  /// Whether anything on the list is currently not right. Drives the card's
  /// colour — warm clay when true, the ordinary calm surface when false.
  /// Never red: warm clay carries every warning in this product.
  final bool needsAttention;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReliabilityAttentionSummary &&
        other.title == title &&
        other.body == body &&
        other.needsAttention == needsAttention;
  }

  @override
  int get hashCode => Object.hash(title, body, needsAttention);

  @override
  String toString() =>
      'ReliabilityAttentionSummary(title: $title, body: $body, '
      'needsAttention: $needsAttention)';
}

/// One caution line on the reliability checklist.
@immutable
class ReliabilityCaution {
  const ReliabilityCaution({required this.kind, required this.text});

  /// Stable identifier for this caution (used by tests / a11y).
  final ReliabilityCautionKind kind;

  /// Localised body copy. Calm, plain, honest.
  final String text;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReliabilityCaution &&
        other.kind == kind &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'ReliabilityCaution(kind: $kind, text: $text)';
}

/// The closed set of caution kinds. Adding a new one requires both an
/// ARB key in all 10 locales and a new `case` in
/// [ReliabilityCopyService.cautions]; the compiler will tell us.
enum ReliabilityCautionKind {
  /// Android — manufacturer battery optimisation may kill the app
  /// (dontkillmyapp.com is the real failure mode).
  batteryOptimization,

  /// iOS — a force-quit / memory-evicted app stops ringing.
  terminationIos,

  /// iOS — silent mode / DND mute the alarm without the Critical
  /// Alerts entitlement.
  silentModeIos,

  /// iOS — at most 64 pending scheduled local notifications.
  scheduleCapIos,
}

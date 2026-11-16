import 'package:meta/meta.dart';

/// Where a Pro entitlement came from. Persisted as the [name] string.
///
/// `none` means the user has never bought Pro. `purchase` is the normal
/// path — a one-time IAP. `restore` is the same purchase resurfaced via the
/// store's "restore purchases" flow on a new device. `promo` covers gift /
/// review codes (kept on the surface so we never confuse a real purchase
/// with a comp).
enum ProPurchaseSource {
  none,
  purchase,
  restore,
  promo,
}

/// Legacy purchase record from builds that offered an in-app unlock.
@immutable
class ProStatus {
  const ProStatus({
    required this.isPro,
    required this.purchaseSource,
    required this.updatedAt,
  });

  /// The honest fresh-install state: not Pro, never purchased, updated at
  /// the unix epoch (sentinel — no real update has happened yet).
  static final initial = ProStatus(
    isPro: false,
    purchaseSource: ProPurchaseSource.none,
    updatedAt: DateTime.utc(1970),
  );

  /// Whether the user currently has Pro.
  final bool isPro;

  /// How the user came to have (or not have) Pro.
  final ProPurchaseSource purchaseSource;

  /// When this row was last written. UTC.
  final DateTime updatedAt;

  ProStatus copyWith({
    bool? isPro,
    ProPurchaseSource? purchaseSource,
    DateTime? updatedAt,
  }) {
    return ProStatus(
      isPro: isPro ?? this.isPro,
      purchaseSource: purchaseSource ?? this.purchaseSource,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProStatus &&
        other.isPro == isPro &&
        other.purchaseSource == purchaseSource &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(isPro, purchaseSource, updatedAt);
}

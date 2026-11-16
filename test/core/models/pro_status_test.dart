import 'package:capywake/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProStatus', () {
    test('initial means: not Pro, never purchased, sentinel updatedAt', () {
      final s = ProStatus.initial;
      expect(s.isPro, isFalse);
      expect(s.purchaseSource, ProPurchaseSource.none);
      // The 1970 sentinel is intentional — see model docs.
      expect(s.updatedAt, DateTime.utc(1970));
    });

    test('value equality on identical fields', () {
      final a = ProStatus(
        isPro: true,
        purchaseSource: ProPurchaseSource.purchase,
        updatedAt: DateTime.utc(2026, 5, 21),
      );
      final b = ProStatus(
        isPro: true,
        purchaseSource: ProPurchaseSource.purchase,
        updatedAt: DateTime.utc(2026, 5, 21),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == a, isTrue);
      // Intentional cross-type compare to exercise the type check in `==`.
      // ignore: unrelated_type_equality_checks
      expect(a == 'pro', isFalse);
    });

    test('copyWith fans out across every field', () {
      final s = ProStatus.initial.copyWith(
        isPro: true,
        purchaseSource: ProPurchaseSource.restore,
        updatedAt: DateTime.utc(2026, 5, 21, 8),
      );
      expect(s.isPro, isTrue);
      expect(s.purchaseSource, ProPurchaseSource.restore);
      expect(s.updatedAt, DateTime.utc(2026, 5, 21, 8));
    });

    test('copyWith() with no args returns an equal value', () {
      final base = ProStatus.initial.copyWith(isPro: true);
      expect(base.copyWith(), equals(base));
    });

    test('purchase sources cover the four documented cases', () {
      expect(ProPurchaseSource.values, [
        ProPurchaseSource.none,
        ProPurchaseSource.purchase,
        ProPurchaseSource.restore,
        ProPurchaseSource.promo,
      ]);
    });
  });
}

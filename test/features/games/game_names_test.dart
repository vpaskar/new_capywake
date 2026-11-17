import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/features/games/game_practice_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an unmapped name key fails loudly, never shows a raw key', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    const stray = GameEntry(
      id: 'stray',
      nameKey: 'gameStray',
      tileAssetId: 'tile.stray',
      availability: GameAvailability.comingSoon,
      screenReaderSolvable: false,
    );
    expect(() => gameName(l10n, stray), throwsArgumentError);
  });

  test('the default practice seed comes from the clock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final seed = container.read(practiceSeedProvider);
    final first = seed();
    expect(seed(), greaterThanOrEqualTo(first));
  });
}

import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/features/games/game_registry.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seeds a practice run. Overridden in tests; never the ring's seed.
final practiceSeedProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().microsecondsSinceEpoch,
);

/// Practice a game outside any alarm. Reads the user's difficulty and writes
/// nothing, so no alarm changes.
class GamePracticeScreen extends ConsumerStatefulWidget {
  const GamePracticeScreen({required this.gameId, super.key});

  final String gameId;

  static const heroBandHeight = 109.0;

  @override
  ConsumerState<GamePracticeScreen> createState() => _GamePracticeScreenState();
}

class _GamePracticeScreenState extends ConsumerState<GamePracticeScreen> {
  late int _seed = ref.read(practiceSeedProvider)();
  bool _done = false;

  void _again() => setState(() {
    _done = false;
    _seed = ref.read(practiceSeedProvider)();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = GameCatalogue.byId(widget.gameId);
    final title = entry == null
        ? l10n.homeGameComingSoonTitle
        : gameName(l10n, entry);

    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.settings,
        bandHeight: GamePracticeScreen.heroBandHeight,
        header: SettingsHeader(title: title),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            CapySpacing.gutterWide,
            CapySpacing.lg,
            CapySpacing.gutterWide,
            CapySpacing.xxl,
          ),
          children: [_body(l10n, entry)],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, GameEntry? entry) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    if (entry == null || !GameRegistry.isLaunchable(entry.id)) {
      return Text(
        l10n.homeGameComingSoonBody(
          entry == null ? widget.gameId : gameName(l10n, entry),
        ),
        style: CapyType.body.copyWith(color: inkSoft),
      );
    }

    if (_done) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.gamePracticeDoneTitle,
              textAlign: TextAlign.center,
              style: CapyType.title.copyWith(color: ink),
            ),
          ),
          const SizedBox(height: CapySpacing.lg),
          CapyButton(label: l10n.gamePracticeAgainAction, onPressed: _again),
        ],
      );
    }

    // Wait for the user's settings: starting on a fallback difficulty and
    // never switching would practise the wrong game.
    final settings = ref.watch(puzzleSettingsStreamProvider);
    if (!settings.hasValue && !settings.hasError) {
      return const SizedBox.shrink();
    }
    final difficulty = settings.value?.difficulty ?? PuzzleDifficulty.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.gamePracticeNote,
          textAlign: TextAlign.center,
          style: CapyType.caption.copyWith(color: inkSoft),
        ),
        const SizedBox(height: CapySpacing.md),
        GameRingingSlot(
          builder: ({required reduceMotion}) => GameRegistry.build(
            entry.id,
            GameLaunch(
              seed: _seed,
              difficulty: difficulty,
              onProgress: (_) {},
              onCompleted: () => setState(() => _done = true),
              reduceMotion: reduceMotion,
            ),
            key: ValueKey(_seed),
          )!,
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/core/puzzle/puzzle_difficulty.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/device_access_prompt.dart';
import 'package:capywake/features/games/game_launch.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/features/games/game_registry.dart';
import 'package:capywake/features/games/game_win_celebration.dart';
import 'package:capywake/features/games/qr_checkpoint_setup.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/features/ringing/ringing_providers.dart';
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

class _GamePracticeScreenState extends ConsumerState<GamePracticeScreen>
    with WidgetsBindingObserver {
  late int _seed = ref.read(practiceSeedProvider)();
  bool _done = false;
  DeviceAccess? _stepAccess;
  bool _stepPromptDismissed = false;
  bool _changingCheckpoint = false;
  DeviceAccess? _cameraAccess;

  bool get _countsSteps =>
      GameCatalogue.byId(widget.gameId)?.countsSteps ?? false;

  bool get _usesCamera =>
      GameCatalogue.byId(widget.gameId)?.usesCamera ?? false;

  @override
  void initState() {
    super.initState();
    if (!_countsSteps && !_usesCamera) return;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_readAccess());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_readAccess());
  }

  Future<void> _readAccess() =>
      _countsSteps ? _readStepAccess() : _readCameraAccess();

  Future<void> _readCameraAccess() async {
    final access = await ref.read(cameraAccessProvider).access();
    if (mounted) setState(() => _cameraAccess = access);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _readStepAccess() async {
    final access = await ref.read(stepSensorProvider).access();
    if (mounted) setState(() => _stepAccess = access);
  }

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
          GameWinPanel(
            gameId: entry.id,
            subline: l10n.gamePracticeDoneTitle,
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

    final checkpoint = ref.watch(qrCheckpointProvider);
    if (entry.usesCamera) {
      // One camera: a ring above this screen needs it, and must not be read
      // as a new checkpoint.
      if (ref.watch(ringingSessionProvider).value != null) {
        return const SizedBox.shrink();
      }
      final camera = _cameraAccess;
      if ((!checkpoint.hasValue && !checkpoint.hasError) || camera == null) {
        return const SizedBox.shrink();
      }
      // Without the camera, the plugin would raise the OS prompt itself.
      if (checkpoint.value == null ||
          _changingCheckpoint ||
          camera != DeviceAccess.ready) {
        return QrCheckpointSetup(
          gameName: gameName(l10n, entry),
          onAccessChanged: (access) => setState(() => _cameraAccess = access),
          onSaved: () => setState(() => _changingCheckpoint = false),
          onCancel: checkpoint.value == null
              ? null
              : () => setState(() => _changingCheckpoint = false),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_offersStepAccess) ...[
          CapyCard(
            child: DeviceAccessPrompt(
              key: const ValueKey('step-access-card'),
              permission: ref.read(stepSensorProvider),
              access: _stepAccess!,
              copy: DeviceAccessCopy.steps(l10n, gameName(l10n, entry)),
              onResolved: (access) => setState(() => _stepAccess = access),
              onNotNow: () => setState(() => _stepPromptDismissed = true),
            ),
          ),
          const SizedBox(height: CapySpacing.md),
        ],
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
              motion: ref.watch(motionSensorProvider),
              steps: ref.watch(stepSensorProvider),
              scanner: ref.watch(codeScannerProvider),
              qrCheckpoint: checkpoint.value,
            ),
            key: ValueKey(_seed),
          )!,
        ),
        if (entry.usesCamera) ...[
          const SizedBox(height: CapySpacing.sm),
          TextButton(
            onPressed: () => setState(() => _changingCheckpoint = true),
            style: TextButton.styleFrom(
              foregroundColor: dark ? CapyColors.darkInk : CapyColors.cocoa,
            ),
            child: Text(l10n.qrCheckpointChange),
          ),
        ],
      ],
    );
  }

  bool get _offersStepAccess =>
      !_stepPromptDismissed &&
      _stepAccess != null &&
      deviceAccessCanImprove(_stepAccess!);
}

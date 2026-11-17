import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/puzzle/puzzle_settings_controller.dart';
import 'package:capywake/features/puzzle/puzzle_settings_fields.dart';
import 'package:capywake/features/settings/settings_header.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide wake-puzzle chooser, pushed from Settings. No native mockup
/// binds it — Tier A binds nothing (see `docs/visual/puzzle_chooser/`).
class PuzzleChooserScreen extends ConsumerWidget {
  const PuzzleChooserScreen({super.key});

  /// Matches the Settings hero band; this is a sibling pushed route.
  static const heroBandHeight = 109.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SceneHeader(
        scene: SceneCrop.settings,
        bandHeight: heroBandHeight,
        header: SettingsHeader(title: l10n.settingsPuzzleHeading),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final settings =
        ref.watch(puzzleSettingsStreamProvider).value ??
        PuzzleSettings.defaults();
    final controller = ref.read(puzzleSettingsControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CapySpacing.gutterWide,
        CapySpacing.lg,
        CapySpacing.gutterWide,
        CapySpacing.xxl,
      ),
      children: [
        Text(
          l10n.settingsPuzzleEntryDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
          ),
        ),
        const SizedBox(height: CapySpacing.lg),
        PuzzleSettingsFields(
          settings: settings,
          onTypeToggled: controller.setTypeEnabled,
          onTaskCountChanged: controller.setTaskCount,
          onDifficultyChanged: controller.setDifficulty,
          onToleratedWrongAnswersChanged: controller.setToleratedWrongAnswers,
          onEscapeStrictnessChanged: controller.setEscapeStrictness,
        ),
      ],
    );
  }
}

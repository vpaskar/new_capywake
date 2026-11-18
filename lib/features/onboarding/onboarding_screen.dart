import 'package:capywake/app/router.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/onboarding/steps/onboarding_strictness_step.dart';
import 'package:capywake/features/onboarding/steps/onboarding_try_step.dart';
import 'package:capywake/features/puzzle/puzzle_settings_controller.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First-run setup: welcome, puzzle preview, strictness. Stepping is local
/// state and `completeOnboarding()` fires only last, so no redirect race.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, puzzle, strictness }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  PuzzleEscapeStrictness _strictness = PuzzleEscapeStrictness.confirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              stepIndex: _Step.values.indexOf(_step),
              stepCount: _Step.values.length,
              onBack: _step == _Step.welcome ? null : _back,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  CapySpacing.xl,
                  CapySpacing.lg,
                  CapySpacing.xl,
                  CapySpacing.lg,
                ),
                child: _StepBody(
                  step: _step,
                  strictness: _strictness,
                  onStrictnessChanged: (s) => setState(() => _strictness = s),
                ),
              ),
            ),
            _Actions(
              step: _step,
              onPrimary: _primary,
              onSkip: _skip,
            ),
          ],
        ),
      ),
    );
  }

  void _back() => setState(() {
    _step = _Step.values[_Step.values.indexOf(_step) - 1];
  });

  Future<void> _primary() async {
    switch (_step) {
      case _Step.welcome:
        setState(() => _step = _Step.puzzle);
      case _Step.puzzle:
        setState(() => _step = _Step.strictness);
      case _Step.strictness:
        await _finish();
    }
  }

  /// The only place onboarding completes: the strictness "Set your first
  /// alarm". Persists the strictness choice, writes the done flag, then leaves.
  Future<void> _finish() => _complete(Routes.alarmNew, writeStrictness: true);

  Future<void> _skip() => _complete(Routes.home, writeStrictness: false);

  /// Persist and leave, or hold position and surface the error on failure, so
  /// a write error never strands the user on a dead-looking button.
  Future<void> _complete(
    String destination, {
    required bool writeStrictness,
  }) async {
    try {
      if (writeStrictness) {
        await ref
            .read(puzzleSettingsControllerProvider)
            .setEscapeStrictness(_strictness);
      }
      await ref.read(settingsControllerProvider).completeOnboarding();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).onboardingSaveError),
          ),
        );
      }
      return;
    }
    if (mounted) context.go(destination);
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.strictness,
    required this.onStrictnessChanged,
  });

  final _Step step;
  final PuzzleEscapeStrictness strictness;
  final ValueChanged<PuzzleEscapeStrictness> onStrictnessChanged;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case _Step.welcome:
        return const _WelcomeBody();
      case _Step.puzzle:
        return const OnboardingTryStep();
      case _Step.strictness:
        return OnboardingStrictnessStep(
          selected: strictness,
          onChanged: onStrictnessChanged,
        );
    }
  }
}

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _WelcomeScene(),
        const SizedBox(height: CapySpacing.xl),
        Semantics(
          header: true,
          child: Text(
            l10n.onboardingWelcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: CapySpacing.md),
        Text(
          l10n.onboardingWelcomeBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: inkSoft),
        ),
        const SizedBox(height: CapySpacing.md),
        Text(
          l10n.onboardingWelcomeSetupNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: inkSoft),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.stepIndex,
    required this.stepCount,
    required this.onBack,
  });

  final int stepIndex;
  final int stepCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;

    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          if (onBack != null)
            PositionedDirectional(
              start: CapySpacing.xs,
              top: 0,
              bottom: 0,
              child: Center(
                child: Semantics(
                  button: true,
                  label: l10n.onboardingBack,
                  onTap: onBack,
                  child: ExcludeSemantics(
                    child: IconButton(
                      onPressed: onBack,
                      tooltip: l10n.onboardingBack,
                      color: ink,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: Semantics(
              label: l10n.onboardingStepProgress(stepIndex + 1, stepCount),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < stepCount; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: CapySpacing.xs,
                        ),
                        width: i == stepIndex ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i <= stepIndex
                              ? CapyColors.accentDeep
                              : (dark
                                    ? CapyColors.darkSurfaceAlt
                                    : CapyColors.surfaceAlt),
                          borderRadius: BorderRadius.circular(CapyRadius.pill),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.step,
    required this.onPrimary,
    required this.onSkip,
  });

  final _Step step;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final isLast = step == _Step.strictness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CapySpacing.xl,
        CapySpacing.sm,
        CapySpacing.xl,
        CapySpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CapyButton(
            label: isLast ? l10n.onboardingFirstAlarmCta : l10n.onboardingNext,
            icon: isLast ? Icons.add_rounded : Icons.arrow_forward_rounded,
            onPressed: onPrimary,
          ),
          const SizedBox(height: CapySpacing.sm),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: inkSoft,
            ),
            child: Text(l10n.onboardingSkip),
          ),
        ],
      ),
    );
  }
}

class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: _sceneHeight,
      width: double.infinity,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CapyRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: dark
                    ? const ColorFilter.mode(
                        CapyColors.artScrim,
                        BlendMode.srcOver,
                      )
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Image.asset(
                  CapyArt.welcomeScene.path,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: CapySpacing.lg),
                  child: Image.asset(
                    CapyArt.wordmark.path,
                    height: _wordmarkPt,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _sceneHeight = 220.0;
  static const _wordmarkPt = 52.0;
}

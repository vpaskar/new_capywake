import 'package:capywake/app/router.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First-run welcome. No mockup binds it; held to tokens and the no-overpromise
/// rule. Asks for no permission — that stays at first alarm enable.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _WelcomeScene(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  CapySpacing.xl,
                  CapySpacing.xl,
                  CapySpacing.xl,
                  CapySpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: inkSoft,
                      ),
                    ),
                    const SizedBox(height: CapySpacing.xl),
                    CapyButton(
                      label: l10n.onboardingFirstAlarmCta,
                      icon: Icons.add_rounded,
                      onPressed: () => _setFirstAlarm(context, ref),
                    ),
                    const SizedBox(height: CapySpacing.sm),
                    _SkipButton(onPressed: () => _skip(context, ref)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setFirstAlarm(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsControllerProvider).completeOnboarding();
    if (context.mounted) context.go(Routes.alarmNew);
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsControllerProvider).completeOnboarding();
    if (context.mounted) context.go(Routes.home);
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
                SceneCrop.home.asset,
                fit: BoxFit.cover,
                alignment: SceneCrop.home.alignment,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: CapySpacing.xl),
                child: Image.asset(CapyArt.wordmark.path, height: _wordmarkPt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _sceneHeight = 300.0;
  static const _wordmarkPt = 56.0;
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inkSoft = Theme.of(context).brightness == Brightness.dark
        ? CapyColors.darkInkSoft
        : CapyColors.cocoaSoft;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(_tapFloor),
        foregroundColor: inkSoft,
      ),
      child: Text(l10n.onboardingSkip),
    );
  }

  static const _tapFloor = 44.0;
}

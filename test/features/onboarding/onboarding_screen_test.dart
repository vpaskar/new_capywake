import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/fake_permission_service.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/features/onboarding/onboarding_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A repository whose settings write always fails, to exercise the onboarding
/// completion error path (SR2 H1).
class _ThrowingRepository extends CapyWakeRepository {
  _ThrowingRepository(super.db);

  @override
  Future<void> saveSettings(UserSettings settings, {DateTime? now}) async {
    throw StateError('write failed');
  }
}

class _Harness {
  _Harness(this.container, this.permissions);

  final ProviderContainer container;
  final FakePermissionService permissions;
}

Future<_Harness> _pumpOnboarding(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  bool failWrites = false,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final permissions = FakePermissionService();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      permissionServiceProvider.overrideWithValue(permissions),
      if (failWrites)
        capywakeRepositoryProvider.overrideWith(
          (ref) => _ThrowingRepository(ref.watch(appDatabaseProvider)),
        ),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const _Stub('home')),
      GoRoute(path: Routes.alarmNew, builder: (_, _) => const _Stub('new')),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container, permissions);
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(OnboardingScreen)));

/// Walk the flow to the last (strictness) step.
Future<void> _toLastStep(WidgetTester tester) async {
  final l10n = _l10n(tester);
  await tester.tap(find.text(l10n.onboardingNext));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.onboardingNext));
  await tester.pumpAndSettle();
}

class _Stub extends StatelessWidget {
  const _Stub(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('stub-$tag')));
}

void main() {
  testWidgets('welcome shows title, body and the Next action', (tester) async {
    await _pumpOnboarding(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
    expect(find.text(l10n.onboardingWelcomeBody), findsOneWidget);
    expect(find.text(l10n.onboardingNext), findsOneWidget);
    expect(find.text(l10n.onboardingSkip), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            (w.image as AssetImage).assetName == CapyArt.welcomeScene.path,
      ),
      findsOneWidget,
      reason: 'G20: the sleeping-Capy bedroom, not the Home scene',
    );
  });

  testWidgets('the welcome step renders no puzzle or strictness title', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    final l10n = _l10n(tester);

    // The welcome is step one; the puzzle and strictness surfaces belong to
    // later steps and must not leak onto it.
    expect(find.text(l10n.onboardingPuzzleTitle), findsNothing);
    expect(find.text(l10n.onboardingStrictnessTitle), findsNothing);
  });

  testWidgets('Next reveals the puzzle step, then the strictness step', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingPuzzleTitle), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingStrictnessTitle), findsOneWidget);
    // The last step offers the first-alarm CTA, not another Next.
    expect(find.text(l10n.onboardingFirstAlarmCta), findsOneWidget);
    expect(find.text(l10n.onboardingNext), findsNothing);
  });

  testWidgets('Back returns to the previous step', (tester) async {
    await _pumpOnboarding(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingPuzzleTitle), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.onboardingBack));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
    expect(find.text(l10n.onboardingPuzzleTitle), findsNothing);
  });

  testWidgets('completion happens only on the last step (H2)', (tester) async {
    final h = await _pumpOnboarding(tester);
    final repo = h.container.read(capywakeRepositoryProvider);

    // Advancing through the intermediate steps must not complete onboarding.
    await tester.tap(find.text(_l10n(tester).onboardingNext));
    await tester.pumpAndSettle();
    expect((await repo.getSettings()).hasCompletedOnboarding, isFalse);

    await tester.tap(find.text(_l10n(tester).onboardingNext));
    await tester.pumpAndSettle();
    expect((await repo.getSettings()).hasCompletedOnboarding, isFalse);

    // Only the final CTA completes it and leaves to the first-alarm screen.
    await tester.tap(find.text(_l10n(tester).onboardingFirstAlarmCta));
    await tester.pumpAndSettle();
    expect(find.text('stub-new'), findsOneWidget);
    expect((await repo.getSettings()).hasCompletedOnboarding, isTrue);
  });

  testWidgets('the strictness choice persists to the puzzle singleton', (
    tester,
  ) async {
    final h = await _pumpOnboarding(tester);
    await _toLastStep(tester);
    final l10n = _l10n(tester);

    // Pick "confirm, then hold" (the non-default), then finish.
    await tester.tap(find.text(l10n.puzzleSettingsEscapeHold));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.onboardingFirstAlarmCta));
    await tester.pumpAndSettle();

    final saved = await h.container
        .read(capywakeRepositoryProvider)
        .getPuzzleSettings();
    expect(saved.escapeStrictness, PuzzleEscapeStrictness.confirmAndHold);
  });

  testWidgets('the strictness step offers no removable-escape option (M1)', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _toLastStep(tester);
    final l10n = _l10n(tester);

    // Exactly the two real strictness values; no third "never"/"off" card.
    expect(find.text(l10n.puzzleSettingsEscapeConfirm), findsOneWidget);
    expect(find.text(l10n.puzzleSettingsEscapeHold), findsOneWidget);
    // The always-reachable explanation is present on the step.
    expect(
      find.text(l10n.puzzleSettingsEscapeExplanation),
      findsOneWidget,
    );
  });

  testWidgets('requests no permission anywhere in the flow (H2)', (
    tester,
  ) async {
    final h = await _pumpOnboarding(tester);
    await _toLastStep(tester);
    await tester.tap(find.text(_l10n(tester).onboardingFirstAlarmCta));
    await tester.pumpAndSettle();

    expect(h.permissions.notificationRequestCount, 0);
    expect(h.permissions.exactAlarmRequestCount, 0);
    expect(h.permissions.openAppSettingsCount, 0);
  });

  testWidgets('copy makes no reliability overpromise', (tester) async {
    await _pumpOnboarding(tester);
    final l10n = _l10n(tester);
    final copy = [
      l10n.onboardingWelcomeTitle,
      l10n.onboardingWelcomeBody,
      l10n.onboardingWelcomeSetupNote,
      l10n.onboardingStrictnessTitle,
      l10n.onboardingStrictnessBody,
      l10n.onboardingFirstAlarmCta,
      l10n.onboardingSkip,
    ].join(' ').toLowerCase();

    for (final banned in ['never oversleep', 'guarantee', 'always wake']) {
      expect(copy.contains(banned), isFalse, reason: 'overpromise: $banned');
    }
  });

  testWidgets('does not overflow at 2x text across the flow', (tester) async {
    await _pumpOnboarding(tester, textScaler: const TextScaler.linear(2));
    expect(tester.takeException(), isNull);
    await _toLastStep(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without hardcoded direction in RTL', (tester) async {
    await _pumpOnboarding(tester, locale: const Locale('ar'));
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a write failure holds the step and surfaces the error (SR2)', (
    tester,
  ) async {
    await _pumpOnboarding(tester, failWrites: true);
    await _toLastStep(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.onboardingFirstAlarmCta));
    await tester.pumpAndSettle();

    // Still on the strictness step; the error is shown, not swallowed.
    expect(find.text(l10n.onboardingStrictnessTitle), findsOneWidget);
    expect(find.text(l10n.onboardingSaveError), findsOneWidget);
  });

  testWidgets('skip completes onboarding via the controller', (tester) async {
    final h = await _pumpOnboarding(tester);

    await tester.tap(find.text(_l10n(tester).onboardingSkip));
    await tester.pumpAndSettle();

    final saved = await h.container
        .read(capywakeRepositoryProvider)
        .getSettings();
    expect(saved.hasCompletedOnboarding, isTrue);
  });
}

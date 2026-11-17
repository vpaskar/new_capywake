import 'package:capywake/app/router.dart';
import 'package:capywake/core/permissions/fake_permission_service.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/onboarding/onboarding_screen.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Harness {
  _Harness(this.container, this.permissions);

  final ProviderContainer container;
  final FakePermissionService permissions;
}

Future<_Harness> _pumpWelcome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
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

class _Stub extends StatelessWidget {
  const _Stub(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('stub-$tag')));
}

void main() {
  testWidgets('shows wordmark, title, body and the two actions', (
    tester,
  ) async {
    await _pumpWelcome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );

    expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
    expect(find.text(l10n.onboardingWelcomeBody), findsOneWidget);
    expect(find.text(l10n.onboardingFirstAlarmCta), findsOneWidget);
    expect(find.text(l10n.onboardingSkip), findsOneWidget);
  });

  testWidgets('requests no permission from the welcome itself (H2)', (
    tester,
  ) async {
    final h = await _pumpWelcome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );

    expect(h.permissions.notificationRequestCount, 0);
    expect(h.permissions.exactAlarmRequestCount, 0);
    expect(h.permissions.openAppSettingsCount, 0);

    // Tapping the CTA completes onboarding and leaves, but still asks for
    // nothing — the permission ask belongs to first enable, not this screen.
    await tester.tap(find.text(l10n.onboardingFirstAlarmCta));
    await tester.pumpAndSettle();
    expect(find.text('stub-new'), findsOneWidget);
    expect(h.permissions.notificationRequestCount, 0);
    expect(h.permissions.exactAlarmRequestCount, 0);
    expect(h.permissions.openAppSettingsCount, 0);
  });

  testWidgets('does not render puzzle or strictness strings (M5)', (
    tester,
  ) async {
    await _pumpWelcome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );

    expect(find.text(l10n.onboardingPuzzleTitle), findsNothing);
    expect(find.text(l10n.onboardingStrictnessTitle), findsNothing);
    expect(find.text(l10n.onboardingWelcomeSetupNote), findsNothing);
  });

  testWidgets('the primary action carries a button semantics label', (
    tester,
  ) async {
    await _pumpWelcome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );
    expect(
      tester.getSemantics(find.text(l10n.onboardingFirstAlarmCta)),
      matchesSemantics(
        label: l10n.onboardingFirstAlarmCta,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
  });

  testWidgets('copy makes no reliability overpromise', (tester) async {
    await _pumpWelcome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );
    final copy = [
      l10n.onboardingWelcomeTitle,
      l10n.onboardingWelcomeBody,
      l10n.onboardingFirstAlarmCta,
      l10n.onboardingSkip,
    ].join(' ').toLowerCase();

    for (final banned in ['never oversleep', 'guarantee', 'always wake']) {
      expect(copy.contains(banned), isFalse, reason: 'overpromise: $banned');
    }
  });

  testWidgets('does not overflow at 2x text', (tester) async {
    await _pumpWelcome(tester, textScaler: const TextScaler.linear(2));
    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('lays out without hardcoded direction in RTL', (tester) async {
    await _pumpWelcome(tester, locale: const Locale('ar'));
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('skip completes onboarding via the controller', (tester) async {
    final h = await _pumpWelcome(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingScreen)),
    );

    await tester.tap(find.text(l10n.onboardingSkip));
    await tester.pumpAndSettle();

    final saved = await h.container
        .read(capywakeRepositoryProvider)
        .getSettings();
    expect(saved.hasCompletedOnboarding, isTrue);
  });
}

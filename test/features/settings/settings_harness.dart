import 'package:capywake/app/router.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/permissions/fake_permission_service.dart';
import 'package:capywake/core/permissions/permission_service.dart';
import 'package:capywake/core/reliability/reliability_copy_service.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/engine/engine_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a Settings test pumps against: the real router, the real provider
/// graph, an in-memory database and a permission service a test can steer.
class SettingsHarness {
  SettingsHarness({
    required this.db,
    required this.container,
    required this.permissions,
  });

  final AppDatabase db;
  final ProviderContainer container;
  final FakePermissionService permissions;

  Future<UserSettings> readSettings() =>
      container.read(capywakeRepositoryProvider).getSettings();
}

/// Pump a route at the mockup's own geometry, 393x852 at 3x.
Future<SettingsHarness> pumpSettings(
  WidgetTester tester, {
  String at = Routes.settings,
  UserSettings? seed,
  List<Alarm> alarms = const [],
  PermissionState grants = const PermissionState(
    notification: PermissionGrant.granted,
    exactAlarm: PermissionGrant.granted,
  ),
  ReliabilityPlatform platform = ReliabilityPlatform.ios,
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final permissionService = FakePermissionService(initial: grants);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      permissionServiceProvider.overrideWithValue(permissionService),
      reliabilityPlatformProvider.overrideWithValue(platform),
    ],
  );
  addTearDown(container.dispose);

  final repository = container.read(capywakeRepositoryProvider);
  if (seed != null) await repository.saveSettings(seed);
  for (final alarm in alarms) {
    await repository.upsertAlarm(alarm);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: createRouter(initialLocation: at),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return SettingsHarness(
    db: db,
    container: container,
    permissions: permissionService,
  );
}

/// The localisations a test reads expected strings from, so an assertion
/// cannot drift from the ARB by being retyped.
AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

/// Scroll [target] clear of the meadow footer and tap it: `scrollUntilVisible`
/// stops as soon as the widget exists, which can leave it unhittable.
Future<void> scrollAndTap(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 120, maxScrolls: 30);
  await tester.pumpAndSettle();

  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 12; i++) {
    final box = tester.getRect(target);
    final hit = tester.hitTestOnBinding(box.center);
    final reachable = hit.path.any(
      (e) => e.target == tester.renderObject(target),
    );
    if (reachable) break;
    await tester.drag(list, const Offset(0, -60));
    await tester.pumpAndSettle();
  }
  await tester.tap(target);
  await tester.pumpAndSettle();
}

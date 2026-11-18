import 'package:capywake/app/router.dart';
import 'package:capywake/core/games/game_catalogue.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/motion/motion_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/device_access_prompt.dart';
import 'package:capywake/features/games/game_names.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// After a game is switched on in a pool (already saved), offers what it
/// still needs: the step sensor, or a checkpoint and the camera.
Future<void> offerGameSetup(
  BuildContext context,
  WidgetRef ref, {
  required String gameId,
  required bool enabled,
}) async {
  final entry = GameCatalogue.byId(gameId);
  if (!enabled || entry == null) return;
  final name = gameName(AppLocalizations.of(context), entry);
  if (entry.countsSteps) return _offerSteps(context, ref, name);
  if (entry.usesCamera) return _offerCheckpoint(context, ref, entry.id, name);
}

Future<void> _offerSteps(
  BuildContext context,
  WidgetRef ref,
  String name,
) async {
  final sensor = ref.read(stepSensorProvider);
  final access = await sensor.access();
  if (!context.mounted || !deviceAccessCanImprove(access)) return;
  await _sheet(
    context,
    (sheet) => DeviceAccessPrompt(
      key: const ValueKey('step-access-sheet'),
      permission: sensor,
      access: access,
      copy: DeviceAccessCopy.steps(AppLocalizations.of(context), name),
      onResolved: (_) => Navigator.of(sheet).pop(),
      onNotNow: () => Navigator.of(sheet).pop(),
      onSettingsOpened: () => Navigator.of(sheet).pop(),
    ),
  );
}

Future<void> _offerCheckpoint(
  BuildContext context,
  WidgetRef ref,
  String gameId,
  String name,
) async {
  final repository = ref.read(capywakeRepositoryProvider);
  final cameraAccess = ref.read(cameraAccessProvider);
  final bool ready;
  try {
    ready =
        await repository.getQrCheckpoint() != null &&
        await cameraAccess.access() == DeviceAccess.ready;
  } on Object {
    return;
  }
  if (!context.mounted || ready) return;
  final l10n = AppLocalizations.of(context);
  final dark = Theme.of(context).brightness == Brightness.dark;
  final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
  final router = GoRouter.of(context);
  await _sheet(
    context,
    (sheet) => Column(
      key: const ValueKey('qr-setup-sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.qrCheckpointTitle,
          style: CapyType.section.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          l10n.qrCheckpointSkipped(name),
          style: CapyType.body.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.lg),
        CapyButton(
          label: l10n.qrCheckpointSet,
          onPressed: () {
            Navigator.of(sheet).pop();
            router.push(Routes.gamePractice(gameId)).ignore();
          },
        ),
        const SizedBox(height: CapySpacing.xs),
        TextButton(
          onPressed: () => Navigator.of(sheet).pop(),
          style: TextButton.styleFrom(foregroundColor: ink),
          child: Text(l10n.permissionNotNowAction),
        ),
      ],
    ),
  );
}

Future<void> _sheet(BuildContext context, WidgetBuilder content) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: dark ? CapyColors.darkSurface : CapyColors.surface,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CapySpacing.xl,
          0,
          CapySpacing.xl,
          CapySpacing.lg,
        ),
        child: content(sheet),
      ),
    ),
  );
}

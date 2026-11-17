import 'package:capywake/core/alarm_sound.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/settings/settings_controller.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pick the sound new alarms start with. Existing alarms keep their own.
Future<void> showSoundPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _Sheet(),
  );
}

class _Sheet extends ConsumerWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(userSettingsStreamProvider).value ?? UserSettings.initial;
    final controller = ref.read(settingsControllerProvider);
    final selected = AlarmSoundCatalog.resolve(settings.defaultSoundId);

    // Scrollable: the catalogue can outgrow a short viewport, and at 2x
    // text scale it does.
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(CapySpacing.lg),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.settingsDefaultSoundLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            RadioGroup<String>(
              groupValue: selected.id,
              onChanged: (id) async {
                if (id == null) return;
                await controller.setDefaultSound(id);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final sound in AlarmSoundCatalog.sounds)
                    RadioListTile<String>(
                      value: sound.id,
                      title: Text(sound.label(l10n)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: CapySpacing.sm),
          ],
        ),
      ),
    );
  }
}

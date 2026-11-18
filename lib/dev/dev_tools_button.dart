import 'package:capywake/data/providers.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/dev/demo_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Off in release and profile builds; captures override it so Tier A
/// screenshots never show developer chrome.
final devToolsEnabledProvider = Provider<bool>((ref) => kDebugMode);

final devToolsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Debug-only entry to the demo-data tools. English only on purpose: it is
/// compiled out of every build a user can install.
class DevToolsButton extends ConsumerWidget {
  const DevToolsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(devToolsEnabledProvider)) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.construction_rounded),
        label: const Text('Developer tools'),
        style: TextButton.styleFrom(
          foregroundColor: dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft,
        ),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const _DevToolsSheet(),
        ),
      ),
    );
  }
}

class _DevToolsSheet extends ConsumerWidget {
  const _DevToolsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;

    Future<void> run(Future<void> Function() action, String done) async {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    }

    final repository = ref.read(capywakeRepositoryProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CapySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Developer tools',
              style: CapyType.section.copyWith(color: ink),
            ),
            const SizedBox(height: CapySpacing.xs),
            Text(
              'Debug builds only. Demo alarms and '
              '${DemoData.historyDays} days of wake history, so Stats and '
              'the alarm list show something. Two demo alarms are on and will '
              'ring. Your own alarms are untouched.',
              style: CapyType.body.copyWith(color: inkSoft),
            ),
            const SizedBox(height: CapySpacing.lg),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Add demo data'),
              onPressed: () => run(
                () => DemoData.add(
                  repository,
                  ref.read(devToolsClockProvider)(),
                ),
                'Demo data added',
              ),
            ),
            const SizedBox(height: CapySpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Remove demo data'),
              onPressed: () =>
                  run(() => DemoData.remove(repository), 'Demo data removed'),
            ),
          ],
        ),
      ),
    );
  }
}

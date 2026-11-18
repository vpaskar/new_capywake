import 'dart:async';

import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/permissions/device_access.dart';
import 'package:capywake/data/camera/camera_providers.dart';
import 'package:capywake/data/providers.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:capywake/features/games/device_access_prompt.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saves the code the user will walk to: why, the camera prompt if needed,
/// then one scan. Every alarm with the game uses the same checkpoint.
class QrCheckpointSetup extends ConsumerStatefulWidget {
  const QrCheckpointSetup({
    required this.gameName,
    required this.onSaved,
    this.onAccessChanged,
    this.onCancel,
    super.key,
  });

  final String gameName;
  final VoidCallback onSaved;

  /// Offered when a checkpoint is already kept, to leave it unchanged.
  final VoidCallback? onCancel;

  final ValueChanged<DeviceAccess>? onAccessChanged;

  static const cameraHeight = 220.0;

  @override
  ConsumerState<QrCheckpointSetup> createState() => _QrCheckpointSetupState();
}

class _QrCheckpointSetupState extends ConsumerState<QrCheckpointSetup>
    with WidgetsBindingObserver {
  DeviceAccess? _access;
  bool _declined = false;
  bool _scanning = false;
  bool _failed = false;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_readAccess());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_readAccess());
    } else if (_scanning) {
      setState(() => _scanning = false);
    }
  }

  Future<void> _readAccess() async {
    _accessIs(await ref.read(cameraAccessProvider).access());
  }

  void _accessIs(DeviceAccess access) {
    if (!mounted) return;
    setState(() => _access = access);
    widget.onAccessChanged?.call(access);
  }

  Future<void> _save(String code) async {
    if (!mounted || _saving || !_scanning) return;
    _saving = true;
    final repository = ref.read(capywakeRepositoryProvider);
    var saved = false;
    try {
      await repository.saveQrCheckpoint(
        QrCheckpoint.of(code, savedAt: DateTime.now().toUtc()),
      );
      saved = true;
    } on Exception {
      saved = false;
    } finally {
      _saving = false;
    }
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _saveFailed = !saved;
    });
    if (!saved) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).qrCheckpointSaved),
      ),
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? CapyColors.darkInk : CapyColors.cocoa;
    final inkSoft = dark ? CapyColors.darkInkSoft : CapyColors.cocoaSoft;
    final access = _access;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.qrCheckpointTitle,
          style: CapyType.section.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.sm),
        Text(
          l10n.qrCheckpointBody(widget.gameName),
          style: CapyType.body.copyWith(color: ink),
        ),
        const SizedBox(height: CapySpacing.lg),
        if (access == null)
          const SizedBox.shrink()
        else if (_declined) ...[
          Text(
            l10n.qrCheckpointSkipped(widget.gameName),
            style: CapyType.caption.copyWith(color: inkSoft),
          ),
          TextButton(
            onPressed: () => setState(() => _declined = false),
            style: TextButton.styleFrom(foregroundColor: ink),
            child: Text(l10n.cameraAccessAllow),
          ),
        ] else if (deviceAccessCanImprove(access))
          DeviceAccessPrompt(
            key: const ValueKey('camera-access-prompt'),
            permission: ref.read(cameraAccessProvider),
            access: access,
            copy: DeviceAccessCopy.camera(l10n, widget.gameName),
            onResolved: _accessIs,
            onNotNow: () => setState(() => _declined = true),
          )
        else if (access == DeviceAccess.unavailable)
          Text(
            l10n.qrCameraUnavailable(widget.gameName),
            style: CapyType.body.copyWith(color: inkSoft),
          )
        else ...[
          if (_scanning) ...[
            SizedBox(
              height: QrCheckpointSetup.cameraHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CapyRadius.lg),
                child: ref
                    .watch(codeScannerProvider)
                    .build(
                      key: const ValueKey('qr-setup-camera'),
                      onCode: _save,
                      onFailed: () => setState(() {
                        _scanning = false;
                        _failed = true;
                      }),
                    ),
              ),
            ),
            const SizedBox(height: CapySpacing.md),
          ],
          if ((_failed || _saveFailed) && !_scanning) ...[
            Text(
              _saveFailed
                  ? l10n.qrCheckpointSaveFailed
                  : l10n.gameQrCameraFailed,
              style: CapyType.caption.copyWith(color: inkSoft),
            ),
            const SizedBox(height: CapySpacing.sm),
          ],
          CapyButton(
            label: _scanning ? l10n.gameQrStopScan : l10n.qrCheckpointScan,
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => setState(() {
              _scanning = !_scanning;
              _failed = false;
              _saveFailed = false;
            }),
          ),
        ],
        if (widget.onCancel != null) ...[
          const SizedBox(height: CapySpacing.xs),
          TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(foregroundColor: ink),
            child: Text(l10n.alarmCancelAction),
          ),
        ],
      ],
    );
  }
}
